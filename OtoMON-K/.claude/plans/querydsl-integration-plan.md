# QueryDSL 통합 프로젝트 플랜

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **목표** | JPA Repository의 복잡한 @Query 및 동적 쿼리를 QueryDSL로 마이그레이션 |
| **핵심 효과** | 타입 안전성, 코드 중복 제거, 성능 최적화 |
| **예상 범위** | Repository 47개, Service 36개, @Query 148개 |

---

## 현재 상태 분석 요약

### 1. 빌드 환경

| 항목 | 현재 | 필요 |
|------|------|------|
| Spring Boot | 3.4.5 | 3.4.5 (호환) |
| Java | 17 | 17 (호환) |
| JPA | spring-boot-starter-data-jpa | 유지 |
| QueryDSL | **없음** | 5.0.0+ 필요 |
| Persistence API | jakarta.persistence | jakarta (정상) |

### 2. Repository 복잡도 분포

| 복잡도 | 개수 | 비율 | 대표 Repository |
|--------|------|------|-----------------|
| **HIGH** (5+ 메서드) | 8 | 17% | EventRepository, Stats1MinRepository, UserRepository |
| **MEDIUM** (3-5 메서드) | 15 | 32% | AssetRepository, WhiteListPolicyRepository |
| **LOW** (0-2 메서드) | 24 | 51% | CodeRepository, MenuRepository |

### 3. @Query 어노테이션 현황

| 유형 | 개수 | 비율 |
|------|------|------|
| **Total** | 148 | 100% |
| Native SQL | 87 | 59% |
| JPQL | 61 | 41% |
| 복잡도 HIGH | 68 | 46% |
| 복잡도 MEDIUM | 48 | 32% |
| 복잡도 LOW | 32 | 22% |

### 4. Entity 구조

| 항목 | 개수 |
|------|------|
| **Total Entities** | 47 |
| Embeddable | 2 (ZoneInfo, LinkId) |
| 복잡한 관계 (5+) | 6 (User, UserGroup, Menu, AlarmConfig, Report, DashboardTemplate) |
| ZoneInfo 사용 | 9 entities |

### 5. 주요 문제점

| 문제 | 영향 범위 | 심각도 |
|------|----------|--------|
| **In-Memory 필터링** | DetectionService, AssetService | 🔴 CRITICAL |
| **복잡한 CTE 쿼리 중복** | Stats1MinRepository (6개 유사 쿼리) | 🔴 CRITICAL |
| **동적 정렬 CASE WHEN** | UserRepository (8개 CASE문) | 🟡 HIGH |
| **Zone3 LIKE 패턴 중복** | 8+ repositories, 17+ methods | 🟡 HIGH |
| **String.format SQL (인젝션 위험)** | ClickHouse 쿼리 40+ 개소 | 🔴 CRITICAL |
| **AG Grid 필터 수동 처리** | 5+ controllers | 🟡 MEDIUM |

---

## Phase 1: QueryDSL 설정 (우선순위: 최상)

### 1.1 Maven 의존성 추가

**pom.xml** 수정:

```xml
<!-- QueryDSL Dependencies (라인 237 이전에 추가) -->
<dependency>
    <groupId>com.querydsl</groupId>
    <artifactId>querydsl-jpa</artifactId>
    <version>5.0.0</version>
    <classifier>jakarta</classifier>
</dependency>
<dependency>
    <groupId>com.querydsl</groupId>
    <artifactId>querydsl-apt</artifactId>
    <version>5.0.0</version>
    <classifier>jakarta</classifier>
    <scope>provided</scope>
</dependency>
```

### 1.2 Annotation Processor 설정

**pom.xml** (라인 286-292 maven-compiler-plugin 내):

```xml
<annotationProcessorPaths>
    <path>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>${lombok.version}</version>
    </path>
    <!-- QueryDSL APT 추가 -->
    <path>
        <groupId>com.querydsl</groupId>
        <artifactId>querydsl-apt</artifactId>
        <version>5.0.0</version>
        <classifier>jakarta</classifier>
    </path>
    <path>
        <groupId>jakarta.persistence</groupId>
        <artifactId>jakarta.persistence-api</artifactId>
        <version>3.1.0</version>
    </path>
</annotationProcessorPaths>
```

### 1.3 Q클래스 생성 확인

```bash
mvnw.cmd clean compile
# target/generated-sources/java/com/otoones/otomon/model/ 에 Q*.java 생성 확인
```

**예상 Q클래스:** 49개 (47 Entity + 2 Embeddable)

### 1.4 QueryDSL Configuration 클래스 생성

**신규 파일:** `src/main/java/com/otoones/otomon/config/QueryDslConfig.java`

```java
@Configuration
@RequiredArgsConstructor
public class QueryDslConfig {

    private final EntityManager entityManager;

    @Bean
    public JPAQueryFactory jpaQueryFactory() {
        return new JPAQueryFactory(entityManager);
    }
}
```

---

## Phase 2: 핵심 Repository 마이그레이션 (우선순위: 상)

### 2.1 Stats1MinRepository - CTE 쿼리 통합

**현재 문제:**
- 6개 유사 CTE 쿼리 (각 80-230 라인)
- `findAggregated10MinData`, `findAggregated10MinDataByRange`, `findLatestAggregated10MinData` 등

**수정 대상:**
| 파일 | 위치 | 현재 | 개선 |
|------|------|------|------|
| Stats1MinRepository.java | :18-97 | 79라인 CTE | 단일 동적 메서드 |
| Stats1MinRepository.java | :102-173 | 동일 CTE + Range | 통합 |
| Stats1MinRepository.java | :237-317 | 동일 CTE + Zone | 통합 |

**QueryDSL 개선:**
```java
public List<Stats1MinDto> findAggregatedData(
    Optional<LocalDateTime> startTime,
    Optional<LocalDateTime> endTime,
    Optional<String> zone3,
    Optional<Integer> limit
) {
    QStats1Min s = QStats1Min.stats1Min;
    BooleanBuilder where = new BooleanBuilder();

    startTime.ifPresent(st -> where.and(s.timeStamp.goe(st)));
    endTime.ifPresent(et -> where.and(s.timeStamp.loe(et)));
    zone3.ifPresent(z -> where.and(s.zone3.eq(z)));

    return queryFactory.select(...)
        .from(s)
        .where(where)
        .orderBy(s.aggregatedTime.desc())
        .limit(limit.orElse(Integer.MAX_VALUE))
        .fetch();
}
```

**예상 효과:** 6개 메서드 → 1개 메서드, 350+ 라인 제거

---

### 2.2 EventRepository - IP 매칭 쿼리 통합

**현재 문제:**
- 6개 UNION 쿼리 (라인 434-459, 465-481, 490-515, 523-548)
- 동일한 IP 매칭 로직 반복

**QueryDSL 개선:**
```java
public List<EventDto> findRelatedEvents(String srcIp, String dstIp, Long currentEventId) {
    QEvent event = QEvent.event;
    QEventDefinition ed = QEventDefinition.eventDefinition;

    BooleanExpression ipMatch = event.srcIp.eq(srcIp)
        .or(event.dstIp.eq(srcIp))
        .or(event.srcIp.eq(dstIp))
        .or(event.dstIp.eq(dstIp));

    BooleanBuilder where = new BooleanBuilder(ipMatch);
    if (currentEventId != null) {
        where.and(event.id.ne(currentEventId));
    }

    return queryFactory.select(new QEventDto(event, ed))
        .from(event)
        .leftJoin(ed).on(event.eventCode.eq(ed.eventCode))
        .where(where)
        .orderBy(event.detectedAt.desc())
        .limit(1000)
        .fetch();
}
```

**예상 효과:** 6개 메서드 → 1개 메서드, UNION 제거

---

### 2.3 UserRepository - 동적 정렬 개선

**현재 문제 (라인 49-55):**
```sql
ORDER BY
    CASE WHEN :#{#criteria.sortColumn} = 'idx' AND :#{#criteria.sortDirection} = 'asc' THEN u.idx END ASC,
    CASE WHEN :#{#criteria.sortColumn} = 'idx' AND :#{#criteria.sortDirection} = 'desc' THEN u.idx END DESC,
    -- ... 6개 더
```

**QueryDSL 개선:**
```java
private OrderSpecifier<?> buildOrderSpecifier(String sortColumn, String sortDirection) {
    QUser user = QUser.user;

    PathBuilder<User> path = new PathBuilder<>(User.class, "user");
    return new OrderSpecifier<>(
        "desc".equals(sortDirection) ? Order.DESC : Order.ASC,
        path.get(sortColumn, Comparable.class)
    );
}
```

**예상 효과:** 8개 CASE WHEN → 1개 메서드, 확장 용이

---

## Phase 3: Service 레이어 최적화 (우선순위: 상)

### 3.1 DetectionService - In-Memory 필터링 제거

**현재 문제 (라인 1510-1596):**
```java
// 전체 로드 후 Java Stream 필터링
List<Event> violationEvents = allEvents.stream()
    .filter(event -> isViolationOptimized(event, whitelistPolicyMap))
    .collect(Collectors.toList());
```

**수정 대상:**
| 메서드 | 위치 | 문제 | 개선 |
|--------|------|------|------|
| getEventsPagedFiltered | :1510-1596 | 4개 쿼리 경로, In-Memory 필터 | 단일 동적 쿼리 |
| getEventsPaged | :1600-1691 | 10,000건 로드 후 필터 | DB 레벨 필터링 |
| applyFilters | :894-1073 | 180라인 if-else 체인 | Predicate Builder |

**QueryDSL 개선:**
```java
public Page<EventDto> getEventsFiltered(EventSearchCriteria criteria, Pageable pageable) {
    QEvent event = QEvent.event;
    QWhitelistPolicy policy = QWhitelistPolicy.whitelistPolicy;
    QEventDefinition ed = QEventDefinition.eventDefinition;

    BooleanBuilder where = new BooleanBuilder();

    // 동적 조건
    if (criteria.getStartDate() != null) {
        where.and(event.detectedAt.between(criteria.getStartDate(), criteria.getEndDate()));
    }
    if (StringUtils.hasText(criteria.getZone3())) {
        where.and(event.zone3.eq(criteria.getZone3()));
    }
    if (StringUtils.hasText(criteria.getEventType())) {
        where.and(ed.eventType.eq(criteria.getEventType()));
    }

    // Whitelist violation 조건 (policy가 없으면 violation)
    where.and(policy.id.isNull());

    return queryFactory.select(new QEventDto(event, ed))
        .from(event)
        .leftJoin(policy).on(
            event.srcIp.eq(policy.srcIp)
            .and(event.dstIp.eq(policy.dstIp))
            .and(event.dstPort.eq(policy.dstPort))
            .and(policy.isShow.isTrue())
        )
        .leftJoin(ed).on(event.eventCode.eq(ed.eventCode))
        .where(where)
        .orderBy(event.detectedAt.desc())
        .offset(pageable.getOffset())
        .limit(pageable.getPageSize())
        .fetchResults();
}
```

**예상 효과:** 60-70% 메모리 사용량 감소

---

### 3.2 DataService - 다중 쿼리 통합

**현재 문제 (라인 104-116):**
```java
// 4개 별도 쿼리
List<OpTag> sp03List = opTagRepository.findBy...("sp_03", ...);
List<OpTag> sp04List = opTagRepository.findBy...("sp_04", ...);
List<OpTag> sp03NumList = opTagRepository.findBy...("3", ...);
List<OpTag> sp04NumList = opTagRepository.findBy...("4", ...);
// 수동 리스트 병합
opList.addAll(sp03List);
opList.addAll(sp04List);
```

**QueryDSL 개선:**
```java
public List<OpTag> findByZoneAndDateRange(String zone1, String zone2,
    List<String> zone3List, LocalDateTime start, LocalDateTime end) {

    QOpTag opTag = QOpTag.opTag;

    return queryFactory.selectFrom(opTag)
        .where(opTag.zoneInfo.zone1.eq(zone1)
            .and(opTag.zoneInfo.zone2.eq(zone2))
            .and(opTag.zoneInfo.zone3.in(zone3List))
            .and(opTag.createdAt.between(start, end)))
        .fetch();
}
```

**예상 효과:** 4개 DB 호출 → 1개

---

### 3.3 DashboardService - findAll() 제거

**현재 문제 (라인 102-109):**
```java
// 전체 로드 후 In-Memory 필터링
List<OpTag> result = opTagRepository.findAll().stream()
    .filter(opTag -> zone3.equals(opTag.getZoneInfo().getZone3()))
    .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()))
    .limit(7)
    .toList();
```

**QueryDSL 개선:**
```java
public List<OpTag> selectOpTagList(String zone3, int limit) {
    QOpTag opTag = QOpTag.opTag;

    return queryFactory.selectFrom(opTag)
        .where(opTag.zoneInfo.zone3.eq(zone3))
        .orderBy(opTag.createdAt.desc())
        .limit(limit)
        .fetch();
}
```

**예상 효과:** 전체 테이블 → 7건만 로드

---

## Phase 4: 공통 유틸리티 (우선순위: 중)

### 4.1 Zone 필터 유틸리티

**현재 문제:** 17+ 메서드에서 Zone3 LIKE 패턴 중복

```java
// 반복되는 패턴
AND (:zone3 IS NULL OR e.zone3 = :zone3)
AND zone3 LIKE CONCAT('%', :zone3, '%')
```

**신규 파일:** `src/main/java/com/otoones/otomon/repository/support/QueryDslPredicates.java`

```java
@UtilityClass
public class QueryDslPredicates {

    public static BooleanExpression zoneEquals(StringPath zonePath, String zone) {
        if (!StringUtils.hasText(zone)) return null;
        return zonePath.eq(zone);
    }

    public static BooleanExpression zoneContains(StringPath zonePath, String zone) {
        if (!StringUtils.hasText(zone)) return null;
        return zonePath.contains(zone);
    }

    public static BooleanExpression dateBetween(DateTimePath<LocalDateTime> datePath,
            LocalDateTime start, LocalDateTime end) {
        if (start == null || end == null) return null;
        return datePath.between(start, end);
    }
}
```

---

### 4.2 AG Grid 필터 변환기

**신규 파일:** `src/main/java/com/otoones/otomon/repository/support/AgGridPredicateBuilder.java`

```java
@Component
public class AgGridPredicateBuilder {

    public <T> BooleanBuilder buildPredicate(Map<String, FilterModel> filterModel,
            PathBuilder<T> entityPath) {

        BooleanBuilder builder = new BooleanBuilder();

        filterModel.forEach((columnId, filter) -> {
            StringPath path = entityPath.getString(columnId);

            switch (filter.getType()) {
                case "contains" -> builder.and(path.containsIgnoreCase(filter.getFilter()));
                case "equals" -> builder.and(path.eq(filter.getFilter()));
                case "startsWith" -> builder.and(path.startsWithIgnoreCase(filter.getFilter()));
                // ... 추가 필터 타입
            }
        });

        return builder;
    }
}
```

---

## Phase 5: ClickHouse 쿼리 안전성 (우선순위: 상)

### 5.1 현재 SQL 인젝션 위험

**위험 패턴 (40+ 개소):**
```java
// AssetTrafficService.java:439-442
String sql = String.format("""
    SELECT ... FROM ZeekConn
    WHERE zone1 = '%s' AND zone2 = '%s' AND zone3 IN (%s)
    """, zone1, zone2, zone3Values);
```

### 5.2 안전한 파라미터 바인딩 적용

**개선 방향:**
```java
// NamedParameterJdbcTemplate 사용
String sql = """
    SELECT ... FROM ZeekConn
    WHERE zone1 = :zone1 AND zone2 = :zone2 AND zone3 IN (:zone3List)
    """;

MapSqlParameterSource params = new MapSqlParameterSource()
    .addValue("zone1", zone1)
    .addValue("zone2", zone2)
    .addValue("zone3List", zone3List);

return namedParameterJdbcTemplate.query(sql, params, rowMapper);
```

### 5.3 ClickHouse 쿼리 빌더 (Optional)

QueryDSL-SQL 또는 jOOQ 도입 검토 (별도 Phase)

---

## Phase 6: Repository Interface 확장 (우선순위: 중)

### 6.1 QuerydslPredicateExecutor 추가

**수정 대상 (47개 Repository 중 우선순위 8개):**

```java
// Before
public interface EventRepository extends JpaRepository<Event, Long>

// After
public interface EventRepository extends JpaRepository<Event, Long>,
    QuerydslPredicateExecutor<Event>
```

**우선순위 Repository:**
1. EventRepository
2. AssetRepository
3. UserRepository
4. WhiteListPolicyRepository
5. Stats1MinRepository
6. SystemActivityLogRepository
7. OpTagRepository
8. AlarmHistoryRepository

---

## 파일별 수정 체크리스트

### Phase 1: 설정
| 파일 | 수정 내용 | 예상 라인 |
|------|----------|----------|
| pom.xml | QueryDSL 의존성 추가 | +15 |
| pom.xml | APT 프로세서 설정 | +10 |
| QueryDslConfig.java | 신규 생성 | +20 |

### Phase 2: Repository
| 파일 | 수정 내용 | 라인 변화 |
|------|----------|----------|
| Stats1MinRepository.java | 6개 CTE → 1개 메서드 | -350 |
| EventRepository.java | UNION 쿼리 통합 | -100 |
| UserRepository.java | CASE WHEN 제거 | -40 |
| WhiteListPolicyRepository.java | Zone 필터 통합 | -30 |

### Phase 3: Service
| 파일 | 수정 내용 | 라인 변화 |
|------|----------|----------|
| DetectionService.java | In-Memory 필터 → DB 쿼리 | -180 |
| DataService.java | 다중 쿼리 통합 | -50 |
| DashboardService.java | findAll() 제거 | -20 |
| AssetService.java | Stream 필터 → Predicate | -80 |
| ReportService.java | 집계 쿼리 개선 | -40 |

### Phase 4: 공통
| 파일 | 수정 내용 | 신규 라인 |
|------|----------|----------|
| QueryDslPredicates.java | 신규 유틸리티 | +50 |
| AgGridPredicateBuilder.java | AG Grid 필터 변환 | +80 |

### Phase 5: ClickHouse
| 파일 | 수정 내용 | 라인 변화 |
|------|----------|----------|
| ClickHouseService.java | 파라미터 바인딩 | ±0 (리팩토링) |
| AssetTrafficService.java | String.format 제거 | ±0 (리팩토링) |

---

## 예상 효과

| 지표 | Before | After | 개선율 |
|------|--------|-------|--------|
| 총 @Query 라인 | 2,500+ | 800 | -68% |
| In-Memory 필터링 메서드 | 15+ | 0 | -100% |
| 중복 쿼리 패턴 | 30+ | 5 | -83% |
| SQL 인젝션 위험 개소 | 40+ | 0 | -100% |
| Repository 복잡도 (HIGH) | 8 | 2 | -75% |

---

## 리스크 및 대응

| 리스크 | 영향 | 대응 방안 |
|--------|------|----------|
| Q클래스 생성 실패 | 빌드 불가 | jakarta classifier 확인, APT 순서 |
| IDE Q클래스 인식 불가 | 개발 불편 | `mvn clean compile` 후 refresh |
| 기존 @Query 호환성 | 기능 오류 | 점진적 마이그레이션, 테스트 |
| ClickHouse 미지원 | 일부 쿼리 유지 | NamedParameterJdbcTemplate 사용 |
| 학습 곡선 | 개발 지연 | 단계별 적용, 문서화 |

---

## 우선순위 및 의존성

```
Phase 1 (설정) ────────────────────────────────────────┐
  └─ pom.xml, QueryDslConfig.java                      │
                                                       ▼
Phase 2 (Repository) ◀── Phase 1 완료 후
  ├─ Stats1MinRepository (CTE 통합)
  ├─ EventRepository (UNION 통합)
  └─ UserRepository (정렬 개선)
                                                       ▼
Phase 3 (Service) ◀── Phase 2 완료 후
  ├─ DetectionService (In-Memory 제거)
  ├─ DataService (다중 쿼리 통합)
  └─ DashboardService (findAll 제거)
                                                       ▼
Phase 4 (공통 유틸) ◀── Phase 2, 3 병행 가능
  ├─ QueryDslPredicates
  └─ AgGridPredicateBuilder
                                                       ▼
Phase 5 (ClickHouse) ◀── 별도 진행 가능
  └─ 파라미터 바인딩 적용
                                                       ▼
Phase 6 (Repository 확장) ◀── Phase 2 완료 후
  └─ QuerydslPredicateExecutor 추가
```

---

## 작성 정보

- **작성일**: 2026-01-19
- **분석 범위**: Repository 47개, Service 36개, Controller 15개
- **분석 방법**: 8개 병렬 에이전트 (Maven, Repository, Entity, Service, @Query, ClickHouse, Pagination, Dynamic Query)