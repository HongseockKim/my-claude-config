# 인라인 스크립트 외부 추출 가이드

CSP(Content Security Policy) nonce 적용을 위한 인라인 스크립트 외부 JS 파일 추출 가이드.

---

## 작업 순서 요약

| 단계 | 파일 | 작업 |
|------|------|------|
| 1 | `layouts/default.html` | pageMessage에 메시지 추가 |
| 2 | `static/js/page.폴더/파일.js` | 외부 JS 파일 생성 |
| 3 | `pages/폴더/페이지.html` | pageConfig div 추가 |
| 4 | `pages/폴더/페이지.html` | 스크립트 블록 교체 (인라인 삭제) |
| 5 | `scripts/generate-sri.sh` | generate_hash 라인 추가 |
| 6 | 터미널 | `./scripts/generate-sri.sh` 실행 |

---

## 1. 인라인 스크립트 분석

### 1-1. Thymeleaf 인라인 변수 찾기

HTML 파일에서 `/*[[...]]*/` 패턴을 찾아 목록화:

```javascript
// 패턴 1: 전역 변수로 선언된 메시지
const 변수명 = /*[[${@messageSource.getMessage('키',null,'기본값',#locale)}]]*/ '기본값';

// 패턴 2: 함수 내부에서 선언된 메시지
function 함수명() {
    const 변수명 = /*[[${@messageSource.getMessage('키',null,'기본값',#locale)}]]*/ '기본값';
}
```

### 1-2. 추출할 항목 분류

| 유형 | 예시 | 처리 방법 |
|------|------|----------|
| 다국어 메시지 | `getMessage('키')` | default.html pageMessage에 추가 |
| 권한 정보 | `userPermissions['canWrite']` | pageConfig div에 추가 |
| 서버 데이터 | `${zone3List}` | pageConfig div에 추가 |
| 전역 변수 | `let gridApi;` | JS 파일로 이동 |
| 함수 | `function loadData()` | JS 파일로 이동 |

---

## 2. default.html 메시지 추가

**위치:** `src/main/resources/templates/layouts/default.html` - `id="pageMessage"` div 내부

### 2-1. 속성 네이밍 규칙

```
th:data-{페이지명}-{기능}-{항목}
```

**예시:**
```html
<!-- 스위치 관리 페이지 메시지 -->
th:data-switch-delete-confirm="${@messageSource.getMessage('setting.switch.delete.confirm.message',null,'정말 삭제하시겠습니까?',#locale)}"
th:data-switch-empty="${@messageSource.getMessage('setting.switch.empty.switch.message',null,'등록된 스위치가 없습니다.',#locale)}"
th:data-switch-add="${@messageSource.getMessage('setting.switch.form.add.switch',null,'스위치 추가',#locale)}"
th:data-switch-name="${@messageSource.getMessage('setting.switch.form.switch.name',null,'스위치 명',#locale)}"
th:data-switch-name-placeholder="${@messageSource.getMessage('setting.switch.form.switch.placeHolder',null,'스위치 명을 입력해주세요',#locale)}"
th:data-switch-ip="${@messageSource.getMessage('setting.switch.form.ip.name',null,'IP',#locale)}"
th:data-switch-ip-placeholder="${@messageSource.getMessage('setting.switch.form.ip.placeHoler',null,'스위치 IP 를 입력해주세요',#locale)}"
```

### 2-2. HTML → JS 변환 규칙

| HTML 속성 | JS dataset 접근 |
|-----------|-----------------|
| `th:data-switch-delete-confirm` | `dataset.switchDeleteConfirm` |
| `th:data-switch-empty` | `dataset.switchEmpty` |
| `th:data-my-key-name` | `dataset.myKeyName` |

**규칙:** 하이픈(-) 구분 → camelCase 변환

---

## 3. 외부 JS 파일 생성

**경로:** `src/main/resources/static/js/page.{폴더명}/{파일명}.js`

### 3-1. 전체 템플릿

```javascript
/**
 * 페이지 설명
 * @FilePath: src/main/resources/static/js/page.폴더명/파일명.js
 */

// ============================================
// PageConfig: 설정 및 메시지 관리
// ============================================
const PageConfig = (function () {
    'use strict';
    let _config = null;
    let _message = null;

    function init() {
        const configElement = document.getElementById('pageConfig');
        const messageElement = document.getElementById('pageMessage');
        if (!configElement || !messageElement) return;

        // 페이지 고유 설정 (권한, 서버 데이터 등)
        _config = {
            canWrite: configElement.dataset.canWrite === 'true',
            canDelete: configElement.dataset.canDelete === 'true'
            // 필요시 추가: zone3: configElement.dataset.zone3
        };

        // 다국어 메시지
        _message = {
            deleteConfirm: messageElement.dataset.switchDeleteConfirm || '정말 삭제하시겠습니까?',
            empty: messageElement.dataset.switchEmpty || '등록된 스위치가 없습니다.',
            add: messageElement.dataset.switchAdd || '스위치 추가'
            // 필요한 메시지 추가
        };
    }

    function get(key) {
        if (!_config) init();
        return key ? _config[key] : _config;
    }

    function msg(key) {
        if (!_message) init();
        return key ? _message[key] : _message;
    }

    return { init, get, msg };
})();

// ============================================
// 전역 변수
// ============================================
let currentZone = null;
let currentIdx = null;
let dataCache = {};

// ============================================
// 함수 정의 (기존 인라인에서 이동)
// ============================================

// 목록 로드
function loadList(zone) {
    $.ajax({
        url: '/api/endpoint/' + zone,
        type: 'GET',
        success: function (res) {
            if (res.success) {
                // 데이터 처리
            }
        },
        error: function (error) {
            ErrorLog.log(error);
        }
    });
}

// 저장
function saveData() {
    // ...
}

// 삭제
function deleteData() {
    if (!currentIdx) return;
    // ...
}

// ============================================
// 초기화 (document.ready)
// ============================================
$(document).ready(function () {
    PageConfig.init();

    // 초기 데이터 로드
    // ...

    // 이벤트 핸들러 등록
    $(document).on('click', '.btn-save', function () {
        saveData();
    });

    $(document).on('click', '.btn-delete', function () {
        if (confirm(PageConfig.msg('deleteConfirm'))) {
            deleteData();
        }
    });
});
```

### 3-2. 변환 매핑 예시

| 기존 인라인 코드 | 변환 후 |
|-----------------|---------|
| `const msg = /*[[${@messageSource...}]]*/ '기본값';` | `const msg = PageConfig.msg('키');` |
| `if (confirm(confirmText))` | `if (confirm(PageConfig.msg('deleteConfirm')))` |
| `${emptySwitchText}` (템플릿 리터럴 내) | `${PageConfig.msg('empty')}` |

---

## 4. HTML pageConfig div 추가

**위치:** `layout:fragment="content"` 바로 다음 (첫 번째 자식)

### 4-1. 권한 전달

```html
<div class="d-none"
     id="pageConfig"
     th:data-can-write="${userPermissions['canWrite']}"
     th:data-can-delete="${userPermissions['canDelete']}">
</div>
```

### 4-2. 추가 데이터 전달 (필요시)

```html
<div class="d-none"
     id="pageConfig"
     th:data-can-write="${userPermissions['canWrite']}"
     th:data-can-delete="${userPermissions['canDelete']}"
     th:data-zone3="${selectedZone3}"
     th:data-user-id="${currentUser.userId}">
</div>
```

### 4-3. 권한별 버튼 처리 (HTML에서 유지)

**중요:** 버튼의 표시/숨김은 **HTML th:if로 유지** (서버 사이드 렌더링)

```html
<!-- WRITE 권한: 추가/저장 버튼 -->
<button class="btn btn-save" th:if="${userPermissions?.canWrite}">저장</button>

<!-- DELETE 권한: 삭제 버튼 -->
<button class="btn btn-delete" th:if="${userPermissions?.canDelete}">삭제</button>
```

**JS에서는 권한 체크 불필요** - 버튼 자체가 렌더링되지 않음

---

## 5. HTML 스크립트 블록 교체

### 5-1. 기존 인라인 스크립트 삭제

```html
<!-- 삭제할 부분 -->
<th:block layout:fragment="script">
    <script th:inline="javascript">
        // 모든 인라인 코드...
    </script>
</th:block>
```

### 5-2. 외부 JS 참조로 교체

```html
<!-- 새로운 코드 -->
<th:block layout:fragment="script">
    <script th:integrity="${sri.getHash('파일명_js')}"
            th:nonce="${nonce}"
            th:src="@{/js/page.폴더명/파일명.js}"></script>
</th:block>
```

### 5-3. SRI 해시 키 네이밍

| JS 파일 경로 | SRI 키 |
|-------------|--------|
| `page.setting/topologySwitch.js` | `topologySwitch_js` |
| `page.detection/connection.js` | `connection_js` |
| `page.asset/operation.js` | `operation_js` |

---

## 6. generate-sri.sh 추가

**파일:** `scripts/generate-sri.sh`

```bash
# 기존 라인들 아래에 추가
generate_hash "$STATIC_DIR/js/page.폴더명/파일명.js" "파일명_js"
```

**실행:**
```bash
./scripts/generate-sri.sh
```

---

## 검증 체크리스트

### 기능 검증

- [ ] 페이지 로드 시 데이터 정상 표시
- [ ] 탭 전환 동작 (있는 경우)
- [ ] 목록 렌더링
- [ ] 추가/수정/삭제 동작
- [ ] 다국어 메시지 표시
- [ ] alert/confirm 메시지 정상

### 권한 검증

- [ ] WRITE 권한 없는 사용자: 추가/저장 버튼 숨김
- [ ] DELETE 권한 없는 사용자: 삭제 버튼 숨김
- [ ] 권한 있는 사용자: 버튼 정상 표시 및 동작

### 보안 검증

- [ ] 브라우저 콘솔에서 CSP 오류 없음
- [ ] SRI 해시 적용 확인 (개발자 도구 Network 탭)

---

## 완료된 페이지

| 페이지 | URL | JS 파일 | 상태 |
|--------|-----|---------|------|
| 자산현황 | `/asset/operation` | `page.asset/operation.js` | 완료 |
| 물리토폴로지 | `/asset/topologyPhysical` | `page.topology/topology_physical.js` | 완료 |
| 자산별트래픽 | `/traffic/trafficAsset` | `page.traffic/trafficAsset.js` | 완료 |
| 화이트리스트위반 | `/event/detection/connection` | `page.detection/connection.js` | 완료 |
| 이상이벤트탐지 | `/event/detection/timesData` | `page.detection/timesData.js` | 완료 |
| 시계열이종데이터 | `/event/detection/timesSereise` | `page.detection/timesSereiseData.js` | 완료 |
| 분석및조치이력 | `/event/detection/analysisAction` | `page.detection/analysisAndAction.js` | 완료 |
| 메뉴관리 | `/setting/menu` | `page.setting/menu.js` | 완료 |
| 코드관리 | `/setting/code` | `page.setting/code.js` | 완료 |
| 감사로그설정 | `/setting/audit` | `page.setting/audit.js` | 완료 |
| 알람설정 | `/setting/alarm` | `page.setting/alarm.js` | 완료 |
| 스위치관리 | `/setting/topology-switch` | `page.setting/topologySwitch.js` | **진행중** |

---

## 미완료 페이지 (예상)

| 페이지 | URL | 작업 필요 |
|--------|-----|----------|
| 스위치관리 | `/setting/topology-switch` | HTML 스크립트 블록 교체 |
| 시스템설정 | `/setting/system-config` | 분석 필요 |
| 사용자관리 | `/setting/user-list` | 분석 필요 |
| 그룹관리 | `/setting/group-list` | 분석 필요 |
| 대시보드템플릿 | `/setting/dashboard-template` | 분석 필요 |
| 운전정보수집설정 | `/setting/collection-op-tag` | 분석 필요 |

---

## 자주 발생하는 실수

### 1. HTML 속성명 ↔ JS dataset 불일치

```html
<!-- HTML -->
th:data-switch-delete-confirm="..."
```
```javascript
// JS - 틀린 예
messageElement.dataset.switch-delete-confirm  // 오류!
messageElement.dataset['switch-delete-confirm']  // 작동하지만 권장 안함

// JS - 올바른 예
messageElement.dataset.switchDeleteConfirm  // camelCase 변환
```

### 2. 인라인 스크립트 삭제 안 함

JS 파일 생성 후 **반드시 HTML의 인라인 스크립트 삭제** 필요

### 3. SRI 해시 미생성

`generate-sri.sh` 실행 안 하면 스크립트 로드 실패

### 4. 권한 버튼 JS에서 중복 체크

권한 체크는 **HTML th:if로 충분** - JS에서 추가 체크 불필요

---

## 스위치관리 페이지 작업 상태 (2026-01-12)

### 완료 항목
- [x] default.html에 메시지 7개 추가 (61-67행)
- [x] topologySwitch.js 파일 생성
- [x] topology-switch.html에 pageConfig div 추가 (7-11행)

### 미완료 항목
- [ ] topology-switch.html 스크립트 블록 교체 (92-406행 삭제 → 외부 JS 참조)
- [ ] generate-sri.sh에 해시 라인 추가
- [ ] SRI 해시 생성 실행
- [ ] 기능 테스트
