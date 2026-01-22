# 그룹 관리 시스템 (Group List System)

## 개요

사용자 그룹(권한 그룹)을 관리하는 페이지. 그룹별로 접근 가능한 사업소/발전소/호기(코드 트리)와 메뉴 접근 권한(메뉴 트리)을 설정. 알람 수신 설정도 그룹 단위로 관리.

## URL

| 경로 | 위치 | 용도 |
|------|------|------|
| `/setting/groupList` | SettingController:276-308 | 그룹 관리 페이지 |

## 아키텍처

```
[groupList.html]
        │
        ├──► [SettingController] - 페이지 렌더링 + 권한 체크
        │
        └──► [UserController] - 그룹 CRUD API
                    │
                    ▼
            [UserGroupService]
                    │
                    ├──► [UserGroupRepository]
                    ├──► [GroupCodeMappingRepository]
                    ├──► [GroupMenuMappingRepository]
                    └──► [PermissionService] ──► [GroupPermissionRepository]
                    │
                    ▼
            [MariaDB]
              ├── UserGroup
              ├── GroupCodeMapping
              ├── GroupMenuMapping
              └── GroupPermission
```

## 핵심 모델

### UserGroup (사용자 그룹)
```
src/main/java/com/otoones/otomon/model/UserGroup.java

@Entity
@Table(name = "UserGroup")
public class UserGroup {
    Long idx;                      // PK
    String groupName;              // 그룹명 (max 100)
    String groupCode;              // 그룹 코드 (unique, max 50)
    String description;            // 설명 (max 255)
    String status;                 // Y=활성, N=비활성
    Boolean alarmEnabled;          // 알람 활성화 여부
    String alarmLevel;             // 알람 레벨 (INFO, WARNING, CRITICAL)
    LocalDateTime createdAt;
    LocalDateTime updatedAt;

    // 관계
    Set<User> users;               // 소속 사용자 (ManyToMany)
    Set<GroupCodeMapping> codeMappings;    // 접근 가능 코드
    Set<GroupMenuMapping> menuMappings;    // 접근 가능 메뉴
    Set<GroupPermission> permissions;      // CRUD 권한
}
```

### GroupCodeMapping (그룹-코드 매핑)
```
@Entity
@Table(name = "GroupCodeMapping")
public class GroupCodeMapping {
    Long id;                       // PK
    UserGroup userGroup;           // FK → UserGroup
    Code code;                     // FK → Code (사업소/발전소/호기)
    LocalDateTime createdAt;
}
```

### GroupMenuMapping (그룹-메뉴 매핑)
```
@Entity
@Table(name = "GroupMenuMapping")
public class GroupMenuMapping {
    Long idx;                      // PK
    UserGroup userGroup;           // FK → UserGroup
    Menu menu;                     // FK → Menu
    LocalDateTime createdAt;
}
```

### GroupPermission (그룹 권한)
```
@Entity
@Table(name = "GroupPermission")
public class GroupPermission {
    Long idx;                      // PK
    UserGroup userGroup;           // FK → UserGroup
    ResourceType resourceType;     // MENU, USER_GROUP, ASSET 등
    String resourceId;             // 특정 리소스 ID (nullable)
    PermissionType permissionType; // READ, WRITE, DELETE, EXECUTE
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
}
```

## API 엔드포인트

| Method | URL | 설명 | 권한 |
|--------|-----|------|------|
| GET | `/setting/groupList` | 페이지 렌더링 | 메뉴 권한 |
| GET | `/user/getGroupList` | 그룹 목록 조회 | 인증 |
| POST | `/user/getGroupData` | 그룹 상세 조회 | 인증 |
| POST | `/user/saveGroup` | 그룹 등록 | WRITE |
| POST | `/user/updateGroup` | 그룹 수정 | WRITE |
| POST | `/user/deleteGroup` | 그룹 삭제 | DELETE |
| GET | `/user/getSystemCodeTree` | 코드 트리 조회 | 인증 |
| GET | `/user/getMenuTree` | 메뉴 트리 조회 | 인증 |
| POST | `/user/updateGroupMenus` | 그룹 메뉴 권한 수정 | WRITE |
| POST | `/user/updateGroupMenuCrudPermissions` | 메뉴별 CRUD 권한 수정 | WRITE |

### POST /user/saveGroup

**Request:**
```json
{
    "groupName": "3호기 운전원",
    "groupCode": "SP_UNIT3_OPERATOR",
    "description": "3호기 운전 담당자",
    "status": "Y",
    "codeIdxList": []
}
```

**Response:**
```json
{
    "ret": 0,
    "message": "그룹이 등록되었습니다.",
    "data": {
        "idx": 1,
        "groupName": "3호기 운전원",
        "groupCode": "SP_UNIT3_OPERATOR"
    }
}
```

### POST /user/updateGroup

**Request:**
```json
{
    "idx": 1,
    "groupName": "3호기 운전원 (수정)",
    "groupCode": "SP_UNIT3_OPERATOR",
    "description": "수정된 설명",
    "status": "Y",
    "alarmEnabled": true,
    "alarmLevel": "WARNING",
    "codeIdxList": [1, 2, 3]
}
```

### POST /user/updateGroupMenus

**Request:**
```json
{
    "groupIdx": 1,
    "menuIds": [1000, 2000, 3000]
}
```

### POST /user/updateGroupMenuCrudPermissions

**Request:**
```json
{
    "groupIdx": 1,
    "menuPermissions": [
        {
            "menuId": 1000,
            "permissions": ["READ", "WRITE"]
        },
        {
            "menuId": 2000,
            "permissions": ["READ", "WRITE", "DELETE"]
        }
    ]
}
```

## UI 구조

### 2컬럼 레이아웃
```
┌──────────────────────────────┬────────────────────────────────────────┐
│      그룹 목록 (350px)        │           그룹 상세 설정                 │
│ ┌──────────────────────────┐ │ ┌────────────────────────────────────┐ │
│ │ [+ 추가]                  │ │ │ 기본 정보                           │ │
│ ├──────────────────────────┤ │ │ - 그룹명, 그룹 코드, 설명, 상태      │ │
│ │ 3호기 운전원              │ │ ├────────────────────────────────────┤ │
│ │ 코드: SP_UNIT3 | 사용자: 5 │ │ │ 알람 설정                          │ │
│ ├──────────────────────────┤ │ │ - 알람 활성화, 알람 레벨             │ │
│ │ 4호기 운전원              │ │ ├────────────────────────────────────┤ │
│ │ 코드: SP_UNIT4 | 사용자: 3 │ │ │ 접근 권한 설정 (코드 트리)          │ │
│ └──────────────────────────┘ │ │ jstree - 사업소/발전소/호기          │ │
│                              │ ├────────────────────────────────────┤ │
│                              │ │ 메뉴 접근 권한 (메뉴 트리)           │ │
│                              │ │ jstree - 메뉴 + READ/WRITE/DELETE   │ │
│                              │ ├────────────────────────────────────┤ │
│                              │ │ [삭제]              [변경사항 저장] │ │
│                              │ └────────────────────────────────────┘ │
└──────────────────────────────┴────────────────────────────────────────┘
```

## JavaScript 함수 (groupList.html)

### 그룹 목록 로드
```javascript
function loadAllGroups() {
    $.ajax({
        url: '/user/getGroupList',
        method: 'GET',
        success: function(response) {
            if (response.ret === 0) {
                allGroups = response.data;
                renderGroupList(allGroups);
            }
        }
    });
}
```

### 그룹 상세 로드
```javascript
function loadGroupDetail(groupIdx) {
    $.ajax({
        url: '/user/getGroupData',
        method: 'POST',
        data: JSON.stringify({ idx: groupIdx }),
        success: function(response) {
            if (response.ret === 0) {
                selectedGroup = response.data;
                renderGroupDetail(selectedGroup);
                loadCodeTree(groupIdx);   // 코드 트리
                loadMenuTree(groupIdx);   // 메뉴 트리
            }
        }
    });
}
```

### 코드 트리 (jstree)
```javascript
function renderCodeTree(treeData) {
    $('#codeTree').jstree({
        'core': {
            'data': treeData,
            'themes': { 'name': 'default', 'icons': false }
        },
        'checkbox': {
            'keep_selected_style': false,
            'three_state': false,     // 부분 선택 직접 처리
            'cascade': '',            // 자동 전파 비활성화
            'tie_selection': false
        },
        'plugins': ['checkbox']
    })
    .on('check_node.jstree', function(e, data) {
        handleTreeCheck('#codeTree', data.node, true);
    })
    .on('uncheck_node.jstree', function(e, data) {
        handleTreeCheck('#codeTree', data.node, false);
    });
}
```

### 메뉴 트리 (jstree + CRUD 권한)
```javascript
function renderMenuTree(treeData) {
    $('#menuTree').jstree({...})
    .on('check_node.jstree', function(e, data) {
        handleMenuPermissionCheck('#menuTree', data.node, true);
    })
    .on('uncheck_node.jstree', function(e, data) {
        handleMenuPermissionCheck('#menuTree', data.node, false);
    });
}

// 메뉴 권한 연동 로직
function handleMenuPermissionCheck(treeSelector, node, isChecked) {
    // WRITE/DELETE 체크 시 READ 자동 체크
    // READ 언체크 시 WRITE/DELETE 자동 언체크
}
```

### 그룹 저장/수정/삭제
```javascript
function saveNewGroup() {
    const groupData = {
        groupName: $('#groupName').val(),
        groupCode: $('#groupCode').val(),
        description: $('#description').val(),
        status: 'Y',
        codeIdxList: []
    };
    $.ajax({
        url: '/user/saveGroup',
        method: 'POST',
        data: JSON.stringify(groupData)
    });
}

function updateGroup() {
    const selectedCodeIds = getSelectedCodeIds();  // 코드 트리 선택값
    const menuData = getSelectedMenuIds();         // 메뉴 트리 선택값

    // 1. 그룹 기본정보 + 코드매핑 업데이트
    $.ajax({
        url: '/user/updateGroup',
        data: JSON.stringify({
            idx: selectedGroup.idx,
            groupName: ...,
            alarmEnabled: ...,
            alarmLevel: ...,
            codeIdxList: selectedCodeIds
        }),
        success: function() {
            // 2. 메뉴 권한 업데이트
            updateGroupMenuPermissions(groupIdx, menuData);
        }
    });
}

function deleteGroup() {
    $.ajax({
        url: '/user/deleteGroup',
        method: 'POST',
        data: JSON.stringify({ idx: selectedGroup.idx })
    });
}
```

## 권한 체크

### 페이지 접근 권한 (SettingController)
```java
@GetMapping("/groupList")
public String groupList(Authentication authentication, Model model) {
    User user = (User) authentication.getPrincipal();

    // ResourceType.USER_GROUP에 대한 CRUD 권한 체크
    boolean canWrite = user.getRole() == UserRole.ADMIN ||
        permissionService.hasResourcePermission(user.getIdx(),
            ResourceType.USER_GROUP, null, PermissionType.WRITE);

    boolean canRead = user.getRole() == UserRole.ADMIN ||
        permissionService.hasResourcePermission(user.getIdx(),
            ResourceType.USER_GROUP, null, PermissionType.READ);

    boolean canDelete = user.getRole() == UserRole.ADMIN ||
        permissionService.hasResourcePermission(user.getIdx(),
            ResourceType.USER_GROUP, null, PermissionType.DELETE);

    model.addAttribute("canRead", canRead);
    model.addAttribute("canWrite", canWrite);
    model.addAttribute("canDelete", canDelete);
}
```

### API 권한 어노테이션
```java
@RequirePermission(menuId = 9000L, resourceType = ResourceType.MENU, permissionType = PermissionType.WRITE)
@PostMapping("/saveGroup")
public ResponseEntity<?> saveGroup(...)

@RequirePermission(menuId = 9000L, resourceType = ResourceType.MENU, permissionType = PermissionType.DELETE)
@PostMapping("/deleteGroup")
public ResponseEntity<?> deleteGroup(...)
```

## 알람 설정

### 그룹별 알람 수신 조건
```
1. 정책에서 알람이 활성화 되어 있고
2. 정책의 알람 레벨이 그룹 설정 레벨 이상이며
3. 그룹 알람이 활성화 되어 있을 때 알람 수신
```

### 알람 레벨
| 레벨 | 설명 |
|------|------|
| INFO | 모든 알람 수신 |
| WARNING | 경고 이상만 수신 |
| CRITICAL | 심각한 알람만 수신 |

## 코드 트리 구조

```
사업소 (zone1)
└── 삼천포발전소 (zone2)
    ├── 3호기 (sp_03, zone3)
    └── 4호기 (sp_04, zone3)
```

## 메뉴 트리 구조

```
대시보드 (menuId: 1000)
├── 조회 (READ)
├── 수정 (WRITE)
└── 삭제 (DELETE)
운영 현황 (menuId: 2000)
├── 조회 (READ)
├── 수정 (WRITE)
└── 삭제 (DELETE)
...
```

### 권한 노드 ID 형식
```
menu_1000        → 메뉴 자체
menu_1000_READ   → 메뉴 조회 권한
menu_1000_WRITE  → 메뉴 수정 권한
menu_1000_DELETE → 메뉴 삭제 권한
```

## Model Attribute (페이지 렌더링 시)

| 속성 | 타입 | 설명 |
|------|------|------|
| canRead | Boolean | 조회 권한 |
| canWrite | Boolean | 등록/수정 권한 |
| canDelete | Boolean | 삭제 권한 |

## 비즈니스 로직

### 그룹 삭제 제한
```java
// 소속 사용자가 있으면 삭제 불가
if (!group.getUsers().isEmpty()) {
    throw new IllegalStateException("소속 사용자가 있는 그룹은 삭제할 수 없습니다.");
}
```

### 그룹 코드 제약
- 그룹 코드는 생성 후 수정 불가
- 영문, 숫자, 언더스코어(_)만 허용
- 중복 불가

## 관련 테이블

### UserGroup
| 컬럼 | 타입 | 설명 |
|------|------|------|
| idx | BIGINT | PK |
| groupName | VARCHAR(100) | 그룹명 |
| groupCode | VARCHAR(50) | 그룹 코드 (unique) |
| description | VARCHAR(255) | 설명 |
| status | VARCHAR(20) | Y/N |
| alarm_enabled | TINYINT(1) | 알람 활성화 |
| alarm_level | VARCHAR(20) | 알람 레벨 |
| createdAt | DATETIME | 생성일 |
| updatedAt | DATETIME | 수정일 |

### GroupCodeMapping
| 컬럼 | 타입 | 설명 |
|------|------|------|
| idx | BIGINT | PK |
| groupIdx | BIGINT | FK → UserGroup |
| codeIdx | BIGINT | FK → Code |
| createdAt | DATETIME | 생성일 |

### GroupMenuMapping
| 컬럼 | 타입 | 설명 |
|------|------|------|
| idx | BIGINT | PK |
| groupIdx | BIGINT | FK → UserGroup |
| menuId | BIGINT | FK → Menu |
| createdAt | DATETIME | 생성일 |

### GroupPermission
| 컬럼 | 타입 | 설명 |
|------|------|------|
| idx | BIGINT | PK |
| groupIdx | BIGINT | FK → UserGroup |
| resourceType | VARCHAR(50) | MENU, USER_GROUP 등 |
| resourceId | VARCHAR(100) | 특정 리소스 ID |
| permissionType | VARCHAR(20) | READ, WRITE, DELETE |
| createdAt | DATETIME | 생성일 |
| updatedAt | DATETIME | 수정일 |

## 연관 문서

- 사용자 관리: `docs/setting-user-list-system.md`
- 권한 시스템: `docs/permission-system.md`
- 메뉴 관리: `docs/setting-menu-system.md`
- 코드 관리: `docs/setting-code-system.md`

---

## 프로그램 명세서

### GRP_001 - 그룹 관리 페이지

| 프로그램 ID | GRP_001 | 프로그램명 | 그룹 관리 페이지 |
|------------|---------|----------|--------------|
| 분류 | 설정 | 처리유형 | 화면 |
| 클래스명 | SettingController.java | 메서드명 | groupList() |

▣ 기능 설명

사용자 그룹(권한 그룹) 관리 페이지를 렌더링한다. 그룹 목록과 상세 설정 영역을 포함하며, 사용자 권한에 따라 CRUD 버튼 표시 여부가 결정된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 인증 정보에서 권한 확인 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | canRead | 조회 권한 | Boolean | Y | 조회 가능 여부 |
| 2 | canWrite | 등록/수정 권한 | Boolean | Y | 등록/수정 가능 여부 |
| 3 | canDelete | 삭제 권한 | Boolean | Y | 삭제 가능 여부 |
| 4 | HTML | 그룹 관리 페이지 | String | Y | Thymeleaf 렌더링 HTML |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | Authentication에서 사용자 정보 조회 | |
| 2 | USER_GROUP 리소스에 대한 권한 확인 | PermissionService |
| 3 | ADMIN은 모든 권한 자동 부여 | |
| 4 | 권한 정보를 모델에 추가 | canRead, canWrite, canDelete |
| 5 | groupList.html 렌더링 | |

---

### GRP_002 - 그룹 목록 조회

| 프로그램 ID | GRP_002 | 프로그램명 | 그룹 목록 조회 |
|------------|---------|----------|-------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | UserController.java | 메서드명 | getGroupList() |

▣ 기능 설명

등록된 모든 사용자 그룹 목록을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 입력 항목 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공, 1=실패 |
| 2 | data | 그룹 목록 | List | Y | UserGroup 배열 |
| 3 | data[].idx | 그룹 ID | Long | Y | PK |
| 4 | data[].groupName | 그룹명 | String | Y | |
| 5 | data[].groupCode | 그룹 코드 | String | Y | unique |
| 6 | data[].description | 설명 | String | N | |
| 7 | data[].status | 상태 | String | Y | Y/N |
| 8 | data[].userCount | 소속 사용자 수 | Integer | Y | |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 전체 그룹 목록 조회 | UserGroupRepository.findAll() |
| 2 | 그룹별 소속 사용자 수 계산 | |
| 3 | 목록 반환 | |

---

### GRP_003 - 그룹 상세 조회

| 프로그램 ID | GRP_003 | 프로그램명 | 그룹 상세 조회 |
|------------|---------|----------|-------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | UserController.java | 메서드명 | getGroupData() |

▣ 기능 설명

특정 그룹의 상세 정보를 조회한다. 기본 정보, 알람 설정, 코드 매핑, 메뉴 권한을 포함한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 그룹 ID | Long | Y | RequestBody |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | data | 그룹 상세 | Object | Y | UserGroup |
| 3 | data.idx | 그룹 ID | Long | Y | |
| 4 | data.groupName | 그룹명 | String | Y | |
| 5 | data.groupCode | 그룹 코드 | String | Y | |
| 6 | data.description | 설명 | String | N | |
| 7 | data.status | 상태 | String | Y | Y/N |
| 8 | data.alarmEnabled | 알람 활성화 | Boolean | N | |
| 9 | data.alarmLevel | 알람 레벨 | String | N | INFO/WARNING/CRITICAL |
| 10 | data.codeMappings | 코드 매핑 | List | Y | 접근 가능 코드 목록 |
| 11 | data.menuMappings | 메뉴 매핑 | List | Y | 접근 가능 메뉴 목록 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 그룹 ID로 조회 | UserGroupRepository |
| 2 | 코드 매핑 정보 조회 | GroupCodeMappingRepository |
| 3 | 메뉴 매핑 정보 조회 | GroupMenuMappingRepository |
| 4 | 권한 정보 조회 | GroupPermissionRepository |
| 5 | 상세 정보 반환 | |

---

### GRP_004 - 그룹 등록

| 프로그램 ID | GRP_004 | 프로그램명 | 그룹 등록 |
|------------|---------|----------|---------|
| 분류 | 설정 | 처리유형 | 등록 |
| 클래스명 | UserController.java | 메서드명 | saveGroup() |

▣ 기능 설명

새로운 사용자 그룹을 등록한다. 그룹 코드는 영문/숫자/언더스코어만 허용되며 중복 불가.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | groupName | 그룹명 | String | Y | 최대 100자 |
| 2 | groupCode | 그룹 코드 | String | Y | 최대 50자, unique |
| 3 | description | 설명 | String | N | 최대 255자 |
| 4 | status | 상태 | String | Y | Y/N |
| 5 | codeIdxList | 접근 코드 목록 | List<Long> | N | 접근 가능 사업소/호기 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공, 1=실패 |
| 2 | message | 메시지 | String | Y | 결과 메시지 |
| 3 | data | 생성된 그룹 | Object | N | idx, groupName, groupCode |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 그룹 코드 중복 검사 | |
| 2 | 그룹 코드 형식 검증 | 영문/숫자/언더스코어 |
| 3 | 그룹 정보 저장 | UserGroupRepository |
| 4 | 코드 매핑 저장 | GroupCodeMappingRepository |
| 5 | 감사 로그 기록 | @ActivityLog |

---

### GRP_005 - 그룹 수정

| 프로그램 ID | GRP_005 | 프로그램명 | 그룹 수정 |
|------------|---------|----------|---------|
| 분류 | 설정 | 처리유형 | 수정 |
| 클래스명 | UserController.java | 메서드명 | updateGroup() |

▣ 기능 설명

기존 그룹의 정보를 수정한다. 그룹 코드는 수정 불가.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 그룹 ID | Long | Y | |
| 2 | groupName | 그룹명 | String | Y | |
| 3 | description | 설명 | String | N | |
| 4 | status | 상태 | String | Y | Y/N |
| 5 | alarmEnabled | 알람 활성화 | Boolean | N | |
| 6 | alarmLevel | 알람 레벨 | String | N | INFO/WARNING/CRITICAL |
| 7 | codeIdxList | 접근 코드 목록 | List<Long> | N | |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | message | 메시지 | String | Y | 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 그룹 존재 여부 확인 | |
| 2 | 그룹 기본 정보 업데이트 | groupName, description, status |
| 3 | 알람 설정 업데이트 | alarmEnabled, alarmLevel |
| 4 | 기존 코드 매핑 삭제 후 재등록 | |
| 5 | 감사 로그 기록 | |

---

### GRP_006 - 그룹 삭제

| 프로그램 ID | GRP_006 | 프로그램명 | 그룹 삭제 |
|------------|---------|----------|---------|
| 분류 | 설정 | 처리유형 | 삭제 |
| 클래스명 | UserController.java | 메서드명 | deleteGroup() |

▣ 기능 설명

그룹과 관련 매핑 정보를 삭제한다. 소속 사용자가 있으면 삭제 불가.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 그룹 ID | Long | Y | RequestBody |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공, 1=실패 |
| 2 | message | 메시지 | String | Y | 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 그룹 존재 여부 확인 | |
| 2 | 소속 사용자 유무 확인 | 있으면 삭제 불가 |
| 3 | 코드 매핑 삭제 | GroupCodeMappingRepository |
| 4 | 메뉴 매핑 삭제 | GroupMenuMappingRepository |
| 5 | 권한 정보 삭제 | GroupPermissionRepository |
| 6 | 그룹 삭제 | |
| 7 | 감사 로그 기록 | |

---

### GRP_007 - 코드 트리 조회

| 프로그램 ID | GRP_007 | 프로그램명 | 코드 트리 조회 |
|------------|---------|----------|-------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | UserController.java | 메서드명 | getSystemCodeTree() |

▣ 기능 설명

사업소/발전소/호기 코드를 jstree 형식의 트리 구조로 조회한다. 그룹에 이미 매핑된 코드는 선택된 상태로 반환.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | groupIdx | 그룹 ID | Long | N | 선택된 그룹 (선택 상태 표시용) |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | data | 트리 데이터 | List | Y | jstree 형식 |
| 3 | data[].id | 노드 ID | String | Y | 코드 idx |
| 4 | data[].text | 노드 텍스트 | String | Y | 코드명 |
| 5 | data[].parent | 부모 노드 | String | Y | 부모 코드 idx 또는 # |
| 6 | data[].state | 상태 | Object | N | selected, checked 등 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | zone1, zone2, zone3 코드 조회 | 사업소/발전소/호기 |
| 2 | 트리 구조로 변환 | jstree 형식 |
| 3 | 그룹 매핑 정보 조회 | groupIdx가 있으면 |
| 4 | 매핑된 코드 선택 상태 표시 | state.checked = true |

---

### GRP_008 - 메뉴 트리 조회

| 프로그램 ID | GRP_008 | 프로그램명 | 메뉴 트리 조회 |
|------------|---------|----------|-------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | UserController.java | 메서드명 | getMenuTree() |

▣ 기능 설명

메뉴 목록을 jstree 형식으로 조회한다. 각 메뉴 하위에 READ/WRITE/DELETE 권한 노드 포함.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | groupIdx | 그룹 ID | Long | N | 선택된 그룹 (권한 표시용) |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | data | 트리 데이터 | List | Y | jstree 형식 |
| 3 | data[].id | 노드 ID | String | Y | menu_{menuId} 또는 menu_{menuId}_{권한} |
| 4 | data[].text | 노드 텍스트 | String | Y | 메뉴명 또는 권한명 |
| 5 | data[].parent | 부모 노드 | String | Y | |
| 6 | data[].state | 상태 | Object | N | checked 여부 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 활성화된 메뉴 목록 조회 | |
| 2 | 메뉴 트리 구조 생성 | |
| 3 | 메뉴별 권한 노드 추가 | READ, WRITE, DELETE |
| 4 | 그룹 권한 정보 조회 | GroupPermissionRepository |
| 5 | 매핑된 권한 선택 상태 표시 | |

---

### GRP_009 - 그룹 메뉴 권한 수정

| 프로그램 ID | GRP_009 | 프로그램명 | 그룹 메뉴 권한 수정 |
|------------|---------|----------|-----------------|
| 분류 | 설정 | 처리유형 | 수정 |
| 클래스명 | UserController.java | 메서드명 | updateGroupMenus() |

▣ 기능 설명

그룹에 접근 가능한 메뉴 목록을 수정한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | groupIdx | 그룹 ID | Long | Y | |
| 2 | menuIds | 메뉴 ID 목록 | List<Long> | Y | 접근 허용할 메뉴 ID |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | message | 메시지 | String | Y | 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 그룹 존재 여부 확인 | |
| 2 | 기존 메뉴 매핑 삭제 | GroupMenuMappingRepository |
| 3 | 새 메뉴 매핑 저장 | |
| 4 | 감사 로그 기록 | |

---

### GRP_010 - 메뉴별 CRUD 권한 수정

| 프로그램 ID | GRP_010 | 프로그램명 | 메뉴별 CRUD 권한 수정 |
|------------|---------|----------|-------------------|
| 분류 | 설정 | 처리유형 | 수정 |
| 클래스명 | UserController.java | 메서드명 | updateGroupMenuCrudPermissions() |

▣ 기능 설명

그룹에 메뉴별 CRUD 권한을 설정한다. WRITE/DELETE 설정 시 READ는 자동 부여.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | groupIdx | 그룹 ID | Long | Y | |
| 2 | menuPermissions | 메뉴별 권한 | List | Y | 배열 |
| 3 | menuPermissions[].menuId | 메뉴 ID | Long | Y | |
| 4 | menuPermissions[].permissions | 권한 목록 | List<String> | Y | READ/WRITE/DELETE |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | Integer | Y | 0=성공 |
| 2 | message | 메시지 | String | Y | 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 그룹 존재 여부 확인 | |
| 2 | 기존 MENU 타입 권한 삭제 | GroupPermissionRepository |
| 3 | 새 권한 저장 | ResourceType.MENU |
| 4 | WRITE/DELETE 시 READ 자동 추가 | |
| 5 | 감사 로그 기록 | |
