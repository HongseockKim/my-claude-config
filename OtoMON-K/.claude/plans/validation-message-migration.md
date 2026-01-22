# 하드코딩 한글 메시지 → ValidationMessage 마이그레이션 플랜

## 목표
- 약 200개의 하드코딩된 한글 메시지를 ValidationMessage 상수로 중앙 집중화
- 향후 DB 기반 메시지 관리로 마이그레이션 가능하도록 구조화

---

## 진행 현황 (2026-01-16 기준)

### ✅ 완료됨

| Phase | 파일 | 건수 | 상태 |
|-------|------|------|------|
| Phase 1 | common.properties (메시지 키 추가) | 90건 | ✅ 완료 |
| Phase 1 | ValidationMessage.java (카테고리 추가) | 10개 | ✅ 완료 |
| Phase 1 | ValidationMessageHolder.java (신규 생성) | - | ✅ 완료 |
| Phase 2 | ValidationUtils.java | 9건 | ✅ 완료 |
| Phase 2 | UserService.java | 6건 | ✅ 완료 |
| Phase 3 | ClickHouseService.java | 9건 | ✅ 완료 |
| Phase 3 | DetectionService.java | 12건 | ✅ 완료 |
| Phase 3 | AlarmService.java | 3건 | ✅ 완료 |
| Phase 4-1 | WidgetService.java | ~20건 | ✅ 완료 |

### ⏳ 남은 작업

| Phase | 파일 | 건수 | 우선순위 |
|-------|------|------|----------|
| Phase 4-2 | DashboardController.java | 8건 | LOW |
| Phase 4-3 | SettingController.java | 7건 | LOW |
| Phase 4-4 | OperationInfoService.java | 10건 | LOW |
| Phase 5 | AssetService.java (엑셀 헤더) | 80건+ | SPECIAL |
| Final | 빌드 및 검증 | - | - |

### 작업 재개 명령
```
다음 작업 이어서 진행해줘 - Phase 4-2 DashboardController부터
```

---

## 마이그레이션 대상 요약

| 파일 | 건수 | 우선순위 | 카테고리 |
|------|------|----------|----------|
| ValidationUtils.java | 8 | HIGH | Validation |
| UserService.java | 6 | HIGH | Auth (신규) |
| ClickHouseService.java | 10 | MEDIUM | Session (신규) |
| DetectionService.java | 12 | MEDIUM | Detection |
| AlarmService.java | 3 | MEDIUM | Alarm |
| WidgetService.java | 15+ | LOW | Widget |
| DashboardController.java | 8 | LOW | Dashboard |
| SettingController.java | 7 | LOW | Setting (신규) |
| OperationInfoService.java | 10 | LOW | Operation |
| AssetService.java (엑셀헤더) | 80+ | SPECIAL | ExcelHeader (신규) |

---

## Phase 1: 사전 준비

### 1-1. ValidationMessageHolder 생성 (static 메서드용)
```
파일: src/main/java/com/otoones/otomon/util/ValidationMessageHolder.java
```
- Spring ApplicationContext에서 MessageService 접근 가능하게 하는 Holder 패턴
- ValidationUtils 같은 static 유틸리티 클래스에서 사용

### 1-2. ValidationMessage.java 카테고리 확장
```
파일: src/main/java/com/otoones/otomon/constant/ValidationMessage.java
```
추가할 Inner Class:
- `Auth` - 인증 관련
- `Session` - 세션/ClickHouse 관련
- `Setting` - 설정 관련
- `ExcelHeader` - 엑셀 헤더 맵핑

---

## Phase 2: HIGH 우선순위 (보안 관련)

### 2-1. ValidationUtils.java (8건)
| Line | Before | After (key) |
|------|--------|-------------|
| 48 | `"입력값에 허용되지 않는 문자가 포함되어 있습니다."` | `validation.util.invalid.input.characters` |
| 56 | `"디코딩된 값에 허용되지 않는 문자가 포함되어 있습니다."` | `validation.util.invalid.decoded.characters` |
| 63 | `"유효하지 않은 Base64 형식입니다."` | `validation.util.invalid.base64` |
| 105 | `"값이 비어있습니다."` | `validation.util.empty.value` |
| 109 | `"값에 허용되지 않는 문자가 포함되어 있습니다."` | `validation.util.invalid.value.characters` |
| 115 | `"유효하지 않은 값입니다."` | `validation.util.invalid.value` |
| 121 | `"값이 비어있습니다."` | `validation.util.empty.value` (재사용) |
| 125 | `"허용 되지 않는 문자가 포함되어 있습니다."` | `validation.util.forbidden.characters` |

### 2-2. UserService.java (6건)
| Line | Before | After (key) |
|------|--------|-------------|
| 38 | `"사용자를 찾을 수 없습니다: "` | `auth.user.not.found` |
| 41 | `"비활성화된 계정입니다."` | `auth.account.disabled` |
| 44 | `"계정이 잠겼습니다. 30분 후에 다시 시도하세요."` | `auth.account.locked` |
| 108 | `"해당 사용자가 없습니다."` | `auth.user.not.exists` |
| 111 | `"현재 비밀번호가 일치하지 않습니다."` | `auth.password.mismatch` |
| 122 | `"해당 사용자가 없습니다."` | `auth.user.not.exists` (재사용) |

---

## Phase 3: MEDIUM 우선순위 (비즈니스 로직)

### 3-1. ClickHouseService.java (10건)
| Line | Before | After (key) |
|------|--------|-------------|
| 106 | `"세션 통계 조회 중 오류가 발생했습니다."` | `session.stat.query.error` |
| 189 | `"세션 조회 중 오류가 발생했습니다."` | `session.query.error` |
| 215 | `"세션 목록 조회 중 오류가 발생했습니다."` | `session.list.query.error` |
| 233 | `"기준 세션 조회 중 오류가 발생했습니다."` | `session.base.query.error` |
| 255 | `"관련 세션 조회 중 오류가 발생했습니다."` | `session.related.query.error` |
| 277 | `"최근 세션 조회 중 오류가 발생했습니다."` | `session.recent.query.error` |
| 297 | `"IP 통계 조회 중 오류가 발생했습니다."` | `session.ip.stat.error` |
| 321 | `"세션 그룹 조회 중 오류가 발생했습니다."` | `session.group.query.error` |
| 338 | `"이상 세션 조회 중 오류가 발생했습니다."` | `session.abnormal.query.error` |

### 3-2. DetectionService.java (12건)
| Line | Before | After (key) |
|------|--------|-------------|
| 99 | `"해당 구역과 포트에 대한 정책이 이미 존재합니다."` | `detection.policy.duplicate` |
| 111 | `"수정할 정책을 찾을 수 없습니다."` | `detection.policy.not.found.update` |
| 118 | `"해당 구역과 포트에 대한 정책이 이미 존재합니다."` | `detection.policy.duplicate` (재사용) |
| 136 | `"삭제할 정책을 찾을 수 없습니다."` | `detection.policy.not.found.delete` |
| 290 | `"엑셀 생성 실패"` | `detection.excel.create.fail` |
| 483 | `"관련 이벤트를 찾을 수 없습니다."` | `detection.event.not.found` |
| 578 | `"모든 항목이 이미 화이트리스트에..."` | `detection.whitelist.already.registered` |
| 586 | `"화이트리스트 추가 실패: "` | `detection.whitelist.add.fail` |
| 2207 | `"설정을 찾을 수 없습니다"` | `detection.config.not.found` |
| 2252 | `"새 설정 생성 실패: "` | `detection.config.create.fail` |
| 2861 | `"조치"` | `detection.action.type.action` |
| 2862 | `"무시"` | `detection.action.type.ignore` |

### 3-3. AlarmService.java (3건)
| Line | Before | After (key) |
|------|--------|-------------|
| 82 | `"생성"` | `alarm.notify.action.create` |
| 113 | `"수정"` | `alarm.notify.action.update` |
| 164 | `"이미 등록된 담당자입니다"` | `alarm.manager.duplicate` |

---

## Phase 4: LOW 우선순위 (UI/프레젠테이션)

### 4-1. WidgetService.java (15건+)
| Line | Before | After (key) |
|------|--------|-------------|
| 131 | `"데이터 없음"` | `widget.status.no.data` |
| 612 | `"운전이상"` | `widget.operation.status.abnormal` |
| 616 | `"운전정지"` | `widget.operation.status.stop` |
| 618 | `"정상운전"` | `widget.operation.status.normal` |
| 1325-1331 | 이벤트 타입명 | `widget.event.type.*` |
| 1974-1977 | 위협점수 상태 | `widget.threat.level.*` |

### 4-2. DashboardController.java (8건)
| Line | Before | After (key) |
|------|--------|-------------|
| 65 | `"위젯"` | `dashboard.widget.label` |
| 272 | `"호기"` | `dashboard.zone.suffix` |
| 344 | `"호기 데이터 조회 실패"` | `dashboard.zone.data.error` |
| 431-434 | 부하 상태 | `dashboard.load.status.*` |

### 4-3. SettingController.java (7건)
| Line | Before | After (key) |
|------|--------|-------------|
| 148-151 | 알람 타입 | `setting.alarm.type.*` |
| 155-157 | 알람 레벨 | `setting.alarm.level.*` |

### 4-4. OperationInfoService.java (10건)
| Line | Before | After (key) |
|------|--------|-------------|
| 264 | `"성공: %d개, 실패: %d개"` | `operation.save.result` |
| 674 | `"발전소 코드가 필요합니다."` | `operation.plant.code.required` |
| 716 | `"OPC UA 서버 설정이 저장되었습니다."` | `operation.opcua.save.success` |
| 기타 | ... | `operation.*` |

---

## Phase 5: 엑셀 헤더 (80건+)

### 5-1. AssetService.java HEADER_TO_FIELD_MAP

ValidationMessage.ExcelHeader 카테고리에 추가:
```properties
# common.properties
excel.header.number=번호
excel.header.importance=중요도
excel.header.confidentiality=기밀성
excel.header.integrity=무결성
excel.header.availability=가용성
excel.header.equipment.type=설비구분
excel.header.system.name=시스템명
excel.header.processing.task=처리업무
excel.header.management.number=관리번호
# ... 80개+ 항목
```

---

## 수정 대상 파일 목록

### 신규 생성
1. `src/main/java/com/otoones/otomon/util/ValidationMessageHolder.java`

### 수정
1. `src/main/java/com/otoones/otomon/constant/ValidationMessage.java` - 카테고리 추가
2. `src/main/resources/messages/common.properties` - 메시지 키 추가
3. `src/main/resources/messages/common_ko.properties` - 한글 메시지
4. `src/main/java/com/otoones/otomon/util/ValidationUtils.java`
5. `src/main/java/com/otoones/otomon/service/UserService.java`
6. `src/main/java/com/otoones/otomon/service/ClickHouseService.java`
7. `src/main/java/com/otoones/otomon/service/DetectionService.java`
8. `src/main/java/com/otoones/otomon/service/AlarmService.java`
9. `src/main/java/com/otoones/otomon/service/WidgetService.java`
10. `src/main/java/com/otoones/otomon/controller/DashboardController.java`
11. `src/main/java/com/otoones/otomon/controller/SettingController.java`
12. `src/main/java/com/otoones/otomon/service/OperationInfoService.java`
13. `src/main/java/com/otoones/otomon/service/AssetService.java`

---

## 검증 방법

1. **빌드 검증**: `mvnw.cmd clean package -DskipTests`
2. **런타임 검증**: `mvnw.cmd spring-boot:run -DskipTests`
3. **UI 검증**: 각 기능 화면에서 메시지 정상 출력 확인
   - 로그인 실패 메시지
   - 알람 생성/수정 메시지
   - 엑셀 다운로드/업로드

---

## 예상 작업량

| Phase | 파일 수 | 메시지 수 |
|-------|---------|----------|
| 1 (준비) | 2 | - |
| 2 (HIGH) | 2 | 14 |
| 3 (MEDIUM) | 3 | 25 |
| 4 (LOW) | 4 | 40+ |
| 5 (엑셀) | 1 | 80+ |
| **합계** | **12** | **~160** |