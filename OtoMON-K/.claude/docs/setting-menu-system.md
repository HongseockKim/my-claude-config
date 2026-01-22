# 메뉴관리 (setting/menu) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/setting/menu` |
| **메뉴 ID** | 7010L |
| **권한** | READ/WRITE/DELETE |
| **한글명** | 메뉴관리 |
| **목적** | 시스템 메뉴 구조 관리 (부모/자식 메뉴, 순서, 권한, 상태) |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/SettingController.java
            src/main/java/com/otoones/otomon/controller/MenuController.java
Service:    src/main/java/com/otoones/otomon/service/MenuService.java
            src/main/java/com/otoones/otomon/service/MenuCacheService.java
Template:   src/main/resources/templates/pages/setting/menu.html
Model:      src/main/java/com/otoones/otomon/model/Menu.java
DTO:        src/main/java/com/otoones/otomon/dto/MenuDto.java
Util:       src/main/java/com/otoones/otomon/util/MenuUtil.java
```

---

## 컨트롤러

### SettingController (`GET /setting/menu`)

**위치**: `SettingController.java:72-91`

**권한**:
```java
@RequirePermission(menuId = 7010L, resourceType = ResourceType.MENU, permissionType = PermissionType.READ)
```

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| menus | 모든 메뉴 목록 (부모-자식 계층) |
| allRoles | 권한 목록 (ADMIN, OPERATOR 등) |
| isAdmin | 관리자 여부 |

### MenuController (`/menu`)

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/menu` | 사용자 접근 가능 메뉴 목록 |
| GET | `/menu/parent` | 부모 메뉴만 조회 |
| POST | `/menu/add` | 자식 메뉴 추가 |
| POST | `/menu/addedMenu` | 부모 메뉴 추가 |
| POST | `/menu/save` | 메뉴 저장 |
| POST | `/menu/edit` | 메뉴 수정 |
| POST | `/menu/delete` | 메뉴 삭제 |
| POST | `/menu/updateOrder` | 메뉴 순서 변경 |

---

## 프론트엔드 (menu.html)

### 페이지 레이아웃

```
┌─────────────────────────────────────────────────────┐
│ 버튼: [순서 변경] [부모메뉴 추가]                    │
├─────────────────────┬───────────────────────────────┤
│ 메뉴 트리 (좌측)    │ 메뉴 상세 폼 (우측)           │
│ ┌─────────────────┐ │ ┌───────────────────────────┐ │
│ │ 대시보드 [수정] │ │ │ 메뉴명: [입력]            │ │
│ │  └ 위젯설정    │ │ │ 메시지코드: [입력]        │ │
│ │  └ [추가]      │ │ │ 메뉴경로: [입력]          │ │
│ │ 자산 [수정]    │ │ │ 우선순위: [입력]          │ │
│ │  └ 자산현황    │ │ │ 권한: [선택]              │ │
│ │  └ 토폴로지    │ │ │ 표시: [토글]              │ │
│ │  └ [추가]      │ │ │ [저장] [삭제]             │ │
│ └─────────────────┘ │ └───────────────────────────┘ │
└─────────────────────┴───────────────────────────────┘
```

### 기능별 모달

1. **순서 변경 모달**: Sortable.js로 드래그 앤 드롭 순서 변경
2. **부모메뉴 추가 모달**: 새 부모 메뉴 생성 폼

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `handleParentMenuEdit(button)` | 부모 메뉴 수정 폼 표시 |
| `handleMenuClick()` | 자식 메뉴 클릭 시 상세 표시 |
| `handleMenuAdd(button)` | 자식 메뉴 추가 폼 표시 |
| `handleMenuSave()` | 메뉴 저장 분기 처리 |
| `handleMenuDelete()` | 메뉴 삭제 |
| `handleChildMenuAdd()` | 자식 메뉴 추가 요청 |
| `handleSubmit()` | 메뉴 수정 요청 |
| `handleAddedParentMenu()` | 순서 변경/부모 추가 모달 처리 |
| `saveMenuOrder()` | 순서 변경 저장 |
| `updateMenuOrder()` | 순서 변경 API 호출 |

### 저장 타입 분기 (MENU_SUBMIT_TYPE)

| 값 | 설명 |
|----|------|
| ADD | 자식 메뉴 추가 |
| SAVE | 자식 메뉴 수정 |
| BIG_MENU_EDIT | 부모 메뉴 수정 |

---

## 메뉴 모델 (Menu)

### 필드 구성

| 필드 | 타입 | 설명 |
|------|------|------|
| id | Long | PK (메뉴 ID) |
| parentId | Long | 부모 메뉴 ID (null이면 최상위) |
| name | String | 메뉴 이름 |
| messageCode | String | 다국어 메시지 코드 |
| url | String | 메뉴 URL 경로 |
| icon | String | FontAwesome 아이콘 클래스 |
| displayOrder | Integer | 표시 순서 |
| allowedRoles | String | 허용 권한 |
| hasChildren | Boolean | 자식 메뉴 사용 여부 |
| status | Boolean | 메뉴 활성화 여부 |
| children | List<Menu> | 자식 메뉴 목록 |

---

## 메뉴 상세 폼 필드

| 필드 | ID | 표시 조건 | 설명 |
|------|-----|----------|------|
| 메뉴명 | localizedName | 항상 | 표시될 메뉴 이름 |
| 메뉴 ID | menuId | 자식 추가 시만 | 새 메뉴 ID |
| 메시지 코드 | messageCode | 항상 | 다국어 키 |
| 자식메뉴 사용여부 | hasChildren | 부모 메뉴만 | 사용/미사용 |
| 아이콘 | is_icon | 부모 메뉴만 | FontAwesome 클래스 |
| 메뉴 경로 | url | 항상 | URL 경로 |
| 메뉴 우선순위 | displayOrder | 항상 | 표시 순서 |
| 메뉴 권한 | allowedRoles | 항상 | 접근 권한 선택 |
| 메뉴 표시 | status | 항상 | 활성/비활성 토글 |

---

## API 엔드포인트 요약

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/setting/menu` | 페이지 렌더링 |
| GET | `/menu` | 사용자 메뉴 목록 (사이드바용) |
| GET | `/menu/parent` | 부모 메뉴만 조회 |
| POST | `/menu/add` | 자식 메뉴 추가 |
| POST | `/menu/addedMenu` | 부모 메뉴 추가 |
| POST | `/menu/save` | 자식 메뉴 수정 |
| POST | `/menu/edit` | 부모 메뉴 수정 |
| POST | `/menu/delete` | 메뉴 삭제 |
| POST | `/menu/updateOrder` | 순서 일괄 변경 |

---

## 데이터 흐름

### 메뉴 조회
```
[SettingController] /setting/menu
         ↓
[MenuCacheService] getMenusWithChildren()
         ↓
[MenuDto.fromEntity()] 계층 구조 변환
         ↓
[Template] 트리 구조로 렌더링
```

### 메뉴 수정
```
[Frontend] handleMenuSave()
         ↓
[AJAX] POST /menu/save
         ↓
[MenuController] 메뉴 업데이트
         ↓
[MenuCacheService] 캐시 무효화
         ↓
[Frontend] MenuCache.forceRefreshMenu()
         ↓
[사이드바] 새로고침
```

### 순서 변경
```
[Sortable.js] 드래그 앤 드롭
         ↓
[Frontend] updateMenuOrder([{id, displayOrder}...])
         ↓
[AJAX] POST /menu/updateOrder
         ↓
[MenuService] 일괄 업데이트
         ↓
[캐시 무효화 + 사이드바 새로고침]
```

---

## 메뉴 캐시 시스템

### MenuCacheService

사이드바 메뉴 성능 최적화를 위한 캐시:

```java
@Cacheable(value = "menus", key = "#userId + '_' + #visibleMenuIds.hashCode()")
public List<Menu> getMenusByUser(Long userId, List<Long> visibleMenuIds)
```

### 클라이언트 캐시 (MenuCache)

```javascript
MenuCache.forceRefreshMenu()  // 메뉴 변경 후 캐시 무효화
```

---

## 권한 처리

### 읽기 전용 모드

```javascript
if (permissions.canRead && !permissions.canWrite) {
    $('input, select, textarea').attr('readonly', true).attr('disabled', true);
    $('#submit_btn, #delete_btn').hide();
    $('.btn[onclick*="handleMenuAdd"]').hide();
    $('.btn[onclick*="handleParentMenuEdit"]').hide();
}
```

### 삭제 권한 체크

```javascript
if (!permissions.canDelete && !permissions.isAdmin) {
    alert(permissionDenine);
    return;
}
```

---

## 사용 라이브러리

| 라이브러리 | 용도 |
|-----------|------|
| Sortable.js | 드래그 앤 드롭 순서 변경 |
| Lodash | 데이터 검색 (_.find, _.throttle) |
| Bootstrap Modal | 순서 변경/부모 추가 모달 |

---

## 메뉴 계층 구조 예시

```
1000 대시보드 (parentId: null)
  └ 1010 위젯설정 (parentId: 1000)
  └ 1020 대시보드 (parentId: 1000)

2000 자산 (parentId: null)
  └ 2010 자산현황 (parentId: 2000)
  └ 2020 토폴로지 (parentId: 2000)
  └ 2030 트래픽현황 (parentId: 2000)

3000 수집현황 (parentId: null)
  └ 3010 운전정보 (parentId: 3000)
  └ 3020 세션 (parentId: 3000)
```

---

## 다국어 메시지 코드 패턴

| 패턴 | 예시 |
|------|------|
| 메뉴명 | `menu.dashboard`, `menu.asset.status` |
| 버튼 | `button.edit`, `button.save`, `button.delete` |
| 메시지 | `info.save.confirm`, `confirm.delete` |

---

## 관련 문서

- [권한 시스템](permission-system.md) - 메뉴별 권한 관리
- [아키텍처](architecture.md) - 메뉴 구조
- [프론트엔드 패턴](frontend-patterns.md) - 사이드바 렌더링

---

## 프로그램 명세서

### SMN_001 - 메뉴관리 페이지

| 프로그램 ID | SMN_001 | 프로그램명 | 메뉴관리 페이지 |
|------------|---------|----------|--------------|
| 분류 | 설정 관리 | 처리유형 | 화면 |
| 클래스명 | SettingController.java | 메서드명 | menuPage() |

▣ 기능 설명

시스템 메뉴 구조를 관리하는 페이지를 렌더링한다. 부모-자식 계층 구조의 메뉴 트리와 상세 편집 폼을 제공한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 파라미터 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | menus | 메뉴 목록 | List<MenuDto> | Y | 부모-자식 계층 구조 |
| 2 | allRoles | 권한 목록 | List<String> | Y | ADMIN, OPERATOR 등 |
| 3 | isAdmin | 관리자 여부 | Boolean | Y | 현재 사용자 관리자 여부 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | @RequirePermission READ |
| 2 | 전체 메뉴 목록 조회 | getMenusWithChildren() |
| 3 | 권한 목록 조회 | getAllRoles() |
| 4 | 현재 사용자 관리자 여부 확인 | isAdmin() |
| 5 | Model에 데이터 추가 및 뷰 반환 | pages/setting/menu |

---

### SMN_002 - 사용자 메뉴 목록 조회 API

| 프로그램 ID | SMN_002 | 프로그램명 | 사용자 메뉴 목록 조회 API |
|------------|---------|----------|------------------------|
| 분류 | 메뉴 조회 | 처리유형 | 조회 |
| 클래스명 | MenuController.java | 메서드명 | getMenus() |

▣ 기능 설명

현재 로그인한 사용자가 접근 가능한 메뉴 목록을 조회한다. 사이드바 렌더링에 사용된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 세션에서 사용자 정보 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 메뉴 목록 | List<MenuDto> | Y | 접근 가능 메뉴 |
| 3 | data[].id | 메뉴 ID | Long | Y | PK |
| 4 | data[].name | 메뉴명 | String | Y | - |
| 5 | data[].url | 경로 | String | Y | URL 경로 |
| 6 | data[].icon | 아이콘 | String | N | FontAwesome 클래스 |
| 7 | data[].children | 자식 메뉴 | List<MenuDto> | N | 하위 메뉴 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 현재 사용자 권한 조회 | - |
| 2 | 권한별 접근 가능 메뉴 조회 | getMenusByUser() |
| 3 | 캐시 확인 및 반환 | MenuCacheService |
| 4 | 결과 반환 | JSON 응답 |

---

### SMN_003 - 부모 메뉴 목록 조회 API

| 프로그램 ID | SMN_003 | 프로그램명 | 부모 메뉴 목록 조회 API |
|------------|---------|----------|----------------------|
| 분류 | 메뉴 조회 | 처리유형 | 조회 |
| 클래스명 | MenuController.java | 메서드명 | getParentMenus() |

▣ 기능 설명

부모 메뉴(최상위 메뉴)만 조회한다. 순서 변경 모달에서 사용된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 파라미터 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 부모 메뉴 목록 | List<MenuDto> | Y | parentId=null인 메뉴 |
| 3 | data[].id | 메뉴 ID | Long | Y | PK |
| 4 | data[].name | 메뉴명 | String | Y | - |
| 5 | data[].displayOrder | 표시 순서 | Integer | Y | - |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 부모 메뉴 조회 | findByParentIdIsNull() |
| 2 | 표시 순서로 정렬 | ORDER BY displayOrder |
| 3 | 결과 반환 | JSON 응답 |

---

### SMN_004 - 자식 메뉴 추가 API

| 프로그램 ID | SMN_004 | 프로그램명 | 자식 메뉴 추가 API |
|------------|---------|----------|------------------|
| 분류 | 메뉴 관리 | 처리유형 | 등록 |
| 클래스명 | MenuController.java | 메서드명 | addChildMenu() |

▣ 기능 설명

부모 메뉴 하위에 새로운 자식 메뉴를 추가한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 메뉴 ID | Long | Y | 새 메뉴 ID |
| 2 | parentId | 부모 메뉴 ID | Long | Y | 상위 메뉴 |
| 3 | name | 메뉴명 | String | Y | 표시 이름 |
| 4 | messageCode | 메시지 코드 | String | Y | 다국어 키 |
| 5 | url | 메뉴 경로 | String | Y | URL 경로 |
| 6 | displayOrder | 표시 순서 | Integer | Y | 정렬 순서 |
| 7 | allowedRoles | 허용 권한 | String | Y | 접근 권한 |
| 8 | status | 활성화 여부 | Boolean | Y | 메뉴 표시 여부 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 생성된 메뉴 | MenuDto | Y | 새 메뉴 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 메뉴 ID 중복 확인 | existsById() |
| 3 | 부모 메뉴 존재 확인 | findById() |
| 4 | 메뉴 Entity 생성 및 저장 | save() |
| 5 | 메뉴 캐시 무효화 | evictCache() |
| 6 | 결과 반환 | JSON 응답 |

---

### SMN_005 - 부모 메뉴 추가 API

| 프로그램 ID | SMN_005 | 프로그램명 | 부모 메뉴 추가 API |
|------------|---------|----------|------------------|
| 분류 | 메뉴 관리 | 처리유형 | 등록 |
| 클래스명 | MenuController.java | 메서드명 | addParentMenu() |

▣ 기능 설명

새로운 부모 메뉴(최상위 메뉴)를 추가한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 메뉴 ID | Long | Y | 새 메뉴 ID |
| 2 | name | 메뉴명 | String | Y | 표시 이름 |
| 3 | messageCode | 메시지 코드 | String | Y | 다국어 키 |
| 4 | icon | 아이콘 | String | N | FontAwesome 클래스 |
| 5 | hasChildren | 자식 사용 여부 | Boolean | Y | 하위 메뉴 사용 |
| 6 | displayOrder | 표시 순서 | Integer | Y | 정렬 순서 |
| 7 | allowedRoles | 허용 권한 | String | Y | 접근 권한 |
| 8 | status | 활성화 여부 | Boolean | Y | 메뉴 표시 여부 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 생성된 메뉴 | MenuDto | Y | 새 메뉴 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 메뉴 ID 중복 확인 | existsById() |
| 3 | 메뉴 Entity 생성 | parentId=null 설정 |
| 4 | 메뉴 저장 | save() |
| 5 | 메뉴 캐시 무효화 | evictCache() |
| 6 | 결과 반환 | JSON 응답 |

---

### SMN_006 - 자식 메뉴 수정 API

| 프로그램 ID | SMN_006 | 프로그램명 | 자식 메뉴 수정 API |
|------------|---------|----------|------------------|
| 분류 | 메뉴 관리 | 처리유형 | 수정 |
| 클래스명 | MenuController.java | 메서드명 | saveChildMenu() |

▣ 기능 설명

기존 자식 메뉴의 정보를 수정한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 메뉴 ID | Long | Y | 수정할 메뉴 ID |
| 2 | name | 메뉴명 | String | Y | 표시 이름 |
| 3 | messageCode | 메시지 코드 | String | Y | 다국어 키 |
| 4 | url | 메뉴 경로 | String | Y | URL 경로 |
| 5 | displayOrder | 표시 순서 | Integer | Y | 정렬 순서 |
| 6 | allowedRoles | 허용 권한 | String | Y | 접근 권한 |
| 7 | status | 활성화 여부 | Boolean | Y | 메뉴 표시 여부 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 수정된 메뉴 | MenuDto | Y | 변경된 메뉴 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 메뉴 존재 확인 | findById() |
| 3 | 메뉴 정보 업데이트 | - |
| 4 | 메뉴 저장 | save() |
| 5 | 메뉴 캐시 무효화 | evictCache() |
| 6 | 결과 반환 | JSON 응답 |

---

### SMN_007 - 부모 메뉴 수정 API

| 프로그램 ID | SMN_007 | 프로그램명 | 부모 메뉴 수정 API |
|------------|---------|----------|------------------|
| 분류 | 메뉴 관리 | 처리유형 | 수정 |
| 클래스명 | MenuController.java | 메서드명 | editParentMenu() |

▣ 기능 설명

기존 부모 메뉴의 정보를 수정한다. 아이콘, 자식 사용 여부 등 부모 메뉴 전용 속성을 포함한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 메뉴 ID | Long | Y | 수정할 메뉴 ID |
| 2 | name | 메뉴명 | String | Y | 표시 이름 |
| 3 | messageCode | 메시지 코드 | String | Y | 다국어 키 |
| 4 | icon | 아이콘 | String | N | FontAwesome 클래스 |
| 5 | hasChildren | 자식 사용 여부 | Boolean | Y | 하위 메뉴 사용 |
| 6 | displayOrder | 표시 순서 | Integer | Y | 정렬 순서 |
| 7 | allowedRoles | 허용 권한 | String | Y | 접근 권한 |
| 8 | status | 활성화 여부 | Boolean | Y | 메뉴 표시 여부 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 수정된 메뉴 | MenuDto | Y | 변경된 메뉴 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 메뉴 존재 확인 | findById() |
| 3 | 부모 메뉴 여부 확인 | parentId=null 체크 |
| 4 | 메뉴 정보 업데이트 | 아이콘, hasChildren 포함 |
| 5 | 메뉴 저장 | save() |
| 6 | 메뉴 캐시 무효화 | evictCache() |
| 7 | 결과 반환 | JSON 응답 |

---

### SMN_008 - 메뉴 삭제 API

| 프로그램 ID | SMN_008 | 프로그램명 | 메뉴 삭제 API |
|------------|---------|----------|-------------|
| 분류 | 메뉴 관리 | 처리유형 | 삭제 |
| 클래스명 | MenuController.java | 메서드명 | deleteMenu() |

▣ 기능 설명

메뉴를 삭제한다. 부모 메뉴 삭제 시 하위 자식 메뉴도 함께 삭제된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 메뉴 ID | Long | Y | 삭제할 메뉴 ID |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | DELETE 권한 필요 |
| 2 | 메뉴 존재 확인 | findById() |
| 3 | 자식 메뉴 존재 시 함께 삭제 | CASCADE 삭제 |
| 4 | 메뉴 삭제 | delete() |
| 5 | 메뉴 캐시 무효화 | evictCache() |
| 6 | 결과 반환 | JSON 응답 |

---

### SMN_009 - 메뉴 순서 변경 API

| 프로그램 ID | SMN_009 | 프로그램명 | 메뉴 순서 변경 API |
|------------|---------|----------|------------------|
| 분류 | 메뉴 관리 | 처리유형 | 수정 |
| 클래스명 | MenuController.java | 메서드명 | updateMenuOrder() |

▣ 기능 설명

여러 메뉴의 표시 순서를 일괄 변경한다. 드래그 앤 드롭으로 변경된 순서를 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | orders | 순서 목록 | List<Object> | Y | RequestBody |
| 2 | orders[].id | 메뉴 ID | Long | Y | 대상 메뉴 |
| 3 | orders[].displayOrder | 표시 순서 | Integer | Y | 새 순서 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 순서 목록 유효성 검증 | - |
| 3 | 각 메뉴 displayOrder 일괄 업데이트 | saveAll() |
| 4 | 메뉴 캐시 무효화 | evictCache() |
| 5 | 결과 반환 | JSON 응답 |
