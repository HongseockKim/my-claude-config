# Implementation Plan: Nonce 작업 및 인라인 스크립트 외부 추출

**Status**: 🔄 In Progress
**Started**: 2026-01-13
**Last Updated**: 2026-01-13

---

**⚠️ CRITICAL INSTRUCTIONS**: After completing each phase:
1. ✅ Check off completed task checkboxes
2. 🔍 Run all quality gate validation commands
3. ⚠️ Verify ALL quality gate items pass
4. 📅 Update "Last Updated" date above
5. 📝 Document learnings in Notes section
6. ➡️ Only then proceed to next phase

⛔ **DO NOT skip quality gates or proceed with failing checks**

---

## 🔧 Code Modification Rules

### ✏️ 기존 코드 수정 시
AI는 직접 수정하지 않음. 변경 정보만 제공:
- 📁 파일 경로
- 📍 라인 번호
- 📝 변경 내용 요약
- Before/After 코드 블록
- **사용자가 직접 수정**

### 🆕 새 코드 작성 시
AI가 **전체 코드** 제공 (요약 X):
- 📁 파일 경로
- 📝 복붙 가능한 완성 코드
- **사용자가 직접 파일 생성 후 붙여넣기**

---

## 📊 Codebase Analysis (Updated 2026-01-13)

### 현재 상태 요약

| 구분 | 파일 수 |
|------|--------|
| 총 HTML 파일 | 95개 |
| nonce 적용 완료 | 34개 |
| **nonce 미적용** | **61개** |
| **인라인 스크립트 남아있음** (th:inline) | **13개** |

### Nonce 적용 완료 파일 (34개)

- layouts/default.html
- analysis/reportAdd.html, reportList.html
- asset/gap.html, operation.html, topology-physical.html, topology-physical-detail.html, topology-physical-detail-fragment.html, trafficAsset.html
- data/node.html, operation.html, session.html, systemResource.html
- detection/analysisAndAction.html, connection.html, timesData.html, timeSereiseData.html
- policy/servicePortPolicy.html, sessionWhite.html, timeSeries.html
- setting/alarm.html, alarmList.html, audit.html, auditList.html, code.html, collectionOpTag.html, groupList.html, menu.html, systemConfig.html, template.html, topology-switch.html, userList.html
- pages/dashboard.html
- user/changePassword.html

### 🚨 인라인 스크립트 외부 추출 필요 (13개) - 최우선

nonce는 적용됐지만 `th:inline="javascript"`가 남아있어 외부 JS로 추출 필요:

| # | 파일 경로 | 상태 |
|---|----------|------|
| 1 | pages/dashboard.html | ⏳ 대형 - 최우선 |
| 2 | pages/asset/gap.html | ⏳ |
| 3 | pages/setting/userList.html | ⏳ |
| 4 | pages/setting/systemConfig.html | ⏳ |
| 5 | pages/setting/menu.html | ⏳ |
| 6 | pages/setting/audit.html | ⏳ |
| 7 | pages/setting/code.html | ⏳ |
| 8 | pages/policy/timeSeries.html | ⏳ |
| 9 | pages/policy/sessionWhite.html | ⏳ |
| 10 | pages/data/session.html | ⏳ |
| 11 | pages/data/operation.html | ⏳ |
| 12 | pages/detection/timeSereiseData.html | ⏳ |
| 13 | layouts/default.html | ⚠️ 공통 레이아웃 - 별도 검토 |

### nonce 미적용 파일 (61개)

#### A. 인라인 스크립트 있음 - 우선순위 높음

| 파일 경로 | 인라인 내용 |
|----------|------------|
| pages/user/reg.html | onclick 이벤트 |
| pages/policy/sessionBlack.html | onclick 이벤트 |
| pages/operation/collectionSysResource.html | onclick 이벤트 |
| pages/operation/dataReceive.html | onclick 이벤트 |
| pages/operation/dataSend.html | onclick 이벤트 |
| pages/policy/alert.html | onclick 이벤트 |
| pages/policy/dataDetectionRule.html | onclick 이벤트 |
| pages/operation/collectionNetwork.html | onclick 이벤트 |
| pages/detection/alert.html | onclick 이벤트 |
| pages/detection/asset.html | onclick 이벤트 |
| pages/detection/policySetup.html | onclick 이벤트 |
| pages/asset/topoligyPurdue.html | onclick 이벤트 |
| pages/analysis/traffic.html | onclick 이벤트 |
| pages/analysis/asset_operation.html | onclick 이벤트 |
| pages/analysis/asset_type.html | onclick 이벤트 |
| pages/analysis/optag.html | onclick 이벤트 |
| pages/analysis/timeseries.html | onclick 이벤트 |
| pages/analysis/anomal_asset.html | onclick 이벤트 |
| pages/analysis/anomal_session.html | onclick 이벤트 |
| index.html | `<script>` |
| components/notification.html | `<script>` |
| error.html | `<script>` |
| login.html | `<script>` |
| pages/analysis/timeseries2.html | `<script>` |
| pages/operation/audit.html | `<script>` |
| pages/operation/logCode.html | `<script>` |
| fragments/* (다수) | `<script>` 또는 onclick |

#### B. 기타 파일 (fragments, components 등)

### 관련 파일 맵

| 파일 | 용도 |
|------|------|
| `templates/layouts/default.html` | #pageMessage 메시지 저장소 |
| `static/js/global/utils.js` | window.loadLicenseKey 등 공통 함수 |
| `scripts/generate-sri.sh` | SRI 해시 자동 생성 |
| `src/main/resources/sri.properties` | SRI 해시 저장소 |

---

## 📋 Overview

### Feature Description
CSP(Content Security Policy) 보안 강화를 위해 모든 HTML 페이지의 인라인 스크립트를 외부 JS 파일로 추출하고, nonce 속성을 적용하는 작업.

### Success Criteria
- [ ] 모든 37개 미적용 파일에 nonce 적용 완료
- [ ] 브라우저 콘솔에 CSP 위반 오류 없음
- [ ] 모든 페이지 기능 정상 동작

### User Impact
보안 취약점(JavaScript 하이재킹) 해결로 시스템 보안 강화

---

## 🏗️ Architecture Decisions

| Decision | Rationale | Trade-offs |
|----------|-----------|------------|
| 인라인 → 외부 JS | CSP strict 정책 준수 | 파일 수 증가 |
| PageConfig IIFE 패턴 | 기존 완료 파일과 일관성 | 초기 학습 필요 |
| default.html 메시지 중앙화 | 국제화, 유지보수 용이 | default.html 비대화 |

---

## 📦 Dependencies

### Required Before Starting
- [x] global utils.js에 loadLicenseKey 함수 존재 확인
- [x] default.html에 #pageMessage 구조 확인
- [x] generate-sri.sh 스크립트 동작 확인

---

## 🚀 Implementation Phases

### Phase 1: 소형 페이지 (연습용) - data/node.html
**Goal**: 가장 간단한 파일로 패턴 연습
**Status**: ⏳ Pending

#### Tasks

**🆕 신규 코드 작성**
- [ ] **Create 1.1**: 외부 JS 파일 생성
    - File: `src/main/resources/static/js/page/data/node.js`
    - Details: 전체 코드 제공

**✏️ 기존 코드 수정**
- [ ] **Modify 1.2**: HTML 파일 수정
    - File: `src/main/resources/templates/pages/data/node.html`
    - Lines: 40-104
    - Change: 인라인 스크립트 제거, 외부 JS 로드 태그 추가

- [ ] **Modify 1.3**: SRI 해시 생성
    - File: `scripts/generate-sri.sh`
    - Change: node_js 해시 생성 라인 추가

#### Quality Gate ✋

**⚠️ STOP: Do NOT proceed to Phase 2 until ALL checks pass**

**Build & Code Quality**:
- [ ] **Build**: `mvnw.cmd spring-boot:run -DskipTests` 성공
- [ ] **SRI**: `./scripts/generate-sri.sh` 실행 완료

**Manual Testing**:
- [ ] `/data/node` 페이지 접속 정상
- [ ] AG Grid 로드 정상
- [ ] 브라우저 콘솔에 CSP 오류 없음

---

### Phase 2: 대형 페이지 - dashboard.html
**Goal**: 핵심 페이지 nonce 작업 완료
**Status**: ⏳ Pending

#### Tasks

**🆕 신규 코드 작성**
- [ ] **Create 2.1**: 외부 JS 파일 생성
    - File: `src/main/resources/static/js/page/dashboard.js`
    - Details: 3,200줄 코드 추출

**✏️ 기존 코드 수정**
- [ ] **Modify 2.2**: HTML 파일 수정
    - File: `src/main/resources/templates/pages/dashboard.html`
    - Lines: 416-3682
    - Change: 인라인 스크립트 제거 (selectedZone만 유지), 외부 JS 로드

- [ ] **Modify 2.3**: SRI 해시 생성
    - File: `scripts/generate-sri.sh`

#### Quality Gate ✋

**⚠️ STOP: Do NOT proceed to Phase 3 until ALL checks pass**

**Manual Testing**:
- [ ] `/dashboard` 페이지 접속 정상
- [ ] 모든 위젯 로드 정상
- [ ] 다크모드 전환 정상
- [ ] 브라우저 콘솔에 CSP 오류 없음

---

### Phase 3: 대형 페이지 - operation/collectionOpTag.html
**Goal**: 두 번째 대형 페이지 완료
**Status**: ⏳ Pending

#### Tasks

**🆕 신규 코드 작성**
- [ ] **Create 3.1**: 외부 JS 파일 생성
    - File: `src/main/resources/static/js/page/operation/collectionOpTag.js`

**✏️ 기존 코드 수정**
- [ ] **Modify 3.2**: HTML 파일 수정
    - File: `src/main/resources/templates/pages/operation/collectionOpTag.html`
    - Lines: 410-965
    - Change: 인라인 스크립트 제거, 외부 JS 로드

#### Quality Gate ✋

**Manual Testing**:
- [ ] 운전정보 수집 설정 페이지 정상 동작
- [ ] 브라우저 콘솔에 CSP 오류 없음

---

### Phase 4: 중형 페이지 (5개)
**Goal**: 중형 인라인 스크립트 파일 완료
**Status**: ⏳ Pending

#### Tasks
- [ ] detection/policySetting.html
- [ ] operation/alarmList.html
- [ ] policy/switchPolicy.html
- [ ] setting/topology-net.html
- [ ] user/list.html

#### Quality Gate ✋
- [ ] 각 페이지 기능 정상 동작
- [ ] 브라우저 콘솔에 CSP 오류 없음

---

### Phase 5: 소형 페이지 (4개)
**Goal**: 나머지 소형 인라인 스크립트 파일 완료
**Status**: ⏳ Pending

#### Tasks
- [ ] asset/topology-physical-detail-fragment.html
- [ ] asset/reg.html
- [ ] analysis/timeseries2.html
- [ ] user/changePassword.html (독립페이지 - 별도 처리)

#### Quality Gate ✋
- [ ] 각 페이지 기능 정상 동작

---

### Phase 6: nonce만 추가 (25개)
**Goal**: 인라인 없는 파일들 nonce 추가
**Status**: ⏳ Pending

#### Tasks
- [ ] 각 HTML 파일의 `<script>` 태그에 `th:nonce="${nonce}"` 추가

#### Quality Gate ✋
- [ ] 모든 페이지 정상 동작

---

## ⚠️ Risk Assessment

| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|---------------------|
| JS 추출 시 변수 참조 오류 | Medium | High | 서버 데이터 인라인 유지, 나머지만 추출 |
| SRI 해시 불일치 | Low | High | generate-sri.sh 재실행 |
| 기존 기능 regression | Medium | High | Phase별 Quality Gate 검증 |

---

## 🔄 Rollback Strategy

### If Any Phase Fails
1. Git에서 해당 파일 변경사항 되돌리기
2. sri.properties 원복
3. 빌드 재실행

---

## 📊 Progress Tracking

### Completion Status
- **Phase 1 (소형 연습)**: ⏳ 0%
- **Phase 2 (dashboard)**: ⏳ 0%
- **Phase 3 (collectionOpTag)**: ⏳ 0%
- **Phase 4 (중형 5개)**: ⏳ 0%
- **Phase 5 (소형 4개)**: ⏳ 0%
- **Phase 6 (nonce만 25개)**: ⏳ 0%

**Overall Progress**: 0% complete (0/37 파일)

---

## 📝 Notes & Learnings

### Implementation Notes
- loadLicenseKey는 global utils.js에 이미 있으므로 중복 정의 불필요
- default.html의 #pageMessage에서 메시지 가져오기
- PageConfig IIFE 패턴 사용

### Blockers Encountered
- (작업 중 기록)

---

## 📚 References

### Documentation
- `.claude/docs/inline-script-extraction.md`
- `.claude/docs/security.md`

---

## ✅ Final Checklist

**Before marking plan as COMPLETE**:
- [ ] 모든 37개 파일 nonce 적용 완료
- [ ] 브라우저 콘솔에 CSP 오류 없음
- [ ] 모든 페이지 기능 정상 동작
- [ ] SRI 해시 최신화 완료

---

**Plan Status**: 🔄 In Progress
**Next Action**: Phase 1 - data/node.html 작업 시작
**Blocked By**: None