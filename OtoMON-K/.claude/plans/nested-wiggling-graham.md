# CSP strict-dynamic 및 nonce 적용 계획

## 문제점

### 현재 상태
```
Content-Security-Policy:
  script-src 'self' 'unsafe-inline' 'unsafe-eval' blob:;
```

### 보안 취약점
1. **CSP 헤더에 nonce가 없음** - HTML에 `th:nonce`를 사용해도 CSP 헤더에 `'nonce-{값}'`이 없으면 브라우저가 검증하지 않음
2. **`'unsafe-inline'` 존재** - nonce의 보안 효과가 무효화됨
3. **`'strict-dynamic'` 누락** - 스캐너가 감지한 취약점

### 현재 흐름
```
CspNonceFilter → nonce 생성 → request.setAttribute() → CspNonceAdvice → View에 전달
                                                        ↓
SecurityConfig → CSP 헤더 (정적, nonce 없음) → Response
```

## 해결 방안

### 수정 후 흐름
```
CspNonceFilter → nonce 생성 → request.setAttribute() → CspNonceAdvice → View에 전달
                           ↓
                  CSP 헤더에 동적 nonce 포함 → Response
```

---

## 수정 파일

### 1. CspNonceFilter.java (핵심 수정)

**파일:** `src/main/java/com/otoones/otomon/filter/CspNonceFilter.java`

**변경 내용:** CSP 헤더를 동적으로 생성하여 nonce 포함

```java
@Component
public class CspNonceFilter extends OncePerRequestFilter {
    public static final String CSP_NONCE_ATTRIBUTE = "cspNonce";
    private static final SecureRandom secureRandom = new SecureRandom();

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        byte[] nonceBytes = new byte[16];
        secureRandom.nextBytes(nonceBytes);
        String nonce = Base64.getEncoder().encodeToString(nonceBytes);
        request.setAttribute(CSP_NONCE_ATTRIBUTE, nonce);

        // 추가: CSP 헤더에 동적 nonce + strict-dynamic 포함
        String cspPolicy = buildCspPolicy(nonce);
        response.setHeader("Content-Security-Policy", cspPolicy);

        filterChain.doFilter(request, response);
    }

    private String buildCspPolicy(String nonce) {
        return "default-src 'self' blob: data:; " +
               "script-src 'self' 'nonce-" + nonce + "' 'strict-dynamic'; " +
               "style-src 'self' 'unsafe-inline' blob:; " +
               "img-src 'self' data: blob: https:; " +
               "font-src 'self' data: blob:; " +
               "connect-src 'self' ws: wss: blob: https:; " +
               "worker-src 'self' blob:; " +
               "child-src 'self' blob:; " +
               "frame-ancestors 'self'; " +
               "object-src 'none'";
    }
}
```

### 2. SecurityConfig.java (CSP 설정 제거)

**파일:** `src/main/java/com/otoones/otomon/config/SecurityConfig.java`

**변경 내용:** 106-117행 CSP 설정 제거 (Filter에서 동적 설정하므로 중복 제거)

```java
// 삭제할 부분 (106-117행):
.contentSecurityPolicy(csp -> csp.policyDirectives(
    "default-src 'self' blob: data:; " +
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' blob:; " +
    ...
))
```

---

## 주요 변경 사항

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| script-src | `'self' 'unsafe-inline' 'unsafe-eval' blob:` | `'self' 'nonce-{동적값}' 'strict-dynamic'` |
| nonce 위치 | HTML만 | HTML + CSP 헤더 |
| unsafe-inline | 있음 | 제거 |
| unsafe-eval | 있음 | 제거 (오류 시 복원) |
| strict-dynamic | 없음 | 추가 |

---

## strict-dynamic 동작 방식

`'strict-dynamic'`이 있으면:
1. nonce가 있는 스크립트에서 동적으로 생성/로드하는 스크립트도 자동 신뢰
2. `'self'`, URL whitelist 등이 무시됨 (nonce만 검증)
3. 외부 라이브러리(AG Grid, ECharts 등)가 내부적으로 스크립트를 생성해도 허용

---

## unsafe-eval 제거 시 주의사항

`'unsafe-eval'` 제거 시 `eval()`, `new Function()`, `setTimeout(string)` 등이 차단됩니다.

**영향 가능성:**
- AG Grid Enterprise - 일부 기능에서 eval 사용 가능
- ECharts - 동적 포매터에서 사용 가능

**대응:**
- 테스트 후 오류 발생 시 `'unsafe-eval'` 복원 고려
- 또는 해당 라이브러리 버전 업그레이드

---

## 검증 방법

### 1. 브라우저 개발자 도구 확인
```
Network 탭 → Response Headers → Content-Security-Policy
→ 'nonce-{값}'과 'strict-dynamic' 포함 여부 확인
```

### 2. 콘솔 오류 확인
CSP 위반 시 콘솔에 오류 메시지 표시됨

### 3. 보안 스캔 재실행
HCL AppScan으로 재스캔하여 "strict-dynamic 누락" 취약점 해결 확인

---

## 추가 작업: 모든 script 태그에 nonce 추가

`strict-dynamic` 적용 시 **모든 `<script>` 태그에 nonce 필요**

### nonce가 없는 외부 JS 로드 script 태그

| 파일 | 행 | 스크립트 |
|------|-----|----------|
| layouts/default.html | 400 | darkMode.js |
| layouts/default.html | 413 | localeDate.js |
| layouts/default.html | 414 | ko.js |
| layouts/default.html | 418 | common.js |
| layouts/default.html | 422 | menuCache.js |
| layouts/default.html | 435 | datetimeRange.js |
| layouts/default.html | 447 | sidebar-minify.js |
| pages/data/operation.html | 145 | moment/ko.js |
| pages/setting/template.html | 178 | gridstack-all.js |
| pages/analysis/reportAdd.html | 391 | gridstack-all.js |
| pages/analysis/timeseries2.html | 387 | tsGrid.js |

### 수정 방법

**변경 전:**
```html
<script th:src="@{/js/darkMode.js}"></script>
```

**변경 후:**
```html
<script th:nonce="${nonce}"
        th:src="@{/js/darkMode.js}"></script>
```

---

## 작업 순서

### Phase 1: CSP 헤더 수정 (완료)
1. ~~CspNonceFilter.java 수정 (nonce + strict-dynamic 포함)~~ ✓
2. ~~SecurityConfig.java CSP 설정 제거~~ ✓

### Phase 2: script 태그에 nonce 추가 (진행 필요)
3. layouts/default.html - 7개 스크립트 태그 수정
4. pages/data/operation.html - 1개 스크립트 태그 수정
5. pages/setting/template.html - 1개 스크립트 태그 수정
6. pages/analysis/reportAdd.html - 1개 스크립트 태그 수정
7. pages/analysis/timeseries2.html - 1개 스크립트 태그 수정

### Phase 3: 검증
8. 서버 재시작
9. 브라우저에서 CSP 헤더 확인
10. 주요 페이지 기능 테스트
11. 오류 발생 시 unsafe-eval 복원 검토
