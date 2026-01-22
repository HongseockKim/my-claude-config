# 시계열 이종 데이터 분석 (timeSereiseData) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/detection/timeSereiseData` |
| **메뉴 ID** | 4070L |
| **권한** | READ 권한 필요 |
| **한글명** | 시계열 이종 데이터 분석 |
| **목적** | 10분 단위 집계된 시계열 데이터를 히트맵 형태로 시각화하여 이상 탐지 패턴 분석 |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/DetectionController.java (1,400+ lines)
Service:    src/main/java/com/otoones/otomon/service/DetectionService.java (3,200+ lines)
Template:   src/main/resources/templates/pages/detection/timeSereiseData.html
JavaScript: src/main/resources/static/js/page.detection/timesSereiseData.js (1,890 lines)
DTO:        src/main/java/com/otoones/otomon/dto/TimeSeriesAggregatedDto.java
Repository: src/main/java/com/otoones/otomon/repository/Stats1MinRepository.java
Fragment:   src/main/resources/templates/fragments/detection/eventDetailOffcanvas.html
```

---

## 컨트롤러 (DetectionController.java)

### 페이지 렌더링 (`GET /detection/timeSereiseData`)

**위치**: `DetectionController.java:864`

**권한**:
```java
@RequirePermission(menuId = 4070L, resourceType = ResourceType.MENU, permissionType = PermissionType.READ)
```

**주요 로직**:
1. 세션에서 날짜/호기 정보 가져오기
2. 날짜 변환 (기본값: 최근 7일)
3. 10분 집계 데이터 조회 (`getAggregated10MinDataFiltered`)
4. 최신 집계 데이터 조회 (`getLatestAggregated10MinDataFiltered`)
5. EventDefinition 조회 (시계열 표시용)
6. 전체 호기 선택 시 3호기/4호기 데이터 분리 제공

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| `initialData` | 10분 집계 데이터 리스트 |
| `latestData` | 최신 집계 데이터 |
| `dataSize` | 데이터 건수 |
| `eventDefinitions` | 이벤트 정의 (is_show_time_series=true) |
| `zone3Data` | 3호기 데이터 (전체 호기 선택 시) |
| `zone4Data` | 4호기 데이터 (전체 호기 선택 시) |
| `isAllZones` | 전체 호기 선택 여부 |
| `userInfo` | 사용자 정보 |

### 엑셀 다운로드 (`GET /detection/timeSereiseData/exportExcel`)

**위치**: `DetectionController.java:951`

**권한**: 4070L WRITE

**파라미터**:
| 파라미터 | 설명 |
|----------|------|
| zone3 | 호기 코드 (선택) |

### 시계열 데이터 API

| 메서드 | URL | 위치 | 설명 |
|--------|-----|------|------|
| GET | `/detection/api/timeseries/data` | :1004 | 시계열 데이터 조회 (limit 기반) |
| GET | `/detection/api/timeseries/latest` | :1034 | 최신 데이터 조회 |
| GET | `/detection/api/timeseries/range` | :1068 | 시간 범위로 조회 |

### 이벤트 상세 조회 (`GET /detection/timeseries/eventDetail`)

**위치**: `DetectionController.java:1254`

히트맵 셀 클릭 시 해당 시간대의 이벤트 상세 조회

**파라미터**:
| 파라미터 | 설명 |
|----------|------|
| eventCode | 이벤트 코드 |
| startTime | 시작 시간 |

### 분석/조치 저장 API

| 메서드 | URL | 위치 | 권한 | @ActivityLog | 설명 |
|--------|-----|------|------|--------------|------|
| POST | `/detection/save-analysis` | :499 | 4070L WRITE | ✅ | 분석 기록 저장 |
| GET | `/detection/get-analysis` | :529 | - | - | 분석 기록 조회 |
| POST | `/detection/save-action` | :564 | 4070L WRITE | - | 조치 저장 |

---

## 서비스 (DetectionService.java)

### 주요 메서드

#### `getAggregated10MinDataFiltered()` - 위치: 2522줄
10분 집계 데이터 조회 (날짜 범위 + 호기 필터링)

```java
public List<TimeSeriesAggregatedDto> getAggregated10MinDataFiltered(
    LocalDateTime startDate,
    LocalDateTime endDate,
    String zone3
)
```

#### `getLatestAggregated10MinDataFiltered()` - 위치: 2541줄
최신 10분 집계 데이터 조회

#### `getAggregated10MinDataByRangeFiltered()` - 위치: 2553줄
시간 범위로 10분 집계 데이터 조회

#### `getAggregated10MinDataByZone()` - 위치: 2570줄
호기별 10분 집계 데이터 조회 (limit 기반)

#### `getAggregated10MinData()` - 위치: 2599줄
10분 집계 데이터 조회 (limit 기반, 전체 호기)

#### `getAggregated10MinDataByRange()` - 위치: 2613줄
시간 범위로 10분 집계 데이터 조회 (호기 필터 없음)

#### `exportTimeSeriesDataToExcel()` - 위치: 2669줄
시계열 데이터 엑셀 내보내기 (EventDefinition 기반 동적 컬럼)

---

## DTO (TimeSeriesAggregatedDto.java)

10분 단위로 집계된 시계열 데이터 구조

### 필드 구성 (총 70개 필드)

| 카테고리 | 필드 패턴 | 개수 | 설명 |
|----------|-----------|------|------|
| 기본 | aggregatedTime, zone1~3, generationOutput, turbineSpeed | 6 | 기본 정보 |
| 이상이벤트 | event0001 ~ event0004 | 4 | 운전정보 이상 이벤트 |
| 자산 | asset1001 ~ asset1036 | 36 | 자산 관련 이벤트 카운트 |
| 연결 | conn2001 ~ conn2024 | 24 | 네트워크 연결 이벤트 카운트 |

### 데이터 변환
```java
public static TimeSeriesAggregatedDto fromMap(Map<String, Object> map)
```
- ClickHouse 쿼리 결과(Map)를 DTO로 변환
- 필드명 매핑: `aggregated_time` → `aggregatedTime`

---

## 프론트엔드 (timesSereiseData.js - 1,890줄)

### 핵심 기능

1. **히트맵 그리드**: 10분 단위 데이터를 AG Grid로 히트맵 형태 표시
2. **호기 분리 표시**: 전체 호기 선택 시 3호기/4호기 그리드 분리
3. **컬럼 비교**: 두 컬럼 선택하여 차이(diff) 계산
4. **이벤트 드로어**: 셀 클릭 시 하단 드로어로 상세 이벤트 표시
5. **사이드바**: 이벤트 상세 정보 + 분석/조치 저장

### 주요 JavaScript 변수

```javascript
const initialData = [[${initialData}]];       // 10분 집계 데이터
const latestData = [[${latestData}]];         // 최신 데이터
const eventDefinitions = [[${eventDefinitions}]]; // 이벤트 정의
const zone3Data = [[${zone3Data}]];           // 3호기 데이터
const zone4Data = [[${zone4Data}]];           // 4호기 데이터
const isAllZones = [[${isAllZones}]];         // 전체 호기 여부
```

### 주요 JavaScript 함수 (38개)

| 함수명 | 위치 | 역할 |
|--------|------|------|
| `buildDynamicMetrics()` | :137 | EventDefinition 기반 카테고리 생성 |
| `applyAgGridTheme()` | :177 | 다크/라이트 모드 테마 적용 |
| `initializeGrid()` | :211 | 메인 AG Grid 초기화 |
| `initializeGrid3()` | :338 | 3호기 AG Grid 초기화 |
| `initializeGrid4()` | :424 | 4호기 AG Grid 초기화 |
| `handleCellClick()` | :531 | 셀 클릭 이벤트 처리 |
| `createColumnDefs()` | :565 | 동적 컬럼 정의 생성 |
| `transformDataForGrid()` | :805 | 데이터를 그리드 형식으로 변환 |
| `calculateColumnMaxValues()` | :872 | 컬럼별 최대값 계산 (히트맵용) |
| `interpolateColorRGB()` | :916 | RGB 색상 보간 (히트맵 색상 계산) |
| `getHeatmapCellStyle()` | :947 | 히트맵 셀 스타일 계산 |
| `openDrawer()` | :1051 | 하단 드로어 열기 |
| `loadDetailInfo()` | :1105 | 이벤트 상세 API 호출 (재시도 로직 포함) |
| `displayEventDetails()` | :1166 | 이벤트 목록 표시 |
| `openEventSidebar()` | :1287 | 이벤트 상세 사이드바 열기 |
| `updateSidebarContent()` | :1314 | 사이드바 내용 업데이트 |
| `retryLoadDetailInfo()` | :1380 | 이벤트 상세 조회 재시도 |
| `loadComprehensiveJudgmentSupportInformation()` | :1396 | 종합 판단 지원 정보 로드 |
| `displayRelatedEvents()` | :1445 | 관련 이벤트 표시 |
| `saveAction()` | :1563 | 조치 저장 |
| `loadAnalysisHistory()` | :1621 | 분석 기록 조회 |
| `saveAnalysisHistory()` | :1712 | 분석 기록 저장 |
| `downloadExcel()` | :1786 | 엑셀 다운로드 |

### 그리드 구조

**행(Row) 구조**:
- 대분류: 운전현황, 자주사용하는이상탐지, 운전정보 이상탐지, 자산 이상탐지, 네트워크 이상탐지
- 소분류: 각 이벤트명 (EventDefinition 기반)

**열(Column) 구조**:
- 고정 왼쪽: category, metric
- 시간 컬럼: time_0, time_1, ... (10분 단위)
- 고정 오른쪽: diff (두 컬럼 차이)

### 히트맵 색상 (RGB 보간 방식)

`interpolateColorRGB()` 함수에서 값에 따라 색상 계산:
- 0: `#1a1d20` (검정)
- MIN: `rgb(20, 30, 50)` (진한 파랑)
- MAX: `rgb(100, 150, 255)` (밝은 파랑)

컬럼별 최대값(`columnMaxValues`)을 기준으로 비율 계산 후 색상 보간

### UI 컴포넌트

1. **메인 그리드 (`#timeSeriesGrid`)**: 600px 높이, 히트맵 표시
2. **3호기 그리드 (`#timeSeriesGrid3`)**: 400px 높이 (전체 호기 선택 시)
3. **4호기 그리드 (`#timeSeriesGrid4`)**: 400px 높이 (전체 호기 선택 시)
4. **하단 드로어 (`#detailDrawer`)**: 50vh 높이, 이벤트 상세 목록
5. **사이드바 (`#eventDetailOffcanvas`)**: 개별 이벤트 상세 + 분석/조치

### 재시도 로직 (ClickHouse 쓰기 지연 대응)

`loadDetailInfo()` 함수에서 이벤트 상세 조회 시:
1. 초기 요청 (1.5초 지연 후)
2. 데이터 없으면 최대 3회 재시도 (각 2초 간격)
3. 최종 실패 시 "재시도" 버튼 표시

```javascript
// 재시도 로직 (ClickHouse 쓰기 지연 대응)
const initialDelay = 1500;  // 1.5초 초기 지연
const maxRetries = 3;       // 최대 3회 재시도
const retryDelay = 2000;    // 2초 간격
```

---

## 권한 및 보안

### 권한 검사

| 기능 | @RequirePermission | @ActivityLog |
|------|-------------------|--------------|
| 페이지 접근 | 4070L READ | - |
| 엑셀 다운로드 | 4070L WRITE | - |
| 분석 기록 저장 | 4070L WRITE | ✅ |
| 조치 저장 | 4070L WRITE | - |
| 시계열 데이터 조회 | - | - |
| 이벤트 상세 조회 | - | - |
| 분석 기록 조회 | - | - |

### 권한 기반 데이터 마스킹

페이지 자체 접근은 READ 권한만 필요하며, 이벤트 상세 조회 API에는 별도 `@RequirePermission` 없음.
**DataMaskingUtils**를 통해 권한에 따라 IP/MAC 마스킹 적용:

```javascript
// data_masking.js
isReadOnlyUser: function () {
    if (permissions.isAdmin) return false;          // 관리자: 마스킹 안함
    if (permissions.canWrite || permissions.canDelete) return false;  // 쓰기/삭제 권한: 마스킹 안함
    return true;  // READ 전용: 마스킹 적용
}
```

- READ 전용 사용자: IP/MAC 마스킹 표시 (`192.168.***.**`)
- WRITE 이상 권한: 전체 IP/MAC 표시
- 엑셀 다운로드 버튼: WRITE 권한 없으면 숨김

---

## API 엔드포인트 요약

| 메서드 | URL | 권한 | 위치 | 설명 |
|--------|-----|------|------|------|
| GET | `/detection/timeSereiseData` | 4070L READ | :864 | 페이지 렌더링 |
| GET | `/detection/timeSereiseData/exportExcel` | 4070L WRITE | :951 | 엑셀 다운로드 |
| GET | `/detection/api/timeseries/data` | - | :1004 | 시계열 데이터 조회 |
| GET | `/detection/api/timeseries/latest` | - | :1034 | 최신 데이터 조회 |
| GET | `/detection/api/timeseries/range` | - | :1068 | 시간 범위 조회 |
| GET | `/detection/timeseries/eventDetail` | - | :1254 | 이벤트 상세 조회 |
| POST | `/detection/save-analysis` | 4070L WRITE | :499 | 분석 기록 저장 |
| GET | `/detection/get-analysis` | - | :529 | 분석 기록 조회 |
| POST | `/detection/save-action` | 4070L WRITE | :564 | 조치 저장 |

---

## 데이터 흐름

```
[ClickHouse] stats_1min 테이블
         ↓
[Repository] Stats1MinRepository.findAggregated10MinData*()
         ↓
[Service] getAggregated10MinDataFiltered() (2522줄)
         ↓
[DTO] TimeSeriesAggregatedDto.fromMap()
         ↓
[Controller] Model에 데이터 추가 (864줄)
         ↓
[Frontend] Thymeleaf → JavaScript 변수
         ↓
[AG Grid] transformDataForGrid() → createColumnDefs()
         ↓
[히트맵 표시] interpolateColorRGB() → getHeatmapCellStyle()
```

---

## 이벤트 카테고리 매핑

EventDefinition의 `eventType`에 따른 카테고리 분류:

| eventType | 카테고리 | 설명 |
|-----------|----------|------|
| operation | 운전정보 이상탐지 | 운전 데이터 이상 |
| asset | 자산 이상탐지 | 자산 변경/이상 |
| network | 네트워크 이상탐지 | 네트워크 연결 이상 |

`isFavorit` 플래그가 true인 이벤트는 "자주사용하는이상탐지" 카테고리에도 표시

---

## 다크모드 지원

CSS 변수를 사용한 테마 전환:

| 변수 | 라이트 모드 | 다크 모드 |
|------|-------------|-----------|
| `--grid-bg-primary` | #ffffff | #1a1d20 |
| `--grid-text-primary` | #212529 | #e0e0e0 |
| `--grid-border-color` | #dee2e6 | #3d4663 |
| `--grid-header-bg` | #e9ecef | #2d3142 |

MutationObserver로 `data-bs-theme` 속성 변경 감지하여 그리드 새로고침

---

## 컬럼 비교 기능

1. 첫 번째 시간 컬럼 헤더 클릭 → 선택
2. 두 번째 시간 컬럼 헤더 클릭 → 선택
3. `diff` 컬럼에 두 값의 차이 표시 (큰 값 - 작은 값)
4. 같은 컬럼 다시 클릭 → 선택 해제

---

## 관련 문서

- [이상 이벤트 탐지 현황](detection-timesdata-system.md) - 이벤트 목록 조회
- [세션 필터링](session-filtering.md) - 날짜/호기 필터링
- [프론트엔드 패턴](frontend-patterns.md) - AG Grid 패턴
- [데이터베이스](database.md) - ClickHouse 시계열 데이터

---

## 프로그램 명세서

### TSE_001 - 시계열 이종 데이터 분석 페이지

| 프로그램 ID | TSE_001 | 프로그램명 | 시계열 이종 데이터 분석 페이지 |
|------------|---------|----------|--------------------------|
| 분류 | 이상탐지 | 처리유형 | 화면 |
| 클래스명 | DetectionController.java | 메서드명 | timeSereisData() |
| 위치 | 864줄 | | |

▣ 기능 설명

10분 단위 집계된 시계열 데이터를 히트맵 형태로 시각화하여 이상 탐지 패턴을 분석하는 페이지를 렌더링한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 세션에서 날짜/호기 정보 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | initialData | 10분집계데이터 | List\<TimeSeriesAggregatedDto\> | Y | 히트맵 표시용 |
| 2 | latestData | 최신데이터 | TimeSeriesAggregatedDto | Y | 최신 집계 데이터 |
| 3 | dataSize | 데이터건수 | int | Y | 전체 데이터 수 |
| 4 | eventDefinitions | 이벤트정의 | List\<EventDefinition\> | Y | is_show_time_series=true |
| 5 | zone3Data | 3호기데이터 | List | N | 전체 호기 선택 시 |
| 6 | zone4Data | 4호기데이터 | List | N | 전체 호기 선택 시 |
| 7 | isAllZones | 전체호기여부 | Boolean | Y | 전체 호기 선택 플래그 |
| 8 | userInfo | 사용자정보 | Map | Y | userId, userName |
| 9 | HTML | 분석 페이지 | String | Y | Thymeleaf 렌더링 HTML |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 검사 (menuId: 4070L, READ) | @RequirePermission |
| 2 | 세션에서 startDateTime/endDateTime/zoneCode 조회 | 기본값: 최근 7일 |
| 3 | DetectionService.getAggregated10MinDataFiltered() 호출 | 10분 집계 |
| 4 | DetectionService.getLatestAggregated10MinDataFiltered() 호출 | 최신 데이터 |
| 5 | EventDefinition 조회 (is_show_time_series=true) | 시계열 표시용 |
| 6 | 전체 호기 선택 시 3호기/4호기 데이터 분리 | |
| 7 | pages/detection/timeSereiseData 템플릿 반환 | AG Grid 히트맵 |

---

### TSE_002 - 시계열 데이터 엑셀 다운로드

| 프로그램 ID | TSE_002 | 프로그램명 | 시계열 데이터 엑셀 다운로드 |
|------------|---------|----------|------------------------|
| 분류 | 이상탐지 | 처리유형 | 조회 |
| 클래스명 | DetectionController.java | 메서드명 | exportTimeSeriesExcel() |
| 위치 | 951줄 | | |

▣ 기능 설명

시계열 이종 데이터 분석 결과를 엑셀 파일로 다운로드한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | zone3 | 호기코드 | String | N | 세션 기본값 사용 |
| 2 | startDateTime | 시작일시 | String | N | 세션 기본값 사용 |
| 3 | endDateTime | 종료일시 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | file | 엑셀파일 | ByteArrayResource | Y | Excel 바이너리 |
| 2 | filename | 파일명 | String | Y | 시계열분석_YYYYMMDD.xlsx |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 검사 (menuId: 4070L, WRITE) | @RequirePermission |
| 2 | 세션에서 날짜/호기 정보 조회 | |
| 3 | DetectionService.exportTimeSeriesDataToExcel() 호출 | |
| 4 | Apache POI XSSFWorkbook 생성 | |
| 5 | 엑셀 파일 반환 | |

---

### TSE_003 - 시계열 데이터 조회 (limit 기반)

| 프로그램 ID | TSE_003 | 프로그램명 | 시계열 데이터 조회 |
|------------|---------|----------|------------------|
| 분류 | 이상탐지 | 처리유형 | 조회 |
| 클래스명 | DetectionController.java | 메서드명 | getTimeSeriesData() |
| 위치 | 1004줄 | | |

▣ 기능 설명

limit 기준으로 시계열 10분 집계 데이터를 조회한다. 히트맵 갱신용 API.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | limit | 조회건수 | int | N | 기본값 144 (24시간) |
| 2 | zone3 | 호기코드 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | data | 시계열데이터 | List\<TimeSeriesAggregatedDto\> | Y | 10분 집계 데이터 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | DetectionService.getAggregated10MinDataByZone() 호출 | limit 기반 |
| 2 | JSON 응답 반환 | |

---

### TSE_004 - 최신 시계열 데이터 조회

| 프로그램 ID | TSE_004 | 프로그램명 | 최신 시계열 데이터 조회 |
|------------|---------|----------|---------------------|
| 분류 | 이상탐지 | 처리유형 | 조회 |
| 클래스명 | DetectionController.java | 메서드명 | getLatestTimeSeriesData() |
| 위치 | 1034줄 | | |

▣ 기능 설명

가장 최신의 10분 집계 데이터를 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | zone3 | 호기코드 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | data | 최신데이터 | TimeSeriesAggregatedDto | Y | 최신 10분 집계 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | DetectionService.getLatestAggregated10MinDataFiltered() 호출 | |
| 2 | JSON 응답 반환 | |

---

### TSE_005 - 시간 범위 시계열 데이터 조회

| 프로그램 ID | TSE_005 | 프로그램명 | 시간 범위 시계열 데이터 조회 |
|------------|---------|----------|------------------------|
| 분류 | 이상탐지 | 처리유형 | 조회 |
| 클래스명 | DetectionController.java | 메서드명 | getTimeSeriesDataByRange() |
| 위치 | 1068줄 | | |

▣ 기능 설명

지정된 시간 범위의 시계열 10분 집계 데이터를 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | startTime | 시작시간 | String | Y | yyyy-MM-dd HH:mm |
| 2 | endTime | 종료시간 | String | Y | yyyy-MM-dd HH:mm |
| 3 | zone3 | 호기코드 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | data | 시계열데이터 | List\<TimeSeriesAggregatedDto\> | Y | 범위 내 데이터 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | startTime/endTime 파싱 | LocalDateTime 변환 |
| 2 | DetectionService.getAggregated10MinDataByRangeFiltered() 호출 | |
| 3 | JSON 응답 반환 | |

---

### TSE_006 - 이벤트 상세 조회

| 프로그램 ID | TSE_006 | 프로그램명 | 이벤트 상세 조회 |
|------------|---------|----------|----------------|
| 분류 | 이상탐지 | 처리유형 | 조회 |
| 클래스명 | DetectionController.java | 메서드명 | getTimeSeriesEventDetail() |
| 위치 | 1254줄 | | |

▣ 기능 설명

히트맵 셀 클릭 시 해당 시간대의 이벤트 상세 목록을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | eventCode | 이벤트코드 | String | Y | 이벤트 식별 코드 |
| 2 | startTime | 시작시간 | String | Y | 10분 구간 시작 시간 |
| 3 | zone3 | 호기코드 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | events | 이벤트목록 | List\<Event\> | Y | 해당 시간대 이벤트 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | startTime 파싱 (10분 구간 계산) | |
| 2 | EventRepository.findByEventCodeAndTimestampBetween() 호출 | |
| 3 | IP/MAC Base64 인코딩 | 보안 처리 |
| 4 | JSON 응답 반환 | |

▣ 권한 기반 마스킹

- 페이지 접근 시 READ 권한으로 API 호출 가능
- DataMaskingUtils를 통해 READ 전용 사용자에게 IP/MAC 마스킹 적용
- 보안 취약점이 아님: 권한에 따른 데이터 마스킹으로 처리됨

---

### TSE_007 - 분석 기록 저장

| 프로그램 ID | TSE_007 | 프로그램명 | 분석 기록 저장 |
|------------|---------|----------|--------------|
| 분류 | 이상탐지 | 처리유형 | 등록 |
| 클래스명 | DetectionController.java | 메서드명 | saveAnalysis() |
| 위치 | 499줄 | @ActivityLog | ✅ |

▣ 기능 설명

시계열 분석 결과에 대한 분석 기록을 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | eventId | 이벤트ID | Long | Y | 대상 이벤트 ID |
| 2 | eventCode | 이벤트코드 | String | Y | 이벤트 코드 |
| 3 | analysisContent | 분석내용 | String | Y | 분석 기록 텍스트 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | int | Y | 0: 성공 |
| 2 | message | 메시지 | String | Y | 처리 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 검사 (menuId: 4070L, WRITE) | @RequirePermission |
| 2 | 세션에서 사용자 ID 추출 | |
| 3 | AlarmAction 엔티티 생성 | |
| 4 | AlarmActionRepository.save() 호출 | |
| 5 | 감사 로그 기록 | @ActivityLog |
| 6 | 성공 응답 반환 | |

---

### TSE_008 - 분석 기록 조회

| 프로그램 ID | TSE_008 | 프로그램명 | 분석 기록 조회 |
|------------|---------|----------|--------------|
| 분류 | 이상탐지 | 처리유형 | 조회 |
| 클래스명 | DetectionController.java | 메서드명 | getAnalysis() |
| 위치 | 529줄 | | |

▣ 기능 설명

특정 이벤트의 분석 기록 목록을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | eventId | 이벤트ID | Long | Y | 대상 이벤트 ID |
| 2 | eventCode | 이벤트코드 | String | Y | 이벤트 코드 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | data | 분석기록목록 | List\<AlarmAction\> | Y | 분석 기록 목록 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | AlarmActionRepository.findByEventIdAndEventCode() 호출 | |
| 2 | 생성일 기준 정렬 | DESC |
| 3 | JSON 응답 반환 | |

---

### TSE_009 - 조치 저장

| 프로그램 ID | TSE_009 | 프로그램명 | 조치 저장 |
|------------|---------|----------|---------|
| 분류 | 이상탐지 | 처리유형 | 등록 |
| 클래스명 | DetectionController.java | 메서드명 | saveAction() |
| 위치 | 564줄 | | |

▣ 기능 설명

시계열 분석 결과에 대한 조치를 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | eventId | 이벤트ID | Long | Y | 대상 이벤트 ID |
| 2 | eventCode | 이벤트코드 | String | Y | 이벤트 코드 |
| 3 | actionType | 조치유형 | String | Y | 조치 유형 |
| 4 | actionStory | 조치사유 | String | N | 조치 내용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | int | Y | 0: 성공 |
| 2 | message | 메시지 | String | Y | 처리 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 검사 (menuId: 4070L, WRITE) | @RequirePermission |
| 2 | 세션에서 사용자 ID 추출 | |
| 3 | EventActionLog 엔티티 생성 | |
| 4 | 이벤트 상태 업데이트 | isAction 플래그 |
| 5 | 성공 응답 반환 | |