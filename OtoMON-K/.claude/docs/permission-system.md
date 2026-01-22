# 권한 시스템 (Permission System)

## 권한 시스템 전체 구조

```
[그룹 권한 설정] → [DB 저장] → [인터셉터/AOP] → [프론트엔드 렌더링]
     ↓                ↓              ↓                 ↓
 groupList      GroupPermission  PermissionService  userPermissions
```

---

## 1. 권한 타입 (PermissionType.java)

| 권한 | 설명 | 프론트 변수 | 용도 |
|------|------|------------|------|
| `READ` | 조회 | `canRead` | 데이터 조회, 페이지 접근 |
| `WRITE` | 쓰기 | `canWrite` | 생성 + 수정 통합 |
| `DELETE` | 삭제 | `canDelete` | 데이터 삭제 |

> **단순화된 3단계 권한**: READ(조회), WRITE(생성+수정), DELETE(삭제)

---

## 2. 리소스 타입 (ResourceType.java)

**주요 사용**: `ResourceType.MENU` (메뉴 기반 권한 체크)

```java
MENU,       // 메뉴 (주로 사용)
CODE,       // 코드 (사업소/발전소/호기)
ASSET,      // 자산
EVENT,      // 이벤트
USER,       // 사용자
USER_GROUP, // 사용자 그룹
POLICY,     // 정책
DETECTION,  // 탐지
OPERATION,  // 운영
DASHBOARD,  // 대시보드
REPORT,     // 보고서
SYSTEM,     // 시스템 설정
ALARM,      // 알람
NETWORK,    // 네트워크
TEMPLATE    // 템플릿
```

---

## 3. ADMIN 역할

**ADMIN은 모든 권한을 자동 통과합니다.**

```java
// PermissionCheckAspect.java
if (requirePermission.skipForAdmin() && user.getRole() == UserRole.ADMIN) {
    return joinPoint.proceed();  // 권한 체크 없이 통과
}
```

| 역할 | 권한 |
|------|------|
| `ADMIN` | 모든 메뉴, 모든 권한 자동 통과 |
| `USER` | 그룹에 할당된 메뉴/권한만 접근 가능 |

---

## 4. 권한 체크 흐름

```
[요청] → [ZoneInterceptor] → [PermissionInterceptor] → [PermissionCheckAspect] → [Controller]
              ↓                       ↓                          ↓
         호기 권한 체크         userPermissions 주입        @RequirePermission 체크
```

### 4-1. ZoneInterceptor (호기 권한)

- `permissionService.getUserAccessibleZones(userIdx)` 호출
- 권한 없는 호기 선택 시 자동으로 첫 번째 호기로 변경

### 4-2. PermissionInterceptor (메뉴별 권한)

- URL → Menu 테이블 → menuId 추출
- `userPermissions` 객체를 Model에 주입

### 4-3. PermissionCheckAspect (AOP)

- `@RequirePermission` 어노테이션 처리
- ADMIN 역할이면 자동 통과 (`skipForAdmin = true` 기본값)
- 권한 없으면 `AccessDeniedException`

---

## 5. PermissionService 주요 메소드

```java
hasMenuPermission(userIdx, menuId)           // 메뉴 접근 권한

hasPermission(userIdx, ResourceType, PermissionType)  // 리소스 타입 권한

hasResourcePermission(userIdx, ResourceType, resourceId, PermissionType)  // 특정 리소스

hasCodeAccess(userIdx, codeIdx)              // 호기 접근 권한

getUserAccessibleZones(userIdx)              // 접근 가능 호기 목록
```

---

## 6. 프론트엔드 권한 객체 (userPermissions)

**default.html에서 JS 변수 초기화:**

```javascript
const userPermissions = {
    hasMenuAccess: true / false,
    canRead: true / false,
    canWrite: true / false,
    canDelete: true / false,
    isAdmin: true / false
};
```

---

## 7. Setting 페이지 권한

Setting 페이지(`/setting/*`)는 **ADMIN 역할만 접근 가능**합니다.

```java
// 컨트롤러 예시
@PreAuthorize("hasRole('ADMIN')")
@GetMapping("/setting/userList")
public String userList() { ... }
```

---

## 8. @RequirePermission 사용법

### 어노테이션 속성

```java
@RequirePermission(
    menuId = 2040L,                    // 메뉴 ID (필수)
    resourceType = ResourceType.MENU,  // 리소스 타입 (기본: MENU)
    permissionType = PermissionType.READ,  // 권한 타입 (READ/WRITE/DELETE)
    skipForAdmin = true                // ADMIN 자동 통과 (기본: true)
)
```

### 컨트롤러 예시

```java
// 페이지 조회 - READ 권한 필요
@RequirePermission(menuId = 2040L, resourceType = ResourceType.MENU, permissionType = PermissionType.READ)
@GetMapping("/asset/reg")
public String assetReg() { ... }

// 저장 API - WRITE 권한 필요
@RequirePermission(menuId = 2040L, resourceType = ResourceType.MENU, permissionType = PermissionType.WRITE)
@PostMapping("/asset/save")
public ResponseEntity<?> saveAsset() { ... }

// 삭제 API - DELETE 권한 필요
@RequirePermission(menuId = 2040L, resourceType = ResourceType.MENU, permissionType = PermissionType.DELETE)
@PostMapping("/asset/delete")
public ResponseEntity<?> deleteAsset() { ... }
```

---

## 9. 프론트엔드 권한 적용

### HTML (Thymeleaf)

```html
<!-- 버튼 표시/숨김 -->
<button th:if="${userPermissions.canWrite}">저장</button>
<button th:if="${userPermissions.canDelete}">삭제</button>

<!-- 읽기전용 -->
<textarea th:readonly="${!userPermissions.canWrite}"></textarea>
<input th:disabled="${!userPermissions.canWrite}" />
```

### JavaScript

```javascript
// 액션 전 권한 체크
if (!userPermissions.canWrite) {
    Swal.fire('권한 없음', '수정 권한이 없습니다.', 'error');
    return;
}

// AG Grid 버튼 렌더러에서
if (userPermissions.canDelete) {
    return '<button class="btn-delete">삭제</button>';
}
return '';
```

---

## 10. 파일 경로 요약

```
src/main/java/com/otoones/otomon/
├── annotation/
│   └── RequirePermission.java        # 권한 체크 어노테이션
├── aspect/
│   └── PermissionCheckAspect.java    # AOP Aspect
├── model/
│   ├── PermissionType.java           # READ, WRITE, DELETE
│   ├── ResourceType.java             # MENU, ASSET, ...
│   └── UserRole.java                 # ADMIN, USER
├── interceptor/
│   ├── ZoneInterceptor.java          # 호기 권한 체크
│   └── PermissionInterceptor.java    # userPermissions 주입
└── service/
    └── PermissionService.java        # 권한 체크 로직
```

---

## 11. 요약

| 항목 | 내용 |
|------|------|
| 권한 타입 | READ, WRITE, DELETE (3단계) |
| 리소스 타입 | 주로 `ResourceType.MENU` 사용 |
| ADMIN | 모든 권한 자동 통과 |
| 어노테이션 | `@RequirePermission(menuId, permissionType)` |
| 프론트 객체 | `userPermissions.canRead/canWrite/canDelete` |