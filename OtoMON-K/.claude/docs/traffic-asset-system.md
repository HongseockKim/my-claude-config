# 자산별 트래픽 현황 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **목적** | 자산별 네트워크 트래픽 현황 모니터링 |
| **URL** | `/asset/trafficAsset` |
| **권한** | menuId: 2080L (READ/WRITE) |
| **레이아웃** | AG Grid 목록 + Offcanvas 상세 |

### 핵심 특징

- **Server-Side Datasource**: AG Grid의 서버 사이드 페이지네이션
- **세션 기반 필터링**: `startDateTime/endDateTime`으로 날짜 범위 지정
- **ClickHouse 쿼리**: ZeekConn 테이블에서 트래픽 집계
- **임계값 알림**: 트래픽/패킷/연결 수 초과 시 시각적 경고

---

## 파일 구조

### 백엔드

| 파일 | 경로 | 설명 |
|------|------|------|
| AssetController | `controller/AssetController.java:110-214` | API 엔드포인트 |
| AssetTrafficService | `service/AssetTrafficService.java` | 비즈니스 로직 (898줄) |
| TrafficDetailDto | `dto/TrafficDetailDto.java` | 상세 정보 DTO |
| TrafficAssetExcelDto | `dto/TrafficAssetExcelDto.java` | 목록 엑셀 DTO |
| TrafficDetailExcelDto | `dto/TrafficDetailExcelDto.java` | 상세 엑셀 DTO |

### 프론트엔드

| 파일 | 경로 | 설명 |
|------|------|------|
| 메인 페이지 | `templates/pages/asset/trafficAsset.html` | Thymeleaf 템플릿 |
| JavaScript | `static/js/page.traffic/trafficAsset.js` | AG Grid + ECharts 로직 |
| CSS | `static/css/pages/asset/trafficAsset.css` | 페이지 스타일 |

### CSS 구조 (trafficAsset.css)

| 선택자 | 설명 |
|--------|------|
| `#trafficGrid` | 메인 Grid 높이 (`calc(100vh - 140px)`) |
| `#connectionDetailGrid` | 연결상세 Grid 높이 (`400px`) |
| `.traffic-detail-offcanvas` | Offcanvas 너비/배경 |
| `.stat-card` | 통계 카드 스타일 |
| `.chart-container` | ECharts 컨테이너 (`height: 300px`) |

---

## API 엔드포인트

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/asset/trafficAsset` | 페이지 렌더링 |
| POST | `/asset/api/getTrafficData` | 트래픽 목록 (Server-Side) |
| POST | `/asset/api/getTrafficDetail` | 트래픽 상세 정보 |
| POST | `/asset/trafficAsset/exportExcel` | 목록 엑셀 다운로드 |
| POST | `/asset/trafficAsset/exportDetailExcel` | 상세 엑셀 다운로드 |

---

## 데이터 흐름

### 목록 데이터

```
ZeekConn (ClickHouse)
  ↓ UNION ALL (src_ip + dst_ip)
AssetTrafficService.getAggregatedTrafficFromZeek()
  ↓ IP별 집계 (traffic, packets, connections)
AssetController.getTrafficData()
  ↓ JSON Response
AG Grid (Server-Side Datasource)
```

### 상세 데이터

```
Row 클릭 → openTrafficDetail(ipAddress)
  ↓
/asset/api/getTrafficDetail
  ↓
AssetTrafficService.getTrafficDetailData()
  ├── 통계: totalTraffic, totalPackets, totalConnections, uniqueIps
  ├── 시계열: inbound/outbound (분 단위)
  ├── 분포: connState, servicePort, duration
  └── 연결상세: connectionDetails (페이지네이션)
  ↓
Offcanvas + ECharts + AG Grid
```

---

## ClickHouse 쿼리

### 트래픽 집계 (목록)

```sql
SELECT
    ip AS asset_ip,
    SUM(orig_ip_bytes + resp_ip_bytes) AS total_traffic,
    SUM(orig_pkts + resp_pkts) AS total_packets,
    COUNT(*) AS total_connections
FROM (
    SELECT src_ip AS ip, orig_ip_bytes, resp_ip_bytes, orig_pkts, resp_pkts
    FROM ZeekConn
    WHERE timestamp >= ? AND timestamp < ?
      AND zone_code = ?
    UNION ALL
    SELECT dst_ip AS ip, orig_ip_bytes, resp_ip_bytes, orig_pkts, resp_pkts
    FROM ZeekConn
    WHERE timestamp >= ? AND timestamp < ?
      AND zone_code = ?
) sub
GROUP BY ip
ORDER BY total_connections DESC
LIMIT ? OFFSET ?
```

### 인바운드 시계열 (상세)

```sql
SELECT
    formatDateTime(toStartOfMinute(timestamp), '%Y-%m-%d %H:%i') AS minute,
    SUM(resp_ip_bytes) / 1048576 AS traffic_mb,
    SUM(resp_pkts) AS packets,
    COUNT(*) AS connections
FROM ZeekConn
WHERE dst_ip = ?
  AND timestamp >= ? AND timestamp < ?
  AND zone_code = ?
GROUP BY toStartOfMinute(timestamp)
ORDER BY minute
```

### 아웃바운드 시계열 (상세)

```sql
SELECT
    formatDateTime(toStartOfMinute(timestamp), '%Y-%m-%d %H:%i') AS minute,
    SUM(orig_ip_bytes) / 1048576 AS traffic_mb,
    SUM(orig_pkts) AS packets,
    COUNT(*) AS connections
FROM ZeekConn
WHERE src_ip = ?
  AND timestamp >= ? AND timestamp < ?
  AND zone_code = ?
GROUP BY toStartOfMinute(timestamp)
ORDER BY minute
```

---

## 임계값 알림

| 항목 | 임계값 | 표시 |
|------|--------|------|
| 트래픽량 | 1GB (1,000,000,000 bytes) | 노란 배경 + 빨간 배지 |
| 패킷수 | 100만 (1,000,000) | 노란 배경 + 빨간 배지 |
| 연결수 | 1만 (10,000) | 노란 배경 + 빨간 배지 |

### 서비스 코드 (임계값 상수)

```java
// AssetTrafficService.java
private static final long TRAFFIC_THRESHOLD = 1_000_000_000L; // 1GB
private static final long PACKET_THRESHOLD = 1_000_000L;      // 100만
private static final long CONNECTION_THRESHOLD = 10_000L;     // 1만
```

### AG Grid CellStyle

```javascript
cellStyle: params => {
    if (params.value >= 1000000000) {
        return { backgroundColor: '#fff3cd' };
    }
    return null;
}
```

---

## ECharts 차트

### 시계열 차트 (6개)

| 차트 ID | 제목 | 데이터 |
|---------|------|--------|
| inboundTrafficChart | 인바운드 트래픽량 | traffic_mb |
| inboundPacketsChart | 인바운드 패킷수 | packets |
| inboundConnectionsChart | 인바운드 연결수 | connections |
| outboundTrafficChart | 아웃바운드 트래픽량 | traffic_mb |
| outboundPacketsChart | 아웃바운드 패킷수 | packets |
| outboundConnectionsChart | 아웃바운드 연결수 | connections |

### 분포 차트 (3개)

| 차트 ID | 제목 | 타입 |
|---------|------|------|
| connStateChart | 연결 상태 분포 | 도넛 |
| servicePortChart | 서비스 포트 분포 | 도넛 |
| durationChart | 연결 지속시간 분포 | 막대 |

### 동적 집계 (줌 레벨)

```javascript
function getAggregationLevel(visibleCount) {
    if (visibleCount <= 720) return 'minute';      // 12시간 이하
    else if (visibleCount <= 4320) return 'hour';  // 3일 이하
    else return 'day';                              // 그 이상
}
```

---

## TrafficDetailDto 구조

```java
public class TrafficDetailDto {
    private String ipAddress;           // IP 주소
    private Long totalTraffic;          // 총 트래픽 (bytes)
    private Long totalPackets;          // 총 패킷 수
    private Long totalConnections;      // 총 연결 수
    private Integer uniqueIps;          // 고유 IP 수

    private List<TimeSeriesData> inboundTimeSeries;   // 인바운드 시계열
    private List<TimeSeriesData> outboundTimeSeries;  // 아웃바운드 시계열

    private Map<String, Long> connStateDistribution;  // 연결 상태 분포
    private Map<String, Long> servicePortDistribution; // 서비스 포트 분포
    private Map<String, Long> durationDistribution;   // 지속시간 분포

    private List<ConnectionDetail> connectionDetails;  // 연결 상세 목록

    // Inner Classes
    public static class TimeSeriesData {
        private String time;        // 시간 (분/시/일)
        private Double trafficMb;   // 트래픽 (MB)
        private Long packets;       // 패킷 수
        private Long connections;   // 연결 수
    }

    public static class ConnectionDetail {
        private String srcIp;       // 출발지 IP
        private String dstIp;       // 목적지 IP
        private Integer srcPort;    // 출발지 포트
        private Integer dstPort;    // 목적지 포트
        private String protocol;    // 프로토콜
        private String connState;   // 연결 상태
        private Long origBytes;     // 송신 바이트
        private Long respBytes;     // 수신 바이트
        private Double duration;    // 지속시간 (초)
        private String timestamp;   // 타임스탬프
    }

    // Base64 인코딩 메서드
    public TrafficDetailDto toEncoded() {
        // IP 주소들을 Base64로 인코딩
    }
}
```

---

## 보안 처리

### IP/MAC Base64 인코딩

```java
// TrafficDetailDto.java
public TrafficDetailDto toEncoded() {
    TrafficDetailDto encoded = new TrafficDetailDto();
    encoded.setIpAddress(encodeBase64(this.ipAddress));
    // connectionDetails의 srcIp, dstIp도 인코딩
    return encoded;
}
```

### IP/MAC 마스킹 (2026-01-15 적용)

읽기 전용 사용자에게 IP/MAC 주소 마스킹 적용.

| 위치 | 파일 | 적용 방식 |
|------|------|----------|
| 목록 Grid (ipAddress) | trafficAsset.js:200-202 | `DataMaskingUtils.maskSensitiveData()` |
| 목록 Grid (macAddress) | trafficAsset.js:208-210 | `DataMaskingUtils.maskSensitiveData()` |
| 상세 헤더 (IP/MAC) | trafficAsset.js:410-411 | `DataMaskingUtils.maskSensitiveData()` |
| 연결상세 Grid (srcIp) | trafficAsset.js:721-726 | `DataMaskingUtils.maskSensitiveData()` |
| 연결상세 Grid (dstIp) | trafficAsset.js:729-733 | `DataMaskingUtils.maskSensitiveData()` |

```javascript
// 목록 Grid valueFormatter
valueFormatter: function (params) {
    return DataMaskingUtils.maskSensitiveData(decodeBase64(params.value));
}

// 상세 헤더
$('#detailIpAddress').text(DataMaskingUtils.maskSensitiveData(decodedIpAddress));

// 연결상세 Grid cellRenderer
cellRenderer: params => DataMaskingUtils.maskSensitiveData(params.value)
```

### CSP Nonce

모든 `<script>` 태그에 `th:nonce="${nonce}"` 적용.

```html
<script th:nonce="${nonce}" th:src="@{/js/page.traffic/trafficAsset.js}"></script>
```

### CSRF 토큰

```javascript
beforeSend: function(xhr) {
    xhr.setRequestHeader(header, token);
}
```

### SRI (Subresource Integrity)

```html
<script src="/js/echarts.min.js"
        th:integrity="${sriService.getIntegrity('/js/echarts.min.js')}"></script>
```

### 권한 검사

```java
@RequirePermission(menuId = 2080L)
@GetMapping("/asset/trafficAsset")
public String trafficAssetPage(Model model) {
    // ...
}
```

---

## TopologyPhysical vs TrafficAsset 비교

| 항목 | TrafficAsset | TopologyPhysical |
|------|--------------|------------------|
| 날짜 조건 | 세션 기반 (startDateTime/endDateTime) | 고정 (90일/1일) |
| 기본 기간 | 7일 | 90일 |
| 바이트 컬럼 | orig_ip_bytes, resp_ip_bytes | orig_bytes, resp_bytes |
| 집계 단위 | IP별 | IP + MAC 조합별 |
| 시각화 | AG Grid + ECharts | D3.js 토폴로지 |

---

## 새 기능 추가 시

### 새 분포 차트 추가

1. **DTO 필드 추가**: `TrafficDetailDto`에 `Map<String, Long>` 필드
2. **쿼리 추가**: `AssetTrafficService`에 집계 쿼리
3. **차트 컨테이너**: `trafficAsset.html`에 `<div id="newChart">`
4. **ECharts 초기화**: JavaScript에서 도넛/막대 차트 생성

### 새 임계값 추가

1. **상수 정의**: `AssetTrafficService`에 `THRESHOLD` 상수
2. **서버 검사**: 응답 데이터에 `exceeds*` 플래그 추가
3. **클라이언트 표시**: AG Grid `cellStyle` 또는 `cellRenderer`에 조건 추가

---

## 프로그램 명세서

### TRF_001 - 자산별 트래픽 현황 페이지

| 프로그램 ID | TRF_001 | 프로그램명 | 자산별 트래픽 현황 페이지 |
|------------|---------|----------|----------------------|
| 분류 | 자산관리 | 처리유형 | 화면 |
| 클래스명 | AssetController.java | 메서드명 | trafficAssetPage() |

▣ 기능 설명

자산별 네트워크 트래픽 현황을 조회하는 페이지를 렌더링한다. AG Grid Server-Side Datasource와 ECharts 차트를 사용한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 세션에서 날짜/호기 정보 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | HTML | 트래픽 현황 페이지 | String | Y | Thymeleaf 렌더링 HTML |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 검사 (menuId: 2080L) | @RequirePermission |
| 2 | 세션에서 startDateTime/endDateTime 조회 | 날짜 범위 |
| 3 | 세션에서 selectedZoneCode 조회 | 호기 필터링용 |
| 4 | pages/asset/trafficAsset 템플릿 반환 | AG Grid + ECharts 포함 |

---

### TRF_002 - 트래픽 목록 조회

| 프로그램 ID | TRF_002 | 프로그램명 | 트래픽 목록 조회 |
|------------|---------|----------|----------------|
| 분류 | 자산관리 | 처리유형 | 조회 |
| 클래스명 | AssetController.java | 메서드명 | getTrafficData() |

▣ 기능 설명

AG Grid Server-Side Datasource를 위한 자산별 트래픽 집계 데이터를 조회한다. ClickHouse ZeekConn 테이블에서 IP별 트래픽/패킷/연결 수를 집계한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | startRow | 시작행 | int | Y | AG Grid 페이지네이션 |
| 2 | endRow | 종료행 | int | Y | AG Grid 페이지네이션 |
| 3 | startDateTime | 시작일시 | String | N | 세션 기본값 사용 |
| 4 | endDateTime | 종료일시 | String | N | 세션 기본값 사용 |
| 5 | zoneCode | 호기코드 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | rows | 트래픽목록 | List\<Map\> | Y | IP별 트래픽 집계 |
| 2 | lastRow | 전체건수 | int | Y | Server-Side 페이지네이션용 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 날짜/호기 정보 조회 | |
| 2 | ClickHouse ZeekConn 쿼리 실행 | UNION ALL (src_ip + dst_ip) |
| 3 | IP별 트래픽/패킷/연결 수 집계 | GROUP BY ip |
| 4 | 임계값 초과 플래그 설정 | 트래픽 1GB, 패킷 100만, 연결 1만 |
| 5 | { rows, lastRow } 응답 반환 | |

---

### TRF_003 - 트래픽 상세 조회

| 프로그램 ID | TRF_003 | 프로그램명 | 트래픽 상세 조회 |
|------------|---------|----------|----------------|
| 분류 | 자산관리 | 처리유형 | 조회 |
| 클래스명 | AssetController.java | 메서드명 | getTrafficDetail() |

▣ 기능 설명

특정 IP의 트래픽 상세 정보를 조회한다. 통계, 시계열, 분포, 연결 상세 데이터를 포함한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ipAddress | IP주소 | String | Y | 조회 대상 IP |
| 2 | startDateTime | 시작일시 | String | N | 세션 기본값 사용 |
| 3 | endDateTime | 종료일시 | String | N | 세션 기본값 사용 |
| 4 | zoneCode | 호기코드 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ipAddress | IP주소 | String | Y | Base64 인코딩 |
| 2 | totalTraffic | 총트래픽 | Long | Y | bytes |
| 3 | totalPackets | 총패킷수 | Long | Y | |
| 4 | totalConnections | 총연결수 | Long | Y | |
| 5 | uniqueIps | 고유IP수 | Integer | Y | |
| 6 | inboundTimeSeries | 인바운드시계열 | List | Y | 분/시/일 단위 |
| 7 | outboundTimeSeries | 아웃바운드시계열 | List | Y | 분/시/일 단위 |
| 8 | connStateDistribution | 연결상태분포 | Map | Y | 도넛 차트용 |
| 9 | servicePortDistribution | 서비스포트분포 | Map | Y | 도넛 차트용 |
| 10 | durationDistribution | 지속시간분포 | Map | Y | 막대 차트용 |
| 11 | connectionDetails | 연결상세목록 | List | Y | 페이지네이션 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 날짜/호기 정보 조회 | |
| 2 | 통계 데이터 집계 | totalTraffic, totalPackets 등 |
| 3 | 인바운드/아웃바운드 시계열 조회 | toStartOfMinute 집계 |
| 4 | 연결 상태/포트/지속시간 분포 조회 | GROUP BY 집계 |
| 5 | 연결 상세 목록 조회 | 페이지네이션 |
| 6 | IP 주소 Base64 인코딩 | 보안 처리 |
| 7 | TrafficDetailDto 응답 반환 | |

---

### TRF_004 - 목록 엑셀 다운로드

| 프로그램 ID | TRF_004 | 프로그램명 | 목록 엑셀 다운로드 |
|------------|---------|----------|------------------|
| 분류 | 자산관리 | 처리유형 | 조회 |
| 클래스명 | AssetController.java | 메서드명 | exportExcel() |

▣ 기능 설명

자산별 트래픽 현황 목록을 엑셀 파일로 다운로드한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | startDateTime | 시작일시 | String | N | 세션 기본값 사용 |
| 2 | endDateTime | 종료일시 | String | N | 세션 기본값 사용 |
| 3 | zoneCode | 호기코드 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | file | 엑셀파일 | ByteArrayResource | Y | Excel 바이너리 |
| 2 | filename | 파일명 | String | Y | 자산별트래픽현황_YYYYMMDD.xlsx |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 날짜/호기 정보 조회 | |
| 2 | 전체 트래픽 데이터 조회 | 페이지네이션 없음 |
| 3 | TrafficAssetExcelDto 목록 생성 | |
| 4 | Apache POI XSSFWorkbook 생성 | |
| 5 | Content-Disposition 헤더 설정 | attachment |
| 6 | 엑셀 파일 반환 | |

---

### TRF_005 - 상세 엑셀 다운로드

| 프로그램 ID | TRF_005 | 프로그램명 | 상세 엑셀 다운로드 |
|------------|---------|----------|------------------|
| 분류 | 자산관리 | 처리유형 | 조회 |
| 클래스명 | AssetController.java | 메서드명 | exportDetailExcel() |

▣ 기능 설명

특정 IP의 트래픽 상세 연결 목록을 엑셀 파일로 다운로드한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ipAddress | IP주소 | String | Y | 조회 대상 IP |
| 2 | startDateTime | 시작일시 | String | N | 세션 기본값 사용 |
| 3 | endDateTime | 종료일시 | String | N | 세션 기본값 사용 |
| 4 | zoneCode | 호기코드 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | file | 엑셀파일 | ByteArrayResource | Y | Excel 바이너리 |
| 2 | filename | 파일명 | String | Y | 트래픽상세_IP_YYYYMMDD.xlsx |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 날짜/호기 정보 조회 | |
| 2 | 해당 IP의 연결 상세 데이터 조회 | 전체 조회 |
| 3 | TrafficDetailExcelDto 목록 생성 | |
| 4 | Apache POI XSSFWorkbook 생성 | |
| 5 | Content-Disposition 헤더 설정 | attachment |
| 6 | 엑셀 파일 반환 | |
