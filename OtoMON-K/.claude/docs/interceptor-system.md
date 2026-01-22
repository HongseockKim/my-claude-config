# 인터셉터 시스템

> 요청 처리 전 공통 로직 수행

---

## 1. 인터셉터 체인

```
[HTTP 요청]
    │
    ▼
┌─────────────────────────────────┐
│  1. ZoneInterceptor             │  ← 호기(zone3) 세션 설정
├─────────────────────────────────┤
│  2. DateRangeInterceptor        │  ← 날짜 범위 세션 설정
├─────────────────────────────────┤
│  3. PermissionInterceptor       │  ← 메뉴 권한 체크
├─────────────────────────────────┤
│  4. RateLimitInterceptor        │  ← API 호출 제한
├─────────────────────────────────┤
│  5. AjaxOnlyInterceptor         │  ← AJAX 요청만 허용
├─────────────────────────────────┤
│  6. WebSocketAuthInterceptor    │  ← WebSocket 인증
└─────────────────────────────────┘
    │
    ▼
[Controller]
```

---

## 2. 인터셉터 상세

### 2.1 ZoneInterceptor
**경로:** `interceptor/ZoneInterceptor.java`

**역할:** 사용자가 선택한 호기(zone3) 값을 세션에 저장

**세션 키:**
- `selectedZoneCode` - 선택된 호기 코드 (예: `sp_03`, `sp_04`)

**동작:**
1. 요청 파라미터에서 `zone3` 확인
2. 세션에 `selectedZoneCode` 저장
3. 없으면 기본값 사용 (SystemConfig 참조)

---

### 2.2 DateRangeInterceptor
**경로:** `interceptor/DateRangeInterceptor.java`

**역할:** 날짜 범위를 세션에 저장

**세션 키:**
- `startDate` - 시작 날짜
- `endDate` - 종료 날짜
- `dateRangeType` - 범위 유형 (TODAY, WEEK, MONTH, CUSTOM)

---

### 2.3 PermissionInterceptor
**경로:** `interceptor/PermissionInterceptor.java`

**역할:** 메뉴 접근 권한 체크

**동작:**
1. 현재 URL에서 메뉴 ID 추출
2. 사용자 그룹의 `GroupMenuMapping` 확인
3. 권한 없으면 403 응답

**제외 경로:**
- `/`, `/login`, `/logout`
- `/css/**`, `/js/**`, `/images/**`
- `/error/**`

---

### 2.4 RateLimitInterceptor
**경로:** `interceptor/RateLimitInterceptor.java`

**역할:** API 호출 횟수 제한 (DDoS 방어)

**설정:**
- 60 requests / minute (기본값)
- Bucket4j + Caffeine 캐시 사용

**제외 경로:**
- 정적 리소스
- WebSocket 엔드포인트

---

### 2.5 AjaxOnlyInterceptor
**경로:** `interceptor/AjaxOnlyInterceptor.java`

**역할:** 브라우저 직접 접근 차단, AJAX만 허용

**대상:**
- `/api/**` 경로
- Fragment 반환 엔드포인트

**체크 방법:**
- `X-Requested-With: XMLHttpRequest` 헤더 확인

---

### 2.6 WebSocketAuthInterceptor
**경로:** `interceptor/WebSocketAuthInterceptor.java`

**역할:** WebSocket 연결 시 인증 확인

**동작:**
1. HTTP 세션에서 인증 정보 확인
2. SecurityContext 설정
3. 미인증 시 연결 거부

---

## 3. 등록 위치

**경로:** `config/WebMvcConfig.java`

```java
@Override
public void addInterceptors(InterceptorRegistry registry) {
    registry.addInterceptor(zoneInterceptor)
            .addPathPatterns("/**")
            .excludePathPatterns("/css/**", "/js/**");

    registry.addInterceptor(dateRangeInterceptor)
            .addPathPatterns("/**");

    registry.addInterceptor(permissionInterceptor)
            .addPathPatterns("/**")
            .excludePathPatterns("/login", "/logout", "/error/**");

    registry.addInterceptor(rateLimitInterceptor)
            .addPathPatterns("/api/**");

    registry.addInterceptor(ajaxOnlyInterceptor)
            .addPathPatterns("/api/**", "/**/fragment/**");
}
```

---

## 4. 세션 데이터 접근

```java
// Controller에서 세션 데이터 사용
@GetMapping("/data")
public String getData(HttpSession session) {
    String zone3 = (String) session.getAttribute("selectedZoneCode");
    LocalDate startDate = (LocalDate) session.getAttribute("startDate");
    // ...
}
```

---

## 5. 참조 파일

| 파일 | 역할 |
|------|------|
| `interceptor/ZoneInterceptor.java` | 호기 필터링 |
| `interceptor/DateRangeInterceptor.java` | 날짜 필터링 |
| `interceptor/PermissionInterceptor.java` | 권한 체크 |
| `interceptor/RateLimitInterceptor.java` | Rate Limit |
| `interceptor/AjaxOnlyInterceptor.java` | AJAX 전용 |
| `interceptor/WebSocketAuthInterceptor.java` | WS 인증 |
| `config/WebMvcConfig.java` | 인터셉터 등록 |
