# 금지 서비스 포트 관리 (policy/servicePortPolicy) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/policy/servicePortPolicy` |
| **메뉴 ID** | 6060L |
| **권한** | READ/WRITE/DELETE |
| **한글명** | 금지 서비스 포트 관리 |
| **목적** | 네트워크 보안을 위한 금지 포트 정책 관리 (SSH, Telnet, RDP 등) |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/PolicyController.java
Service:    src/main/java/com/otoones/otomon/service/ServicePortPolicyService.java
Template:   src/main/resources/templates/pages/policy/servicePortPolicy.html
JavaScript: src/main/resources/static/js/page.policy/servicePortPolicy.js (328 lines)
Model:      src/main/java/com/otoones/otomon/model/ServicePortPolicy.java
DTO:        src/main/java/com/otoones/otomon/dto/ServicePortPolicyDto.java
Repository: src/main/java/com/otoones/otomon/repository/ServicePortPolicyRepository.java
Aspect:     src/main/java/com/otoones/otomon/aspect/ServicePortPolicyActivityLogExtractor.java
```

---

## 컨트롤러 (PolicyController.java)

### 페이지 렌더링 (`GET /policy/servicePortPolicy`)

**위치**: `PolicyController.java:677-689`

**권한**:
```java
@RequirePermission(menuId = 6060L, resourceType = ResourceType.MENU, permissionType = PermissionType.READ)
```

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| zone3 | 세션에서 가져온 호기 코드 |

### CRUD API

| 메서드 | URL | 위치 | 권한 | @ActivityLog | 설명 |
|--------|-----|------|------|--------------|------|
| GET | `/api/servicePortPolicy/list` | :691-707 | 6060L READ | - | 정책 목록 조회 |
| POST | `/api/servicePortPolicy` | :710-751 | 6060L WRITE | - | 정책 생성 |
| PUT | `/api/servicePortPolicy/{id}` | :753-795 | 6060L WRITE | - | 정책 수정 |
| DELETE | `/api/servicePortPolicy/{id}` | :797-823 | 6060L DELETE | - | 정책 삭제 |
| DELETE | `/api/servicePortPolicy/batch` | :825-842 | 6060L DELETE | - | 대량 삭제 |
| GET | `/api/servicePortPolicies` | :846-850 | - | - | 분석 서버용 조회 |

### 응답 형식

```json
{
  "ret": 0,
  "message": "처리 메시지",
  "data": { ServicePortPolicyDto }
}
```

### 메시지 코드

| 코드 | 설명 |
|------|------|
| `POLICY_PROHIBITED_SERVICE_PORT_ADD_SUCCESS` | 생성 성공 |
| `POLICY_PROHIBITED_SERVICE_PORT_EDIT_SUCCESS` | 수정 성공 |
| `POLICY_PROHIBITED_SERVICE_PORT_DELETED_SUCCESS` | 삭제 성공 |
| `POLICY_PROHIBITED_SERVICE_PORT_DELETED_BULK_SUCCESS` | 대량 삭제 성공 |

---

## 서비스 (ServicePortPolicyService.java)

### 주요 메서드

| 메서드명 | 위치 | 기능 | @ActivityLog |
|---------|------|------|-------------|
| `getServicePortPolicies()` | :86-91 | 구역별 활성 정책 조회 | - |
| `createServicePortPolicy()` | :94-107 | 정책 생성 | ✅ CREATE |
| `updateServicePortPolicy()` | :110-133 | 정책 수정 | ✅ UPDATE |
| `deleteServicePortPolicy()` | :136-142 | 정책 삭제 (소프트) | ✅ DELETE |
| `deleteMultipleServicePortPolicies()` | :146-155 | 대량 삭제 | ✅ BATCH_DELETE |
| `getServicePortPoliciesForAnalysis()` | :160-182 | 분석용 전체 정책 조회 | - |

### getServicePortPolicies() 상세

```java
public List<ServicePortPolicyDto> getServicePortPolicies(String zone1, String zone2, String zone3) {
    List<ServicePortPolicy> policies = servicePortPolicyRepository.findByZonesAndIsShowTrue(zone1, zone2, zone3);
    return policies.stream()
            .map(ServicePortPolicyDto::fromEntity)
            .collect(Collectors.toList());
}
```

### createServicePortPolicy() 상세

```java
@ActivityLog(category = "POLICY_MANAGE", action = "CREATE", resourceType = "SERVICE_PORT_POLICY")
public ServicePortPolicyDto createServicePortPolicy(ServicePortPolicyDto dto)
```

1. **중복 체크** - zone1, zone2, zone3, port 조합 검사
2. **Entity 생성** - `dto.toEntity()`
3. **DB 저장** - `servicePortPolicyRepository.save(entity)`

### deleteServicePortPolicy() 상세

```java
@ActivityLog(category = "POLICY_MANAGE", action = "DELETE", resourceType = "SERVICE_PORT_POLICY")
public void deleteServicePortPolicy(Long id)
```

- **소프트 삭제**: `isShow = false` 설정 (실제 삭제 안함)

### deleteMultipleServicePortPolicies() 상세

```java
@Transactional
@ActivityLog(category = "POLICY_MANAGE", action = "BATCH_DELETE", resourceType = "SERVICE_PORT_POLICY")
public int deleteMultipleServicePortPolicies(List<Long> ids)
```

- **물리 삭제**: `deleteById()` 사용 (소프트 삭제 아님)

---

## Repository 호출 패턴

### ServicePortPolicyRepository

| 메서드 | 호출 위치 | 용도 |
|--------|---------|------|
| `findByZonesAndIsShowTrue()` | :87 | 구역별 정책 조회 (Native Query) |
| `existsByZone1AndZone2AndZone3AndPortAndIsShowTrue()` | :95, 115 | 중복 정책 체크 |
| `findByIdAndIsShowTrue()` | :111, 137 | ID로 활성 정책 조회 |
| `save()` | :104, 131, 141 | Entity 저장 |
| `existsById()` | :149 | ID 존재 여부 확인 |
| `deleteById()` | :150 | 물리 삭제 |
| `findByIsShowTrueOrderByPortAsc()` | :161 | 포트 순서로 전체 조회 |

### Native Query (동적 zone 필터링)

```sql
SELECT * FROM ServicePortPolicy
WHERE (:zone1 IS NULL OR zone1 = :zone1)
  AND (:zone2 IS NULL OR zone2 = :zone2)
  AND (:zone3 IS NULL OR zone3 = :zone3)
  AND is_show = true
ORDER BY port ASC
```

---

## DTO 변환

### Entity → DTO

```java
public static ServicePortPolicyDto fromEntity(ServicePortPolicy entity) {
    return ServicePortPolicyDto.builder()
            .id(entity.getId())
            .zone1(entity.getZone1())
            .zone2(entity.getZone2())
            .zone3(entity.getZone3())
            .port(entity.getPort())
            .serviceName(entity.getServiceName())
            .description(entity.getDescription())
            .createdAt(entity.getCreatedAt())
            .updatedAt(entity.getUpdatedAt())
            .userId(entity.getUserId())
            .isShow(entity.getIsShow())
            .build();
}
```

### DTO → Entity

```java
public ServicePortPolicy toEntity() {
    ServicePortPolicy entity = new ServicePortPolicy();
    entity.setZone1(this.zone1);
    entity.setZone2(this.zone2);
    entity.setZone3(this.zone3);
    entity.setPort(this.port);
    entity.setServiceName(this.serviceName);
    entity.setDescription(this.description);
    entity.setUserId(this.userId);
    entity.setIsShow(this.isShow != null ? this.isShow : true);  // 기본값 true
    return entity;
}
```

---

## 프론트엔드 (servicePortPolicy.js - 328줄)

### 주요 함수

| 함수명 | 위치 | 역할 |
|--------|------|------|
| `PageConfig.init()` | :13-21 | 페이지 설정 초기화 (zone3, 권한) |
| `deleteSelectedPolicies()` | :34-70 | 선택 항목 일괄 삭제 |
| `deletePolicy()` | :72-91 | 단일 항목 삭제 |
| `saveServicePortPolicy()` | :93-127 | 신규/수정 저장 |
| `editPolicy()` | :129-143 | 편집 모달 열기 |
| `showCreateModal()` | :145-151 | 신규 생성 모달 열기 |
| `loadServicePortPolicies()` | :153-173 | 데이터 조회 (필터 적용) |
| `initializeGrid()` | :175-312 | AG Grid 초기화 |

### AG Grid 설정

| 설정 | 값 |
|------|-----|
| 그리드 ID | `#servicePortPolicyGrid` |
| 테마 | `ag-theme-quartz` |
| 페이지네이션 | 20건 기본 |
| 행 선택 | 복수 선택 (multiple) |
| CSP Nonce | `styleNonce` 설정 |

### 컬럼 정의 (라인 176-270)

| 컬럼명 | 필드 | 너비 | 특징 |
|--------|------|------|------|
| 선택 | checkbox | 60px | 헤더 체크박스 |
| 번호 | rowIndex | 80px | rowIndex + 1 |
| Zone1 | zone1 | flex: 1 | 정렬/필터 |
| Zone2 | zone2 | flex: 1 | 정렬/필터 |
| Zone3 | zone3 | flex: 1 | 정렬/필터 |
| 포트 | port | 100px | 중앙 정렬 |
| 서비스명 | serviceName | flex: 1 | 정렬/필터 |
| 설명 | description | flex: 2 | 텍스트 줄바꿈 |
| 등록일 | createdAt | 150px | 한국 로케일 포맷 |
| 관리 | - | 120px | 수정/삭제 버튼 |

### API 호출 패턴

| 작업 | URL | 메서드 | 위치 |
|------|-----|--------|------|
| 조회 | `/policy/api/servicePortPolicy/list?` | GET | :164 |
| 신규 저장 | `/policy/api/servicePortPolicy` | POST | :105 |
| 수정 | `/policy/api/servicePortPolicy/{id}` | PUT | :104 |
| 삭제 | `/policy/api/servicePortPolicy/{id}` | DELETE | :75 |
| 대량 삭제 | `/policy/api/servicePortPolicy/{id}` | DELETE | :52 (각각) |

### 이벤트 위임 패턴

```javascript
// 라인 296-308: AG Grid onCellClicked
onCellClicked: function (params) {
    const target = params.event.target;
    const button = target.closest('button[data-action]');
    if (!button) return;

    const action = button.dataset.action;
    const id = parseInt(button.dataset.id, 10);

    if (action === 'edit') {
        editPolicy(id);
    } else if (action === 'delete') {
        deletePolicy(id);
    }
}
```

### CRUD 모달 처리

```javascript
// 신규 (라인 145-151)
function showCreateModal() {
    currentEditId = null;
    $('#modalTitle').text('금지포트 정책 등록');
    $('#servicePortPolicyForm')[0].reset();
    $('#servicePortPolicyModal').modal('show');
}

// 편집 (라인 129-143)
function editPolicy(id) {
    currentEditId = id;
    // 그리드에서 데이터 찾아서 폼에 채우기
    $('#servicePortPolicyModal').modal('show');
}

// 저장 (라인 93-127)
function saveServicePortPolicy() {
    const method = currentEditId ? 'PUT' : 'POST';
    const url = currentEditId
        ? `/policy/api/servicePortPolicy/${currentEditId}`
        : '/policy/api/servicePortPolicy';
    // AJAX 호출
}
```

---

## 권한 및 보안

### 권한 검사

| 기능 | Controller @RequirePermission | Service @ActivityLog |
|------|------------------------------|---------------------|
| 페이지 접근 | 6060L READ | - |
| 목록 조회 | 6060L READ | - |
| 정책 생성 | 6060L WRITE | ✅ CREATE |
| 정책 수정 | 6060L WRITE | ✅ UPDATE |
| 정책 삭제 | 6060L DELETE | ✅ DELETE |
| 대량 삭제 | 6060L DELETE | ✅ BATCH_DELETE |
| 분석 서버 조회 | - | - |

### 보안 처리

1. **CSRF 토큰**: 모든 AJAX 요청에 헤더 포함
2. **유효성 검사**: @Valid, @Positive 어노테이션 사용
3. **중복 체크**: zone + port 조합 중복 방지
4. **사용자 ID 설정**: Authentication에서 자동 추출

---

## API 엔드포인트 요약

| 메서드 | URL | 권한 | 위치 | 설명 |
|--------|-----|------|------|------|
| GET | `/policy/servicePortPolicy` | 6060L READ | :677 | 페이지 렌더링 |
| GET | `/policy/api/servicePortPolicy/list` | 6060L READ | :691 | 목록 조회 |
| POST | `/policy/api/servicePortPolicy` | 6060L WRITE | :710 | 생성 |
| PUT | `/policy/api/servicePortPolicy/{id}` | 6060L WRITE | :753 | 수정 |
| DELETE | `/policy/api/servicePortPolicy/{id}` | 6060L DELETE | :797 | 삭제 |
| DELETE | `/policy/api/servicePortPolicy/batch` | 6060L DELETE | :825 | 대량 삭제 |
| GET | `/policy/api/servicePortPolicies` | - | :846 | 분석 서버용 |

---

## 데이터 흐름

```
[Controller] 세션에서 zone3 조회 (:677-689)
         ↓
[Frontend] loadServicePortPolicies() AJAX 호출 (:153-173)
         ↓
[Controller] getServicePortPolicies() (:691-707)
         ↓
[Service] findByZonesAndIsShowTrue() (:86-91)
         ↓
[Repository] Native Query (동적 zone 필터링)
         ↓
[DTO] ServicePortPolicyDto.fromEntity()
         ↓
[Frontend] AG Grid 표시 + 이벤트 위임 패턴
```

---

## Entity 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| id | Long (PK) | 자동 증가 |
| zone1 | String | 구역1 (nullable) |
| zone2 | String | 구역2 (nullable) |
| zone3 | String | 구역3 (nullable) |
| port | Integer | 포트번호 (1-65535) |
| serviceName | String | 서비스명 |
| description | String | 설명 |
| userId | String | 생성/수정 사용자 |
| isShow | Boolean | 활성 여부 (기본값 true) |
| createdAt | LocalDateTime | 생성일시 (@CreationTimestamp) |
| updatedAt | LocalDateTime | 수정일시 (@UpdateTimestamp) |

---

## 핵심 특징

| 항목 | 내용 |
|------|------|
| **삭제 전략** | 단일: 소프트 삭제(isShow=false), 대량: 물리 삭제(deleteById) |
| **중복 체크** | zone1+zone2+zone3+port 조합 중복 방지 |
| **구역 필터링** | Native Query로 NULL 체크 가능한 유연한 필터링 |
| **감사 추적** | Service 레벨 @ActivityLog 적용 |
| **이벤트 위임** | AG Grid onCellClicked + data-action 속성 |

---

## 관련 문서

- [화이트리스트 위반 현황](detection-connection-system.md) - 금지 포트 위반 이벤트
- [프론트엔드 패턴](frontend-patterns.md) - AG Grid 패턴
- [감사 로그](audit-log-system.md) - @ActivityLog 사용법