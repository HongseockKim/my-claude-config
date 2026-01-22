# 운전정보 수집 설정 시스템 (Collection Op Tag System)

## 개요

OPC UA 서버와 연동하여 발전소 운전정보(발전량, 터빈속도, 온도, 압력 등)를 수집하고 외부 분석 서버로 송부하기 위한 태그 설정 페이지

## URL

| 경로 | 위치 | 용도 |
|------|------|------|
| `/setting/collectionOpTag` | SettingController:312-319 | 설정 메뉴 진입점 |
| `/operation/collectionOpTag` | OperationController:60-65 | 운영 메뉴 진입점 |

## 아키텍처

```
[collectionOpTag.html]
        │
        ▼
[SettingController / OperationController]
        │
        ▼
[OperationInfoService]  ──► [@Cacheable operationConfig]
        │
        ├──► [OpTagRelRepository]
        ├──► [OpCollectionConfigRepository]
        └──► [OpTransferConfigRepository]
        │
        ▼
[MariaDB]
  ├── op_tag_rel (태그 설정)
  ├── op_collection_config (수집 OPC 서버 설정)
  └── op_transfer_config (송부 OPC 서버 설정)
```

## 탭 구조

### 1단계: 목적별 탭
| 탭 | TagPurpose | 설명 |
|----|------------|------|
| 운전정보 수집 | COLLECTION | OPC 서버에서 데이터 수집용 태그 |
| 운전정보 송부 | TRANSFER | 외부 분석 서버로 데이터 송부용 태그 |

### 2단계: 호기별 탭
| 탭 | plantCode | zone3 |
|----|-----------|-------|
| 3호기 | sp_03 | sp_03 |
| 4호기 | sp_04 | sp_04 |

## 핵심 모델

### OpTagRel (태그 관계 설정)
```
src/main/java/com/otoones/otomon/model/OpTagRel.java

@Entity
@Table(name = "op_tag_rel")
public class OpTagRel {
    Long id;
    String plantCode;           // "sp_03", "sp_04"
    TagType tagType;            // POWER, TURBINE_SPEED, etc.
    String tagPattern;          // 태그명 패턴
    String tagUnit;             // 단위 (MW, RPM 등)
    String description;         // 설명
    String nodeId;              // OPC UA 노드 ID (ns=2;s=태그명)
    Integer namespaceIndex;     // 네임스페이스 인덱스 (기본값: 2)
    String dataType;            // 데이터 타입
    String targetIp;            // DROP/TRAFFIC 태그용 대상 IP
    TagPurpose tagPurpose;      // COLLECTION, TRANSFER
    Boolean isActive;           // 활성 여부
    Long collectionConfigId;    // 연결된 OPC 서버 설정 ID
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
}
```

### TagType Enum (10개)
```java
public enum TagType {
    POWER("발전량"),
    TURBINE_SPEED("터빈속도"),
    DROP_PREFIX("DROP 태그 접두사"),
    FREQUENCY("주파수"),
    VOLTAGE("전압"),
    CURRENT("전류"),
    TEMPERATURE("온도"),
    PRESSURE("압력"),
    TRAFFIC_INBOUND("트래픽_인바운드"),
    TRAFFIC_OUTBOUND("트래픽_아웃바운드")
}
```

### TagPurpose Enum
```java
public enum TagPurpose {
    COLLECTION("수집용"),
    TRANSFER("송부용")
}
```

### OpCollectionConfig / OpTransferConfig (OPC 서버 설정)
```
동일한 구조로 수집/송부 서버 설정 분리

@Entity
@Table(name = "op_collection_config" / "op_transfer_config")
public class OpCollectionConfig / OpTransferConfig {
    Long id;
    String configName;          // 설정명 (unique)
    String plantCode;           // "sp_03", "sp_04"
    String serverIp;            // OPC 서버 IP
    Integer serverPort;         // 기본값: 4840
    String endpointUrl;         // 기본값: "/OPC"
    String authType;            // ANONYMOUS, USER_PASSWORD, X509, OAUTH
    String username;
    String password;
    Boolean isActive;
    LocalDateTime lastConnectedAt;
    String connectionStatus;    // CONNECTED, DISCONNECTED
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
}
```

## API 엔드포인트

### 내부 API (인증 필요)

| Method | URL | 설명 |
|--------|-----|------|
| GET | `/operation/tags?purpose=COLLECTION\|TRANSFER` | 목적별 태그 목록 조회 |
| POST | `/operation/tag/update` | 태그 단일 수정/추가 |
| POST | `/operation/tag/delete` | 태그 삭제 |
| POST | `/operation/tags/bulkUpdate` | 태그 일괄 저장 |
| GET | `/operation/tag/changeLog?category=OpTagInfo` | 변경 이력 조회 |
| POST | `/operation/collection/config/save` | 수집 OPC 서버 설정 저장 |
| POST | `/operation/transfer/config/save` | 송부 OPC 서버 설정 저장 |
| GET | `/operation/collection/config/{plantCode}` | 수집 OPC 서버 설정 조회 |
| GET | `/operation/transfer/config/{plantCode}` | 송부 OPC 서버 설정 조회 |

### 외부 API (수집 서버용, 인증 불필요)
```
OperationApiController.java - /operation/api/*
```

| Method | URL | 설명 |
|--------|-----|------|
| GET | `/operation/api/collection/full` | 전체 수집 설정 (OPC + 태그) |
| GET | `/operation/api/transfer/tags` | 전체 송부 설정 (OPC + 태그) |

## JavaScript 함수 (collectionOpTag.html)

### OPC 서버 설정
```javascript
// 수집용 OPC 설정 저장
function saveOPCConfig(plantCode) {
    POST /operation/collection/config/save
    { plantCode, serverIp, serverPort, endpointUrl, authType, username }
}

// 송부용 OPC 설정 저장
function saveTransferOPCConfig(plantCode) {
    POST /operation/transfer/config/save
    { plantCode, serverIp, serverPort, endpointUrl, authType, username }
}

// OPC 설정 로드 (탭 전환 시)
function loadOPCConfig(plantCode, purpose) {
    GET /operation/{purpose}/config/{plantCode}
}
```

### 태그 관리
```javascript
// 태그 추가 (인라인)
function addCollectionTag(plantCode, purpose) {
    // 그리드에 빈 행 추가, 사용자 편집 후 저장
}

// 단일 태그 저장
function saveTag(gridApi, rowData, tagPurpose) {
    POST /operation/tag/update
    { id, plantCode, tagType, tagPattern, description,
      tagUnit, nodeId, namespaceIndex, targetIp, isActive, tagPurpose }
}

// 일괄 저장 (수정된 모든 태그)
function bulkSaveCollectionTags(plantCode, purpose) {
    POST /operation/tags/bulkUpdate
    [{ ... }, { ... }, ...]
}

// 태그 삭제
function deleteTagSetting(tagId) {
    POST /operation/tag/delete { id: tagId }
}

// 태그 편집 모달
function editTagSetting(tagId, rowData) {
    // 모달 표시 → 저장
}
```

### 변경 이력
```javascript
function showChangeLog() {
    GET /operation/tag/changeLog?category=OpTagInfo
    // 모달에 이력 표시
}
```

## 캐싱 전략

### @Cacheable
```java
// OperationInfoService.java

@Cacheable(value = "operationConfig", key = "'collection_active'")
public Map<String,Object> getOperationInfoCached()

@Cacheable(value = "operationConfig", key = "#tagPurpose.name() + '_active'")
public Map<String,Object> getOperationInfoByPurposeCached(TagPurpose tagPurpose)
```

### @CacheEvict
```java
// 태그 수정/삭제/일괄저장 시 캐시 무효화

@CacheEvict(value = "operationConfig", key = "'collection_active'")
public Map<String, Object> opTagInfoUpdate(...)

@CacheEvict(value = "operationConfig", key = "'collection_active'")
public Map<String, Object> opTagInfoDelete(...)

@CacheEvict(value = "operationConfig", allEntries = true)
public Map<String, Object> saveTransferConfig(...)
```

## 비즈니스 로직

### targetIp 처리 규칙
```java
// DROP, TRAFFIC 태그만 targetIp 허용, 그 외는 null 강제
tag.setTargetIp(
    (tagType == TagType.DROP_PREFIX ||
     tagType == TagType.TRAFFIC_INBOUND ||
     tagType == TagType.TRAFFIC_OUTBOUND)
        ? targetIp
        : null
);
```

### 중복 체크
```java
// plantCode + tagType + tagPattern 조합 중복 불허
Optional<OpTagRel> duplicate = opTagRelRepository
    .findByPlantCodeAndTagTypeAndTagPattern(plantCode, tagType, tagPattern);

if (duplicate.isPresent() && !duplicate.get().getId().equals(tagId)) {
    return "중복 오류";
}
```

### Node ID 자동 생성
```java
// 태그 저장 시 nodeId가 없으면 자동 생성
if (tag.getNodeId() == null) {
    tag.setNodeId("ns=2;s=" + tag.getTagPattern());
}
```

## 인증 타입

| authType | 설명 |
|----------|------|
| ANONYMOUS | 인증 없음 |
| USER_PASSWORD | 사용자명/비밀번호 |
| X509 | 인증서 기반 |
| OAUTH | OAuth 토큰 |

## 그리드 컬럼

| 컬럼 | 필드명 | 편집 | 비고 |
|------|--------|------|------|
| ID | id | X | 자동 생성 |
| 태그 유형 | tagType | O | select (TagType enum) |
| 태그 패턴 | tagPattern | O | text |
| 설명 | description | O | text |
| 단위 | tagUnit | O | text |
| 노드 ID | nodeId | O | OPC UA 경로 |
| 네임스페이스 | namespaceIndex | O | 기본값 2 |
| 대상 IP | targetIp | O | DROP/TRAFFIC만 |
| 활성 | isActive | O | checkbox |
| 생성일 | createdAt | X | |
| 수정일 | updatedAt | X | |
| 액션 | - | - | 저장/삭제 버튼 |

## 감사 로그

```java
// @ActivityLog 적용

@ActivityLog(category = "OpTagInfo", action = "UPDATE")
public Map<String, Object> opTagInfoUpdate(...)

@ActivityLog(category = "OpTagInfo", action = "BULK_UPDATE")
public Map<String,Object> opTagInfoBulkUpdate(...)

@ActivityLog(category = "OpTagInfo", action = "DELETE")
public Map<String, Object> opTagInfoDelete(...)

@ActivityLog(category = "OpCollection", action = "UPDATE")
public Map<String, Object> saveCollectionConfig(...)

@ActivityLog(category = "OpTransfer", action = "UPDATE")
public Map<String, Object> saveTransferConfig(...)
```

## Repository 쿼리

### OpTagRelRepository
```java
// 발전소별 활성 태그
List<OpTagRel> findByPlantCodeAndIsActiveTrue(String plantCode);

// 발전소별 + 목적별 활성 태그
List<OpTagRel> findByPlantCodeAndTagPurposeAndIsActiveTrue(
    String plantCode, TagPurpose tagPurpose);

// 중복 체크용
Optional<OpTagRel> findByPlantCodeAndTagTypeAndTagPattern(
    String plantCode, TagType tagType, String tagPattern);

// DROP 태그 조회
@Query("SELECT o FROM OpTagRel o WHERE o.plantCode = :plantCode
        AND o.tagType = 'DROP_PREFIX' AND o.isActive = true")
Optional<OpTagRel> findDropTagPattern(@Param("plantCode") String plantCode);
```

### OpCollectionConfigRepository
```java
Optional<OpCollectionConfig> findByPlantCode(String plantCode);
Optional<OpCollectionConfig> findByPlantCodeAndIsActiveTrue(String plantCode);
List<OpCollectionConfig> findByIsActiveTrue();
```

## 외부 API 응답 형식

### /operation/api/collection/full
```json
{
    "success": true,
    "collectionConfigs": [
        {
            "unitCode": "sp_03",
            "plantCode": "sp_03",
            "opcServer": {
                "serverIp": "192.168.0.2",
                "serverPort": 4840,
                "endpointUrl": "/OPC",
                "authType": "ANONYMOUS"
            },
            "tags": [
                {
                    "tagType": "POWER",
                    "tagPattern": "SP03_GENMW",
                    "description": "3호기 발전량",
                    "tagUnit": "MW",
                    "nodeId": "ns=2;s=SP03_GENMW",
                    "targetIp": null
                }
            ]
        }
    ],
    "timestamp": "2025-10-11T18:30:45.123"
}
```

## 연관 문서

- 시스템 설정: `docs/setting-system-config-system.md` (zone3 설정)
- 감사 로그: `docs/audit-log-system.md`
- 운전정보 데이터: `docs/data-operation-system.md`

---

## 프로그램 명세서

### OPT_001 - 운전정보 수집 설정 페이지

| 프로그램 ID | OPT_001 | 프로그램명 | 운전정보 수집 설정 페이지 |
|------------|---------|----------|---------------------|
| 분류 | 설정 | 처리유형 | 화면 |
| 클래스명 | SettingController / OperationController | 메서드명 | collectionOpTag() |

▣ 기능 설명

OPC UA 서버 연동을 위한 태그 설정 페이지를 렌더링한다. 수집용/송부용 탭과 호기별(3호기/4호기) 탭으로 구성.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 입력 항목 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | HTML | 수집 설정 페이지 | String | Y | Thymeleaf 렌더링 HTML |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | collectionOpTag.html 렌더링 | |
| 2 | 기본 탭: 운전정보 수집 > 3호기 | |

---

### OPT_002 - 목적별 태그 목록 조회

| 프로그램 ID | OPT_002 | 프로그램명 | 목적별 태그 목록 조회 |
|------------|---------|----------|------------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | OperationController | 메서드명 | getTags() |

▣ 기능 설명

수집용 또는 송부용 태그 목록을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | purpose | 태그 목적 | String | Y | COLLECTION 또는 TRANSFER |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | data | 태그 목록 | List | Y | OpTagRel 배열 |
| 3 | data[].id | 태그 ID | Long | Y | PK |
| 4 | data[].plantCode | 호기 코드 | String | Y | sp_03/sp_04 |
| 5 | data[].tagType | 태그 유형 | String | Y | POWER, TURBINE_SPEED 등 |
| 6 | data[].tagPattern | 태그 패턴 | String | Y | |
| 7 | data[].tagUnit | 단위 | String | N | MW, RPM 등 |
| 8 | data[].description | 설명 | String | N | |
| 9 | data[].nodeId | 노드 ID | String | Y | OPC UA 경로 |
| 10 | data[].isActive | 활성 여부 | Boolean | Y | |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | purpose 파라미터로 TagPurpose 변환 | |
| 2 | 해당 목적의 태그 목록 조회 | OpTagRelRepository |
| 3 | 목록 반환 | |

---

### OPT_003 - 태그 단일 수정/추가

| 프로그램 ID | OPT_003 | 프로그램명 | 태그 단일 수정/추가 |
|------------|---------|----------|-----------------|
| 분류 | 설정 | 처리유형 | 등록/수정 |
| 클래스명 | OperationController | 메서드명 | updateTag() |

▣ 기능 설명

태그 정보를 추가하거나 수정한다. id가 있으면 수정, 없으면 신규 등록.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 태그 ID | Long | N | 수정 시 필수 |
| 2 | plantCode | 호기 코드 | String | Y | sp_03/sp_04 |
| 3 | tagType | 태그 유형 | String | Y | TagType enum |
| 4 | tagPattern | 태그 패턴 | String | Y | |
| 5 | description | 설명 | String | N | |
| 6 | tagUnit | 단위 | String | N | |
| 7 | nodeId | 노드 ID | String | N | 자동 생성 가능 |
| 8 | namespaceIndex | 네임스페이스 | Integer | N | 기본값 2 |
| 9 | targetIp | 대상 IP | String | N | DROP/TRAFFIC만 |
| 10 | isActive | 활성 여부 | Boolean | Y | |
| 11 | tagPurpose | 태그 목적 | String | Y | COLLECTION/TRANSFER |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공, 1=실패 |
| 2 | message | 메시지 | String | Y | 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 중복 검사 | plantCode + tagType + tagPattern |
| 2 | targetIp 처리 | DROP/TRAFFIC만 허용 |
| 3 | nodeId 자동 생성 | 없으면 ns=2;s={tagPattern} |
| 4 | 태그 저장 | OpTagRelRepository |
| 5 | 캐시 무효화 | @CacheEvict |
| 6 | 감사 로그 기록 | @ActivityLog |

---

### OPT_004 - 태그 삭제

| 프로그램 ID | OPT_004 | 프로그램명 | 태그 삭제 |
|------------|---------|----------|---------|
| 분류 | 설정 | 처리유형 | 삭제 |
| 클래스명 | OperationController | 메서드명 | deleteTag() |

▣ 기능 설명

태그를 삭제한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 태그 ID | Long | Y | RequestBody |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | message | 메시지 | String | Y | 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 태그 존재 여부 확인 | |
| 2 | 태그 삭제 | OpTagRelRepository |
| 3 | 캐시 무효화 | @CacheEvict |
| 4 | 감사 로그 기록 | @ActivityLog |

---

### OPT_005 - 태그 일괄 저장

| 프로그램 ID | OPT_005 | 프로그램명 | 태그 일괄 저장 |
|------------|---------|----------|-------------|
| 분류 | 설정 | 처리유형 | 등록/수정 |
| 클래스명 | OperationController | 메서드명 | bulkUpdateTags() |

▣ 기능 설명

수정된 모든 태그를 일괄 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | tags | 태그 목록 | List | Y | RequestBody 배열 |
| 2 | tags[].id | 태그 ID | Long | N | |
| 3 | tags[].plantCode | 호기 코드 | String | Y | |
| 4 | tags[].tagType | 태그 유형 | String | Y | |
| 5 | tags[].tagPattern | 태그 패턴 | String | Y | |
| 6 | tags[].* | 기타 필드 | - | - | OPT_003 참조 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | message | 메시지 | String | Y | 저장 건수 포함 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 각 태그 유효성 검증 | |
| 2 | 중복 검사 | |
| 3 | 일괄 저장 | saveAll() |
| 4 | 캐시 전체 무효화 | allEntries = true |
| 5 | 감사 로그 기록 | BULK_UPDATE |

---

### OPT_006 - 변경 이력 조회

| 프로그램 ID | OPT_006 | 프로그램명 | 변경 이력 조회 |
|------------|---------|----------|-------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | OperationController | 메서드명 | getChangeLog() |

▣ 기능 설명

태그 설정 변경 이력을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | category | 카테고리 | String | Y | OpTagInfo |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | data | 이력 목록 | List | Y | ActivityLog 배열 |
| 3 | data[].createdAt | 변경일시 | LocalDateTime | Y | |
| 4 | data[].action | 액션 | String | Y | UPDATE/DELETE 등 |
| 5 | data[].userId | 사용자 ID | String | Y | |
| 6 | data[].details | 상세 내용 | String | N | |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 카테고리별 감사 로그 조회 | ActivityLogRepository |
| 2 | 최신순 정렬 | |
| 3 | 이력 목록 반환 | |

---

### OPT_007 - 수집 OPC 서버 설정 저장

| 프로그램 ID | OPT_007 | 프로그램명 | 수집 OPC 서버 설정 저장 |
|------------|---------|----------|---------------------|
| 분류 | 설정 | 처리유형 | 등록/수정 |
| 클래스명 | OperationController | 메서드명 | saveCollectionConfig() |

▣ 기능 설명

수집용 OPC UA 서버 연결 정보를 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | plantCode | 호기 코드 | String | Y | sp_03/sp_04 |
| 2 | serverIp | 서버 IP | String | Y | |
| 3 | serverPort | 서버 포트 | Integer | Y | 기본값 4840 |
| 4 | endpointUrl | 엔드포인트 | String | Y | 기본값 /OPC |
| 5 | authType | 인증 타입 | String | Y | ANONYMOUS 등 |
| 6 | username | 사용자명 | String | N | USER_PASSWORD 시 |
| 7 | password | 비밀번호 | String | N | USER_PASSWORD 시 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | message | 메시지 | String | Y | 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 기존 설정 조회 | plantCode로 |
| 2 | 있으면 수정, 없으면 신규 등록 | |
| 3 | 설정 저장 | OpCollectionConfigRepository |
| 4 | 캐시 무효화 | @CacheEvict |
| 5 | 감사 로그 기록 | @ActivityLog |

---

### OPT_008 - 송부 OPC 서버 설정 저장

| 프로그램 ID | OPT_008 | 프로그램명 | 송부 OPC 서버 설정 저장 |
|------------|---------|----------|---------------------|
| 분류 | 설정 | 처리유형 | 등록/수정 |
| 클래스명 | OperationController | 메서드명 | saveTransferConfig() |

▣ 기능 설명

송부용 OPC UA 서버 연결 정보를 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | plantCode | 호기 코드 | String | Y | sp_03/sp_04 |
| 2 | serverIp | 서버 IP | String | Y | |
| 3 | serverPort | 서버 포트 | Integer | Y | |
| 4 | endpointUrl | 엔드포인트 | String | Y | |
| 5 | authType | 인증 타입 | String | Y | |
| 6 | username | 사용자명 | String | N | |
| 7 | password | 비밀번호 | String | N | |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | message | 메시지 | String | Y | 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 기존 설정 조회 | |
| 2 | 설정 저장/수정 | OpTransferConfigRepository |
| 3 | 캐시 전체 무효화 | allEntries = true |
| 4 | 감사 로그 기록 | @ActivityLog |

---

### OPT_009 - 수집 OPC 서버 설정 조회

| 프로그램 ID | OPT_009 | 프로그램명 | 수집 OPC 서버 설정 조회 |
|------------|---------|----------|---------------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | OperationController | 메서드명 | getCollectionConfig() |

▣ 기능 설명

호기별 수집용 OPC 서버 설정을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | plantCode | 호기 코드 | String | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | data | 서버 설정 | Object | N | OpCollectionConfig |
| 3 | data.serverIp | 서버 IP | String | Y | |
| 4 | data.serverPort | 서버 포트 | Integer | Y | |
| 5 | data.endpointUrl | 엔드포인트 | String | Y | |
| 6 | data.authType | 인증 타입 | String | Y | |
| 7 | data.connectionStatus | 연결 상태 | String | N | CONNECTED/DISCONNECTED |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | plantCode로 설정 조회 | OpCollectionConfigRepository |
| 2 | 설정 반환 (없으면 null) | |

---

### OPT_010 - 송부 OPC 서버 설정 조회

| 프로그램 ID | OPT_010 | 프로그램명 | 송부 OPC 서버 설정 조회 |
|------------|---------|----------|---------------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | OperationController | 메서드명 | getTransferConfig() |

▣ 기능 설명

호기별 송부용 OPC 서버 설정을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | plantCode | 호기 코드 | String | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | data | 서버 설정 | Object | N | OpTransferConfig |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | plantCode로 설정 조회 | OpTransferConfigRepository |
| 2 | 설정 반환 | |

---

### OPT_011 - 전체 수집 설정 조회 (외부 API)

| 프로그램 ID | OPT_011 | 프로그램명 | 전체 수집 설정 조회 |
|------------|---------|----------|-----------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | OperationApiController | 메서드명 | getCollectionFull() |

▣ 기능 설명

외부 수집 서버에서 OPC 서버 설정과 태그 목록을 조회한다. 인증 불필요.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 입력 항목 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공여부 | Boolean | Y | true/false |
| 2 | collectionConfigs | 수집 설정 목록 | List | Y | 호기별 설정 |
| 3 | collectionConfigs[].unitCode | 호기 코드 | String | Y | |
| 4 | collectionConfigs[].opcServer | OPC 서버 설정 | Object | Y | IP, 포트, 인증 |
| 5 | collectionConfigs[].tags | 태그 목록 | List | Y | 활성 태그만 |
| 6 | timestamp | 조회 시간 | String | Y | ISO 형식 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 캐시된 수집 설정 조회 | @Cacheable |
| 2 | 호기별 OPC 설정 + 태그 조합 | |
| 3 | 활성 태그만 필터링 | isActive = true |
| 4 | JSON 응답 반환 | |

---

### OPT_012 - 전체 송부 설정 조회 (외부 API)

| 프로그램 ID | OPT_012 | 프로그램명 | 전체 송부 설정 조회 |
|------------|---------|----------|-----------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | OperationApiController | 메서드명 | getTransferTags() |

▣ 기능 설명

외부 분석 서버에서 송부용 OPC 설정과 태그 목록을 조회한다. 인증 불필요.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 입력 항목 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공여부 | Boolean | Y | true/false |
| 2 | transferConfigs | 송부 설정 목록 | List | Y | 호기별 설정 |
| 3 | transferConfigs[].unitCode | 호기 코드 | String | Y | |
| 4 | transferConfigs[].opcServer | OPC 서버 설정 | Object | Y | |
| 5 | transferConfigs[].tags | 태그 목록 | List | Y | 활성 태그만 |
| 6 | timestamp | 조회 시간 | String | Y | |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 캐시된 송부 설정 조회 | @Cacheable |
| 2 | 호기별 설정 조합 | |
| 3 | 활성 태그만 필터링 | |
| 4 | JSON 응답 반환 | |
