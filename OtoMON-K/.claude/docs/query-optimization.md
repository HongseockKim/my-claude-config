# MariaDB 쿼리 최적화 가이드

> 이 문서는 OtoMON-K 프로젝트에서 경험한 쿼리 최적화 사례와 MariaDB 특성을 기록합니다.

---

## 1. UNION vs OR 비교 (2025-01-07 경험)

### 상황
- **테이블**: Event (222,172건)
- **조건**: `(src_ip = ? OR dst_ip = ?)`
- **인덱스**: `idx_events_src_ip`, `idx_events_dst_ip` 존재

### 결과

| 방식 | 소요 시간 | 이유 |
|------|-----------|------|
| OR 조건 | **3~4초** | Index Merge + Early Termination |
| UNION 서브쿼리 | **50초** | 전체 Materialization 필요 |

### 왜 OR이 더 빨랐나?

```
MariaDB Index Merge 최적화:
┌─────────────────┐    ┌─────────────────┐
│ idx_src_ip 스캔 │    │ idx_dst_ip 스캔 │
└────────┬────────┘    └────────┬────────┘
         │                      │
         └──────────┬───────────┘
                    ▼
         ┌─────────────────────┐
         │ Merge + LIMIT 적용  │ ← LIMIT 도달 시 즉시 중단!
         └─────────────────────┘
```

```
UNION 방식의 문제:
┌─────────────────┐    ┌─────────────────┐
│ src_ip 쿼리     │    │ dst_ip 쿼리     │
│ (전체 실행)     │    │ (전체 실행)     │
└────────┬────────┘    └────────┬────────┘
         │                      │
         └──────────┬───────────┘
                    ▼
         ┌─────────────────────┐
         │ 임시 테이블 생성    │ ← 전체 결과 저장 필요!
         └──────────┬──────────┘
                    ▼
         ┌─────────────────────┐
         │ ORDER BY + LIMIT    │ ← 이미 늦음
         └─────────────────────┘
```

### 교훈

1. **UNION은 LIMIT 최적화 불가**: 서브쿼리가 완전히 실행된 후에야 LIMIT 적용
2. **MariaDB의 Index Merge는 똑똑함**: OR 조건을 두 인덱스로 분할하여 병렬 처리
3. **SELECT * 주의**: UNION에서 `SELECT *` 사용 시 `longtext` 컬럼까지 복사되어 극도로 느림

### 결론

```sql
-- 권장: OR + Index Merge 활용
WHERE (e.src_ip = :srcIp OR e.dst_ip = :srcIp)
ORDER BY e.detected_at DESC
LIMIT 50

-- 비권장: UNION 서브쿼리 (대용량 테이블)
FROM (
    SELECT * FROM Event WHERE src_ip = :srcIp
    UNION
    SELECT * FROM Event WHERE dst_ip = :srcIp
) e
```

---

## 2. Event 테이블 인덱스 참조

### 전체 인덱스 목록 (18개)

| 인덱스명 | 컬럼 | 주요 용도 |
|---------|------|----------|
| `idx_events_src_ip` | (src_ip, detected_at DESC) | 출발지 IP 조회 |
| `idx_events_dst_ip` | (dst_ip, detected_at DESC) | 목적지 IP 조회 |
| `idx_events_src_mac` | (src_mac, detected_at DESC) | 출발지 MAC 조회 |
| `idx_events_dst_mac` | (dst_mac, detected_at DESC) | 목적지 MAC 조회 |
| `idx_events_dst_port` | (dst_port, detected_at DESC) | 목적지 포트 조회 |
| `idx_events_event_code` | (event_code, detected_at DESC) | 이벤트 코드 조회 |
| `idx_events_timestamp` | (timestamp) | 발생 시간 조회 |
| `idx_events_detected_at_id` | (detected_at DESC, id) | 탐지 시간 + ID 정렬 |
| `idx_event_detected_zone` | (detected_at DESC, zone3) | 탐지 시간 + 호기 |
| `idx_event_zone_time` | (zone3, detected_at DESC) | 호기별 시간순 조회 |
| `idx_event_zone3_timestamp` | (zone3, timestamp) | 호기별 발생 시간 |
| `idx_event_code_zone3_timestamp` | (event_code, zone3, timestamp) | 코드+호기+시간 |
| `idx_event_violation` | (event_code, detected_at, zone3, is_ignore) | 위반 탐지 |
| `idx_event_whitelist` | (event_code, src_ip, dst_ip, dst_port, protocol) | 화이트리스트 체크 |
| `idx_event_detection_composite` | (detected_at, zone3, event_code, is_ignore, is_action) | 복합 탐지 |
| `idx_event_performance` | (detected_at DESC, zone3, event_code) | 성능 최적화 |
| `idx_event_zone_first` | (zone3, detected_at, event_code, is_ignore, is_action) | 호기 우선 조회 |
| `idx_event_action_ignore_timestamp` | (is_action, is_ignore, timestamp) | 상태별 조회 |

### 인덱스 선택 가이드

```sql
-- src_ip 또는 dst_ip 조회
WHERE src_ip = ?  -- idx_events_src_ip 사용
WHERE dst_ip = ?  -- idx_events_dst_ip 사용
WHERE (src_ip = ? OR dst_ip = ?)  -- Index Merge (두 인덱스 병합)

-- 호기별 시간순 조회
WHERE zone3 = ? ORDER BY detected_at DESC  -- idx_event_zone_time 사용

-- 이벤트 코드 + 호기 + 시간
WHERE event_code = ? AND zone3 = ? AND timestamp BETWEEN ? AND ?
-- idx_event_code_zone3_timestamp 사용

-- 화이트리스트 정책 체크
WHERE event_code = ? AND src_ip = ? AND dst_ip = ? AND dst_port = ? AND protocol = ?
-- idx_event_whitelist 사용
```

---

## 3. SELECT * 주의사항

### Event 테이블의 longtext 컬럼

```sql
detail longtext  -- JSON 데이터, 수 KB ~ 수십 KB 가능
```

### 문제가 되는 패턴

```sql
-- 위험: SELECT * 사용
SELECT * FROM Event WHERE src_ip = ?

-- 위험: UNION에서 SELECT * 사용
SELECT * FROM Event WHERE src_ip = ?
UNION
SELECT * FROM Event WHERE dst_ip = ?
-- → detail 컬럼까지 모두 복사되어 임시 테이블 크기 폭발
```

### 권장 패턴

```sql
-- 권장: 필요한 컬럼만 명시
SELECT id, event_code, src_ip, dst_ip, detected_at
FROM Event
WHERE src_ip = ?

-- UNION 사용 시에도 필요한 컬럼만
SELECT id, event_code FROM Event WHERE src_ip = ?
UNION
SELECT id, event_code FROM Event WHERE dst_ip = ?
```

---

## 4. MariaDB Index Merge 동작 방식

### Index Merge란?

OR 조건에서 여러 인덱스를 동시에 활용하는 최적화 기법

### 동작 조건

1. OR로 연결된 각 조건이 별도 인덱스를 사용할 수 있어야 함
2. 각 조건의 선택도(selectivity)가 적절해야 함

### EXPLAIN으로 확인

```sql
EXPLAIN SELECT * FROM Event
WHERE (src_ip = '10.5.0.250' OR dst_ip = '10.5.0.250')
ORDER BY detected_at DESC
LIMIT 50;
```

결과 예시:
```
type: index_merge
key: idx_events_src_ip,idx_events_dst_ip
Extra: Using union(idx_events_src_ip,idx_events_dst_ip); Using filesort
```

---

## 5. 쿼리 최적화 체크리스트

### 새 쿼리 작성 시

- [ ] `SELECT *` 대신 필요한 컬럼만 명시했는가?
- [ ] `longtext` 컬럼(detail)이 불필요하게 포함되지 않았는가?
- [ ] EXPLAIN으로 실행 계획을 확인했는가?
- [ ] 적절한 인덱스가 사용되는가?
- [ ] OR 조건 사용 시 Index Merge가 동작하는가?

### 성능 이슈 발생 시

1. **EXPLAIN 분석**: 실행 계획 확인
2. **인덱스 확인**: 사용 가능한 인덱스 존재 여부
3. **데이터 볼륨**: 대상 데이터 건수 확인
4. **SELECT 컬럼**: longtext 등 대용량 컬럼 포함 여부
5. **서브쿼리**: UNION/서브쿼리의 materialization 여부

---

## 6. 참고: 쿼리 수 최적화

### 기존 방식 (4개 쿼리)

```
1. COUNT 쿼리 (GROUP BY event_type)
2. SELECT connection 이벤트
3. SELECT asset 이벤트
4. SELECT operation 이벤트
```

### 최적화 방식 (2개 쿼리)

```
1. COUNT 쿼리 (GROUP BY event_type)
2. SELECT 전체 + ROW_NUMBER() OVER (PARTITION BY event_type)
   → 메모리에서 타입별 그룹핑
```

### ROW_NUMBER 활용

```sql
SELECT * FROM (
    SELECT ...,
           ROW_NUMBER() OVER (PARTITION BY ed.event_type ORDER BY e.detected_at DESC) as row_num
    FROM Event e
    JOIN EventDefinition ed ON e.event_code = ed.event_code
    WHERE ...
) ranked
WHERE row_num <= 50  -- 타입당 50개씩
```

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-01-07 | 최초 작성 - UNION vs OR 비교, Index Merge 분석 |
