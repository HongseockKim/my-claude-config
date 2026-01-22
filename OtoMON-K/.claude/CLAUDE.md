# CLAUDE.md

## Project Overview

**OtoMON-K** - 한국동서발전 삼천포발전소 산업용 모니터링 시스템

## Tech Stack

| Category | Technology |
|----------|------------|
| Backend | Java 17, Spring Boot 3.4.5, JPA |
| Frontend | Thymeleaf, AG Grid Enterprise, ECharts |
| Database | MariaDB (메타데이터), ClickHouse (시계열) |
| Realtime | WebSocket (STOMP) |
| Build | Maven |

## Quick Commands

```bash
# 개발 실행
mvnw.cmd spring-boot:run -DskipTests

# 빌드
mvnw.cmd clean package -DskipTests

# 로컬 접속
http://localhost:8080
admin / qwe123!@#
```

---

## Agent Rules

### Role Definition

> **Claude는 가이드 역할. 코드 수정은 사용자가 직접 수행.**

### Code Suggestion Format

```
✅ DO:
- 변경/추가/삭제 부분만 주석으로 마킹
- Java 문법 설명 포함 (왜 이렇게 쓰는지)

❌ DON'T:
- 변경 없는 기존 코드 전체 나열
- 단순 import문 나열
```

### Development Flow

```
[DB] → [Repository] → [Service] → [Controller] → [JS] → [HTML]
```

### Core Conventions

| Rule | Description |
|------|-------------|
| ORM | JPA만 사용 (MyBatis 금지) |
| DI | `@RequiredArgsConstructor` (`@Autowired` 금지) |
| Response | `{ "ret": 0, "message": "성공", "data": {...} }` |
| Audit | Entity CRUD 시 `.claude/docs/audit-log-system.md` 참조 |
| Script Tag | 모든 `<script>` 태그에 `th:nonce="${nonce}"` 필수 |

---

### Plan File Location

> **플랜 파일은 프로젝트 내 `.claude/plans/` 폴더에 작성**
> - 전역 `~/.claude/` 가 아닌 IntelliJ 프로젝트의 `.claude/plans/` 사용
> - 예: `C:\Users\user\IdeaProjects\OtoMON-K\.claude\plans\{plan-name}.md`

### Script Tag Security (CSP Nonce)

> **모든 `<script>` 태그에 `th:nonce="${nonce}"` 필수 적용**

  ```html
  <!-- ✅ 올바른 예시 -->
  <script th:nonce="${nonce}" th:src="@{/js/example.js}"></script>
  <script th:nonce="${nonce}" th:inline="javascript">
      // 서버 값 전달
  </script>

  <!-- ❌ 잘못된 예시 (nonce 누락) -->
  <script th:src="@{/js/example.js}"></script>

  - CSP strict-dynamic 정책 적용됨
  - nonce 없으면 스크립트 차단됨
  - 참조: .claude/docs/security.md

---

### Code Modification Rules

| 작업 유형 | AI 역할 | 사용자 역할 |
|-----------|---------|-------------|
| ✏️ 기존 코드 수정 | 라인 번호 + Before/After | 직접 수정 |
| 🆕 새 코드 작성 | 전체 코드 제공 | 파일 생성 후 붙여넣기 |

### Before Planning (필수)
- Frontend/Backend 전체 연결 로직 분석 먼저
- Connection Map 작성 후 계획 수립

## Security Checklist

### ✅ Resolved (2026-01-15 기준)

| 취약점 | 조치 내용 |
|--------|----------|
| SRI 미적용 | 외부 스크립트 integrity 속성 추가 |
| CSP 헤더 누락 | Content-Security-Policy 헤더 설정 |
| CORS 정책 | 허용 Origin 화이트리스트 적용 |
| WebSocket 하이재킹 | Origin 검증 + CSRF 토큰 |
| Rate Limit 부재 | API 요청 제한 구현 |
| 호스트 헤더 인젝션 | 허용 호스트 검증 |
| 암호화되지 않은 로그인 | HTTPS 강제 적용 |
| Referrer-Policy 누락 | strict-origin-when-cross-origin 설정 |
| XPath 인젝션 | 파라미터 바인딩 적용 |
| CSP strict-dynamic | 모든 `<script>` 태그에 `th:nonce="${nonce}"` 적용 |
| 스크립트 허용 목록 우회 | `'unsafe-inline'`, `'unsafe-eval'` 제거, nonce 기반 CSP 적용 (CspNonceFilter) |
| JavaScript 하이재킹 | AjaxOnlyInterceptor 확장 + ApiResponse 래핑 (2026-01-15) |
  | Tomcat CVE-2025-24813 | 10.1.40 버전 업그레이드 |
  | 멀티파트 Integer Overflow | 파일 크기 제한 설정 추가 |


### ⚠️ Remaining Issues

| 취약점 | 건수 | 우선순위 |
|--------|------|----------|
| 취약한 구성 요소 (Tomcat CVE) | 0 | Resolved |
| API 대량 할당 | 6 | Medium |
| 내부 IP 노출 | 12 | Low |
| 계정 잠금 정책 | 1 | Medium |

### Security Implementation Reference

```
.claude/docs/security.md → SRI, CSP, JWT, 암호화, Rate Limit
```

---

## Documentation Index

| When              | Read                                               |
|-------------------|----------------------------------------------------|
| 프로젝트 구조 파악        | `.claude/docs/architecture.md`                      |
| 세션/날짜/호기 작업       | `.claude/docs/interceptor-system.md`                |
| 권한 체크             | `.claude/docs/permission-system.md`                 |
| 날짜/호기 필터링         | `.claude/docs/session-filtering.md`                 |
| JPA, ClickHouse   | `.claude/docs/database.md`                          |
| AJAX, AG Grid, WS | `.claude/docs/frontend-patterns.md`                 |
| 새 API/페이지 추가      | `.claude/docs/development-workflow.md`              |
| Zone3Util 등       | `.claude/docs/utils.md`                             |
| 대시보드 위젯           | `.claude/docs/dashboard-widget-system.md`           |
| Entity CRUD 감사    | `.claude/docs/audit-log-system.md`                  |
| 보안 관련             | `.claude/docs/security.md`                          |
| 로그인/로그아웃/비밀번호     | `.claude/docs/authentication-system.md`             |
| 엑셀 다운로드           | `.claude/docs/excel-download-system.md`             |
| 자산현황 페이지          | `.claude/docs/asset-operation-spec.md`              |
| 물리 토폴로지           | `.claude/docs/topology-physical-system.md`          |
| 자산별 트래픽 현황        | `.claude/docs/traffic-asset-system.md`              |
| 화이트리스트 위반 현황      | `.claude/docs/detection-connection-system.md`       |
| 이상 이벤트 탐지 현황      | `.claude/docs/detection-timesdata-system.md`        |
| 시계열 이종 데이터 분석     | `.claude/docs/detection-timesereise-system.md`      |
| 분석 및 조치 이력        | `.claude/docs/detection-analysis-action-system.md`  |
| 운전정보              | `.claude/docs/data-operation-system.md`             |
| 세션                | `.claude/docs/data-session-system.md`               |
| 시스템 리소스 현황        | `.claude/docs/data-system-resource-system.md`       |
| 세션 화이트리스트 정책      | `.claude/docs/policy-session-white-system.md`       |
| 시계열 정책            | `.claude/docs/policy-timeseries-system.md`          |
| 금지 서비스 포트 관리      | `.claude/docs/policy-service-port-system.md`        |
| 통계 및 리포트 생성       | `.claude/docs/analysis-report-add-system.md`        |
| 메뉴관리              | `.claude/docs/setting-menu-system.md`               |
| 코드관리              | `.claude/docs/setting-code-system.md`               |
| 감사로그 설정           | `.claude/docs/setting-audit-system.md`              |
| 알람 설정             | `.claude/docs/setting-alarm-system.md`              |
| 스위치 관리            | `.claude/docs/setting-topology-switch-system.md`    |
| 시스템 설정            | `.claude/docs/setting-system-config-system.md`      |
| 사용자 관리            | `.claude/docs/setting-user-list-system.md`          |
| 운전정보 수집 설정        | `.claude/docs/setting-collection-op-tag-system.md`  |
| 감사로그 목록           | `.claude/docs/setting-audit-list-system.md`         |
| 알람 리스트            | `.claude/docs/setting-alarm-list-system.md`         |
| 대시보드 템플릿 관리       | `.claude/docs/setting-dashboard-template-system.md` |
| 그룹 관리             | `.claude/docs/setting-group-list-system.md`         |
| 마리아 스키마           | `.claude/docs/skima.sql`                            |
| **쿼리 최적화**        | `.claude/docs/query-optimization.md`                |
| **인라인 스크립트 외부 추출** | `.claude/docs/inline-script-extraction.md`          |

---

## Context

- **호기**: 3호기, 4호기 (system_config 테이블 참조)
- **목적**: 실시간 자산/네트워크 모니터링, 알람/이상탐지 이벤트 처리
- **보안 스캔**: HCL AppScan Standard 10.8.1
- **최근 스캔**: 2025-12-17 (110건, 이전 168건에서 58건 감소)


## MCP 활용 가이드

### 1. mariadb - DB 작업 시
```
"User 테이블 스키마 보여줘"
"asset 테이블에서 최근 등록된 자산 10개 조회해줘"
"이 Entity랑 실제 DB 스키마 맞는지 확인해줘"
```

### 2. sequential-thinking - 복잡한 분석 시
```
"SecurityConfig 코드 단계별로 분석해줘"
"이 에러 원인 순차적으로 파악해줘"
"새 API 추가할 때 필요한 작업 단계별로 정리해줘"
```

### 3. memory - 컨텍스트 유지
```
"이 내용 기억해줘: Rate Limit은 분당 60회"
"아까 분석한 보안 이슈 뭐였지?"
```

### 4. puppeteer - 웹 테스트
```
"dev.otoones.com:9090 접속해서 로그인 페이지 스크린샷 찍어줘"
"대시보드 페이지 로딩 속도 테스트해줘"
```
```

---

## Agent Rules

### Role Definition
Claude는 가이드 역할. 코드 수정은 사용자가 직접 수행.

### MCP 필수 사용 규칙 ⚠️
1. **DB 질문** → mariadb MCP로 실제 조회 (추측 금지)
2. **복잡한 분석** → sequential-thinking 사용
3. **"기억해줘"** → memory에 저장
4. **Entity 검증** → mariadb로 실제 스키마 비교

### Code Suggestion Format
...
```

---

### 또는 직접 요청할 때 명시
```
"mariadb MCP 써서 User 테이블 구조 보여줘"
"sequential-thinking으로 이 에러 분석해줘"