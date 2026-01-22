# 대시보드 위젯 시스템

## 개요

대시보드(`/dashboard`)는 **템플릿 기반 위젯 시스템**으로, GridStack 라이브러리를 사용한 드래그-앤-드롭 레이아웃을 지원합니다.

### 핵심 특징

- **템플릿 기반**: 사용자별 개별 설정 없이 템플릿으로 관리
- **호기별 필터링**: `zone_code`로 3호기(`sp_03`), 4호기(`sp_04`) 구분
- **12단 GridStack**: 반응형 그리드 레이아웃
- **Thymeleaf Fragment**: 동적 위젯 렌더링

---

## 테이블 구조

### 테이블 관계

```
dashboard_templates (1) ──▶ (N) dashboard_template_widgets
        │
        └── 호기별 기본 템플릿 정의

dashboard_widget_layout ── 독립적 (템플릿과 별개로 동적 레이아웃 저장)
```

### dashboard_templates (템플릿 정의)

| 컬럼명           | 타입                  | 설명                                |
|---------------|---------------------|-----------------------------------|
| id            | BIGINT (PK)         | 템플릿 ID                            |
| template_name | VARCHAR(100) UNIQUE | 템플릿 이름                            |
| description   | VARCHAR(255)        | 설명                                |
| is_default    | BOOLEAN             | 기본 템플릿 여부                         |
| zone_code     | VARCHAR(20)         | 호기 코드 (`sp_03`, `sp_04`, NULL=공통) |
| created_at    | DATETIME            | 생성일시                              |
| updated_at    | DATETIME            | 수정일시                              |

**초기 데이터 (4개)**:

- 기본 템플릿 (3호기) - `sp_03`, `is_default=1`
- 기본 템플릿 (4호기) - `sp_04`, `is_default=1`
- 운전현황 템플릿 - 공통
- 보안현황 템플릿 - 공통

### dashboard_template_widgets (위젯 배치)

| 컬럼명           | 타입           | 설명                    |
|---------------|--------------|-----------------------|
| id            | BIGINT (PK)  | 위젯 ID                 |
| template_id   | BIGINT (FK)  | 소속 템플릿 ID             |
| fragment_name | VARCHAR(100) | HTML fragment 경로      |
| widget_title  | VARCHAR(100) | 위젯 제목                 |
| x_position    | INT          | GridStack X 좌표 (0-11) |
| y_position    | INT          | GridStack Y 좌표        |
| width         | INT          | 너비 (1-12)             |
| height        | INT          | 높이                    |
| is_visible    | BOOLEAN      | 표시 여부                 |
| sort_order    | INT          | 정렬 순서                 |
| zone_code     | VARCHAR(20)  | 호기 코드                 |

### dashboard_widget_layout (동적 레이아웃)

| 컬럼명                    | 타입                  | 설명                                      |
|------------------------|---------------------|-----------------------------------------|
| id                     | BIGINT (PK)         | 레이아웃 ID                                 |
| widget_id              | VARCHAR(100) UNIQUE | 위젯 식별자                                  |
| widget_type            | ENUM                | `CHART`, `LIST`, `STATUS`, `PIE`, `BAR` |
| widget_title           | VARCHAR(100)        | 위젯 제목                                   |
| x_position, y_position | INT                 | GridStack 좌표                            |
| width, height          | INT                 | 크기                                      |
| widget_config          | JSON                | 위젯 설정                                   |
| is_visible             | BOOLEAN             | 표시 여부                                   |

---

## 위젯 렌더링 흐름

```
1. 사용자 /dashboard 접속
        ↓
2. Session에서 selectedZoneCode 추출 (sp_03 또는 sp_04)
        ↓
3. DashboardTemplateService.getDefaultTemplateWidgets(zoneCode)
   → 해당 호기의 기본 템플릿 + 위젯 목록 조회 (isVisible=true)
        ↓
4. dashboard.html에서 th:each로 위젯 반복 렌더링
        ↓
5. 각 위젯: th:insert로 fragment 로드
   예: fragments/dashboard/power-chart.html
        ↓
6. Fragment 내 JavaScript가 AJAX로 데이터 요청
   예: GET /widget/power-generation-trend
        ↓
7. ECharts 또는 AG Grid로 시각화
```

---

## 프로그램 명세서

### DSH_001 - 대시보드 메인

| 항목 | 내용 |
|------|------|
| 프로그램 ID | DSH_001 |
| 프로그램명 | 대시보드 메인 |
| 클래스명 | DashboardController.java |
| 메서드명 | main() |
| 메서드 위치 | controller/DashboardController.java:30-38 |

#### 기능 설명

로그인 후 접근 가능한 대시보드 메인 페이지. 선택된 호기(Zone)의 기본 템플릿에 정의된 위젯들을 GridStack 레이아웃으로 렌더링합니다.

#### 처리 흐름도

```
[로그인 성공]
      ↓
[Zone 정보 세션 저장] (AuthInterceptor)
      ↓
[GET /dashboard]
      ↓
[Session에서 selectedZoneCode 추출]
      ↓
[DashboardTemplateService.getDefaultTemplateWidgets(zoneCode)]
      ↓
[dashboard.html 렌더링 + GridStack 초기화]
```

#### 입력 항목

| 항목명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| selectedZoneCode | String | O | 세션에 저장된 호기 코드 (sp_03 또는 sp_04) |

#### 출력 항목

| 항목명 | 타입 | 설명 |
|--------|------|------|
| widgets | List\<DashboardTemplateWidget\> | 표시할 위젯 목록 |
| error | String | 템플릿 없을 시 에러 메시지 |

#### 처리 로직

| 단계 | 처리 내용 |
|------|----------|
| 1 | HttpSession에서 `selectedZoneCode` 속성 추출 |
| 2 | zoneCode가 null이면 빈 위젯 목록 반환 |
| 3 | `DashboardTemplateService.getDefaultTemplateWidgets(zoneCode)` 호출 |
| 4 | 해당 호기의 `is_default=true` 템플릿 조회 |
| 5 | 템플릿의 `is_visible=true` 위젯들을 `sort_order` 순으로 조회 |
| 6 | 위젯 목록을 Model에 `widgets` 속성으로 추가 |
| 7 | `pages/dashboard` 뷰 반환 |
| 8 | 프론트엔드에서 GridStack 초기화 및 위젯 Fragment 로드 |

---

## 파일 경로

### 백엔드

| 파일                             | 경로                                            |
|--------------------------------|-----------------------------------------------|
| DashboardController            | `controller/DashboardController.java`         |
| DashboardTemplateController    | `controller/DashboardTemplateController.java` |
| WidgetController               | `controller/WidgetController.java`            |
| DashboardTemplate Entity       | `model/DashboardTemplate.java`                |
| DashboardTemplateWidget Entity | `model/DashboardTemplateWidget.java`          |
| DashboardWidgetLayout Entity   | `model/DashboardWidgetLayout.java`            |
| DashboardTemplateService       | `service/DashboardTemplateService.java`       |
| WidgetService                  | `service/WidgetService.java`                  |

### 프론트엔드

| 파일           | 경로                                     |
|--------------|----------------------------------------|
| 대시보드 페이지     | `templates/pages/dashboard.html`       |
| 위젯 Fragment들 | `templates/fragments/dashboard/*.html` |
| GridStack JS | `static/js/gridstack-all.js`           |
| 위젯 CSS       | `static/css/widget.css`                |

---

## 위젯 목록 (15개)

| Fragment Name                         | 위젯 제목           | 기본 크기 |
|---------------------------------------|-----------------|-------|
| `dashboard/sp_03/zone-status`         | 3호기 발전량         | 4×4   |
| `dashboard/sp_04/zone-status`         | 4호기 발전량         | 4×4   |
| `dashboard/facility_widget`           | 설비유형별 자산 현황     | 4×4   |
| `dashboard/manufacture_company`       | H/W 제조사별 자산     | 4×4   |
| `dashboard/asset_status_analysis`     | 자산 현행화 현황       | 4×4   |
| `dashboard/new_asset_detection_trend` | 신규 자산 탐지 추이     | 6×4   |
| `dashboard/asset-operation-status`    | 자산 운전상태 현황      | 4×4   |
| `dashboard/power-chart`               | 호기별 발전량 추이      | 6×4   |
| `dashboard/turbine-speed-trend`       | 호기별 터빈속도 추이     | 6×4   |
| `dashboard/power-fluctuation`         | 발전량 과다 변화량 탐지   | 6×4   |
| `dashboard/event-type-status`         | 이벤트 유형별 이상탐지    | 4×4   |
| `dashboard/whitelist-trend`           | 화이트리스트 위반 탐지 추이 | 6×4   |
| `dashboard/whitelist-policy-trend`    | 화이트리스트 등록 추이    | 6×4   |
| `dashboard/tag-collection-trend`      | 태그 수집 추이        | 6×4   |
| `dashboard/event-action-trend`        | 이상탐지 조치 추이      | 6×4   |

---

## API 엔드포인트

### 대시보드 API

| Method | Endpoint                  | 설명                |
|--------|---------------------------|-------------------|
| GET    | `/dashboard`              | 대시보드 페이지          |
| GET    | `/dashboard/widgetList`   | 표시 가능 위젯 목록       |
| POST   | `/dashboard/saveLayout`   | GridStack 레이아웃 저장 |
| POST   | `/dashboard/toggleWidget` | 위젯 표시/숨김          |

### 위젯 데이터 API (`/widget/*`)

| Endpoint                         | 설명         |
|----------------------------------|------------|
| `/widget/zone-status`            | 호기별 상태     |
| `/widget/power-generation-trend` | 발전량 추이     |
| `/widget/turbine-speed-trend`    | 터빈속도 추이    |
| `/widget/facility-asset`         | 설비유형별 자산   |
| `/widget/event-type-status`      | 이벤트 유형별 현황 |

---

## 새 위젯 추가 시

1. **Fragment 생성**: `templates/fragments/dashboard/새위젯.html`
2. **DB 등록**: `dashboard_template_widgets`에 INSERT
3. **API 추가** (필요시): `WidgetController`에 엔드포인트 추가
4. **Service 구현** (필요시): `WidgetService`에 데이터 조회 로직