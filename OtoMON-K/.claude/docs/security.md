# 보안 시스템 가이드

OtoMON-K 프로젝트의 보안 구현 상세 문서

---

## 1. SRI (Subresource Integrity)

### 개요
외부 스크립트 파일의 무결성을 검증하여 CDN 변조 공격을 방지합니다.

### 구성 파일
| 파일 | 설명 |
|------|------|
| `config/SriProperties.java` | SRI 해시 값 로딩 |
| `config/SriControllerAdvice.java` | 템플릿에 `sri` 객체 전달 |
| `resources/sri.properties` | 각 JS 파일별 SHA-384 해시 (자동 생성) |
| `scripts/generate-sri.sh` | Linux/Mac용 해시 생성 스크립트 |
| `generate_sri.ps1` | Windows PowerShell용 해시 생성 스크립트 |

### 해시 자동 생성

**Linux/Mac (권장)**
```bash
./scripts/generate-sri.sh
```

**Windows PowerShell**
```powershell
.\generate_sri.ps1
```

스크립트 실행 시:
1. `src/main/resources/static/js/` 내 모든 JS 파일 해시 생성
2. WebJars (Maven 로컬 저장소)에서 jQuery, Bootstrap 등 해시 추출
3. `sri.properties` 파일 자동 갱신

### 사용 방법

**sri.properties**
```properties
sri.hashes.echarts_min_js=sha384-suNXQEmQcNBoAG5ahAPwciiuE9VNn0DH+...
sri.hashes.jquery_min_js=sha384-1H217gwSVyLSIfaLxHbE7dRb3v4mYCKbpQ...
```

**템플릿 (Thymeleaf)**
```html
<script th:src="@{/js/echarts.min.js}"
        th:integrity="${sri.getHash('echarts.min.js')}"
        crossorigin="anonymous"></script>
```

### 새 JS 파일 추가 시
1. 해시 생성: `openssl dgst -sha384 -binary 파일명.js | openssl base64 -A`
2. `sri.properties`에 추가 (파일명의 `.`은 `_`로 변환)
3. 템플릿에서 `th:integrity="${sri.getHash('파일명.js')}"` 사용

---

## 2. CSP (Content Security Policy)

### 설정 위치
`filter/CspNonceFilter.java:42-53`

### 현재 정책
```java
  // filter/CspNonceFilter.java
private String buildCspPolicy(String nonce) {
    return "default-src 'self' blob: data:; " +
            "script-src 'nonce-" + nonce + "' 'strict-dynamic' 'self'; " +
            "style-src 'self' 'unsafe-inline' blob:; " +
            "img-src 'self' data: blob: https:; " +
            "font-src 'self' data: blob:; " +
            "connect-src 'self' ws: wss: blob: https:; " +
            "worker-src 'self' blob:; " +
            "child-src 'self' blob:; " +
            "frame-src 'self'; " +
            "media-src 'self'; " +
            "manifest-src 'self'; " +
            "frame-ancestors 'self'; " +
            "object-src 'none'; " +
            "base-uri 'self'; " +
            "form-action 'self'; " +
            "upgrade-insecure-requests";
}
```
### 주요 설정 설명
| 지시자 | 값 | 설명 |
|--------|-----|------|
| `default-src` | `'self' blob: data:` | 기본 리소스 출처 |
| `script-src` | `'nonce-{random}' 'strict-dynamic' 'self'` | Nonce 기반 인라인 스크립트만 허용 |
| `frame-ancestors` | `'self'` | Clickjacking 방지 |
| `object-src` | `'none'` | Flash/플러그인 차단 |

---

## 3. HTTP 보안 헤더

### HSTS (HTTP Strict Transport Security)
```java
.httpStrictTransportSecurity(hsts ->
    hsts.includeSubDomains(true)
        .maxAgeInSeconds(31536000)  // 1년
)
```

### Referrer Policy
```java
.referrerPolicy(referrer -> referrer.policy(
    ReferrerPolicyHeaderWriter.ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN
))
```

### HTTPS 강제
```java
.requiresChannel(channel -> channel.anyRequest().requiresSecure())
```

### Cross-Origin Isolation (COEP/COOP)

**설정 위치**: `filter/CspNonceFilter.java:39-41`

```java
// Cross-Origin-Embedder-Policy: Spectre 등 사이드채널 공격 방어
response.setHeader("Cross-Origin-Embedder-Policy", "credentialless");

// Cross-Origin-Opener-Policy: 브라우징 컨텍스트 격리
response.setHeader("Cross-Origin-Opener-Policy", "same-origin-allow-popups");

// Cross-Origin-Resource-Policy: 리소스 로드 출처 제한
response.setHeader("Cross-Origin-Resource-Policy", "same-origin");

// Server 헤더 숨김: Tomcat 버전 정보 노출 방지
response.setHeader("Server", "");
```

| 헤더 | 값 | 설명 |
|------|-----|------|
| `COEP` | `credentialless` | 외부 리소스(CDN) 호환성 유지하며 격리 |
| `COOP` | `same-origin-allow-popups` | 같은 출처 + 팝업 허용 |
| `CORP` | `same-origin` | 같은 출처에서만 리소스 로드 허용 |
| `Server` | `""` (빈 값) | 서버 버전 정보 숨김 (CVE 스캔 회피) |

**옵션 설명**
- `COEP: require-corp` - 가장 엄격, 외부 CDN 사용 시 문제 발생
- `COEP: credentialless` - 자격증명 없이 교차출처 요청 허용 (권장)
- `COOP: same-origin` - 팝업 차단됨
- `COOP: same-origin-allow-popups` - 팝업 기능 유지 (권장)
- `CORP: same-origin` - 같은 출처만 허용 (권장)
- `CORP: same-site` - 서브도메인 포함 허용
- `CORP: cross-origin` - 모든 출처 허용 (CDN용)

---

## 4. Rate Limiting (요청 제한)

### 구성 파일
| 파일 | 설명 |
|------|------|
| `config/RateLimitConfig.java` | Bucket4j + Caffeine 캐시 설정 |
| `interceptor/RateLimitInterceptor.java` | 요청 제한 인터셉터 |

### 설정 값 (application.properties)
```properties
rate-limit.requests-per-minute=60
rate-limit.enabled=true
```

### 적용 경로
- `/data/api/**`
- `/api/**`
- `/login`
- `/user/changePassword`

### 응답 (한도 초과 시)
```json
{
  "ret": -1,
  "message": "요청 한도를 초과 했습니다.",
  "data": null
}
```
HTTP Status: `429 Too Many Requests`

---

## 5. AJAX Only Interceptor

### 파일
`interceptor/AjaxOnlyInterceptor.java`

### 목적
브라우저 직접 접근을 차단하고 AJAX 요청만 허용합니다.

### 검증 방식
```java
String requestedWith = request.getHeader("X-Requested-With");
String ajaxHeader = request.getHeader("AJAX");

if("XMLHttpRequest".equals(requestedWith) || "true".equals(ajaxHeader)) {
    return true;
}
```

### 적용 경로 (주요)
- `/menu/**`
- `/widget/**`
- `/zone/**`
- `/data/api/**`
- `/data/grid-data-systemResource`
- `/alarm-notification/**`
- `/detection/**`
- `/asset/grid-data-asset`
- `/asset/grid-data-topology-switch`
- `/asset/grid-data-topology-switch-optimized`
- `/topology-physical/**`

---

## 6. 암호화 시스템

### ARIA 암호화 (국산 암호 알고리즘)

**파일 구조**
| 파일 | 설명 |
|------|------|
| `util/crypto/AriaUtil.java` | ARIA 암/복호화 유틸리티 |
| `util/crypto/Aria256Coder.java` | ARIA-256 구현 |
| `security/AriaPasswordEncoder.java` | Spring Security 연동 |

**사용 예시**
```java
// 암호화
String encrypted = AriaUtil.encrypt("평문");  // Base64 인코딩된 암호문

// 복호화
String decrypted = AriaUtil.decrypt(encrypted);
```

### 비밀번호 인코더 (MigrationPasswordEncoder)

**파일**: `security/MigrationPasswordEncoder.java`

**지원 형식**
- `{ARIA}` 접두사: ARIA 암호화 (레거시)
- `$2a$`, `$2b$`: BCrypt (레거시)

**마이그레이션 확인**
```java
MigrationPasswordEncoder encoder = ...;
if (encoder.needsMigration(encodedPassword)) {
    // BCrypt → ARIA 마이그레이션 필요
}
```

---

## 7. JWT 인증 (API용)

### 구성 파일
| 파일 | 설명 |
|------|------|
| `security/JwtTokenProvider.java` | 토큰 생성/검증 |
| `security/JwtAuthenticationFilter.java` | 인증 필터 |

### 설정 (application.properties)
```properties
jwt.secret=Base64인코딩된시크릿키
jwt.token-validity-in-milliseconds=3600000  # 1시간
```

### 토큰 구조
- Subject: username
- Claim: roles
- 서명: HMAC-SHA256 (Base64 디코딩된 secret 사용)

### API 인증 흐름
```
1. POST /api/auth/login → JWT 토큰 발급
2. Authorization: Bearer {token} 헤더로 요청
3. JwtAuthenticationFilter가 토큰 검증
```

---

## 8. WebSocket 인증

### 파일
`interceptor/WebSocketAuthInterceptor.java`

### 검증 로직
```java
1. HTTP 세션 존재 확인
2. SecurityContext에서 Authentication 확인
3. isAuthenticated() 검증
4. username을 WebSocket attributes에 저장
```

### 적용
```java
// WebSocketConfig.java
registry.addHandler(...)
        .addInterceptors(webSocketAuthInterceptor)
```

---

## 9. CSRF 보호

### 기본: 활성화
폼 기반 요청에 대해 CSRF 토큰 검증

### 예외 경로
```java
.csrf(csrf -> csrf.ignoringRequestMatchers(
    "/policy/api/**",
    "/operation/api/**"
))
```

### API 체인 (/api/**)
- CSRF 비활성화 (Stateless JWT 인증 사용)

---

## 10. 입력 검증 (@Valid)

### DTO 검증 패턴
```java
// DTO
public class EventActiveRequest {
    @NotNull(message = "validation.idx.required")
    private Long idx;

    @NotNull(message = "validation.active.required")
    private Boolean active;
}

// Controller
@PostMapping("/toggleEvent")
public Response toggleEvent(
    @Valid @RequestBody EventActiveRequest request,
    BindingResult bindingResult
) {
    if (bindingResult.hasErrors()) {
        String key = bindingResult.getFieldErrors().get(0).getDefaultMessage();
        return Response.error(messageService.getMessage(key));
    }
    // ...
}
```

### 주요 검증 어노테이션
- `@NotNull`: null 불가
- `@NotBlank`: 빈 문자열 불가
- `@NotEmpty`: 빈 컬렉션 불가

---

## 11. CORS 설정

### 파일
`config/SecurityConfig.java:181-192`

### 설정
```java
CorsConfiguration configuration = new CorsConfiguration();
configuration.setAllowedOrigins(apiSvrUriList);  // application.properties의 api.uri
configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
configuration.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "X-Requested-With"));
configuration.setExposedHeaders(List.of("Authorization"));
configuration.setAllowCredentials(true);
```

---

## 요약: 보안 계층 구조

```
┌─────────────────────────────────────────┐
│           HTTPS 강제 (TLS)              │
├─────────────────────────────────────────┤
│     HTTP 보안 헤더 (HSTS, CSP, etc.)    │
├─────────────────────────────────────────┤
│         Rate Limiting (Bucket4j)        │
├─────────────────────────────────────────┤
│    인증 (Session/JWT) + CSRF 보호       │
├─────────────────────────────────────────┤
│   AJAX Only Interceptor (특정 경로)     │
├─────────────────────────────────────────┤
│      입력 검증 (@Valid + DTO)           │
├─────────────────────────────────────────┤
│     SRI (스크립트 무결성 검증)           │
└─────────────────────────────────────────┘
```

---

## 12. JavaScript 하이재킹 방어

### 개요
JSON 배열을 직접 반환하는 API는 JavaScript 하이재킹 공격에 취약할 수 있습니다.
이를 방어하기 위해 두 가지 전략을 적용합니다.

### 방어 전략

#### 1. AjaxOnlyInterceptor 적용
AJAX 요청만 허용하여 `<script src="...">` 태그를 통한 직접 로드 차단

#### 2. ApiResponse 래핑
JSON 배열을 객체로 래핑하여 직접 실행 불가하도록 변경

**ApiResponse DTO** (`dto/ApiResponse.java`):
```java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ApiResponse<T> {
    private int ret;
    private String message;
    private T data;

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(0, "조회 성공", data);
    }

    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(-1, message, null);
    }
}
```

**컨트롤러 패턴**:
```java
@GetMapping("/api/data")
public ResponseEntity<ApiResponse<List<Data>>> getData() {
    try {
        return ResponseEntity.ok(ApiResponse.success(service.getList()));
    } catch (Exception e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(e.getMessage()));
    }
}
```

**클라이언트 패턴**:
```javascript
$.ajax({
    url: '/api/data',
    success: function(response) {
        if (response.ret === 0) {
            processData(response.data);
        }
    }
});
```

### 적용 대상 API (2026-01-15)

| Controller | Endpoint |
|------------|----------|
| AssetController | `/asset/grid-data-asset` |
| AssetController | `/asset/grid-data-topology-switch` |
| AssetController | `/asset/grid-data-topology-switch-optimized` |
| TopologyPhysicalController | `/topology-physical/select-topology-switch-list` |
| TopologyPhysicalController | `/topology-physical/select-topology-switch-asset-list` |
| TopologyPhysicalController | `/topology-physical/select-related-events` |
| DataController | `/data/grid-data-systemResource` |