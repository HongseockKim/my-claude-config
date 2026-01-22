# OtoMON-K 멀티사이트 솔루션화 프로젝트 플랜

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **목표** | 삼천포발전소 전용 → 어떤 발전소든 적용 가능한 범용 솔루션화 |
| **핵심 원칙** | 코드 수정 없이 DB 설정(Code + SystemConfig)만으로 사이트 전환 |
| **예상 범위** | Backend 15개, Frontend 25개, HTML 10개 파일 수정 |

---

## 전체 페이지 하드코딩 분석 결과

### 하드코딩 유형별 분류

| 유형 | 건수 | 심각도 |
|------|------|--------|
| **호기명 하드코딩** ("3호기", "4호기") | 80+ | 🔴 HIGH |
| **호기코드 하드코딩** ("sp_03", "sp_04") | 60+ | 🔴 HIGH |
| **발전소명 하드코딩** ("삼천포", "samcheonpo") | 15+ | 🔴 HIGH |
| **사업소명 하드코딩** ("남동발전", "koen") | 10+ | 🟡 MEDIUM |
| **Fallback 하드코딩** (`|| '남동발전'`) | 5+ | 🟡 MEDIUM |
| **위젯/템플릿 하드코딩** | 20+ | 🟡 MEDIUM |

### 페이지별 하드코딩 현황

| 페이지 영역 | 하드코딩 건수 | 주요 파일 |
|------------|-------------|----------|
| **Dashboard** | 35+ | dashbord.js, DashboardTemplateService.java |
| **Detection** | 50+ | timesSereiseData.js, DetectionService.java |
| **Asset** | 15+ | operation.js, topology-physical-detail.html |
| **Data** | 20+ | DataService.java, operation.js (data) |
| **Policy** | 35+ | timeSeries.js, servicePortPolicy.js |
| **Report** | 20+ | reportList.js, reportAdd.js |
| **Setting** | 15+ | collectionOpTag.js, topologySwitch.js |
| **Common** | 5+ | navbar.html |

---

## Phase 1: 계층 연동 완성 (핵심 - 우선순위 최상)

### 1.1 Zone1 → Zone2 연동 구현

**현재 문제:**
- Zone1(사업소) 변경 시 Zone2(발전소) 목록이 연동되지 않음
- Zone2 드롭다운이 전체 발전소를 표시

**수정 대상:**

| 파일 | 위치 | 수정 내용 |
|------|------|----------|
| `SystemConfigService.java` | :92-114 | zone2 조회 시 zone1 parent_code 필터링 추가 |
| `systemConfig.js` | 신규 | zone1 change 이벤트 핸들러 추가 |
| `CodeController.java` | 신규 API | `/api/code/zone2/{zone1Code}` 엔드포인트 |

**구현 로직:**
```
Zone1 select 변경
  → AJAX: GET /api/code/zone2/{zone1Code}
  → Zone2 드롭다운 옵션 갱신
  → Zone3 체크박스 초기화 (또는 첫번째 Zone2 기준 로드)
```

### 1.2 Zone2 → Zone3 연동 개선

**현재 문제:**
- Zone2 변경 시 `location.reload()` 호출 (UX 불편)

**수정 대상:**

| 파일 | 위치 | 수정 내용 |
|------|------|----------|
| `systemConfig.js` | :164-170 | reload → AJAX 비동기 방식으로 변경 |
| `CodeController.java` | 신규 API | `/api/code/zone3/{zone2Code}` 엔드포인트 |

**구현 로직:**
```
Zone2 select 변경
  → AJAX: GET /api/code/zone3/{zone2Code}
  → Zone3 체크박스 동적 재생성
  → 저장된 값과 비교하여 체크 상태 유지
```

### 1.3 신규 API 엔드포인트

```java
// CodeController.java 추가

@GetMapping("/api/code/zone2/{zone1Code}")
public ResponseEntity<List<Code>> getZone2ByZone1(@PathVariable String zone1Code) {
    return ResponseEntity.ok(codeRepository.findByTypeCodeAndParentCode("zone2", zone1Code));
}

@GetMapping("/api/code/zone3/{zone2Code}")
public ResponseEntity<List<Code>> getZone3ByZone2(@PathVariable String zone2Code) {
    return ResponseEntity.ok(codeRepository.findByTypeCodeAndParentCode("zone3", zone2Code));
}
```

---

## Phase 2: 시스템 타이틀/발전소명 동적화

### 2.1 SystemConfig 키 추가

| config_key | config_value 예시 | 용도 |
|------------|------------------|------|
| `system.name` | `"발전제어망 보안관제시스템"` | navbar 메인 타이틀 |
| `system.subtitle` | (zone2의 value 연동) | navbar 서브타이틀 |

**수정 대상:**

| 파일 | 위치 | 수정 내용 |
|------|------|----------|
| `navbar.html` | :20-21 | 하드코딩 → Thymeleaf 변수 |
| `LayoutInterceptor.java` | 신규 | 모든 페이지에 system.name 전달 |

**Before:**
```html
<b class="system-title">발전제어망 보안관제시스템</b>
<small class="system-subtitle">삼천포</small>
```

**After:**
```html
<b class="system-title" th:text="${systemName}">시스템명</b>
<small class="system-subtitle" th:text="${plantName}">발전소명</small>
```

---

## Phase 3: 호기명 하드코딩 제거 (Backend)

### 3.1 Zone3Util.java 확장

**현재:**
- switch 문으로 `"sp_03" → "3호기"` 변환

**개선:**
- Code 테이블 조회 (캐싱 적용)

```java
// Zone3Util.java 확장
@Cacheable("zone3DisplayNames")
public String toDisplayText(String zone3Code) {
    Code code = codeRepository.findByTypeCodeAndCode("zone3", zone3Code).orElse(null);
    return code != null ? code.getValue() : zone3Code;
}
```

**수정 대상:**

| 파일 | 위치 | 현재 코드 | 수정 방향 |
|------|------|----------|----------|
| `DetectionService.java` | :2811-2812, 2931-2932 | switch 문 | Zone3Util.toDisplayText() 호출 |
| `TimeSeriesExcelDto.java` | :305-306 | switch 문 | Zone3Util.toDisplayText() 호출 |
| `DashboardTemplateService.java` | :220-232 | 하드코딩 문자열 | 템플릿 변수화 |

### 3.2 DataService.java 동적 호기 조회

**현재 문제:**
```java
// 하드코딩된 호기만 조회
List<OpTag> sp03List = ...("sp_03", ...);
List<OpTag> sp04List = ...("sp_04", ...);
```

**개선:**
```java
// 활성 호기 동적 조회
List<String> activeZones = systemConfigService.getActiveZone3List();
for (String zone : activeZones) {
    opList.addAll(opTagRepository.findBy...(..., zone, ...));
}
```

---

## Phase 4: 호기명 하드코딩 제거 (Frontend)

### 4.1 Zone3Util.js 확장

**현재:**
- 클라이언트 사이드에서 `"sp_03" → "3호기"` 변환

**개선:**
- 페이지 로드 시 Code API에서 zone3 목록 프리페칭
- 또는 __PAGE_DATA__에 zone3 매핑 포함

**수정 대상:**

| 파일 | 위치 | 현재 코드 | 수정 방향 |
|------|------|----------|----------|
| `operation.js` | :86 | `zone === 'sp_03' ? '3호기' : '4호기'` | Zone3Util.toDisplayText() |
| `dashbord.js` | :1802-1830 | 호기별 색상 하드코딩 | SystemConfig zone.colors 연동 |
| `reportList.js` | :389-390 | `'sp_03': '3호기'` 맵 | API 조회 또는 PAGE_DATA |
| `timesSereiseData.js` | 25개소 | 3호기/4호기 변수명 | 동적 생성 |
| `collectionOpTag.js` | :349, 384 | fallback 하드코딩 | SystemConfig 연동 |

### 4.2 Dashboard 위젯 동적화

**현재 문제:**
```html
<!-- 하드코딩된 호기 위젯 -->
<div th:case="'dashboard/sp_03/zone-status'">
    th:insert="~{fragments/dashboard/zone-status :: widgetContent('sp_03', '3호기')}"
</div>
```

**개선:**
```html
<!-- 동적 호기 위젯 -->
<th:block th:each="zone : ${activeZones}">
    <div th:case="'dashboard/' + ${zone.code} + '/zone-status'">
        th:insert="~{fragments/dashboard/zone-status :: widgetContent(${zone.code}, ${zone.value})}"
    </div>
</th:block>
```

---

## Phase 5: ClickHouse 기본값 제거

### 5.1 테이블 DDL 수정

**현재:**
```sql
zone1 varchar(20) default 'koen',
zone2 varchar(20) default 'samcheonpo',
```

**개선:**
```sql
zone1 varchar(20) default '',
zone2 varchar(20) default '',
```

**대상 테이블:**
- `stats_1min`
- `stats_10min`
- `TimeSeriesRawAsset`
- `TimeSeriesRawConnection`
- `TimeSeriesRawOis`

### 5.2 데이터 마이그레이션

- 기존 데이터의 zone 값 유지
- 신규 데이터는 삽입 시 명시적 zone 지정

---

## Phase 6: 호기별 색상/아이콘 설정

### 6.1 SystemConfig 확장

| config_key | config_value 예시 |
|------------|------------------|
| `zone.colors` | `{"sp_03":"#FFD700","sp_04":"#00CED1","sp_05":"#FF6B6B"}` |
| `zone.icons` | `{"sp_03":"fa-industry","sp_04":"fa-industry"}` |

### 6.2 ZoneConfigService 신규 생성

```java
@Service
@RequiredArgsConstructor
public class ZoneConfigService {

    @Cacheable("zoneColors")
    public Map<String, String> getZoneColors() {
        SystemConfig config = systemConfigRepository.findByConfigKey("zone.colors");
        return parseJsonMap(config.getConfigValue());
    }

    public String getZoneColor(String zoneCode) {
        return getZoneColors().getOrDefault(zoneCode, "#6c757d");
    }
}
```

---

## 파일별 수정 체크리스트

### Backend (Java)

| 파일 | Phase | 수정 내용 |
|------|-------|----------|
| `SystemConfigService.java` | 1.1 | zone2 필터링, zone1 연동 |
| `CodeController.java` | 1.1, 1.2 | zone2/zone3 조회 API 추가 |
| `Zone3Util.java` | 3.1 | DB 조회 방식으로 변경 |
| `DetectionService.java` | 3.1 | switch 문 → Zone3Util |
| `DataService.java` | 3.2 | 동적 호기 조회 |
| `TimeSeriesExcelDto.java` | 3.1 | switch 문 → Zone3Util |
| `DashboardTemplateService.java` | 3.1 | 템플릿 변수화 |
| `WidgetService.java` | 3.2 | getActiveZone3List() 동적화 |
| `LayoutInterceptor.java` | 2.1 | 신규 - systemName 전달 |
| `ZoneConfigService.java` | 6.2 | 신규 - 호기 색상/아이콘 |

### Frontend (JavaScript)

| 파일 | Phase | 수정 내용 |
|------|-------|----------|
| `systemConfig.js` | 1.1, 1.2 | zone1/zone2 change 이벤트 AJAX |
| `operation.js` | 4.1 | Zone3Util.toDisplayText() |
| `dashbord.js` | 4.1, 6.1 | 동적 색상 매핑 |
| `reportList.js` | 4.1 | 동적 호기명 |
| `reportAdd.js` | 4.1 | 동적 호기명 |
| `timesSereiseData.js` | 4.1 | 동적 그리드 생성 |
| `timesData.js` | 4.1 | Zone3Util 사용 |
| `timeSeries.js` | 4.1 | 정책 설명 템플릿화 |
| `collectionOpTag.js` | 4.1 | fallback 제거 |
| `common.js` | 4.1 | Zone3Util 확장 |

### HTML (Thymeleaf)

| 파일 | Phase | 수정 내용 |
|------|-------|----------|
| `navbar.html` | 2.1 | 시스템명/발전소명 동적화 |
| `dashboard.html` | 4.2 | 호기 위젯 동적 생성 |
| `timeSereiseData.html` | 4.2 | 호기 탭 동적 생성 |
| `collectionOpTag.html` | 4.1 | 호기명 동적화 |
| `topology-physical-detail.html` | 4.1 | 드롭다운 동적 생성 |

---

## 우선순위 및 의존성

```
Phase 1 (계층 연동) ─────────────────────────────────────┐
  ├─ 1.1 Zone1→Zone2 연동 ◀── 핵심                      │
  ├─ 1.2 Zone2→Zone3 AJAX 개선                          │
  └─ 1.3 API 엔드포인트                                 │
                                                        ▼
Phase 2 (시스템 타이틀) ◀── Phase 1 완료 후
  └─ navbar 동적화
                                                        ▼
Phase 3 (Backend 하드코딩) ◀── Phase 1, 2 완료 후
  ├─ Zone3Util 확장
  └─ Service 레이어 수정
                                                        ▼
Phase 4 (Frontend 하드코딩) ◀── Phase 3 완료 후
  ├─ JavaScript 수정
  └─ Dashboard 동적화
                                                        ▼
Phase 5 (ClickHouse) ◀── 별도 진행 가능
  └─ DDL 수정 + 마이그레이션
                                                        ▼
Phase 6 (색상/아이콘) ◀── Phase 4 완료 후
  └─ ZoneConfigService
```

---

## 예상 효과

| Before | After |
|--------|-------|
| 신규 사이트 적용 시 80+ 파일 수정 | Code + SystemConfig 설정만으로 적용 |
| 호기 추가 시 JS/Java 코드 수정 | DB에 Code 추가만으로 완료 |
| 발전회사별 커스터마이징 불가 | 동일 코드베이스로 다중 사이트 운영 |
| Zone1 변경 시 수동 Zone2 선택 | 자동 연동 (하위 계층 자동 갱신) |

---

## 테스트 시나리오

### Phase 1 완료 후 테스트

1. **Zone1 변경 테스트**
   - Zone1 드롭다운에서 다른 사업소 선택
   - Zone2 드롭다운이 해당 사업소의 발전소만 표시되는지 확인
   - Zone3 체크박스가 초기화되는지 확인

2. **Zone2 변경 테스트**
   - Zone2 드롭다운에서 다른 발전소 선택
   - 페이지 reload 없이 Zone3 체크박스가 갱신되는지 확인
   - 저장된 Zone3 값이 유지되는지 확인

3. **저장 테스트**
   - Zone1, Zone2, Zone3 모두 변경 후 저장
   - 페이지 새로고침 후 값이 유지되는지 확인
   - 다른 페이지(dashboard, detection 등)에서 연동되는지 확인

### 전체 완료 후 테스트

1. **신규 사이트 시뮬레이션**
   - Code 테이블에 새로운 zone1, zone2, zone3 추가
   - SystemConfig에서 새 zone 선택
   - 모든 페이지에서 새 호기명이 정상 표시되는지 확인

2. **기존 데이터 호환성**
   - 기존 이벤트, 자산, 세션 데이터가 정상 조회되는지 확인
   - 리포트 생성, 엑셀 다운로드 정상 동작 확인

---

## 리스크 및 대응

| 리스크 | 영향 | 대응 방안 |
|--------|------|----------|
| Zone3Util 캐시 무효화 | 호기 추가 시 반영 지연 | @CacheEvict 적용, 설정 저장 시 캐시 클리어 |
| ClickHouse 기본값 제거 | 기존 데이터 영향 | 마이그레이션 스크립트로 기존 데이터 유지 |
| 프론트엔드 호환성 | 일부 JS 파일 누락 | 단계별 테스트로 검증 |
| 성능 저하 | DB 조회 증가 | 캐싱 전략 적용 |

---

## 작성일

- **작성일**: 2026-01-19
- **작성자**: Claude Code Assistant
- **버전**: 1.0