# CSS 외부 추출 및 솔루션화 계획

> **작성일**: 2026-01-13
> **상태**: Phase 3 진행 중
> **최종 수정**: 2026-01-14
> **다음 작업**: Phase 3 계속 - 나머지 페이지 CSS 추출

---

## 진행 현황

| Phase | 상태 | 완료 항목 |
|-------|------|----------|
| Phase 1 | ✅ 완료 | `_variables.css`, `_ag_grid-custom.css`, `main.css` |
| Phase 2 | ✅ 완료 | `_jstree-custom.css`, `_loading.css`, `_two-column.css` |
| Phase 3 | 🔄 진행중 | dashboard, groupList, userList, timeSereiseData, topology-physical, topology-physical-detail, operation, gap, trafficAsset, timesData (10/35) |
| Phase 4 | ⏳ 대기 | |
| Phase 5 | ⏳ 대기 | |
| Phase 6 | ⏳ 대기 | |

---

## 목표
- 35개 HTML 템플릿의 인라인 CSS를 외부 파일로 추출
- CSP `style-src 'unsafe-inline'` 제거하여 보안 강화
- 솔루션화를 위한 테마/커스터마이징 구조 구축

---

## 중요 사항
- **정확하고 자세하게, 오타 없이 마이그레이션**
- 각 파일 작업 후 브라우저에서 UI 확인 필수
- 순차적으로 Phase 1 → 6 진행

---

## ⭐ CSS 제안 원칙 (필수)

> **모든 페이지 CSS 제안 시 공통 CSS와 정밀 비교 후 중복 제거된 버전으로 제안**

### 비교 대상 공통 CSS 파일
| 파일 | 포함 내용 |
|------|----------|
| `core/_variables.css` | CSS Custom Properties (테마 변수) |
| `components/_ag_grid-custom.css` | AG Grid 테마 (quartz, quartz-dark) |
| `components/_loading.css` | 로딩 오버레이 |
| `components/_jstree-custom.css` | jsTree 스타일 |
| `layouts/_two-column.css` | 2단 레이아웃 |

### 제안 프로세스
1. 페이지 인라인 CSS 전체 확인
2. 공통 CSS 파일과 **라인별 정밀 비교**
3. 100% 동일 → 제거
4. 공통이 더 완전 → 제거
5. 페이지 고유 또는 의도적 충돌 → 유지
6. 충돌 시 `!important` 필요 여부 확인
7. **최적화된 페이지 고유 CSS만 제안**
8. **관련 JS 파일 인라인 이벤트 핸들러 검사** (onclick, onchange 등)

### 충돌 주의사항
- 동일 선택자에 다른 값: CSS 로드 순서 확인
- `!important` 충돌: 특이성 + important 우선순위 확인
- 의도적 오버라이드: 페이지에서 `!important` 추가 필요할 수 있음

---

## 현재 상태

| 항목 | 수치 |
|------|------|
| 인라인 CSS 포함 파일 | 35개 |
| th:nonce 적용된 `<style>` | 0개 |
| 가장 큰 CSS | timeSereiseData.html (631줄) |
| CSP 현재 설정 | `style-src 'self' 'unsafe-inline' blob:` |
| CSP 목표 설정 | `style-src 'self' blob:` |

---

## CSS 폴더 구조 (솔루션 지향)

```
src/main/resources/static/css/
├── core/                           # 핵심 시스템 스타일
│   ├── _variables.css              # CSS Custom Properties (테마 기반)
│   ├── _reset.css                  # 추가 리셋
│   └── _utilities.css              # 커스텀 유틸리티 클래스
│
├── themes/                         # 고객별 테마
│   ├── default/
│   │   └── theme.css               # 기본 테마
│   └── samcheonpo/                 # 삼천포발전소 (현재 고객)
│       └── theme.css
│
├── components/                     # 재사용 컴포넌트 스타일
│   ├── _ag-grid-custom.css         # AG Grid 테마 오버라이드 (통합)
│   ├── _jstree-custom.css          # jsTree 커스터마이징
│   ├── _panel.css                  # 패널 컴포넌트
│   ├── _offcanvas.css              # Offcanvas/사이드바
│   ├── _loading.css                # 로딩 오버레이
│   └── _forms.css                  # 폼 스타일
│
├── layouts/                        # 레이아웃 스타일
│   ├── _two-column.css             # 2단 레이아웃
│   ├── _grid-layout.css            # 그리드 레이아웃
│   └── _page-container.css         # 페이지 컨테이너
│
├── pages/                          # 페이지별 스타일 (최소화)
│   ├── dashboard.css
│   ├── setting/
│   │   ├── groupList.css
│   │   ├── userList.css
│   │   └── ...
│   ├── asset/
│   │   └── topology.css
│   ├── detection/
│   │   └── timeSereiseData.css
│   └── analysis/
│       └── report.css
│
└── main.css                        # 마스터 import 파일
```

---

## 구현 단계

### Phase 1: 기반 구조 생성 (2-3시간)
1. `css/core/_variables.css` 생성 - CSS Custom Properties 정의
2. `css/components/_ag-grid-custom.css` 생성 - AG Grid 공통 스타일 통합
3. `css/main.css` 생성 - 마스터 import 파일

### Phase 2: 공통 패턴 추출 (3-4시간)
1. `css/components/_jstree-custom.css` - jstree 스타일
2. `css/components/_loading.css` - 로딩 오버레이
3. `css/components/_panel.css` - 패널/카드 스타일
4. `css/layouts/_two-column.css` - 2단 레이아웃

### Phase 3: 페이지별 CSS 추출 (4-6시간)
| 우선순위 | 파일 | 대상 CSS | 상태 |
|---------|------|----------|------|
| 1 | dashboard.html | pages/dashboard.css | ✅ 완료 |
| 2 | groupList.html | pages/setting/groupList.css | ✅ 완료 |
| 3 | userList.html | pages/setting/userList.css | ✅ 완료 |
| 4 | timeSereiseData.html | pages/detection/timeSereiseData.css | ✅ 완료 |
| 5 | topology-physical.html | pages/asset/topology-physical.css | ✅ 완료 (최적화) |
| 6 | topology-physical-detail.html | pages/asset/topology-physical-detail.css | ✅ 완료 |
| 7 | operation.html (asset) | pages/asset/operation.css | ✅ 완료 (최적화+JS수정) |
| 8 | gap.html | pages/asset/gap.css | ✅ 완료 |
| 9 | trafficAsset.html | pages/asset/trafficAsset.css | ✅ 완료 (최적화 186→71줄) |
| 10 | timesData.html | pages/detection/timesData.css | ✅ 완료 (160→84줄, JS수정) |
| ... | 나머지 25개 | 해당 폴더에 생성 | ⏳ 대기 |

### Phase 4: 인라인 style 속성 처리 (2-3시간)
| 패턴 | 해결 방법 |
|------|----------|
| `style="display: none;"` | Bootstrap `.d-none` 사용 |
| `style="min-height: 100px;"` | 유틸리티 클래스 생성 |
| `style="z-index: 10000;"` | `.z-overlay` 유틸리티 생성 |

### Phase 5: 테마 시스템 구축 (2-3시간)
1. `css/themes/default/theme.css` 생성
2. `css/themes/samcheonpo/theme.css` 생성
3. 테마 전환 메커니즘 구현

### Phase 6: CSP 업데이트 및 테스트 (1-2시간)
1. `CspNonceFilter.java` 수정: `'unsafe-inline'` 제거
2. 전체 페이지 테스트
3. 보안 스캔 재실행

---

## 수정 대상 파일

### 생성할 파일
- `css/core/_variables.css`
- `css/components/_ag-grid-custom.css`
- `css/components/_jstree-custom.css`
- `css/components/_loading.css`
- `css/components/_panel.css`
- `css/layouts/_two-column.css`
- `css/pages/dashboard.css`
- `css/pages/setting/groupList.css`
- (35개 페이지별 CSS 파일)
- `css/themes/default/theme.css`
- `css/main.css`

### 수정할 파일
- 35개 HTML 템플릿 (인라인 `<style>` 제거, `<link>` 추가)
- `CspNonceFilter.java` (style-src에서 `'unsafe-inline'` 제거)
- `pom.xml` (jstree webjars 추가) ✅ 완료

---

## 검증 방법

1. **로컬 테스트**
   ```bash
   mvnw.cmd spring-boot:run -DskipTests
   ```
   - 모든 페이지 UI 확인
   - 개발자 도구에서 CSP 오류 확인

2. **CSP 검증**
   - 응답 헤더에서 `'unsafe-inline'` 제거 확인
   - 브라우저 콘솔에서 스타일 차단 오류 없음 확인

3. **보안 스캔**
   - HCL AppScan 재스캔
   - "스크립트 허용 목록 우회" 취약점 해결 확인

---

## 35개 HTML 파일 전체 목록

### setting/ (10개)
| # | 파일명 | CSS 줄수 | 추출 대상 CSS |
|---|--------|----------|---------------|
| 1 | groupList.html | 290 | `pages/setting/groupList.css` |
| 2 | userList.html | 150 | `pages/setting/userList.css` |
| 3 | template.html | 188 | `pages/setting/template.css` |
| 4 | alarmList.html | 102 | `pages/setting/alarmList.css` |
| 5 | auditList.html | 163 | `pages/setting/auditList.css` |
| 6 | collectionOpTag.html | 3 | 공통 컴포넌트로 통합 |
| 7 | menu.html | 33 | `pages/setting/menu.css` |
| 8 | code.html | ~50 | `pages/setting/code.css` |
| 9 | audit.html | ~50 | `pages/setting/audit.css` |
| 10 | alarm.html | ~50 | `pages/setting/alarm.css` |

### asset/ (5개)
| # | 파일명 | CSS 줄수 | 추출 대상 CSS |
|---|--------|----------|---------------|
| 11 | operation.html | 78 | `pages/asset/operation.css` |
| 12 | topology-physical.html | ~200 | `pages/asset/topology-physical.css` |
| 13 | topology-physical-detail.html | 283 | `pages/asset/topology-physical-detail.css` |
| 14 | topology-physical-detail-fragment.html | 230 | 공통 컴포넌트로 통합 |
| 15 | gap.html | 26 | `pages/asset/gap.css` |
| 16 | trafficAsset.html | ~100 | `pages/asset/trafficAsset.css` |

### detection/ (5개)
| # | 파일명 | CSS 줄수 | 추출 대상 CSS |
|---|--------|----------|---------------|
| 17 | timeSereiseData.html | 631 | `pages/detection/timeSereiseData.css` |
| 18 | timesData.html | ~200 | `pages/detection/timesData.css` |
| 19 | connection.html | ~150 | `pages/detection/connection.css` |
| 20 | analysisAndAction.html | 102 | `pages/detection/analysisAndAction.css` |

### data/ (3개)
| # | 파일명 | CSS 줄수 | 추출 대상 CSS |
|---|--------|----------|---------------|
| 21 | session.html | 40 | `pages/data/session.css` |
| 22 | systemResource.html | 225 | `pages/data/systemResource.css` |
| 23 | operation.html (data) | ~50 | `pages/data/operation.css` |

### policy/ (3개)
| # | 파일명 | CSS 줄수 | 추출 대상 CSS |
|---|--------|----------|---------------|
| 24 | sessionWhite.html | 117 | `pages/policy/sessionWhite.css` |
| 25 | timeSeries.html | 20 | `pages/policy/timeSeries.css` |
| 26 | servicePortPolicy.html | 61 | `pages/policy/servicePortPolicy.css` |

### analysis/ (2개)
| # | 파일명 | CSS 줄수 | 추출 대상 CSS |
|---|--------|----------|---------------|
| 27 | reportAdd.html | 230 | `pages/analysis/reportAdd.css` |
| 28 | reportList.html | 264 | `pages/analysis/reportList.css` |

### 기타 (7개)
| # | 파일명 | CSS 줄수 | 추출 대상 CSS |
|---|--------|----------|---------------|
| 29 | dashboard.html | 243 | `pages/dashboard.css` |
| 30 | login.html | 4 | 공통 컴포넌트로 통합 |
| 31 | changePassword.html | 4 | 공통 컴포넌트로 통합 |
| 32 | error.html | 7 | 공통 컴포넌트로 통합 |
| 33 | index.html | 4 | 공통 컴포넌트로 통합 |
| 34 | node.html | 12 | 공통 컴포넌트로 통합 |
| 35 | cyber-threat-gauge.html | ~50 | `pages/widget/cyber-threat-gauge.css` |

---

## 작업 체크리스트

### Phase 1 시작 전 확인
- [ ] 현재 브랜치 확인 (master 또는 feature 브랜치 생성)
- [ ] 프로젝트 빌드 정상 확인: `mvnw.cmd clean package -DskipTests`
- [ ] 로컬 서버 실행 확인: `mvnw.cmd spring-boot:run -DskipTests`

### 각 파일 작업 순서
1. HTML 파일에서 `<style>` 태그 내용 복사
2. 해당 CSS 파일 생성 (폴더 없으면 생성)
3. HTML에서 `<style>` 태그 제거
4. HTML에 `<link>` 태그 추가
5. 브라우저에서 해당 페이지 UI 확인
6. 문제 없으면 다음 파일 진행

### HTML 수정 패턴
**Before:**
```html
<th:block layout:fragment="style">
    <style>
        /* 인라인 CSS 내용 */
    </style>
</th:block>
```

**After:**
```html
<th:block layout:fragment="style">
    <link rel="stylesheet" th:href="@{/css/pages/setting/groupList.css}" />
</th:block>
```

---

## 핵심 파일 경로

### CSP 설정 파일
```
src/main/java/com/otoones/otomon/filter/CspNonceFilter.java
- 라인 45: style-src 'self' 'unsafe-inline' blob:
- 목표: style-src 'self' blob: (unsafe-inline 제거)
```

### CSS 기본 경로
```
src/main/resources/static/css/
```

### HTML 템플릿 경로
```
src/main/resources/templates/pages/
├── setting/
├── asset/
├── detection/
├── data/
├── policy/
├── analysis/
└── dashboard.html
```

---

## 예상 소요 시간

| Phase | 내용 | 시간 |
|-------|------|------|
| Phase 1 | 기반 구조 생성 | 2-3시간 |
| Phase 2 | 공통 패턴 추출 | 3-4시간 |
| Phase 3 | 페이지별 CSS 추출 (35개) | 4-6시간 |
| Phase 4 | 인라인 style 속성 처리 | 2-3시간 |
| Phase 5 | 테마 시스템 구축 | 2-3시간 |
| Phase 6 | CSP 업데이트 및 테스트 | 1-2시간 |
| **총계** | | **14-21시간** |

---

## 작업 시작 명령어

```bash
# 1. 프로젝트 경로로 이동
cd C:\Users\user\IdeaProjects\OtoMON-K

# 2. 빌드 확인
mvnw.cmd clean package -DskipTests

# 3. 서버 실행 (별도 터미널)
mvnw.cmd spring-boot:run -DskipTests

# 4. CSS 폴더 구조 생성
mkdir src\main\resources\static\css\core
mkdir src\main\resources\static\css\components
mkdir src\main\resources\static\css\layouts
mkdir src\main\resources\static\css\themes\default
mkdir src\main\resources\static\css\pages\setting
mkdir src\main\resources\static\css\pages\asset
mkdir src\main\resources\static\css\pages\detection
mkdir src\main\resources\static\css\pages\data
mkdir src\main\resources\static\css\pages\policy
mkdir src\main\resources\static\css\pages\analysis
```

---

## 완료 조건

- [ ] 35개 HTML 파일에서 모든 `<style>` 태그 제거됨
- [ ] 모든 페이지 UI 정상 동작 확인
- [ ] `CspNonceFilter.java`에서 `'unsafe-inline'` 제거됨
- [ ] 브라우저 콘솔에 CSP 스타일 오류 없음
- [ ] 보안 스캔에서 "스크립트 허용 목록 우회" 취약점 해결됨
