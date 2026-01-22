# 이상 이벤트 탐지 정책 (policy/timeSeries) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/policy/timeSeries` |
| **메뉴 ID** | 6050L |
| **권한** | READ/WRITE |
| **한글명** | 시계열 정책 |
| **목적** | 이벤트 정의(EventDefinition) 관리 - 활성화, 알람, 조치, 시계열 표시 여부 설정 |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/PolicyController.java
Service:    src/main/java/com/otoones/otomon/service/DetectionService.java (3,200+ lines)
Template:   src/main/resources/templates/pages/policy/timeSeries.html
JavaScript: src/main/resources/static/js/page.policy/timeSeries.js (665 lines)
Fragment:   src/main/resources/templates/fragments/policy/eventTableFragment.html
Model:      src/main/java/com/otoones/otomon/model/EventDefinition.java
            src/main/java/com/otoones/otomon/model/DetectionPolicy.java
Repository: src/main/java/com/otoones/otomon/repository/EventDefinitionRepository.java
```

---

## 컨트롤러 (PolicyController.java)

### 페이지 렌더링 (`GET /policy/timeSeries`)

**위치**: `PolicyController.java:206-212`

**권한**:
```java
@RequirePermission(menuId = 6050L, resourceType = ResourceType.MENU, permissionType = PermissionType.READ)
```

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| operation | 운전 이벤트 목록 (eventType="operation") |
| asset | 자산 이벤트 목록 (eventType="asset") |
| connection | 네트워크 이벤트 목록 (eventType="connection") |

### 이벤트 설정 API

| 메서드 | URL | 위치 | 권한 | @ActivityLog | 설명 |
|--------|-----|------|------|--------------|------|
| PUT | `/policy/event/{eventCode}/toggle` | :216-248 | 6050L WRITE | - | 이벤트 활성화 토글 |
| PUT | `/policy/event/{eventCode}/toggle/alarm` | :252-284 | 6050L WRITE | - | 알람 활성화 토글 + 레벨 설정 |
| PUT | `/policy/event/{eventCode}/level` | :288-321 | 6050L WRITE | - | 알람 레벨만 변경 |
| POST | `/policy/event/{eventCode}/action` | :325-357 | - ⚠️ | - | 조치 여부 설정 |
| POST | `/policy/event/{eventCode}/showtimesereies` | :359-391 | - ⚠️ | - | 시계열 표시 여부 |
| POST | `/policy/event/{eventCode}/isFavorit` | :393-425 | - ⚠️ | - | 즐겨찾기 토글 |

### 정책 CRUD API

| 메서드 | URL | 위치 | 권한 | 설명 |
|--------|-----|------|------|------|
| GET | `/policy/api/timeSeries` | :451-455 | 6050L READ | 정책 목록 조회 |
| PUT | `/policy/api/timeSeries` | :459-469 | 6050L WRITE | 정책 수정 |
| POST | `/policy/api/timeSeries` | :472-482 | 6050L WRITE | 정책 생성 |

### 권한 미적용 이슈 ⚠️

다음 메서드들에 `@RequirePermission` 누락:
- `eventAction()` (라인 325)
- `eventShowTimeSereies()` (라인 359)
- `eventIsFavorit()` (라인 393)

---

## 서비스 (DetectionService.java)

### EventDefinition 조회 메서드

| 메서드명 | 위치 | 기능 | 반환타입 |
|---------|------|------|---------|
| `getEventDefinitionsByEventType()` | :1753-1760 | 이벤트 타입별 활성 EventDefinition 조회 | `List<EventDefinition>` |
| `getCachedEventDefinitions()` | :3021-3030 | EventDefinition 캐시된 맵 반환 | `Map<String, EventDefinition>` |

### EventDefinition 업데이트 메서드

| 메서드명 | 위치 | 기능 | @ActivityLog |
|---------|------|------|-------------|
| `updateEventActive()` | :2049-2057 | 이벤트 활성화/비활성화 토글 | ✅ |
| `updateEventIsFavorit()` | :2059-2067 | 자주 사용하는 이벤트 토글 | ✅ |
| `updateEventAlarm()` | :2069-2088 | 알람 활성화/비활성화 + 레벨 설정 | ✅ |
| `updateEventAlarmLevel()` | :2090-2106 | 알람 레벨만 변경 | ✅ |
| `updateEventAction()` | :1763-1770 | 이벤트 조치 여부 설정 | ✅ |

### AlarmConfig 연동 메서드

| 메서드명 | 위치 | 기능 |
|---------|------|------|
| `createOrEnableAlarmConfig()` | :2108-2131 | 알람 설정 자동 생성 또는 활성화 |
| `disableAlarmConfig()` | :2133-2139 | 알람 설정 비활성화 |

### updateEventAlarm() 상세 로직

```java
@Transactional
@ActivityLog(category = "EVENT_DEFINITION", action = "UPDATE", resourceType = "EVENT_DEFINITION")
public void updateEventAlarm(String eventCode, Boolean isActive, String alarmLevel)
```

1. **EventDefinition 조회** - `findById(eventCode)`
2. **isAlarm, alarmLevel 설정**
3. **DB 저장**
4. **AlarmConfig 연동**:
   - `isActive = true` → `createOrEnableAlarmConfig()`
   - `isActive = false` → `disableAlarmConfig()`

---

## Repository 호출 패턴

### EventDefinitionRepository

| 메서드 | 호출 위치 | 용도 |
|--------|---------|------|
| `findById(eventCode)` | :1766, 2053, 2063, 2072, 2094 | 특정 이벤트 조회 |
| `findByEventTypeAndIsShowTrue(eventType)` | :1755 | 타입별 활성 이벤트 조회 |
| `findByEventActiveTrueAndIsShowTrue()` | :2400, 3023 | 활성+표시 이벤트 조회 |
| `findByIsShowTimeSeriesTrue()` | :2679 | 시계열 표시 이벤트 조회 |
| `save(event)` | :1769, 2056, 2066, 2080, 2098 | 이벤트 저장/업데이트 |

### AlarmConfigRepository

| 메서드 | 호출 위치 | 용도 |
|--------|---------|------|
| `findByAlarmCode(eventCode)` | :2101, 2110, 2135 | 알람 설정 조회 |
| `save(config)` | :2104, 2119, 2129, 2137 | 알람 설정 저장 |

---

## 프론트엔드 (timeSeries.js - 665줄)

### 주요 함수

| 함수명 | 위치 | 역할 |
|--------|------|------|
| `PageConfig.init()` | :13 | 페이지 데이터 및 메시지 초기화 |
| `checkSaveCompletion()` | :196 | 저장 완료 여부 확인 |
| `collectUpdatedPolicies()` | :214 | 변경된 정책들 수집 |
| `createNewConfigFromField()` | :253 | 새 설정 데이터 생성 |
| `saveAllPolicies()` | :342 | 모든 정책 저장 실행 |
| `savePoliciesAsync()` | :354 | 정책 비동기 저장 처리 |
| `showMessage()` | :384 | 알림 메시지 표시 |
| `bindConfigToInput()` | :427 | 설정 데이터를 입력 필드에 바인딩 |
| `initializeConfigData()` | :445 | 설정 데이터 초기화 |

### 토글 스위치 이벤트 핸들링 (이벤트 위임 패턴)

| 클래스명 | 위치 | 기능 | API 엔드포인트 |
|---------|------|------|---------------|
| `.event-toggle` | :467 | 이벤트 활성화/비활성화 | `/policy/event/{eventCode}/toggle` |
| `.alarm-toggle` | :513 | 알람 활성화/비활성화 | `/policy/event/{eventCode}/toggle/alarm` |
| `.alarm-level-select` | :565 | 알람 레벨 변경 | `/policy/event/{eventCode}/level` |
| `.action-toggle` | :591 | 조치 여부 토글 | `/policy/event/{eventCode}/action` |
| `.time-series-toggle` | :617 | 시계열 데이터 표시여부 | `/policy/event/{eventCode}/showtimesereies` |
| `.favorit-toggle` | :642 | 자주사용표시 토글 | `/policy/event/{eventCode}/isFavorit` |

### 공통 패턴

```javascript
$(document).on('change', '.event-toggle', function() {
    const eventCode = $(this).data('event-code');
    const isActive = $(this).prop('checked');

    if (!confirm('이벤트 상태를 변경하시겠습니까?')) {
        checkbox.prop('checked', !isActive);  // 상태 복원
        return;
    }

    $.ajax({
        url: `/policy/event/${eventCode}/toggle`,
        type: 'PUT',
        data: JSON.stringify({ isActive: isActive }),
        ...
    });
});
```

### API 호출 패턴

| 엔드포인트 | 메서드 | 용도 |
|-----------|--------|------|
| `/policy/api/timeSeries` | PUT/POST | 정책 저장 |
| `/policy/event/{eventCode}/toggle` | PUT | 이벤트 활성화 |
| `/policy/event/{eventCode}/toggle/alarm` | PUT | 알람 토글 |
| `/policy/event/{eventCode}/level` | PUT | 알람 레벨 |
| `/policy/event/{eventCode}/action` | POST | 조치 여부 |
| `/policy/event/{eventCode}/showtimesereies` | POST | 시계열 표시 |
| `/policy/event/{eventCode}/isFavorit` | POST | 즐겨찾기 |

---

## 권한 및 보안

### 권한 검사

| 기능 | Controller @RequirePermission | Service @ActivityLog |
|------|------------------|---------------------|
| 페이지 접근 | 6050L READ | - |
| 이벤트 토글 | 6050L WRITE | ✅ EVENT_DEFINITION/UPDATE |
| 알람 토글 | 6050L WRITE | ✅ EVENT_DEFINITION/UPDATE |
| 알람 레벨 변경 | 6050L WRITE | ✅ EVENT_DEFINITION/UPDATE |
| 조치 토글 | 6050L WRITE | ✅ EVENT_DEFINITION/UPDATE |
| 시계열 토글 | 6050L WRITE | ✅ EVENT_DEFINITION/UPDATE |
| 즐겨찾기 토글 | 6050L WRITE | ✅ EVENT_DEFINITION/UPDATE |
| 정책 조회 | 6050L READ | - |
| 정책 수정 | 6050L WRITE | - |
| 정책 생성 | 6050L WRITE | - |

### 보안 처리

1. **CSRF 토큰**: 모든 AJAX 요청에 헤더 포함
2. **사용자 확인**: 상태 변경 전 confirm 대화상자 표시
3. **상태 복원**: 실패 시 원래 상태로 복원

---

## API 엔드포인트 요약

| 메서드 | URL | 권한 | 위치 | 설명 |
|--------|-----|---|------|------|
| GET | `/policy/timeSeries` | 6050L READ | :206 | 페이지 렌더링 |
| PUT | `/policy/event/{eventCode}/toggle` | 6050L WRITE | :216 | 이벤트 토글 |
| PUT | `/policy/event/{eventCode}/toggle/alarm` | 6050L WRITE | :252 | 알람 토글 |
| PUT | `/policy/event/{eventCode}/level` | 6050L WRITE | :288 | 알람 레벨 |
| POST | `/policy/event/{eventCode}/action` | 6050L WRITE | :325 | 조치 토글 |
| POST | `/policy/event/{eventCode}/showtimesereies` | 6050L WRITE | :359 | 시계열 토글 |
| POST | `/policy/event/{eventCode}/isFavorit` | 6050L WRITE | :393 | 즐겨찾기 토글 |
| GET | `/policy/api/timeSeries` | 6050L READ | :451 | 정책 조회 |
| PUT | `/policy/api/timeSeries` | 6050L WRITE | :459 | 정책 수정 |
| POST | `/policy/api/timeSeries` | 6050L WRITE | :472 | 정책 생성 |

---

## 데이터 흐름

```
[Controller] getEventDefinitionsByEventType() 호출 (:206-212)
         ↓
[Service] findByEventTypeAndIsShowTrue() (:1753-1760)
         ↓
[Repository] EventDefinitionRepository
         ↓
[Model] List<EventDefinition>
         ↓
[Frontend] 이벤트별 테이블 렌더링 (operation, asset, connection)
         ↓
[토글 변경] AJAX → updateEventActive/Alarm/Level() → @ActivityLog
```

---

## EventDefinition 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| eventCode | String (PK) | 이벤트 코드 |
| eventName | String | 이벤트명 |
| eventType | String | 타입 (operation/asset/connection) |
| eventActive | Boolean | 활성화 여부 |
| isAlarm | Boolean | 알람 활성화 여부 |
| alarmLevel | String | 알람 레벨 (INFO/WARNING/ERROR) |
| isAction | Boolean | 조치 필요 여부 |
| isShowTimeSeries | Boolean | 시계열 표시 여부 |
| isFavorit | Boolean | 자주 사용 표시 |
| isShow | Boolean | 표시 여부 |
| description | String | 설명 |

---

## 핵심 특징

| 항목 | 내용 |
|------|------|
| **이벤트 타입** | operation(운전), asset(자산), connection(네트워크) |
| **AlarmConfig 연동** | 알람 활성화 시 자동 생성/활성화 |
| **캐시 사용** | `getCachedEventDefinitions()` 성능 최적화 |
| **감사 추적** | Service 레벨 @ActivityLog 적용 |
| **이벤트 위임** | `$(document).on('change', ...)` 패턴 |

---

## 관련 문서

- [시계열 이종 데이터 분석](detection-timesereise-system.md) - 시계열 히트맵 표시
- [이상 이벤트 탐지 현황](detection-timesdata-system.md) - 이벤트 목록 조회
- [알람 설정](setting-alarm-system.md) - AlarmConfig 관리