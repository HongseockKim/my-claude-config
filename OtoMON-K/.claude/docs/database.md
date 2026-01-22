# 데이터베이스 패턴

> MariaDB (JPA) + ClickHouse (JDBC) 이중 DB 구조

---

## 1. 데이터베이스 구분

| DB | 용도 | 접근 방식 | 설정 파일 |
|----|------|----------|----------|
| **MariaDB** | 메타데이터, 설정, 사용자 | JPA/Hibernate | `PrimaryDataSourceConfig.java` |
| **ClickHouse** | 시계열 데이터 (이벤트, 통계) | JdbcTemplate | `ClickHouseConfig.java` |

```
┌─────────────────────────────────────────────────────────────┐
│                      APPLICATION                             │
├─────────────────────────────────────────────────────────────┤
│  Repository (JPA)          │  ClickHouseService (JDBC)      │
│  ↓                         │  ↓                             │
│  MariaDB                   │  ClickHouse                    │
│  - Asset, User, Menu       │  - Event, Stats1Min            │
│  - AlarmConfig, Code       │  - TrafficMetric               │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. MariaDB (JPA)

### 2.1 Repository 기본 패턴
```java
public interface AssetRepository extends JpaRepository<Asset, Long> {
    // 기본 CRUD: save(), findById(), findAll(), delete()
}
```

### 2.2 @Query 사용
```java
@Query("SELECT a FROM Asset a WHERE a.isDeleted = false " +
       "AND (:zone3 IS NULL OR a.zoneInfo.zone3 LIKE %:zone3%)")
List<Asset> findActiveByZone(@Param("zone3") String zone3);
```

### 2.3 Native Query
```java
@Query(value = "SELECT * FROM Asset WHERE status = :status",
       nativeQuery = true)
List<Asset> findByStatusNative(@Param("status") String status);
```

### 2.4 주요 Repository 목록 (45개)

| 카테고리 | Repository |
|----------|------------|
| **자산** | AssetRepository, AssetRawRepository |
| **알람** | AlarmConfigRepository, AlarmHistoryRepository, AlarmActionRepository, AlarmManagerRepository |
| **사용자** | UserRepository, UserGroupRepository, GroupPermissionRepository, GroupMenuMappingRepository |
| **정책** | DetectionPolicyRepository, WhiteListPolicyRepository, ServicePortPolicyRepository |
| **토폴로지** | TopologyNetRepository, TopologyPhysicalRepository, TopologySwitchRepository |
| **대시보드** | DashboardTemplateRepository, DashboardWidgetRepository |
| **코드** | CodeRepository, CodeTypeRepository, CodeGroupRepository |
| **설정** | SystemConfigRepository, MonitoringConfigRepository |
| **로그** | SystemActivityLogRepository, AuditLogSettingRepository |

---

## 3. ClickHouse (JDBC)

### 3.1 ClickHouseService
**경로:** `service/ClickHouseService.java`

```java
@Service
@RequiredArgsConstructor
public class ClickHouseService {
    private final JdbcTemplate clickHouseJdbcTemplate;

    public List<Map<String, Object>> queryEvents(
            LocalDateTime start, LocalDateTime end, String zone3) {

        String sql = """
            SELECT * FROM events
            WHERE timestamp BETWEEN ? AND ?
            AND zone3 = ?
            ORDER BY timestamp DESC
            LIMIT 1000
        """;

        return clickHouseJdbcTemplate.queryForList(sql, start, end, zone3);
    }
}
```

### 3.2 ClickHouse 테이블 예시

| 테이블 | 용도 |
|--------|------|
| `events` | 이벤트 로그 |
| `stats_1min` | 1분 통계 |
| `stats_10min` | 10분 통계 |
| `traffic_metrics` | 트래픽 지표 |

### 3.3 IP 암호화 처리
ClickHouse 쿼리 시 IP 주소 암호화/복호화:

```java
// 조회 후 복호화
String encryptedIp = row.get("src_ip");
String decryptedIp = Base64Util.decode(encryptedIp);
```

---

## 4. 트랜잭션 관리

### 4.1 기본 트랜잭션
```java
@Service
@Transactional(readOnly = true)
public class AssetService {

    @Transactional
    public void updateAsset(AssetDto dto) {
        // 쓰기 작업
    }
}
```

### 4.2 다중 DB 트랜잭션
MariaDB와 ClickHouse는 별도 트랜잭션:

```java
@Transactional  // MariaDB만 적용
public void saveWithStats(AssetDto dto) {
    assetRepository.save(toEntity(dto));

    // ClickHouse는 별도 (트랜잭션 없음)
    clickHouseService.insertStats(dto);
}
```

---

## 5. 페이징 처리

### 5.1 JPA Pageable
```java
Page<Asset> findByZone(String zone3, Pageable pageable);

// 호출
Pageable pageable = PageRequest.of(0, 20, Sort.by("registrantDate").descending());
Page<Asset> page = assetRepository.findByZone("sp_03", pageable);
```

### 5.2 무한 스크롤 (AG Grid)
```java
@GetMapping("/infinite")
public Map<String, Object> getInfinite(
    @RequestParam int startRow,
    @RequestParam int endRow) {

    List<Asset> data = assetService.getRange(startRow, endRow);
    long total = assetService.count();

    return Map.of("data", data, "totalCount", total);
}
```

---

## 6. 설정 파일

### 6.1 application.properties
```properties
# MariaDB
spring.datasource.url=jdbc:mariadb://localhost:3306/otomon
spring.datasource.username=root
spring.datasource.password=****

# ClickHouse
clickhouse.url=jdbc:clickhouse://localhost:8123/default
clickhouse.username=default
clickhouse.password=
```

### 6.2 PrimaryDataSourceConfig
**경로:** `config/PrimaryDataSourceConfig.java`

```java
@Configuration
@EnableJpaRepositories(basePackages = "com.otoones.otomon.repository")
public class PrimaryDataSourceConfig {
    @Bean
    @Primary
    public DataSource dataSource() { ... }
}
```

### 6.3 ClickHouseConfig
**경로:** `config/ClickHouseConfig.java`

```java
@Configuration
public class ClickHouseConfig {
    @Bean(name = "clickHouseJdbcTemplate")
    public JdbcTemplate clickHouseJdbcTemplate() { ... }
}
```

---

## 7. 참조 파일

| 파일 | 역할 |
|------|------|
| `config/PrimaryDataSourceConfig.java` | MariaDB 설정 |
| `config/ClickHouseConfig.java` | ClickHouse 설정 |
| `config/JpaConfig.java` | JPA 설정 |
| `service/ClickHouseService.java` | ClickHouse 쿼리 |
| `repository/*.java` | JPA Repository (45개) |
