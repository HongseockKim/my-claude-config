# 물리 토폴로지 시스템

## 개요

물리 토폴로지(`/asset/topology-physical`)는 **네트워크 스위치-장비 물리적 연결 관계**를 시각화하는 페이지입니다.

### 핵심 특징

- **D3.js 시각화**: 스위치-장비 토폴로지맵 렌더링
- **AG Grid 목록**: 스위치 목록 및 포트 상태 요약
- **실시간 자동 갱신**: 60초 주기 데이터 새로고침
- **ClickHouse 연동**: 트래픽 상세 시계열 데이터
- **다크모드 지원**: 테마에 따른 동적 스타일 변경

---

## 파일 구조

### Backend

| 파일 | 역할 |
|------|------|
| `TopologyPhysicalController.java` | REST API 엔드포인트 (5개) |
| `TopologyPhysicalService.java` | 비즈니스 로직 |
| `TopologyPhysicalRepository.java` | 자산 조회 |
| `TopologySwitchRepository.java` | 스위치 조회 |

### Frontend

| 파일 | 역할 |
|------|------|
| `topology-physical.html` | 스위치 목록 (AG Grid) |
| `topology-physical-detail.html` | 토폴로지맵 상세 (독립 페이지) |
| `topology-physical-detail-fragment.html` | 토폴로지맵 (Fragment, AJAX 로드) |

---

## 아키텍처

```
[Frontend]                          [Backend]
topology-physical.html              TopologyPhysicalController.java
  ├── AG Grid (목록)                  └── TopologyPhysicalService.java
  └── showTopologyPhysicalDetail()         ├── TopologySwitchRepository (MariaDB)
       └── topology-physical-detail        ├── AssetRepository (MariaDB)
           └── D3.js 토폴로지맵            ├── EventRepository (MariaDB)
               └── 자산 사이드바           └── ClickHouseJdbcTemplate (시계열)
```

---

## API 엔드포인트

### TopologyPhysicalController

| Method | Endpoint | 설명 | 응답 |
|--------|----------|------|------|
| GET | `/topology-physical/select-topology-switch-list` | 스위치 목록 조회 | `ApiResponse<List<Map>>` |
| POST | `/topology-physical/select-topology-switch-asset-list` | 스위치 포트 자산 조회 | `ApiResponse<List<Map>>` |
| GET | `/topology-physical/select-asset-list` | 자산 상세 정보 | `Map` |
| GET | `/topology-physical/select-related-events` | 자산 관련 이벤트 | `ApiResponse<List<Map>>` |
| POST | `/topology-physical/api/getTrafficDetail` | 트래픽 상세 (ClickHouse) | `TrafficDetailDto` |

### 요청 파라미터

**스위치 목록 조회**:
```
zone1: String (예: "koen")
zone2: String (예: "samcheonpo")
zone3: String (예: "3" 또는 "4")
idx: Long (선택, 특정 스위치)
```

**트래픽 상세 조회**:
```
ipAddress: String (Base64 인코딩)
startRaw: int (기본값: 0)
endRaw: int (기본값: 100)
```

---

## 데이터 흐름

### 1. 목록 페이지 로드

```javascript
// topology-physical.html
onGridReady: function(params) {
    $.ajax({
        url: '/asset/grid-data-topology-switch-optimized',
        success: function(response) {
            if (response.ret === 0) {
                gridApi.setGridOption('rowData', response.data);
            }
        }
    });
}
```

**AG Grid 컬럼**:
- No (행번호)
- 스위치 상태 (포트 박스 시각화)
- 호기 (Zone3Util 변환)
- 스위치명
- 총 포트 / 정상 / 정지 / 이상 / 일반이상 / 상태없음 / 미사용
- 상세보기 버튼

### 2. 상세보기 클릭

```javascript
function showTopologyPhysicalDetail(idx, zone1, zone2, zone3) {
    $.ajax({
        url: '/asset/topology-physical-detail-fragment?idx=' + idx,
        success: function(html) {
            $('#detailContainer').html(html).show();
            $('#myGrid').parent().hide();
            // Fragment 초기화
            window.selectTopologySwitchlList();
        }
    });
}
```

### 3. 토폴로지 데이터 로드

```javascript
function selectTopologySwitchlList() {
    // 1단계: 스위치 정보 조회
    $.ajax({
        url: '/topology-physical/select-topology-switch-list',
        success: function(response) {
            if (response.ret !== 0) return;

            topology.clearTopologyManager();

            response.data.forEach(switchData => {
                // 스위치 추가
                const switchId = topology.addSwitch(
                    switchData.name,
                    portIpTagList.length,
                    switchData.idx
                );

                // 장비 추가
                portIpTagList.forEach(portInfo => {
                    if (portInfo.connectedIp) {
                        topology.addDevice(switchId, portInfo.portNumber, ...);
                    }
                });
            });

            topology.render();
            selectTopologySwitchAssetList(response.data); // 2단계 호출
        }
    });
}

function selectTopologySwitchAssetList(switchList) {
    // 2단계: 자산 정보 매칭 및 상태 설정
    $.ajax({
        url: '/topology-physical/select-topology-switch-asset-list',
        type: 'POST',
        data: JSON.stringify(ipList),
        success: function(response) {
            if (response.ret !== 0) return;

            topology.switches.forEach(networkSwitch => {
                networkSwitch.devices.forEach((device, portNumber) => {
                    const matchedAsset = response.data.find(...);
                    if (matchedAsset) {
                        topology.setDeviceStatus(device.id, statusMap[matchedAsset.status]);
                    }
                });
            });

            topology.render();
            updatePortStatusBadges();
        }
    });
}
```

### 4. 장비 클릭 (사이드바)

```javascript
function selectAssetList(idx, deviceIpAddress) {
    $.ajax({
        url: '/topology-physical/select-asset-list',
        data: { idx: idx },
        success: function(assetData) {
            openAssetDetailSidebar(assetData);
        }
    });
}

function openAssetDetailSidebar(assetData) {
    // 1. 자산 기본 정보 로드
    $.ajax({
        url: '/asset/operation/detail',
        success: function(html) {
            $('#assetDetailContent').html(html);
            sidebar.show();
            addRelatedEventsTabAndLoadFragment(assetData); // 탭 추가
        }
    });
}
```

---

## 토폴로지 시각화 (D3.js)

### 클래스 구조

```javascript
class TopologyManager {
    constructor() {
        this.switches = new Map();        // 스위치 컬렉션
        this.svg = d3.select('#topology');
        this.zoomBehavior = null;
        this.container = null;
    }

    // 주요 메서드
    addSwitch(name, portCount, idx)           // 스위치 추가
    addDevice(switchId, portNumber, ...)      // 장비 추가
    setDeviceStatus(deviceId, status)         // 장비 상태 변경
    updateLayout()                            // 레이아웃 계산
    render()                                  // 렌더링
    setupZoomAndPan()                         // 줌/팬 설정
    clearTopologyManager()                    // 초기화
}

class NetworkSwitch {
    constructor(id, name, portCount) {
        this.ports = [];           // 포트 배열
        this.devices = new Map();  // 연결된 장비
        this.position = { x: 0, y: 0 };
        this.boundingBox = { width: 0, height: 0 };
    }

    addDevice(portNumber, device)
    removeDevice(portNumber)
}

class Device {
    constructor(id, name, ipAddress, type) {
        this.status = 'inactive';  // active/inactive/error/warning/caution
        this.traffic = null;
        this.position = { x: 0, y: 0 };
    }

    getIcon()           // FontAwesome 아이콘 클래스
    setStatus(status)
    setTraffic(traffic)
}
```

### 설정 객체

```javascript
const config = {
    port: {
        width: 40,
        height: 30,
        margin: 10
    },
    switch: {
        padding: 15
    },
    device: {
        radius: 20,
        verticalOffset: 200,
        horizontalGap: 100
    },
    maxPerRow: 12,
    switchGap: 100,
    elbowOffset: 12,
    deviceAlign: 'LEFT',      // LEFT | CENTER | RIGHT
    trafficDisplay: false,    // 트래픽 표시 여부
    trafficOffset: 20
};
```

### 상태별 색상

| 상태 | 포트 색상 | 장비 테두리 | 의미 |
|------|----------|------------|------|
| `active` | #28a745 (초록) | #218838 | 정상 운전 |
| `inactive` | #fff900 (노랑) | #fff900 | 운전 상태 없음 |
| `error` | #6c757d (회색) | #6b747c | 운전 정지 |
| `warning` | #dc3545 (빨강) | #dc3545 | 운전 이상 |
| `caution` | #ff9800 (주황) | #f57c00 | 운전 일반 이상 |
| `empty` | 흰색 (테두리만) | - | 미사용 포트 |

### 장비 타입별 아이콘

```javascript
function determineDeviceType(name) {
    if (name === '서버') return 'server';      // fa-server
    if (name === 'router') return 'router';   // fa-wifi
    if (name === 'firewall') return 'firewall'; // fa-shield-alt
    if (name === '제어PC') return 'computer';   // fa-desktop
    if (name === '제어기기') return 'controller'; // fa-microchip
    return 'computer';  // 기본값
}
```

---

## 트래픽 상세 (ClickHouse)

### TrafficDetailDto 구조

```java
@Builder
public class TrafficDetailDto {
    private String assetName;
    private String ipAddress;      // Base64 인코딩
    private String macAddress;     // Base64 인코딩

    // 통계
    private Long totalTraffic;
    private Long totalPackets;
    private Long totalConnections;
    private Long uniqueIps;

    // 시계열
    private TimeSeriesData inboundTimeSeries;
    private TimeSeriesData outboundTimeSeries;

    // 분포
    private Map<String, Long> connectionsStateDistribution;
    private Map<String, Long> servicePortDistribution;
    private Map<String, Long> durationDistribution;

    // 연결 상세
    private List<ConnectionDetail> connectionDetails;
    private Long totalConnectionRecords;
}
```

### ClickHouse 쿼리

**통계 조회 (90일)**:
```sql
SELECT
    SUM(orig_bytes + resp_bytes) AS total_traffic,
    SUM(orig_pkts + resp_pkts) AS total_packets,
    COUNT(*) AS total_connections,
    COUNT(DISTINCT CASE WHEN src_ip = ? THEN dst_ip ELSE src_ip END) AS unique_ips
FROM ZeekConn
WHERE zone1 = ? AND zone2 = ? AND zone3 IN (?)
  AND timestamp >= now() - INTERVAL 90 DAY
  AND (src_ip = ? OR dst_ip = ?)
```

**인바운드 시계열 (1일, 분 단위)**:
```sql
SELECT
    formatDateTime(toStartOfMinute(timestamp), '%Y-%m-%d %H:%i') AS minute,
    SUM(resp_bytes) / 1048576 AS traffic_mb,
    SUM(resp_pkts) AS packets,
    COUNT(*) AS connections
FROM ZeekConn
WHERE dst_ip = ? AND timestamp >= now() - INTERVAL 1 DAY
GROUP BY toStartOfMinute(timestamp)
ORDER BY minute
```

### 차트 렌더링 (ECharts)

```javascript
function renderMiniCharts(data) {
    const inboundData = data.inboundTimeSeries;
    const outboundData = data.outboundTimeSeries;

    // 라인 차트 (시계열)
    renderMiniLineChart('mini_inbound_traffic_chart', inboundData.timestamps, inboundData.trafficMB, '#3b82f6');
    renderMiniLineChart('mini_inbound_packets_chart', inboundData.timestamps, inboundData.packets, '#06b6d4');

    // 파이 차트 (분포)
    renderMiniPieChart('mini_conn_state_chart', data.connectionsStateDistribution);
    renderMiniPieChart('mini_service_port_chart', data.servicePortDistribution);

    // 바 차트 (지속시간 분포)
    renderMiniBarChart('mini_duration_chart', data.durationDistribution);
}
```

---

## 보안 처리

### IP/MAC 주소 Base64 인코딩

**Backend (Java)**:
```java
private Map<String, Object> convertAssetToEncodedMap(Asset asset) {
    map.put("ipAddress", asset.getIpAddress() != null
        ? Base64.getEncoder().encodeToString(asset.getIpAddress().getBytes(StandardCharsets.UTF_8))
        : null);
}
```

**Frontend (JavaScript)**:
```javascript
// 인코딩
btoa(assetData.ipAddress)

// 디코딩
function decodeBase64(encoded) {
    if (!encoded) return '';
    try {
        return decodeURIComponent(escape(atob(encoded)));
    } catch (e) {
        return encoded;
    }
}
```

### CSRF 토큰

```javascript
$.ajax({
    url: '/topology-physical/api/getTrafficDetail',
    method: 'POST',
    beforeSend: function(xhr) {
        const csrfHeader = $("meta[name='_csrf_header']").attr("content");
        const csrfToken = $("meta[name='_csrf']").attr("content");
        if (csrfHeader && csrfToken) {
            xhr.setRequestHeader(csrfHeader, csrfToken);
        }
    }
});
```

### SRI (Subresource Integrity)

```html
<script crossorigin="anonymous"
        th:integrity="${sri.getHash('d3.min.js')}"
        th:src="@{/js/d3.min.js}"></script>
```

---

## 다크모드 지원

### 테마 감지

```javascript
function applyTopologyTheme(container) {
    const currentTheme = getAgGridThemeClass();
    const isDarkMode = currentTheme.includes('dark');

    if (isDarkMode) {
        container.style.background = '#2d353c';
        container.classList.add('dark-mode');
    } else {
        container.style.background = 'white';
        container.classList.remove('dark-mode');
    }
}
```

### CSS 변수

```css
/* 다크 모드 */
.topology-container.dark-mode .switch-label,
.topology-container.dark-mode .device-text {
    fill: #ffffff !important;
}

/* AG Grid 다크 테마 */
.ag-theme-quartz-dark {
    --ag-background-color: #2d353c;
    --ag-foreground-color: #dee2e6;
    --ag-header-background-color: #2d353c;
}
```

---

## 특이사항 및 주의점

### 1. IIFE 스코프 이슈 (2025-12-23)

Fragment에서 IIFE 스코프 내 함수를 외부에서 호출할 수 없어 전역 함수로 노출:

```javascript
(function() {
    function selectTopologySwitchlList() { ... }

    // 전역으로 노출
    window.selectTopologySwitchlList = selectTopologySwitchlList;
})();
```

### 2. 동적 탭 차트 렌더링

보이지 않는 DOM에서 ECharts 렌더링 불가. 탭 전환 시 렌더링:

```javascript
$('#trafficTabBtnOutbound').one('shown.bs.tab', function() {
    renderMiniLineChart('mini_outbound_traffic_chart', ...);
});
```

### 3. 자동 새로고침

```javascript
// 초기 로드
selectTopologySwitchlList();

// 60초마다 새로고침
setInterval(selectTopologySwitchlList, 60000);

// Fragment 닫을 때 정리
window.closeTopologyDetailFragment = function() {
    if (window.topologyRefreshInterval) {
        clearInterval(window.topologyRefreshInterval);
    }
    $('#detailContainer').hide().empty();
};
```

### 4. 줌/팬 초기화

토폴로지 데이터 갱신 시 줌 상태 리셋:

```javascript
topology.svg.transition()
    .duration(0)
    .call(topology.zoomBehavior.transform, d3.zoomIdentity);
```

---

## 관련 문서

- [architecture.md](architecture.md) - 전체 아키텍처
- [frontend-patterns.md](frontend-patterns.md) - 프론트엔드 패턴
- [database.md](database.md) - 데이터베이스 구조
- [asset-operation-spec.md](asset-operation-spec.md) - 자산현황 페이지

---

## 프로그램 명세서

### TPY_001 - 물리 토폴로지 목록 페이지

| 프로그램 ID | TPY_001 | 프로그램명 | 물리 토폴로지 목록 페이지 |
|------------|---------|----------|----------------------|
| 분류 | 자산 | 처리유형 | 화면 |
| 클래스명 | AssetController.java | 메서드명 | topologyPhysical() |

▣ 기능 설명

네트워크 스위치 목록을 AG Grid로 표시하는 페이지를 렌더링한다. 스위치별 포트 상태를 시각화하여 표시.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 세션에서 호기 정보 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | HTML | 토폴로지 페이지 | String | Y | Thymeleaf 렌더링 HTML |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | topology-physical.html 렌더링 | |
| 2 | AG Grid 스위치 목록 초기화 (클라이언트) | |

---

### TPY_002 - 물리 토폴로지 상세 Fragment

| 프로그램 ID | TPY_002 | 프로그램명 | 물리 토폴로지 상세 Fragment |
|------------|---------|----------|-------------------------|
| 분류 | 자산 | 처리유형 | 화면 (Fragment) |
| 클래스명 | AssetController.java | 메서드명 | topologyPhysicalDetailFragment() |

▣ 기능 설명

D3.js를 사용한 토폴로지맵 시각화 Fragment를 반환한다. AJAX로 로드되어 목록 페이지에 삽입.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 스위치 ID | Long | Y | RequestParam |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | HTML | 토폴로지맵 Fragment | String | Y | D3.js 토폴로지맵 HTML |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 스위치 idx를 모델에 추가 | |
| 2 | topology-physical-detail-fragment.html 렌더링 | |
| 3 | 60초 자동 새로고침 설정 (클라이언트) | |

---

### TPY_003 - 스위치 목록 조회

| 프로그램 ID | TPY_003 | 프로그램명 | 스위치 목록 조회 |
|------------|---------|----------|----------------|
| 분류 | 자산 | 처리유형 | 조회 |
| 클래스명 | TopologyPhysicalController.java | 메서드명 | selectTopologySwitchList() |

▣ 기능 설명

토폴로지맵 렌더링을 위한 스위치 및 포트 정보를 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | zone1 | 사업소 코드 | String | Y | 예: koen |
| 2 | zone2 | 발전소 코드 | String | Y | 예: samcheonpo |
| 3 | zone3 | 호기 코드 | String | Y | 예: 3 또는 4 |
| 4 | idx | 스위치 ID | Long | N | 특정 스위치 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 메시지 | String | Y | 처리 결과 메시지 |
| 3 | data[].idx | 스위치 ID | Long | Y | PK |
| 4 | data[].name | 스위치명 | String | Y | |
| 5 | data[].portCount | 총 포트 수 | Integer | Y | |
| 6 | data[].portIpTagList | 포트 정보 | List | Y | |
| 7 | data[].portIpTagList[].portNumber | 포트 번호 | Integer | Y | |
| 8 | data[].portIpTagList[].connectedIp | 연결 IP | String | N | Base64 인코딩 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | zone 파라미터로 스위치 조회 | TopologySwitchRepository |
| 2 | 스위치별 포트 정보 조회 | SwitchPort |
| 3 | IP 주소 Base64 인코딩 | 보안 |
| 4 | ApiResponse 래핑 후 반환 | JavaScript 하이재킹 방어 |

---

### TPY_004 - 스위치 포트 자산 조회

| 프로그램 ID | TPY_004 | 프로그램명 | 스위치 포트 자산 조회 |
|------------|---------|----------|---------------------|
| 분류 | 자산 | 처리유형 | 조회 |
| 클래스명 | TopologyPhysicalController.java | 메서드명 | selectTopologySwitchAssetList() |

▣ 기능 설명

IP 주소 목록으로 자산 정보를 조회하여 토폴로지 장비 상태를 매칭한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ipList | IP 목록 | List<String> | Y | Base64 인코딩 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 메시지 | String | Y | 처리 결과 메시지 |
| 3 | data[].idx | 자산 ID | Long | Y | PK |
| 4 | data[].ipAddress | IP 주소 | String | Y | Base64 인코딩 |
| 5 | data[].status | 운전 상태 | String | Y | active/inactive/error/warning/caution |
| 6 | data[].assetName | 자산명 | String | Y | |
| 7 | data[].facilityType | 설비 유형 | String | N | |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | IP 목록 Base64 디코딩 | |
| 2 | IP로 자산 조회 | AssetRepository |
| 3 | 자산 상태 매핑 (운전정보 기반) | |
| 4 | ApiResponse 래핑 후 반환 | JavaScript 하이재킹 방어 |

---

### TPY_005 - 자산 상세 정보 조회

| 프로그램 ID | TPY_005 | 프로그램명 | 자산 상세 정보 조회 |
|------------|---------|----------|-------------------|
| 분류 | 자산 | 처리유형 | 조회 |
| 클래스명 | TopologyPhysicalController.java | 메서드명 | selectAssetList() |

▣ 기능 설명

토폴로지 장비 클릭 시 자산 상세 정보를 조회하여 사이드바에 표시한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 자산 ID | Long | Y | RequestParam |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 자산 ID | Long | Y | PK |
| 2 | assetName | 자산명 | String | Y | |
| 3 | ipAddress | IP 주소 | String | Y | Base64 인코딩 |
| 4 | macAddress | MAC 주소 | String | Y | Base64 인코딩 |
| 5 | facilityType | 설비 유형 | String | N | |
| 6 | operationStatus | 운전 상태 | String | N | |
| 7 | manufacturer | 제조사 | String | N | |
| 8 | modelName | 모델명 | String | N | |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 자산 ID로 조회 | AssetRepository |
| 2 | 민감정보 Base64 인코딩 (IP, MAC) | 보안 |
| 3 | 자산 상세 반환 | |

---

### TPY_006 - 자산 관련 이벤트 조회

| 프로그램 ID | TPY_006 | 프로그램명 | 자산 관련 이벤트 조회 |
|------------|---------|----------|---------------------|
| 분류 | 자산 | 처리유형 | 조회 |
| 클래스명 | TopologyPhysicalController.java | 메서드명 | selectRelatedEvents() |

▣ 기능 설명

특정 자산에 관련된 이벤트(알람, 이상탐지) 목록을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 자산 ID | Long | Y | RequestParam |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 메시지 | String | Y | 처리 결과 메시지 |
| 3 | data[].eventId | 이벤트 ID | Long | Y | PK |
| 4 | data[].eventType | 이벤트 유형 | String | Y | |
| 5 | data[].severity | 심각도 | String | Y | |
| 6 | data[].message | 메시지 | String | N | |
| 7 | data[].createdAt | 발생일시 | LocalDateTime | Y | |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 자산 ID로 이벤트 조회 | EventRepository |
| 2 | 최신순 정렬 | |
| 3 | ApiResponse 래핑 후 반환 | JavaScript 하이재킹 방어 |

---

### TPY_007 - 트래픽 상세 조회

| 프로그램 ID | TPY_007 | 프로그램명 | 트래픽 상세 조회 |
|------------|---------|----------|----------------|
| 분류 | 자산 | 처리유형 | 조회 |
| 클래스명 | TopologyPhysicalController.java | 메서드명 | getTrafficDetail() |

▣ 기능 설명

ClickHouse에서 자산의 트래픽 상세 정보(시계열, 분포, 연결 상세)를 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ipAddress | IP 주소 | String | Y | Base64 인코딩 |
| 2 | startRow | 시작 행 | Integer | N | 기본값: 0 |
| 3 | endRow | 종료 행 | Integer | N | 기본값: 100 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | assetName | 자산명 | String | Y | |
| 2 | totalTraffic | 총 트래픽 | Long | Y | bytes |
| 3 | totalPackets | 총 패킷 | Long | Y | |
| 4 | totalConnections | 총 연결 수 | Long | Y | |
| 5 | uniqueIps | 고유 IP 수 | Long | Y | |
| 6 | inboundTimeSeries | 인바운드 시계열 | Object | Y | TimeSeriesData |
| 7 | outboundTimeSeries | 아웃바운드 시계열 | Object | Y | TimeSeriesData |
| 8 | connectionsStateDistribution | 연결 상태 분포 | Map | Y | |
| 9 | servicePortDistribution | 서비스 포트 분포 | Map | Y | |
| 10 | durationDistribution | 지속시간 분포 | Map | Y | |
| 11 | connectionDetails | 연결 상세 목록 | List | Y | |
| 12 | totalConnectionRecords | 총 레코드 수 | Long | Y | |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | IP 주소 Base64 디코딩 | |
| 2 | 통계 조회 (90일 기준) | ClickHouse |
| 3 | 인바운드/아웃바운드 시계열 조회 (1일, 분 단위) | |
| 4 | 연결 상태/서비스 포트/지속시간 분포 조회 | |
| 5 | 연결 상세 목록 조회 (페이징) | |
| 6 | TrafficDetailDto 조립 후 반환 | |

---

### TPY_008 - 스위치 목록 그리드 데이터 조회

| 프로그램 ID | TPY_008 | 프로그램명 | 스위치 목록 그리드 데이터 조회 |
|------------|---------|----------|---------------------------|
| 분류 | 자산 | 처리유형 | 조회 |
| 클래스명 | AssetController.java | 메서드명 | gridDataTopologySwitchOptimized() |

▣ 기능 설명

AG Grid에 표시할 스위치 목록과 포트 상태 요약 정보를 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 세션에서 호기 정보 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 메시지 | String | Y | 처리 결과 메시지 |
| 3 | data[].idx | 스위치 ID | Long | Y | PK |
| 4 | data[].switchName | 스위치명 | String | Y | |
| 5 | data[].zone3 | 호기 | String | Y | |
| 6 | data[].totalPort | 총 포트 수 | Integer | Y | |
| 7 | data[].normalCount | 정상 포트 수 | Integer | Y | |
| 8 | data[].stopCount | 정지 포트 수 | Integer | Y | |
| 9 | data[].errorCount | 이상 포트 수 | Integer | Y | |
| 10 | data[].cautionCount | 일반이상 포트 수 | Integer | Y | |
| 11 | data[].noStatusCount | 상태없음 포트 수 | Integer | Y | |
| 12 | data[].unusedCount | 미사용 포트 수 | Integer | Y | |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 zone 정보 조회 | |
| 2 | 스위치 목록 조회 | TopologySwitchRepository |
| 3 | 스위치별 포트 상태 집계 (자산 운전 상태 기반) | |
| 4 | ApiResponse 래핑 후 반환 | JavaScript 하이재킹 방어 |