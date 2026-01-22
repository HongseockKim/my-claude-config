# 통계 및 리포트 생성 (analysis/reportAdd) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/analysis/reportAdd` |
| **메뉴 ID** | - (권한 체크 없음) |
| **한글명** | 통계 및 리포트 생성 |
| **목적** | 드래그 앤 드롭으로 위젯을 배치하여 PDF 리포트 생성 |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/AnalysisController.java
Service:    src/main/java/com/otoones/otomon/service/ReportService.java
Template:   src/main/resources/templates/pages/analysis/reportAdd.html
Model:      src/main/java/com/otoones/otomon/model/Report.java
            src/main/java/com/otoones/otomon/model/ReportWidget.java
DTO:        src/main/java/com/otoones/otomon/dto/ReportDto.java
```

---

## 컨트롤러 (AnalysisController.java)

### 페이지 렌더링 (`GET /analysis/reportAdd`)

**위치**: `AnalysisController.java:218-224`

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| zoneList | 사용자 접근 가능한 호기 목록 |
| currentUser | 현재 로그인 사용자 정보 |

### 리포트 CRUD API

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/analysis/report/{id}` | 리포트 상세 조회 |
| POST | `/analysis/report/save` | 리포트 저장 |
| PUT | `/analysis/report/{id}` | 리포트 수정 |
| DELETE | `/analysis/report/{id}` | 리포트 삭제 |
| GET | `/analysis/report/list` | 리포트 목록 조회 |

### 차트 데이터 API (`GET /analysis/report/chart-data`)

**위치**: `AnalysisController.java:347-384`

**파라미터**:
| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| widgetKey | String | O | 위젯 키 (fragment 경로) |
| chartType | String | X | 차트 유형 (bar/line/doughnut) |
| zone | String | X | 호기 코드 |
| year | Integer | X | 조회 년도 |
| month | Integer | X | 조회 월 |

---

## 프론트엔드 (reportAdd.html)

### 핵심 기능

1. **드래그 앤 드롭 위젯 배치**: GridStack 라이브러리 사용
2. **텍스트 위젯**: 자유 텍스트 입력
3. **차트 위젯**: 대시보드 위젯 데이터를 차트로 표시
4. **PDF 생성**: html2canvas + jsPDF로 A4 PDF 생성
5. **리포트 저장/수정**: DB에 위젯 구성 저장

### 사용 라이브러리

| 라이브러리 | 용도 |
|-----------|------|
| GridStack | 드래그 앤 드롭 그리드 레이아웃 |
| ECharts | 차트 렌더링 |
| html2canvas | HTML → Canvas 변환 |
| jsPDF | Canvas → PDF 생성 |
| dayjs | 날짜 처리 |

### 페이지 레이아웃

```
┌─────────────────────────────────────────────────┐
│ 상단 버튼: 초기화 | 미리보기 | 저장              │
├──────────────┬──────────────────────────────────┤
│ 위젯 팔레트  │ A4 캔버스 (800px × 1131px)       │
│ ┌──────────┐│ ┌──────────────────────────────┐ │
│ │조회조건   ││ │ 리포트 헤더                  │ │
│ │호기/년월  ││ │ 제목 | 작성자 | 호기         │ │
│ └──────────┘│ ├──────────────────────────────┤ │
│ ┌──────────┐│ │ GridStack 영역               │ │
│ │텍스트     ││ │ (위젯 드래그 앤 드롭)        │ │
│ └──────────┘│ │                              │ │
│ ┌──────────┐│ │                              │ │
│ │대시보드   ││ │                              │ │
│ │위젯 목록  ││ │                              │ │
│ └──────────┘│ └──────────────────────────────┘ │
└──────────────┴──────────────────────────────────┘
```

### GridStack 설정

```javascript
grid = GridStack.init({
    column: 12,
    cellHeight: 50,
    margin: 10,
    float: true,
    removable: false,
    acceptWidgets: false,
    disableResize: false,
    animate: true
}, '#gridStack');
```

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `initGridStack()` | GridStack 초기화 |
| `loadDashboardWidgets()` | 대시보드 위젯 목록 로드 |
| `setupWidgetDrag()` | 위젯 드래그 이벤트 설정 |
| `handleDrop()` | 위젯 드롭 처리 |
| `addWidgetToGrid()` | 그리드에 위젯 추가 |
| `loadChartData()` | 차트 데이터 API 호출 |
| `renderChart()` | ECharts 차트 렌더링 |
| `getChartOption()` | 차트 옵션 생성 |
| `collectWidgetData()` | 저장용 위젯 데이터 수집 |
| `saveReport()` | 리포트 저장 |
| `loadExistingReport()` | 기존 리포트 로드 (수정 모드) |
| `restoreWidgets()` | 저장된 위젯 복원 |
| `generatePDF()` | PDF 생성 |
| `previewPDF()` | PDF 미리보기 |
| `clearReport()` | 리포트 초기화 |
| `reloadAllCharts()` | 모든 차트 리로드 |

### 차트 타입

| 타입 | 설명 | ECharts 옵션 |
|------|------|-------------|
| bar | 막대 차트 | `type: 'bar'` |
| line | 라인 차트 | `type: 'line', smooth: true` |
| doughnut | 도넛 차트 | `type: 'pie', radius: ['30%', '60%']` |

### 위젯 데이터 구조

```javascript
{
    widgetType: 'chart' | 'text',
    widgetKey: 'dashboard/event-type-status',
    chartType: 'bar' | 'line' | 'doughnut',
    content: '',  // 텍스트 위젯용
    gridX: 0,
    gridY: 0,
    gridW: 6,
    gridH: 4,
    sortOrder: 0
}
```

---

## API 엔드포인트 요약

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/analysis/reportAdd` | 페이지 렌더링 |
| GET | `/analysis/report/{id}` | 리포트 상세 |
| POST | `/analysis/report/save` | 리포트 저장 |
| PUT | `/analysis/report/{id}` | 리포트 수정 |
| DELETE | `/analysis/report/{id}` | 리포트 삭제 |
| GET | `/analysis/report/list` | 리포트 목록 |
| GET | `/analysis/report/chart-data` | 차트 데이터 |
| GET | `/setting/dashboard/api/available-widgets` | 사용 가능한 위젯 목록 |

---

## 데이터 흐름

### 리포트 생성
```
[호기/년월 선택] → [위젯 팔레트에서 드래그]
         ↓
[GridStack 드롭] → [차트 타입 선택 모달]
         ↓
[addWidgetToGrid()] → [loadChartData()]
         ↓
[/analysis/report/chart-data API] → [renderChart()]
         ↓
[저장 버튼] → [collectWidgetData()] → [/analysis/report/save]
```

### 리포트 수정
```
[URL ?id=123] → [loadExistingReport(123)]
         ↓
[/analysis/report/123 API] → [restoreWidgets()]
         ↓
[위젯 수정] → [저장] → [PUT /analysis/report/123]
```

### PDF 생성
```
[미리보기 버튼] → [generatePDF(false)]
         ↓
[html2canvas(reportCanvas)] → [Canvas 이미지]
         ↓
[jsPDF.addImage()] → [pdf.output('bloburl')]
         ↓
[새 탭에서 PDF 열기]
```

---

## 리포트 저장 구조 (ReportDto)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | Long | PK |
| title | String | 리포트 제목 |
| zoneCode | String | 호기 코드 |
| reportZone | String | 조회 호기 |
| reportYear | Integer | 조회 년도 |
| reportMonth | Integer | 조회 월 |
| reportDate | LocalDate | 리포트 날짜 |
| widgets | List | 위젯 목록 |
| createdAt | LocalDateTime | 생성일시 |
| updatedAt | LocalDateTime | 수정일시 |

---

## 사용 가능한 대시보드 위젯

| widgetKey | 제목 |
|-----------|------|
| dashboard/event-type-status | 이벤트 유형별 현황 |
| dashboard/whitelist-trend | 화이트리스트 위반 추이 |
| dashboard/whitelist-policy-trend | 화이트리스트 정책 등록 |
| dashboard/event-action-trend | 이벤트 조치 추이 |
| dashboard/facility_widget | 설비유형별 자산 |
| dashboard/manufacture_company | 제조사별 자산 |
| dashboard/asset_status_analysis | 자산 상태 분석 |
| dashboard/asset-operation-status | 운전상태별 자산 |
| dashboard/power-chart | 발전량 추이 |
| dashboard/sp_03/zone-status | 3호기 발전량 |
| dashboard/sp_04/zone-status | 4호기 발전량 |
| dashboard/turbine-speed-trend | 터빈속도 추이 |

---

## A4 캔버스 스타일

```css
.report-canvas {
    width: 100%;
    max-width: 800px;
    min-height: 1131px;  /* 800 * 1.414 (A4 비율) */
    background: #fff;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    margin: 0 auto;
    padding: 40px;
}
```

---

## 호기 선택 검증

호기가 선택되지 않으면 위젯 드래그/드롭 비활성화:

```javascript
function checkZoneSelection() {
    const zoneSelected = $('#reportZone').val() ? true : false;
    if (zoneSelected) {
        $('.widget-item').removeClass('disabled').attr('draggable', 'true');
    } else {
        $('.widget-item').addClass('disabled').attr('draggable', 'false');
    }
}
```

---

## 차트 리사이즈

GridStack 위젯 리사이즈 시 차트도 함께 리사이즈:

```javascript
grid.on('resizestop', function (event, element) {
    const $chartWidget = $(element).find('.chart-widget');
    if ($chartWidget.length > 0) {
        const chartId = $chartWidget.attr('id');
        resizeChart(chartId);
    }
});
```

---

## 관련 문서

- [대시보드 위젯](dashboard-widget-system.md) - 대시보드 위젯 시스템
- [프론트엔드 패턴](frontend-patterns.md) - ECharts 패턴

---

## 프로그램 명세서

### ARA_001 - 통계 및 리포트 생성 페이지

| 프로그램 ID | ARA_001 | 프로그램명 | 통계 및 리포트 생성 페이지 |
|------------|---------|----------|------------------------|
| 분류 | 분석 관리 | 처리유형 | 화면 |
| 클래스명 | AnalysisController.java | 메서드명 | reportAddPage() |

▣ 기능 설명

드래그 앤 드롭으로 위젯을 배치하여 PDF 리포트를 생성하는 페이지를 렌더링한다. GridStack 기반의 편집 화면을 제공한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 리포트 ID | Long | N | 수정 모드 시 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | zoneList | 호기 목록 | List<String> | Y | 사용자 접근 가능 호기 |
| 2 | currentUser | 현재 사용자 | UserDto | Y | 로그인 사용자 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 사용자 접근 가능 호기 목록 조회 | getAccessibleZones() |
| 2 | 현재 로그인 사용자 정보 조회 | getCurrentUser() |
| 3 | Model에 데이터 추가 및 뷰 반환 | pages/analysis/reportAdd |

---

### ARA_002 - 리포트 상세 조회 API

| 프로그램 ID | ARA_002 | 프로그램명 | 리포트 상세 조회 API |
|------------|---------|----------|-------------------|
| 분류 | 분석 조회 | 처리유형 | 조회 |
| 클래스명 | AnalysisController.java | 메서드명 | getReport() |

▣ 기능 설명

저장된 리포트의 상세 정보와 위젯 구성을 조회한다. 수정 모드에서 기존 리포트를 불러올 때 사용한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 리포트 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 리포트 정보 | ReportDto | Y | 리포트 상세 |
| 4 | data.id | 리포트 ID | Long | Y | PK |
| 5 | data.title | 제목 | String | Y | 리포트 제목 |
| 6 | data.zoneCode | 호기 코드 | String | Y | 작성 호기 |
| 7 | data.reportZone | 조회 호기 | String | Y | 데이터 조회 호기 |
| 8 | data.reportYear | 조회 년도 | Integer | Y | - |
| 9 | data.reportMonth | 조회 월 | Integer | Y | - |
| 10 | data.widgets | 위젯 목록 | List<ReportWidget> | Y | 배치된 위젯 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 리포트 존재 확인 | findById() |
| 2 | 리포트 상세 조회 | 위젯 목록 포함 |
| 3 | DTO 변환 및 결과 반환 | JSON 응답 |

---

### ARA_003 - 리포트 저장 API

| 프로그램 ID | ARA_003 | 프로그램명 | 리포트 저장 API |
|------------|---------|----------|---------------|
| 분류 | 분석 관리 | 처리유형 | 등록 |
| 클래스명 | AnalysisController.java | 메서드명 | saveReport() |

▣ 기능 설명

새로운 리포트를 저장한다. 위젯 배치 정보와 차트 설정을 함께 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | title | 제목 | String | Y | 리포트 제목 |
| 2 | zoneCode | 호기 코드 | String | Y | 작성 호기 |
| 3 | reportZone | 조회 호기 | String | Y | 데이터 조회 호기 |
| 4 | reportYear | 조회 년도 | Integer | Y | - |
| 5 | reportMonth | 조회 월 | Integer | Y | - |
| 6 | widgets | 위젯 목록 | List<Object> | Y | 배치된 위젯 정보 |
| 7 | widgets[].widgetType | 위젯 타입 | String | Y | chart/text |
| 8 | widgets[].widgetKey | 위젯 키 | String | N | 대시보드 위젯 경로 |
| 9 | widgets[].chartType | 차트 타입 | String | N | bar/line/doughnut |
| 10 | widgets[].content | 텍스트 내용 | String | N | 텍스트 위젯용 |
| 11 | widgets[].gridX | X 좌표 | Integer | Y | 그리드 X 위치 |
| 12 | widgets[].gridY | Y 좌표 | Integer | Y | 그리드 Y 위치 |
| 13 | widgets[].gridW | 너비 | Integer | Y | 그리드 너비 |
| 14 | widgets[].gridH | 높이 | Integer | Y | 그리드 높이 |
| 15 | widgets[].sortOrder | 정렬 순서 | Integer | Y | 표시 순서 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 저장된 리포트 | ReportDto | Y | 생성된 리포트 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 입력값 유효성 검증 | 필수 필드 체크 |
| 2 | Report Entity 생성 | - |
| 3 | ReportWidget 목록 생성 | 위젯별 저장 |
| 4 | 리포트 저장 | save() |
| 5 | 결과 반환 | JSON 응답 |

---

### ARA_004 - 리포트 수정 API

| 프로그램 ID | ARA_004 | 프로그램명 | 리포트 수정 API |
|------------|---------|----------|---------------|
| 분류 | 분석 관리 | 처리유형 | 수정 |
| 클래스명 | AnalysisController.java | 메서드명 | updateReport() |

▣ 기능 설명

기존 리포트를 수정한다. 위젯 배치 변경 및 설정 수정을 반영한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 리포트 ID | Long | Y | PathVariable |
| 2 | title | 제목 | String | Y | 리포트 제목 |
| 3 | reportZone | 조회 호기 | String | Y | 데이터 조회 호기 |
| 4 | reportYear | 조회 년도 | Integer | Y | - |
| 5 | reportMonth | 조회 월 | Integer | Y | - |
| 6 | widgets | 위젯 목록 | List<Object> | Y | 수정된 위젯 정보 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 수정된 리포트 | ReportDto | Y | 변경된 리포트 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 리포트 존재 확인 | findById() |
| 2 | 리포트 정보 업데이트 | - |
| 3 | 기존 위젯 삭제 | deleteAllByReportId() |
| 4 | 새 위젯 목록 저장 | 재생성 방식 |
| 5 | 결과 반환 | JSON 응답 |

---

### ARA_005 - 리포트 삭제 API

| 프로그램 ID | ARA_005 | 프로그램명 | 리포트 삭제 API |
|------------|---------|----------|---------------|
| 분류 | 분석 관리 | 처리유형 | 삭제 |
| 클래스명 | AnalysisController.java | 메서드명 | deleteReport() |

▣ 기능 설명

리포트를 삭제한다. 연관된 위젯 정보도 함께 삭제된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 리포트 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 리포트 존재 확인 | findById() |
| 2 | 연관 위젯 삭제 | CASCADE 또는 수동 삭제 |
| 3 | 리포트 삭제 | delete() |
| 4 | 결과 반환 | JSON 응답 |

---

### ARA_006 - 리포트 목록 조회 API

| 프로그램 ID | ARA_006 | 프로그램명 | 리포트 목록 조회 API |
|------------|---------|----------|-------------------|
| 분류 | 분석 조회 | 처리유형 | 조회 |
| 클래스명 | AnalysisController.java | 메서드명 | getReportList() |

▣ 기능 설명

저장된 리포트 목록을 조회한다. 사용자 또는 호기별로 필터링할 수 있다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | zoneCode | 호기 코드 | String | N | 필터링 조건 |
| 2 | page | 페이지 번호 | Integer | N | 기본값 0 |
| 3 | size | 페이지 크기 | Integer | N | 기본값 10 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 리포트 목록 | List<ReportDto> | Y | 리포트 리스트 |
| 4 | data[].id | 리포트 ID | Long | Y | PK |
| 5 | data[].title | 제목 | String | Y | 리포트 제목 |
| 6 | data[].zoneCode | 호기 코드 | String | Y | 작성 호기 |
| 7 | data[].createdAt | 생성일시 | LocalDateTime | Y | - |
| 8 | totalCount | 전체 건수 | Long | Y | 페이징용 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 필터 조건 구성 | 호기, 사용자 등 |
| 2 | 리포트 목록 조회 | 페이징 적용 |
| 3 | 결과 반환 | JSON 응답 |

---

### ARA_007 - 차트 데이터 조회 API

| 프로그램 ID | ARA_007 | 프로그램명 | 차트 데이터 조회 API |
|------------|---------|----------|-------------------|
| 분류 | 분석 조회 | 처리유형 | 조회 |
| 클래스명 | AnalysisController.java | 메서드명 | getChartData() |

▣ 기능 설명

대시보드 위젯의 차트 데이터를 조회한다. 위젯 키와 조회 조건에 따라 ECharts용 데이터를 반환한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | widgetKey | 위젯 키 | String | Y | 대시보드 위젯 경로 |
| 2 | chartType | 차트 타입 | String | N | bar/line/doughnut |
| 3 | zone | 호기 코드 | String | N | 조회 호기 |
| 4 | year | 조회 년도 | Integer | N | 기본값 현재년도 |
| 5 | month | 조회 월 | Integer | N | 기본값 현재월 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 차트 데이터 | Object | Y | ECharts 옵션용 |
| 4 | data.labels | 라벨 목록 | List<String> | Y | X축 라벨 |
| 5 | data.datasets | 데이터셋 | List<Object> | Y | 차트 데이터 |
| 6 | data.datasets[].label | 범례명 | String | Y | - |
| 7 | data.datasets[].data | 값 목록 | List<Number> | Y | Y축 값 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | widgetKey로 위젯 타입 확인 | - |
| 2 | 조회 조건 구성 | zone, year, month |
| 3 | 위젯별 데이터 조회 서비스 호출 | getWidgetData() |
| 4 | 차트 타입에 맞게 데이터 변환 | labels, datasets 구성 |
| 5 | 결과 반환 | JSON 응답 |
