# e.getMessage() 정보 노출 취약점 수정 계획

## 개요

API 응답에 `e.getMessage()`가 직접 포함되어 내부 시스템 정보(파일 경로, DB 정보, 클래스명 등)가 노출되는 보안 취약점 수정

## 취약점 현황 (약 40개 위치)

| 컨트롤러 | 위치 수 | 우선순위 |
|----------|--------|---------|
| UserController.java | 12 | P1 |
| AlarmController.java | 7 | P1 |
| MenuController.java | 5 | P2 |
| AssetController.java | 4 | P2 |
| TopologyPhysicalController.java | 3 | P2 |
| DashboardTemplateController.java | 3 | P3 |
| SettingController.java | 2 | P3 |
| OperationApiController.java | 2 | P3 |
| DataController.java | 1 | P3 |
| AnalysisController.java | 1 | P3 |
| **GlobalExceptionHandler.java** | 2 | **P0** |

## 수정 전략

**원칙:**
- 서버 로그: 상세 에러 정보 기록 (`log.error("메시지", e)`)
- 클라이언트 응답: 일반화된 메시지만 반환 (`messageService.getMessage(...)`)

**패턴:**
```java
// Before (취약)
} catch (Exception e) {
    result.put("message", e.getMessage());
}

// After (안전)
} catch (Exception e) {
    log.error("작업 실패", e);  // 로그에만 상세 정보
    result.put("message", messageService.getMessage(ValidationMessage.XXX.XXX_FAIL));
}
```

---

## 수정 파일 목록

### Phase 0: GlobalExceptionHandler (최우선)

**파일:** `src/main/java/com/otoones/otomon/exception/GlobalExceptionHandler.java`

| 라인 | 현재 | 수정 |
|------|------|------|
| 60 | `"접근 권한이 없습니다: " + ex.getMessage()` | `"접근 권한이 없습니다."` |
| 90 | `ex.getMessage()` | `"요청하신 데이터를 찾을 수 없습니다."` |

### Phase 1: 고위험 컨트롤러

#### UserController.java
**파일:** `src/main/java/com/otoones/otomon/controller/UserController.java`

| 라인 | 메서드 | 수정 메시지 |
|------|--------|-----------|
| 160-161 | saveUser | `ValidationMessage.Common.ERROR_USER_FAILED` |
| 220-221 | saveNewUser | `ValidationMessage.Common.ERROR_USER_FAILED` |
| 276-278 | saveExistingUser | `ValidationMessage.Common.ERROR_USER_FAILED` |
| 391 | getGroupList | `ValidationMessage.UserGroup.GROUP_NOT_FOUND` |
| 422 | getUsersByGroup | `ValidationMessage.UserGroup.GROUP_NOT_FOUND` |
| 467 | updateUserGroups | `ValidationMessage.UserGroup.GROUP_UPDATE_SUCCESS` → 실패시 일반 메시지 |
| 497 | getGroupData | `ValidationMessage.UserGroup.GROUP_NOT_FOUND` |
| 555 | saveGroup | `ValidationMessage.UserGroup.GROUP_SAME_GROUP_NAME` |
| 613 | updateGroup | `ValidationMessage.UserGroup.GROUP_NOT_FOUND` |
| 655 | deleteGroup | `ValidationMessage.UserGroup.GROUP_DELETE_ROLE_REQUIRED` |
| 699-856 | 기타 메서드 | 각 기능에 맞는 ValidationMessage 사용 |

#### AlarmController.java
**파일:** `src/main/java/com/otoones/otomon/controller/AlarmController.java`

| 라인 | 메서드 | 수정 메시지 |
|------|--------|-----------|
| 108 | createAlarm | `ValidationMessage.Alarm.ALARM_SETTING_ADD_FAIL` |
| 146 | updateAlarm | `ValidationMessage.Alarm.ALARM_SETTING_EDIT_FAIL` |
| 173 | deleteAlarm | `ValidationMessage.Alarm.ALARM_SETTING_DELETE_FAIL` |
| 203 | toggleAlarm | `ValidationMessage.Alarm.ALARM_SETTING_STATUS_FAIL` |
| 273 | addManager | `ValidationMessage.Alarm.ALARM_SETTING_MANAGER_ADD_FAIL` |
| 303 | removeManager | `ValidationMessage.Alarm.ALARM_SETTING_MANAGER_DELETE_FAIL` |
| 396 | batchUpdateManagers | `ValidationMessage.Alarm.ALARM_SETTING_MANAGER_BATCH_FAIL` |

### Phase 2: 중위험 컨트롤러

#### MenuController.java
**파일:** `src/main/java/com/otoones/otomon/controller/MenuController.java`

| 라인 | 수정 메시지 |
|------|-----------|
| 145 | `ValidationMessage.Menu.MENU_UPDATE_FAILED` |
| 159 | `ValidationMessage.Menu.MENU_CREATE_FAILED` |
| 170 | `ValidationMessage.Menu.MENU_DELETE_FAILED` |
| 181 | `ValidationMessage.Menu.MENU_DISPLAY_ORDER_UPDATE_FAILED` |
| 215 | `ValidationMessage.Menu.MENU_EDIT_FAILED` |

#### AssetController.java
**파일:** `src/main/java/com/otoones/otomon/controller/AssetController.java`

| 라인 | 수정 메시지 |
|------|-----------|
| 319 | `ValidationMessage.Asset.ASSET_OPERATION_DETAIL_EDIT_FAIL` |
| 564 | `ValidationMessage.Asset.ASSET_DATA_LIST_ERROR` |
| 624 | `ValidationMessage.Topology.SETTING_TOPOLOGY_SWITCH_FIND_ERROR` |
| 643 | `ValidationMessage.Topology.SETTING_TOPOLOGY_SWITCH_FIND_ERROR` |

#### TopologyPhysicalController.java
**파일:** `src/main/java/com/otoones/otomon/controller/TopologyPhysicalController.java`

| 라인 | 수정 메시지 |
|------|-----------|
| 46, 65, 95 | `ValidationMessage.Topology.SETTING_TOPOLOGY_SWITCH_FIND_ERROR` |

### Phase 3: 저위험 컨트롤러

#### DashboardTemplateController.java
| 라인 | 수정 메시지 |
|------|-----------|
| 56, 139 | `ValidationMessage.Dashboard.TEMPLATE_NOT_FOUND` |
| 190 | `ValidationMessage.Dashboard.WIDGET_NOT_POSITION` |

#### SettingController.java
| 라인 | 수정 메시지 |
|------|-----------|
| 238 | `ValidationMessage.Topology.SETTING_TOPOLOGY_SWITCH_DELETED_FAIL` |
| 451 | `ValidationMessage.SystemConfig.SYSTEM_CONFIG_SAVE_FAIL` |

#### OperationApiController.java
| 라인 | 수정 메시지 |
|------|-----------|
| 120, 203 | `ValidationMessage.Operation.DATA_OPERATION_ERROR_TEXT` |

#### DataController.java
| 라인 | 수정 메시지 |
|------|-----------|
| 146 | `"시스템 리소스 조회 중 오류가 발생했습니다."` |

#### AnalysisController.java
| 라인 | 수정 메시지 |
|------|-----------|
| 326 | `"차트 데이터 조회 중 오류가 발생했습니다."` |

---

## 메시지 파일 추가 (선택)

**파일:** `src/main/resources/messages/common_ko.properties`

필요시 추가할 메시지:
```properties
common.processing.error=처리 중 오류가 발생했습니다.
common.access.denied=접근 권한이 없습니다.
common.data.not.found=요청하신 데이터를 찾을 수 없습니다.
common.query.error=조회 중 오류가 발생했습니다.
```

---

## 검증 방법

1. **빌드 테스트**: `mvnw.cmd clean package -DskipTests`
2. **수동 테스트**: 각 API에 잘못된 요청 전송 후 응답 확인
   - 응답에 파일 경로, DB 정보, 클래스명 등 노출 여부 확인
   - 서버 로그에 상세 에러 기록 확인
3. **AppScan 재스캔**: 취약점 해결 확인

---

## 주요 파일 경로

```
src/main/java/com/otoones/otomon/
├── exception/GlobalExceptionHandler.java      # Phase 0
├── controller/
│   ├── UserController.java                    # Phase 1
│   ├── AlarmController.java                   # Phase 1
│   ├── MenuController.java                    # Phase 2
│   ├── AssetController.java                   # Phase 2
│   ├── TopologyPhysicalController.java        # Phase 2
│   ├── DashboardTemplateController.java       # Phase 3
│   ├── SettingController.java                 # Phase 3
│   ├── OperationApiController.java            # Phase 3
│   ├── DataController.java                    # Phase 3
│   └── AnalysisController.java                # Phase 3
├── constant/ValidationMessage.java            # 메시지 상수 (이미 대부분 존재)
└── service/MessageService.java                # 메시지 서비스
```
