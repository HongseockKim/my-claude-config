# 세션 화이트리스트 (policy/sessionWhite) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/policy/sessionWhite` |
| **메뉴 ID** | 6010L |
| **권한** | READ/WRITE/DELETE |
| **한글명** | 세션 화이트리스트 |
| **목적** | 허용된 네트워크 세션(IP/포트/프로토콜) 정책 관리 |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/PolicyController.java
Service:    src/main/java/com/otoones/otomon/service/DetectionService.java (3,200+ lines)
Template:   src/main/resources/templates/pages/policy/sessionWhite.html
JavaScript: src/main/resources/static/js/page.policy/sessionWhite.js (805 lines)
DTO:        src/main/java/com/otoones/otomon/dto/WhiteListPolicyDto.java
            src/main/java/com/otoones/otomon/dto/WhiteListPolicyExcelDto.java
Model:      src/main/java/com/otoones/otomon/model/WhitelistPolicy.java
Repository: src/main/java/com/otoones/otomon/repository/WhiteListPolicyRepository.java
```

---

## 컨트롤러 (PolicyController.java)

### 페이지 렌더링 (`GET /policy/sessionWhite`)

**위치**: `PolicyController.java:50-65`

**권한**:
```java
@RequirePermission(menuId = 6010L, resourceType = ResourceType.MENU, permissionType = PermissionType.READ)
```

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| whitelists | 화이트리스트 정책 목록 |
| config | 시스템 설정 (zone1, zone2, zone3) |
| detectedWhiteList | 탐지된 트래픽 (화이트리스트 후보) |

### CRUD API

| 메서드 | URL | 위치 | 권한 | @ActivityLog | 설명 |
|--------|-----|------|------|--------------|------|
| POST | `/policy/sessionWhite/create` | :85-118 | 6010L WRITE | - | 화이트리스트 생성 |
| PUT | `/policy/sessionWhite/update/{id}` | :124-157 | 6010L WRITE | - | 화이트리스트 수정 |
| DELETE | `/policy/sessionWhite/delete/{id}` | :160-177 | 6010L DELETE | - | 화이트리스트 삭제 |
| GET | `/policy/sessionWhite/changeLog` | :67-82 | - | - | 변경 로그 조회 |
| GET | `/policy/sessionWhite/exportExcel` | :179-203 | 6010L WRITE | - | 엑셀 다운로드 |

**응답 형식**:
```json
{
  "success": true,
  "message": "처리 메시지",
  "data": { WhiteListPolicyDto }
}
```

---

## 서비스 (DetectionService.java)

### 주요 메서드

#### 조회 메서드

| 메서드명 | 위치 | 기능 | 반환타입 |
|---------|------|------|---------|
| `getAllActiveWhitelists()` | :187-192 | 모든 활성 화이트리스트 조회 | `List<WhiteListPolicyDto>` |
| `getAllActiveWhitelistsByZone()` | :196-211 | 호기별 활성 화이트리스트 조회 | `List<WhiteListPolicyDto>` |
| `getWhiteListChangeLog()` | :216-221 | 화이트리스트 변경 로그 조회 | `List<SystemActivityLogDto>` |
| `getWhitelistPoliciesForAnalysis()` | :321-362 | 분석 서버용 화이트리스트 조회 | `Map<String, Object>` |
| `getWhitelistPoliciesForAnalysisCached()` | :369-370 | 캐시된 화이트리스트 조회 | `Map<String, Object>` |
| `getWhitelistPolicyMap()` | :2818-2826 | 화이트리스트 맵 변환 (최적화) | `Map<String, WhitelistPolicy>` |

#### CRUD 메서드

| 메서드명 | 위치 | 기능 | 어노테이션 |
|---------|------|------|----------|
| `createWhitelist()` | :377-414 | 화이트리스트 생성 | `@CacheEvict`, `@ActivityLog`, `@Transactional` |
| `updateWhitelist()` | :421-439 | 화이트리스트 수정 | `@CacheEvict`, `@ActivityLog`, `@Transactional` |
| `deleteWhitelist()` | :446-465 | 화이트리스트 삭제 (소프트) | `@CacheEvict`, `@ActivityLog`, `@Transactional` |

#### 기타 메서드

| 메서드명 | 위치 | 기능 |
|---------|------|------|
| `addToWhitelistFromAction()` | :472+ | 조치사항에서 화이트리스트 추가 |
| `isViolation()` | :831-858 | 화이트리스트 위반 여부 판단 (private) |
| `isViolationOptimized()` | :2829-2833 | 최적화된 위반 판단 (private) |

### createWhitelist() 상세 로직

```java
@CacheEvict(value = "whitelistPolicies", allEntries = true)
@ActivityLog(category = "WHITELIST", action = "CREATE", resourceType = "WHITELIST_POLICY")
@Transactional
public WhiteListPolicyDto createWhitelist(WhiteListPolicyDto dto)
```

1. **중복 체크** - srcIp, dstIp, dstPort, protocol 조합 검사
2. **Entity 생성** - `dto.toEntity()`
3. **DB 저장** - `whiteListPolicyRepository.save(entity)`
4. **Link 테이블 연동** - `is_policy = true` 업데이트

### deleteWhitelist() 상세 로직

- **소프트 삭제**: `isShow = false` 설정 (실제 삭제 아님)
- **Link 동기화**: `is_policy = false` 되돌림

---

## DTO 변환

### Entity → DTO

```java
WhiteListPolicyDto.fromEntity(entity)
WhiteListPolicyDto.toEncoded()  // Base64 인코딩
```

### 엑셀 DTO 변환 (라인 234-253)

```java
WhiteListPolicyExcelDto excelDto = new WhiteListPolicyExcelDto();
excelDto.setZone3Name(getZone3DisplayName(dto.getZone3()));  // 호기명 변환
excelDto.setSrcIp(decodeBase64(dto.getSrcIp()));             // Base64 디코딩
excelDto.setDstIp(decodeBase64(dto.getDstIp()));
```

---

## 프론트엔드 (sessionWhite.js - 805줄)

### 주요 함수

| 함수명 | 위치 | 역할 |
|--------|------|------|
| `PageConfig.init()` | :13 | 페이지 설정 및 메시지 초기화 |
| `safeBase64Decode()` | :64 | Base64 디코딩 (에러 처리) |
| `getZone3Name()` | :73 | 호기 이름 매핑 |
| `initializeAgGrid()` | :97 | AG Grid 초기화 |
| `sessionColumn()` | :132 | AG Grid 컬럼 정의 |
| `selectWhiteListType()` | :227 | 화이트리스트 타입 선택 모달 |
| `openAddModal()` | :231 | 추가 모달 열기 |
| `openTrafficModal()` | :269 | 탐지된 트래픽 모달 열기 |
| `editWhitelist()` | :280 | 화이트리스트 수정 |
| `saveWhitelist()` | :321 | 저장/수정 API 호출 |
| `deleteWhitelist()` | :375 | 화이트리스트 삭제 |
| `renderDetectedTraffic()` | :398 | 탐지된 트래픽 테이블 렌더링 |
| `addSingleTrafficToWhitelist()` | :467 | 탐지 트래픽 개별 추가 |
| `deleteSelected()` | :544 | 선택 항목 일괄 삭제 |
| `showChangeLog()` | :584 | 감사 로그 조회 |
| `downloadWhiteListExcel()` | :674 | 엑셀 다운로드 |

### AG Grid 설정

| 설정 | 값 |
|------|-----|
| 그리드 ID | `#session_white_grid` |
| 테마 | `ag-theme-quartz` |
| 페이지네이션 | 20건 기본 (10, 20, 50, 100) |
| 행 선택 | 복수 선택 (multiple) |
| CSP Nonce | `styleNonce` 설정 |

### 컬럼 정의

| 컬럼명 | 필드 | 특징 |
|--------|------|------|
| No | rowIndex | 체크박스 (삭제 권한 시) |
| 이름 | name | 텍스트 필터 |
| 호기 | zone3 | Zone3 이름 매핑 |
| 출발지 IP | srcIp | DataMaskingUtils 마스킹 + 포트 |
| 목적지 IP | dstIp | DataMaskingUtils 마스킹 + 포트 |
| 프로토콜 | protocol | 배지 스타일 |
| 설명 | description | - |
| 생성일시 | createdAt | 로케일 포맷팅 |
| 작업 | - | 수정/삭제 버튼 |

### 이벤트 위임 패턴

```javascript
// 라인 780-793: AG Grid 내 버튼 클릭 처리
document.getElementById('session_white_grid')?.addEventListener('click', function (e) {
    const editBtn = e.target.closest('.btn-edit-whitelist');
    const deleteBtn = e.target.closest('.btn-delete-whitelist');
    if (editBtn) { editWhitelist(parseInt(editBtn.dataset.id)); }
    if (deleteBtn) { deleteWhitelist(parseInt(deleteBtn.dataset.id)); }
});

// 라인 795-801: 탐지된 트래픽 테이블 버튼
document.getElementById('detected_traffic_tbody')?.addEventListener('click', function (e) {
    const addBtn = e.target.closest('.btn-add-traffic');
    if (addBtn) { addSingleTrafficToWhitelist(parseInt(addBtn.dataset.index)); }
});
```

### DataMaskingUtils 사용

```javascript
// 라인 156, 163, 419, 422
DataMaskingUtils.maskSensitiveData(params.value)
```

- srcIp, dstIp 컬럼에 권한 기반 마스킹 적용

### Base64 처리

```javascript
// 서버 전송 시 인코딩 (라인 338, 340)
btoa(srcIp)

// 수신 데이터 디코딩 (라인 731-749)
safeBase64Decode(encodedString)
```

---

## 권한 및 보안

### 권한 검사

| 기능 | Controller @RequirePermission | Service @ActivityLog |
|------|------------------------------|---------------------|
| 페이지 접근 | 6010L READ | - |
| 화이트리스트 생성 | 6010L WRITE | ✅ WHITELIST/CREATE |
| 화이트리스트 수정 | 6010L WRITE | ✅ WHITELIST/UPDATE |
| 화이트리스트 삭제 | 6010L DELETE | ✅ WHITELIST/DELETE |
| 변경 로그 조회 | - | - |
| 엑셀 다운로드 | 6010L WRITE | - |

### 보안 처리

1. **IP 마스킹**: `DataMaskingUtils.maskSensitiveData()` 사용
2. **Base64 인코딩**: IP 주소 서버 전송 시 인코딩
3. **CSRF 토큰**: 모든 AJAX 요청에 헤더 포함
4. **캐시 관리**: CRUD 시 `@CacheEvict`로 캐시 무효화

---

## API 엔드포인트 요약

| 메서드 | URL | 권한 | 위치 | 설명 |
|--------|-----|------|------|------|
| GET | `/policy/sessionWhite` | 6010L READ | :50 | 페이지 렌더링 |
| POST | `/policy/sessionWhite/create` | 6010L WRITE | :85 | 생성 |
| PUT | `/policy/sessionWhite/update/{id}` | 6010L WRITE | :124 | 수정 |
| DELETE | `/policy/sessionWhite/delete/{id}` | 6010L DELETE | :160 | 삭제 |
| GET | `/policy/sessionWhite/changeLog` | - | :67 | 변경 로그 |
| GET | `/policy/sessionWhite/exportExcel` | 6010L WRITE | :179 | 엑셀 |

---

## 데이터 흐름

```
[Controller] 세션에서 zone3 조회
         ↓
[Service] getAllActiveWhitelistsByZone() (:196-211)
         ↓
[Repository] findByZone3AndIsShowTrueOrderByCreatedAtDesc()
         ↓
[DTO] WhiteListPolicyDto.fromEntity().toEncoded()
         ↓
[Frontend] AG Grid 표시 + safeBase64Decode() + DataMaskingUtils 마스킹
```

---

## 핵심 특징

| 항목 | 내용 |
|------|------|
| **소프트 삭제** | `isShow = false` 설정 (실제 삭제 안함) |
| **Link 테이블 동기화** | 생성/삭제 시 Link.is_policy 상태 연동 |
| **Base64 인코딩** | IP 주소 DTO에서 Base64로 저장 |
| **중복 체크** | srcIp, dstIp, dstPort, protocol 조합 중복 방지 |
| **캐시 전략** | `@Cacheable` / `@CacheEvict` 적용 |
| **감사 추적** | Service 레벨 `@ActivityLog`로 기록 |

---

## 관련 문서

- [화이트리스트 위반 현황](detection-connection-system.md) - 화이트리스트 위반 이벤트 조회
- [프론트엔드 패턴](frontend-patterns.md) - AG Grid 패턴
- [감사 로그](audit-log-system.md) - @ActivityLog 사용법