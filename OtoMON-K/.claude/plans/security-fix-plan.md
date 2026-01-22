# OtoMON-K 보안 취약점 수정 플랜

## 개요
보안 분석 결과 발견된 CVE 취약점 및 설정 누락 사항을 단계별로 수정합니다.

---

## Phase 1: Tomcat CVE 취약점 수정 (긴급)

### 1.1 Tomcat 버전 업그레이드

**파일**: `pom.xml` (라인 32)

**현재 상태**:
```xml
<tomcat.version>10.1.34</tomcat.version>
```

**수정 내용**:
```xml
<tomcat.version>10.1.40</tomcat.version>
```

**해결되는 CVE**:
- CVE-2025-24813 (CVSS 9.8 Critical) - RCE via partial PUT
- Integer Overflow DoS - 멀티파트 업로드
- CVE-2025-55752 - Directory Traversal
- CVE-2025-55754 - Log Injection

**검증 방법**:
```bash
mvnw.cmd dependency:tree | findstr tomcat
# 결과에 10.1.40 버전 확인
```

---

## Phase 2: 멀티파트 업로드 보안 설정

### 2.1 파일 크기 제한 추가

**파일**: `src/main/resources/application.properties`

**추가 위치**: 파일 끝 또는 적절한 위치

**추가 내용**:
```properties
# Multipart Upload Security Settings
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
spring.servlet.multipart.file-size-threshold=2MB
```

**영향받는 기능**:
- `AssetController.java:718` - Excel 파일 업로드

**검증 방법**:
1. 애플리케이션 실행
2. 10MB 초과 파일 업로드 시도
3. 413 Payload Too Large 에러 확인

---

## Phase 3: ClickHouse JDBC 업그레이드 (권장)

### 3.1 clickhouse-jdbc 버전 업그레이드

**파일**: `pom.xml` (라인 220-225)

**현재 상태**:
```xml
<dependency>
    <groupId>com.clickhouse</groupId>
    <artifactId>clickhouse-jdbc</artifactId>
    <version>0.4.6</version>
</dependency>
```

**수정 내용**:
```xml
<dependency>
    <groupId>com.clickhouse</groupId>
    <artifactId>clickhouse-jdbc</artifactId>
    <version>0.7.1</version>
</dependency>
```

> 주의: 0.9.6은 breaking change 가능성이 있으므로 0.7.1 권장 (안정 버전)

**검증 방법**:
1. 빌드: `mvnw.cmd clean package -DskipTests`
2. 시계열 데이터 조회 기능 테스트
3. 대시보드 위젯 데이터 로딩 확인

---

## Phase 4: security.md 문서 업데이트

### 4.1 CSP 정책 섹션 수정

**파일**: `.claude/docs/security.md`

**수정 위치**: 라인 60-88 (## 2. CSP 섹션)

**수정 전** (라인 63-78):
```markdown
### 설정 위치
`config/SecurityConfig.java:106-117`

### 현재 정책
```java
.contentSecurityPolicy(csp -> csp.policyDirectives(
    "default-src 'self' blob: data:; " +
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' blob:; " +
    ...
))
```

**수정 후**:
```markdown
### 설정 위치
`filter/CspNonceFilter.java:42-53`

### 현재 정책 (Nonce 기반 동적 생성)
```java
private String buildCspPolicy(String nonce) {
    return "default-src 'self' blob: data:; " +
            "script-src 'nonce-" + nonce + "' 'strict-dynamic' 'self'; " +
            "style-src 'self' 'unsafe-inline' blob:; " +
            "img-src 'self' data: blob: https:; " +
            "font-src 'self' data: blob:; " +
            "connect-src 'self' ws: wss: blob: https:; " +
            "worker-src 'self' blob:; " +
            "child-src 'self' blob:; " +
            "frame-ancestors 'self'; " +
            "object-src 'none'";
}
```
```

### 4.2 CSP 설명 테이블 수정

**수정 위치**: 라인 82-87

**수정 전**:
```markdown
| `script-src` | `'self' 'unsafe-inline' 'unsafe-eval'` | AG Grid 등 동적 스크립트 허용 |
```

**수정 후**:
```markdown
| `script-src` | `'nonce-{random}' 'strict-dynamic' 'self'` | Nonce 기반 인라인 스크립트만 허용, 외부 스크립트 차단 |
```

### 4.3 Nonce 메커니즘 섹션 추가

**추가 위치**: ## 2. CSP 섹션 끝 (라인 88 이후)

**추가 내용**:
```markdown
### Nonce 생성 메커니즘

**구현 파일**:
| 파일 | 역할 |
|------|------|
| `filter/CspNonceFilter.java` | 요청마다 SecureRandom 16바이트 nonce 생성 |
| `config/CspNonceAdvice.java` | @ModelAttribute로 모든 뷰에 nonce 주입 |
| `layouts/default.html:15-16` | Meta 태그로 클라이언트에 nonce 노출 |

**템플릿 적용 현황**:
- 39개 템플릿 파일에서 102회 `th:nonce="${nonce}"` 적용
- 모든 `<script>` 태그에 nonce 필수

**작동 원리**:
1. CspNonceFilter가 매 요청마다 고유 nonce 생성
2. CSP 헤더에 `script-src 'nonce-{값}'` 포함
3. Thymeleaf가 `<script th:nonce="${nonce}">` 렌더링
4. 브라우저가 nonce 값 일치 여부 검증 후 스크립트 실행
```

---

## Phase 5: CLAUDE.md 보안 체크리스트 업데이트

### 5.1 Resolved 섹션에 Tomcat CVE 추가

**파일**: `.claude/CLAUDE.md`

**수정 위치**: Security Checklist > Resolved 테이블

**추가 내용**:
```markdown
| Tomcat CVE-2025-24813 | 10.1.40 버전 업그레이드 (2026-01-22) |
| 멀티파트 Integer Overflow | 파일 크기 제한 설정 |
```

### 5.2 Remaining Issues 업데이트

**수정 위치**: Security Checklist > Remaining Issues 테이블

**수정 내용**:
```markdown
| 취약한 구성 요소 (Tomcat CVE) | ~~61~~ 0 | ~~High~~ Resolved |
```

---

## 수정 순서 요약

| 순서 | 파일 | 작업 | 우선순위 |
|------|------|------|----------|
| 1 | `pom.xml` | Tomcat 10.1.40 업그레이드 | 긴급 |
| 2 | `application.properties` | 멀티파트 설정 추가 | 긴급 |
| 3 | `pom.xml` | clickhouse-jdbc 0.7.1 업그레이드 | 권장 |
| 4 | `.claude/docs/security.md` | CSP 문서 업데이트 | 보통 |
| 5 | `.claude/CLAUDE.md` | 체크리스트 업데이트 | 보통 |

---

## 검증 체크리스트

- [ ] Phase 1: `mvnw.cmd dependency:tree | findstr tomcat` → 10.1.40 확인
- [ ] Phase 2: 대용량 파일 업로드 거부 테스트
- [ ] Phase 3: 시계열 데이터 조회 정상 동작 확인
- [ ] Phase 4: security.md 문서 CSP 섹션 확인
- [ ] Phase 5: CLAUDE.md 체크리스트 확인
- [ ] 전체: `mvnw.cmd clean package -DskipTests` 빌드 성공
- [ ] 전체: 애플리케이션 기동 후 로그인/대시보드 테스트
