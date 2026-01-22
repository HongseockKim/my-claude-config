# 세션 (data/session) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/data/session` |
| **메뉴 ID** | - (권한 체크 없음) |
| **한글명** | 세션 |
| **목적** | 네트워크 세션(Zeek Conn 로그) 조회 및 분석 |
| **데이터 소스** | ClickHouse - ZeekConn 테이블 |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/DataController.java
Service:    src/main/java/com/otoones/otomon/service/ClickHouseService.java
Template:   src/main/resources/templates/pages/data/session.html
```

---

## 컨트롤러 (DataController.java)

### 페이지 렌더링 (`GET /data/session`)

**위치**: `DataController.java:42-59`

**파라미터**:
| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| zone1 | String | X | Zone1 필터 |
| zone2 | String | X | Zone2 필터 |
| zone3 | String | X | Zone3 필터 (세션에서 가져옴) |

**주요 로직**:
1. 세션에서 선택된 호기(selectedZoneCode) 가져오기
2. 세션에서 날짜 범위(startDateTime, endDateTime) 가져오기
3. ClickHouseService 호출하여 세션 데이터 조회
4. Model에 sessionList 추가

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| sessionList | 세션 데이터 리스트 (최대 1000건) |

### 그리드 데이터 API (`GET /data/grid-data-session`)

**위치**: `DataController.java:252-259`

zone 파라미터로 필터링된 세션 데이터 반환

---

## 서비스 (ClickHouseService.java)

### `getAllSessionWithDateRange()` - 위치: 23줄

날짜 범위와 zone 필터로 세션 데이터 조회

```java
public List<Map<String, Object>> getAllSessionWithDateRange(
    String zone1,
    String zone2,
    String zone3,
    String startDateTime,
    String endDateTime
)
```

**쿼리**:
```sql
SELECT timestamp, src_ip, src_port, dst_ip, dst_port, protocol,
       duration, conn_state, orig_pkts, orig_ip_bytes, resp_pkts, resp_ip_bytes
FROM ZeekConn
WHERE (? IS NULL OR zone1 = ?)
  AND (? IS NULL OR zone2 = ?)
  AND (? IS NULL OR zone3 = ?)
  AND timestamp BETWEEN ? AND ?
ORDER BY timestamp DESC
LIMIT 1000
```

**보안 처리**:
- IP 주소(src_ip, dst_ip)는 Base64 인코딩하여 반환
- `Base64Util.encodeFieldsInMap(row, "src_ip", "dst_ip")`

### `getAllSession()` - 위치: 113줄

zone 필터만으로 세션 데이터 조회 (날짜 범위 없음)

---

## 프론트엔드 (session.html)

### AG Grid 설정

| 설정 | 값 |
|------|-----|
| 그리드 ID | `#session_grid` |
| 높이 | `calc(100vh - 220px)` (최소 400px) |
| 페이지네이션 | 50건 기본 (20, 50, 100, 200 선택) |
| 테마 | ag-theme-quartz-dark |

### 컬럼 정의 (`sessionColum()`)

| 컬럼명 | 필드 | 너비 | 필터 | 특징 |
|--------|------|------|------|------|
| 발생일시 | timestamp | 160 | agDateColumnFilter | dayjs 포맷팅 |
| 출발지 IP | src_ip | 120 | true | Base64 디코딩 |
| 출발지 Port | src_port | 100 | true | 중앙 정렬 |
| 목적지 IP | dst_ip | 120 | true | Base64 디코딩 |
| 목적지 Port | dst_port | 100 | true | 중앙 정렬 |
| 프로토콜 | protocol | 80 | true | 중앙 정렬 |
| 지속시간 | duration | 100 | agNumberColumnFilter | 소수점 3자리 + 's' |
| 연결상태 | conn_state | 90 | true | 중앙 정렬 |
| 송신 패킷수 | orig_pkts | 110 | agNumberColumnFilter | 숫자 포맷팅 |
| 송신 바이트 | orig_ip_bytes | 110 | agNumberColumnFilter | 숫자 포맷팅 |
| 수신 패킷수 | resp_pkts | 110 | agNumberColumnFilter | 숫자 포맷팅 |
| 수신 바이트 | resp_ip_bytes | 110 | agNumberColumnFilter | 숫자 포맷팅 |

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `loadLicenseKey()` | AG Grid Enterprise 라이센스 로드 |
| `initializeAgGrid()` | AG Grid 초기화 |
| `sessionColum()` | 컬럼 정의 반환 |

### 데이터 초기화

```javascript
const sessionList = /*[[${sessionList}]]*/ [];
```

---

## ZeekConn 테이블 필드

### 주요 필드

| 필드 | 설명 | 예시 |
|------|------|------|
| timestamp | 연결 시작 시간 | 2025-09-27T09:00:00 |
| uid | 고유 연결 ID | C07wM93lRZzKqYw7Z9 |
| src_ip | 출발지 IP | 10.69.1.116 |
| src_port | 출발지 포트 | 47303 |
| dst_ip | 목적지 IP | 10.69.1.112 |
| dst_port | 목적지 포트 | 2004 |
| protocol | 프로토콜 | tcp |
| duration | 연결 지속시간 (초) | 63.000201 |
| conn_state | 연결 상태 코드 | RSTRH |
| orig_pkts | 송신 패킷 수 | 3 |
| orig_bytes | 송신 데이터 바이트 | 0 |
| orig_ip_bytes | 송신 IP 바이트 | 144 |
| resp_pkts | 수신 패킷 수 | 15 |
| resp_bytes | 수신 데이터 바이트 | 0 |
| resp_ip_bytes | 수신 IP 바이트 | 720 |

### 연결 상태 코드 (conn_state)

| 코드 | 의미 |
|------|------|
| S0 | 연결 시도 없음, SYN만 |
| S1 | 연결 설정, SYN 응답 없음 |
| SF | 정상 연결 완료 |
| REJ | 연결 거부 |
| S2 | 연결 설정 후 응답 없음 |
| S3 | 연결 설정 후 응답 FIN |
| RSTO | 연결이 Originator에 의해 리셋 |
| RSTR | 연결이 Responder에 의해 리셋 |
| RSTOS0 | Originator가 SYN 후 RST 전송 |
| RSTRH | Reset, Half-closed |
| SH | Originator가 FIN 후 응답 없음 |
| SHR | Responder가 FIN 후 응답 없음 |
| OTH | 기타 상태 |

### 추가 필드

| 필드 | 설명 |
|------|------|
| collected_at | 데이터 수집 시간 |
| src_mac | 출발지 MAC 주소 |
| dst_mac | 목적지 MAC 주소 |
| local_orig | 출발지가 로컬인지 (1=true) |
| local_resp | 목적지가 로컬인지 (1=true) |
| missed_bytes | 놓친 바이트 수 |
| history | 연결 히스토리 |
| service | 서비스 유형 |
| tunnel_parents | 터널 부모 |

---

## API 엔드포인트 요약

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/data/session` | 페이지 렌더링 |
| GET | `/data/grid-data-session` | 그리드 데이터 API |
| GET | `/data/sessions/countByMinute` | 분당 세션 카운트 |

---

## 데이터 흐름

```
[세션] selectedZoneCode, startDateTime, endDateTime
         ↓
[Controller] zone 파라미터 처리
         ↓
[ClickHouseService] getAllSessionWithDateRange()
         ↓
[ClickHouse] ZeekConn 테이블 쿼리
         ↓
[Base64Util] IP 주소 인코딩
         ↓
[Frontend] AG Grid 표시 + IP 디코딩
```

---

## 보안 고려사항

1. **IP Base64 인코딩**: 서버에서 src_ip, dst_ip를 Base64 인코딩
2. **프론트엔드 디코딩**: `atob()` 함수로 디코딩하여 표시
3. **조회 제한**: LIMIT 1000으로 대용량 데이터 방지

```javascript
// 프론트엔드 Base64 디코딩
cellRenderer: function(params) {
    try {
        return params.value ? atob(params.value) : '-';
    } catch(e) {
        return params.value || '-';
    }
}
```

---

## 그리드 스타일

```css
#session_grid {
    height: calc(100vh - 220px);
    width: 100%;
    min-height: 400px;
}

.ag-theme-quartz-dark {
    --ag-background-color: #2d353c;
    --ag-foreground-color: #dee2e6;
    --ag-border-color: #495057;
    --ag-header-background-color: #343a40;
    --ag-row-hover-color: #3d454c;
}
```

---

## 관련 문서

- [세션 필터링](session-filtering.md) - 날짜/호기 필터링
- [프론트엔드 패턴](frontend-patterns.md) - AG Grid 패턴
- [데이터베이스](database.md) - ClickHouse 시계열 데이터
- [운전정보](data-operation-system.md) - 같은 데이터 메뉴

---

## 프로그램 명세서

### SES_001 - 세션 페이지

| 프로그램 ID | SES_001 | 프로그램명 | 세션 페이지 |
|------------|---------|----------|------------|
| 분류 | 데이터 조회 | 처리유형 | 화면 |
| 클래스명 | DataController.java | 메서드명 | sessionPage() |

▣ 기능 설명

네트워크 세션(Zeek Conn 로그) 데이터를 조회하는 페이지를 렌더링한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | zone1 | Zone1 필터 | String | N | 기본값: null |
| 2 | zone2 | Zone2 필터 | String | N | 기본값: null |
| 3 | zone3 | Zone3 필터 | String | N | 세션에서 자동 조회 |
| 4 | session.startDateTime | 시작일시 | String | N | 세션에서 자동 조회 |
| 5 | session.endDateTime | 종료일시 | String | N | 세션에서 자동 조회 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | sessionList | 세션 리스트 | List<Map> | Y | 세션 데이터 (최대 1000건) |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 호기/날짜 정보 조회 | SessionHelper 사용 |
| 2 | ClickHouseService 호출 | getAllSessionWithDateRange() |
| 3 | IP 주소 Base64 인코딩 | src_ip, dst_ip 보안 처리 |
| 4 | Model에 sessionList 추가 및 뷰 반환 | pages/data/session |

---

### SES_002 - 세션 그리드 데이터 조회

| 프로그램 ID | SES_002 | 프로그램명 | 세션 그리드 데이터 조회 |
|------------|---------|----------|----------------------|
| 분류 | 데이터 조회 | 처리유형 | 조회 |
| 클래스명 | DataController.java | 메서드명 | getGridDataSession() |

▣ 기능 설명

AG Grid에서 사용할 세션 데이터를 zone 필터로 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | zone1 | Zone1 필터 | String | N | 기본값: null |
| 2 | zone2 | Zone2 필터 | String | N | 기본값: null |
| 3 | zone3 | Zone3 필터 | String | N | 기본값: null |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | 세션 리스트 | List<Map> | Y | JSON 배열 형식 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | zone 파라미터 처리 | - |
| 2 | ClickHouseService 호출 | getAllSession() |
| 3 | IP 주소 Base64 인코딩 | src_ip, dst_ip |
| 4 | JSON 배열 반환 | @ResponseBody |

---

### SES_003 - 분당 세션 카운트 조회

| 프로그램 ID | SES_003 | 프로그램명 | 분당 세션 카운트 조회 |
|------------|---------|----------|---------------------|
| 분류 | 데이터 조회 | 처리유형 | 조회 |
| 클래스명 | DataController.java | 메서드명 | getSessionCountByMinute() |

▣ 기능 설명

분당 세션 발생 건수를 집계하여 조회한다. 차트/통계 표시용.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | session.selectedZoneCode | 호기 코드 | String | N | 세션에서 자동 조회 |
| 2 | session.startDateTime | 시작일시 | String | N | 세션에서 자동 조회 |
| 3 | session.endDateTime | 종료일시 | String | N | 세션에서 자동 조회 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | minute | 분 단위 시간 | String | Y | yyyy-MM-dd HH:mm |
| 2 | count | 세션 건수 | Long | Y | 해당 분의 세션 수 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 호기/날짜 정보 조회 | SessionHelper 사용 |
| 2 | ClickHouse 집계 쿼리 실행 | GROUP BY minute |
| 3 | 분당 카운트 결과 반환 | JSON 배열 |
