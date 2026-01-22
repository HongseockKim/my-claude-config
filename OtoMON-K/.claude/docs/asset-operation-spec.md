# 자산별 트래픽 현황 시스템 문서

## 개요

- **페이지 URL**: `/asset/trafficAsset`
- **메뉴 ID**: 2080L
- **주요 기능**: 자산별 네트워크 트래픽 모니터링 및 이상 탐지
- **데이터 소스**: ClickHouse (ZeekConn 테이블)

  ---                                                                                                         

## 파일 구조

Controller:  AssetController.java (115-221)                                                                 
Service:     AssetTrafficService.java (898줄)                                                               
Template:    pages/asset/trafficAsset.html                                                                  
JavaScript:  page.traffic/trafficAsset.js (968줄)                                                           
CSS:         pages/asset/trafficAsset.css                                                                   
DTO:         TrafficDetailDto.java, TrafficAssetExcelDto.java, TrafficDetailExcelDto.java
                                                                                                              
---                                                                                                         

## API 엔드포인트

### 1. 페이지 렌더링

| 항목 | 값 |                                                                                               
  |------|-----|                                                                                              
| URL | `GET /asset/trafficAsset` |                                                                         
| Controller | `AssetController.trafficAsset()` |                                                           
| 라인 | 115-119 |                                                                                          
| 반환 | `pages/asset/trafficAsset` (Thymeleaf) |                                                           
| 권한 | `@RequirePermission(menuId=2080L, READ)` |                                                         

### 2. 트래픽 목록 조회

| 항목 | 값 |                                                                                               
  |------|-----|                                                                                              
| URL | `POST /asset/api/getTrafficData` |                                                                  
| Controller | `AssetController.getTrafficData()` |                                                         
| 라인 | 166-188 |                                                                                          
| 파라미터 | `startRow` (기본 0), `endRow` (기본 100) |                                                     
| 반환 | `{ ret: 0, data: [...], totalCount: N }` |                                                         
| 권한 | `@RequirePermission(menuId=2080L, READ)` |                                                         
| 날짜 기본값 | 90일 |                                                                                      

### 3. 트래픽 상세 조회

| 항목 | 값 |                                                                                               
  |------|-----|                                                                                              
| URL | `POST /asset/api/getTrafficDetail` |                                                                
| Controller | `AssetController.getTrafficDetail()` |                                                       
| 라인 | 198-221 |                                                                                          
| 파라미터 | `ipAddress` (Base64), `startRaw`, `endRaw` |                                                   
| 반환 | `{ ret: 0, data: TrafficDetailDto }` |                                                             
| 권한 | ⚠️ **@RequirePermission 없음 (보안 취약)** |                                                       
| 날짜 기본값 | 7일 |                                                                                       

### 4. 목록 엑셀 다운로드

| 항목 | 값 |                                                                                               
  |------|-----|                                                                                              
| URL | `POST /asset/trafficAsset/exportExcel` |                                                            
| Controller | `AssetController.exportTrafficExcel()` |                                                     
| 라인 | 121-143 |                                                                                          
| 반환 | Excel 파일 (BLOB) |                                                                                
| 파일명 | `자산별트래픽현황_yyyyMMdd_HHmmss.xlsx` |                                                        
| 권한 | `@RequirePermission(menuId=2080L, WRITE)` |                                                        
| 최대 행 | 100,000건 |                                                                                     

### 5. 상세 엑셀 다운로드

| 항목 | 값 |                                                                                               
  |------|-----|                                                                                              
| URL | `POST /asset/trafficAsset/exportDetailExcel` |                                                      
| Controller | `AssetController.exportTrafficDetailExcel()` |                                               
| 라인 | 145-164 |                                                                                          
| 파라미터 | `@RequestBody List<ConnectionDetail>` |                                                        
| 반환 | Excel 파일 (BLOB) |                                                                                
| 권한 | `@RequirePermission(menuId=2080L, WRITE)` |                                                        
                                                                                                              
---                                                                                                         

## Service 메서드

### AssetTrafficService (898줄)

| 메서드 | 라인 | 반환타입 | 용도 |                                                                         
  |--------|-----|---------|------|                                                                           
| `getAssetTrafficData()` | - | `Map<String, Object>` | 자산별 트래픽 목록 (페이지네이션) |                 
| `getTrafficDetailData()` | - | `TrafficDetailDto` | 특정 IP 트래픽 상세 |                                 
| `exportTrafficToExcel()` | 328-381 | `ByteArrayResource` | 목록 Excel 생성 |                              
| `exportTrafficDetailToExcel()` | 384-404 | `ByteArrayResource` | 상세 Excel 생성 |                        

### 내부 헬퍼 메서드

| 메서드 | 용도 |                                                                                           
  |--------|------|                                                                                           
| `getAggregatedTrafficFromZeek()` | ClickHouse 집계 쿼리 (UNION ALL 방식) |                                
| `getTrafficDataTotalCount()` | 전체 IP 개수 조회 |                                                        
| `getTrafficStatistics()` | 통계 데이터 (총 트래픽/패킷/연결/고유IP) |                                     
| `getInboundTimeSeries()` | 인바운드 분단위 시계열 |                                                       
| `getOutboundTimeSeries()` | 아웃바운드 분단위 시계열 |                                                    
| `getConnectionStateDistribution()` | 연결 상태 분포 (SF, S0, REJ 등) |                                    
| `getServicePortDistribution()` | 서비스 포트 분포 (Top 6) |                                               
| `getDurationDistribution()` | 지속시간 분포 (카테고리화) |                                                
| `getConnectionDetails()` | 연결 상세 목록 (페이지네이션) |                                                
| `buildAssetIpMap()` | IP → Asset 매핑 구성 |                                                              
| `buildZone3InClause()` | Zone3 IN 절 생성 (숫자/코드 형식 모두) |                                         
                                                                                                              
---                                                                                                         

## ClickHouse 쿼리 패턴

### 자산 목록 집계 (UNION ALL)

  ```sql                                                                                                      
  SELECT                                                                                                      
      ip AS asset_ip,                                                                                         
      SUM(orig_ip_bytes + resp_ip_bytes) AS total_traffic,                                                    
      SUM(orig_pkts + resp_pkts) AS total_packets,                                                            
      COUNT(*) AS total_connections                                                                           
  FROM (                                                                                                      
      SELECT src_ip AS ip, ... FROM ZeekConn WHERE [조건]                                                     
      UNION ALL                                                                                               
      SELECT dst_ip AS ip, ... FROM ZeekConn WHERE [조건]                                                     
  ) sub                                                                                                       
  GROUP BY ip                                                                                                 
  ORDER BY total_connections DESC                                                                             
  LIMIT [limit] OFFSET [offset]                                                                               
                                                                                                              
  시계열 데이터 (분단위)                                                                                      
                                                                                                              
  SELECT                                                                                                      
      formatDateTime(toStartOfMinute(timestamp), '%Y-%m-%d %H:%i') AS minute,                                 
      SUM(orig_ip_bytes) / 1048576 AS traffic_mb,                                                             
      SUM(orig_pkts) AS packets,                                                                              
      COUNT(*) AS connections                                                                                 
  FROM ZeekConn                                                                                               
  WHERE src_ip = '특정IP' AND [날짜조건]                                                                      
  GROUP BY toStartOfMinute(timestamp)                                                                         
  ORDER BY minute                                                                                             
                                                                                                              
  날짜 조건 기본값                                                                                            
  ┌─────────────┬───────────┐                                                                                 
  │    용도     │ 기본 범위 │                                                                                 
  ├─────────────┼───────────┤                                                                                 
  │ 목록 조회   │ 90일      │                                                                                 
  ├─────────────┼───────────┤                                                                                 
  │ 상세 조회   │ 7일       │                                                                                 
  ├─────────────┼───────────┤                                                                                 
  │ 시계열/분포 │ 7일       │                                                                                 
  └─────────────┴───────────┘                                                                                 
  ---                                                                                                         
  임계값 설정                                                                                                 
  ┌──────────┬───────────────────────────┬─────────────────────────┐                                          
  │   항목   │          임계값           │      초과 시 표시       │                                          
  ├──────────┼───────────────────────────┼─────────────────────────┤                                          
  │ 트래픽량 │ 1GB (1,000,000,000 bytes) │ 노란 배경 + "초과" 배지 │                                          
  ├──────────┼───────────────────────────┼─────────────────────────┤                                          
  │ 패킷수   │ 100만 (1,000,000)         │ 노란 배경 + "초과" 배지 │                                          
  ├──────────┼───────────────────────────┼─────────────────────────┤                                          
  │ 연결수   │ 1만 (10,000)              │ 노란 배경 + "초과" 배지 │                                          
  └──────────┴───────────────────────────┴─────────────────────────┘                                          
  서버 측 플래그 설정 (AssetTrafficService)                                                                   
                                                                                                              
  long trafficThreshold = 1_000_000_000L;    // 1GB                                                           
  long packetThreshold = 1_000_000L;         // 100만                                                         
  long connectionThreshold = 10_000L;        // 1만                                                           
                                                                                                              
  row.put("trafficExceeded", totalTraffic > trafficThreshold);                                                
  row.put("packetExceeded", totalPackets > packetThreshold);                                                  
  row.put("connectionExceeded", connectionCount > connectionThreshold);                                       
                                                                                                              
  클라이언트 측 표시 (trafficAsset.js)                                                                        
                                                                                                              
  // 배경색 (cellStyle)                                                                                       
  if (params.data.trafficExceeded) {                                                                          
      return {backgroundColor: '#fff3cd', color: '#856404'};                                                  
  }                                                                                                           
                                                                                                              
  // 배지 (cellRenderer)                                                                                      
  if (params.value) {                                                                                         
      return '<span class="badge bg-danger">초과</span>';                                                     
  }                                                                                                           
  return '<span class="badge bg-success">정상</span>';                                                        
                                                                                                              
  ---                                                                                                         
  TrafficDetailDto 구조                                                                                       
                                                                                                              
  메인 필드                                                                                                   
                                                                                                              
  String assetName              // 자산명 (기본값: "미등록 자산")                                             
  String ipAddress              // IP 주소 (Base64 인코딩)                                                    
  String macAddress             // MAC 주소 (Base64 인코딩)                                                   
                                                                                                              
  Long totalTraffic             // 총 트래픽량 (바이트)                                                       
  Long totalPackets             // 총 패킷 수                                                                 
  Long totalConnections         // 총 연결 수                                                                 
  Long uniqueIps                // 통신한 고유 IP 개수                                                        
                                                                                                              
  TimeSeriesData inboundTimeSeries    // 인바운드 시계열                                                      
  TimeSeriesData outboundTimeSeries   // 아웃바운드 시계열                                                    
                                                                                                              
  Map<String,Long> connectionsStateDistribution  // 연결 상태 분포                                            
  Map<String,Long> servicePortDistribution       // 포트 분포                                                 
  Map<String,Long> durationDistribution          // 지속시간 분포                                             
                                                                                                              
  List<ConnectionDetail> connectionDetails       // 연결 상세 목록                                            
  Long totalConnectionRecords                    // 전체 연결 레코드 수                                       
                                                                                                              
  TimeSeriesData 구조                                                                                         
                                                                                                              
  List<String> timestamps       // "2025-01-15 10:30" 형식                                                    
  List<Long> trafficMB          // MB 단위 트래픽                                                             
  List<Long> packets            // 패킷 수                                                                    
  List<Long> connections        // 연결 수                                                                    
                                                                                                              
  ConnectionDetail 구조                                                                                       
                                                                                                              
  String timestamp              // "2025-01-15 10:30:45"                                                      
  String srcIp, srcPort         // 출발지 (Base64 인코딩)                                                     
  String dstIp, dstPort         // 목적지 (Base64 인코딩)                                                     
  String proto                  // tcp, udp 등                                                                
  String service                // 서비스명                                                                   
  Double duration               // 연결 지속시간 (초)                                                         
  String connState              // Zeek 연결 상태                                                             
  Long origPkts, origBytes      // 송신 패킷/바이트                                                           
  Long respPkts, respBytes      // 수신 패킷/바이트                                                           
                                                                                                              
  Base64 인코딩 (toEncoded 메서드)                                                                            
                                                                                                              
  public TrafficDetailDto toEncoded() {                                                                       
      return TrafficDetailDto.builder()                                                                       
          .ipAddress(encodeBase64(this.ipAddress))                                                            
          .macAddress(encodeBase64(this.macAddress))                                                          
          // connectionDetails의 srcIp, dstIp도 인코딩                                                        
          .build();                                                                                           
  }                                                                                                           
                                                                                                              
  ---                                                                                                         
  JavaScript 구조 (trafficAsset.js)                                                                           
                                                                                                              
  전역 변수                                                                                                   
  ┌──────────────────────────┬────────┬──────────────────────────────────┐                                    
  │          변수명          │  타입  │               용도               │                                    
  ├──────────────────────────┼────────┼──────────────────────────────────┤                                    
  │ gridApi                  │ Object │ 메인 AG Grid API                 │                                    
  ├──────────────────────────┼────────┼──────────────────────────────────┤                                    
  │ trafficCharts            │ Object │ ECharts 인스턴스 저장소 (9개)    │                                    
  ├──────────────────────────┼────────┼──────────────────────────────────┤                                    
  │ rawTimeSeriesData        │ Object │ 원본 시계열 데이터               │                                    
  ├──────────────────────────┼────────┼──────────────────────────────────┤                                    
  │ currentAggregationLevel  │ String │ 현재 집계 레벨 (minute/hour/day) │                                    
  ├──────────────────────────┼────────┼──────────────────────────────────┤                                    
  │ currentConnectionDetails │ Array  │ 연결 상세 데이터                 │                                    
  ├──────────────────────────┼────────┼──────────────────────────────────┤                                    
  │ connectionDetailGridApi  │ Object │ 상세 Grid API                    │                                    
  └──────────────────────────┴────────┴──────────────────────────────────┘                                    
  주요 함수 (16개)                                                                                            
  ┌───────────────────────────────┬─────────┬───────────────────────────┐                                     
  │             함수              │  라인   │           용도            │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ initGrid()                    │ 21-55   │ 메인 그리드 초기화        │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ trafficDataColum()            │ 171-315 │ 컬럼 정의 (12개)          │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ createServerSideDatasource()  │ 317-353 │ Server-Side datasource    │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ openTrafficDetail()           │ 364-376 │ 상세 팝업 열기            │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ loadTrafficDetailData()       │ 378-447 │ 상세 API 호출             │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ createTimeSeriesChartOption() │ 449-515 │ 시계열 차트 옵션          │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ initTimeSeriesCharts()        │ 518-580 │ 6개 시계열 차트 초기화    │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ initDistributionCharts()      │ 582-711 │ 3개 분포 차트 초기화      │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ initConnectionDetailGrid()    │ 713-823 │ 연결상세 그리드 초기화    │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ exportTrafficExcel()          │ 825-864 │ 목록 엑셀 다운로드        │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ exportTrafficDetailExcel()    │ 867-919 │ 상세 엑셀 다운로드        │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ aggregateTimeSeries()         │ 66-101  │ 시계열 재집계 (hour/day)  │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ getAggregationLevel()         │ 103-111 │ 집계 레벨 자동 결정       │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ updateAllTimeSeriesCharts()   │ 138-169 │ 모든 시계열 차트 업데이트 │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ decodeBase64()                │ 57-64   │ Base64 디코딩             │                                     
  ├───────────────────────────────┼─────────┼───────────────────────────┤                                     
  │ formatBytes()                 │ 355-361 │ 바이트 포맷팅             │                                     
  └───────────────────────────────┴─────────┴───────────────────────────┘                                     
  ---                                                                                                         
  ECharts 차트 구성 (9개)                                                                                     
                                                                                                              
  시계열 차트 (6개)                                                                                           
  ┌──────────────────────────┬────────────┬─────────────┬────────────────┐                                    
  │         차트 ID          │     탭     │   데이터    │      색상      │                                    
  ├──────────────────────────┼────────────┼─────────────┼────────────────┤                                    
  │ inboundTrafficChart      │ 인바운드   │ trafficMB   │ #3b82f6 (파랑) │                                    
  ├──────────────────────────┼────────────┼─────────────┼────────────────┤                                    
  │ inboundPacketsChart      │ 인바운드   │ packets     │ #06b6d4 (시안) │                                    
  ├──────────────────────────┼────────────┼─────────────┼────────────────┤                                    
  │ inboundConnectionsChart  │ 인바운드   │ connections │ #10b981 (초록) │                                    
  ├──────────────────────────┼────────────┼─────────────┼────────────────┤                                    
  │ outboundTrafficChart     │ 아웃바운드 │ trafficMB   │ #ef4444 (빨강) │                                    
  ├──────────────────────────┼────────────┼─────────────┼────────────────┤                                    
  │ outboundPacketsChart     │ 아웃바운드 │ packets     │ #f97316 (주황) │                                    
  ├──────────────────────────┼────────────┼─────────────┼────────────────┤                                    
  │ outboundConnectionsChart │ 아웃바운드 │ connections │ #f59e0b (황금) │                                    
  └──────────────────────────┴────────────┴─────────────┴────────────────┘                                    
  분포 차트 (3개)                                                                                             
  ┌──────────────────┬────────────┬───────────────────┐                                                       
  │     차트 ID      │    타입    │       용도        │                                                       
  ├──────────────────┼────────────┼───────────────────┤                                                       
  │ connStateChart   │ 도넛 (Pie) │ 연결 상태 분포    │                                                       
  ├──────────────────┼────────────┼───────────────────┤                                                       
  │ servicePortChart │ 도넛 (Pie) │ 서비스 포트 Top 6 │                                                       
  ├──────────────────┼────────────┼───────────────────┤                                                       
  │ durationChart    │ 막대 (Bar) │ 지속시간 카테고리 │                                                       
  └──────────────────┴────────────┴───────────────────┘                                                       
  시계열 차트 설정                                                                                            
                                                                                                              
  {                                                                                                           
      type: 'line',                                                                                           
      smooth: true,                                                                                           
      sampling: 'lttb',           // 대용량 데이터 최적화                                                     
      areaStyle: { opacity: 0.3 },                                                                            
      dataZoom: [                                                                                             
          { type: 'slider', height: 25 },                                                                     
          { type: 'inside' }      // 휠 줌                                                                    
      ]                                                                                                       
  }                                                                                                           
                                                                                                              
  동적 집계 레벨                                                                                              
  ┌──────────────────┬───────────────┐                                                                        
  │ 보이는 포인트 수 │   집계 레벨   │                                                                        
  ├──────────────────┼───────────────┤                                                                        
  │ > 500            │ hour (시간별) │                                                                        
  ├──────────────────┼───────────────┤                                                                        
  │ > 1000           │ day (일별)    │                                                                        
  ├──────────────────┼───────────────┤                                                                        
  │ 그 외            │ minute (분별) │                                                                        
  └──────────────────┴───────────────┘                                                                        
  function getAggregationLevel(visiblePointsCount) {                                                          
      if (visiblePointsCount > 1000) return 'day';                                                            
      if (visiblePointsCount > 500) return 'hour';                                                            
      return 'minute';                                                                                        
  }                                                                                                           
                                                                                                              
  ---                                                                                                         
  AG Grid 설정                                                                                                
                                                                                                              
  메인 그리드 (trafficGrid)                                                                                   
  ┌───────────────┬───────────────────────────────────────┐                                                   
  │     설정      │                  값                   │                                                   
  ├───────────────┼───────────────────────────────────────┤                                                   
  │ Row Model     │ serverSide                            │                                                   
  ├───────────────┼───────────────────────────────────────┤                                                   
  │ Pagination    │ Page Size 50, 옵션 [20, 50, 100, 200] │                                                   
  ├───────────────┼───────────────────────────────────────┤                                                   
  │ Row Height    │ 40px                                  │                                                   
  ├───────────────┼───────────────────────────────────────┤                                                   
  │ Header Height │ 45px                                  │                                                   
  ├───────────────┼───────────────────────────────────────┤                                                   
  │ Theme         │ ag-theme-quartz-dark                  │                                                   
  ├───────────────┼───────────────────────────────────────┤                                                   
  │ CSP Nonce     │ styleNonce 적용                       │                                                   
  └───────────────┴───────────────────────────────────────┘                                                   
  컬럼 정의 (12개)                                                                                            
  ┌────────────────────┬─────────────────┬────────────────────────┐                                           
  │        필드        │      헤더       │          특징          │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ rowNum             │ No              │ pinned: 'left'         │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ assetName          │ 자산명          │ 미등록 시 노란 배지    │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ ipAddress          │ IP주소          │ Base64 디코딩 + 마스킹 │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ macAddress         │ MAC주소         │ Base64 디코딩 + 마스킹 │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ trafficAmount      │ 트래픽량        │ formatBytes()          │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ packetCount        │ 패킷수          │ toLocaleString()       │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ connectionCount    │ 연결수          │ toLocaleString()       │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ trafficExceeded    │ 트래픽 임계초과 │ 배지 렌더러            │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ packetExceeded     │ 패킷수 임계초과 │ 배지 렌더러            │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ connectionExceeded │ 연결수 임계초과 │ 배지 렌더러            │                                           
  ├────────────────────┼─────────────────┼────────────────────────┤                                           
  │ status             │ 운전상태        │ 상태 매핑              │                                           
  └────────────────────┴─────────────────┴────────────────────────┘                                           
  연결상세 그리드 (connectionDetailGrid)                                                                      
  설정: Row Model                                                                                             
  값: clientSide                                                                                              
  ────────────────────────────────────────                                                                    
  설정: Pagination                                                                                            
  값: 비활성                                                                                                  
  ────────────────────────────────────────                                                                    
  설정: Height                                                                                                
  값: 400px                                                                                                   
  ────────────────────────────────────────                                                                    
  설정: 컬럼                                                                                                  
  값: 12개 (timestamp, srcIp, srcPort, dstIp, dstPort, proto, service, duration, connState, origPkts,         
  respPkts,                                                                                                   
    origBytes, respBytes)                                                                                     
  ---                                                                                                         
  Base64 인코딩/디코딩 흐름                                                                                   
                                                                                                              
  서버 → 클라이언트                                                                                           
                                                                                                              
  1. Service: IP/MAC 원본 데이터                                                                              
        ↓                                                                                                     
  2. TrafficDetailDto.toEncoded(): Base64 인코딩                                                              
        ↓                                                                                                     
  3. Controller: JSON 응답                                                                                    
        ↓                                                                                                     
  4. JavaScript: atob()로 디코딩                                                                              
        ↓                                                                                                     
  5. DataMaskingUtils.maskSensitiveData(): 마스킹 적용                                                        
        ↓                                                                                                     
  6. UI 표시: "192.168.***.***"                                                                               
                                                                                                              
  클라이언트 → 서버                                                                                           
                                                                                                              
  1. JavaScript: IP 원본 (디코딩된 상태)                                                                      
        ↓                                                                                                     
  2. btoa(): Base64 인코딩                                                                                    
        ↓                                                                                                     
  3. API 요청: ipAddress 파라미터                                                                             
        ↓                                                                                                     
  4. Controller: ValidationUtils.safeBase64Decode()                                                           
        ↓                                                                                                     
  5. Service: 원본 IP로 ClickHouse 쿼리                                                                       
                                                                                                              
  decodeBase64 함수                                                                                           
                                                                                                              
  function decodeBase64(encoded) {                                                                            
      if (!encoded || encoded === '-') return encoded;                                                        
      try {                                                                                                   
          return decodeURIComponent(escape(atob(encoded)));                                                   
      } catch (e) {                                                                                           
          return encoded;                                                                                     
      }                                                                                                       
  }                                                                                                           
                                                                                                              
  ---                                                                                                         
  보안 구현                                                                                                   
                                                                                                              
  CSP Nonce                                                                                                   
                                                                                                              
  <!-- 모든 script 태그에 적용 -->                                                                            
  <script th:nonce="${nonce}" th:src="@{/js/...}"></script>                                                   
                                                                                                              
  <!-- AG Grid 동적 스타일용 -->                                                                              
  styleNonce: document.querySelector('meta[name="csp-nonce"]')?.content                                       
                                                                                                              
  SRI (Subresource Integrity)                                                                                 
                                                                                                              
  <script crossorigin="anonymous"                                                                             
          th:integrity="${sri.getHash('echarts.min.js')}"                                                     
          th:nonce="${nonce}"                                                                                 
          th:src="@{/js/echarts.min.js}"></script>                                                            
                                                                                                              
  CSRF 토큰                                                                                                   
                                                                                                              
  beforeSend: function (xhr) {                                                                                
      const csrfHeader = $("meta[name='_csrf_header']").attr("content");                                      
      const csrfToken = $("meta[name='_csrf']").attr("content");                                              
      if (csrfHeader && csrfToken) {                                                                          
          xhr.setRequestHeader(csrfHeader, csrfToken);                                                        
      }                                                                                                       
  }                                                                                                           
                                                                                                              
  IP 마스킹                                                                                                   
                                                                                                              
  DataMaskingUtils.maskSensitiveData(decodeBase64(params.value))                                              
  // 결과: "192.168.***.***"                                                                                  
                                                                                                              
  ---                                                                                                         
  Zone3 필터링                                                                                                
                                                                                                              
  세션에서 Zone 정보 추출                                                                                     
                                                                                                              
  String selectedZoneCode = (String) session.getAttribute("selectedZoneCode");                                
  if (selectedZoneCode == null || selectedZoneCode.isEmpty()) {                                               
      zone3List = systemConfigService.getActiveZone3List();  // 전체 호기                                     
  } else {                                                                                                    
      zone3List = Collections.singletonList(selectedZoneCode);  // 선택된 호기                                
  }                                                                                                           
                                                                                                              
  Zone3 IN 절 생성 (buildZone3InClause)                                                                       
                                                                                                              
  // zone3이 숫자 또는 코드 형식일 수 있으므로 둘 다 포함                                                     
  for (String zone3 : zone3List) {                                                                            
      String numeric = Zone3Util.toNumber(zone3);    // "3"                                                   
      String code = Zone3Util.toCode(zone3);         // "sp_03"                                               
  }                                                                                                           
  // 결과: zone3 IN ('3', 'sp_03', '4', 'sp_04')                                                              
                                                                                                              
  ---                                                                                                         
  데이터 흐름                                                                                                 
                                                                                                              
  메인 페이지 로드                                                                                            
                                                                                                              
  페이지 요청 (GET /asset/trafficAsset)                                                                       
      ↓                                                                                                       
  @RequirePermission(menuId=2080L, READ) 검증                                                                 
      ↓                                                                                                       
  Thymeleaf 렌더링                                                                                            
      ↓                                                                                                       
  JavaScript 초기화 (initGrid)                                                                                
      ↓                                                                                                       
  Server-Side Datasource 생성                                                                                 
      ↓                                                                                                       
  POST /asset/api/getTrafficData (startRow=0, endRow=50)                                                      
      ↓                                                                                                       
  AG Grid 렌더링                                                                                              
                                                                                                              
  상세 팝업 로드                                                                                              
                                                                                                              
  행 클릭 (onRowClicked)                                                                                      
      ↓                                                                                                       
  decodeBase64(ipAddress)                                                                                     
      ↓                                                                                                       
  openTrafficDetail(ip)                                                                                       
      ↓                                                                                                       
  Offcanvas 표시                                                                                              
      ↓                                                                                                       
  loadTrafficDetailData(ip)                                                                                   
      ↓                                                                                                       
  POST /asset/api/getTrafficDetail (ipAddress=Base64)                                                         
      ↓                                                                                                       
  응답 처리:                                                                                                  
      - 통계 카드 업데이트                                                                                    
      - 6개 시계열 차트 초기화                                                                                
      - 3개 분포 차트 초기화                                                                                  
      - 연결상세 그리드 초기화                                                                                
                                                                                                              
  Offcanvas 닫기                                                                                              
                                                                                                              
  hidden.bs.offcanvas 이벤트                                                                                  
      ↓                                                                                                       
  autoRefreshInterval 정리                                                                                    
      ↓                                                                                                       
  상태 초기화 (currentDetailIpAddress = null)                                                                 
      ↓                                                                                                       
  탭 초기화 (인바운드 탭으로)                                                                                 
      ↓                                                                                                       
  차트 메모리 해제 (chart.dispose())                                                                          
      ↓                                                                                                       
  데이터 초기화 (rawTimeSeriesData, trafficCharts)                                                            
                                                                                                              
  ---                                                                                                         
  성능 최적화                                                                                                 
  ┌────────────────────────┬───────────────────────────────────────────────────┐                              
  │          항목          │                     구현 방식                     │                              
  ├────────────────────────┼───────────────────────────────────────────────────┤                              
  │ Server-Side Pagination │ 전체 로드 X, 요청한 범위만 조회                   │                              
  ├────────────────────────┼───────────────────────────────────────────────────┤                              
  │ 차트 샘플링            │ sampling: 'lttb' (Largest-Triangle-Three-Buckets) │                              
  ├────────────────────────┼───────────────────────────────────────────────────┤                              
  │ DataZoom 디바운스      │ _.debounce(handleDataZoom, 300ms)                 │                              
  ├────────────────────────┼───────────────────────────────────────────────────┤                              
  │ 동적 집계              │ 보이는 포인트 수에 따라 minute/hour/day 자동 전환 │                              
  ├────────────────────────┼───────────────────────────────────────────────────┤                              
  │ 메모리 정리            │ Offcanvas 닫을 때 chart.dispose()                 │                              
  ├────────────────────────┼───────────────────────────────────────────────────┤                              
  │ 최대 행 제한           │ Excel 다운로드 시 100,000건                       │                              
  └────────────────────────┴───────────────────────────────────────────────────┘                              
 ┌───────────────────┬──────────────────────────┬────────────────────┐                                       
  │       권한        │       IP/MAC 표시        │ 엑셀 다운로드 버튼 │                                       
  ├───────────────────┼──────────────────────────┼────────────────────┤                                       
  │ 관리자 (isAdmin)  │ 원본 표시                │ ✅ 표시            │                                       
  ├───────────────────┼──────────────────────────┼────────────────────┤                                       
  │ WRITE/DELETE 권한 │ 원본 표시                │ ✅ 표시            │                                       
  ├───────────────────┼──────────────────────────┼────────────────────┤                                       
  │ READ 권한만       │ 마스킹 (192.168.***.***) │ ❌ 숨김            │                                       
  └───────────────────┴──────────────────────────┴────────────────────┘                                       
  그래서 getTrafficDetail에 @RequirePermission 없어도:                                                        
  1. 페이지 접근 자체가 READ 권한 필요                                                                        
  2. 상세 조회해도 READ 전용 사용자는 마스킹된 데이터만 봄                                                    
  3. 엑셀 다운로드는 WRITE 권한 있어야 버튼이 보임                                                            
                                                                                                                                                         
  지속시간 카테고리화                                                                                         
                                                                                                              
  categorizeDuration 메서드 (Service)                                                                         
                                                                                                              
  private String categorizeDuration(Double duration) {                                                        
      if (duration == null || duration < 1) return "1초 미만";                                                
      if (duration < 5) return "1-5초";                                                                       
      if (duration < 10) return "5-10초";                                                                     
      if (duration < 30) return "10-30초";                                                                    
      return "30초 이상";                                                                                     
  }                                                                                                           
                                                                                                              
  분포 차트 표시                                                                                              
                                                                                                              
  X축: ["1초 미만", "1-5초", "5-10초", "10-30초", "30초 이상"]                                                
  Y축: 각 카테고리별 연결 수                                                                                  
                                                                                                              
  ---                                                                                                         
  관련 문서                                                                                                   
                                                                                                              
  - 자산현황: .claude/docs/asset-operation-spec.md                                                            
  - 보안 설정: .claude/docs/security.md                                                                       
  - 프론트엔드 패턴: .claude/docs/frontend-patterns.md                                                        
  - 세션 필터링: .claude/docs/session-filtering.md                                                            
  - 엑셀 다운로드: .claude/docs/excel-download-system.md                                                      
                                                                                                              
  --- 