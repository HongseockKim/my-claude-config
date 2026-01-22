# 개발 워크플로우

> 새 기능 추가 가이드

---

## 1. 개발 순서

```
[DB] → [Entity] → [Repository] → [Service] → [Controller] → [JS] → [HTML]
```

---

## 2. Controller 추가

### 2.1 기본 구조
```java
@Slf4j
@Controller
@RequestMapping("/feature")
@RequiredArgsConstructor
public class FeatureController {
    private static final long MENU_ID = 9999L;  // 메뉴 ID

    private final FeatureService featureService;
    private final MessageService messageService;

    @RequirePermission(menuId = MENU_ID,
                       resourceType = ResourceType.MENU,
                       permissionType = PermissionType.READ)
    @GetMapping("")
    public String index(Model model, HttpSession session) {
        String zone3 = (String) session.getAttribute("selectedZoneCode");
        model.addAttribute("data", featureService.findByZone(zone3));
        return "pages/feature/index";
    }
}
```

### 2.2 API 응답 형식
```java
@PostMapping("/save")
@ResponseBody
public Map<String, Object> save(@RequestBody FeatureDto dto) {
    try {
        featureService.save(dto);
        return Map.of("ret", 0, "message", "저장 완료");
    } catch (Exception e) {
        return Map.of("ret", -1, "message", e.getMessage());
    }
}
```

---

## 3. Service 추가

### 3.1 기본 구조
```java
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FeatureService {

    private final FeatureRepository featureRepository;

    public List<Feature> findByZone(String zone3) {
        return featureRepository.findByZone3(zone3);
    }

    @Transactional
    public void save(FeatureDto dto) {
        Feature entity = toEntity(dto);
        featureRepository.save(entity);
    }
}
```

---

## 4. Repository 추가

### 4.1 JPA Repository
```java
public interface FeatureRepository extends JpaRepository<Feature, Long> {

    List<Feature> findByZone3(String zone3);

    @Query("SELECT f FROM Feature f WHERE f.isDeleted = false " +
           "AND (:zone3 IS NULL OR f.zone3 = :zone3)")
    List<Feature> findActiveByZone(@Param("zone3") String zone3);
}
```

---

## 5. Entity 추가

### 5.1 기본 구조
```java
@Entity
@Table(name = "feature")
@Getter @Setter
@NoArgsConstructor
public class Feature {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "zone3", length = 20)
    private String zone3;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "is_deleted")
    private Boolean isDeleted = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
```

---

## 6. 권한 설정

### 6.1 @RequirePermission
```java
@RequirePermission(
    menuId = 9999L,                      // 메뉴 ID (menu 테이블)
    resourceType = ResourceType.MENU,    // MENU, API, DATA
    permissionType = PermissionType.READ // READ, WRITE, DELETE
)
```

### 6.2 PermissionType
| 타입 | 설명 |
|------|------|
| `READ` | 조회 권한 |
| `WRITE` | 생성/수정 권한 |
| `DELETE` | 삭제 권한 |

### 6.3 메뉴 등록 (DB)
```sql
INSERT INTO menu (id, name, url, parent_id, sort_order)
VALUES (9999, '새 기능', '/feature', 2000, 10);
```

---

## 7. 감사 로그 (@ActivityLog)

### 7.1 사용법
```java
@ActivityLog(
    category = "FEATURE",           // 카테고리
    action = "CREATE",              // CREATE, UPDATE, DELETE, READ
    resourceType = "FEATURE"        // 리소스 타입
)
@PostMapping("/save")
public Map<String, Object> save(@RequestBody FeatureDto dto) {
    // ...
}
```

### 7.2 주요 Category
| Category | 설명 |
|----------|------|
| `USER_MANAGE` | 사용자 관리 |
| `ASSET_MANAGE` | 자산 관리 |
| `POLICY_MANAGE` | 정책 관리 |
| `SETTING_MANAGE` | 설정 관리 |
| `ANALYSIS` | 분석 |

**상세:** `agent_docs/audit-log-system.md` 참조

---

## 8. DTO 추가

### 8.1 기본 구조
```java
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
public class FeatureDto {

    private Long id;
    private String zone3;
    private String name;

    // Entity 변환
    public static FeatureDto from(Feature entity) {
        FeatureDto dto = new FeatureDto();
        dto.setId(entity.getId());
        dto.setZone3(entity.getZone3());
        dto.setName(entity.getName());
        return dto;
    }
}
```

---

## 9. 템플릿 추가

### 9.1 페이지 생성
**경로:** `templates/pages/feature/index.html`

```html
<html layout:decorate="~{layouts/default}">
<head>
    <th:block layout:fragment="style">
        <!-- 페이지별 CSS -->
    </th:block>
</head>
<body>
    <th:block layout:fragment="content">
        <h1 class="page-header">새 기능</h1>

        <div id="myGrid" class="ag-theme-quartz"
             style="height: 500px;"></div>
    </th:block>

    <th:block layout:fragment="scripts">
        <script>
            // 페이지 JavaScript
        </script>
    </th:block>
</body>
</html>
```

---

## 10. 체크리스트

| 단계 | 체크 |
|------|:----:|
| Entity 생성 | ☐ |
| Repository 생성 | ☐ |
| Service 생성 | ☐ |
| DTO 생성 | ☐ |
| Controller 생성 | ☐ |
| @RequirePermission 적용 | ☐ |
| @ActivityLog 적용 (CRUD) | ☐ |
| 메뉴 등록 (DB) | ☐ |
| 템플릿 생성 | ☐ |
| JavaScript 작성 | ☐ |

---

## 11. 참조 파일

| 파일 | 역할 |
|------|------|
| `controller/AssetController.java` | Controller 예시 |
| `service/AssetService.java` | Service 예시 |
| `repository/AssetRepository.java` | Repository 예시 |
| `model/Asset.java` | Entity 예시 |
| `dto/AssetDto.java` | DTO 예시 |
| `agent_docs/permission-system.md` | 권한 시스템 |
| `agent_docs/audit-log-system.md` | 감사 로그 |
