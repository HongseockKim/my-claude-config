# Implementation Plan: [Feature Name]

**Status**: 🔄 In Progress
**Started**: YYYY-MM-DD
**Last Updated**: YYYY-MM-DD
**Estimated Completion**: YYYY-MM-DD

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

## 📊 Codebase Analysis (계획 전 필수)

### Frontend Structure
| Component | Location | Purpose |
|-----------|----------|---------|
| [Page/Component] | [Path] | [Description] |

### Backend Structure
| Layer | Class | Location |
|-------|-------|----------|
| Controller | [Name] | [Path] |
| Service | [Name] | [Path] |
| Repository | [Name] | [Path] |

### Connection Map
| Frontend | API Endpoint | Backend Handler |
|----------|--------------|-----------------|
| [File:Line] | [Method /path] | [Controller.method()] |

### Impact Analysis
- **영향받는 파일**: [List]
- **작업 유형**: 🆕 신규 작성 / ✏️ 기존 수정

---

## 📋 Overview

### Feature Description
[What this feature does and why it's needed]

### Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### User Impact
[How this benefits users or improves the product]

---

## 🏗️ Architecture Decisions

| Decision | Rationale | Trade-offs |
|----------|-----------|------------|
| [Decision 1] | [Why this approach] | [What we're giving up] |
| [Decision 2] | [Why this approach] | [What we're giving up] |

---

## 📦 Dependencies

### Required Before Starting
- [ ] Dependency 1: [Description]
- [ ] Dependency 2: [Description]

### External Dependencies
- Package/Library 1: version X.Y.Z
- Package/Library 2: version X.Y.Z

---

## 🚀 Implementation Phases

### Phase 1: [Foundation Phase Name]
**Goal**: [Specific working functionality this phase delivers]
**Estimated Time**: X hours
**Status**: ⏳ Pending | 🔄 In Progress | ✅ Complete

#### Tasks

**✏️ 기존 코드 수정** (AI → 라인+요약, 사용자 → 직접 수정)
- [ ] **Modify 1.1**: [수정 내용]
    - File: `src/[path]/[file]`
    - Lines: [시작]-[끝]
    - Change: [변경 요약]

**🆕 신규 코드 작성** (AI → 전체 코드 제공, 사용자 → 파일 생성)
- [ ] **Create 1.2**: [생성할 내용]
    - File: `src/[path]/[file]`
    - Details: [전체 코드 제공됨]

- [ ] **Task 1.3**: Code cleanup & refactoring
    - Files: Review all new code in this phase
    - Checklist:
        - [ ] Remove duplication (DRY principle)
        - [ ] Improve naming clarity
        - [ ] Add inline documentation

#### Quality Gate ✋

**⚠️ STOP: Do NOT proceed to Phase 2 until ALL checks pass**

**Build & Code Quality**:
- [ ] **Build**: Project compiles without errors
- [ ] **Lint**: No linting errors or warnings
- [ ] **No Regression**: Existing functionality works

**Manual Testing**:
- [ ] **Functionality**: Feature works as expected
- [ ] **Edge Cases**: Boundary conditions verified
- [ ] **Error Handling**: Error states handled properly

**Validation Commands**:
```bash
# Build
./mvnw clean compile

# Code Quality (if configured)
./mvnw checkstyle:check
```

**Manual Test Checklist**:
- [ ] Test case 1: [Specific scenario to verify]
- [ ] Test case 2: [Edge case to verify]
- [ ] Test case 3: [Error handling to verify]

---

### Phase 2: [Core Feature Phase Name]
**Goal**: [Specific deliverable]
**Estimated Time**: X hours
**Status**: ⏳ Pending | 🔄 In Progress | ✅ Complete

#### Tasks

**✏️ 기존 코드 수정** (AI → 라인+요약, 사용자 → 직접 수정)
- [ ] **Modify 2.1**: [수정 내용]
    - File: `src/[path]/[file]`
    - Lines: [시작]-[끝]
    - Change: [변경 요약]

**🆕 신규 코드 작성** (AI → 전체 코드 제공, 사용자 → 파일 생성)
- [ ] **Create 2.2**: [생성할 내용]
    - File: `src/[path]/[file]`
    - Details: [전체 코드 제공됨]

- [ ] **Task 2.3**: Code cleanup & refactoring
    - Files: Review all new code in this phase
    - Checklist:
        - [ ] Remove duplication (DRY principle)
        - [ ] Improve naming clarity
        - [ ] Add inline documentation

#### Quality Gate ✋

**⚠️ STOP: Do NOT proceed to Phase 3 until ALL checks pass**

**Build & Code Quality**:
- [ ] **Build**: Project compiles without errors
- [ ] **Lint**: No linting errors or warnings
- [ ] **No Regression**: Existing functionality works

**Manual Testing**:
- [ ] **Functionality**: Feature works as expected
- [ ] **Edge Cases**: Boundary conditions verified
- [ ] **Error Handling**: Error states handled properly

**Validation Commands**:
```bash
# Build
./mvnw clean compile

# Code Quality (if configured)
./mvnw checkstyle:check
```

**Manual Test Checklist**:
- [ ] Test case 1: [Specific scenario to verify]
- [ ] Test case 2: [Edge case to verify]
- [ ] Test case 3: [Error handling to verify]

---

### Phase 3: [Enhancement Phase Name]
**Goal**: [Specific deliverable]
**Estimated Time**: X hours
**Status**: ⏳ Pending | 🔄 In Progress | ✅ Complete

#### Tasks

**✏️ 기존 코드 수정** (AI → 라인+요약, 사용자 → 직접 수정)
- [ ] **Modify 3.1**: [수정 내용]
    - File: `src/[path]/[file]`
    - Lines: [시작]-[끝]
    - Change: [변경 요약]

**🆕 신규 코드 작성** (AI → 전체 코드 제공, 사용자 → 파일 생성)
- [ ] **Create 3.2**: [생성할 내용]
    - File: `src/[path]/[file]`
    - Details: [전체 코드 제공됨]

- [ ] **Task 3.3**: Code cleanup & refactoring
    - Files: Review all new code in this phase
    - Checklist:
        - [ ] Remove duplication (DRY principle)
        - [ ] Improve naming clarity
        - [ ] Add inline documentation

#### Quality Gate ✋

**⚠️ STOP: Do NOT proceed until ALL checks pass**

**Build & Code Quality**:
- [ ] **Build**: Project compiles without errors
- [ ] **Lint**: No linting errors or warnings
- [ ] **No Regression**: Existing functionality works

**Manual Testing**:
- [ ] **Functionality**: Feature works as expected
- [ ] **Edge Cases**: Boundary conditions verified
- [ ] **Error Handling**: Error states handled properly

**Validation Commands**:
```bash
# Build
./mvnw clean compile

# Code Quality (if configured)
./mvnw checkstyle:check
```

**Manual Test Checklist**:
- [ ] Test case 1: [Specific scenario to verify]
- [ ] Test case 2: [Edge case to verify]
- [ ] Test case 3: [Error handling to verify]

---

## ⚠️ Risk Assessment

| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|---------------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [Mitigation steps] |
| [Risk 2] | Low/Med/High | Low/Med/High | [Mitigation steps] |

---

## 🔄 Rollback Strategy

### If Phase 1 Fails
- Undo code changes in: [list files]
- Restore configuration: [specific settings]

### If Phase 2 Fails
- Restore to Phase 1 complete state
- Undo changes in: [list files]

### If Phase 3 Fails
- Restore to Phase 2 complete state
- [Additional cleanup steps]

---

## 📊 Progress Tracking

### Completion Status
- **Phase 1**: ⏳ 0%
- **Phase 2**: ⏳ 0%
- **Phase 3**: ⏳ 0%

**Overall Progress**: 0% complete

### Time Tracking
| Phase | Estimated | Actual | Variance |
|-------|-----------|--------|----------|
| Phase 1 | X hours | - | - |
| Phase 2 | X hours | - | - |
| Phase 3 | X hours | - | - |
| **Total** | X hours | - | - |

---

## 📝 Notes & Learnings

### Implementation Notes
- [Add insights discovered during implementation]
- [Document decisions that deviate from original plan]

### Blockers Encountered
- **Blocker 1**: [Description] → [Resolution]

### Improvements for Future
- [What would you do differently?]

---

## 📚 References

### Documentation
- [Link to relevant docs]
- [Link to API references]

### Related Issues
- Issue #X: [Description]

---

## ✅ Final Checklist

**Before marking plan as COMPLETE**:
- [ ] All phases completed with quality gates passed
- [ ] Manual integration testing performed
- [ ] Documentation updated
- [ ] No regressions in existing functionality
- [ ] Code reviewed (if applicable)

---

**Plan Status**: 🔄 In Progress
**Next Action**: [What needs to happen next]
**Blocked By**: [Any current blockers] or None
