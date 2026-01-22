# CSP 인라인 코드 제거 - 2차 작업 계획

> **분석일**: 2026-01-14
> **1차 완료**: 16/16 CSS 추출 + 8건 JS 이벤트 수정
> **2차 남은 작업**: 35건 (15개 파일)

---

## 요약

| 유형 | 건수 | 파일수 |
|------|------|--------|
| `<style>` 태그 | 4 | 4 |
| `onclick=` | 17 | 8 |
| `onchange=` | 1 | 1 |
| `href="javascript:"` | 12 | 10 |
| HTML 오류 | 1 | 1 |
| **총계** | **35건** | **15개 파일** |

---

## Phase H: href="javascript:" 수정 (12건)

### H-1. layouts/default.html (Line 380)

**경로**: `src/main/resources/templates/layouts/default.html`

```html
<!-- Before -->
<a class="btn btn-icon btn-circle btn-success btn-scroll-to-top"
   data-toggle="scroll-to-top"
   href="javascript:"><i class="fa fa-angle-up"></i></a>

<!-- After -->
<a class="btn btn-icon btn-circle btn-success btn-scroll-to-top"
   data-toggle="scroll-to-top"
   href="#"><i class="fa fa-angle-up"></i></a>
```

### H-2. pages/data/node.html (Line 19)

**경로**: `src/main/resources/templates/pages/data/node.html`

```html
<!-- Before -->
<li class="breadcrumb-item"><a href="javascript:">Home</a></li>

<!-- After -->
<li class="breadcrumb-item"><a href="#">Home</a></li>
```

### H-3. pages/asset/operation.html (Line 23)

**경로**: `src/main/resources/templates/pages/asset/operation.html`

```html
<!-- Before -->
<li class="breadcrumb-item"><a href="javascript:">Home</a></li>

<!-- After -->
<li class="breadcrumb-item"><a href="#">Home</a></li>
```

### H-4. pages/detection/timeSereiseData.html (Line 28)

**경로**: `src/main/resources/templates/pages/detection/timeSereiseData.html`

```html
<!-- Before -->
<li class="breadcrumb-item"><a href="javascript:">Home</a></li>

<!-- After -->
<li class="breadcrumb-item"><a href="#">Home</a></li>
```

### H-5. pages/setting/audit.html (Line 13)

**경로**: `src/main/resources/templates/pages/setting/audit.html`

```html
<!-- Before -->
<li class="breadcrumb-item"><a href="javascript:">Home</a></li>

<!-- After -->
<li class="breadcrumb-item"><a href="#">Home</a></li>
```

### H-6. pages/setting/code.html (Line 15)

**경로**: `src/main/resources/templates/pages/setting/code.html`

```html
<!-- Before -->
<li class="breadcrumb-item"><a href="javascript:">Home</a></li>

<!-- After -->
<li class="breadcrumb-item"><a href="#">Home</a></li>
```

### H-7. pages/setting/groupList.html (Line 23)

**경로**: `src/main/resources/templates/pages/setting/groupList.html`

```html
<!-- Before -->
<li class="breadcrumb-item"><a href="javascript:">Home</a></li>

<!-- After -->
<li class="breadcrumb-item"><a href="#">Home</a></li>
```

### H-8. pages/setting/systemConfig.html (Line 9)

**경로**: `src/main/resources/templates/pages/setting/systemConfig.html`

```html
<!-- Before -->
<li class="breadcrumb-item"><a href="javascript:">Home</a></li>

<!-- After -->
<li class="breadcrumb-item"><a href="#">Home</a></li>
```

### H-9. pages/setting/topology-switch.html (Line 15)

**경로**: `src/main/resources/templates/pages/setting/topology-switch.html`

```html
<!-- Before -->
<li class="breadcrumb-item"><a href="javascript:">Home</a></li>

<!-- After -->
<li class="breadcrumb-item"><a href="#">Home</a></li>
```

### H-10. pages/setting/userList.html (Lines 17, 170, 173)

**경로**: `src/main/resources/templates/pages/setting/userList.html`

```html
<!-- Line 17 Before -->
<li class="breadcrumb-item"><a href="javascript:">Home</a></li>

<!-- Line 17 After -->
<li class="breadcrumb-item"><a href="#">Home</a></li>

<!-- Line 170 Before -->
<a class="btn btn-white"
   data-bs-dismiss="modal"
   href="javascript:"

<!-- Line 170 After -->
<a class="btn btn-white"
   data-bs-dismiss="modal"
   href="#"

<!-- Line 173 Before -->
<a class="btn btn-success"
   href="javascript:"
   id="btnReg"></a>

<!-- Line 173 After -->
<a class="btn btn-success"
   href="#"
   id="btnReg"></a>
```

---

## Phase E: 인라인 style 태그 제거 (4개)

### E-1. topology-physical-detail-fragment.html

**HTML 경로**: `src/main/resources/templates/pages/asset/topology-physical-detail-fragment.html`
**CSS 경로**: `src/main/resources/static/css/pages/asset/topologyPhysicalDetailFragment.css`

#### HTML 수정 (Lines 11-13 추가, Lines 14-230 삭제)

```html
<!-- Before (Line 11-12) -->
<link rel="stylesheet"
      th:href="@{/css/all.min.css}">

<style>
    /* 216줄 CSS */
</style>

<!-- After -->
<link rel="stylesheet"
      th:href="@{/css/all.min.css}">
<link rel="stylesheet"
      th:href="@{/css/pages/asset/topologyPhysicalDetailFragment.css}">
```

#### CSS 파일 생성

```css
/**
 * topologyPhysicalDetailFragment.css
 * 물리 토폴로지 상세 Fragment 스타일
 */

.topology-container {
    flex: 1;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    overflow: hidden;
    height: 78vh;
}

.switch-rect {
    fill: #e9ecef;
    stroke: #6c757d;
    stroke-width: 2;
}

.port-rect {
    stroke: #333;
    stroke-width: 1;
}

.port-active {
    fill: #28a745;
}

.port-inactive {
    fill: #fff900;
}

.port-error {
    fill: #6c757d;
}

.port-warning {
    fill: #dc3545;
}

.port-caution {
    fill: #ff9800;
}

.port-empty {
    fill: white;
    stroke: #6c757d;
    stroke-width: 1;
}

.device-circle {
    fill: #ffffff;
    stroke: #6c757d;
    stroke-width: 2;
}

.device-icon {
    font-size: 16px;
    text-anchor: middle;
    dominant-baseline: central;
}

.device-text {
    font-size: 12px;
    text-anchor: middle;
    fill: #333;
}

.device-circle.error {
    fill: #ffffff;
    stroke: #6b747c;
    stroke-width: 3;
}

.device-circle.warning {
    fill: #ffffff;
    stroke: #dc3545;
    stroke-width: 3;
}

.device-circle.caution {
    fill: #ffffff;
    stroke: #f57c00;
    stroke-width: 3;
}

.device-circle.inactive {
    fill: #ffffff;
    stroke: #fff900;
    stroke-width: 3;
}

.device-circle.active {
    fill: #ffffff;
    stroke: #218838;
    stroke-width: 3;
}

.connection-line.warning {
    stroke: #dc3545;
}

.connection-line.caution {
    stroke: #ff9800;
}

.connection-line.active {
    stroke: #28a745;
}

.connection-line {
    fill: none;
    stroke: #6c757d;
}

.connection-line.error {
    stroke: #6c757d;
}

.connection-line.inactive {
    stroke: #fff900;
}

.switch-label {
    font-size: 14px;
    font-weight: bold;
    text-anchor: middle;
    fill: #333;
}

.traffic-text {
    font-size: 10px;
    text-anchor: middle;
    fill: #007bff;
    font-weight: bold;
}

.zoom-container {
    cursor: grab;
}

.zoom-container:active {
    cursor: grabbing;
}

.buttons-container {
    text-align: left;
    margin-bottom: 10px;
    padding: 0 20px;
    width: 100%;
    box-sizing: border-box;
    display: block;
    position: relative;
    z-index: 10;
}

.buttons-container select {
    padding: 6px 12px;
    border: 1px solid #ced4da;
    border-radius: 4px;
    background-color: #fff;
    cursor: pointer;
    min-width: 150px;
}

/* 다크 모드 */
.topology-container.dark-mode .switch-label,
.topology-container.dark-mode .device-text {
    fill: #ffffff !important;
}

.topology-container.dark-mode .device-text {
    fill: #e0e0e0 !important;
}

/* 자산 상세보기 너비 조절 */
#assetDetailSidebar {
    width: 90% !important;
    max-width: 1400px;
    min-width: 350px;
}

/* 자산 카드 헤더 스타일 */
.asset-card-header {
    background: #cccccc;
    color: rgba(33, 33, 33, 0.8);
    font-size: 0.95rem;
    padding: 0.75rem 1rem;
    border: none;
}

/* 관련 이벤트 Accordion 다크모드 스타일 */
#related_events .accordion,
[data-bs-theme="dark"] #related_events .accordion {
    --bs-accordion-color: #dee2e6 !important;
    --bs-accordion-bg: #212529 !important;
    --bs-accordion-border-color: #495057 !important;
    --bs-accordion-btn-color: #dee2e6 !important;
    --bs-accordion-btn-bg: #212529 !important;
    --bs-accordion-active-color: #ffffff !important;
    --bs-accordion-active-bg: #2c3034 !important;
}

#related_events .accordion-body {
    background-color: #2d353c;
    color: #dee2e6;
}

#related_events .accordion-item {
    background-color: #212529;
    border-color: #495057;
}

#related_events .text-muted {
    color: #adb5bd !important;
}

#related_events .badge {
    background-color: #495057 !important;
}
```

### E-2. node.html

**HTML 경로**: `src/main/resources/templates/pages/data/node.html`
**CSS 경로**: `src/main/resources/static/css/pages/data/node.css`

#### HTML 수정 (Lines 5-14)

```html
<!-- Before -->
<th:block layout:fragment="style">
    <link rel="stylesheet"
          th:src="@{/css/ag-theme-quartz.css}">
    <style>
        #nodeGrid {
            height: 600px;
            width: 100%;
        }
    </style>
</th:block>

<!-- After -->
<th:block layout:fragment="style">
    <link rel="stylesheet"
          th:href="@{/css/ag-theme-quartz.css}">
    <link rel="stylesheet"
          th:href="@{/css/pages/data/node.css}">
</th:block>
```

> **주의**: `th:src` → `th:href` 버그 수정 포함

#### CSS 파일 생성

```css
/**
 * node.css
 * 노드 페이지 전용 스타일
 */

#nodeGrid {
    height: 600px;
    width: 100%;
}
```

### E-3 & E-4. showAssetEventList.html & showNetworkEventList.html (공통 CSS)

**HTML 경로 1**: `src/main/resources/templates/fragments/dashboard/showAssetEventList.html`
**HTML 경로 2**: `src/main/resources/templates/fragments/dashboard/showNetworkEventList.html`
**CSS 경로**: `src/main/resources/static/css/components/_dashboard-event-list.css`

#### showAssetEventList.html 수정 (Lines 2-17 삭제)

```html
<!-- Before -->
<th:block th:fragment="assetEventList">
    <style>
        .list-title{...}
        ...
    </style>
    <div class="list-title">

<!-- After -->
<th:block th:fragment="assetEventList">
    <div class="list-title">
```

#### showNetworkEventList.html 수정 (Lines 2-15 삭제)

```html
<!-- Before -->
<th:block th:fragment="networkEventList">
    <style>
        .list-title{...}
        ...
    </style>
    <div class="list-title">

<!-- After -->
<th:block th:fragment="networkEventList">
    <div class="list-title">
```

#### CSS 파일 생성

```css
/**
 * _dashboard-event-list.css
 * 대시보드 이벤트 리스트 공통 스타일
 */

.list-title {
    display: flex;
    align-items: center;
    margin-bottom: 5px;
}

.list-title p {
    margin: 0;
    font-weight: 600;
    font-size: 16px;
}

.list-group-item {
    padding: 6px 10px;
    font-size: 12px;
}

.empty-text {
    margin: 0;
    font-size: 14px;
}
```

#### main.css에 import 추가

**경로**: `src/main/resources/static/css/main.css`

```css
/* 기존 import 아래에 추가 */
@import url('./components/_dashboard-event-list.css');
```

---

## Phase F: 인라인 onclick 제거 (17건)

### F-1. external-ip-communication-trend.html (2건)

**HTML 경로**: `src/main/resources/templates/fragments/dashboard/external-ip-communication-trend.html`

#### HTML 수정 (Lines 12-15)

```html
<!-- Before -->
<button class="btn btn-outline-light active" id="btn10m"
        onclick="loadExternalIpTrend('10m')" type="button">10m</button>
<button class="btn btn-outline-light" id="btn1h"
        onclick="loadExternalIpTrend('1h')" type="button">1h</button>

<!-- After -->
<button class="btn btn-outline-light active" id="btn10m"
        type="button">10m</button>
<button class="btn btn-outline-light" id="btn1h"
        type="button">1h</button>
```

#### JS 수정 (대시보드 JS 또는 위젯 로드 시)

```javascript
// DOMContentLoaded 또는 위젯 초기화 시
document.getElementById('btn10m')?.addEventListener('click', () => loadExternalIpTrend('10m'));
document.getElementById('btn1h')?.addEventListener('click', () => loadExternalIpTrend('1h'));
```

### F-2. timeSereiseData.html (3건)

**HTML 경로**: `src/main/resources/templates/pages/detection/timeSereiseData.html`

#### HTML 수정 (Lines 58-61, 142-145, 228-231)

```html
<!-- Line 58-61 Before -->
<button class="btn btn-success btn-sm me-3"
        onclick="downloadExcel('sp_03')"
        type="button">

<!-- After -->
<button class="btn btn-success btn-sm me-3"
        id="btnDownloadExcel3"
        type="button">

<!-- Line 142-145 Before -->
<button class="btn btn-info btn-sm me-3"
        onclick="downloadExcel('sp_04')"
        type="button">

<!-- After -->
<button class="btn btn-info btn-sm me-3"
        id="btnDownloadExcel4"
        type="button">

<!-- Line 228-231 Before -->
<button class="btn btn-success btn-sm me-3"
        onclick="downloadExcel()"
        type="button">

<!-- After -->
<button class="btn btn-success btn-sm me-3"
        id="btnDownloadExcel"
        type="button">
```

#### JS 수정

**경로**: `src/main/resources/static/js/page.detection/timesSereiseData.js`

```javascript
// 파일 끝 또는 DOMContentLoaded 내에 추가
document.getElementById('btnDownloadExcel3')?.addEventListener('click', () => downloadExcel('sp_03'));
document.getElementById('btnDownloadExcel4')?.addEventListener('click', () => downloadExcel('sp_04'));
document.getElementById('btnDownloadExcel')?.addEventListener('click', () => downloadExcel());
```

### F-3. assetEditFragment.html (6건)

**HTML 경로**: `src/main/resources/templates/fragments/operation/assetEditFragment.html`

#### HTML 수정

```html
<!-- Lines 242-246 Before -->
<button class="btn btn-outline-danger"
        onclick="removeInput(this)"
        type="button">
    <i class="fa fa-trash"></i>
</button>

<!-- After (모든 removeInput 버튼에 클래스 추가) -->
<button class="btn btn-outline-danger btn-remove-input"
        type="button">
    <i class="fa fa-trash"></i>
</button>

<!-- Line 264-269 Before -->
<button class="btn btn-outline-primary btn-sm"
        onclick="addIpInput()"
        type="button">

<!-- After -->
<button class="btn btn-outline-primary btn-sm"
        id="btnAddIp"
        type="button">

<!-- Line 311-316 Before -->
<button class="btn btn-outline-primary btn-sm"
        onclick="addMacInput()"
        type="button">

<!-- After -->
<button class="btn btn-outline-primary btn-sm"
        id="btnAddMac"
        type="button">
```

#### JS 수정 (이벤트 위임)

**경로**: `src/main/resources/static/js/page/asset/operation.js` 또는 해당 페이지 JS

```javascript
// 이벤트 위임으로 동적 요소 처리
document.addEventListener('click', function(e) {
    if (e.target.closest('.btn-remove-input')) {
        removeInput(e.target.closest('.btn-remove-input'));
    }
});

document.getElementById('btnAddIp')?.addEventListener('click', addIpInput);
document.getElementById('btnAddMac')?.addEventListener('click', addMacInput);
```

### F-4. actionTab.html (1건)

**HTML 경로**: `src/main/resources/templates/fragments/detection/tabs/actionTab.html`

#### HTML 수정 (Line 25)

```html
<!-- Before -->
<button class="btn btn-primary" onclick="saveAction()" th:if="${userPermissions['canWrite'] or userPermissions['canDelete']}" type="button">저장</button>

<!-- After -->
<button class="btn btn-primary" id="btnSaveAction" th:if="${userPermissions['canWrite'] or userPermissions['canDelete']}" type="button">저장</button>
```

#### JS 수정 (connection.js, timesData.js, timesSereiseData.js)

```javascript
// 이 fragment를 사용하는 모든 JS 파일에 추가
document.getElementById('btnSaveAction')?.addEventListener('click', saveAction);
```

### F-5. analysisTab.html (1건)

**HTML 경로**: `src/main/resources/templates/fragments/detection/tabs/analysisTab.html`

#### HTML 수정 (Line 14)

```html
<!-- Before -->
<button class="btn btn-primary" onclick="saveAnalysisHistory()" type="button" th:if="${userPermissions['canWrite']}">저장</button>

<!-- After -->
<button class="btn btn-primary" id="btnSaveAnalysis" type="button" th:if="${userPermissions['canWrite']}">저장</button>
```

#### JS 수정

```javascript
// 이 fragment를 사용하는 모든 JS 파일에 추가
document.getElementById('btnSaveAnalysis')?.addEventListener('click', saveAnalysisHistory);
```

### F-6. relatedEventsTab.html (1건)

**HTML 경로**: `src/main/resources/templates/fragments/detection/tabs/relatedEventsTab.html`

#### HTML 수정 (Line 63-72)

```html
<!-- Before -->
<button class="btn btn-outline-secondary btn-sm"
        onclick="loadMoreRelatedEvents(this)"
        th:data-current-event-id="${currentEventId}"
        ...

<!-- After -->
<button class="btn btn-outline-secondary btn-sm btn-load-more-events"
        th:data-current-event-id="${currentEventId}"
        ...
```

#### JS 수정 (이벤트 위임)

```javascript
// 이 fragment를 사용하는 모든 JS 파일에 추가
document.addEventListener('click', function(e) {
    if (e.target.closest('.btn-load-more-events')) {
        loadMoreRelatedEvents(e.target.closest('.btn-load-more-events'));
    }
});
```

### F-7. groupList.html (2건)

**HTML 경로**: `src/main/resources/templates/pages/setting/groupList.html`

#### HTML 수정 (Lines 41-46, 123-126)

```html
<!-- Line 41-46 Before -->
<button class="btn btn-sm btn-primary"
        onclick="showGroupAddModal()"
        th:if="${canWrite}">

<!-- After -->
<button class="btn btn-sm btn-primary"
        id="btnShowGroupAddModal"
        th:if="${canWrite}">

<!-- Line 123-126 Before -->
<button class="btn btn-success"
        onclick="saveNewGroup()"
        th:text="${@messageSource.getMessage('button.add',null,'등록',#locale)}"
        type="button"></button>

<!-- After -->
<button class="btn btn-success"
        id="btnSaveNewGroup"
        th:text="${@messageSource.getMessage('button.add',null,'등록',#locale)}"
        type="button"></button>
```

#### JS 수정

**경로**: `src/main/resources/static/js/page.setting/groupList.js`

```javascript
// 파일 끝 또는 DOMContentLoaded 내에 추가
document.getElementById('btnShowGroupAddModal')?.addEventListener('click', showGroupAddModal);
document.getElementById('btnSaveNewGroup')?.addEventListener('click', saveNewGroup);
```

### F-8. systemConfig.html (1건)

**HTML 경로**: `src/main/resources/templates/pages/setting/systemConfig.html`

#### HTML 수정 (Lines 21-25)

```html
<!-- Before -->
<button class="btn btn-xs btn-primary"
        onclick="saveSystemConfig()"
        th:if="${userPermissions?.canWrite}"
        type="button">

<!-- After -->
<button class="btn btn-xs btn-primary"
        id="btnSaveSystemConfig"
        th:if="${userPermissions?.canWrite}"
        type="button">
```

#### JS 수정

**경로**: `src/main/resources/static/js/page.setting/systemConfig.js`

```javascript
// 파일 끝 또는 DOMContentLoaded 내에 추가
document.getElementById('btnSaveSystemConfig')?.addEventListener('click', saveSystemConfig);
```

---

## Phase G: 인라인 onchange 제거 (1건)

### G-1. userList.html

**HTML 경로**: `src/main/resources/templates/pages/setting/userList.html`

#### HTML 수정 (Lines 130-135)

```html
<!-- Before -->
<input class="form-check-input"
       id="status"
       name="status"
       onchange="toggleStatusLabel()"
       type="checkbox"
       value="1" />

<!-- After -->
<input class="form-check-input"
       id="status"
       name="status"
       type="checkbox"
       value="1" />
```

#### JS 수정

**경로**: `src/main/resources/static/js/page.setting/userList.js`

```javascript
// 파일 끝 또는 DOMContentLoaded 내에 추가
document.getElementById('status')?.addEventListener('change', toggleStatusLabel);
```

---

## 작업 순서

1. **Phase H**: `href="javascript:"` → `href="#"` (12건, 간단)
2. **Phase E**: `<style>` 태그 외부 추출 (4개 파일)
3. **Phase F**: `onclick=` 제거 (17건, 8개 파일)
4. **Phase G**: `onchange=` 제거 (1건)

---

## 검증 방법

1. 브라우저 콘솔에서 CSP 오류 없음 확인
2. 각 페이지 기능 테스트 (버튼 클릭, 폼 제출)
3. 다크모드 전환 테스트 (토폴로지 페이지)
4. 대시보드 위젯 동작 확인

---

## 체크리스트

### Phase H (12건)
- [ ] layouts/default.html (Line 380)
- [ ] pages/data/node.html (Line 19)
- [ ] pages/asset/operation.html (Line 23)
- [ ] pages/detection/timeSereiseData.html (Line 28)
- [ ] pages/setting/audit.html (Line 13)
- [ ] pages/setting/code.html (Line 15)
- [ ] pages/setting/groupList.html (Line 23)
- [ ] pages/setting/systemConfig.html (Line 9)
- [ ] pages/setting/topology-switch.html (Line 15)
- [ ] pages/setting/userList.html (Lines 17, 170, 173)

### Phase E (4개 파일)
- [ ] topology-physical-detail-fragment.html + CSS 생성
- [ ] node.html + CSS 생성 + th:src 버그 수정
- [ ] showAssetEventList.html + 공통 CSS
- [ ] showNetworkEventList.html + main.css import

### Phase F (17건)
- [ ] external-ip-communication-trend.html (2건) + JS
- [ ] timeSereiseData.html (3건) + JS
- [ ] assetEditFragment.html (6건) + JS
- [ ] actionTab.html (1건) + JS
- [ ] analysisTab.html (1건) + JS
- [ ] relatedEventsTab.html (1건) + JS
- [ ] groupList.html (2건) + JS
- [ ] systemConfig.html (1건) + JS

### Phase G (1건)
- [ ] userList.html + JS
