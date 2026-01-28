# OtoMON-K - 삼천포발전소 산업용 모니터링 시스템

## Tech Stack
- **Backend**: Java 17, Spring Boot 3.4.5, JPA, QueryDSL 5.x
- **Frontend**: Thymeleaf, AG Grid Enterprise, ECharts
- **DB**: MariaDB (메타데이터), ClickHouse (시계열)
- **Realtime**: WebSocket (STOMP)

## Quick Start
```bash
mvnw.cmd spring-boot:run -DskipTests  # 실행
mvnw.cmd clean package -DskipTests    # 빌드
# http://localhost:8080 (admin / qwe123!@#)
```

## 핵심 규칙

| # | Rule |
|---|------|
| 1 | ORM은 JPA만 (MyBatis 금지) |
| 2 | DI는 `@RequiredArgsConstructor` (`@Autowired` 금지) |
| 3 | 응답 형식: `{ "ret": 0, "message": "성공", "data": {...} }` |
| 4 | 모든 `<script>`에 `th:nonce="${nonce}"` 필수 |
| 5 | Entity CRUD 시 `.claude/docs/audit-log-system.md` 참조 |

## Agent Role
- **Claude = 가이드** (코드 수정은 사용자가 직접)
- 기존 로직 흐름 파악 필수
- 기존 코드 수정 → git diff 형식으로 제시 (`빨간색` 삭제, `초록색` 추가)
- Search 보다 mcp 가 더 정확하면 mcp 적극 활용
- 새 코드 작성 → 전체 코드 제공
- 플랜 파일 위치: `.claude/plans/`

### 코드 변경 제시 형식
```diff
### 파일명:라인번호 (메서드명)
- 삭제되는 코드
+ 추가되는 코드
```

## 작업 Flow
```
[DB] → [Repository] → [Service] → [Controller] → [JS] → [HTML]
```
**Before Planning**: Frontend/Backend 전체 연결 로직 분석 먼저

## 문서 찾기

| 카테고리 | 문서 위치 |
|---------|----------|
| 프로젝트 구조 | `.claude/docs/architecture.md` |
| 보안 관련 | `.claude/docs/security.md` |
| 프론트엔드 패턴 | `.claude/docs/frontend-patterns.md` |
| DB/JPA/ClickHouse | `.claude/docs/database.md` |
| 개발 워크플로우 | `.claude/docs/development-workflow.md` |
| **전체 문서 목록** | `.claude/references/doc-index.md` |

## Security Status (2026-01-15)

**✅ Resolved**: CSP, SRI, CORS, Rate Limit, WebSocket 보안, HTTPS, Referrer-Policy, Tomcat CVE

**⚠️ Remaining**:
- API 대량 할당 (6건) - Medium
- 내부 IP 노출 (12건) - Low
- 계정 잠금 정책 (1건) - Medium

## QueryDSL 요약
- **Config**: `config/QueryDslConfig.java`
- **구조**: `repository/Impl/{Entity}/{Entity}RepositoryImpl.java`
- **주의**: Boolean 필드는 `Boolean.TRUE.equals()` 사용
- **Q클래스**: `mvn compile` 시 자동 생성

## MCP 활용

| 상황 | 사용할 MCP |
|------|-----------|
| DB 질문/스키마 확인 | `mariadb` |
| 복잡한 분석/디버깅 | `sequential-thinking` |
| 컨텍스트 저장 | `memory` |
| 웹 테스트 | `puppeteer` |

## Context
- **호기**: 3호기, 4호기 (system_config 테이블)
- **목적**: 실시간 자산/네트워크 모니터링, 알람/이상탐지
- **보안 스캔**: HCL AppScan Standard 10.8.1
