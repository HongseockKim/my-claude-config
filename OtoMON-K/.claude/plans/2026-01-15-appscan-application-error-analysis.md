# AppScan 애플리케이션 오류 분석 플랜

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** AppScan에서 발견된 20개 애플리케이션 오류(500 응답)에 대한 근본 원인 분석 및 개선 방안 수립

**Architecture:** 현재 Spring Boot 3.4.5 기반 애플리케이션의 파라미터 검증 체계 분석, GlobalExceptionHandler를 통한 일괄 예외 처리 구조 검토

**Tech Stack:** Java 17, Spring Boot 3.4.5, Spring Validation (@Valid, @Positive 등), JPA

---

## 분석 요약

### AppScan 테스트 기법 설명

AppScan은 다음 기법으로 애플리케이션 오류를 유발:
1. **파라미터 제거** - 필수 파라미터를 요청에서 제외
2. **파라미터값 제거** - 빈 문자열 전달
3. **널 바이트 주입** - `%00` (null byte) 전달
4. **숫자 오버플로우** - `+/- 99999999` 전달
5. **위험 문자** - `' " \ .` 등 특수문자 주입
6. **파라미터명 조작** - `.` 또는 `[]` 추가

---

## 취약점 분류

### 카테고리 A: 파라미터 필수값 검증 미흡 (12건)

| # | 엔드포인트 | 문제 파라미터 | 현재 상태 | 위험도 |
|---|-----------|-------------|----------|-------|
| 1 | `/widget/turbine-speed-trend` | zone3 | `@RequestParam String zone3` - required 기본값 true이나 빈값 처리 미흡 | HIGH |
| 2 | `/widget/power-generation-trend` | zone3 | 동일 | HIGH |
| 3 | `/topology-physical/select-topology-switch-list` | zone1, zone2, zone3 | 3개 파라미터 모두 검증 없음 | HIGH |
| 6 | `/topology-physical/select-topology-switch-list` | zone3 (3호기 테스트) | 동일 | HIGH |
| 10 | `/topology-physical/select-related-events` | srcIp | 제거 시 500 오류 | HIGH |
| 11 | `/topology-physical/select-related-events` | srcMac | 제거 시 500 오류 | HIGH |
| 12 | `/topology-physical/select-asset-list` | idx | `.` 추가 시 500 오류 | MEDIUM |
| 15 | `/policy/sessionWhite/changeLog` | category | 제거 시 500 오류 | HIGH |
| 17 | `/detection/connection/get-analysisHistory` | eventId | 빈값 시 500 오류 | HIGH |
| 18 | `/code/deleteCode` | idx | 빈값 시 500 오류 | MEDIUM |
| 19 | `/detection/connection/get-analysisHistory` | eventCode | `.` 추가 시 500 오류 | HIGH |

### 카테고리 B: 널 바이트(%00) 주입 취약점 (5건)

| # | 엔드포인트 | 문제 파라미터 | 현재 상태 | 위험도 |
|---|-----------|-------------|----------|-------|
| 7 | `/asset/operation/detail` | ipAddress | `\u0000` 주입 시 500 오류 | HIGH |
| 8 | `/asset/operation/detail` | macAddress | `\u0000` 주입 시 500 오류 | HIGH |
| 9 | `/topology-physical/api/getTrafficDetail` | ipAddress | `%00` 주입 시 500 오류 | HIGH |
| 20 | `/asset/api/getTrafficDetail` | ipAddress | `%00` 주입 시 500 오류 | HIGH |
| 14 | `/detection/connection/related-events-html` | srcIp, dstIp | 특수문자 주입 시 500 오류 | HIGH |

### 카테고리 C: Base64 디코딩 실패 (4건)

| # | 엔드포인트 | 문제 파라미터 | 현재 상태 | 위험도 |
|---|-----------|-------------|----------|-------|
| 9 | `/topology-physical/api/getTrafficDetail` | ipAddress | Base64 디코딩 예외 미처리 | HIGH |
| 14 | `/detection/connection/related-events-html` | srcIp, dstIp | Base64 디코딩 예외 미처리 | HIGH |
| 16 | `/detection/connection/related-events-html` | dstIp | 동일 | HIGH |
| 10, 11 | `/topology-physical/select-related-events` | srcIp, srcMac | Base64 디코딩 예외 미처리 | HIGH |

### 카테고리 D: WebSocket SockJS 폴백 (2건)

| # | 엔드포인트 | 문제 파라미터 | 현재 상태 | 위험도 |
|---|-----------|-------------|----------|-------|
| 4 | `/ws/993/t0anxd44/htmlfile` | c (callback) | SockJS JSONP callback 검증 없음 | CRITICAL |
| 13 | `/ws/486/jtf2nmug/htmlfile` | c (callback) | 동일 | CRITICAL |

---

## 상세 원인 분석

### 1. 파라미터 필수값 검증 미흡

**현재 코드 패턴 (WidgetController.java:171-194):**
```java
@GetMapping("/turbine-speed-trend")
public ResponseEntity<Map<String ,Object>> getTurbinSpeedTrend(
        @RequestParam String zone3,  // required=true가 기본값
        @RequestParam(defaultValue = "1h") String timeRange,
        HttpSession session
){
    if(zone3 == null || zone3.isEmpty()){  // 이 검증이 도달하기 전에 예외 발생
        zone3 = (String) session.getAttribute("selectedZoneCode");
    }
    // ...
}
```

**문제점:**
- `@RequestParam String zone3`는 `required=true`가 기본값
- 파라미터가 누락되면 Spring이 `MissingServletRequestParameterException` 발생
- 그러나 파라미터가 **존재하지만 빈 문자열**인 경우는 예외 없이 통과
- 이후 서비스 레이어에서 빈 문자열로 인한 오류 발생 → 500 응답

**GlobalExceptionHandler 검토 (GlobalExceptionHandler.java:118-125):**
```java
@ExceptionHandler(Exception.class)
public ResponseEntity<Map<String,Object>> handleException(Exception ex){
    Map<String,Object> response = new HashMap<>();
    response.put("ret",-1);
    response.put("success",false);
    response.put("message","서버 오류가 발생했습니다.");  // 모든 예외가 이 메시지로 통일
    return ResponseEntity.internalServerError().body(response);  // 500 응답
}
```

**근본 원인:**
- `MissingServletRequestParameterException`에 대한 명시적 핸들러 없음
- 모든 처리되지 않은 예외가 `Exception.class` 핸들러로 떨어져 500 응답

---

### 2. 널 바이트(%00) 주입 취약점

**현재 코드 패턴 (AssetController.java:795-865):**
```java
@PostMapping("/operation/detail")
public String getAssetDetailFragment(@RequestBody AssetDto assetDto, Model model, Authentication auth) {
    // assetDto.getIpAddress()에 널 바이트가 포함될 수 있음
    Asset actualAsset = assetRepository.findById(assetDto.getIdx())
            .orElseThrow(() -> new RuntimeException("자산을 찾을 수 없습니다"));
    // ...
}
```

**문제점:**
- 널 바이트(`\u0000`, `%00`)가 포함된 문자열이 검증 없이 처리됨
- JPA 쿼리 실행 시 널 바이트로 인한 예외 발생
- 일부 데이터베이스는 널 바이트를 문자열 종결자로 해석

**근본 원인:**
- 입력 데이터의 위험 문자 필터링 없음
- 특히 Base64 디코딩 후 결과에 대한 검증 없음

---

### 3. Base64 디코딩 실패

**현재 코드 패턴 (TopologyPhysicalController.java:87-101):**
```java
@GetMapping("/select-related-events")
public ResponseEntity<ApiResponse<List<Map<String, Object>>>> selectRelatedAssetList(
        @RequestParam String srcIp,
        @RequestParam String srcMac) {
    try {
        String decodedSrcIp = srcIp != null && !srcIp.isEmpty()
                ? new String(Base64.getDecoder().decode(srcIp), StandardCharsets.UTF_8) : srcIp;
        // ...
    }
}
```

**문제점:**
- `Base64.getDecoder().decode()`는 유효하지 않은 Base64 문자열에 대해 `IllegalArgumentException` 발생
- 이 예외가 GlobalExceptionHandler의 범용 `Exception` 핸들러로 처리됨
- 결과적으로 500 응답 발생

**테스트 입력 예시:**
- `srcIp.=...` → `.` 추가로 유효하지 않은 Base64
- `srcIp=%00` → 널 바이트로 인한 디코딩 실패

---

### 4. WebSocket SockJS 폴백 취약점

**현재 설정 (WebSocketConfig.java:32-37):**
```java
@Override
public void registerStompEndpoints(StompEndpointRegistry registry) {
    registry.addEndpoint("/ws")
            .setAllowedOriginPatterns(allowedOrigins)
            .addInterceptors(webSocketAuthInterceptor)
            .withSockJS();  // SockJS 폴백 활성화
}
```

**SockJS 폴백 경로 구조:**
```
/ws/{server-id}/{session-id}/{transport}
예: /ws/993/t0anxd44/htmlfile?c=callback_function
```

**문제점:**
- SockJS의 `htmlfile` 트랜스포트는 JSONP 콜백 방식 사용
- `c` 파라미터(callback)가 응답에 그대로 삽입됨
- Spring의 SockJS 구현에서 callback 파라미터 검증
- `c=%00`(널 바이트) 입력 시 검증 실패로 "callback parameter required" 오류

**AppScan 테스트:**
```
GET /ws/993/t0anxd44/htmlfile?c=%00
응답: 500 - "callback" parameter required
```

**근본 원인:**
- Spring SockJS는 callback 파라미터가 `null`, 빈 문자열, 또는 유효하지 않은 값일 때 예외 발생
- 이 예외가 적절히 처리되지 않아 500 응답

---

## 현재 예외 처리 체계 분석

### GlobalExceptionHandler 커버리지

| 예외 유형 | 핸들러 존재 | HTTP 상태 | 비고 |
|----------|-----------|----------|-----|
| `MethodArgumentNotValidException` | ✅ | 400 | @Valid 검증 실패 |
| `AccessDeniedException` | ✅ | 403 | 권한 없음 |
| `ConstraintViolationException` | ✅ | 400 | @Positive 등 검증 실패 |
| `EntityNotFoundException` | ✅ | 404 | 엔티티 없음 |
| `HttpMessageNotReadableException` | ✅ | 400 | JSON 파싱 실패 |
| `MethodArgumentTypeMismatchException` | ✅ | 400 | 타입 불일치 |
| `NumberFormatException` | ✅ | 400 | 숫자 변환 실패 |
| `MissingServletRequestParameterException` | ❌ | 500 | **미처리** |
| `IllegalArgumentException` | ❌ | 500 | **미처리** (Base64 실패) |
| `Exception` (기타) | ✅ | 500 | 범용 핸들러 |

### 누락된 핸들러로 인한 500 오류

1. **`MissingServletRequestParameterException`** - 필수 파라미터 누락 시
2. **`IllegalArgumentException`** - Base64 디코딩 실패 시
3. **`MissingRequestValueException`** - Spring 6+ 파라미터 검증 실패 시
4. **`HandlerMethodValidationException`** - Spring 6+ 메서드 검증 실패 시

---

## 엔드포인트별 상세 분석

### 1-2. /widget/turbine-speed-trend, /widget/power-generation-trend

**파일:** `src/main/java/com/otoones/otomon/controller/WidgetController.java`

**현재 코드:**
```java
@GetMapping("/turbine-speed-trend")
public ResponseEntity<Map<String ,Object>> getTurbinSpeedTrend(
        @RequestParam String zone3,  // 필수 파라미터
        @RequestParam(defaultValue = "1h") String timeRange,
        HttpSession session
){
    if(zone3 == null || zone3.isEmpty()){
        zone3 = (String) session.getAttribute("selectedZoneCode");
    }
    // ...
}
```

**AppScan 테스트 케이스:**
- `zone3` 파라미터 제거 → `MissingServletRequestParameterException` → 500

**개선 방안:**
```java
@GetMapping("/turbine-speed-trend")
public ResponseEntity<Map<String ,Object>> getTurbinSpeedTrend(
        @RequestParam(required = false) String zone3,  // Optional로 변경
        @RequestParam(defaultValue = "1h") String timeRange,
        HttpSession session
){
    // zone3가 null이거나 빈 문자열이면 세션에서 가져오기
    if(zone3 == null || zone3.isBlank()){
        zone3 = (String) session.getAttribute("selectedZoneCode");
    }
    // zone3가 여전히 없으면 400 오류 반환
    if(zone3 == null || zone3.isBlank()){
        return ResponseEntity.badRequest()
            .body(Map.of("ret", 1, "message", "zone3 파라미터가 필요합니다."));
    }
    // ...
}
```

---

### 3, 5, 6. /topology-physical/select-topology-switch-list

**파일:** `src/main/java/com/otoones/otomon/controller/TopologyPhysicalController.java`

**현재 코드:**
```java
@GetMapping("/select-topology-switch-list")
public ResponseEntity<ApiResponse<List<Map<String, Object>>>> selectTopologySwitchList(
        @RequestParam String zone1,
        @RequestParam String zone2,
        @RequestParam String zone3,
        @RequestParam(required = false) @Positive(message = "유효 하지 않은 ID 입니다.") Long idx
) {
    // zone1, zone2, zone3 검증 없음
}
```

**AppScan 테스트 케이스:**
- `zone1.=koen` → 파라미터명에 `.` 추가 → zone1 파라미터 인식 안됨 → 500
- `zone2.=samcheonpo` → 동일
- `zone3.=3` → 동일

**문제점:**
- 파라미터명에 `.`이 추가되면 Spring은 다른 파라미터로 인식
- 원래 파라미터가 누락된 것으로 처리됨
- `MissingServletRequestParameterException` 발생 → 500

---

### 7-8. /asset/operation/detail

**파일:** `src/main/java/com/otoones/otomon/controller/AssetController.java`

**AppScan 테스트 케이스:**
- `ipAddress=\u0000` → 널 바이트 주입 → 500
- `macAddress=\u0000` → 널 바이트 주입 → 500

**개선 방안:**
- 입력 값에서 널 바이트 및 제어 문자 필터링
- 정규식: `[^\x00-\x1F\x7F]` (제어 문자 제외)

---

### 9, 20. /topology-physical/api/getTrafficDetail, /asset/api/getTrafficDetail

**현재 코드:**
```java
@PostMapping("/api/getTrafficDetail")
public ResponseEntity<Map<String,Object>> getTrafficDetail(
        @RequestParam String ipAddress,
        // ...
){
    try {
        String decodedIpAddress = ipAddress != null && !ipAddress.isEmpty()
                ? new String(Base64.getDecoder().decode(ipAddress), StandardCharsets.UTF_8)
                : ipAddress;
        // ...
    }
}
```

**AppScan 테스트 케이스:**
- `ipAddress=%00` → Base64 디코딩 실패 → `IllegalArgumentException` → 500

**문제점:**
- `%00`은 유효한 Base64 문자가 아님
- `Base64.getDecoder().decode()` 실패
- 예외가 범용 핸들러로 처리되어 500 응답

---

### 10-11, 14, 16. /topology-physical/select-related-events, /detection/connection/related-events-html

**문제점:**
- `srcIp.=...` → 파라미터명 조작으로 인식 실패
- `srcMac` 제거 → 필수 파라미터 누락
- Base64 디코딩 전 입력 검증 없음

---

### 4, 13. /ws/*/htmlfile (WebSocket SockJS)

**Spring SockJS 내부 동작:**
```java
// SockJS HtmlFileTransportHandler에서
String callback = request.getParameter("c");
if (callback == null || callback.isEmpty()) {
    throw new TransportErrorException("\"callback\" parameter required");
}
// callback 검증 로직
if (!CALLBACK_PATTERN.matcher(callback).matches()) {
    throw new TransportErrorException("Invalid \"callback\" parameter");
}
```

**AppScan 테스트 케이스:**
- `c=%00` → 널 바이트가 포함된 callback → 검증 실패 → 500

**Spring의 기본 callback 검증 패턴:**
```java
private static final Pattern CALLBACK_PATTERN = Pattern.compile("[a-zA-Z0-9_\\.]+");
```

---

## 개선 권장사항

### 1단계: GlobalExceptionHandler 확장 (즉시 조치)

**추가할 예외 핸들러:**

```java
// MissingServletRequestParameterException 핸들러
@ExceptionHandler(MissingServletRequestParameterException.class)
public ResponseEntity<Map<String, Object>> handleMissingParam(MissingServletRequestParameterException ex) {
    Map<String, Object> response = new HashMap<>();
    response.put("ret", -1);
    response.put("success", false);
    response.put("message", "필수 파라미터가 누락되었습니다: " + ex.getParameterName());
    return ResponseEntity.badRequest().body(response);  // 400 응답
}

// IllegalArgumentException 핸들러 (Base64 디코딩 실패 등)
@ExceptionHandler(IllegalArgumentException.class)
public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
    Map<String, Object> response = new HashMap<>();
    response.put("ret", -1);
    response.put("success", false);
    response.put("message", "잘못된 파라미터 값입니다.");
    return ResponseEntity.badRequest().body(response);  // 400 응답
}

// MissingRequestValueException 핸들러 (Spring 6+)
@ExceptionHandler(MissingRequestValueException.class)
public ResponseEntity<Map<String, Object>> handleMissingRequestValue(MissingRequestValueException ex) {
    Map<String, Object> response = new HashMap<>();
    response.put("ret", -1);
    response.put("success", false);
    response.put("message", "필수 요청 값이 누락되었습니다.");
    return ResponseEntity.badRequest().body(response);  // 400 응답
}
```

### 2단계: 입력 검증 유틸리티 추가 (단기)

**ValidationUtils.java 생성:**

```java
public class ValidationUtils {
    // 널 바이트 및 제어 문자 검사
    public static boolean containsControlCharacters(String input) {
        if (input == null) return false;
        return input.chars().anyMatch(c -> c < 0x20 || c == 0x7F);
    }

    // 안전한 Base64 디코딩
    public static String safeBase64Decode(String encoded) {
        if (encoded == null || encoded.isBlank()) {
            return null;
        }
        // 제어 문자 검사
        if (containsControlCharacters(encoded)) {
            throw new IllegalArgumentException("Invalid characters in Base64 input");
        }
        try {
            return new String(Base64.getDecoder().decode(encoded), StandardCharsets.UTF_8);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid Base64 encoding", e);
        }
    }

    // IP 주소 형식 검증
    public static boolean isValidIpAddress(String ip) {
        if (ip == null || ip.isBlank()) return false;
        String ipPattern = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
        return ip.matches(ipPattern);
    }

    // MAC 주소 형식 검증
    public static boolean isValidMacAddress(String mac) {
        if (mac == null || mac.isBlank()) return false;
        String macPattern = "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$";
        return mac.matches(macPattern);
    }
}
```

### 3단계: 컨트롤러별 파라미터 검증 강화 (중기)

**@NotBlank, @Pattern 어노테이션 활용:**

```java
@GetMapping("/select-topology-switch-list")
public ResponseEntity<ApiResponse<List<Map<String, Object>>>> selectTopologySwitchList(
        @RequestParam @NotBlank(message = "zone1은 필수입니다") String zone1,
        @RequestParam @NotBlank(message = "zone2는 필수입니다") String zone2,
        @RequestParam @NotBlank(message = "zone3은 필수입니다") String zone3,
        @RequestParam(required = false) @Positive(message = "유효하지 않은 ID입니다") Long idx
) {
    // ...
}
```

### 4단계: WebSocket SockJS 보안 강화 (선택)

**SockJS 비활성화 또는 callback 검증 커스터마이징:**

현재 Spring의 SockJS 구현은 callback 파라미터에 대해 기본 검증을 수행하며,
널 바이트나 유효하지 않은 문자가 포함되면 예외를 발생시킵니다.
이는 보안 기능이지만, 500 응답 대신 400 응답을 반환하도록 개선할 수 있습니다.

---

## 우선순위별 조치 계획

### 즉시 조치 (P0)
1. `MissingServletRequestParameterException` 핸들러 추가 → 400 응답
2. `IllegalArgumentException` 핸들러 추가 → 400 응답
3. `MissingRequestValueException` 핸들러 추가 → 400 응답

### 단기 조치 (P1)
4. ValidationUtils 유틸리티 클래스 생성
5. Base64 디코딩 로직에 안전한 디코딩 메서드 적용
6. 널 바이트 필터링 로직 추가

### 중기 조치 (P2)
7. 컨트롤러 파라미터에 `@NotBlank`, `@Pattern` 적용
8. IP/MAC 주소 형식 검증 추가
9. zone 파라미터 화이트리스트 검증

### 장기 조치 (P3)
10. WebSocket SockJS 오류 처리 커스터마이징
11. 통합 입력 검증 필터 구현
12. API 문서에 파라미터 제약사항 명시

---

## AppScan 재스캔 시 예상 결과

### 개선 후 예상 응답 변화

| 현재 응답 | 개선 후 응답 | 설명 |
|----------|------------|-----|
| 500 Internal Server Error | 400 Bad Request | 파라미터 누락 |
| 500 Internal Server Error | 400 Bad Request | Base64 디코딩 실패 |
| 500 Internal Server Error | 400 Bad Request | 널 바이트 주입 |
| 500 Internal Server Error | 400 Bad Request | 형식 검증 실패 |

**AppScan 판정 기준:**
- 500 응답 → "애플리케이션 오류" (취약점)
- 400 응답 → "입력 검증 작동" (정상)

1단계 조치만으로도 20건 중 대부분을 400 응답으로 변경하여
AppScan에서 "애플리케이션 오류" 취약점으로 분류되지 않도록 할 수 있습니다.

---

## 참고 자료

- **GlobalExceptionHandler:** `src/main/java/com/otoones/otomon/exception/GlobalExceptionHandler.java`
- **WebSocketConfig:** `src/main/java/com/otoones/otomon/config/WebSocketConfig.java`
- **Spring Boot Validation:** https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.validation
- **OWASP Input Validation:** https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
