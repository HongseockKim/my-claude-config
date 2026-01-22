# CSP style-src 'unsafe-inline' 제거 가능성 분석

> **분석일**: 2026-01-14
> **결론**: ❌ **즉시 제거 불가** - 추가 작업 필요

---

## 요약

| 유형 | 발견 건수 | 파일 수 |
|------|----------|--------|
| `<style>` 태그 | 6개 | 5개 |
| `style=` 인라인 속성 (HTML) | 293개 | 53개 |
| `th:style` 동적 스타일 | 5개 | 3개 |
| `.style.` (JS) | ~25개 | 10개 |
| `.css()` (jQuery) | ~23개 | 12개 |
| **총계** | **~352건** | - |

---

## 1. HTML `<style>` 태그 (6건)

| 파일 | 라인 | 내용 |
|------|------|------|
| `login.html` | 12-16 | `body { height: 100vh; }` |
| `index.html` | 10-14 | `body { height: 100vh; }` |
| `error.html` | 3-7 | `body { height: 100vh; }` |
| `pages/authError.html` | 5-25 | 에러 페이지 스타일 |
| `pages/user/changePassword.html` | 28-32 | `body { height: 100vh; }` |

**해결 방안**: 외부 CSS 파일로 이동

---

## 2. HTML `style=` 인라인 속성 (293건) - 주요 항목

### 2.1 동적 스타일 `th:style` (5건) - 우선순위 HIGH

| 파일 | 라인 | 코드 |
|------|------|------|
| `pages/dashboard.html` | 23 | `th:style="'grid-column: ' + ... + '; grid-row: ' + ..."` |
| `components/navbar.html` | 52 | `th:style="${selectedZone.code == null ? 'color:red;' : ''}"` |
| `components/navbar.html` | 74 | `th:style="${selectedZone.idx == zone.idx} ? 'background-color:#e9ecef;' : ''"` |
| `pages/setting/collectionOpTag.html` | 234, 584 | `th:style="${tag['tagType'] == 'DROP_PREFIX' ? '' : 'display:none;'}"` |

### 2.2 정적 인라인 스타일 - 주요 파일별 분포

| 파일 | 건수 | 예시 |
|------|------|------|
| `pages/detection/timeSereiseData.html` | 45개 | 배경색, 폰트 크기, 패딩 |
| `pages/setting/collectionOpTag.html` | 48개 | 테이블 레이아웃, 너비 |
| `fragments/policy/eventTableFragment.html` | 18개 | 테이블 컬럼 너비 |
| `components/navbar.html` | 14개 | 레이아웃 스타일 |
| `pages/setting/alarm.html` | 12개 | 테이블 컬럼 너비 |
| `pages/asset/operation.html` | 16개 | display, cursor |
| 대시보드 위젯 (20+ 파일) | 80개+ | height, display, flex |

---

## 3. JavaScript 인라인 스타일 (~48건)

### 3.1 `.style.` 패턴 - 주요 항목

| 파일 | 라인 | 코드 | 제거 가능 |
|------|------|------|----------|
| `dashbord.js` | 24-26 | `btn.style.display = 'none'` | YES |
| `dashbord.js` | 981, 1050-1051 | `canvas.style.height = '400px'` | YES |
| `topologyPhysicalDetail.js` | 14, 17 | `container.style.background = '#2d353c'` | YES |
| `topologyPhysicalDetail.js` | 954, 1018 | `element.style.display = 'none/block'` | YES |
| `timesSereiseData.js` | 1023-1043 | `cell.style.backgroundColor = '#2d3142'` | YES |
| `userList.js` | 660, 673 | `btn.style = btnStyle` | YES |
| `updateCodeModal.js` | 276, 316 | `document.body.style.overflow = 'hidden'` | YES |

### 3.2 `.css()` 패턴 - 주요 항목

| 파일 | 라인 | 코드 | 제거 가능 |
|------|------|------|----------|
| `alarm_manager.js` | 105-130 | 배지 스타일 (17줄) | YES |
| `sessionWhite.js` | 249-258 | Zone3 비활성화 스타일 | YES |
| `sidebar-minify.js` | 345-663 | 서브메뉴 위치/스타일 (다수) | CONDITIONAL |
| `collectionOpTag.js` | 1111-1113 | IP 유효성 border-color | YES |
| `templates.js` | 179-185 | 위젯 opacity/cursor | YES |

---

## 4. 제거 불가 판정 이유

### 4.1 즉시 제거 시 문제 발생 예상 영역

1. **대시보드 위젯 그리드**: `th:style`로 동적 grid-column/grid-row 설정
2. **사이드바 메뉴**: JavaScript로 동적 위치 계산 후 스타일 적용
3. **테이블 컬럼 너비**: 293개 중 ~100개가 테이블 width 설정
4. **다크모드 전환**: JavaScript로 배경색/텍스트색 동적 변경

### 4.2 CSP style-src 'unsafe-inline' 제거 시 영향

- `style=` 인라인 속성: **모두 차단됨**
- `<style>` 태그 (nonce 없음): **모두 차단됨**
- `.style.xxx = 'value'` (JS): **모두 차단됨**
- `.css({...})` (jQuery): **모두 차단됨**

---

## 5. 권장 작업 순서

### Phase 1: `<style>` 태그 제거 (5개 파일)
- login.html, index.html, error.html, authError.html, changePassword.html
- 외부 CSS 파일로 이동 또는 기존 CSS에 병합

### Phase 2: `th:style` 동적 스타일 변환 (5건)
- CSS 변수 활용 또는 클래스 기반으로 변경
- dashboard.html의 grid 스타일은 특별 처리 필요

### Phase 3: JavaScript 인라인 스타일 제거 (~48건)
- `.style.display` → `classList.add/remove('d-none')`
- `.css({...})` → 클래스 토글
- 동적 계산 값 → CSS 변수 사용

### Phase 4: HTML `style=` 속성 제거 (293건)
- 테이블 width → CSS 클래스 정의
- display:none → `d-none` 클래스
- 기타 스타일 → 외부 CSS로 이동

---

## 6. 작업량 추정

| Phase | 건수 | 예상 작업량 |
|-------|------|------------|
| Phase 1 | 6건 | 소 |
| Phase 2 | 5건 | 중 |
| Phase 3 | 48건 | 대 |
| Phase 4 | 293건 | 대 |
| **총계** | ~352건 | **매우 큼** |

---

## 7. 결론

**현재 상태로는 `style-src 'unsafe-inline'` 제거 불가**

추가 작업 없이 제거하면:
- 대시보드 위젯 레이아웃 깨짐
- 사이드바 메뉴 동작 불가
- 테이블 컬럼 너비 무시됨
- 다크모드 전환 불가
- 모달/팝업 스타일 적용 안됨

**권장**: Phase 1 (style 태그)부터 단계적으로 진행
