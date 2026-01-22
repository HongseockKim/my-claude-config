# CSP style-src 'unsafe-inline' 제거 작업

> **최종 업데이트**: 2026-01-14
> **목표**: CSP에서 `style-src 'unsafe-inline'` 제거하여 보안 강화

---

## 진행 상황

| Phase | 작업 내용 | 상태 | 비고 |
|-------|----------|------|------|
| Phase 1 | `<style>` 태그 제거 | ✅ 완료 | 외부 CSS로 이동 |
| Phase 2 | `th:style` 동적 스타일 변환 | ✅ 완료 | CSS 변수 활용 |
| Phase 3 | JS 인라인 스타일 제거 (~48건) | ✅ 완료 | classList 활용 |
| Phase 4 | HTML `style=` 속성 제거 | 🔄 진행중 | 182건 남음 (293→182) |

---

## Phase 4 남은 작업 (182건)

### 파일별 분포

| 파일 | 건수 | 우선순위 |
|------|------|----------|
| `pages/setting/collectionOpTag.html` | 47 | HIGH |
| `pages/detection/timeSereiseData.html` | 38 | HIGH |
| `fragments/policy/eventTableFragment.html` | 17 | MEDIUM |
| `pages/asset/operation.html` | 14 | MEDIUM |
| `pages/setting/alarm.html` | 12 | MEDIUM |
| `components/navbar.html` | 12 | MEDIUM |
| `pages/asset/topology-physical-detail.html` | 9 | LOW |
| `pages/asset/topology-physical-detail-fragment.html` | 8 | LOW |
| `pages/policy/sessionWhite.html` | 7 | LOW |
| `pages/data/systemResource.html` | 6 | LOW |
| 기타 파일들 | 12 | LOW |

---

## 수정 규칙

### HTML 인라인 스타일 → CSS 클래스 변환

| 인라인 스타일 | CSS 클래스 | 비고 |
|--------------|-----------|------|
| `style="height: 100%"` | `class="h-100"` | Bootstrap |
| `style="width: 100%"` | `class="w-100"` | Bootstrap |
| `style="width: 15%"` | `class="col-width-15"` | dashboard.css |
| `style="width: 30%"` | `class="col-width-30"` | dashboard.css |
| `style="width: 40%"` | `class="col-width-40"` | dashboard.css |
| `style="display: none"` | `class="d-none"` | Bootstrap |
| `style="display: flex"` | `class="d-flex"` | Bootstrap |
| `style="min-height: 0"` | `class="min-h-0"` | dashboard.css |
| `style="overflow-y: auto"` | `class="overflow-y-auto"` | dashboard.css |
| `style="overflow-x: hidden"` | `class="overflow-x-hidden"` | dashboard.css |
| `style="padding-left: 12px"` | `class="ps-3"` | Bootstrap |
| `style="cursor: pointer"` | `class="cursor-pointer"` | dashboard.css |
| `style="position: relative"` | `class="position-relative"` | Bootstrap |

### 복합 스타일 → 전용 클래스 정의

```css
/* 예: 차트 컨테이너 */
.asset-chart-container {
    position: relative;
    max-width: 140px;
    width: 100%;
    height: auto;
    margin: auto;
}
```

---

## 분석 규칙 (작업 전 확인사항)

### 1. 레이아웃 확인
```html
<!-- 어떤 레이아웃을 사용하는지 확인 -->
layout:decorate="~{layouts/default}"  → main.css, dashboard.css 로드
layout:decorate="~{layouts/nothing}"  → _auth-pages.css만 로드
```

### 2. CSS 파일 선택
| 레이아웃 | CSS 파일 위치 |
|---------|--------------|
| default | `css/pages/{page}.css` 또는 `css/main.css` |
| nothing | `css/components/_auth-pages.css` |
| 대시보드 관련 | `css/pages/dashboard.css` |

### 3. Bootstrap 유틸리티 우선 사용
- `h-100`, `w-100`, `d-flex`, `d-none`, `ps-3`, `pe-3`, `position-relative` 등
- 없으면 해당 CSS 파일에 유틸리티 클래스 추가

### 4. Fragment 수정 시 주의
- `th:fragment` div에 `class="h-100"` 필수 추가
- `th:insert`로 삽입되면 중첩 div 발생 → fragment root에 h-100 필요

---

## 오늘 완료한 작업 요약

### 대시보드 Fragment 수정 (19개 파일)
- 모든 fragment root div에 `h-100` 추가
- 인라인 스타일 → CSS 클래스 변환
- 스크롤바 숨김 처리

### dashboard.css 추가된 클래스
```css
.col-width-15 { width: 15%; }
.col-width-30 { width: 30%; }
.col-width-40 { width: 40%; }
.min-h-0 { min-height: 0; }
.overflow-y-auto { overflow-y: auto; }
.overflow-x-hidden { overflow-x: hidden; }
.asset-chart-container { ... }
.asset-status-legend { overflow-y: auto; scrollbar-width: none; ... }
```

### 기타 수정
- `border-radius: 0 !important` 복원 (위젯 라운드 제거)
- 중복 CSS 규칙 제거

---

## 내일 작업 시작점

1. **collectionOpTag.html** (47건) - 가장 많음
2. **timeSereiseData.html** (38건)
3. **eventTableFragment.html** (17건)

### 작업 명령어
```bash
# 특정 파일의 인라인 스타일 확인
grep -n "style=" src/main/resources/templates/pages/setting/collectionOpTag.html | grep -v "th:style"

# 전체 남은 건수 확인
grep -r "style=" src/main/resources/templates --include="*.html" | grep -v "th:style" | wc -l
```

---

## 최종 목표

모든 인라인 스타일 제거 후:
1. `SecurityConfig.java`에서 `style-src 'unsafe-inline'` 제거
2. 테스트 및 검증
3. 보안 스캔 재실행
