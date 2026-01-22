# 유틸리티 클래스

> 공통 유틸리티 함수 가이드

---

## 1. Zone3Util

**경로:** `util/Zone3Util.java`

호기(zone3) 문자열 처리

### 1.1 주요 메서드

| 메서드 | 입력 | 출력 | 설명 |
|--------|------|------|------|
| `normalize()` | `"sp_03"` | `"3"` | 숫자로 정규화 |
| `toCode()` | `"3"` | `"sp_03"` | 코드 형식 변환 |
| `toDisplayText()` | `"sp_03"` | `"3호기"` | 표시용 텍스트 |
| `matches()` | `"3", "sp_03"` | `true` | 동일 여부 비교 |
| `contains()` | `"3", "[\"sp_03\",\"sp_04\"]"` | `true` | 목록 포함 여부 |
| `normalizeAll()` | `"[\"sp_03\",\"sp_04\"]"` | `["3","4"]` | 복수 추출 |

### 1.2 사용 예시
```java
// 정규화
String num = Zone3Util.normalize("sp_03");  // "3"
String num2 = Zone3Util.normalize("[\"sp_03\"]");  // "3"

// 코드 변환
String code = Zone3Util.toCode("3");  // "sp_03"

// 표시용
String display = Zone3Util.toDisplayText("sp_03");  // "3호기"

// 비교
boolean match = Zone3Util.matches("sp_03", "3");  // true

// 복수 zone3 처리
List<String> zones = Zone3Util.normalizeAll("[\"sp_03\",\"sp_04\"]");
// → ["3", "4"]
```

---

## 2. DateTimeUtil

**경로:** `util/DateTimeUtil.java`

날짜/시간 변환 처리

### 2.1 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `convertToDateTime(Object)` | Object → LocalDateTime 변환 |
| `formatDateTime(LocalDateTime)` | LocalDateTime → "yyyy-MM-dd HH:mm:ss" |
| `formatDate(LocalDateTime)` | LocalDateTime → "yyyy-MM-dd" |
| `safeFormat(LocalDateTime, DateTimeFormatter)` | null-safe 포맷팅 |

### 2.2 지원 형식
- `yyyy-MM-dd HH:mm:ss`
- `yyyy-MM-dd`
- `yyyy/MM/dd`
- ISO 형식 (`2021-05-26T15:00:00`)

### 2.3 사용 예시
```java
// Object → LocalDateTime
LocalDateTime dt = DateTimeUtil.convertToDateTime("2025-12-23 10:30:00");

// LocalDateTime → String
String str = DateTimeUtil.formatDateTime(LocalDateTime.now());
// → "2025-12-23 10:30:00"

// 날짜만
String dateStr = DateTimeUtil.formatDate(LocalDateTime.now());
// → "2025-12-23"
```

---

## 3. Base64Util

**경로:** `util/Base64Util.java`

Base64 인코딩/디코딩 (IP 암호화 등)

### 3.1 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `encodeBase64(String)` | 문자열 → Base64 인코딩 |
| `decodeBase64(String)` | Base64 → 문자열 디코딩 |
| `encodeFieldsInMap(Map, String...)` | Map 내 필드들 일괄 인코딩 |

### 3.2 사용 예시
```java
// 인코딩
String encoded = Base64Util.encodeBase64("192.168.1.1");

// 디코딩
String decoded = Base64Util.decodeBase64(encoded);

// Map 필드 일괄 인코딩
Map<String, Object> data = new HashMap<>();
data.put("src_ip", "192.168.1.1");
data.put("dst_ip", "10.0.0.1");
Base64Util.encodeFieldsInMap(data, "src_ip", "dst_ip");
```

---

## 4. ClientIpUtil

**경로:** `util/ClientIpUtil.java`

클라이언트 IP 추출

### 4.1 사용법
```java
@GetMapping("/example")
public String example(HttpServletRequest request) {
    String clientIp = ClientIpUtil.getClientIp(request);
    // 프록시 뒤에서도 실제 IP 추출
}
```

### 4.2 체크 순서
1. `X-Forwarded-For` 헤더
2. `X-Real-IP` 헤더
3. `request.getRemoteAddr()`

---

## 5. MacAddressUtils

**경로:** `util/MacAddressUtils.java`

MAC 주소 처리

### 5.1 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `extractMacAddresses(String)` | 복수 MAC 문자열에서 개별 추출 |
| `normalizeMacAddress(String)` | MAC 정규화 (대문자, 구분자 통일) |
| `isMacAddressMatch(String, String)` | 두 MAC 매칭 확인 |
| `containsMacAddress(String, String)` | MAC 포함 여부 확인 |

### 5.2 사용 예시
```java
// 복수 MAC 추출
String dbMac = "AA:BB:CC:DD:EE:FF\n11-22-33-44-55-66";
List<String> macs = MacAddressUtils.extractMacAddresses(dbMac);
// → ["AA-BB-CC-DD-EE-FF", "11-22-33-44-55-66"]

// 정규화
String normalized = MacAddressUtils.normalizeMacAddress("aa:bb:cc:dd:ee:ff");
// → "AA-BB-CC-DD-EE-FF"

// 매칭 확인
boolean match = MacAddressUtils.isMacAddressMatch(dbMac, "AA:BB:CC:DD:EE:FF");
// → true
```

---

## 6. ResultCode

**경로:** `util/ResultCode.java`

API 응답 코드

```java
public enum ResultCode {
    SUCCESS(0, "성공"),
    FAIL(-1, "실패"),
    INVALID_PARAM(-2, "잘못된 파라미터"),
    NOT_FOUND(-3, "데이터 없음"),
    UNAUTHORIZED(-4, "권한 없음");
}
```

---

## 7. 기타 유틸리티

| 클래스 | 역할 |
|--------|------|
| `PasswordGenerator` | 랜덤 비밀번호 생성 |
| `MenuUtil` | 메뉴 트리 변환 |
| `JsonMapConverter` | JSON ↔ Map 변환 (JPA AttributeConverter) |
| `ExcelExportUtil` | 엑셀 다운로드 (`agent_docs/excel-download-system.md` 참조) |

---

## 8. JavaScript 유틸리티

**경로:** `static/js/common.js`

### 8.1 Zone3Util (JS)
```javascript
Zone3Util.normalize('sp_03');     // "3"
Zone3Util.toCode('3');            // "sp_03"
Zone3Util.toDisplayText('sp_03'); // "3호기"
Zone3Util.matches('sp_03', '3');  // true
```

### 8.2 GlobalErrorHandler (JS)
```javascript
$.ajax({
    url: '/api/data',
    error: function (xhr) {
        GlobalErrorHandler.handle(xhr);
    }
});
```

---

## 9. 참조 파일

| 파일 | 역할 |
|------|------|
| `util/Zone3Util.java` | 호기 문자열 처리 |
| `util/DateTimeUtil.java` | 날짜 변환 |
| `util/Base64Util.java` | Base64 인코딩 |
| `util/ClientIpUtil.java` | IP 추출 |
| `util/MacAddressUtils.java` | MAC 주소 처리 |
| `static/js/common.js` | JS 유틸리티 |
