# AppScan 입력 검증 취약점 종합 개선 플랜

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** AppScan "애플리케이션 오류" 취약점을 "입력 검증이 올바르게 작동함"으로 변경

**Architecture:** GlobalExceptionHandler 확장 + ValidationUtils 유틸리티 + 컨트롤러별 검증 적용

**Tech Stack:** Java 17, Spring Boot 3.4.5, Jakarta Validation

---

## 수정 범위 구분

### 1. 필수 수정 (AppScan 실제 발견 20건)
- **실제 스캔에서 발견된 취약점** - 반드시 수정 필요
- 스캔 결과에 명시된 엔드포인트와 파라미터

### 2. 예방적 수정 (동일 유형 추가 발견)
- **동일한 취약점 패턴을 가진 다른 엔드포인트** - 미리 보완
- 향후 스캔에서 발견될 수 있는 잠재적 취약점

---

## AppScan 판정 기준 이해

| 현재 응답 | AppScan 판정 | 목표 응답 | 목표 판정 |
|----------|-------------|----------|----------|
| 500 + "서버 오류가 발생했습니다" | **애플리케이션 오류** (취약) | 400 + "구체적 오류 메시지" | **입력 검증 작동** (정상) |

**핵심:** 단순히 500→400이 아니라, **의미있는 오류 메시지**로 입력 검증이 작동함을 증명해야 함

---

## 전체 프로젝트 취약점 현황

### 발견된 취약점 총계

| 유형 | 설명 | 필수 수정 | 예방적 수정 | 합계 |
|-----|-----|----------|-----------|------|
| **A** | GlobalExceptionHandler 핸들러 누락 | 20건 적용 | 전체 API | 전체 |
| **B** | Base64 디코딩 검증 없음 | 8건 | 26건 | 34개 위치 |
| **C** | @RequestParam String 필수 파라미터 검증 없음 | 12건 | 33건 | 45개 위치 |
| **D** | Enum.valueOf() 예외 미처리 | 0건 | 4건 | 4개 위치 |
| **E** | @RequestParam Long/int 범위 검증 없음 | 2건 | 13건 | 15개 위치 |

---

## AppScan 20건 상세 분석

### #1-2: /widget/turbine-speed-trend, /widget/power-generation-trend

**테스트 입력:** `zone3` 파라미터 제거
**현재 응답:** 500 - "서버 오류가 발생했습니다"
**원인:** `MissingServletRequestParameterException` → GlobalExceptionHandler에서 미처리

**비즈니스 로직:**
- zone3가 없으면 세션에서 `selectedZoneCode` 가져옴
- 세션에도 없으면 기본 호기로 처리하거나 오류

**올바른 응답:** 400 - "zone3 파라미터가 필요합니다. 호기 코드를 선택해주세요."

---

### #3, #5, #6: /topology-physical/select-topology-switch-list

**테스트 입력:** `zone1.=koen`, `zone2.=samcheonpo`, `zone3.=3`
**현재 응답:** 500 - "서버 오류가 발생했습니다"
**원인:** 파라미터명에 `.` 추가 → 원래 파라미터 누락으로 인식 → `MissingServletRequestParameterException`

**비즈니스 로직:**
- zone1, zone2, zone3 모두 필수
- 토폴로지 스위치 목록 조회에 사용

**올바른 응답:** 400 - "필수 파라미터가 누락되었습니다: zone1"

---

### #4, #13: /ws/*/htmlfile (WebSocket SockJS)

**테스트 입력:** `c=%00` (널바이트)
**현재 응답:** 500 - "callback" parameter required
**원인:** SockJS JSONP 트랜스포트에서 callback 파라미터 검증 실패

**비즈니스 로직:**
- WebSocket 폴백용 SockJS 트랜스포트
- callback은 JavaScript 함수명이어야 함

**올바른 응답:** 400 - "유효하지 않은 callback 파라미터입니다"

---

### #7, #8: /asset/operation/detail

**테스트 입력:** `ipAddress=\u0000`, `macAddress=\u0000`
**현재 응답:** 500 - "서버 오류가 발생했습니다"
**원인:** 널바이트가 포함된 문자열이 DB 쿼리에 전달 → 예외 발생

**비즈니스 로직:**
- 자산 상세 정보 조회
- idx로 자산을 찾고 ipAddress, macAddress는 결과 데이터

**올바른 응답:** 400 - "요청 데이터에 허용되지 않는 문자가 포함되어 있습니다"

---

### #9, #20: /topology-physical/api/getTrafficDetail, /asset/api/getTrafficDetail

**테스트 입력:** `ipAddress=%00`
**현재 응답:** 500 - "트래픽 데이터 조회 실패"
**원인:** `Base64.getDecoder().decode("%00")` → `IllegalArgumentException`

**비즈니스 로직:**
- ipAddress는 Base64 인코딩된 IP 주소
- 트래픽 상세 데이터 조회에 사용

**올바른 응답:** 400 - "유효하지 않은 IP 주소 형식입니다"

---

### #10, #11: /topology-physical/select-related-events

**테스트 입력:** `srcIp.=...`, `srcMac` 제거
**현재 응답:** 500 - "서버 오류가 발생했습니다"
**원인:** 파라미터 누락 또는 Base64 디코딩 실패

**비즈니스 로직:**
- srcIp, srcMac으로 관련 이벤트 조회
- 둘 다 필수, Base64 인코딩됨

**올바른 응답:** 400 - "srcIp 파라미터가 누락되었습니다" 또는 "유효하지 않은 IP 주소 형식입니다"

---

### #12: /topology-physical/select-asset-list

**테스트 입력:** `idx.=7620`
**현재 응답:** 500 - "서버 오류가 발생했습니다"
**원인:** `idx.` → 원래 `idx` 파라미터 누락

**비즈니스 로직:**
- idx는 자산 ID (양수)
- `@Positive` 검증 있으나 파라미터 누락은 별개

**올바른 응답:** 400 - "필수 파라미터가 누락되었습니다: idx"

---

### #14, #16: /detection/connection/related-events-html

**테스트 입력:** `srcIp.=...`, `dstIp.=...`
**현재 응답:** 500 - "서버 오류가 발생했습니다"
**원인:** 파라미터 누락 또는 Base64 디코딩 실패

**올바른 응답:** 400 - "srcIp 파라미터가 누락되었습니다"

---

### #15: /policy/sessionWhite/changeLog

**테스트 입력:** `category` 제거
**현재 응답:** 500 - "서버 오류가 발생했습니다"
**원인:** 필수 파라미터 누락

**비즈니스 로직:**
- category로 화이트리스트 변경 이력 조회
- 허용 값: "session", "timeseries" 등

**올바른 응답:** 400 - "category 파라미터가 누락되었습니다"

---

### #17, #19: /detection/connection/get-analysisHistory

**테스트 입력:** `eventId=` (빈값), `eventCode.=2001`
**현재 응답:** 500 - "서버 오류가 발생했습니다"
**원인:** eventId 빈값 → Long 파싱 실패, eventCode 파라미터 누락

**비즈니스 로직:**
- eventId: 이벤트 고유 ID (Long)
- eventCode: 이벤트 코드 (String)

**올바른 응답:** 400 - "eventId는 양수여야 합니다" 또는 "eventCode 파라미터가 누락되었습니다"

---

### #18: /code/deleteCode

**테스트 입력:** `idx=` (빈값)
**현재 응답:** 500 - "서버 오류가 발생했습니다"
**원인:** `@Positive` 검증 있으나 빈값 → Long 파싱 실패가 먼저 발생

**올바른 응답:** 400 - "idx는 양수여야 합니다"

---

## Phase 1: GlobalExceptionHandler 확장

### Task 1.1: MissingServletRequestParameterException 핸들러

**파일:** `src/main/java/com/otoones/otomon/exception/GlobalExceptionHandler.java`
**위치:** Line 117 (범용 Exception 핸들러 앞에 추가)

```java
import org.springframework.web.bind.MissingServletRequestParameterException;

/**
 * 필수 @RequestParam 파라미터 누락 시 처리
 * - zone3 파라미터 제거
 * - srcIp. 파라미터명 조작
 */
@ExceptionHandler(MissingServletRequestParameterException.class)
public ResponseEntity<Map<String, Object>> handleMissingParam(MissingServletRequestParameterException ex) {
    log.warn("필수 파라미터 누락: {} (타입: {})", ex.getParameterName(), ex.getParameterType());

    Map<String, Object> response = new HashMap<>();
    response.put("ret", -1);
    response.put("success", false);
    response.put("message", "필수 파라미터가 누락되었습니다: " + ex.getParameterName());

    return ResponseEntity.badRequest().body(response);
}
```

**해결되는 AppScan 항목:** #1, #2, #3, #5, #6, #10, #11, #12, #14, #15, #16, #17, #19

---

### Task 1.2: IllegalArgumentException 핸들러

```java
/**
 * 잘못된 인자 예외 처리
 * - Base64 디코딩 실패
 * - Enum.valueOf() 실패
 * - 잘못된 형식의 데이터
 */
@ExceptionHandler(IllegalArgumentException.class)
public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
    log.warn("잘못된 파라미터 값: {}", ex.getMessage());

    Map<String, Object> response = new HashMap<>();
    response.put("ret", -1);
    response.put("success", false);

    // 구체적인 오류 메시지 (Base64, Enum 등 구분)
    String message = "입력값이 올바르지 않습니다.";
    if (ex.getMessage() != null) {
        if (ex.getMessage().contains("Base64") || ex.getMessage().contains("Illegal base64")) {
            message = "유효하지 않은 인코딩 형식입니다.";
        } else if (ex.getMessage().contains("No enum constant")) {
            message = "유효하지 않은 값입니다.";
        }
    }
    response.put("message", message);

    return ResponseEntity.badRequest().body(response);
}
```

**해결되는 AppScan 항목:** #7, #8, #9, #20 및 모든 Base64/Enum 관련 오류

---

### Task 1.3: MissingRequestValueException 핸들러 (Spring 6+)

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

### Task 1.4: HandlerMethodValidationException 핸들러

```java
import org.springframework.web.method.annotation.HandlerMethodValidationException;

/**
 * Spring 6+ 메서드 레벨 검증 실패 처리
 * - @Positive, @NotBlank 등 검증 실패
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

---

### Task 1.5: 제어 문자 검증 필터 추가 (선택)

**파일:** `src/main/java/com/otoones/otomon/filter/ControlCharacterFilter.java` (새 파일)

```java
package com.otoones.otomon.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Map;
import java.util.HashMap;

/**
 * 요청 파라미터에서 제어 문자(널바이트 등) 필터링
 * AppScan 테스트: ipAddress=\u0000, macAddress=\u0000
 */
@Component
@Order(1)
public class ControlCharacterFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // 파라미터에 제어 문자가 있는지 검사
        Map<String, String[]> params = httpRequest.getParameterMap();
        for (Map.Entry<String, String[]> entry : params.entrySet()) {
            for (String value : entry.getValue()) {
                if (value != null && containsControlCharacter(value)) {
                    httpResponse.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    httpResponse.setContentType("application/json;charset=UTF-8");
                    httpResponse.getWriter().write(
                        "{\"ret\":-1,\"success\":false,\"message\":\"요청에 허용되지 않는 문자가 포함되어 있습니다.\"}"
                    );
                    return;
                }
            }
        }

        chain.doFilter(request, response);
    }

    private boolean containsControlCharacter(String value) {
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            // 널바이트, 제어 문자 검사 (탭, 줄바꿈은 허용)
            if (c < 0x20 && c != '\t' && c != '\n' && c != '\r') {
                return true;
            }
            if (c == 0x7F) {
                return true;
            }
        }
        return false;
    }
}
```

**해결되는 AppScan 항목:** #7, #8 및 모든 널바이트 주입 공격

---

## Phase 2: ValidationUtils 유틸리티 생성

### Task 2.1: ValidationUtils 클래스 생성

**파일:** `src/main/java/com/otoones/otomon/util/ValidationUtils.java` (새 파일)

```java
package com.otoones.otomon.util;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * 입력값 검증 유틸리티
 * AppScan 애플리케이션 오류 취약점 방지
 */
public final class ValidationUtils {

    private ValidationUtils() {}

    // IP 주소 패턴 (IPv4)
    private static final Pattern IP_PATTERN = Pattern.compile(
        "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    );

    // MAC 주소 패턴
    private static final Pattern MAC_PATTERN = Pattern.compile(
        "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$"
    );

    // 허용된 zone3 값
    private static final Set<String> ALLOWED_ZONE3 = Set.of("3", "4", "sp_03", "sp_04");

    // 허용된 category 값 (changeLog용)
    private static final Set<String> ALLOWED_CATEGORIES = Set.of("session", "timeseries", "connection");

    /**
     * 제어 문자 포함 여부 검사
     */
    public static boolean containsControlCharacters(String input) {
        if (input == null) return false;
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            if ((c < 0x20 && c != '\t' && c != '\n' && c != '\r') || c == 0x7F) {
                return true;
            }
        }
        return false;
    }

    /**
     * 안전한 Base64 디코딩
     * @param encoded Base64 인코딩된 문자열
     * @return 디코딩된 문자열
     * @throws IllegalArgumentException 유효하지 않은 입력
     */
    public static String safeBase64Decode(String encoded) {
        if (encoded == null || encoded.isBlank()) {
            return null;
        }

        if (containsControlCharacters(encoded)) {
            throw new IllegalArgumentException("입력값에 허용되지 않는 문자가 포함되어 있습니다.");
        }

        try {
            byte[] decoded = Base64.getDecoder().decode(encoded);
            String result = new String(decoded, StandardCharsets.UTF_8);

            if (containsControlCharacters(result)) {
                throw new IllegalArgumentException("디코딩된 값에 허용되지 않는 문자가 포함되어 있습니다.");
            }

            return result;
        } catch (IllegalArgumentException e) {
            if (e.getMessage().contains("허용되지 않는")) {
                throw e;
            }
            throw new IllegalArgumentException("유효하지 않은 Base64 형식입니다.", e);
        }
    }

    /**
     * 안전한 Base64 디코딩 (null 허용)
     */
    public static String safeBase64DecodeOrNull(String encoded) {
        if (encoded == null || encoded.isBlank()) {
            return null;
        }
        return safeBase64Decode(encoded);
    }

    /**
     * IP 주소 형식 검증
     */
    public static boolean isValidIpAddress(String ip) {
        if (ip == null || ip.isBlank()) return false;
        return IP_PATTERN.matcher(ip.trim()).matches();
    }

    /**
     * MAC 주소 형식 검증
     */
    public static boolean isValidMacAddress(String mac) {
        if (mac == null || mac.isBlank()) return false;
        return MAC_PATTERN.matcher(mac.trim()).matches();
    }

    /**
     * zone3 값 검증
     */
    public static boolean isValidZone3(String zone3) {
        if (zone3 == null || zone3.isBlank()) return false;
        return ALLOWED_ZONE3.contains(zone3.toLowerCase().trim());
    }

    /**
     * category 값 검증
     */
    public static boolean isValidCategory(String category) {
        if (category == null || category.isBlank()) return false;
        return ALLOWED_CATEGORIES.contains(category.toLowerCase().trim());
    }

    /**
     * 안전한 Enum 파싱
     */
    public static <T extends Enum<T>> T safeEnumValueOf(Class<T> enumClass, String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("값이 비어있습니다.");
        }

        if (containsControlCharacters(value)) {
            throw new IllegalArgumentException("값에 허용되지 않는 문자가 포함되어 있습니다.");
        }

        try {
            return Enum.valueOf(enumClass, value.toUpperCase().trim());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("유효하지 않은 값입니다: " + value, e);
        }
    }

    /**
     * 문자열 유효성 검사 (빈값, 제어문자)
     */
    public static void validateString(String value, String paramName) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(paramName + " 값이 비어있습니다.");
        }
        if (containsControlCharacters(value)) {
            throw new IllegalArgumentException(paramName + "에 허용되지 않는 문자가 포함되어 있습니다.");
        }
    }
}
```

---

## Phase 3: 컨트롤러별 Base64 디코딩 수정

### 영향받는 파일 목록 (34개 위치)

| 파일 | 라인 | 메서드 | 파라미터 |
|-----|-----|-------|---------|
| AssetController | 204 | getTrafficDetail | ipAddress |
| AssetController | 301, 304, 307 | editAsset | ipAddress, macAddress, manageNumber |
| AssetController | 377, 380, 383 | registerAsset | ipAddress, macAddress, manageNumber |
| AssetController | 528, 531, 534 | addAsset | ipAddress, macAddress, manageNumber |
| DetectionController | 159, 161 | getRelatedEvents | srcIp, dstIp |
| DetectionController | 195, 196 | getRelatedEventsHtml | srcIp, dstIp |
| DetectionController | 272 | getRelatedEventsByType | srcIp |
| DetectionController | 337 | getRelatedEventsMore | srcIp |
| DetectionController | 400, 403 | saveConnectionAction | srcIp, dstIp |
| PolicyController | 99, 102 | createWhitelist | srcIp, dstIp |
| PolicyController | 137, 140 | updateWhitelist | srcIp, dstIp |
| TopologyPhysicalController | 58 | selectTopologySwitchAssetList | ip (리스트) |
| TopologyPhysicalController | 92, 94 | selectRelatedAssetList | srcIp, srcMac |
| TopologyPhysicalController | 120 | getTrafficDetail | ipAddress |

---

### Task 3.1: AssetController Base64 디코딩 수정

**파일:** `src/main/java/com/otoones/otomon/controller/AssetController.java`

**Step 1: import 추가**
```java
import com.otoones.otomon.util.ValidationUtils;
```

**Step 2: getTrafficDetail 수정 (Line 203-204)**

```java
// Before (Line 203-204)
String decodedIpAddress = ipAddress != null && !ipAddress.isEmpty()
        ? new String(Base64.getDecoder().decode(ipAddress), StandardCharsets.UTF_8) : ipAddress;

// After
String decodedIpAddress = ValidationUtils.safeBase64DecodeOrNull(ipAddress);
if (decodedIpAddress == null || decodedIpAddress.isBlank()) {
    Map<String, Object> errorResult = new HashMap<>();
    errorResult.put("ret", 1);
    errorResult.put("message", "IP 주소가 필요합니다.");
    return ResponseEntity.badRequest().body(errorResult);
}
```

**Step 3: editAsset 수정 (Line 301-307)**

```java
// Before
if (asset.getIpAddress() != null && !asset.getIpAddress().isEmpty()) {
    asset.setIpAddress(new String(Base64.getDecoder().decode(asset.getIpAddress()), StandardCharsets.UTF_8));
}

// After
if (asset.getIpAddress() != null && !asset.getIpAddress().isEmpty()) {
    asset.setIpAddress(ValidationUtils.safeBase64Decode(asset.getIpAddress()));
}
```

**동일 패턴 적용 위치:**
- Line 304 (macAddress)
- Line 307 (manageNumber)
- Line 377, 380, 383 (registerAsset)
- Line 528, 531, 534 (addAsset)

---

### Task 3.2: DetectionController Base64 디코딩 수정

**파일:** `src/main/java/com/otoones/otomon/controller/DetectionController.java`

**Step 1: import 추가**
```java
import com.otoones.otomon.util.ValidationUtils;
```

**Step 2: getRelatedEvents 수정 (Line 158-161)**

```java
// Before
String decodedSrcIp = (srcIp != null && !srcIp.isEmpty())
        ? new String(Base64.getDecoder().decode(srcIp), StandardCharsets.UTF_8) : srcIp;
String decodedDstIp = (dstIp != null && !dstIp.isEmpty())
        ? new String(Base64.getDecoder().decode(dstIp), StandardCharsets.UTF_8) : dstIp;

// After
String decodedSrcIp = ValidationUtils.safeBase64DecodeOrNull(srcIp);
String decodedDstIp = ValidationUtils.safeBase64DecodeOrNull(dstIp);
```

**Step 3: getRelatedEventsHtml 수정 (Line 195-196)**

```java
// Before
String decodedSrcIp = new String(Base64.getDecoder().decode(srcIp), StandardCharsets.UTF_8);
String decodedDstIp = new String(Base64.getDecoder().decode(dstIp), StandardCharsets.UTF_8);

// After
String decodedSrcIp = ValidationUtils.safeBase64Decode(srcIp);
String decodedDstIp = ValidationUtils.safeBase64Decode(dstIp);
```

**동일 패턴 적용 위치:**
- Line 272 (getRelatedEventsByType)
- Line 337 (getRelatedEventsMore)
- Line 400, 403 (saveConnectionAction)

---

### Task 3.3: TopologyPhysicalController Base64 디코딩 수정

**파일:** `src/main/java/com/otoones/otomon/controller/TopologyPhysicalController.java`

**Step 1: import 추가**
```java
import com.otoones.otomon.util.ValidationUtils;
```

**Step 2: selectTopologySwitchAssetList 수정 (Line 54-63)**

```java
// Before
List<Map<String, String>> decodedIpList = ipList.stream()
        .map(item -> {
            String ip = item.get("ip");
            String decodedIp = (ip != null && !ip.isEmpty())
                    ? new String(Base64.getDecoder().decode(ip), StandardCharsets.UTF_8) : ip;
            Map<String, String> newItem = new HashMap<>(item);
            newItem.put("ip", decodedIp);
            return newItem;
        })
        .collect(Collectors.toList());

// After
List<Map<String, String>> decodedIpList = ipList.stream()
        .map(item -> {
            String ip = item.get("ip");
            String decodedIp = ValidationUtils.safeBase64DecodeOrNull(ip);
            Map<String, String> newItem = new HashMap<>(item);
            newItem.put("ip", decodedIp);
            return newItem;
        })
        .collect(Collectors.toList());
```

**Step 3: selectRelatedAssetList 수정 (Line 91-94)**

```java
// Before
String decodedSrcIp = srcIp != null && !srcIp.isEmpty()
        ? new String(Base64.getDecoder().decode(srcIp), StandardCharsets.UTF_8) : srcIp;
String decodedSrcMac = srcMac != null && !srcMac.isEmpty()
        ? new String(Base64.getDecoder().decode(srcMac), StandardCharsets.UTF_8) : srcMac;

// After
String decodedSrcIp = ValidationUtils.safeBase64DecodeOrNull(srcIp);
String decodedSrcMac = ValidationUtils.safeBase64DecodeOrNull(srcMac);
```

**Step 4: getTrafficDetail 수정 (Line 119-120)**

```java
// Before
String decodedIpAddress = ipAddress != null && !ipAddress.isEmpty()
        ? new String(Base64.getDecoder().decode(ipAddress), StandardCharsets.UTF_8) : ipAddress;

// After
String decodedIpAddress = ValidationUtils.safeBase64DecodeOrNull(ipAddress);
if (decodedIpAddress == null || decodedIpAddress.isBlank()) {
    Map<String, Object> errorResult = new HashMap<>();
    errorResult.put("ret", 1);
    errorResult.put("message", "IP 주소가 필요합니다.");
    return ResponseEntity.badRequest().body(errorResult);
}
```

---

### Task 3.4: PolicyController Base64 디코딩 수정

**파일:** `src/main/java/com/otoones/otomon/controller/PolicyController.java`

**수정 위치:**
- Line 99, 102 (createWhitelist)
- Line 137, 140 (updateWhitelist)

```java
// Before
if (dto.getSrcIp() != null && !dto.getSrcIp().isEmpty()) {
    dto.setSrcIp(new String(Base64.getDecoder().decode(dto.getSrcIp()), StandardCharsets.UTF_8));
}

// After
if (dto.getSrcIp() != null && !dto.getSrcIp().isEmpty()) {
    dto.setSrcIp(ValidationUtils.safeBase64Decode(dto.getSrcIp()));
}
```

---

## Phase 4: Enum.valueOf() 예외 처리 수정

### 영향받는 파일 목록 (4개 위치)

| 파일 | 라인 | Enum 타입 |
|-----|-----|----------|
| OperationController | 423 | OpTagRel.TagPurpose |
| UserController | 195 | UserRole |
| UserController | 252 | UserRole |
| UserController | 841 | PermissionType |

---

### Task 4.1: OperationController Enum 파싱 수정

**파일:** `src/main/java/com/otoones/otomon/controller/OperationController.java`

**Step 1: import 추가**
```java
import com.otoones.otomon.util.ValidationUtils;
```

**Step 2: getTagsByPurpose 수정 (Line 423)**

```java
// Before (Line 423)
OpTagRel.TagPurpose tagPurpose = OpTagRel.TagPurpose.valueOf(purpose.toUpperCase());

// After
OpTagRel.TagPurpose tagPurpose = ValidationUtils.safeEnumValueOf(
    OpTagRel.TagPurpose.class, purpose
);
```

---

### Task 4.2: UserController Enum 파싱 수정

**파일:** `src/main/java/com/otoones/otomon/controller/UserController.java`

**수정 위치:**
- Line 195, 252 (UserRole.valueOf)
- Line 841 (PermissionType.valueOf)

```java
// Before
user.setRole(UserRole.valueOf(userDto.getRole()));

// After
user.setRole(ValidationUtils.safeEnumValueOf(UserRole.class, userDto.getRole()));
```

---

## Phase 5: DTO/Service Base64 디코딩 수정

### 영향받는 파일 목록 (7개 위치)

| 파일 | 라인 | 설명 |
|-----|-----|-----|
| Base64IpValidator | 21 | IP 검증자 |
| ConnectionExcelDto | 56, 57 | 엑셀 변환 |
| DetectionService | 2895 | 서비스 레이어 |
| TopologySwitchService | 385, 395 | 서비스 레이어 |
| Base64Util | 34 | 유틸리티 |
| TrafficAssetExcelDto | 67 | 엑셀 변환 |

---

### Task 5.1: Base64Util 수정

**파일:** `src/main/java/com/otoones/otomon/util/Base64Util.java`

```java
// Before (Line 34)
return new String(Base64.getDecoder().decode(encodedStr), StandardCharsets.UTF_8);

// After
return ValidationUtils.safeBase64Decode(encodedStr);
```

---

### Task 5.2: ConnectionExcelDto 수정

**파일:** `src/main/java/com/otoones/otomon/dto/ConnectionExcelDto.java`

```java
// Before (Line 56-57)
.srcIp(event.getSrcIp() != null ? new String(Base64.getDecoder().decode(event.getSrcIp())) : "-")
.dstIp(event.getDstIp() != null ? new String(Base64.getDecoder().decode(event.getDstIp())) : "-")

// After
.srcIp(event.getSrcIp() != null ? ValidationUtils.safeBase64DecodeOrDefault(event.getSrcIp(), "-") : "-")
.dstIp(event.getDstIp() != null ? ValidationUtils.safeBase64DecodeOrDefault(event.getDstIp(), "-") : "-")
```

**ValidationUtils에 추가 메서드:**

```java
/**
 * 안전한 Base64 디코딩 (실패 시 기본값 반환)
 */
public static String safeBase64DecodeOrDefault(String encoded, String defaultValue) {
    try {
        String result = safeBase64Decode(encoded);
        return result != null ? result : defaultValue;
    } catch (IllegalArgumentException e) {
        return defaultValue;
    }
}
```

---

## Phase 6: 서비스/DTO 레이어 수정

### Task 6.1: DetectionService 수정

**파일:** `src/main/java/com/otoones/otomon/service/DetectionService.java`
**위치:** Line 2895

```java
// Before
return new String(Base64.getDecoder().decode(encodedStr), StandardCharsets.UTF_8);

// After
return ValidationUtils.safeBase64DecodeOrNull(encodedStr);
```

---

### Task 6.2: TopologySwitchService 수정

**파일:** `src/main/java/com/otoones/otomon/service/TopologySwitchService.java`
**위치:** Line 385, 395

```java
// Before
topologySwitch.setIp(new String(Base64.getDecoder().decode(encodedIp), StandardCharsets.UTF_8));

// After
topologySwitch.setIp(ValidationUtils.safeBase64DecodeOrNull(encodedIp));
```

---

## 테스트 체크리스트

### AppScan 20건 재테스트

| # | 엔드포인트 | 테스트 입력 | 예상 응답 |
|---|-----------|-----------|----------|
| 1 | /widget/turbine-speed-trend | zone3 제거 | 400 + "필수 파라미터가 누락되었습니다: zone3" |
| 2 | /widget/power-generation-trend | zone3.=sp_03 | 400 + "필수 파라미터가 누락되었습니다: zone3" |
| 3-6 | /topology-physical/select-topology-switch-list | zone1.=koen | 400 + "필수 파라미터가 누락되었습니다: zone1" |
| 7-8 | /asset/operation/detail | ipAddress=\u0000 | 400 + "요청에 허용되지 않는 문자가 포함되어 있습니다" |
| 9, 20 | /*/api/getTrafficDetail | ipAddress=%00 | 400 + "유효하지 않은 인코딩 형식입니다" |
| 10-11 | /topology-physical/select-related-events | srcIp.=... | 400 + "필수 파라미터가 누락되었습니다: srcIp" |
| 4, 13 | /ws/*/htmlfile | c=%00 | 400 + "유효하지 않은 callback 파라미터입니다" |
| 14, 16 | /detection/connection/related-events-html | srcIp.=... | 400 + "필수 파라미터가 누락되었습니다: srcIp" |
| 15 | /policy/sessionWhite/changeLog | category 제거 | 400 + "필수 파라미터가 누락되었습니다: category" |
| 17 | /detection/connection/get-analysisHistory | eventId= | 400 + "잘못된 파라미터 형식입니다" |
| 18 | /code/deleteCode | idx= | 400 + "잘못된 파라미터 형식입니다" |
| 19 | /detection/connection/get-analysisHistory | eventCode.=2001 | 400 + "필수 파라미터가 누락되었습니다: eventCode" |

---

## 구현 순서

### Part A: 필수 수정 (AppScan 20건 해결)

#### Step 1: GlobalExceptionHandler 확장 (30분) - 필수
1. **Task 1.1**: MissingServletRequestParameterException 핸들러 추가
   - 해결: #1, #2, #3, #5, #6, #10, #11, #12, #14, #15, #16, #17, #19
2. **Task 1.2**: IllegalArgumentException 핸들러 추가
   - 해결: #7, #8, #9, #20 (Base64 관련)
3. **Task 1.3-1.4**: MissingRequestValueException, HandlerMethodValidationException 핸들러

#### Step 2: 널바이트 차단 필터 (30분) - 필수
4. **Task 1.5**: ControlCharacterFilter 추가
   - 해결: #7, #8 (ipAddress=\u0000, macAddress=\u0000)
   - 해결: #4, #13 (WebSocket c=%00)

#### Step 3: AppScan 발견 엔드포인트 직접 수정 (1시간) - 필수
5. 20건에 해당하는 엔드포인트만 우선 수정
   - TopologyPhysicalController: #3, #5, #6, #9, #10, #11, #12
   - DetectionController: #14, #16, #17, #19
   - AssetController: #7, #8, #20
   - WidgetController: #1, #2
   - PolicyController: #15
   - CodeController: #18

### Part B: 예방적 수정 (동일 유형 미리 보완)

#### Step 4: ValidationUtils 생성 (30분)
6. **Task 2.1**: ValidationUtils 클래스 생성
   - 안전한 Base64 디코딩
   - 제어 문자 검증
   - Enum 파싱

#### Step 5: 전체 프로젝트 동일 패턴 수정 (2-3시간)
7. **Task 3.1-3.4**: 나머지 Base64 디코딩 위치 수정 (26개 추가)
8. **Task 4.1-4.2**: Enum.valueOf() 예외 처리 (4개)
9. **Task 5.1-5.2, 6.1-6.2**: DTO/Service 레이어 수정 (7개)

### Part C: 검증

#### Step 6: AppScan 재스캔
10. 20건 필수 항목 재스캔 및 결과 확인
11. 추가 발견 여부 확인

---

## 예상 결과

### AppScan 판정 변화

| 구분 | 현재 | 개선 후 |
|-----|-----|--------|
| 응답 코드 | 500 Internal Server Error | 400 Bad Request |
| 응답 메시지 | "서버 오류가 발생했습니다" | 구체적인 오류 메시지 |
| AppScan 판정 | **애플리케이션 오류** (취약) | **입력 검증 작동** (정상) |

### 전체 프로젝트 개선

| 항목 | 수정 전 | 수정 후 |
|-----|--------|--------|
| Base64 디코딩 취약점 | 34개 | 0개 |
| Enum 파싱 취약점 | 4개 | 0개 |
| 필수 파라미터 검증 | 미흡 | 완료 |
| 제어 문자 필터링 | 없음 | 적용 |

---

## 참고 파일

- **GlobalExceptionHandler:** `src/main/java/com/otoones/otomon/exception/GlobalExceptionHandler.java`
- **컨트롤러 디렉토리:** `src/main/java/com/otoones/otomon/controller/`
- **유틸리티 디렉토리:** `src/main/java/com/otoones/otomon/util/`
- **보안 문서:** `.claude/docs/security.md`

---

## 진행 상황 (2026-01-16 최종 완료)

### ✅ Phase 1: GlobalExceptionHandler 확장

| Task | 설명 | 상태 |
|------|------|------|
| 1.1 | MissingServletRequestParameterException 핸들러 | ✅ 완료 |
| 1.2 | IllegalArgumentException 핸들러 | ✅ 완료 |
| 1.3 | MissingRequestValueException 핸들러 | ✅ 완료 |
| 1.4 | HandlerMethodValidationException 핸들러 | ✅ 완료 |
| 1.5 | ControlCharacterFilter 생성 | ✅ 완료 |
| 1.6 | InvalidDataAccessApiUsageException 핸들러 | ✅ 완료 (추가) |

### ✅ Phase 2: ValidationUtils 생성

| Task | 설명 | 상태 |
|------|------|------|
| 2.1 | ValidationUtils 클래스 생성 | ✅ 완료 |

### ✅ Phase 3: 컨트롤러 Base64 수정

| Task | 설명 | 상태 |
|------|------|------|
| 3.1 | AssetController Base64 수정 | ✅ 완료 |
| 3.2 | DetectionController Base64 수정 | ✅ 완료 |
| 3.3 | TopologyPhysicalController Base64 수정 | ✅ 완료 |
| 3.4 | PolicyController Base64 수정 | ✅ 완료 |

### ✅ Phase 4-5: 서비스/DTO/Validator 수정

| 파일 | 설명 | 상태 |
|-----|-----|------|
| Base64IpValidator.java | Validator | ✅ 완료 |
| DetectionService.java | Service | ✅ 완료 |
| ConnectionExcelDto.java | DTO | ✅ 완료 |
| TopologySwitchService.java | Service | ✅ 완료 |
| TrafficAssetExcelDto.java | DTO | ✅ 완료 |

### ✅ 테스트 완료

- 빌드 정상 ✅
- 필수 파라미터 누락 → 400 응답 ✅
- 널바이트 주입 차단 → 400 응답 ✅
- 잘못된 Base64 → 400 응답 ✅
- InvalidDataAccessApiUsageException → 400 응답 ✅
- 프론트엔드 에러 핸들링 수정 ✅

### 다음 단계
1. ✅ ~~빌드 및 테스트 진행~~
2. ✅ ~~남은 파일 수정 (Phase 5-6)~~
3. ⏳ **AppScan 재스캔**
