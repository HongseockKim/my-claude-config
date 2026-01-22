# AppScan 애플리케이션 오류 종합 개선 플랜

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** AppScan에서 발견된 20건 + 전체 프로젝트 분석으로 발견된 47건, 총 67건의 파라미터 검증 취약점 해결

**Architecture:** GlobalExceptionHandler 확장, ValidationUtils 유틸리티 생성, 컨트롤러별 검증 강화

**Tech Stack:** Java 17, Spring Boot 3.4.5, Jakarta Validation, Spring Security

---

## 취약점 요약

### 발견된 취약점 총계: 67건

| 카테고리 | AppScan 발견 | 추가 발견 | 합계 | 위험도 |
|---------|-------------|----------|------|-------|
| A. GlobalExceptionHandler 누락 | 20건 | - | 20건 | CRITICAL |
| B. Base64 디코딩 검증 미흡 | 5건 | 21건 | 26건 | HIGH |
| C. @RequestParam 검증 미흡 | 12건 | 18건 | 30건 | MEDIUM-HIGH |
| D. @PathVariable 검증 미흡 | - | 5건 | 5건 | MEDIUM |
| E. Enum 파싱 예외 미처리 | - | 2건 | 2건 | HIGH |
| F. 숫자 범위 검증 미흡 | 3건 | 6건 | 9건 | MEDIUM |

---

## 영향받는 컨트롤러 목록

| 컨트롤러 | 취약점 수 | 우선순위 |
|---------|----------|---------|
| AssetController | 10건 | P0 |
| DetectionController | 8건 | P0 |
| TopologyPhysicalController | 5건 | P0 |
| PolicyController | 4건 | P1 |
| WidgetController | 3건 | P1 |
| OperationController | 4건 | P1 |
| DashboardController | 4건 | P2 |
| DataController | 3건 | P2 |
| CodeController | 2건 | P2 |
| SettingController | 2건 | P2 |
| UserController | 2건 | P2 |
| 기타 | 20건 | P3 |

---

## Phase 1: GlobalExceptionHandler 확장 (즉시 조치 - 모든 500 오류 해결)

### Task 1.1: MissingServletRequestParameterException 핸들러 추가

**Files:**
- Modify: `src/main/java/com/otoones/otomon/exception/GlobalExceptionHandler.java:117` (Exception 핸들러 앞에 추가)

**Step 1: 핸들러 코드 추가**

```java
// GlobalExceptionHandler.java - Line 117 앞에 추가

import org.springframework.web.bind.MissingServletRequestParameterException;

/**
 * 필수 @RequestParam 누락 시 처리
 * AppScan 테스트: 파라미터 제거, 파라미터명에 . 추가 등
 */
@ExceptionHandler(MissingServletRequestParameterException.class)
public ResponseEntity<Map<String, Object>> handleMissingParam(MissingServletRequestParameterException ex) {
    log.warn("필수 파라미터 누락: {}", ex.getParameterName());
    Map<String, Object> response = new HashMap<>();
    response.put("ret", -1);
    response.put("success", false);
    response.put("message", "필수 파라미터가 누락되었습니다: " + ex.getParameterName());
    return ResponseEntity.badRequest().body(response);
}
```

**해결되는 AppScan 항목:**
- #1 /widget/turbine-speed-trend (zone3 제거)
- #2 /widget/power-generation-trend (zone3 제거)
- #3, #5, #6 /topology-physical/select-topology-switch-list (zone1., zone2., zone3.)
- #10, #11 /topology-physical/select-related-events (srcIp., srcMac 제거)
- #15 /policy/sessionWhite/changeLog (category 제거)
- #17 /detection/connection/get-analysisHistory (eventId 빈값)
- #18 /code/deleteCode (idx 빈값)

---

### Task 1.2: IllegalArgumentException 핸들러 추가

**Files:**
- Modify: `src/main/java/com/otoones/otomon/exception/GlobalExceptionHandler.java:117` (앞에 추가)

**Step 1: 핸들러 코드 추가**

```java
/**
 * 잘못된 인자 예외 처리
 * AppScan 테스트: Base64 디코딩 실패, Enum.valueOf() 실패 등
 */
@ExceptionHandler(IllegalArgumentException.class)
public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
    log.warn("잘못된 파라미터 값: {}", ex.getMessage());
    Map<String, Object> response = new HashMap<>();
    response.put("ret", -1);
    response.put("success", false);
    response.put("message", "잘못된 파라미터 값입니다.");
    return ResponseEntity.badRequest().body(response);
}
```

**해결되는 AppScan 항목:**
- #7, #8 /asset/operation/detail (ipAddress, macAddress 널바이트)
- #9, #20 /topology-physical/api/getTrafficDetail, /asset/api/getTrafficDetail (ipAddress %00)
- #14, #16 /detection/connection/related-events-html (srcIp., dstIp.)
- #19 /detection/connection/get-analysisHistory (eventCode.)

**해결되는 추가 발견 항목:**
- OperationController:423 (Enum.valueOf 실패)
- PolicyController:603 (eventType 파싱 실패)
- 모든 Base64 디코딩 실패 케이스 (21건)

---

### Task 1.3: MissingRequestValueException 핸들러 추가 (Spring 6+)

**Files:**
- Modify: `src/main/java/com/otoones/otomon/exception/GlobalExceptionHandler.java`

**Step 1: import 및 핸들러 추가**

```java
import org.springframework.web.bind.MissingRequestValueException;

/**
 * Spring 6+ 요청 값 누락 처리
 */
@ExceptionHandler(MissingRequestValueException.class)
public ResponseEntity<Map<String, Object>> handleMissingRequestValue(MissingRequestValueException ex) {
    log.warn("요청 값 누락: {}", ex.getMessage());
    Map<String, Object> response = new HashMap<>();
    response.put("ret", -1);
    response.put("success", false);
    response.put("message", "필수 요청 값이 누락되었습니다.");
    return ResponseEntity.badRequest().body(response);
}
```

---

### Task 1.4: HandlerMethodValidationException 핸들러 추가 (Spring 6+)

**Files:**
- Modify: `src/main/java/com/otoones/otomon/exception/GlobalExceptionHandler.java`

**Step 1: import 및 핸들러 추가**

```java
import org.springframework.web.method.annotation.HandlerMethodValidationException;

/**
 * Spring 6+ 메서드 레벨 검증 실패 처리
 * @Positive, @NotBlank 등 검증 실패 시
 */
@ExceptionHandler(HandlerMethodValidationException.class)
public ResponseEntity<Map<String, Object>> handleMethodValidation(HandlerMethodValidationException ex) {
    log.warn("메서드 검증 실패: {}", ex.getMessage());

    String errorMessage = ex.getAllErrors().stream()
            .findFirst()
            .map(error -> error.getDefaultMessage())
            .orElse("입력값이 올바르지 않습니다.");

    Map<String, Object> response = new HashMap<>();
    response.put("ret", -1);
    response.put("success", false);
    response.put("message", errorMessage);
    return ResponseEntity.badRequest().body(response);
}
```

**해결되는 항목:**
- #12 /topology-physical/select-asset-list (idx.)
- 모든 @Positive 검증 실패 케이스

---

### Task 1.5: SockJS TransportErrorException 처리 확인

**Files:**
- Modify: `src/main/java/com/otoones/otomon/exception/GlobalExceptionHandler.java`

**Step 1: WebSocket 예외 처리 추가**

```java
import org.springframework.web.socket.sockjs.SockJsException;

/**
 * SockJS 전송 오류 처리
 * AppScan 테스트: /ws/*/htmlfile?c=%00
 */
@ExceptionHandler(SockJsException.class)
public ResponseEntity<Map<String, Object>> handleSockJsException(SockJsException ex) {
    log.warn("WebSocket 오류: {}", ex.getMessage());
    Map<String, Object> response = new HashMap<>();
    response.put("ret", -1);
    response.put("success", false);
    response.put("message", "WebSocket 연결 오류입니다.");
    return ResponseEntity.badRequest().body(response);
}
```

**해결되는 AppScan 항목:**
- #4 /ws/993/t0anxd44/htmlfile (c=%00)
- #13 /ws/486/jtf2nmug/htmlfile (c=%00)

---

## Phase 2: ValidationUtils 유틸리티 클래스 생성

### Task 2.1: ValidationUtils 클래스 생성

**Files:**
- Create: `src/main/java/com/otoones/otomon/util/ValidationUtils.java`

**Step 1: 유틸리티 클래스 작성**

```java
package com.otoones.otomon.util;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.regex.Pattern;

/**
 * 입력값 검증 유틸리티
 * AppScan 애플리케이션 오류 방지를 위한 중앙화된 검증 로직
 */
public final class ValidationUtils {

    private ValidationUtils() {
        // 유틸리티 클래스 - 인스턴스화 방지
    }

    // 정규식 패턴 (재사용을 위해 컴파일)
    private static final Pattern IP_PATTERN = Pattern.compile(
        "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    );

    private static final Pattern MAC_PATTERN = Pattern.compile(
        "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$"
    );

    private static final Pattern BASE64_PATTERN = Pattern.compile(
        "^[A-Za-z0-9+/]*={0,2}$"
    );

    // 허용된 zone1 값
    private static final String[] ALLOWED_ZONE1 = {"koen"};

    // 허용된 zone2 값
    private static final String[] ALLOWED_ZONE2 = {"samcheonpo"};

    // 허용된 zone3 값
    private static final String[] ALLOWED_ZONE3 = {"3", "4", "sp_03", "sp_04"};

    /**
     * 제어 문자 포함 여부 검사 (널 바이트 등)
     * @param input 검사할 문자열
     * @return 제어 문자 포함 시 true
     */
    public static boolean containsControlCharacters(String input) {
        if (input == null) return false;
        return input.chars().anyMatch(c -> c < 0x20 || c == 0x7F);
    }

    /**
     * 안전한 Base64 디코딩
     * 제어 문자 검사, Base64 형식 검증 후 디코딩
     *
     * @param encoded Base64 인코딩된 문자열
     * @return 디코딩된 문자열, null이거나 빈 문자열이면 null 반환
     * @throws IllegalArgumentException 유효하지 않은 Base64 또는 제어 문자 포함 시
     */
    public static String safeBase64Decode(String encoded) {
        if (encoded == null || encoded.isBlank()) {
            return null;
        }

        // 제어 문자 검사
        if (containsControlCharacters(encoded)) {
            throw new IllegalArgumentException("입력값에 허용되지 않는 문자가 포함되어 있습니다.");
        }

        // Base64 형식 검증
        if (!BASE64_PATTERN.matcher(encoded).matches()) {
            throw new IllegalArgumentException("유효하지 않은 Base64 형식입니다.");
        }

        try {
            byte[] decoded = Base64.getDecoder().decode(encoded);
            String result = new String(decoded, StandardCharsets.UTF_8);

            // 디코딩된 결과에서도 제어 문자 검사
            if (containsControlCharacters(result)) {
                throw new IllegalArgumentException("디코딩된 값에 허용되지 않는 문자가 포함되어 있습니다.");
            }

            return result;
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Base64 디코딩 실패: " + e.getMessage(), e);
        }
    }

    /**
     * IP 주소 형식 검증
     * @param ip 검사할 IP 주소
     * @return 유효한 IPv4 형식이면 true
     */
    public static boolean isValidIpAddress(String ip) {
        if (ip == null || ip.isBlank()) return false;
        return IP_PATTERN.matcher(ip).matches();
    }

    /**
     * MAC 주소 형식 검증
     * @param mac 검사할 MAC 주소
     * @return 유효한 MAC 형식이면 true
     */
    public static boolean isValidMacAddress(String mac) {
        if (mac == null || mac.isBlank()) return false;
        return MAC_PATTERN.matcher(mac).matches();
    }

    /**
     * zone1 값 검증
     * @param zone1 검사할 zone1 값
     * @return 허용된 값이면 true
     */
    public static boolean isValidZone1(String zone1) {
        if (zone1 == null || zone1.isBlank()) return false;
        for (String allowed : ALLOWED_ZONE1) {
            if (allowed.equalsIgnoreCase(zone1)) return true;
        }
        return false;
    }

    /**
     * zone2 값 검증
     * @param zone2 검사할 zone2 값
     * @return 허용된 값이면 true
     */
    public static boolean isValidZone2(String zone2) {
        if (zone2 == null || zone2.isBlank()) return false;
        for (String allowed : ALLOWED_ZONE2) {
            if (allowed.equalsIgnoreCase(zone2)) return true;
        }
        return false;
    }

    /**
     * zone3 값 검증
     * @param zone3 검사할 zone3 값
     * @return 허용된 값이면 true
     */
    public static boolean isValidZone3(String zone3) {
        if (zone3 == null || zone3.isBlank()) return false;
        for (String allowed : ALLOWED_ZONE3) {
            if (allowed.equalsIgnoreCase(zone3)) return true;
        }
        return false;
    }

    /**
     * 문자열이 비어있지 않고 제어 문자가 없는지 검증
     * @param value 검사할 문자열
     * @return 유효하면 true
     */
    public static boolean isValidString(String value) {
        if (value == null || value.isBlank()) return false;
        return !containsControlCharacters(value);
    }

    /**
     * Long 값이 양수 범위 내인지 검증
     * @param value 검사할 값
     * @param maxValue 최대값
     * @return 유효하면 true
     */
    public static boolean isValidPositiveLong(Long value, long maxValue) {
        if (value == null) return false;
        return value > 0 && value <= maxValue;
    }

    /**
     * 안전한 Enum 파싱
     * @param enumClass Enum 클래스
     * @param value 파싱할 문자열
     * @param <T> Enum 타입
     * @return 파싱된 Enum 값
     * @throws IllegalArgumentException 유효하지 않은 값일 경우
     */
    public static <T extends Enum<T>> T safeEnumValueOf(Class<T> enumClass, String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Enum 값이 비어있습니다.");
        }

        if (containsControlCharacters(value)) {
            throw new IllegalArgumentException("Enum 값에 허용되지 않는 문자가 포함되어 있습니다.");
        }

        try {
            return Enum.valueOf(enumClass, value.toUpperCase().trim());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("유효하지 않은 값입니다: " + value, e);
        }
    }
}
```

---

## Phase 3: 컨트롤러별 검증 강화

### Task 3.1: AssetController Base64 디코딩 수정 (10건)

**Files:**
- Modify: `src/main/java/com/otoones/otomon/controller/AssetController.java`

**수정 위치 및 내용:**

| 라인 | 메서드 | 수정 내용 |
|-----|-------|---------|
| 204 | getTrafficDetail | `ValidationUtils.safeBase64Decode()` 사용 |
| 301-307 | editAsset | ipAddress, macAddress, manageNumber 디코딩 수정 |
| 377-383 | registerAsset | 동일 |
| 528-534 | addAsset | 동일 |

**Step 1: import 추가**

```java
import com.otoones.otomon.util.ValidationUtils;
```

**Step 2: getTrafficDetail 메서드 수정 (Line 204)**

```java
// Before (Line 204)
String decodedIpAddress = ipAddress != null && !ipAddress.isEmpty()
        ? new String(Base64.getDecoder().decode(ipAddress), StandardCharsets.UTF_8) : ipAddress;

// After
String decodedIpAddress = ValidationUtils.safeBase64Decode(ipAddress);
if (decodedIpAddress == null) {
    Map<String, Object> response = new HashMap<>();
    response.put("ret", 1);
    response.put("message", "IP 주소가 필요합니다.");
    return ResponseEntity.badRequest().body(response);
}
```

**Step 3: editAsset 메서드 수정 (Line 301-307)**

```java
// Before (Line 301-307)
if (asset.getIpAddress() != null && !asset.getIpAddress().isEmpty()) {
    asset.setIpAddress(new String(Base64.getDecoder().decode(asset.getIpAddress()), StandardCharsets.UTF_8));
}
if (asset.getMacAddress() != null && !asset.getMacAddress().isEmpty()) {
    asset.setMacAddress(new String(Base64.getDecoder().decode(asset.getMacAddress()), StandardCharsets.UTF_8));
}
if (asset.getManageNumber() != null && !asset.getManageNumber().isEmpty()) {
    asset.setManageNumber(new String(Base64.getDecoder().decode(asset.getManageNumber()), StandardCharsets.UTF_8));
}

// After
if (asset.getIpAddress() != null && !asset.getIpAddress().isEmpty()) {
    asset.setIpAddress(ValidationUtils.safeBase64Decode(asset.getIpAddress()));
}
if (asset.getMacAddress() != null && !asset.getMacAddress().isEmpty()) {
    asset.setMacAddress(ValidationUtils.safeBase64Decode(asset.getMacAddress()));
}
if (asset.getManageNumber() != null && !asset.getManageNumber().isEmpty()) {
    asset.setManageNumber(ValidationUtils.safeBase64Decode(asset.getManageNumber()));
}
```

**Step 4: registerAsset 메서드 수정 (Line 377-383)** - 동일 패턴

**Step 5: addAsset 메서드 수정 (Line 528-534)** - 동일 패턴

---

### Task 3.2: DetectionController 수정 (8건)

**Files:**
- Modify: `src/main/java/com/otoones/otomon/controller/DetectionController.java`

**수정 위치:**

| 라인 | 메서드 | 수정 내용 |
|-----|-------|---------|
| 159-161 | getRelatedEvents | safeBase64Decode 사용 |
| 195-196 | getRelatedEventsHtml | safeBase64Decode 사용 |
| 272 | getRelatedEventsByType | safeBase64Decode 사용 |
| 337 | getRelatedEventsMore | safeBase64Decode 사용 |
| 400-403 | saveConnectionAction | safeBase64Decode 사용 |

**Step 1: import 추가**

```java
import com.otoones.otomon.util.ValidationUtils;
```

**Step 2: getRelatedEvents 수정 (Line 159-161)**

```java
// Before
String decodedSrcIp = srcIp != null && !srcIp.isEmpty()
    ? new String(Base64.getDecoder().decode(srcIp), StandardCharsets.UTF_8) : srcIp;
String decodedDstIp = dstIp != null && !dstIp.isEmpty()
    ? new String(Base64.getDecoder().decode(dstIp), StandardCharsets.UTF_8) : dstIp;

// After
String decodedSrcIp = ValidationUtils.safeBase64Decode(srcIp);
String decodedDstIp = ValidationUtils.safeBase64Decode(dstIp);
```

**Step 3: getRelatedEventsHtml 수정 (Line 195-196)**

```java
// Before
String decodedSrcIp = new String(Base64.getDecoder().decode(srcIp), StandardCharsets.UTF_8);
String decodedDstIp = new String(Base64.getDecoder().decode(dstIp), StandardCharsets.UTF_8);

// After
String decodedSrcIp = ValidationUtils.safeBase64Decode(srcIp);
String decodedDstIp = ValidationUtils.safeBase64Decode(dstIp);
if (decodedSrcIp == null || decodedDstIp == null) {
    model.addAttribute("error", "IP 주소가 유효하지 않습니다.");
    return "fragments/detection/tabs/relatedEventsTab :: errorRelatedEvents";
}
```

---

### Task 3.3: TopologyPhysicalController 수정 (5건)

**Files:**
- Modify: `src/main/java/com/otoones/otomon/controller/TopologyPhysicalController.java`

**수정 위치:**

| 라인 | 메서드 | 수정 내용 |
|-----|-------|---------|
| 58 | selectTopologySwitchAssetList | IP 리스트 디코딩 수정 |
| 89 | selectRelatedAssetList | srcIp, srcMac 디코딩 수정 |
| 114-115 | getTrafficDetail | ipAddress 디코딩 수정 |

**Step 1: selectRelatedAssetList 수정 (Line 89)**

```java
// Before
String decodedSrcIp = srcIp != null && !srcIp.isEmpty()
        ? new String(Base64.getDecoder().decode(srcIp), StandardCharsets.UTF_8) : srcIp;
String decodedSrcMac = srcMac != null && !srcMac.isEmpty()
        ? new String(Base64.getDecoder().decode(srcMac), StandardCharsets.UTF_8) : srcMac;

// After
String decodedSrcIp = ValidationUtils.safeBase64Decode(srcIp);
String decodedSrcMac = ValidationUtils.safeBase64Decode(srcMac);
```

---

### Task 3.4: PolicyController 수정 (4건)

**Files:**
- Modify: `src/main/java/com/otoones/otomon/controller/PolicyController.java`

**수정 위치:**

| 라인 | 메서드 | 수정 내용 |
|-----|-------|---------|
| 67 | sessionWhiteChangeLog | category 검증 추가 |
| 99-102 | createWhitelist | srcIp, dstIp 디코딩 수정 |
| 603 | getEventsByTypeForAnalysis | eventType 검증 추가 |

**Step 1: sessionWhiteChangeLog 수정 (Line 67)**

```java
// Before
@GetMapping("/sessionWhite/changeLog")
@ResponseBody
public ResponseEntity<Map<String, Object>> sessionWhiteChangeLog(
        @RequestParam String category) {

// After
@GetMapping("/sessionWhite/changeLog")
@ResponseBody
public ResponseEntity<Map<String, Object>> sessionWhiteChangeLog(
        @RequestParam @NotBlank(message = "category는 필수입니다") String category) {

    // 제어 문자 검사
    if (ValidationUtils.containsControlCharacters(category)) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", "유효하지 않은 category 값입니다.");
        return ResponseEntity.badRequest().body(response);
    }
```

---

### Task 3.5: OperationController Enum 파싱 수정 (2건)

**Files:**
- Modify: `src/main/java/com/otoones/otomon/controller/OperationController.java`

**수정 위치: Line 423**

```java
// Before (Line 423)
OpTagRel.TagPurpose tagPurpose = OpTagRel.TagPurpose.valueOf(purpose.toUpperCase());

// After
OpTagRel.TagPurpose tagPurpose = ValidationUtils.safeEnumValueOf(
    OpTagRel.TagPurpose.class, purpose
);
```

---

### Task 3.6: WidgetController zone3 검증 추가 (3건)

**Files:**
- Modify: `src/main/java/com/otoones/otomon/controller/WidgetController.java`

**수정 위치:**

| 라인 | 메서드 | 수정 내용 |
|-----|-------|---------|
| 91 | getSingleZoneData | zone3 화이트리스트 검증 |
| 130 | getPowerGenerationTrend | zone3 화이트리스트 검증 |
| 171 | getTurbinSpeedTrend | zone3 화이트리스트 검증 |

**Step 1: getTurbinSpeedTrend 수정 (Line 171-194)**

```java
// Before
@GetMapping("/turbine-speed-trend")
public ResponseEntity<Map<String ,Object>> getTurbinSpeedTrend(
        @RequestParam String zone3,
        @RequestParam(defaultValue = "1h") String timeRange,
        HttpSession session
){
    if(zone3 == null || zone3.isEmpty()){
        zone3 = (String) session.getAttribute("selectedZoneCode");
    }

// After
@GetMapping("/turbine-speed-trend")
public ResponseEntity<Map<String ,Object>> getTurbinSpeedTrend(
        @RequestParam(required = false) String zone3,
        @RequestParam(defaultValue = "1h") String timeRange,
        HttpSession session
){
    // zone3가 없거나 빈 값이면 세션에서 가져오기
    if(zone3 == null || zone3.isBlank()){
        zone3 = (String) session.getAttribute("selectedZoneCode");
    }

    // zone3가 여전히 없으면 400 오류
    if(zone3 == null || zone3.isBlank()){
        return ResponseEntity.badRequest()
            .body(Map.of("ret", 1, "message", "zone3 파라미터가 필요합니다."));
    }

    // zone3 화이트리스트 검증
    if(!ValidationUtils.isValidZone3(zone3)){
        return ResponseEntity.badRequest()
            .body(Map.of("ret", 1, "message", "유효하지 않은 zone3 값입니다."));
    }
```

---

## Phase 4: 숫자 범위 검증 강화

### Task 4.1: @Max 어노테이션 추가

**Files:**
- Modify: Multiple controllers

**수정 위치:**

| 컨트롤러 | 라인 | 파라미터 | 추가 어노테이션 |
|---------|-----|---------|--------------|
| AssetController | 197-198 | startRaw, endRaw | @Min(0) @Max(10000) |
| TopologyPhysicalController | 114-115 | startRaw, endRaw | @Min(0) @Max(10000) |
| DetectionController | 112-113 | startRow, endRow | @Min(0) @Max(10000) |
| DataController | 129 | hours | @Min(1) @Max(168) |
| AlarmNotificationController | 33 | limit | @Min(1) @Max(100) |

**Step 1: AssetController 예시**

```java
// Before
@RequestParam(required = false, defaultValue = "0") int startRaw,
@RequestParam(required = false, defaultValue = "100") int endRaw,

// After
@RequestParam(required = false, defaultValue = "0") @Min(0) @Max(10000) int startRaw,
@RequestParam(required = false, defaultValue = "100") @Min(0) @Max(10000) int endRaw,
```

---

## Phase 5: @PathVariable 검증 강화

### Task 5.1: @PathVariable 검증 추가

**Files:**
- Modify: Multiple controllers

**수정 위치:**

| 컨트롤러 | 라인 | 파라미터 | 추가 검증 |
|---------|-----|---------|---------|
| SettingController | 199 | zone3 | 화이트리스트 검증 |
| WidgetController | 91 | zone3 | 화이트리스트 검증 |
| OperationController | 227, 394 | plantCode | 화이트리스트 검증 |

**Step 1: SettingController 예시 (Line 199)**

```java
// Before
@GetMapping("/topology-switch/list/{zone3}")
public ResponseEntity<Map<String, Object>> getSwitchListByZone3(@PathVariable String zone3) {

// After
@GetMapping("/topology-switch/list/{zone3}")
public ResponseEntity<Map<String, Object>> getSwitchListByZone3(
        @PathVariable @NotBlank String zone3) {

    // zone3 화이트리스트 검증
    if (!ValidationUtils.isValidZone3(zone3)) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", "유효하지 않은 zone3 값입니다.");
        return ResponseEntity.badRequest().body(response);
    }
```

---

## Phase 6: 테스트 및 검증

### Task 6.1: 단위 테스트 작성

**Files:**
- Create: `src/test/java/com/otoones/otomon/util/ValidationUtilsTest.java`

```java
package com.otoones.otomon.util;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ValidationUtilsTest {

    @Test
    void testContainsControlCharacters_withNullByte() {
        assertTrue(ValidationUtils.containsControlCharacters("\u0000test"));
        assertTrue(ValidationUtils.containsControlCharacters("test\u0000"));
    }

    @Test
    void testContainsControlCharacters_withNormalString() {
        assertFalse(ValidationUtils.containsControlCharacters("normal string"));
        assertFalse(ValidationUtils.containsControlCharacters("192.168.1.1"));
    }

    @Test
    void testSafeBase64Decode_withValidInput() {
        // "test" in Base64 = "dGVzdA=="
        assertEquals("test", ValidationUtils.safeBase64Decode("dGVzdA=="));
    }

    @Test
    void testSafeBase64Decode_withInvalidBase64() {
        assertThrows(IllegalArgumentException.class,
            () -> ValidationUtils.safeBase64Decode("invalid!!!"));
    }

    @Test
    void testSafeBase64Decode_withNullByte() {
        assertThrows(IllegalArgumentException.class,
            () -> ValidationUtils.safeBase64Decode("\u0000"));
    }

    @Test
    void testIsValidIpAddress() {
        assertTrue(ValidationUtils.isValidIpAddress("192.168.1.1"));
        assertTrue(ValidationUtils.isValidIpAddress("10.0.0.1"));
        assertFalse(ValidationUtils.isValidIpAddress("256.1.1.1"));
        assertFalse(ValidationUtils.isValidIpAddress("invalid"));
        assertFalse(ValidationUtils.isValidIpAddress(null));
    }

    @Test
    void testIsValidMacAddress() {
        assertTrue(ValidationUtils.isValidMacAddress("00:11:22:33:44:55"));
        assertTrue(ValidationUtils.isValidMacAddress("00-11-22-33-44-55"));
        assertFalse(ValidationUtils.isValidMacAddress("invalid"));
        assertFalse(ValidationUtils.isValidMacAddress(null));
    }

    @Test
    void testIsValidZone3() {
        assertTrue(ValidationUtils.isValidZone3("3"));
        assertTrue(ValidationUtils.isValidZone3("4"));
        assertTrue(ValidationUtils.isValidZone3("sp_03"));
        assertFalse(ValidationUtils.isValidZone3("invalid"));
        assertFalse(ValidationUtils.isValidZone3(null));
    }
}
```

---

### Task 6.2: AppScan 재스캔을 위한 테스트 케이스

**수동 테스트 체크리스트:**

| # | 엔드포인트 | 테스트 입력 | 예상 응답 |
|---|-----------|-----------|----------|
| 1 | /widget/turbine-speed-trend | zone3 제거 | 400 + "zone3 파라미터가 필요합니다" |
| 2 | /widget/turbine-speed-trend | zone3= (빈값) | 400 + "zone3 파라미터가 필요합니다" |
| 3 | /asset/api/getTrafficDetail | ipAddress=%00 | 400 + "잘못된 파라미터 값입니다" |
| 4 | /topology-physical/select-topology-switch-list | zone1.=koen | 400 + "필수 파라미터가 누락되었습니다: zone1" |
| 5 | /ws/*/htmlfile | c=%00 | 400 + "WebSocket 연결 오류입니다" |

---

## 구현 순서 요약

### 즉시 조치 (1-2시간)
1. **Task 1.1-1.5**: GlobalExceptionHandler 확장 → 모든 500 오류가 400으로 변경

### 단기 조치 (반나절)
2. **Task 2.1**: ValidationUtils 클래스 생성

### 중기 조치 (1-2일)
3. **Task 3.1-3.6**: 컨트롤러별 검증 강화
4. **Task 4.1**: 숫자 범위 검증 추가
5. **Task 5.1**: @PathVariable 검증 추가

### 검증 (반나절)
6. **Task 6.1-6.2**: 테스트 작성 및 AppScan 재스캔

---

## 예상 결과

### AppScan 재스캔 시

| 현재 | 개선 후 |
|-----|--------|
| 애플리케이션 오류 20건 | 0건 |
| 500 Internal Server Error | 400 Bad Request |
| "서버 오류가 발생했습니다" | 구체적인 오류 메시지 |

### 추가 발견 취약점

| 현재 | 개선 후 |
|-----|--------|
| 잠재적 취약점 47건 | 0건 |
| Base64 디코딩 실패 시 500 | 400 + "잘못된 파라미터 값입니다" |
| Enum 파싱 실패 시 500 | 400 + "유효하지 않은 값입니다" |

---

## 참고 파일

- **GlobalExceptionHandler:** `src/main/java/com/otoones/otomon/exception/GlobalExceptionHandler.java`
- **컨트롤러 디렉토리:** `src/main/java/com/otoones/otomon/controller/`
- **유틸리티 디렉토리:** `src/main/java/com/otoones/otomon/util/`
- **보안 문서:** `.claude/docs/security.md`
