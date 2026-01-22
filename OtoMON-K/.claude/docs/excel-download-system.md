# 엑셀 다운로드 시스템

> @ExcelColumn + ExcelExportUtil 기반 엑셀 내보내기

---

## 1. 개요

```
[DTO with @ExcelColumn]
        │
        ▼
[ExcelExportUtil.exportToExcel()]
        │
        ▼
[ByteArrayResource (xlsx)]
        │
        ▼
[ResponseEntity 반환]
```

---

## 2. @ExcelColumn 어노테이션

**경로:** `annotation/ExcelColumn.java`

### 2.1 속성

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `header` | String | (필수) | 엑셀 헤더 텍스트 |
| `order` | int | 0 | 컬럼 순서 |
| `width` | int | 0 (auto) | 컬럼 너비 (문자 수) |
| `dateFormat` | String | `yyyy-MM-dd HH:mm:ss` | 날짜 포맷 |
| `alignment` | Alignment | `AUTO` | 정렬 방식 |
| `exclude` | boolean | false | 내보내기 제외 |

### 2.2 Alignment 옵션

| 값 | 설명 |
|----|------|
| `AUTO` | 자동 (숫자: 우측, 날짜: 중앙, 문자: 좌측) |
| `LEFT` | 좌측 정렬 |
| `CENTER` | 중앙 정렬 |
| `RIGHT` | 우측 정렬 |

---

## 3. DTO 정의

### 3.1 예시
```java
@Getter @Setter
@NoArgsConstructor
public class FeatureExcelDto {

    @ExcelColumn(header = "No", order = 1, width = 6,
                 alignment = ExcelColumn.Alignment.CENTER)
    private Integer rowNum;

    @ExcelColumn(header = "이름", order = 2, width = 20)
    private String name;

    @ExcelColumn(header = "상태", order = 3, width = 10,
                 alignment = ExcelColumn.Alignment.CENTER)
    private String status;

    @ExcelColumn(header = "등록일", order = 4, width = 18,
                 dateFormat = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;

    @ExcelColumn(header = "수량", order = 5, width = 10,
                 alignment = ExcelColumn.Alignment.RIGHT)
    private Integer count;

    // 내보내기 제외 필드
    @ExcelColumn(header = "", exclude = true)
    private Long internalId;
}
```

---

## 4. ExcelExportUtil

**경로:** `util/ExcelExportUtil.java`

### 4.1 사용법
```java
List<FeatureExcelDto> dataList = service.getExcelData();

ByteArrayResource resource = ExcelExportUtil.exportToExcel(
    dataList,
    FeatureExcelDto.class,
    "시트이름"
);
```

### 4.2 기능
- 최대 100,000행 지원
- 자동 필터 설정
- 헤더 행 고정 (Freeze Pane)
- 홀수/짝수 행 색상 구분
- 자동 컬럼 너비 조정

---

## 5. Controller 구현

### 5.1 기본 패턴
```java
@GetMapping("/excel")
public ResponseEntity<Resource> downloadExcel(
        @RequestParam(required = false) String zone3) {

    // 1. 데이터 조회
    List<FeatureExcelDto> dataList = featureService.getExcelData(zone3);

    // 2. 엑셀 생성
    ByteArrayResource resource = ExcelExportUtil.exportToExcel(
        dataList,
        FeatureExcelDto.class,
        "기능목록"
    );

    if (resource == null) {
        return ResponseEntity.noContent().build();
    }

    // 3. 파일명 생성
    String timestamp = LocalDateTime.now()
        .format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
    String filename = "feature_" + timestamp + ".xlsx";

    // 4. 응답 반환
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_DISPOSITION,
            "attachment; filename=\"" + filename + "\"")
        .contentType(MediaType.APPLICATION_OCTET_STREAM)
        .contentLength(resource.contentLength())
        .body(resource);
}
```

### 5.2 한글 파일명 처리
```java
String filename = "기능목록_" + timestamp + ".xlsx";
String encodedFilename = URLEncoder.encode(filename, StandardCharsets.UTF_8)
    .replace("+", "%20");

return ResponseEntity.ok()
    .header(HttpHeaders.CONTENT_DISPOSITION,
        "attachment; filename*=UTF-8''" + encodedFilename)
    .contentType(MediaType.APPLICATION_OCTET_STREAM)
    .body(resource);
```

---

## 6. 감사 로그 연동

```java
@ActivityLog(
    category = "FEATURE_MANAGE",
    action = "EXCEL_DOWN_ALL",
    resourceType = "FEATURE"
)
@GetMapping("/excel")
public ResponseEntity<Resource> downloadExcel(...) {
    // ...
}
```

---

## 7. Entity → ExcelDto 변환

```java
public static FeatureExcelDto from(Feature entity, int rowNum) {
    FeatureExcelDto dto = new FeatureExcelDto();
    dto.setRowNum(rowNum);
    dto.setName(entity.getName());
    dto.setStatus(entity.getStatus());
    dto.setCreatedAt(entity.getCreatedAt());
    dto.setCount(entity.getCount());
    return dto;
}

// Service에서 사용
public List<FeatureExcelDto> getExcelData(String zone3) {
    List<Feature> entities = repository.findByZone3(zone3);
    AtomicInteger rowNum = new AtomicInteger(1);
    return entities.stream()
        .map(e -> FeatureExcelDto.from(e, rowNum.getAndIncrement()))
        .toList();
}
```

---

## 8. 기존 ExcelDto 목록

| DTO | 용도 |
|-----|------|
| `AssetExcelDto` | 자산 목록 |
| `UserExcelDto` | 사용자 목록 |
| `AnalysisAndActionExcelDto` | 분석/조치 이력 |
| `TrafficDetailExcelDto` | 트래픽 상세 |

---

## 9. 참조 파일

| 파일 | 역할 |
|------|------|
| `annotation/ExcelColumn.java` | 어노테이션 정의 |
| `util/ExcelExportUtil.java` | 엑셀 생성 유틸 |
| `dto/*ExcelDto.java` | 엑셀용 DTO |
| `controller/AssetController.java` | 다운로드 예시 (line 390+) |
