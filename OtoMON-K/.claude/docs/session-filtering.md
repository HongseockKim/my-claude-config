# 세션 기반 필터링

> 호기(Zone)와 날짜 범위 필터링 메커니즘

---

## 1. 세션에 저장되는 데이터

| 세션 키 | 타입 | 설명 | 예시 |
|---------|------|------|------|
| `selectedZoneCode` | String | 선택된 호기 코드 | `sp_03`, `sp_04` |
| `startDate` | LocalDate | 시작 날짜 | `2025-12-01` |
| `endDate` | LocalDate | 종료 날짜 | `2025-12-23` |
| `dateRangeType` | String | 범위 유형 | `TODAY`, `WEEK`, `MONTH` |

---

## 2. Zone 필터링

### 2.1 Zone 계층 구조
```
zone1 (사업장)     → 남동발전
    └── zone2 (발전소)  → 삼천포발전본부
        ├── zone3 (호기) → sp_03 (3호기)
        └── zone3 (호기) → sp_04 (4호기)
```

### 2.2 Zone 선택 흐름

```
[헤더 호기 선택 드롭다운]
    │
    ▼
[ZoneController.selectZone()]
    │
    ▼
[세션에 selectedZoneCode 저장]
    │
    ▼
[페이지 리다이렉트]
```

### 2.3 Zone 기본값 설정
**테이블:** `system_config`

| config_key | config_value | zone3 |
|------------|--------------|-------|
| default_zone1 | 남동발전 | - |
| default_zone2 | 삼천포발전본부 | - |
| default_zone3 | sp_03 | sp_03 |

### 2.4 Repository 쿼리 패턴

```java
@Query("SELECT a FROM Asset a WHERE " +
       "(:zone1 IS NULL OR a.zoneInfo.zone1 = :zone1) AND " +
       "(:zone2 IS NULL OR a.zoneInfo.zone2 = :zone2) AND " +
       "(:zone3 IS NULL OR a.zoneInfo.zone3 LIKE CONCAT('%', :zone3, '%'))")
List<Asset> findByZone(@Param("zone1") String zone1,
                       @Param("zone2") String zone2,
                       @Param("zone3") String zone3);
```

**참고:** zone3는 복수 선택 가능 (예: `sp_03,sp_04`)

---

## 3. 날짜 범위 필터링

### 3.1 날짜 선택 흐름

```
[헤더 날짜 선택 컴포넌트]
    │
    ▼
[DateRangeController.setDateRange()]
    │
    ▼
[세션에 startDate, endDate 저장]
    │
    ▼
[AJAX로 데이터 새로고침]
```

### 3.2 DateRangeController
**경로:** `controller/DateRangeController.java`

```java
@PostMapping("/date-range/set")
@ResponseBody
public Map<String, Object> setDateRange(
    @RequestParam String startDate,
    @RequestParam String endDate,
    @RequestParam String type,
    HttpSession session) {

    session.setAttribute("startDate", LocalDate.parse(startDate));
    session.setAttribute("endDate", LocalDate.parse(endDate));
    session.setAttribute("dateRangeType", type);

    return Map.of("ret", 0, "message", "날짜 범위 설정 완료");
}
```

### 3.3 Service에서 날짜 범위 사용

```java
public List<Event> getEvents(HttpSession session) {
    LocalDate start = (LocalDate) session.getAttribute("startDate");
    LocalDate end = (LocalDate) session.getAttribute("endDate");

    if (start == null) {
        start = LocalDate.now().minusDays(7);
        end = LocalDate.now();
    }

    return eventRepository.findByDateBetween(start, end);
}
```

---

## 4. Controller에서 필터 적용

### 4.1 세션에서 직접 가져오기
```java
@GetMapping("/assets")
public String getAssets(HttpSession session, Model model) {
    String zone3 = (String) session.getAttribute("selectedZoneCode");
    List<Asset> assets = assetService.findByZone(null, null, zone3);
    model.addAttribute("assets", assets);
    return "pages/asset/list";
}
```

### 4.2 요청 파라미터와 세션 조합
```java
@GetMapping("/operation")
public String operation(
    @RequestParam(required = false) String zone3,
    HttpSession session,
    Model model) {

    // 파라미터 우선, 없으면 세션 사용
    if (zone3 == null) {
        zone3 = (String) session.getAttribute("selectedZoneCode");
    }

    // ...
}
```

---

## 5. Zone3Util 사용

**경로:** `util/Zone3Util.java`

```java
// 복수 호기 문자열 파싱
List<String> zones = Zone3Util.parseZone3("sp_03,sp_04");
// → ["sp_03", "sp_04"]

// 호기 목록을 문자열로
String zone3Str = Zone3Util.joinZone3(Arrays.asList("sp_03", "sp_04"));
// → "sp_03,sp_04"

// 특정 호기 포함 여부
boolean contains = Zone3Util.containsZone("sp_03,sp_04", "sp_03");
// → true
```

---

## 6. 참조 파일

| 파일 | 역할 |
|------|------|
| `controller/ZoneController.java` | 호기 선택 처리 |
| `controller/DateRangeController.java` | 날짜 범위 처리 |
| `interceptor/ZoneInterceptor.java` | 호기 세션 설정 |
| `interceptor/DateRangeInterceptor.java` | 날짜 세션 설정 |
| `util/Zone3Util.java` | 호기 문자열 유틸 |
| `service/SystemConfigService.java` | 기본값 조회 |
