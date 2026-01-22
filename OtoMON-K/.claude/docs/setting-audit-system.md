# 감사로그 설정 (setting/audit) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/setting/audit` |
| **메뉴 ID** | 9000L |
| **권한** | READ/WRITE |
| **한글명** | 감사로그 설정 |
| **목적** | 그룹별 감사로그 표시 여부 및 알람 설정 관리 |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/SettingController.java
Service:    src/main/java/com/otoones/otomon/service/AuditSettingService.java
Template:   src/main/resources/templates/pages/setting/audit.html
Model:      src/main/java/com/otoones/otomon/model/AuditLogSetting.java
DTO:        src/main/java/com/otoones/otomon/dto/AuditSettingDto.java
Repository: src/main/java/com/otoones/otomon/repository/AuditLogSettingRepository.java
```

---

## 컨트롤러 (SettingController.java)

### 페이지 렌더링 (`GET /setting/audit`)

**위치**: `SettingController.java:107-112`

**권한**:
```java
@RequirePermission(menuId = 9000L)
```

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| allGroups | 전체 그룹별 감사로그 설정 목록 (List<AuditSettingDto>) |

### 설정 저장 API

| 메서드 | URL | 권한 | 설명 |
|--------|-----|------|------|
| POST | `/setting/audit/save` | WRITE | 그룹별 알람 설정 저장 |

---

## 프론트엔드 (audit.html)

### 페이지 레이아웃

```
┌─────────────────────────────────────────────────────────────────┐
│ 감사로그 설정                                                    │
├─────────────────────────────────────────────────────────────────┤
│ [!] 각 그룹별로 감사로그 표시 여부와 알람 설정을 관리할 수 있습니다 │
├─────────────────────────────────────────────────────────────────┤
│ 그룹별 감사로그 설정                                              │
├────────────┬─────────────┬─────────────┬────────────────────────┤
│ 그룹       │ 로그 표시   │ 알람 설정   │ 설명                   │
├────────────┼─────────────┼─────────────┼────────────────────────┤
│ ADMIN      │ [v] 권한있음│ [v] 알람   │ ADMIN 그룹             │
│ admin      │ (disabled)  │             │                        │
├────────────┼─────────────┼─────────────┼────────────────────────┤
│ OPERATOR   │ [ ] 권한없음│ [ ] 알람   │ OPERATOR 그룹          │
│ operator   │ (disabled)  │             │                        │
└────────────┴─────────────┴─────────────┴────────────────────────┘
│                                         [초기화] [설정 저장]    │
└─────────────────────────────────────────────────────────────────┘
```

### 테이블 컬럼

| 컬럼 | 설명 | 편집 가능 |
|------|------|----------|
| 그룹 | 그룹명 + 그룹코드 | X |
| 로그 표시 | 감사로그 메뉴 접근 권한 여부 | X (disabled) |
| 알람 설정 | 알람 활성화 토글 | O |
| 설명 | 그룹 설명 | X |

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `resetAuditSetting()` | 모든 알람 설정 초기화 (isAlarm = false) |
| `auditSettingSave()` | 현재 설정 저장 |
| `submitAuditSetting()` | AJAX로 설정 저장 요청 |

### 데이터 흐름

```javascript
// 초기 데이터 로드
const allGroups = /*[[${allGroups}]]*/ [];

// 저장 시 현재 체크박스 상태 수집
_.forEach(allGroups, (v) => {
    v.isAlarm = $('#alarm_' + v.groupIdx).prop('checked');
});

// AJAX 저장
$.ajax({
    url: '/setting/audit/save',
    method: 'POST',
    data: JSON.stringify(allGroups)
});
```

---

## 서비스 (AuditSettingService.java)

### 주요 메서드

| 메서드 | 위치 | 설명 |
|--------|------|------|
| `groupAuditSettingList()` | 40줄 | 전체 그룹별 설정 목록 조회 |
| `saveGroupSettings()` | 73줄 | 그룹별 알람 설정 저장 |
| `isLogDisplayAllowed()` | 96줄 | 그룹의 감사로그 메뉴 접근 권한 체크 |
| `isAlarmEnabledForGroup()` | 102줄 | 그룹의 알람 활성화 여부 체크 |
| `userViewAuditLogs()` | 109줄 | 사용자의 감사로그 접근 권한 체크 |
| `alarmEnabledForRole()` | 129줄 | 사용자의 알람 수신 가능 여부 체크 |

### 설정 조회 로직

```java
public void groupAuditSettingList(Model model) {
    List<UserGroup> groups = userGroupRepository.findAll();
    List<AuditSettingDto> groupList = new ArrayList<>();

    for (UserGroup group : groups) {
        // 그룹별 감사로그 설정 조회 (없으면 기본값 생성)
        AuditLogSetting setting = auditLogSettingRepository
                .findByUserGroupIdx(group.getIdx())
                .orElse(createDefaultSetting(group.getIdx()));

        // 감사로그 목록 메뉴(9090L) 접근 권한 체크
        boolean hasMenuAccess = groupMenuMappingRepository
                .existsByUserGroupIdxAndMenuId(group.getIdx(), AUDIT_LIST_MENU_ID);

        AuditSettingDto dto = new AuditSettingDto();
        dto.setIsDisplay(hasMenuAccess);  // 로그 표시 권한
        dto.setIsAlarm("Y".equals(setting.getIsAlarm()));  // 알람 설정
        groupList.add(dto);
    }
    model.addAttribute("allGroups", groupList);
}
```

### 설정 저장 로직

```java
@ActivityLog(category = "SETTING_MANAGE", action = "UPDATE", resourceType = "AUDIT_LOG_SETTING")
@Transactional
public void saveGroupSettings(List<AuditSettingDto> settings) {
    for(AuditSettingDto dto : settings) {
        // 감사로그 설정 저장
        AuditLogSetting setting = auditLogSettingRepository
                .findByUserGroupIdx(dto.getGroupIdx())
                .orElse(new AuditLogSetting());
        setting.setUserGroupIdx(dto.getGroupIdx());
        setting.setIsAlarm(dto.getIsAlarm() ? "Y" : "N");
        auditLogSettingRepository.save(setting);

        // 권한 그룹의 전체 알람도 함께 활성화/비활성화
        UserGroup group = userGroupRepository.findById(dto.getGroupIdx()).orElse(null);
        if (group != null) {
            group.setAlarmEnabled(dto.getIsAlarm());
            if (group.getAlarmLevel() == null) {
                group.setAlarmLevel("INFO");
            }
            userGroupRepository.save(group);
        }
    }
}
```

### 알람 레벨 우선순위

| 레벨 | 우선순위 |
|------|---------|
| CRITICAL | 3 |
| WARNING | 2 |
| INFO | 1 (기본값) |

---

## 모델 (AuditLogSetting.java)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| id | Long | id | PK |
| userGroupIdx | Long | user_group_idx | 사용자 그룹 FK (unique) |
| isAlarm | String | is_alarm | 알람 활성화 ("Y"/"N") |
| createdDate | LocalDateTime | created_date | 생성일시 |
| updatedDate | LocalDateTime | updated_date | 수정일시 |
| userGroup | UserGroup | - | 관계 매핑 |

---

## DTO (AuditSettingDto)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | Long | 설정 PK |
| groupIdx | Long | 그룹 PK |
| groupName | String | 그룹명 |
| groupCode | String | 그룹 코드 |
| isDisplay | Boolean | 감사로그 메뉴 접근 권한 여부 |
| isAlarm | Boolean | 알람 활성화 여부 |
| role | String | 역할 (레거시) |
| roleName | String | 역할명 (화면 표시용) |
| roleInfo | String | 역할 설명 |

---

## API 엔드포인트 요약

| 메서드 | URL | 권한 | 설명 |
|--------|-----|------|------|
| GET | `/setting/audit` | 9000L READ | 페이지 렌더링 |
| POST | `/setting/audit/save` | 9000L WRITE | 설정 저장 |

---

## 데이터 흐름

### 페이지 로드

```
[Controller] /setting/audit
         ↓
[Service] groupAuditSettingList()
         ↓
[Repository] userGroupRepository.findAll() → 전체 그룹
         ↓
[Service] 각 그룹별 설정 조회
         ↓
[Repository] auditLogSettingRepository.findByUserGroupIdx()
[Repository] groupMenuMappingRepository.existsByUserGroupIdxAndMenuId(9090L)
         ↓
[DTO] AuditSettingDto 조합
         ↓
[Template] 테이블 렌더링
```

### 설정 저장

```
[사용자] 알람 토글 변경 + [설정 저장] 클릭
         ↓
[JS] auditSettingSave() → confirm
         ↓
[JS] submitAuditSetting()
         ↓
[AJAX] POST /setting/audit/save (JSON body)
         ↓
[Controller] saveAuditSettings()
         ↓
[Service] saveGroupSettings()
         ↓
[Repository] AuditLogSetting 저장
[Repository] UserGroup.alarmEnabled 업데이트
         ↓
[ActivityLog] 감사 로그 기록
         ↓
[JS] location.reload()
```

---

## 관련 시스템

### 감사로그 목록 페이지 연동

감사로그 설정은 `/setting/auditList` 페이지와 연동:

| 설정 | 영향 |
|------|------|
| isDisplay (로그 표시) | 그룹의 9090L 메뉴 접근 권한에 따라 결정 |
| isAlarm (알람) | 해당 그룹 사용자에게 감사로그 알람 발송 여부 |

### 알람 수신 조건

사용자가 감사로그 알람을 받으려면:

1. 사용자가 속한 그룹의 `alarmEnabled = true`
2. 해당 그룹의 `AuditLogSetting.isAlarm = "Y"`
3. 이벤트 레벨 >= 그룹의 `alarmLevel`

```java
public boolean alarmEnabledForRole(User user, String eventLevel) {
    for (UserGroup group : user.getGroups()) {
        if (!group.getAlarmEnabled()) continue;
        if (!isAlarmEnabledForGroup(group.getIdx())) continue;
        if (eventPriority >= groupPriority) return true;
    }
    return false;
}
```

---

## 감사 로그

`@ActivityLog` 어노테이션으로 설정 변경 자동 기록:

| 작업 | category | action | resourceType |
|------|----------|--------|--------------|
| 설정 저장 | SETTING_MANAGE | UPDATE | AUDIT_LOG_SETTING |

---

## 권한 처리

프론트엔드에서 권한에 따라 버튼 표시/숨김:

```html
<!-- WRITE 권한이 있을 때만 초기화/저장 버튼 표시 -->
<div th:if="${userPermissions?.canWrite}">
    <button id="btnReset">초기화</button>
    <button id="btnSave">설정 저장</button>
</div>
```

---

## 다국어 메시지

| 메시지 키 | 설명 |
|----------|------|
| `menu.setting.audit` | 페이지 제목 |
| `setting.operate.setting.title` | 패널 제목 |
| `setting.operate.page.info` | 안내문 |
| `setting.operate.group.title` | 그룹별 설정 카드 제목 |
| `setting.operate.table.*` | 테이블 헤더 |
| `setting.operate.reset.info` | 초기화 확인 메시지 |
| `setting.operate.save.info` | 저장 확인 메시지 |

---

## 관련 문서

- [감사로그 목록](setting-audit-list-system.md) - 감사로그 조회 페이지
- [감사 로그](audit-log-system.md) - 감사 로그 시스템
- [권한 시스템](permission-system.md) - 그룹별 권한 관리
- [알람 시스템](alarm-system.md) - 알람 발송

---

## 프로그램 명세서

### SAU_001 - 감사로그 설정 페이지

| 프로그램 ID | SAU_001 | 프로그램명 | 감사로그 설정 페이지 |
|------------|---------|----------|------------------|
| 분류 | 설정 관리 | 처리유형 | 화면 |
| 클래스명 | SettingController.java | 메서드명 | auditPage() |

▣ 기능 설명

그룹별 감사로그 표시 여부 및 알람 설정을 관리하는 페이지를 렌더링한다. 각 그룹의 감사로그 메뉴 접근 권한과 알람 활성화 상태를 테이블 형태로 표시한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 파라미터 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | allGroups | 그룹별 설정 목록 | List<AuditSettingDto> | Y | 전체 그룹 감사로그 설정 |
| 2 | allGroups[].groupIdx | 그룹 PK | Long | Y | 그룹 ID |
| 3 | allGroups[].groupName | 그룹명 | String | Y | 그룹 이름 |
| 4 | allGroups[].groupCode | 그룹 코드 | String | Y | 그룹 코드 |
| 5 | allGroups[].isDisplay | 로그 표시 권한 | Boolean | Y | 감사로그 메뉴 접근 권한 |
| 6 | allGroups[].isAlarm | 알람 설정 | Boolean | Y | 알람 활성화 여부 |
| 7 | allGroups[].roleInfo | 그룹 설명 | String | N | 그룹 설명 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | @RequirePermission(menuId = 9000L) |
| 2 | 전체 그룹 목록 조회 | userGroupRepository.findAll() |
| 3 | 각 그룹별 감사로그 설정 조회 | findByUserGroupIdx() |
| 4 | 설정 없으면 기본값 생성 | isAlarm = "N" |
| 5 | 그룹의 감사로그 메뉴(9090L) 접근 권한 조회 | groupMenuMappingRepository |
| 6 | DTO 조합 후 Model에 추가 | allGroups |
| 7 | 뷰 반환 | pages/setting/audit |

---

### SAU_002 - 감사로그 설정 저장 API

| 프로그램 ID | SAU_002 | 프로그램명 | 감사로그 설정 저장 API |
|------------|---------|----------|---------------------|
| 분류 | 설정 관리 | 처리유형 | 수정 |
| 클래스명 | SettingController.java | 메서드명 | saveAuditSettings() |

▣ 기능 설명

그룹별 감사로그 알람 설정을 저장한다. 알람 활성화 시 해당 그룹의 UserGroup.alarmEnabled도 함께 업데이트한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | settings | 설정 목록 | List<AuditSettingDto> | Y | RequestBody (JSON) |
| 2 | settings[].groupIdx | 그룹 PK | Long | Y | 그룹 ID |
| 3 | settings[].isAlarm | 알람 설정 | Boolean | Y | 알람 활성화 여부 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 각 그룹별 설정 조회/생성 | findByUserGroupIdx() or new |
| 3 | isAlarm 값 업데이트 | "Y" / "N" |
| 4 | AuditLogSetting 저장 | auditLogSettingRepository.save() |
| 5 | UserGroup.alarmEnabled 동기화 | 알람 활성화 상태 연동 |
| 6 | alarmLevel 기본값 설정 | null이면 "INFO" |
| 7 | UserGroup 저장 | userGroupRepository.save() |
| 8 | 감사 로그 기록 | @ActivityLog(UPDATE) |
| 9 | 결과 반환 | JSON 응답 |

▣ 알람 연동 로직

| 설정 | AuditLogSetting.isAlarm | UserGroup.alarmEnabled | 효과 |
|------|------------------------|----------------------|------|
| 알람 활성화 | "Y" | true | 해당 그룹 사용자에게 감사로그 알람 발송 |
| 알람 비활성화 | "N" | false | 해당 그룹 알람 수신 안함 |

▣ 알람 수신 조건

사용자가 감사로그 알람을 받으려면 다음 조건을 모두 만족해야 함:

| 순서 | 조건 | 설명 |
|------|------|------|
| 1 | UserGroup.alarmEnabled = true | 그룹 알람 활성화 |
| 2 | AuditLogSetting.isAlarm = "Y" | 감사로그 알람 설정 |
| 3 | eventPriority >= groupPriority | 이벤트 레벨이 그룹 설정 이상 |

▣ 알람 레벨 우선순위

| 레벨 | 우선순위 | 설명 |
|------|---------|------|
| CRITICAL | 3 | 중요 알람 |
| WARNING | 2 | 경고 알람 |
| INFO | 1 | 일반 알람 (기본값) |

