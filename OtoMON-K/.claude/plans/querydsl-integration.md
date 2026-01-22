# QueryDSL 점진적 도입 계획

## 개요

OtoMON-K 프로젝트에 QueryDSL 5.1.0을 Repository별로 단계적 적용

| 항목 | 현재 | 목표 |
|-----|------|-----|
| Spring Boot | 3.4.5 | 유지 |
| QueryDSL | 없음 | 5.1.0 (Jakarta) |
| Repository | 53개 | 점진적 전환 |
| Native Query | 82개 | 동적 쿼리만 전환 |

---

## Phase 0: 인프라 구축 (1주)

### 0.1 pom.xml 수정

**파일**: `pom.xml`

```xml
<!-- properties 섹션에 추가 (라인 31 근처) -->
<querydsl.version>5.1.0</querydsl.version>

<!-- dependencies 섹션에 추가 -->
<dependency>
    <groupId>com.querydsl</groupId>
    <artifactId>querydsl-jpa</artifactId>
    <version>${querydsl.version}</version>
    <classifier>jakarta</classifier>
</dependency>
<dependency>
    <groupId>com.querydsl</groupId>
    <artifactId>querydsl-apt</artifactId>
    <version>${querydsl.version}</version>
    <classifier>jakarta</classifier>
    <scope>provided</scope>
</dependency>

<!-- maven-compiler-plugin의 annotationProcessorPaths에 추가 -->
<path>
    <groupId>com.querydsl</groupId>
    <artifactId>querydsl-apt</artifactId>
    <version>${querydsl.version}</version>
    <classifier>jakarta</classifier>
</path>
<path>
    <groupId>jakarta.persistence</groupId>
    <artifactId>jakarta.persistence-api</artifactId>
    <version>3.1.0</version>
</path>
```

### 0.2 QueryDslConfig.java 생성

**파일**: `src/main/java/com/otoones/otomon/config/QueryDslConfig.java`

```java
package com.otoones.otomon.config;

import com.querydsl.jpa.impl.JPAQueryFactory;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class QueryDslConfig {

    @PersistenceContext
    private EntityManager entityManager;

    @Bean
    public JPAQueryFactory jpaQueryFactory() {
        return new JPAQueryFactory(entityManager);
    }
}
```

### 0.3 검증

```bash
mvnw.cmd compile -DskipTests
# target/generated-sources/annotations/ 에 Q클래스 생성 확인
```

---

## Phase 1: DetectionPolicyRepositoryImpl 전환 (1-2주)

**대상**: `src/main/java/com/otoones/otomon/repository/DetectionPolicyRepositoryImpl.java`

### 변경 내용

| Before (JPA Criteria) | After (QueryDSL) |
|----------------------|------------------|
| CriteriaBuilder, CriteriaQuery | JPAQueryFactory |
| List<Predicate> | BooleanBuilder |
| 275줄 | ~100줄 예상 |

### 주요 메서드 전환

1. `searchWithComplexConditions()` - 동적 검색 (15+ 조건)
2. `groupByCategory()` - 카테고리별 그룹핑
3. `countConfigsByCategory()` - 집계 쿼리

### 검증

- 기존 API 호출 결과 동일성 확인
- `/policy/api/**` 엔드포인트 테스트

---

## Phase 2: Zone3QueryHelper 유틸리티 (1주)

**파일**: `src/main/java/com/otoones/otomon/repository/support/Zone3QueryHelper.java`

### 목적

기존 Native Query의 반복 패턴 추상화:
```sql
(:zone3 IS NULL OR zone3 LIKE CONCAT('%', :zone3, '%'))
```

### 사용 예시

```java
BooleanBuilder builder = new BooleanBuilder();
builder.and(Zone3QueryHelper.zone3Filter(QEvent.event.zone3, zone3));
```

---

## Phase 3: EventRepository 부분 전환 (3-5주)

**대상**: `src/main/java/com/otoones/otomon/repository/EventRepository.java`

### 전환 대상 (15개 메서드)

| 메서드 | 이유 |
|-------|-----|
| `countEventsByTypeDirectly` | zone3 동적 필터 |
| `findActiveEventsByDateRangeAndZonePaged` | 페이징 + 동적 조건 |
| `countActiveEventsByDateRangeAndZone` | 집계 + 동적 조건 |
| `findActiveEventsByTypeAndDateRangeAndZonePaged` | 복합 조건 |
| `countActiveEventsByTypeAndDateRangeAndZone` | 복합 집계 |
| ... | ... |

### 유지 대상 (Native Query 유지)

| 메서드 | 이유 |
|-------|-----|
| `findRelatedEventsGroupedByTypeOptimized` | ROW_NUMBER() OVER |
| `findRelatedEventsWithDefinitionOptimized` | UNION |

### 구현 파일

1. `EventRepositoryCustom.java` - 인터페이스 정의
2. `EventRepositoryImpl.java` - QueryDSL 구현

---

## Phase 4: AssetRepository 전환 (2-3주)

**대상**: `src/main/java/com/otoones/otomon/repository/AssetRepository.java`

### 전환 대상 (5개 메서드)

- `findFacilityAssetCountByZone3`
- `findManufactureCompanyAssetCountByZone3`
- `findByZone`
- `findByZone1And2Only`

### 구현 파일

1. `AssetRepositoryCustom.java`
2. `AssetRepositoryImpl.java`

---

## Phase 5: 공통 유틸리티 완성 (1주)

**파일**: `src/main/java/com/otoones/otomon/repository/support/QueryDslSupport.java`

### 기능

- `getOrderSpecifiers()` - Pageable Sort → OrderSpecifier 변환
- `dateRangeFilter()` - 날짜 범위 조건 생성

---

## 수정 파일 목록

| Phase | 파일 경로 | 작업 |
|-------|----------|-----|
| 0 | `pom.xml` | 의존성 추가 |
| 0 | `config/QueryDslConfig.java` | 신규 생성 |
| 1 | `repository/DetectionPolicyRepositoryImpl.java` | 전면 수정 |
| 2 | `repository/support/Zone3QueryHelper.java` | 신규 생성 |
| 3 | `repository/EventRepositoryCustom.java` | 신규 생성 |
| 3 | `repository/EventRepositoryImpl.java` | 신규 생성 |
| 3 | `repository/EventRepository.java` | extends 추가 |
| 4 | `repository/AssetRepositoryCustom.java` | 신규 생성 |
| 4 | `repository/AssetRepositoryImpl.java` | 신규 생성 |
| 4 | `repository/AssetRepository.java` | extends 추가 |
| 5 | `repository/support/QueryDslSupport.java` | 신규 생성 |

---

## 검증 방법

### 각 Phase 완료 시

1. **빌드 확인**
   ```bash
   mvnw.cmd clean compile -DskipTests
   ```

2. **애플리케이션 실행**
   ```bash
   mvnw.cmd spring-boot:run -DskipTests
   ```

3. **API 테스트**
   - Phase 1: `/policy/api/**` 엔드포인트
   - Phase 3: `/detection/**`, `/data/api/**` 엔드포인트
   - Phase 4: `/asset/**` 엔드포인트

4. **결과 비교**
   - 기존 메서드 vs QueryDSL 메서드 결과 일치 확인
   - 페이징, 정렬 정확성 확인

### 최종 검증

```bash
# 전체 테스트 실행
mvnw.cmd test

# 실제 환경 테스트 (로그인 후)
# https://localhost:8080
# admin / qwe123!@#
```

---

## 일정 요약

| Phase | 내용 | 기간 | 누적 |
|-------|-----|------|-----|
| 0 | 인프라 구축 | 1주 | 1주 |
| 1 | DetectionPolicyRepositoryImpl | 1-2주 | 2-3주 |
| 2 | Zone3QueryHelper | 1주 | 3-4주 |
| 3 | EventRepository | 3-5주 | 6-9주 |
| 4 | AssetRepository | 2-3주 | 8-12주 |
| 5 | 공통 유틸리티 | 1주 | 9-13주 |

**총 예상 기간: 10-14주**

---

## 주의사항

1. **Native Query 유지 대상**
   - CTE (WITH 절) 사용 쿼리
   - 윈도우 함수 (ROW_NUMBER, PARTITION BY)
   - UNION 쿼리
   - JSON_TABLE 사용 쿼리

2. **기존 코드 영향 최소화**
   - 기존 @Query 메서드는 당장 삭제하지 않음
   - Custom 인터페이스로 새 메서드 추가 후 점진적 전환
   - Service 레이어 수정은 Phase 완료 후 별도 진행

3. **롤백 전략**
   - 각 Phase는 독립적으로 롤백 가능
   - Git 브랜치 전략: `feature/querydsl-phase-{n}`
