# 대시보드 템플릿 관리 시스템 (Dashboard Template System)

## 개요

대시보드에 표시할 위젯의 레이아웃(위치, 크기)을 템플릿으로 관리하는 페이지. GridStack.js를 사용하여 드래그 앤 드롭으로 위젯 배치를 편집하고 저장.

## URL

| 경로 | 위치 | 용도 |
|------|------|------|
| `/setting/dashboard/templates` | DashboardTemplateController:31-38 | 템플릿 관리 페이지 |

## 아키텍처

```
[template.html]
        │
        ├──► [DashboardTemplateController] - 페이지 렌더링 / API
        │
        └──► [DashboardTemplateService]
                    │
                    ├──► [DashboardTemplateRepository]
                    └──► [DashboardTemplateWidgetRepository]
                    │
                    ▼
            [MariaDB]
              ├── dashboard_templates
              └── dashboard_template_widgets
```

## 핵심 모델

### DashboardTemplate (템플릿)
```
src/main/java/com/otoones/otomon/model/DashboardTemplate.java

@Entity
@Table(name = "dashboard_templates")
public class DashboardTemplate {
    Long id;                       // PK
    String templateName;           // 템플릿명 (unique, max 100)
    String description;            // 설명 (max 255)
    Boolean isDefault;             // 기본 템플릿 여부
    String zoneCode;               // 호기 코드 (sp_03, sp_04)
    LocalDateTime createdAt;       // 생성일
    LocalDateTime updatedAt;       // 수정일

    // 관계
    List<DashboardTemplateWidget> widgets;  // 위젯 목록 (orphanRemoval)
}
```

### DashboardTemplateWidget (템플릿 위젯)
```
src/main/java/com/otoones/otomon/model/DashboardTemplateWidget.java

@Entity
@Table(name = "dashboard_template_widgets")
public class DashboardTemplateWidget {
    Long id;                       // PK
    DashboardTemplate template;    // 소속 템플릿 (ManyToOne)
    String fragmentName;           // 프래그먼트 경로 (예: dashboard/sp_03/zone-status)
    String widgetTitle;            // 위젯 제목
    Integer xPosition;             // GridStack X 좌표 (0-11)
    Integer yPosition;             // GridStack Y 좌표
    Integer width;                 // GridStack 너비 (1-12)
    Integer height;                // GridStack 높이
    Boolean isVisible;             // 표시 여부
    Integer sortOrder;             // 정렬 순서
    String zoneCode;               // 호기 코드 (위젯별)
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
}
```

## API 엔드포인트

| Method | URL | 설명 |
|--------|-----|------|
| GET | `/setting/dashboard/templates` | 페이지 렌더링 |
| GET | `/setting/dashboard/api/templates` | 템플릿 목록 조회 |
| GET | `/setting/dashboard/api/templates/{id}` | 템플릿 상세 조회 |
| POST | `/setting/dashboard/api/templates` | 템플릿 생성 |
| PUT | `/setting/dashboard/api/templates/{id}` | 템플릿 수정 |
| DELETE | `/setting/dashboard/api/templates/{id}` | 템플릿 삭제 |
| POST | `/setting/dashboard/api/templates/{id}/widgets` | 위젯 레이아웃 저장 |
| GET | `/setting/dashboard/api/available-widgets` | 사용 가능한 위젯 목록 |

### POST /setting/dashboard/api/templates

**Request:**
```json
{
    "templateName": "3호기 기본 템플릿",
    "description": "3호기 대시보드용",
    "isDefault": true
}
```

**Response:**
```json
{
    "success": true,
    "message": "템플릿이 생성되었습니다.",
    "data": {
        "id": 1,
        "templateName": "3호기 기본 템플릿",
        "description": "3호기 대시보드용",
        "isDefault": true,
        "zoneCode": "sp_03",
        "createdAt": "2025-12-29T10:30:00",
        "widgets": []
    }
}
```

### POST /setting/dashboard/api/templates/{id}/widgets

**Request:**
```json
[
    {
        "fragmentName": "dashboard/sp_03/zone-status",
        "widgetTitle": "3호기 발전량",
        "xPosition": 0,
        "yPosition": 0,
        "width": 3,
        "height": 4,
        "isVisible": true,
        "sortOrder": 0,
        "zoneCode": "sp_03"
    },
    {
        "fragmentName": "dashboard/power-chart",
        "widgetTitle": "호기별 발전량 추이",
        "xPosition": 3,
        "yPosition": 0,
        "width": 6,
        "height": 4,
        "isVisible": true,
        "sortOrder": 1,
        "zoneCode": null
    }
]
```

### GET /setting/dashboard/api/available-widgets

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "fragmentName": "dashboard/sp_03/zone-status",
            "widgetTitle": "3호기 발전량",
            "widgetType": "fa-solid fa-bolt",
            "description": "3호기 운영 상태 표시",
            "defaultWidth": 3,
            "defaultHeight": 4,
            "zoneCode": "sp_03"
        }
    ]
}
```

## 사용 가능한 위젯 목록

| 위젯명 | fragmentName | 기본 크기 | 호기 |
|--------|--------------|----------|------|
| 3호기 발전량 | dashboard/sp_03/zone-status | 3x4 | sp_03 |
| 4호기 발전량 | dashboard/sp_04/zone-status | 3x4 | sp_04 |
| 설비유형별 자산 현황 | dashboard/facility_widget | 3x4 | 공통 |
| H/W 제조사별 자산 현황 | dashboard/manufacture_company | 3x4 | 공통 |
| 자산 현행화 현황 | dashboard/asset_status_analysis | 3x4 | 공통 |
| 신규 자산 탐지 추이 | dashboard/new_asset_detection_trend | 6x4 | 공통 |
| 자산 운전상태 현황 | dashboard/asset-operation-status | 3x4 | 공통 |
| 호기별 발전량 추이 | dashboard/power-chart | 6x4 | 공통 |
| 호기별 터빈속도 추이 | dashboard/turbine-speed-trend | 6x4 | 공통 |
| 발전량 과다 변화량 탐지 추이 | dashboard/power-fluctuation | 3x4 | 공통 |
| 이벤트 유형별 이상 탐지 현황 | dashboard/event-type-status | 3x4 | 공통 |
| 화이트리스트 위반 탐지 추이 | dashboard/whitelist-trend | 3x4 | 공통 |
| 화이트리스트 등록 추이 | dashboard/whitelist-policy-trend | 3x4 | 공통 |
| 태그 수집 추이 | dashboard/tag-collection-trend | 3x4 | 공통 |
| 이상탐지 조치 추이 | dashboard/event-action-trend | 3x4 | 공통 |
| 외부 IP 통신 자산 이벤트 추이 | dashboard/external-ip-communication-trend | 6x4 | 공통 |
| 사이버 위협 점검 필요도 | dashboard/cyber-threat-gauge | 4x3 | 공통 |

## JavaScript 함수 (template.html)

### GridStack 초기화
```javascript
function initGridStack() {
    grid = GridStack.init({
        column: 12,              // 12열 그리드
        cellHeight: 68,          // 셀 높이
        margin: 30,              // 위젯 간 여백
        acceptWidgets: true,     // 외부 위젯 드래그 허용
        removable: false,        // 삭제 버튼으로 삭제
        float: true,             // 자유 배치
        disableResize: false,
        animate: true
    });

    // 이벤트 리스너
    grid.on('added', updateSaveButton);
    grid.on('change', updateSaveButton);
    grid.on('removed', updateSaveButton);
}
```

### 템플릿 목록 로드
```javascript
function loadTemplates() {
    $.ajax({
        url: '/setting/dashboard/api/templates',
        success: function(response) {
            // select 옵션 생성
            // 기본 템플릿 자동 선택
        }
    });
}
```

### 위젯 드래그 설정
```javascript
function setupDraggableWidgets() {
    // 템플릿 선택 여부에 따라 드래그 활성화/비활성화
    $('.draggable-widget').each(function() {
        $(this).attr('draggable', hasTemplate);
        // dragstart, dragend 이벤트 리스너 설정
    });

    // 그리드에 drop 이벤트 설정
    gridElement.addEventListener('drop', handleDrop);
}
```

### 그리드에 위젯 추가
```javascript
function addWidgetToGrid(widgetData) {
    const widgetHtml = `
        <div class="panel panel-inverse"
             data-fragment="${widgetData.fragment}"
             data-title="${widgetData.title}"
             data-zone-code="${zoneCode || ''}">
            <div class="widget-header panel-heading">
                <h4 class="panel-title">${widgetData.title}</h4>
                <button class="widget-panel-remove">삭제</button>
            </div>
            <div class="widget-body panel-body">...</div>
        </div>
    `;

    const addedWidget = grid.addWidget({
        w: widgetData.width || 3,
        h: widgetData.height || 4
    });
    $(addedWidget).find('.grid-stack-item-content').html(widgetHtml);
}
```

### 레이아웃 저장
```javascript
$('#saveLayoutBtn').on('click', function() {
    const widgets = [];
    const gridItems = grid.getGridItems();

    gridItems.forEach(function(element, index) {
        const node = element.gridstackNode;
        widgets.push({
            fragmentName: ...,
            widgetTitle: ...,
            xPosition: node.x,
            yPosition: node.y,
            width: node.w,
            height: node.h,
            isVisible: true,
            sortOrder: index,
            zoneCode: ...
        });
    });

    $.ajax({
        url: `/setting/dashboard/api/templates/${currentTemplateId}/widgets`,
        method: 'POST',
        data: JSON.stringify(widgets)
    });
});
```

## 서비스 계층

### DashboardTemplateService

#### 템플릿 CRUD
```java
// 호기별 템플릿 목록 조회
public List<DashboardTemplateDto> getAllTimplates(String selectedZoneCode);

// 템플릿 상세 조회
public DashboardTemplateDto getTemplateById(Long id);

// 기본 템플릿 조회
public DashboardTemplateDto getDefaultTemplate(String selectedZoneCode);

// 템플릿 생성 (감사 로그)
@ActivityLog(category = "TEMPLATE_MANAGE", action = "CREATE", resourceType = "TEMPLATE")
public DashboardTemplateDto createTemplate(DashboardTemplateDto dto, String selectedZoneCode);

// 템플릿 수정 (감사 로그)
@ActivityLog(category = "TEMPLATE_MANAGE", action = "UPDATE", resourceType = "TEMPLATE")
public DashboardTemplateDto updateTemplate(Long id, DashboardTemplateDto dto, String selectedZoneCode);

// 템플릿 삭제 (감사 로그) - 기본 템플릿은 삭제 불가
@ActivityLog(category = "TEMPLATE_MANAGE", action = "DELETE", resourceType = "TEMPLATE")
public void deleteTemplate(Long id);
```

#### 위젯 관리
```java
// 위젯 레이아웃 저장 (기존 삭제 후 새로 저장)
public void saveTemplateWidgets(Long templateId, List<DashboardTemplateWidgetDto> widgetsDtos);

// 기본 템플릿의 위젯 목록 조회
public List<DashboardTemplateWidget> getDefaultTemplateWidgets(String selectedZoneCode);

// 사용 가능한 위젯 목록 (하드코딩)
public List<AvailableWidgetDto> getAvailableWidgets();

// 호기별 필터링된 위젯 목록
public List<AvailableWidgetDto> getAvailableWidgets(String selectedZoneCode);
```

## 비즈니스 로직

### 기본 템플릿 설정
```java
// 새 기본 템플릿 설정 시 기존 기본 템플릿 해제
private void resetDefaultTemplate(String zoneCode) {
    dashboardTemplateRepository.findByZoneCodeAndIsDefaultTrue(zoneCode)
            .ifPresent(template -> {
                template.setIsDefault(false);
                dashboardTemplateRepository.save(template);
            });
}
```

### 기본 템플릿 삭제 방지
```java
// 기본 템플릿은 삭제 불가
if (Boolean.TRUE.equals(template.getIsDefault())) {
    throw new IllegalArgumentException("기본 템플릿은 삭제할 수 없습니다.");
}
```

### 호기 코드 자동 추출
```javascript
// fragmentName에서 호기 코드 추출
function extractZoneCode(fragmentName) {
    const match = fragmentName.match(/\/(sp_\d{2})\//);
    return match ? match[1] : null;
}
```

## UI 구조

### 2컬럼 레이아웃
```
┌─────────────────────────────────────┬──────────────────┐
│      템플릿 편집 영역 (9컬럼)          │  위젯 목록 (3컬럼)  │
│  ┌────────────────────────────────┐ │ ┌──────────────┐ │
│  │ 템플릿 선택 + 기본 템플릿 체크박스 │ │ │ 위젯 추가     │ │
│  └────────────────────────────────┘ │ │ 드래그해서    │ │
│  ┌────────────────────────────────┐ │ │ 왼쪽으로 추가  │ │
│  │                                │ │ ├──────────────┤ │
│  │      GridStack 위젯 그리드       │ │ │ 3호기 발전량  │ │
│  │      (12x12 그리드, 16:9)       │ │ │ 4호기 발전량  │ │
│  │                                │ │ │ 설비유형별... │ │
│  └────────────────────────────────┘ │ │ ...          │ │
│                                     │ └──────────────┘ │
└─────────────────────────────────────┴──────────────────┘
```

### 버튼 기능
| 버튼 | ID | 기능 |
|------|----|------|
| 새 템플릿 | createTemplateBtn | 템플릿 생성 모달 표시 |
| 저장 | saveLayoutBtn | 위젯 레이아웃 저장 |
| 삭제 | deleteTemplateBtn | 템플릿 삭제 |

## GridStack 설정

```javascript
{
    column: 12,              // 12열 그리드
    cellHeight: 68,          // 셀 높이 (px)
    margin: 30,              // 위젯 간 여백 (px)
    acceptWidgets: true,     // 외부 위젯 드래그 허용
    removable: false,        // 삭제 버튼 방식
    float: true,             // 자유 배치 (빈 공간 허용)
    disableResize: false,    // 크기 조절 허용
    animate: true            // 애니메이션 효과
}
```

## 감사 로그

```java
@ActivityLog(category = "TEMPLATE_MANAGE", action = "CREATE", resourceType = "TEMPLATE")
@ActivityLog(category = "TEMPLATE_MANAGE", action = "UPDATE", resourceType = "TEMPLATE")
@ActivityLog(category = "TEMPLATE_MANAGE", action = "DELETE", resourceType = "TEMPLATE")
```

## Validation

### DashboardTemplateDto
```java
@NotBlank(message = "템플릿 이름은 필수입니다")
@Size(max = 100, message = "템플릿 이름은 100자 이하여야 합니다")
private String templateName;

@Size(max = 255, message = "설명은 255자 이하여야 합니다")
private String description;
```

### 위젯 좌표 검증
```java
// 저장 전 좌표 null 체크
if (dto.getXPosition() == null || dto.getYPosition() == null) {
    throw new IllegalArgumentException("위젯의 좌표 정보가 없습니다.");
}
```

## 다크모드 지원

```css
[data-bs-theme="dark"] .grid-stack {
    background: #1a1d20;
    border-color: #6c757d;
    background-image: linear-gradient(...);
}
```

## 관련 테이블

### dashboard_templates
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | BIGINT | PK |
| template_name | VARCHAR(100) | 템플릿명 (unique) |
| description | VARCHAR(255) | 설명 |
| is_default | TINYINT(1) | 기본 템플릿 여부 |
| zone_code | VARCHAR(20) | 호기 코드 |
| created_at | DATETIME | 생성일 |
| updated_at | DATETIME | 수정일 |

### dashboard_template_widgets
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | BIGINT | PK |
| template_id | BIGINT | FK → dashboard_templates |
| fragment_name | VARCHAR(100) | 프래그먼트 경로 |
| widget_title | VARCHAR(100) | 위젯 제목 |
| x_position | INT | GridStack X 좌표 |
| y_position | INT | GridStack Y 좌표 |
| width | INT | GridStack 너비 |
| height | INT | GridStack 높이 |
| is_visible | TINYINT(1) | 표시 여부 |
| sort_order | INT | 정렬 순서 |
| zone_code | VARCHAR(20) | 호기 코드 |
| created_at | DATETIME | 생성일 |
| updated_at | DATETIME | 수정일 |

## 연관 문서

- 대시보드 위젯: `docs/dashboard-widget-system.md`
- 프론트엔드 패턴: `docs/frontend-patterns.md`
- 감사로그 기록: `docs/audit-log-system.md`

---

## 프로그램 명세서

### TPL_001 - 대시보드 템플릿 관리 페이지

| 프로그램 ID | TPL_001 | 프로그램명 | 대시보드 템플릿 관리 페이지 |
|------------|---------|----------|----------------------|
| 분류 | 설정 | 처리유형 | 화면 |
| 클래스명 | DashboardTemplateController.java | 메서드명 | templates() |

▣ 기능 설명

대시보드 위젯의 레이아웃을 관리하는 페이지를 렌더링한다. GridStack.js를 사용하여 드래그 앤 드롭으로 위젯 배치 편집이 가능하다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 세션에서 호기 정보 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | HTML | 템플릿 관리 페이지 | String | Y | Thymeleaf 렌더링 HTML |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 selectedZoneCode 조회 | 호기 필터링용 |
| 2 | template.html 템플릿 렌더링 | GridStack 포함 |

---

### TPL_002 - 템플릿 목록 조회

| 프로그램 ID | TPL_002 | 프로그램명 | 템플릿 목록 조회 |
|------------|---------|----------|--------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | DashboardTemplateController.java | 메서드명 | getTemplates() |

▣ 기능 설명

현재 호기에 등록된 모든 대시보드 템플릿 목록을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 세션에서 호기 정보 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공여부 | Boolean | Y | true/false |
| 2 | data | 템플릿 목록 | List | Y | DashboardTemplateDto 배열 |
| 3 | data[].id | 템플릿 ID | Long | Y | PK |
| 4 | data[].templateName | 템플릿명 | String | Y | 템플릿 이름 |
| 5 | data[].description | 설명 | String | N | 템플릿 설명 |
| 6 | data[].isDefault | 기본 템플릿 여부 | Boolean | Y | true/false |
| 7 | data[].zoneCode | 호기 코드 | String | Y | sp_03, sp_04 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 selectedZoneCode 조회 | |
| 2 | 해당 호기의 템플릿 목록 조회 | DashboardTemplateRepository |
| 3 | DTO 변환 후 반환 | |

---

### TPL_003 - 템플릿 상세 조회

| 프로그램 ID | TPL_003 | 프로그램명 | 템플릿 상세 조회 |
|------------|---------|----------|--------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | DashboardTemplateController.java | 메서드명 | getTemplate() |

▣ 기능 설명

특정 템플릿의 상세 정보와 위젯 목록을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 템플릿 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공여부 | Boolean | Y | true/false |
| 2 | data | 템플릿 정보 | Object | Y | DashboardTemplateDto |
| 3 | data.widgets | 위젯 목록 | List | Y | 템플릿에 포함된 위젯 배열 |
| 4 | data.widgets[].fragmentName | 프래그먼트명 | String | Y | 위젯 경로 |
| 5 | data.widgets[].xPosition | X좌표 | Integer | Y | GridStack X 위치 |
| 6 | data.widgets[].yPosition | Y좌표 | Integer | Y | GridStack Y 위치 |
| 7 | data.widgets[].width | 너비 | Integer | Y | GridStack 너비 |
| 8 | data.widgets[].height | 높이 | Integer | Y | GridStack 높이 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 템플릿 ID로 조회 | DashboardTemplateRepository |
| 2 | 존재하지 않으면 예외 발생 | EntityNotFoundException |
| 3 | 위젯 목록 포함하여 DTO 반환 | |

---

### TPL_004 - 템플릿 생성

| 프로그램 ID | TPL_004 | 프로그램명 | 템플릿 생성 |
|------------|---------|----------|----------|
| 분류 | 설정 | 처리유형 | 등록 |
| 클래스명 | DashboardTemplateController.java | 메서드명 | createTemplate() |

▣ 기능 설명

새로운 대시보드 템플릿을 생성한다. 기본 템플릿으로 설정 시 기존 기본 템플릿은 해제된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | templateName | 템플릿명 | String | Y | 최대 100자, unique |
| 2 | description | 설명 | String | N | 최대 255자 |
| 3 | isDefault | 기본 템플릿 여부 | Boolean | N | 기본값 false |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공여부 | Boolean | Y | true/false |
| 2 | message | 메시지 | String | Y | 결과 메시지 |
| 3 | data | 생성된 템플릿 | Object | Y | DashboardTemplateDto |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 입력값 유효성 검증 | @Valid |
| 2 | 기본 템플릿 설정 시 기존 기본 템플릿 해제 | resetDefaultTemplate() |
| 3 | 세션의 호기 코드 설정 | zoneCode |
| 4 | 템플릿 저장 | DashboardTemplateRepository |
| 5 | 감사 로그 기록 | @ActivityLog |

---

### TPL_005 - 템플릿 수정

| 프로그램 ID | TPL_005 | 프로그램명 | 템플릿 수정 |
|------------|---------|----------|----------|
| 분류 | 설정 | 처리유형 | 수정 |
| 클래스명 | DashboardTemplateController.java | 메서드명 | updateTemplate() |

▣ 기능 설명

기존 템플릿의 정보(이름, 설명, 기본 템플릿 여부)를 수정한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 템플릿 ID | Long | Y | PathVariable |
| 2 | templateName | 템플릿명 | String | Y | 최대 100자 |
| 3 | description | 설명 | String | N | 최대 255자 |
| 4 | isDefault | 기본 템플릿 여부 | Boolean | N | |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공여부 | Boolean | Y | true/false |
| 2 | message | 메시지 | String | Y | 결과 메시지 |
| 3 | data | 수정된 템플릿 | Object | Y | DashboardTemplateDto |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 템플릿 존재 여부 확인 | |
| 2 | 입력값 유효성 검증 | @Valid |
| 3 | 기본 템플릿 설정 변경 시 기존 기본 템플릿 해제 | |
| 4 | 템플릿 정보 업데이트 | |
| 5 | 감사 로그 기록 | @ActivityLog |

---

### TPL_006 - 템플릿 삭제

| 프로그램 ID | TPL_006 | 프로그램명 | 템플릿 삭제 |
|------------|---------|----------|----------|
| 분류 | 설정 | 처리유형 | 삭제 |
| 클래스명 | DashboardTemplateController.java | 메서드명 | deleteTemplate() |

▣ 기능 설명

템플릿과 관련 위젯 정보를 삭제한다. 기본 템플릿은 삭제할 수 없다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 템플릿 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공여부 | Boolean | Y | true/false |
| 2 | message | 메시지 | String | Y | 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 템플릿 존재 여부 확인 | |
| 2 | 기본 템플릿 여부 확인 | 기본 템플릿이면 삭제 불가 |
| 3 | 관련 위젯 삭제 | orphanRemoval=true |
| 4 | 템플릿 삭제 | |
| 5 | 감사 로그 기록 | @ActivityLog |

---

### TPL_007 - 위젯 레이아웃 저장

| 프로그램 ID | TPL_007 | 프로그램명 | 위젯 레이아웃 저장 |
|------------|---------|----------|----------------|
| 분류 | 설정 | 처리유형 | 등록/수정 |
| 클래스명 | DashboardTemplateController.java | 메서드명 | saveTemplateWidgets() |

▣ 기능 설명

템플릿에 포함될 위젯의 레이아웃(위치, 크기, 순서)을 저장한다. 기존 위젯을 삭제하고 새로 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 템플릿 ID | Long | Y | PathVariable |
| 2 | widgets | 위젯 목록 | List | Y | RequestBody 배열 |
| 3 | widgets[].fragmentName | 프래그먼트명 | String | Y | 위젯 경로 |
| 4 | widgets[].widgetTitle | 위젯 제목 | String | Y | 표시 제목 |
| 5 | widgets[].xPosition | X좌표 | Integer | Y | 0-11 |
| 6 | widgets[].yPosition | Y좌표 | Integer | Y | |
| 7 | widgets[].width | 너비 | Integer | Y | 1-12 |
| 8 | widgets[].height | 높이 | Integer | Y | |
| 9 | widgets[].isVisible | 표시여부 | Boolean | N | 기본값 true |
| 10 | widgets[].sortOrder | 정렬순서 | Integer | N | |
| 11 | widgets[].zoneCode | 호기 코드 | String | N | sp_03, sp_04 또는 null |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공여부 | Boolean | Y | true/false |
| 2 | message | 메시지 | String | Y | 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 템플릿 존재 여부 확인 | |
| 2 | 위젯 좌표 유효성 검증 | null 체크 |
| 3 | 기존 위젯 전체 삭제 | DashboardTemplateWidgetRepository |
| 4 | 새 위젯 목록 저장 | |

---

### TPL_008 - 사용 가능한 위젯 목록 조회

| 프로그램 ID | TPL_008 | 프로그램명 | 사용 가능한 위젯 목록 조회 |
|------------|---------|----------|----------------------|
| 분류 | 설정 | 처리유형 | 조회 |
| 클래스명 | DashboardTemplateController.java | 메서드명 | getAvailableWidgets() |

▣ 기능 설명

대시보드에 추가할 수 있는 모든 위젯 목록을 조회한다. 호기별로 필터링된 결과를 반환한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 세션에서 호기 정보 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공여부 | Boolean | Y | true/false |
| 2 | data | 위젯 목록 | List | Y | AvailableWidgetDto 배열 |
| 3 | data[].fragmentName | 프래그먼트명 | String | Y | 위젯 경로 |
| 4 | data[].widgetTitle | 위젯 제목 | String | Y | 표시 제목 |
| 5 | data[].widgetType | 위젯 아이콘 | String | Y | FontAwesome 클래스 |
| 6 | data[].description | 설명 | String | N | 위젯 설명 |
| 7 | data[].defaultWidth | 기본 너비 | Integer | Y | GridStack 너비 |
| 8 | data[].defaultHeight | 기본 높이 | Integer | Y | GridStack 높이 |
| 9 | data[].zoneCode | 호기 코드 | String | N | sp_03, sp_04 또는 null(공통) |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 selectedZoneCode 조회 | |
| 2 | 하드코딩된 위젯 목록 조회 | getAvailableWidgets() |
| 3 | 호기 코드로 필터링 | 공통 위젯 + 해당 호기 위젯 |
| 4 | 위젯 목록 반환 | |
