---
name: feature-planner
description: Creates phase-based feature plans with quality gates. Use when planning features, organizing work, breaking down tasks. Keywords: plan, planning, phases, breakdown, strategy, roadmap, organize.
---

# Feature Planner (No Test Version)

## Purpose
Generate structured, phase-based plans where:
- Each phase delivers complete, runnable functionality
- Quality gates enforce validation before proceeding
- User approves plan before any work begins
- Progress tracked via markdown checkboxes
- Each phase is 1-4 hours maximum

## Code Modification Rules

### 🔧 기존 코드 수정 시
**AI는 직접 수정하지 않음.** 대신:
- 변경할 파일과 라인 번호 명시
- 변경 내용 요약 설명
- Before/After 형태로 제시

**출력 형식**:
```
📁 파일: src/main/java/com/example/UserController.java
📍 라인: 45-52
📝 변경: userId 파라미터 검증 로직 추가

[Before]
public User getUser(Long userId) {
    return userRepository.findById(userId);
}

[After]
public User getUser(Long userId) {
    if (userId == null || userId <= 0) {
        throw new IllegalArgumentException("Invalid userId");
    }
    return userRepository.findById(userId);
}
```

### ✨ 새 코드 작성 시
**AI가 전체 코드를 제공, 사용자가 직접 파일 생성**:
- 파일 경로 명시
- 전체 코드 제공 (요약 X, 복붙 가능한 완성 코드)
- 사용자가 직접 파일 생성 후 붙여넣기

**출력 형식**:
```
📁 새 파일: src/main/java/com/example/validator/UserValidator.java

[전체 코드]
package com.example.validator;

import org.springframework.stereotype.Component;

@Component
public class UserValidator {
    
    public boolean isValid(Long userId) {
        return userId != null && userId > 0;
    }
    
    public void validate(Long userId) {
        if (!isValid(userId)) {
            throw new IllegalArgumentException("Invalid userId: " + userId);
        }
    }
}
```

---

## Planning Workflow

### Step 0: Codebase Analysis (MANDATORY)
**⚠️ 계획 세우기 전 필수 수행**

**Frontend 분석**:
1. 페이지/컴포넌트 구조 파악
2. API 호출 위치 및 방식 확인
3. 상태 관리 흐름 파악
4. 라우팅 구조 확인

**Backend 분석**:
1. Controller → Service → Repository 흐름 파악
2. Entity/DTO 구조 확인
3. API 엔드포인트 목록 정리
4. 설정 파일 확인 (application.yml 등)

**연결 로직 분석**:
1. Frontend ↔ Backend API 매핑
2. 데이터 흐름 (Request → Response)
3. 인증/권한 처리 방식
4. 에러 핸들링 방식

**분석 결과 출력 형식**:
```
## 📊 Codebase Analysis Report

### Frontend Structure
- Pages: [목록]
- API Calls: [파일:라인 → 엔드포인트]
- State Management: [방식]

### Backend Structure  
- Controllers: [목록]
- Services: [목록]
- Repositories: [목록]

### Connection Map
| Frontend | API Endpoint | Backend Handler |
|----------|--------------|-----------------|
| UserList.html:25 | GET /api/users | UserController.getUsers() |
| ...

### Impact Analysis
- 영향받는 파일: [목록]
- 수정 필요 여부: [신규/수정]
```

### Step 1: Requirements Analysis
1. Read relevant files to understand codebase architecture
2. Identify dependencies and integration points
3. Assess complexity and risks
4. Determine appropriate scope (small/medium/large)

### Step 2: Phase Breakdown
Break feature into 3-7 phases where each phase:
- Delivers working functionality
- Takes 1-4 hours maximum
- Can be rolled back independently
- Has clear success criteria
- Has manual test scenarios

**Phase Structure**:
- Phase Name: Clear deliverable
- Goal: What working functionality this produces
- Tasks: Implementation steps with file locations
- Quality Gate: Build + manual testing validation
- Dependencies: What must exist before starting

### Step 3: Plan Document Creation
Use plan-template.md to generate: `docs/plans/PLAN_<feature-name>.md`

Include:
- Overview and objectives
- Architecture decisions with rationale
- Complete phase breakdown with checkboxes
- Quality gate checklists (build + manual testing)
- Risk assessment table
- Rollback strategy per phase
- Progress tracking section

### Step 4: User Approval
**CRITICAL**: Get explicit approval before proceeding.

Ask:
- "Does this phase breakdown make sense?"
- "Any concerns about the approach?"
- "Should I proceed with creating the plan?"

Only create plan document after user confirms.

### Step 5: Document Generation
1. Create `docs/plans/` directory if not exists
2. Generate plan document with all checkboxes unchecked
3. Inform user of plan location and next steps

## Quality Gate Standards (No Tests)

Each phase MUST validate before proceeding:

**Build & Compilation**:
- [ ] Project builds/compiles without errors
- [ ] No syntax errors

**Code Quality**:
- [ ] Linting passes (if configured)
- [ ] Code formatting consistent
- [ ] No obvious code smells

**Manual Testing**:
- [ ] Feature works as expected
- [ ] No regressions in existing functionality
- [ ] Edge cases manually verified
- [ ] Error handling works

**Documentation**:
- [ ] Code comments for complex logic
- [ ] README updated if needed

## Phase Sizing Guidelines

**Small Scope** (2-3 phases, 3-6 hours total):
- Single component or simple feature
- Minimal dependencies
- Example: Add new form field, create simple widget

**Medium Scope** (4-5 phases, 8-15 hours total):
- Multiple components
- Some integration complexity
- Example: New dashboard page, API endpoint with UI

**Large Scope** (6-7 phases, 15-25 hours total):
- Complex feature spanning multiple areas
- Significant architectural impact
- Example: Permission system, real-time monitoring

## Validation Commands (Java/Spring Boot)

```bash
# Build
./mvnw clean compile

# Full build with packaging
./mvnw clean package -DskipTests

# Code Quality (if checkstyle configured)
./mvnw checkstyle:check

# Run application
./mvnw spring-boot:run
```

## Risk Assessment

For each risk, specify:
- **Probability**: Low/Medium/High
- **Impact**: Low/Medium/High
- **Mitigation**: Specific action steps

Common risks:
- Database schema changes
- API breaking changes
- Performance impact
- Security implications

## Rollback Strategy

For each phase, document:
- What code changes to undo
- Database migrations to reverse (if any)
- Configuration to restore

## Supporting Files
- plan-template.md - Complete plan document template
