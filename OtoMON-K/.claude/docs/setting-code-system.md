# 코드 관리 (setting/code) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/setting/code` |
| **메뉴 ID** | 9000L |
| **권한** | READ/WRITE/DELETE |
| **한글명** | 코드 관리 |
| **목적** | 시스템 코드 관리 (사업소/발전소/호기 등 계층적 코드 구조 관리) |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/SettingController.java
            src/main/java/com/otoones/otomon/controller/CodeController.java
Service:    src/main/java/com/otoones/otomon/service/CodeService.java
Template:   src/main/resources/templates/pages/setting/code.html
Model:      src/main/java/com/otoones/otomon/model/Code.java
            src/main/java/com/otoones/otomon/model/CodeGroup.java
            src/main/java/com/otoones/otomon/model/CodeType.java
DTO:        src/main/java/com/otoones/otomon/dto/CodeDto.java
            src/main/java/com/otoones/otomon/dto/CodeMenuHierarchyDto.java
            src/main/java/com/otoones/otomon/dto/CodeTypeCodeDto.java
Mapper:     src/main/java/com/otoones/otomon/mapper/CodeMapper.java
```

---

## 코드 계층 구조

시스템은 3계층 구조로 코드를 관리:

```
CodeGroup (1단계 탭)
    └── CodeType (2단계 탭)
            └── Code (테이블 행)
```

### 예시 구조

```
사업장 (CodeGroup: workplace)
    ├── zone1 (CodeType: 사업소)
    │   └── koen (Code: 한국동서발전)
    ├── zone2 (CodeType: 발전소)
    │   └── samcheonpo (Code: 삼천포발전소, parentCode: koen)
    └── zone3 (CodeType: 호기)
        ├── unit3 (Code: 3호기, parentCode: samcheonpo)
        └── unit4 (Code: 4호기, parentCode: samcheonpo)
```

---

## 컨트롤러

### SettingController (`GET /setting/code`)

**위치**: `SettingController.java:93-105`

**권한**:
```java
@RequirePermission(menuId = 9000L)
```

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| codeMenus | CodeGroup별 계층 구조 (Map<String, CodeMenuHierarchyDto>) |
| zone2List | zone2(발전소) 목록 (호기 추가 시 드롭다운용) |

### CodeController (`/code`)

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/code/searchCodeList` | 코드 목록 검색 |
| POST | `/code/saveCode` | 새 코드 추가 |
| POST | `/code/editCode` | 코드 수정 |
| POST | `/code/updateCode` | 코드 업데이트 (레거시) |
| POST | `/code/deleteCode` | 코드 삭제 |

---

## 프론트엔드 (code.html)

### 페이지 레이아웃

```
┌─────────────────────────────────────────────────────────────┐
│ 1단계 탭 (nav-tabs): 사업장 | 이벤트 | 시스템              │
├─────────────────────────────────────────────────────────────┤
│ 2단계 탭 (nav-pills): 사업소 | 발전소 | 호기               │
├─────────────────────────────────────────────────────────────┤
│ 제목 + [추가] 버튼                                          │
├───────────┬────────────────┬──────────────────┬─────────────┤
│ 순서      │ 코드           │ 값               │ 관리        │
├───────────┼────────────────┼──────────────────┼─────────────┤
│ 1         │ koen           │ 한국동서발전     │ [수정][삭제]│
│ 2         │ ...            │ ...              │ [수정][삭제]│
└───────────┴────────────────┴──────────────────┴─────────────┘
```

### 탭 구조

**1단계 탭 (CodeGroup)**:
- Bootstrap nav-tabs
- `data-bs-toggle="tab"`
- 탭 ID: `${entry.key}-content` (예: `workplace-content`)

**2단계 탭 (CodeType)**:
- Bootstrap nav-pills
- `data-bs-toggle="pill"`
- 탭 ID: `${entry.key}-${typeDto.codeType.code}-content` (예: `workplace-zone1-content`)

### 모달 (code_add_modal)

동적으로 생성되는 추가/수정 모달:

**추가 모드 필드 설정** (`codeFieldConfig`):

| codeType | 필드 구성 |
|----------|----------|
| zone1 | code (사업소 코드), value (사업소명) |
| zone2 | code (발전소 코드), value (발전소명), parentCode (상위 사업소 선택) |
| zone3 | parentCode (발전소 선택), code (코드), value (호기명) |

**수정 모드 필드**:
| 필드 | ID | 설명 |
|------|-----|------|
| idx | code_idx | PK (hidden) |
| code | code_code | 코드 |
| displayOrder | code_display_order | 메뉴순서 |
| parentCode | code_parent_code | 부모코드 |
| typeCode | code_type_code | 코드타입 |
| value | code_value | 이름 |

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `addCodeModal(button)` | 추가 모달 오픈 + 필드 동적 생성 |
| `editCode(button)` | 수정 모달 오픈 |
| `saveCode(codeType)` | 코드 저장 (POST /code/saveCode) |
| `editCodeRequest()` | 코드 수정 (POST /code/editCode) |
| `deleteCode(button)` | 코드 삭제 (POST /code/deleteCode) |

---

## 모델

### CodeGroup (코드 그룹)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| idx | Long | idx | PK |
| code | String | code | 그룹 코드 (예: workplace) |
| name | String | name | 그룹명 (예: 사업장) |
| displayOrder | String | display_order | 표시 순서 |
| isShow | Boolean | is_show | 표시 여부 |

### CodeType (코드 타입)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| idx | Long | idx | PK |
| groupCode | String | group_code | 소속 그룹 코드 |
| code | String | code | 타입 코드 (예: zone1, zone2) |
| name | String | name | 타입명 (예: 사업소, 발전소) |
| parentType | String | parent_type | 부모 타입 코드 |
| displayOrder | String | display_order | 표시 순서 |

### Code (코드)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| idx | Long | idx | PK |
| typeCode | String | type_code | 소속 타입 코드 |
| code | String | code | 코드 값 (예: koen, unit3) |
| value | String | value | 표시값 (예: 한국동서발전, 3호기) |
| parentCode | String | parent_code | 부모 코드 |
| displayOrder | String | display_order | 표시 순서 |

---

## DTO

### CodeDto

요청 데이터 DTO:

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| codeType | String | O | 코드 타입 |
| idx | String | X | PK (수정 시) |
| code | String | O | 코드 값 |
| value | String | O | 표시값 |
| parentCode | String | O | 부모 코드 |

### CodeMenuHierarchyDto

계층 구조 DTO:
```java
public class CodeMenuHierarchyDto {
    private CodeGroup codeGroup;
    private List<CodeTypeCodeDto> codeTypeCodeDtos;
}
```

### CodeTypeCodeDto

타입별 코드 목록 DTO:
```java
public class CodeTypeCodeDto {
    private CodeType codeType;
    private List<Code> code;
}
```

---

## 서비스 (CodeService.java)

### 주요 메서드

| 메서드 | 위치 | 설명 |
|--------|------|------|
| `codeMenuList()` | 39줄 | 전체 코드 메뉴 계층 조회 |
| `getCodeMenuHierarchy()` | 91줄 | 그룹별 계층 구조 조회 |
| `zone2GroupList()` | 31줄 | zone2 목록 조회 |
| `AddCodeGroup()` | 186줄 | 새 코드 추가 |
| `editCode()` | 56줄 | 코드 수정 |
| `deleteCode()` | 155줄 | 코드 삭제 |

### 중복 체크 로직

```java
// 부모코드 없는 경우: 전체에서 중복 체크
if(codeRepository.existsByCode(codeDto.getCode()))
    throw new RuntimeException("중복");

// 부모코드 있는 경우: 같은 타입 내에서만 중복 체크
if (codeRepository.existsByTypeCodeAndCode(codeType, code))
    throw new RuntimeException("중복");
```

### Zone3 삭제 제약

호기(zone3) 삭제 시 특별한 제약 적용:

```java
if("zone3".equals(code.getTypeCode())){
    // 1. 시스템 설정에서 활성화된 호기인지 확인
    boolean isActive = isZoneActiveInConfig(code.getCode());

    // 2. 활성화된 호기면 삭제 불가
    if(isActive){
        // 마지막 활성 호기인 경우 삭제 불가
        int activeZoneCount = getActiveZoneCount();
        if(activeZoneCount <= 1)
            throw new RuntimeException("마지막 호기는 삭제 불가");
        throw new RuntimeException("활성화된 호기 삭제 불가");
    }

    // 3. 현재 세션에서 선택된 호기면 삭제 불가
    if(selectedZoneCode.equals(code.getCode()))
        throw new RuntimeException("현재 선택된 호기 삭제 불가");
}
```

---

## API 엔드포인트 요약

| 메서드 | URL | 권한 | 설명 |
|--------|-----|------|------|
| GET | `/setting/code` | 9000L READ | 페이지 렌더링 |
| GET | `/code/searchCodeList` | - | 코드 목록 검색 |
| POST | `/code/saveCode` | - | 코드 생성 |
| POST | `/code/editCode` | - | 코드 수정 |
| POST | `/code/deleteCode` | - | 코드 삭제 |

---

## 데이터 흐름

### 페이지 로드

```
[Controller] /setting/code
         ↓
[CodeService] codeMenuList()
         ↓
[Repository] findAllByIsShowTrueOrderByDisplayOrder() → CodeGroup 목록
         ↓
[CodeService] getCodeMenuHierarchy(groupCode) per CodeGroup
         ↓
[Repository] findByGroupCodeOrderByDisplayOrder() → CodeType 목록
         ↓
[Repository] findByTypeCodeOrderByDisplayOrder() → Code 목록
         ↓
[DTO] CodeMenuHierarchyDto 조합
         ↓
[Template] 2단계 탭 + 테이블 렌더링
```

### 코드 추가

```
[모달] addCodeModal() → 필드 동적 생성
         ↓
[사용자] 폼 입력
         ↓
[JS] saveCode(codeType)
         ↓
[AJAX] POST /code/saveCode
         ↓
[Controller] saveCode() → CodeService.AddCodeGroup()
         ↓
[Service] 중복 체크 + displayOrder 계산 + 저장
         ↓
[ActivityLog] 감사 로그 기록
         ↓
[JS] location.reload()
```

### 코드 삭제

```
[버튼] deleteCode(button)
         ↓
[confirm] 삭제 확인 다이얼로그
         ↓
[AJAX] POST /code/deleteCode?idx=123
         ↓
[Controller] deleteCode()
         ↓
[Service] zone3 제약 체크
         ↓
[Repository] groupCodeMappingRepository.deleteByCodeIdx() → 권한 연결 삭제
[Repository] codeRepository.deleteById() → 코드 삭제
         ↓
[ActivityLog] 감사 로그 기록
         ↓
[JS] location.reload()
```

---

## 감사 로그

`@ActivityLog` 어노테이션으로 CRUD 작업 자동 기록:

| 작업 | category | action | resourceType |
|------|----------|--------|--------------|
| 생성 | CODE | CREATE | CODE |
| 수정 | CODE | EDIT | CODE |
| 삭제 | CODE | DELETE | CODE |

---

## 권한 처리

프론트엔드에서 권한에 따라 버튼 표시/숨김:

```html
<!-- 추가 버튼: WRITE 권한 필요 -->
<button th:if="${userPermissions?.canWrite}">추가</button>

<!-- 수정 버튼: WRITE 권한 필요 -->
<button th:if="${userPermissions?.canWrite}">수정</button>

<!-- 삭제 버튼: DELETE 권한 필요 -->
<button th:if="${userPermissions?.canDelete}">삭제</button>
```

---

## 다국어 메시지

| 메시지 키 | 설명 |
|----------|------|
| `menu.setting.code` | 페이지 제목 |
| `setting.codeManagement.table.col1~4` | 테이블 헤더 |
| `setting.codeManagement.delete.confirm` | 삭제 확인 메시지 |
| `setting.codeManagement.add.success` | 저장 성공 메시지 |
| `button.added` | 추가 버튼 |
| `button.edit` | 수정 버튼 |
| `button.delete` | 삭제 버튼 |
| `button.close` | 닫기 버튼 |

---

## 관련 문서

- [권한 시스템](permission-system.md) - 코드별 권한 관리
- [감사 로그](audit-log-system.md) - 코드 변경 이력
- [시스템 설정](setting-system-config.md) - zone3 활성화 설정

---

## 프로그램 명세서

### SCO_001 - 코드관리 페이지

| 프로그램 ID | SCO_001 | 프로그램명 | 코드관리 페이지 |
|------------|---------|----------|--------------|
| 분류 | 설정 관리 | 처리유형 | 화면 |
| 클래스명 | SettingController.java | 메서드명 | codePage() |

▣ 기능 설명

시스템 코드를 관리하는 페이지를 렌더링한다. 사업장/발전소/호기 등 계층적 코드 구조를 2단계 탭(CodeGroup → CodeType) 형태로 표시하며, 각 코드에 대한 CRUD 기능을 제공한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 파라미터 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | codeMenus | 코드 메뉴 계층 | Map<String, CodeMenuHierarchyDto> | Y | CodeGroup별 계층 구조 |
| 2 | zone2List | 발전소 목록 | List<Code> | Y | 호기 추가 시 드롭다운용 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | @RequirePermission(menuId = 9000L) |
| 2 | CodeGroup 목록 조회 | isShow=true, displayOrder 정렬 |
| 3 | 각 CodeGroup별 계층 구조 조회 | getCodeMenuHierarchy() |
| 4 | zone2 목록 조회 | zone2GroupList() |
| 5 | Model에 데이터 추가 및 뷰 반환 | pages/setting/code |

---

### SCO_002 - 코드 목록 검색 API

| 프로그램 ID | SCO_002 | 프로그램명 | 코드 목록 검색 API |
|------------|---------|----------|------------------|
| 분류 | 코드 조회 | 처리유형 | 조회 |
| 클래스명 | CodeController.java | 메서드명 | searchCodeList() |

▣ 기능 설명

특정 코드 타입에 속한 코드 목록을 조회한다. 검색어를 기준으로 필터링 가능하다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | typeCode | 코드 타입 | String | Y | zone1, zone2, zone3 등 |
| 2 | keyword | 검색어 | String | N | 코드/값 검색 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 코드 목록 | List<Code> | Y | 코드 목록 |
| 3 | data[].idx | PK | Long | Y | 코드 ID |
| 4 | data[].code | 코드 | String | Y | 코드 값 |
| 5 | data[].value | 표시값 | String | Y | 이름 |
| 6 | data[].parentCode | 부모 코드 | String | N | 상위 코드 |
| 7 | data[].displayOrder | 표시 순서 | String | Y | 정렬 순서 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | typeCode로 코드 조회 | findByTypeCodeOrderByDisplayOrder() |
| 2 | 검색어 있으면 필터링 적용 | code/value 부분 일치 |
| 3 | 결과 반환 | JSON 응답 |

---

### SCO_003 - 코드 생성 API

| 프로그램 ID | SCO_003 | 프로그램명 | 코드 생성 API |
|------------|---------|----------|-------------|
| 분류 | 코드 관리 | 처리유형 | 등록 |
| 클래스명 | CodeController.java | 메서드명 | saveCode() |

▣ 기능 설명

새로운 코드를 생성한다. 중복 체크를 수행하고, displayOrder를 자동 계산하여 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | codeType | 코드 타입 | String | Y | zone1, zone2, zone3 등 |
| 2 | code | 코드 | String | Y | 코드 값 |
| 3 | value | 표시값 | String | Y | 이름 |
| 4 | parentCode | 부모 코드 | String | △ | zone2, zone3의 경우 필수 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 생성된 코드 | Code | N | 성공 시 코드 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 중복 체크 | 부모코드 없으면 전체, 있으면 타입 내 중복 체크 |
| 3 | displayOrder 계산 | 해당 타입의 마지막 순서 + 1 |
| 4 | Code Entity 생성 및 저장 | codeRepository.save() |
| 5 | 감사 로그 기록 | @ActivityLog(CREATE) |
| 6 | 결과 반환 | JSON 응답 |

---

### SCO_004 - 코드 수정 API

| 프로그램 ID | SCO_004 | 프로그램명 | 코드 수정 API |
|------------|---------|----------|-------------|
| 분류 | 코드 관리 | 처리유형 | 수정 |
| 클래스명 | CodeController.java | 메서드명 | editCode() |

▣ 기능 설명

기존 코드의 정보를 수정한다. 코드 값, 표시값, 표시 순서 등을 변경할 수 있다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | PK | String | Y | 수정할 코드 ID |
| 2 | codeType | 코드 타입 | String | Y | 코드 타입 |
| 3 | code | 코드 | String | Y | 코드 값 |
| 4 | value | 표시값 | String | Y | 이름 |
| 5 | displayOrder | 표시 순서 | String | N | 정렬 순서 |
| 6 | parentCode | 부모 코드 | String | N | 상위 코드 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 수정된 코드 | Code | N | 성공 시 코드 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 코드 존재 확인 | findById() |
| 3 | 중복 체크 (자신 제외) | 다른 코드와 중복 여부 |
| 4 | 코드 정보 업데이트 | - |
| 5 | 저장 | codeRepository.save() |
| 6 | 감사 로그 기록 | @ActivityLog(EDIT) |
| 7 | 결과 반환 | JSON 응답 |

---

### SCO_005 - 코드 삭제 API

| 프로그램 ID | SCO_005 | 프로그램명 | 코드 삭제 API |
|------------|---------|----------|-------------|
| 분류 | 코드 관리 | 처리유형 | 삭제 |
| 클래스명 | CodeController.java | 메서드명 | deleteCode() |

▣ 기능 설명

코드를 삭제한다. zone3(호기)의 경우 활성화 상태, 현재 세션 선택 여부, 마지막 호기 여부 등 특별한 제약 조건을 확인한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | PK | Long | Y | 삭제할 코드 ID |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과/오류 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | DELETE 권한 필요 |
| 2 | 코드 존재 확인 | findById() |
| 3 | zone3 제약 조건 확인 | 활성화/현재 선택/마지막 호기 체크 |
| 4 | 권한 연결 삭제 | groupCodeMappingRepository.deleteByCodeIdx() |
| 5 | 코드 삭제 | codeRepository.deleteById() |
| 6 | 감사 로그 기록 | @ActivityLog(DELETE) |
| 7 | 결과 반환 | JSON 응답 |

▣ Zone3 삭제 제약 조건

| 조건 | 오류 메시지 | 설명 |
|------|------------|------|
| 시스템 설정에서 활성화된 호기 | "활성화된 호기 삭제 불가" | system_config에서 사용 중 |
| 마지막 활성 호기 | "마지막 호기는 삭제 불가" | 활성 호기가 1개만 남음 |
| 현재 세션에서 선택된 호기 | "현재 선택된 호기 삭제 불가" | 세션의 selectedZoneCode |

