# CSS 외부 추출 및 CSP 준수 - 2차 작업 계획

> **분석일**: 2026-01-14
> **1차 완료**: 16/16 CSS 추출 + 8건 JS 이벤트 수정
> **2차 남은 작업**: 35건 (15개 파일)

---

## 1차 작업 완료 현황 ✓

### 완료된 CSS 추출 (16개)
- [x] reportList.html → `pages/analysis/reportList.css`
- [x] systemResource.html → `pages/data/systemResource.css`
- [x] reportAdd.html → `pages/analysis/reportAdd.css`
- [x] connection.html → `pages/detection/connection.css`
- [x] template.html → `pages/setting/template.css`
- [x] auditList.html → `pages/setting/auditList.css`
- [x] collectionOpTag.html → `pages/setting/collectionOpTag.css`
- [x] sessionWhite.html → `pages/policy/sessionWhite.css`
- [x] alarmList.html → `pages/setting/alarmList.css`
- [x] analysisAndAction.html → `pages/detection/analysisAndAction.css`
- [x] operation.html (data) → `pages/data/operation.css`
- [x] servicePortPolicy.html → `pages/policy/servicePortPolicy.css`
- [x] session.html → `pages/data/session.css`
- [x] cyber-threat-gauge.html → `components/_cyber-threat-gauge.css`
- [x] menu.html → `pages/setting/menu.css`
- [x] timeSeries.html → `pages/policy/timeSeries.css`

### 완료된 JS 이벤트 수정
- [x] sessionWhite.html (7건 onclick → id 기반)
- [x] analysisAndAction.html (1건)
- [x] alarm.html (이미 클래스 기반)
- [x] changePassword.html (1건)
- [x] eventDetailOffcanvas.html fragment (1건)

---

## 2차 작업: 남은 항목 분석 결과

### 총계

| 유형 | 건수 | 파일수 |
|------|------|--------|
| `<style>` 태그 | 4 | 4 |
| `onclick=` | 17 | 8 |
| `onchange=` | 1 | 1 |
| `href="javascript:"` | 12 | 10 |
| HTML 오류 | 1 | 1 |
| **총계** | **35건** | **15개 파일** |

---

## Phase E: 인라인 `<style>` 태그 제거 (4개)

### E-1. topology-physical-detail-fragment.html (~216줄)
**경로**: `pages/asset/topology-physical-detail-fragment.html`
**CSS 파일**: `pages/asset/topologyPhysicalDetailFragment.css`

주요 스타일:
- `.topology-container` - SVG 컨테이너
- `.switch-rect`, `.port-rect`, `.port-active/inactive/error/warning` - 포트 상태
- `.device-circle`, `.device-icon`, `.device-text` - 디바이스 표시
- `.connection-line` - 연결선 상태
- 다크모드 스타일

### E-2. node.html (~4줄)
**경로**: `pages/data/node.html`
**CSS 파일**: `pages/data/node.css`

수정 사항:
- Line 7: `th:src` → `th:href` (버그 수정)
- Line 19: `href="javascript:"` → `href="#"`

CSS:
```css
#nodeGrid {
    height: 600px;
    width: 100%;
}
```

### E-3. showAssetEventList.html (~15줄)
**경로**: `fragments/dashboard/showAssetEventList.html`
**CSS 파일**: `components/_dashboard-event-list.css` (공통)

### E-4. showNetworkEventList.html (~14줄)
**경로**: `fragments/dashboard/showNetworkEventList.html`
**CSS**: E-3과 동일 스타일 → 공통 CSS로 통합

---

## Phase F: 인라인 `onclick=` 제거 (17건, 8개 파일)

### F-1. external-ip-communication-trend.html (2건)
**경로**: `fragments/dashboard/external-ip-communication-trend.html`

| Line | Before | After |
|------|--------|-------|
| 13 | `onclick="loadExternalIpTrend('10m')"` | `id="btn10m"` (이미 있음) |
| 15 | `onclick="loadExternalIpTrend('1h')"` | `id="btn1h"` (이미 있음) |

**JS 수정**: 대시보드 위젯 JS에 이벤트 리스너 추가

### F-2. timeSereiseData.html (3건)
**경로**: `pages/detection/timeSereiseData.html`

| Line | Before | After |
|------|--------|-------|
| 59 | `onclick="downloadExcel('sp_03')"` | `id="btnDownloadExcel3"` |
| 143 | `onclick="downloadExcel('sp_04')"` | `id="btnDownloadExcel4"` |
| 229 | `onclick="downloadExcel()"` | `id="btnDownloadExcel"` |

**JS 수정**: `timesSereiseData.js`에 이벤트 리스너 추가

### F-3. assetEditFragment.html (6건)
**경로**: `fragments/operation/assetEditFragment.html`

| Lines | 함수 | 수정 방안 |
|-------|------|----------|
| 243, 257, 290, 304 | `removeInput(this)` | 클래스 기반 위임 |
| 265 | `addIpInput()` | `id="btnAddIp"` |
| 312 | `addMacInput()` | `id="btnAddMac"` |

**JS 수정**: 부모 페이지 JS에서 이벤트 위임

### F-4. actionTab.html (1건)
**경로**: `fragments/detection/tabs/actionTab.html`

| Line | Before | After |
|------|--------|-------|
| 25 | `onclick="saveAction()"` | `id="btnSaveAction"` |

### F-5. analysisTab.html (1건)
**경로**: `fragments/detection/tabs/analysisTab.html`

| Line | Before | After |
|------|--------|-------|
| 14 | `onclick="saveAnalysisHistory()"` | `id="btnSaveAnalysis"` |

### F-6. relatedEventsTab.html (1건)
**경로**: `fragments/detection/tabs/relatedEventsTab.html`

| Line | Before | After |
|------|--------|-------|
| 64 | `onclick="loadMoreRelatedEvents(this)"` | 클래스 기반 위임 |

### F-7. groupList.html (2건)
**경로**: `pages/setting/groupList.html`

| Line | Before | After |
|------|--------|-------|
| 42 | `onclick="showGroupAddModal()"` | `id="btnShowGroupAddModal"` |
| 124 | `onclick="saveNewGroup()"` | `id="btnSaveNewGroup"` |

**JS 수정**: `groupList.js`에 이벤트 리스너 추가

### F-8. systemConfig.html (1건)
**경로**: `pages/setting/systemConfig.html`

| Line | Before | After |
|------|--------|-------|
| 22 | `onclick="saveSystemConfig()"` | `id="btnSaveSystemConfig"` |

**JS 수정**: `systemConfig.js`에 이벤트 리스너 추가

---

## Phase G: 인라인 `onchange=` 제거 (1건)

### G-1. userList.html
**경로**: `pages/setting/userList.html`

| Line | Before | After |
|------|--------|-------|
| 133 | `onchange="toggleStatusLabel()"` | `id="statusCheckbox"` 추가 |

**JS 수정**: `userList.js`에 change 이벤트 리스너 추가

---

## Phase H: `href="javascript:"` 수정 (12건, 10개 파일)

### 일괄 수정: `href="javascript:"` → `href="#"`

| # | 파일 | Lines |
|---|------|-------|
| 1 | `layouts/default.html` | 380 |
| 2 | `pages/data/node.html` | 19 |
| 3 | `pages/asset/operation.html` | 23 |
| 4 | `pages/detection/timeSereiseData.html` | 28 |
| 5 | `pages/setting/audit.html` | 13 |
| 6 | `pages/setting/code.html` | 15 |
| 7 | `pages/setting/groupList.html` | 23 |
| 8 | `pages/setting/systemConfig.html` | 9 |
| 9 | `pages/setting/topology-switch.html` | 15 |
| 10 | `pages/setting/userList.html` | 17, 170, 173 |

---

## 작업 순서 (권장)

1. **Phase H 먼저**: `href="javascript:"` 일괄 수정 (간단, 12건)
2. **Phase E**: `<style>` 태그 외부 추출 (4개 파일)
3. **Phase F**: `onclick=` 제거 (17건)
4. **Phase G**: `onchange=` 제거 (1건)

---

## 검증 방법

1. 브라우저 콘솔에서 CSP 오류 확인
2. 각 페이지 기능 테스트 (버튼 클릭, 폼 제출)
3. 다크모드 전환 테스트 (토폴로지 페이지)

---

## 완료 조건

### 1차 완료 ✓
- [x] 16개 CSS 외부 추출 완료
- [x] 기존 8건 JS 인라인 이벤트 제거 완료

### 2차 목표
- [ ] 4개 추가 CSS 외부 추출
- [ ] 17건 onclick 제거
- [ ] 1건 onchange 제거
- [ ] 12건 href="javascript:" 수정
- [ ] CSP에서 style-src 'unsafe-inline' 제거 가능
