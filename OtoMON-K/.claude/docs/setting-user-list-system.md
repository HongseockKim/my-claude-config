# 사용자 관리 (setting/userList) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/setting/userList` |
| **메뉴 ID** | 9000L |
| **권한** | READ/WRITE/DELETE |
| **한글명** | 사용자 관리 |
| **목적** | 시스템 사용자 계정 관리 (등록/수정/삭제/그룹 할당) |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/SettingController.java (페이지)
            src/main/java/com/otoones/otomon/controller/UserController.java (REST API)
Service:    src/main/java/com/otoones/otomon/service/UserService.java
            src/main/java/com/otoones/otomon/service/UserNormalService.java
            src/main/java/com/otoones/otomon/service/UserGroupService.java
Template:   src/main/resources/templates/pages/setting/userList.html
Model:      src/main/java/com/otoones/otomon/model/User.java
            src/main/java/com/otoones/otomon/model/UserGroup.java
            src/main/java/com/otoones/otomon/model/UserRole.java
DTO:        src/main/java/com/otoones/otomon/dto/UserDto.java
            src/main/java/com/otoones/otomon/dto/UserGroupDto.java
Repository: src/main/java/com/otoones/otomon/repository/UserRepository.java
            src/main/java/com/otoones/otomon/repository/UserGroupRepository.java
```

---

## 컨트롤러

### SettingController (`GET /setting/userList`)

**위치**: `SettingController.java:267-273`

**권한**:
```java
@RequirePermission(menuId = 9000L)
```

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| isAdmin | 현재 사용자가 ADMIN인지 여부 |

### UserController (`/user`)

| 메서드 | URL | 권한 | 설명 |
|--------|-----|------|------|
| POST | `/user/grid-data-user` | - | AG Grid 서버사이드 데이터 조회 |
| POST | `/user/saveUser` | WRITE | 사용자 저장 (신규/수정 통합) |
| POST | `/user/saveNewUser` | WRITE | 새 사용자 등록 |
| POST | `/user/saveExistingUser` | - | 기존 사용자 수정 |
| POST | `/user/getUserData` | - | 사용자 상세 조회 |
| POST | `/user/deleteUser` | DELETE | 사용자 비활성화 |
| GET | `/user/getGroupList` | - | 활성화된 그룹 목록 조회 |
| POST | `/user/updateUserGroups` | - | 사용자 그룹 할당 |
| POST | `/user/export-excel` | - | 전체 사용자 엑셀 다운로드 |
| GET | `/user/changePassword` | - | 비밀번호 변경 페이지 |
| POST | `/user/changePassword` | - | 비밀번호 변경 처리 |

---

## 프론트엔드 (userList.html)

### 페이지 레이아웃

```
┌─────────────────────────────────────────────────────────────────┐
│ 사용자 목록                                                      │
├───────────────────────┬─────────────────────────────────────────┤
│ 권한 그룹 목록         │ [현재 페이지 다운로드] [전체 페이지 다운로드] │
│                       │ [사용자 등록] [전체 사용자]                │
├───────────────────────┼─────────────────────────────────────────┤
│ ▼ 권한 그룹 목록       │ ┌────┬───────┬───────┬──────┬────┬────┐ │
│   ├─ ADMIN (3)       │ │ ID │ 아이디 │ 이메일 │ 이름 │처리│상태│ │
│   ├─ OPERATOR (5)    │ ├────┼───────┼───────┼──────┼────┼────┤ │
│   └─ VIEWER (10)     │ │  1 │ admin │ a@a.c │ 관리 │수정│삭제│ │
│                       │ │  2 │ user1 │ b@b.c │ 사용 │수정│삭제│ │
│                       │ └────┴───────┴───────┴──────┴────┴────┘ │
└───────────────────────┴─────────────────────────────────────────┘
```

### 주요 구성 요소

**왼쪽 패널**: 그룹 트리 (jstree)
- 권한 그룹 목록을 트리 형태로 표시
- 그룹 선택 시 해당 그룹의 사용자만 필터링

**오른쪽 패널**: 사용자 목록 (AG Grid)
- Server-Side Row Model 사용
- 페이지네이션, 필터링, 정렬 지원

### 사용자 등록/수정 모달

| 필드 | ID | 설명 | 유효성 |
|------|-----|------|--------|
| idx | idx | PK (hidden) | - |
| 아이디 | userId | 사용자 ID | 필수, 중복 불가 |
| 이메일 | email | 이메일 | 필수, 형식 검증, 중복 불가 |
| 이름 | name | 사용자 이름 | 필수 |
| 상태 | status | 활성/비활성 토글 | 수정 시만 표시 |
| 시스템 관리자 | isAdmin | ADMIN/USER 구분 체크박스 | ADMIN 체크 시 그룹 선택 비활성화 |
| 소속 권한 그룹 | userGroupRadio | 라디오 버튼 그룹 선택 | USER인 경우 필수 |

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `initGroupTree()` | 그룹 트리 초기화 |
| `renderGroupTree(groups)` | jstree 렌더링 |
| `loadUsersByGroup(groupIdx)` | 그룹별 사용자 로드 |
| `showUserRegModal()` | 사용자 등록 모달 표시 |
| `openEditModal(idx)` | 사용자 수정 모달 표시 |
| `userReg()` | 사용자 저장 요청 |
| `loadGroupsToModal()` | 모달에 그룹 라디오 버튼 로드 |
| `toggleAdminGroupAccess()` | ADMIN 체크 시 그룹 선택 비활성화 |
| `GridModule.initialize()` | AG Grid 초기화 |
| `GridModule.refreshData()` | 그리드 데이터 새로고침 |
| `GridModule.exportCurrentData()` | 현재 페이지 엑셀 다운로드 |
| `GridModule.exportAllData()` | 전체 데이터 엑셀 다운로드 |

---

## 모델 (User.java)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| idx | Long | idx | PK |
| userId | String | userId | 사용자 ID (unique) |
| password | String | password | 비밀번호 (암호화) |
| name | String | name | 이름 |
| email | String | email | 이메일 (ARIA 암호화) |
| role | UserRole | role | 권한 (ADMIN/USER) |
| status | String | status | 상태 (Y/N) |
| passwordChangeRequired | boolean | password_change_required | 비밀번호 변경 필요 여부 |
| failedAttempt | int | failed_attempt | 로그인 실패 횟수 |
| lockTime | LocalDateTime | Lock_time | 계정 잠금 시간 |
| createdAt | LocalDateTime | createdAt | 생성일시 |
| updatedAt | LocalDateTime | updatedAt | 수정일시 |
| groups | Set<UserGroup> | - | 소속 그룹 (ManyToMany) |

### UserRole Enum

```java
public enum UserRole {
    ADMIN,  // 시스템 관리자 - 모든 권한
    USER    // 일반 사용자 - 그룹 권한으로 관리
}
```

### 계정 잠금 로직

```java
@Override
public boolean isAccountNonLocked() {
    if (lockTime == null) {
        return true;
    }
    // 30분 후 자동 잠금 해제
    return lockTime.plusMinutes(30).isBefore(LocalDateTime.now());
}
```

---

## DTO (UserDto.java)

| 필드 | 타입 | 유효성 | 설명 |
|------|------|--------|------|
| idx | Long | - | PK |
| name | String | @NotBlank | 이름 |
| email | String | @NotBlank, @Email | 이메일 |
| role | String | @NotBlank | 권한 |
| userId | String | @NotBlank | 사용자 ID |
| status | String | - | 상태 |
| groupNames | List<String> | - | 소속 그룹명 목록 |
| groupIds | List<Long> | - | 소속 그룹 ID 목록 |

---

## 서비스

### UserNormalService

| 메서드 | 위치 | 설명 |
|--------|------|------|
| `getUserData()` | 33줄 | AG Grid용 사용자 목록 조회 |
| `deactivateUser()` | 51줄 | 사용자 비활성화 |
| `makeExcelData()` | 126줄 | 엑셀 다운로드 데이터 생성 |
| `updateUserInfo()` | 201줄 | 사용자 정보 수정 |

### UserService

| 메서드 | 설명 |
|--------|------|
| `createUser()` | 새 사용자 생성 (비밀번호 암호화) |
| `findByIdx()` | 사용자 조회 |
| `changePassword()` | 비밀번호 변경 |

### UserGroupService

| 메서드 | 설명 |
|--------|------|
| `getActiveGroups()` | 활성화된 그룹 목록 |
| `updateUserGroups()` | 사용자 그룹 할당/해제 |
| `getUsersByGroup()` | 그룹별 사용자 조회 |

---

## 중복 체크 로직

### 신규 등록 시

```java
private Map<String, Object> checkDuplicateForCreate(UserDto userDto) {
    // userId 중복 체크
    if (userRepository.existsByUserId(userDto.getUserId())) {
        return errorMap("아이디 중복");
    }
    // email 중복 체크 (암호화된 값으로 비교)
    if (userRepository.existsByEmail(AriaUtil.encrypt(userDto.getEmail()))) {
        return errorMap("이메일 중복");
    }
    return null;
}
```

### 수정 시

```java
private Map<String, Object> checkDuplicateForUpdate(UserDto userDto) {
    // 자신을 제외한 다른 사용자와 중복 체크
    if (userRepository.existsByUserIdAndIdxNot(userDto.getUserId(), userDto.getIdx())) {
        return errorMap("아이디 중복");
    }
    if (userRepository.existsByEmailAndIdxNot(AriaUtil.encrypt(userDto.getEmail()), userDto.getIdx())) {
        return errorMap("이메일 중복");
    }
    return null;
}
```

---

## 신규 사용자 등록 프로세스

```
[모달] 정보 입력
         ↓
[JS] userReg() → 데이터 수집
         ↓
[검증] ADMIN 아니면 그룹 필수
         ↓
[AJAX] POST /user/saveUser
         ↓
[Controller] saveUser()
         ↓
[Service] 중복 체크
         ↓
[Service] createUser()
    ├─ 초기 비밀번호: "1111"
    ├─ passwordChangeRequired: true
    └─ status: "Y"
         ↓
[Service] updateUserGroups() → 그룹 할당
         ↓
[ActivityLog] 감사 로그 기록
         ↓
[Response] 성공/실패
         ↓
[JS] location.reload()
```

---

## AG Grid 설정

### 서버사이드 데이터 소스

```javascript
serverSideDatasource: {
    getRows: function (params) {
        const requestParams = {
            email: email,
            groupIdx: selectedGroupIdx,  // 그룹 필터
            startRow: params.request.startRow,
            endRow: params.request.endRow,
            sortModel: params.request.sortModel,
            filterModel: params.request.filterModel
        };

        $.ajax({
            url: '/user/grid-data-user',
            method: 'POST',
            data: JSON.stringify(requestParams),
            success: function (response) {
                params.success({
                    rowData: response.data,
                    rowCount: response.totalCount
                });
            }
        });
    }
}
```

### 동적 컬럼 정의

| 컬럼 | 필터 | 설명 |
|------|------|------|
| idx | X | ID |
| userId | agTextColumnFilter | 사용자 아이디 |
| email | agTextColumnFilter | 이메일 (복호화 표시) |
| name | agTextColumnFilter | 이름 |
| groupNames | agTextColumnFilter | 소속 그룹 |
| createdAt | X | 등록일시 |
| 처리 | X | 수정/삭제 버튼 |
| status | agSetColumnFilter | 상태 (Y/N) |

---

## 보안 처리

### 이메일 암호화

ARIA 알고리즘으로 이메일 암호화/복호화:

```java
// 저장 시 암호화
user.setEmail(AriaUtil.encrypt(userDto.getEmail()));

// 조회 시 복호화
userDto.setEmail(AriaUtil.decrypt(user.getEmail()));
```

### 비밀번호 정책

| 항목 | 값 |
|------|-----|
| 초기 비밀번호 | 1111 |
| 최초 로그인 시 | 비밀번호 변경 강제 |
| 로그인 실패 제한 | failedAttempt 필드 관리 |
| 계정 잠금 시간 | 30분 자동 해제 |

---

## 감사 로그

`@ActivityLog` 어노테이션으로 CRUD 작업 자동 기록:

| 작업 | category | action | resourceType |
|------|----------|--------|--------------|
| 등록 | USER_MANAGE | ADD | USER |
| 수정 | USER_MANAGE | UPDATE | USER |
| 삭제 | USER_GROUP | DELETE | USER |
| 엑셀 다운로드 | USER_MANAGE | EXCEL_DOWN_ALL | USER |
| 비밀번호 변경 | USER | UPDATE | USER |

---

## 권한 처리

### 프론트엔드

```html
<!-- 사용자 등록 버튼: WRITE 권한 -->
<button th:if="${userPermissions?.canWrite}">사용자 등록</button>
```

```javascript
// 수정 버튼: canWrite 권한
if (canWrite) {
    container.appendChild(editBtn);
}

// 삭제 버튼: canDelete 권한
if (canDelete) {
    container.appendChild(deleteBtn);
}
```

### 백엔드

```java
@RequirePermission(menuId = 9000L, resourceType = ResourceType.MENU, permissionType = PermissionType.WRITE)
@PostMapping("/saveUser")
public Map<String, Object> saveUser(...) { }

@RequirePermission(menuId = 9000L, resourceType = ResourceType.MENU, permissionType = PermissionType.DELETE)
@PostMapping("/deleteUser")
public Map<String, Object> deleteUser(...) { }
```

---

## ADMIN vs USER 권한

| 권한 | ADMIN | USER |
|------|-------|------|
| 그룹 할당 | 불필요 (모든 권한) | 필수 |
| 메뉴 접근 | 전체 | 그룹 권한에 따름 |
| 데이터 접근 | 전체 | 그룹 권한에 따름 |

### ADMIN 체크 시 동작

```javascript
function toggleAdminGroupAccess() {
    const isAdmin = $('#isAdmin').is(':checked');

    if (isAdmin) {
        // 그룹 라디오 버튼 비활성화 + 체크 해제
        $('.user-group-radio').prop('disabled', true).prop('checked', false);
        // 안내 메시지 표시
        $('#userGroupsContainer').prepend(
            '<div class="alert alert-info" id="adminWarning">' +
            'ADMIN은 그룹과 무관하게 모든권한을 가집니다.' +
            '</div>'
        );
    } else {
        $('.user-group-radio').prop('disabled', false);
        $('#adminWarning').remove();
    }
}
```

---

## 다국어 메시지

| 메시지 키 | 설명 |
|----------|------|
| `menu.user.list` | 페이지 제목 |
| `setting.user.registration.*` | 등록 폼 라벨/플레이스홀더 |
| `setting.user.download.*` | 엑셀 다운로드 버튼 |
| `setting.user.status.*` | 상태 텍스트 |
| `userGroup.*` | 그룹 관련 메시지 |

---

## 엑셀 다운로드

### 현재 페이지 다운로드

```javascript
function exportCurrentDataToExcel() {
    gridApi.exportDataAsExcel({
        fileName: '사용자목록_' + moment().format('YYYYMMDD_HHmmss') + '.xlsx'
    });
}
```

### 전체 데이터 다운로드

```javascript
function exportAllDataToExcel() {
    $.ajax({
        url: '/user/export-excel',
        method: 'POST',
        data: JSON.stringify({exportAll: true, filterModel, sortModel}),
        xhrFields: { responseType: 'blob' },
        success: function (blob) {
            // Blob으로 파일 다운로드
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = '사용자목록_..xlsx';
            a.click();
        }
    });
}
```

---

## 관련 문서

- [권한 시스템](permission-system.md) - 그룹별 권한 관리
- [인증 시스템](authentication-system.md) - 로그인/비밀번호
- [감사 로그](audit-log-system.md) - 활동 기록
- [그룹 관리](setting-group-list-system.md) - 권한 그룹 관리

---

## 프로그램 명세서

### SUL_001 - 사용자 관리 페이지

| 프로그램 ID | SUL_001 | 프로그램명 | 사용자 관리 페이지 |
|------------|---------|----------|-----------------|
| 분류 | 설정 관리 | 처리유형 | 화면 |
| 클래스명 | SettingController.java | 메서드명 | userListPage() |

▣ 기능 설명

시스템 사용자 계정을 관리하는 페이지를 렌더링한다. 좌측에 권한 그룹 트리(jstree), 우측에 사용자 목록 그리드(AG Grid)를 표시한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 파라미터 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | isAdmin | 관리자 여부 | Boolean | Y | 현재 사용자 ADMIN 여부 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | @RequirePermission(menuId = 9000L) |
| 2 | 현재 사용자 관리자 여부 확인 | isAdmin() |
| 3 | Model에 isAdmin 추가 | - |
| 4 | 뷰 반환 | pages/setting/userList |

---

### SUL_002 - 사용자 목록 조회 API (AG Grid)

| 프로그램 ID | SUL_002 | 프로그램명 | 사용자 목록 조회 API |
|------------|---------|----------|-------------------|
| 분류 | 사용자 조회 | 처리유형 | 조회 |
| 클래스명 | UserController.java | 메서드명 | getGridDataUser() |

▣ 기능 설명

AG Grid Server-Side Row Model용 사용자 목록을 조회한다. 페이지네이션, 필터링, 정렬을 지원한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | startRow | 시작 행 | Integer | Y | 페이지 시작 위치 |
| 2 | endRow | 종료 행 | Integer | Y | 페이지 종료 위치 |
| 3 | sortModel | 정렬 정보 | List | N | 컬럼별 정렬 |
| 4 | filterModel | 필터 정보 | Map | N | 컬럼별 필터 |
| 5 | groupIdx | 그룹 ID | Long | N | 그룹별 필터 |
| 6 | email | 이메일 검색 | String | N | 이메일 검색어 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | data | 사용자 목록 | List<UserDto> | Y | 페이지 데이터 |
| 2 | totalCount | 전체 건수 | Integer | Y | 총 레코드 수 |
| 3 | data[].idx | 사용자 ID | Long | Y | PK |
| 4 | data[].userId | 아이디 | String | Y | - |
| 5 | data[].email | 이메일 | String | Y | 복호화된 값 |
| 6 | data[].name | 이름 | String | Y | - |
| 7 | data[].groupNames | 소속 그룹 | List<String> | N | 그룹명 목록 |
| 8 | data[].status | 상태 | String | Y | Y/N |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 요청 파라미터 파싱 | startRow, endRow, sortModel 등 |
| 2 | 그룹 필터 적용 | groupIdx 있으면 해당 그룹만 |
| 3 | 이메일 검색 적용 | email 있으면 필터링 |
| 4 | 정렬/필터 적용 | AG Grid 모델 변환 |
| 5 | 페이지 조회 | JPA Pageable |
| 6 | 이메일 복호화 | AriaUtil.decrypt() |
| 7 | 결과 반환 | data + totalCount |

---

### SUL_003 - 사용자 저장 API

| 프로그램 ID | SUL_003 | 프로그램명 | 사용자 저장 API |
|------------|---------|----------|---------------|
| 분류 | 사용자 관리 | 처리유형 | 등록/수정 |
| 클래스명 | UserController.java | 메서드명 | saveUser() |

▣ 기능 설명

사용자 정보를 저장한다. idx 유무로 신규/수정을 분기하며, 중복 체크 후 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 사용자 ID | Long | N | null이면 신규 |
| 2 | userId | 아이디 | String | Y | 중복 불가 |
| 3 | email | 이메일 | String | Y | 중복 불가 |
| 4 | name | 이름 | String | Y | - |
| 5 | role | 권한 | String | Y | ADMIN/USER |
| 6 | status | 상태 | String | N | Y/N (수정 시만) |
| 7 | groupIds | 그룹 ID 목록 | List<Long> | △ | USER인 경우 필수 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | idx 분기 | null → 신규, else → 수정 |
| 3 | userId 중복 체크 | existsByUserId() |
| 4 | email 중복 체크 | 암호화 후 비교 |
| 5 | 신규: 초기 비밀번호 설정 | "1111" |
| 6 | 신규: passwordChangeRequired 설정 | true |
| 7 | 이메일 암호화 저장 | AriaUtil.encrypt() |
| 8 | 그룹 할당 | updateUserGroups() |
| 9 | 감사 로그 기록 | @ActivityLog(ADD/UPDATE) |
| 10 | 결과 반환 | JSON 응답 |

▣ 신규 사용자 초기값

| 항목 | 값 | 설명 |
|------|-----|------|
| password | "1111" | 초기 비밀번호 |
| passwordChangeRequired | true | 최초 로그인 시 변경 강제 |
| status | "Y" | 활성 상태 |
| failedAttempt | 0 | 로그인 실패 횟수 |

---

### SUL_004 - 사용자 상세 조회 API

| 프로그램 ID | SUL_004 | 프로그램명 | 사용자 상세 조회 API |
|------------|---------|----------|-------------------|
| 분류 | 사용자 조회 | 처리유형 | 조회 |
| 클래스명 | UserController.java | 메서드명 | getUserData() |

▣ 기능 설명

특정 사용자의 상세 정보를 조회한다. 수정 모달에서 사용된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 사용자 ID | Long | Y | RequestBody |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 사용자 정보 | UserDto | Y | 상세 정보 |
| 3 | data.idx | 사용자 ID | Long | Y | PK |
| 4 | data.userId | 아이디 | String | Y | - |
| 5 | data.email | 이메일 | String | Y | 복호화된 값 |
| 6 | data.name | 이름 | String | Y | - |
| 7 | data.role | 권한 | String | Y | ADMIN/USER |
| 8 | data.status | 상태 | String | Y | Y/N |
| 9 | data.groupIds | 그룹 ID 목록 | List<Long> | N | 소속 그룹 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 사용자 조회 | findById() |
| 2 | 이메일 복호화 | AriaUtil.decrypt() |
| 3 | 소속 그룹 조회 | getGroups() |
| 4 | DTO 변환 | Entity → UserDto |
| 5 | 결과 반환 | JSON 응답 |

---

### SUL_005 - 사용자 비활성화 API

| 프로그램 ID | SUL_005 | 프로그램명 | 사용자 비활성화 API |
|------------|---------|----------|------------------|
| 분류 | 사용자 관리 | 처리유형 | 수정 |
| 클래스명 | UserController.java | 메서드명 | deleteUser() |

▣ 기능 설명

사용자를 비활성화한다. 실제 삭제가 아닌 status를 "N"으로 변경한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 사용자 ID | Long | Y | RequestBody |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | DELETE 권한 필요 |
| 2 | 사용자 조회 | findById() |
| 3 | status = "N" 설정 | 비활성화 |
| 4 | 저장 | save() |
| 5 | 감사 로그 기록 | @ActivityLog(DELETE) |
| 6 | 결과 반환 | JSON 응답 |

---

### SUL_006 - 그룹 목록 조회 API

| 프로그램 ID | SUL_006 | 프로그램명 | 그룹 목록 조회 API |
|------------|---------|----------|-----------------|
| 분류 | 그룹 조회 | 처리유형 | 조회 |
| 클래스명 | UserController.java | 메서드명 | getGroupList() |

▣ 기능 설명

활성화된 권한 그룹 목록을 조회한다. 사용자 등록/수정 모달의 그룹 라디오 버튼에 사용된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 파라미터 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 그룹 목록 | List<UserGroupDto> | Y | 활성 그룹 |
| 3 | data[].idx | 그룹 ID | Long | Y | PK |
| 4 | data[].name | 그룹명 | String | Y | - |
| 5 | data[].code | 그룹 코드 | String | Y | - |
| 6 | data[].userCount | 사용자 수 | Integer | N | 소속 사용자 수 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 활성 그룹 조회 | getActiveGroups() |
| 2 | DTO 변환 | Entity → UserGroupDto |
| 3 | 결과 반환 | JSON 응답 |

---

### SUL_007 - 사용자 그룹 할당 API

| 프로그램 ID | SUL_007 | 프로그램명 | 사용자 그룹 할당 API |
|------------|---------|----------|-------------------|
| 분류 | 사용자 관리 | 처리유형 | 수정 |
| 클래스명 | UserController.java | 메서드명 | updateUserGroups() |

▣ 기능 설명

사용자의 소속 그룹을 할당/해제한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | userIdx | 사용자 ID | Long | Y | - |
| 2 | groupIds | 그룹 ID 목록 | List<Long> | Y | 할당할 그룹 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 사용자 조회 | findById() |
| 2 | 기존 그룹 연결 해제 | clearGroups() |
| 3 | 새 그룹 연결 | addGroups() |
| 4 | 저장 | save() |
| 5 | 결과 반환 | JSON 응답 |

---

### SUL_008 - 전체 사용자 엑셀 다운로드 API

| 프로그램 ID | SUL_008 | 프로그램명 | 전체 사용자 엑셀 다운로드 API |
|------------|---------|----------|--------------------------|
| 분류 | 사용자 조회 | 처리유형 | 조회 |
| 클래스명 | UserController.java | 메서드명 | exportExcel() |

▣ 기능 설명

전체 사용자 목록을 엑셀 파일로 다운로드한다. 현재 필터/정렬 상태를 유지한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | exportAll | 전체 내보내기 | Boolean | Y | true 고정 |
| 2 | filterModel | 필터 정보 | Map | N | 현재 필터 |
| 3 | sortModel | 정렬 정보 | List | N | 현재 정렬 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | 엑셀 파일 | Blob | Y | .xlsx 파일 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 전체 사용자 조회 | 필터/정렬 적용 |
| 2 | 이메일 복호화 | AriaUtil.decrypt() |
| 3 | 엑셀 데이터 생성 | makeExcelData() |
| 4 | 파일명 생성 | 사용자목록_YYYYMMDD_HHmmss.xlsx |
| 5 | Blob 반환 | ResponseEntity<byte[]> |
| 6 | 감사 로그 기록 | @ActivityLog(EXCEL_DOWN_ALL) |

▣ 엑셀 컬럼

| No | 컬럼명 | 필드 |
|----|-------|------|
| 1 | ID | idx |
| 2 | 아이디 | userId |
| 3 | 이메일 | email |
| 4 | 이름 | name |
| 5 | 소속 그룹 | groupNames |
| 6 | 등록일시 | createdAt |
| 7 | 상태 | status |

---

### SUL_009 - 비밀번호 변경 페이지

| 프로그램 ID | SUL_009 | 프로그램명 | 비밀번호 변경 페이지 |
|------------|---------|----------|------------------|
| 분류 | 사용자 관리 | 처리유형 | 화면 |
| 클래스명 | UserController.java | 메서드명 | changePasswordPage() |

▣ 기능 설명

비밀번호 변경 페이지를 렌더링한다. 최초 로그인 시 또는 사용자 요청 시 표시된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 세션에서 사용자 정보 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 비밀번호 변경 폼 페이지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션 사용자 확인 | - |
| 2 | 뷰 반환 | pages/user/changePassword |

---

### SUL_010 - 비밀번호 변경 처리 API

| 프로그램 ID | SUL_010 | 프로그램명 | 비밀번호 변경 처리 API |
|------------|---------|----------|---------------------|
| 분류 | 사용자 관리 | 처리유형 | 수정 |
| 클래스명 | UserController.java | 메서드명 | changePassword() |

▣ 기능 설명

사용자 비밀번호를 변경한다. 현재 비밀번호 확인 후 새 비밀번호로 변경한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | currentPassword | 현재 비밀번호 | String | Y | - |
| 2 | newPassword | 새 비밀번호 | String | Y | - |
| 3 | confirmPassword | 비밀번호 확인 | String | Y | newPassword와 일치 필수 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션 사용자 조회 | - |
| 2 | 현재 비밀번호 확인 | BCrypt 비교 |
| 3 | 새 비밀번호 일치 확인 | newPassword == confirmPassword |
| 4 | 비밀번호 암호화 | BCrypt 인코딩 |
| 5 | passwordChangeRequired = false | 변경 완료 |
| 6 | 저장 | save() |
| 7 | 감사 로그 기록 | @ActivityLog(UPDATE) |
| 8 | 결과 반환 | JSON 응답 |

---

▣ ADMIN vs USER 권한 차이

| 항목 | ADMIN | USER |
|------|-------|------|
| 그룹 할당 | 불필요 (모든 권한) | 필수 |
| 메뉴 접근 | 전체 | 그룹 권한에 따름 |
| 데이터 접근 | 전체 | 그룹 권한에 따름 |
| 모달 동작 | 그룹 선택 비활성화 | 그룹 선택 필수 |

▣ 계정 보안 정책

| 항목 | 값 | 설명 |
|------|-----|------|
| 초기 비밀번호 | 1111 | 신규 사용자 |
| 최초 로그인 | 비밀번호 변경 강제 | passwordChangeRequired |
| 로그인 실패 제한 | failedAttempt 카운트 | - |
| 계정 잠금 시간 | 30분 자동 해제 | lockTime + 30분 |
| 이메일 암호화 | ARIA | AriaUtil |

▣ 이메일 암호화 처리

| 방향 | 처리 |
|------|------|
| 저장 시 | AriaUtil.encrypt(email) |
| 조회 시 | AriaUtil.decrypt(email) |
| 중복 체크 | 암호화된 값으로 비교 |

