# 알람 설정 (setting/alarm) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/setting/alarm` |
| **메뉴 ID** | 9000L |
| **권한** | READ/WRITE/DELETE |
| **한글명** | 알람 설정 |
| **목적** | 시스템 알람 이벤트 관리 (생성/수정/삭제, 담당자 지정, 활성화 토글) |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/SettingController.java
            src/main/java/com/otoones/otomon/controller/AlarmController.java
Service:    src/main/java/com/otoones/otomon/service/AlarmService.java
            src/main/java/com/otoones/otomon/service/AlarmNotificationService.java
Template:   src/main/resources/templates/pages/setting/alarm.html
Model:      src/main/java/com/otoones/otomon/model/AlarmConfig.java
            src/main/java/com/otoones/otomon/model/AlarmManager.java
            src/main/java/com/otoones/otomon/model/AlarmTypeCode.java
            src/main/java/com/otoones/otomon/model/AlarmLevelCode.java
            src/main/java/com/otoones/otomon/model/AlarmAction.java
DTO:        src/main/java/com/otoones/otomon/dto/AlarmDto.java
```

---

## 컨트롤러

### SettingController (`GET /setting/alarm`)

**위치**: `SettingController.java:115-160`

**권한**:
```java
@RequirePermission(menuId = 9000L)
```

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| alarmTypes | 알람 유형 목록 (Map<String, Map<String, String>>) |
| alarmLevels | 알람 레벨 목록 (Map<String, String>) |
| alarms | 알람 설정 목록 (List<AlarmDto>) |

### AlarmController (`/setting/alarm`)

REST API 컨트롤러:

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/setting/alarm/list` | 알람 목록 조회 |
| GET | `/setting/alarm/{id}` | 알람 상세 조회 |
| POST | `/setting/alarm` | 알람 생성 |
| PUT | `/setting/alarm/{id}` | 알람 수정 |
| DELETE | `/setting/alarm/{id}` | 알람 삭제 |
| POST | `/setting/alarm/{id}/toggle` | 활성화/비활성화 토글 |
| GET | `/setting/alarm/{id}/managers` | 담당자 목록 조회 |
| POST | `/setting/alarm/{id}/managers` | 담당자 추가 |
| DELETE | `/setting/alarm/{id}/managers/{managerId}` | 담당자 삭제 |
| POST | `/setting/alarm/{id}/managers/batch` | 담당자 일괄 처리 |
| GET | `/setting/alarm/{id}/available-users` | 할당 가능 사용자 조회 |
| GET | `/setting/alarm/{id}/actions` | 조치사항 목록 조회 |

---

## 프론트엔드 (alarm.html)

### 페이지 레이아웃

```
┌─────────────────────────────────────────────────────────────────────┐
│ 알람 설정 관리                                        [알람 추가]   │
├─────────────────────────────────────────────────────────────────────┤
│ [!] 시스템 알람 설정을 관리할 수 있습니다.                          │
├─────────────────────────────────────────────────────────────────────┤
│ 알람 이벤트 설정                                                    │
├──────┬────────────┬──────────┬────────┬────────┬────────┬──────────┤
│ 순번 │ 알람명     │ 유형     │ 레벨   │ 상태   │ 담당자 │ 관리     │
├──────┼────────────┼──────────┼────────┼────────┼────────┼──────────┤
│ 1    │ 네트워크   │ NETWORK  │ 심각   │ [v]    │ 홍길동 │ [수정]   │
│      │ 이상탐지   │ (bg-pri) │(bg-dan)│ 토글   │ [수정] │ [삭제]   │
├──────┼────────────┼──────────┼────────┼────────┼────────┼──────────┤
│ 2    │ 이벤트     │ EVENT    │ 정보   │ [v]    │ 전체   │ 자동생성 │
│      │ 알람       │ (table-  │(bg-inf)│(disabl)│ 발송   │ (locked) │
│      │            │ active)  │        │        │        │          │
└──────┴────────────┴──────────┴────────┴────────┴────────┴──────────┘
```

### 알람 유형 (AlarmTypeCode)

| 코드 | 이름 | 배지 색상 | 카테고리 |
|------|------|----------|----------|
| NETWORK | 네트워크 | bg-primary | SECURITY |
| AUDIT | 감사로그 | bg-success | SYSTEM |
| OPERATION | 운전정보 | bg-info | OT |
| ASSET | 자산변경 | bg-secondary | OT |
| EVENT | 이벤트 | table-active (행 전체) | - |

### 알람 레벨 (AlarmLevelCode)

| 코드 | 이름 | 배지 색상 | 우선순위 |
|------|------|----------|----------|
| INFO | 정보 | bg-info | 1 |
| WARNING | 경고 | bg-warning | 2 |
| CRITICAL | 심각 | bg-danger | 3 |

### EVENT 타입 특수 처리

`alarmType == 'EVENT'`인 알람은 자동 생성 알람으로 특별 처리:
- 활성화 토글: disabled (수정 불가)
- 담당자: "전체 발송" 표시
- 관리 버튼: "자동 생성" + 자물쇠 아이콘 (수정/삭제 불가)
- 행 스타일: `table-active` 클래스 적용

### 모달

#### 1. 알람 추가/수정 모달 (`#alarmModal`)

| 필드 | ID | 타입 | 필수 | 설명 |
|------|-----|------|------|------|
| 알람명 | alarmName | text | O | - |
| 알람 코드 | alarmCode | text | O | 자동 생성 (hidden) |
| 알람 유형 | alarmType | select | O | AlarmTypeCode 목록 |
| 알람 레벨 | alarmLevel | select | O | AlarmLevelCode 목록 |
| 설명 | alarmDescription | textarea | X | - |

#### 2. 담당자 관리 모달 (`#managerModal`)

**구조**:
- 현재 담당자 목록 (체크박스로 해제 가능)
- 추가 가능한 사용자 목록 (체크박스로 선택 가능)
- 일괄 저장 버튼

| 컬럼 | 설명 |
|------|------|
| 선택 | 체크박스 |
| 이름 | 사용자명 |
| 이메일 | 이메일 주소 |
| 권한 | 사용자 역할 |
| 작업 | 상태 배지 (담당중/미지정) |

#### 3. 조치사항 관리 모달 (`#actionModal`)

조치사항 추가/삭제 (prompt 다이얼로그 사용)

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `openAlarmModal()` | 알람 추가 모달 오픈 |
| `editAlarm(id)` | 알람 수정 모달 오픈 |
| `saveAlarm()` | 알람 저장 (POST/PUT) |
| `deleteAlarm(id)` | 알람 삭제 |
| `toggleAlarm(id, enabled)` | 활성화/비활성화 토글 |
| `manageManager(alarmId)` | 담당자 관리 모달 오픈 |
| `renderManagerList()` | 담당자 목록 렌더링 |
| `renderUserSelectionList()` | 사용자 선택 목록 렌더링 |
| `saveSelectedManagers()` | 담당자 일괄 저장 |
| `generateAlarmCodeFromType()` | 알람 코드 자동 생성 |
| `refreshPage()` | 테이블 영역만 새로고침 (AJAX) |
| `loadAlarmList()` | 알람 목록 로드 |
| `showSuccessToast()` | 성공 토스트 표시 |

---

## 모델

### AlarmConfig (알람 설정)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| id | Long | id | PK |
| alarmName | String | alarm_name | 알람명 |
| alarmCode | String | alarm_code | 알람 코드 (unique) |
| alarmType | String | alarm_type | 유형 (NETWORK/AUDIT/OPERATION) |
| alarmLevel | String | alarm_level | 레벨 (INFO/WARNING/CRITICAL) |
| trapLevel | String | trap_level | 조치항목 레벨 |
| isEnabled | Boolean | is_enabled | 활성화 여부 |
| url | String | url | 연결 URL |
| description | String | description | 설명 |
| managers | List<AlarmManager> | - | 담당자 목록 (OneToMany) |
| actions | List<AlarmAction> | - | 조치사항 목록 (OneToMany) |
| createdAt | LocalDateTime | created_at | 생성일시 |
| updatedAt | LocalDateTime | updated_at | 수정일시 |

### AlarmManager (알람 담당자)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| id | Long | id | PK |
| alarmConfig | AlarmConfig | alarm_config_id | 알람 설정 FK |
| userId | String | user_id | 사용자 ID |
| userName | String | user_name | 사용자명 |
| email | String | email | 이메일 |
| phone | String | phone | 전화번호 |
| role | UserRole | role | 역할 |
| isPrimary | Boolean | is_primary | 주담당자 여부 |
| createdAt | LocalDateTime | created_at | 생성일시 |

### AlarmTypeCode (알람 유형 코드)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| code | String | code | PK (NETWORK/AUDIT/OPERATION) |
| name | String | name | 유형명 |
| category | String | category | 카테고리 (SYSTEM/SECURITY/OT) |
| url | String | url | 기본 URL |
| isActive | Boolean | is_active | 활성화 여부 |
| displayOrder | Integer | display_order | 표시 순서 |

### AlarmLevelCode (알람 레벨 코드)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| code | String | code | PK (INFO/WARNING/CRITICAL) |
| name | String | name | 레벨명 |
| priority | Integer | priority | 우선순위 (1~3) |
| colorClass | String | color_class | CSS 클래스 |
| isActive | Boolean | is_active | 활성화 여부 |

---

## 서비스 (AlarmService.java)

### 주요 메서드

| 메서드 | 위치 | 설명 |
|--------|------|------|
| `getAllAlarms()` | 38줄 | 전체 알람 목록 조회 |
| `getAlarmById()` | 53줄 | 알람 상세 조회 |
| `createAlarm()` | 64줄 | 알람 생성 (중복 코드 체크) |
| `updateAlarm()` | 93줄 | 알람 수정 |
| `deleteAlarm()` | 123줄 | 알람 삭제 |
| `toggleAlarm()` | 134줄 | 활성화/비활성화 토글 |
| `getManagersByAlarmId()` | 145줄 | 담당자 목록 조회 |
| `addManager()` | 157줄 | 담당자 추가 (중복 체크) |
| `batchUpdateManagers()` | 184줄 | 담당자 일괄 처리 |
| `removeManager()` | 242줄 | 담당자 삭제 |
| `getActionsByAlarmId()` | 257줄 | 조치사항 목록 조회 |
| `getEnabledAlarms()` | 269줄 | 활성화된 알람 목록 |
| `getAlarmsByType()` | 276줄 | 타입별 알람 조회 |
| `notifyAlarmConfigChange()` | 362줄 | 설정 변경 알림 발송 |

### 중복 체크 로직

```java
// 알람 코드 중복 체크
if (alarmConfigRepository.existsByAlarmCode(dto.getAlarmCode())) {
    throw new RuntimeException("중복된 알람 코드");
}

// 담당자 중복 체크
boolean exists = alarmManagerRepository.existsByAlarmConfigIdAndEmail(alarmId, dto.getEmail());
if (exists) {
    throw new RuntimeException("이미 등록된 담당자");
}
```

### 설정 변경 알림

알람 설정 변경 시 담당자들에게 WebSocket 알림 발송:

```java
private void notifyAlarmConfigChange(AlarmConfig alarmConfig, String changeType) {
    Set<String> notifiedUsers = new HashSet<>();  // 중복 방지

    for (AlarmManager manager : managers) {
        if (notifiedUsers.contains(manager.getUserName())) continue;

        AlarmHistoryDto notification = new AlarmHistoryDto();
        notification.setTitle("알람 설정 변경");
        notification.setMessage(String.format("'%s'이(가) %s되었습니다.",
            alarmConfig.getAlarmName(), changeType));

        alarmNotificationService.createAndPushAlarm(notification);
        notifiedUsers.add(manager.getUserName());
    }
}
```

---

## API 엔드포인트 요약

| 메서드 | URL | 권한 | 설명 |
|--------|-----|------|------|
| GET | `/setting/alarm` | 9000L READ | 페이지 렌더링 |
| GET | `/setting/alarm/list` | READ | 알람 목록 (JSON) |
| GET | `/setting/alarm/{id}` | - | 알람 상세 |
| POST | `/setting/alarm` | - | 알람 생성 |
| PUT | `/setting/alarm/{id}` | - | 알람 수정 |
| DELETE | `/setting/alarm/{id}` | - | 알람 삭제 |
| POST | `/setting/alarm/{id}/toggle` | - | 활성화 토글 |
| GET | `/setting/alarm/{id}/managers` | - | 담당자 목록 |
| POST | `/setting/alarm/{id}/managers` | - | 담당자 추가 |
| DELETE | `/setting/alarm/{id}/managers/{managerId}` | - | 담당자 삭제 |
| POST | `/setting/alarm/{id}/managers/batch` | - | 담당자 일괄 처리 |
| GET | `/setting/alarm/{id}/available-users` | - | 할당 가능 사용자 |
| GET | `/setting/alarm/{id}/actions` | - | 조치사항 목록 |

---

## 데이터 흐름

### 페이지 로드

```
[Controller] /setting/alarm
         ↓
[Repository] alarmTypeCodeRepository.findByIsActiveTrueOrderByDisplayOrder()
[Repository] alarmLevelCodeRepository.findByIsActiveTrueOrderByPriority()
[Service] alarmService.getAllAlarms()
         ↓
[Model] alarmTypes, alarmLevels, alarms
         ↓
[Template] 테이블 렌더링 (EVENT 타입 특수 처리)
```

### 알람 저장

```
[모달] saveAlarm()
         ↓
[JS] generateAlarmCodeFromType() → 코드 자동 생성
         ↓
[AJAX] POST/PUT /setting/alarm/{id}
         ↓
[Controller] createAlarm() / updateAlarm()
         ↓
[Service] 중복 체크 + 저장
         ↓
[Service] notifyAlarmConfigChange() → 담당자 알림
         ↓
[ActivityLog] 감사 로그 기록
         ↓
[JS] refreshPage() → 테이블 부분 갱신
```

### 담당자 일괄 처리

```
[모달] saveSelectedManagers()
         ↓
[JS] 체크박스 상태 수집 (toAdd, toRemove)
         ↓
[AJAX] POST /setting/alarm/{id}/managers/batch
         ↓
[Controller] batchUpdateManagers()
         ↓
[Service] 삭제 처리 (toRemove)
[Service] 추가 처리 (toAdd, 중복 체크)
         ↓
[Service] notifyAlarmConfigChange()
         ↓
[JS] refreshPage()
```

---

## 감사 로그

`@ActivityLog` 어노테이션으로 CRUD 작업 자동 기록:

| 작업 | category | action | resourceType |
|------|----------|--------|--------------|
| 알람 생성 | ALARM_SYSTEM | ADD | ALARM |
| 알람 수정 | ALARM_SYSTEM | UPDATE | ALARM |
| 알람 삭제 | ALARM_SYSTEM | DELETE | ALARM |
| 담당자 추가 | MANAGER_SYSTEM | ADD | MANAGER |
| 담당자 삭제 | MANAGER_SYSTEM | DELETE | MANAGER |
| 담당자 일괄 | MANAGER_SYSTEM | BATCH_UPDATE | MANAGER |

---

## 권한 처리

프론트엔드에서 권한에 따라 버튼 표시/숨김:

```html
<!-- 알람 추가 버튼: WRITE 권한 -->
<button th:if="${userPermissions?.canWrite}">알람 추가</button>

<!-- 수정 버튼: WRITE 권한 + EVENT 타입 아님 -->
<button th:if="${userPermissions?.canWrite}"
        th:unless="${alarm.alarmType == 'EVENT'}">수정</button>

<!-- 삭제 버튼: DELETE 권한 + EVENT 타입 아님 -->
<button th:if="${userPermissions?.canDelete}"
        th:unless="${alarm.alarmType == 'EVENT'}">삭제</button>
```

---

## 다국어 메시지

| 메시지 키 | 설명 |
|----------|------|
| `menu.setting.alarm` | 페이지 제목 |
| `setting.alarm.title` | 패널 제목 |
| `setting.alarm.btn.add` | 알람 추가 버튼 |
| `setting.alarm.save.success` | 저장 성공 |
| `setting.alarm.save.fail` | 저장 실패 |
| `setting.alarm.confirm.deleted` | 삭제 확인 |
| `setting.alarm.status.success` | 상태 변경 성공 |
| `setting.alarm.manager.add.success` | 담당자 추가 성공 |
| `setting.alarm.manager.change.success` | 담당자 업데이트 성공 |

---

## 관련 문서

- [감사로그 설정](setting-audit-system.md) - 그룹별 알람 설정
- [알람 이력](setting-alarm-list-system.md) - 알람 발송 이력
- [이상 이벤트 탐지 정책](policy-timeseries-system.md) - 이벤트 알람 연동
- [WebSocket](frontend-patterns.md) - 실시간 알람 발송

---

## 프로그램 명세서

### SAL_001 - 알람 설정 페이지

| 프로그램 ID | SAL_001 | 프로그램명 | 알람 설정 페이지 |
|------------|---------|----------|---------------|
| 분류 | 설정 관리 | 처리유형 | 화면 |
| 클래스명 | SettingController.java | 메서드명 | alarmPage() |

▣ 기능 설명

시스템 알람 이벤트를 관리하는 페이지를 렌더링한다. 알람 유형/레벨별 목록을 표시하고, 담당자 지정 및 활성화 토글 기능을 제공한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 파라미터 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | alarmTypes | 알람 유형 목록 | Map<String, Map<String, String>> | Y | NETWORK, AUDIT 등 |
| 2 | alarmLevels | 알람 레벨 목록 | Map<String, String> | Y | INFO, WARNING, CRITICAL |
| 3 | alarms | 알람 설정 목록 | List<AlarmDto> | Y | 전체 알람 목록 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | @RequirePermission(menuId = 9000L) |
| 2 | 활성화된 알람 유형 조회 | findByIsActiveTrueOrderByDisplayOrder() |
| 3 | 활성화된 알람 레벨 조회 | findByIsActiveTrueOrderByPriority() |
| 4 | 전체 알람 목록 조회 | getAllAlarms() |
| 5 | Model에 데이터 추가 | alarmTypes, alarmLevels, alarms |
| 6 | 뷰 반환 | pages/setting/alarm |

---

### SAL_002 - 알람 목록 조회 API

| 프로그램 ID | SAL_002 | 프로그램명 | 알람 목록 조회 API |
|------------|---------|----------|-----------------|
| 분류 | 알람 조회 | 처리유형 | 조회 |
| 클래스명 | AlarmController.java | 메서드명 | getAlarmList() |

▣ 기능 설명

전체 알람 설정 목록을 JSON으로 반환한다. 테이블 부분 갱신(refreshPage)에 사용된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 파라미터 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 알람 목록 | List<AlarmDto> | Y | 알람 설정 목록 |
| 3 | data[].id | 알람 ID | Long | Y | PK |
| 4 | data[].alarmName | 알람명 | String | Y | - |
| 5 | data[].alarmCode | 알람 코드 | String | Y | unique |
| 6 | data[].alarmType | 유형 | String | Y | NETWORK/AUDIT 등 |
| 7 | data[].alarmLevel | 레벨 | String | Y | INFO/WARNING/CRITICAL |
| 8 | data[].isEnabled | 활성화 | Boolean | Y | - |
| 9 | data[].managers | 담당자 목록 | List | N | - |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 전체 알람 조회 | getAllAlarms() |
| 2 | DTO 변환 | Entity → AlarmDto |
| 3 | 결과 반환 | JSON 응답 |

---

### SAL_003 - 알람 상세 조회 API

| 프로그램 ID | SAL_003 | 프로그램명 | 알람 상세 조회 API |
|------------|---------|----------|-----------------|
| 분류 | 알람 조회 | 처리유형 | 조회 |
| 클래스명 | AlarmController.java | 메서드명 | getAlarm() |

▣ 기능 설명

특정 알람의 상세 정보를 조회한다. 수정 모달에서 사용된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 알람 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 알람 정보 | AlarmDto | Y | 상세 정보 |
| 3 | data.id | 알람 ID | Long | Y | PK |
| 4 | data.alarmName | 알람명 | String | Y | - |
| 5 | data.alarmCode | 알람 코드 | String | Y | - |
| 6 | data.alarmType | 유형 | String | Y | - |
| 7 | data.alarmLevel | 레벨 | String | Y | - |
| 8 | data.description | 설명 | String | N | - |
| 9 | data.isEnabled | 활성화 | Boolean | Y | - |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 알람 조회 | findById() |
| 2 | 존재하지 않으면 예외 | RuntimeException |
| 3 | DTO 변환 및 반환 | JSON 응답 |

---

### SAL_004 - 알람 생성 API

| 프로그램 ID | SAL_004 | 프로그램명 | 알람 생성 API |
|------------|---------|----------|-------------|
| 분류 | 알람 관리 | 처리유형 | 등록 |
| 클래스명 | AlarmController.java | 메서드명 | createAlarm() |

▣ 기능 설명

새로운 알람 설정을 생성한다. 알람 코드 중복 체크 후 저장하고, 담당자에게 설정 변경 알림을 발송한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | alarmName | 알람명 | String | Y | - |
| 2 | alarmCode | 알람 코드 | String | Y | 자동 생성 (unique) |
| 3 | alarmType | 유형 | String | Y | NETWORK/AUDIT/OPERATION |
| 4 | alarmLevel | 레벨 | String | Y | INFO/WARNING/CRITICAL |
| 5 | description | 설명 | String | N | - |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 생성된 알람 | AlarmDto | N | 성공 시 알람 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 알람 코드 중복 체크 | existsByAlarmCode() |
| 3 | AlarmConfig Entity 생성 | isEnabled = true (기본값) |
| 4 | 저장 | alarmConfigRepository.save() |
| 5 | 감사 로그 기록 | @ActivityLog(ADD) |
| 6 | 결과 반환 | JSON 응답 |

---

### SAL_005 - 알람 수정 API

| 프로그램 ID | SAL_005 | 프로그램명 | 알람 수정 API |
|------------|---------|----------|-------------|
| 분류 | 알람 관리 | 처리유형 | 수정 |
| 클래스명 | AlarmController.java | 메서드명 | updateAlarm() |

▣ 기능 설명

기존 알람 설정을 수정한다. EVENT 타입 알람은 수정 불가하다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 알람 ID | Long | Y | PathVariable |
| 2 | alarmName | 알람명 | String | Y | - |
| 3 | alarmType | 유형 | String | Y | - |
| 4 | alarmLevel | 레벨 | String | Y | - |
| 5 | description | 설명 | String | N | - |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 수정된 알람 | AlarmDto | N | 성공 시 알람 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 알람 조회 | findById() |
| 3 | EVENT 타입 체크 | EVENT면 수정 불가 |
| 4 | 알람 정보 업데이트 | - |
| 5 | 저장 | save() |
| 6 | 설정 변경 알림 발송 | notifyAlarmConfigChange() |
| 7 | 감사 로그 기록 | @ActivityLog(UPDATE) |
| 8 | 결과 반환 | JSON 응답 |

---

### SAL_006 - 알람 삭제 API

| 프로그램 ID | SAL_006 | 프로그램명 | 알람 삭제 API |
|------------|---------|----------|-------------|
| 분류 | 알람 관리 | 처리유형 | 삭제 |
| 클래스명 | AlarmController.java | 메서드명 | deleteAlarm() |

▣ 기능 설명

알람 설정을 삭제한다. EVENT 타입 알람은 삭제 불가하다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 알람 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | DELETE 권한 필요 |
| 2 | 알람 조회 | findById() |
| 3 | EVENT 타입 체크 | EVENT면 삭제 불가 |
| 4 | 관련 담당자 삭제 | CASCADE |
| 5 | 알람 삭제 | delete() |
| 6 | 감사 로그 기록 | @ActivityLog(DELETE) |
| 7 | 결과 반환 | JSON 응답 |

---

### SAL_007 - 알람 활성화 토글 API

| 프로그램 ID | SAL_007 | 프로그램명 | 알람 활성화 토글 API |
|------------|---------|----------|-------------------|
| 분류 | 알람 관리 | 처리유형 | 수정 |
| 클래스명 | AlarmController.java | 메서드명 | toggleAlarm() |

▣ 기능 설명

알람의 활성화/비활성화 상태를 토글한다. EVENT 타입은 토글 불가하다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 알람 ID | Long | Y | PathVariable |
| 2 | enabled | 활성화 여부 | Boolean | Y | RequestBody |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data.isEnabled | 변경된 상태 | Boolean | Y | 현재 활성화 상태 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 알람 조회 | findById() |
| 2 | EVENT 타입 체크 | EVENT면 토글 불가 |
| 3 | isEnabled 값 변경 | - |
| 4 | 저장 | save() |
| 5 | 결과 반환 | JSON 응답 |

---

### SAL_008 - 담당자 목록 조회 API

| 프로그램 ID | SAL_008 | 프로그램명 | 담당자 목록 조회 API |
|------------|---------|----------|-------------------|
| 분류 | 담당자 관리 | 처리유형 | 조회 |
| 클래스명 | AlarmController.java | 메서드명 | getManagers() |

▣ 기능 설명

특정 알람에 지정된 담당자 목록을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 알람 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 담당자 목록 | List<AlarmManager> | Y | 담당자 정보 |
| 3 | data[].id | 담당자 ID | Long | Y | PK |
| 4 | data[].userName | 이름 | String | Y | - |
| 5 | data[].email | 이메일 | String | Y | - |
| 6 | data[].role | 권한 | String | Y | ADMIN/USER |
| 7 | data[].isPrimary | 주담당자 | Boolean | Y | - |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 알람 ID로 담당자 조회 | getManagersByAlarmId() |
| 2 | 결과 반환 | JSON 응답 |

---

### SAL_009 - 담당자 추가 API

| 프로그램 ID | SAL_009 | 프로그램명 | 담당자 추가 API |
|------------|---------|----------|---------------|
| 분류 | 담당자 관리 | 처리유형 | 등록 |
| 클래스명 | AlarmController.java | 메서드명 | addManager() |

▣ 기능 설명

알람에 새로운 담당자를 추가한다. 이미 등록된 담당자는 중복 체크로 거부한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 알람 ID | Long | Y | PathVariable |
| 2 | userId | 사용자 ID | String | Y | - |
| 3 | userName | 사용자명 | String | Y | - |
| 4 | email | 이메일 | String | Y | - |
| 5 | role | 권한 | String | Y | ADMIN/USER |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 추가된 담당자 | AlarmManager | N | 성공 시 담당자 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 알람 존재 확인 | findById() |
| 2 | 담당자 중복 체크 | existsByAlarmConfigIdAndEmail() |
| 3 | AlarmManager Entity 생성 | isPrimary = false (기본값) |
| 4 | 저장 | save() |
| 5 | 감사 로그 기록 | @ActivityLog(ADD) |
| 6 | 결과 반환 | JSON 응답 |

---

### SAL_010 - 담당자 삭제 API

| 프로그램 ID | SAL_010 | 프로그램명 | 담당자 삭제 API |
|------------|---------|----------|---------------|
| 분류 | 담당자 관리 | 처리유형 | 삭제 |
| 클래스명 | AlarmController.java | 메서드명 | removeManager() |

▣ 기능 설명

알람에서 담당자를 삭제한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 알람 ID | Long | Y | PathVariable |
| 2 | managerId | 담당자 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 담당자 조회 | findById() |
| 2 | 알람 ID 일치 확인 | 보안 체크 |
| 3 | 삭제 | delete() |
| 4 | 감사 로그 기록 | @ActivityLog(DELETE) |
| 5 | 결과 반환 | JSON 응답 |

---

### SAL_011 - 담당자 일괄 처리 API

| 프로그램 ID | SAL_011 | 프로그램명 | 담당자 일괄 처리 API |
|------------|---------|----------|-------------------|
| 분류 | 담당자 관리 | 처리유형 | 수정 |
| 클래스명 | AlarmController.java | 메서드명 | batchUpdateManagers() |

▣ 기능 설명

담당자 추가/삭제를 일괄 처리한다. 모달에서 체크박스로 선택한 사용자를 한 번에 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 알람 ID | Long | Y | PathVariable |
| 2 | toAdd | 추가할 사용자 | List<ManagerDto> | N | 신규 담당자 목록 |
| 3 | toRemove | 삭제할 담당자 | List<Long> | N | 담당자 ID 목록 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data.added | 추가된 수 | Integer | Y | 추가 성공 건수 |
| 4 | data.removed | 삭제된 수 | Integer | Y | 삭제 성공 건수 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 알람 존재 확인 | findById() |
| 2 | 삭제 목록 처리 | toRemove 순회 → delete() |
| 3 | 추가 목록 처리 | toAdd 순회 → 중복 체크 → save() |
| 4 | 설정 변경 알림 발송 | notifyAlarmConfigChange() |
| 5 | 감사 로그 기록 | @ActivityLog(BATCH_UPDATE) |
| 6 | 결과 반환 | 추가/삭제 건수 포함 |

---

### SAL_012 - 할당 가능 사용자 조회 API

| 프로그램 ID | SAL_012 | 프로그램명 | 할당 가능 사용자 조회 API |
|------------|---------|----------|----------------------|
| 분류 | 담당자 관리 | 처리유형 | 조회 |
| 클래스명 | AlarmController.java | 메서드명 | getAvailableUsers() |

▣ 기능 설명

특정 알람에 담당자로 추가 가능한 사용자 목록을 조회한다. 이미 담당자로 지정된 사용자도 포함하여 현재 상태를 표시한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 알람 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 사용자 목록 | List<UserDto> | Y | 전체 활성 사용자 |
| 3 | data[].idx | 사용자 ID | Long | Y | PK |
| 4 | data[].name | 이름 | String | Y | - |
| 5 | data[].email | 이메일 | String | Y | - |
| 6 | data[].role | 권한 | String | Y | - |
| 7 | data[].isAssigned | 담당자 여부 | Boolean | Y | 현재 담당자인지 |
| 8 | data[].managerId | 담당자 ID | Long | N | 담당자면 ID |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 전체 활성 사용자 조회 | status = "Y" |
| 2 | 현재 담당자 목록 조회 | getManagersByAlarmId() |
| 3 | 사용자별 담당자 여부 매핑 | isAssigned, managerId |
| 4 | 결과 반환 | JSON 응답 |

---

### SAL_013 - 조치사항 목록 조회 API

| 프로그램 ID | SAL_013 | 프로그램명 | 조치사항 목록 조회 API |
|------------|---------|----------|---------------------|
| 분류 | 조치사항 관리 | 처리유형 | 조회 |
| 클래스명 | AlarmController.java | 메서드명 | getActions() |

▣ 기능 설명

특정 알람에 등록된 조치사항 목록을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 알람 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 조치사항 목록 | List<AlarmAction> | Y | 조치사항 정보 |
| 3 | data[].id | 조치사항 ID | Long | Y | PK |
| 4 | data[].content | 내용 | String | Y | 조치 내용 |
| 5 | data[].createdAt | 생성일시 | LocalDateTime | Y | - |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 알람 ID로 조치사항 조회 | getActionsByAlarmId() |
| 2 | 결과 반환 | JSON 응답 |

---

▣ EVENT 타입 제약 조건

| 작업 | 허용 여부 | 사유 |
|------|----------|------|
| 수정 | X | 자동 생성 알람 |
| 삭제 | X | 시스템 필수 알람 |
| 활성화 토글 | X | 항상 활성 상태 유지 |
| 담당자 관리 | X | 전체 사용자 발송 |

