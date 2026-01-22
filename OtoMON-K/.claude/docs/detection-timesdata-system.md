# 이상 이벤트 탐지 현황 (timesData) 시스템

## 개요

| 항목 | 내용 |                                                                                             
  |------|------|                                                                                             
| **URL** | `/detection/timesData` |                                                                        
| **메뉴 ID** | 4060L |                                                                                     
| **권한** | READ 권한 필요 |                                                                               
| **한글명** | 이상 이벤트 탐지 현황 |                                                                      
| **목적** | 모든 이벤트 유형(네트워크/자산/운전정보)을 통합 조회 및 분석 |                                 
                                                                                                              
---                                                                                                         

## 파일 구조

| 파일 | 경로 | 줄수 |                                                                                      
  |------|------|------|                                                                                      
| Controller | `controller/DetectionController.java` | 1,419줄 |                                            
| Service | `service/DetectionService.java` | 3,235줄 |                                                     
| Template | `templates/pages/detection/timesData.html` | - |                                               
| Fragment | `templates/fragments/detection/eventDetailOffcanvas.html` | - |                                
| JavaScript | `static/js/page.detection/timesData.js` | 920줄 |                                            
| CSS | `static/css/pages/detection/timesData.css` | - |                                                    
                                                                                                              
---                                                                                                         

## API 엔드포인트

### 페이지 및 데이터

| Method | Endpoint | 라인 | 권한 | @ActivityLog | 설명 |                                                   
  |--------|----------|------|------|--------------|------|                                                   
| GET | `/detection/timesData` | 720-856 | 4060L READ | ❌ | 페이지 렌더링 |                                
| GET | `/detection/timesData/infinite` | 636-710 | - | ❌ | 무한스크롤 데이터 |                            
| GET | `/detection/timesData/unique-protocols` | 713-718 | - | ❌ | 프로토콜 목록 |                        

### 관련 이벤트

| Method | Endpoint | 라인 | 설명 |                                                                         
  |--------|----------|------|------|                                                                         
| GET | `/detection/related-events` | - | 관련 이벤트 조회 (JSON) |                                         
| GET | `/detection/related-events/more` | - | 관련 이벤트 더보기 |                                         

### 조치 및 분석 (connection API 공유)

| Method | Endpoint | 라인 | 권한 | @ActivityLog | 설명 |                                                   
  |--------|----------|------|------|--------------|------|                                                   
| POST | `/detection/connection/save-action` | 378-461 | 4020L WRITE | ❌ | 조치 저장 |                     
| GET | `/detection/connection/get-analysisHistory` | 605-634 | - | ❌ | 분석기록 조회 |                    
| POST | `/detection/connection/save-analysisHistory` | 463-492 | 4020L WRITE | ✅ | 분석기록 저장 |        

### timeSereiseData 관련 (별도 페이지, 메뉴 ID 4070L)

| Method | Endpoint | 라인 | 권한 | 설명 |                                                                  
  |--------|----------|------|------|------|                                                                  
| GET | `/detection/timeSereiseData` | 862-945 | 4070L READ | 시계열 페이지 |                               
| GET | `/detection/timeSereiseData/exportExcel` | 948-997 | 4070L WRITE | 엑셀 다운로드 |                  
| GET | `/detection/api/timeseries/data` | 1002-1030 | - | 시계열 데이터 |                                  
| GET | `/detection/api/timeseries/latest` | 1032-1064 | - | 최신 데이터 |                                  
| GET | `/detection/api/timeseries/range` | 1066-1108 | - | 범위 데이터 |                                   
| GET | `/detection/timeseries/eventDetail` | 1252-1292 | - | 이벤트 상세 |                                 
| POST | `/detection/save-analysis` | 495-524 | 4070L WRITE | 분석 저장 |                                   
| GET | `/detection/get-analysis` | 527-558 | - | 분석 조회 |                                               
| POST | `/detection/save-action` | 561-603 | 4070L WRITE | 조치 저장 |                                     
                                                                                                              
---                                                                                                         

## 컨트롤러 (DetectionController.java)

### 페이지 렌더링 (`GET /detection/timesData`)

**위치**: `DetectionController.java:720-856`

**권한**:
  ```java                                                                                                     
  @RequirePermission(menuId = 4060L, resourceType = ResourceType.MENU, permissionType = PermissionType.READ)  
                                                                                                              
  주요 로직:                                                                                                  
  1. 세션에서 날짜/호기 정보 가져오기 (startDateTime, endDateTime, selectedZoneCode)                          
  2. 날짜 변환 (yyyy-MM-dd → LocalDateTime)                                                                   
  3. 이벤트 유형별 카운트 조회 (connection, asset, operation)                                                 
  4. 모델에 카운트 및 사용자 정보 추가                                                                        
  5. URL 파라미터로 초기 eventType 필터 설정 가능                                                             
                                                                                                              
  모델 속성:                                                                                                  
  ┌──────────────────────────┬────────────────────────────────────────┐                                       
  │          속성명          │                  설명                  │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ grandTotalCount          │ 전체 탐지 수                           │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ totalViolationCount      │ 조치대상 수                            │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ totalActionedCount       │ 조치완료 수                            │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ totalIgnoreCount         │ 무시 수                                │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ connectionTotalCount     │ 네트워크 이벤트 수                     │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ connectionViolationCount │ 네트워크 위반 수                       │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ connectionIgnoreCount    │ 네트워크 무시 수                       │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ connectionPendingCount   │ 네트워크 대기 수                       │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ assetTotalCount          │ 자산 이벤트 수                         │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ assetViolationCount      │ 자산 위반 수                           │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ operationTotalCount      │ 운전정보 이벤트 수                     │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ operationViolationCount  │ 운전정보 위반 수                       │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ userInfo                 │ 사용자 정보 (userId, userName)         │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ selectedDateRange        │ 날짜 범위 (startDateTime, endDateTime) │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ selectedZone             │ 호기 정보 (code, name)                 │                                       
  ├──────────────────────────┼────────────────────────────────────────┤                                       
  │ initialEventType         │ URL 파라미터 eventType                 │                                       
  └──────────────────────────┴────────────────────────────────────────┘                                       
  데이터 조회 API (GET /detection/timesData/infinite)                                                         
                                                                                                              
  위치: DetectionController.java:636-710                                                                      
                                                                                                              
  방식: 무한 스크롤 (Infinite Scroll)                                                                         
                                                                                                              
  파라미터:                                                                                                   
  ┌─────────────┬────────┬────────┬─────────┬─────────────────────┐                                           
  │  파라미터   │  타입  │ 기본값 │  검증   │        설명         │                                           
  ├─────────────┼────────┼────────┼─────────┼─────────────────────┤                                           
  │ startRow    │ int    │ 0      │ @Min(0) │ 시작 행             │                                           
  ├─────────────┼────────┼────────┼─────────┼─────────────────────┤                                           
  │ endRow      │ int    │ 20     │ @Min(1) │ 종료 행             │                                           
  ├─────────────┼────────┼────────┼─────────┼─────────────────────┤                                           
  │ filterModel │ String │ null   │ -       │ AG Grid 필터 (JSON) │                                           
  └─────────────┴────────┴────────┴─────────┴─────────────────────┘                                           
  응답 형식:                                                                                                  
  {                                                                                                           
    "data": [...],                                                                                            
    "totalCount": 1234                                                                                        
  }                                                                                                           
                                                                                                              
  프로토콜 목록 조회 (GET /detection/timesData/unique-protocols)                                              
                                                                                                              
  위치: DetectionController.java:713-718                                                                      
                                                                                                              
  응답:                                                                                                       
  {                                                                                                           
    "protocols": ["TCP", "UDP", "ICMP", ...]                                                                  
  }                                                                                                           
                                                                                                              
  ---                                                                                                         
  서비스 (DetectionService.java)                                                                              
                                                                                                              
  getAllEventsOptimized()                                                                                     
                                                                                                              
  위치: DetectionService.java:2944                                                                            
                                                                                                              
  최적화된 이벤트 조회 메서드                                                                                 
                                                                                                              
  파라미터:                                                                                                   
  ┌─────────────┬───────────────┬──────────────────┐                                                          
  │  파라미터   │     타입      │       설명       │                                                          
  ├─────────────┼───────────────┼──────────────────┤                                                          
  │ startRow    │ int           │ 시작 행          │                                                          
  ├─────────────┼───────────────┼──────────────────┤                                                          
  │ endRow      │ int           │ 종료 행          │                                                          
  ├─────────────┼───────────────┼──────────────────┤                                                          
  │ filterModel │ Map           │ AG Grid 필터     │                                                          
  ├─────────────┼───────────────┼──────────────────┤                                                          
  │ startDate   │ LocalDateTime │ 시작 날짜 (세션) │                                                          
  ├─────────────┼───────────────┼──────────────────┤                                                          
  │ endDate     │ LocalDateTime │ 종료 날짜 (세션) │                                                          
  ├─────────────┼───────────────┼──────────────────┤                                                          
  │ zone3       │ String        │ 호기 코드 (세션) │                                                          
  └─────────────┴───────────────┴──────────────────┘                                                          
  처리 로직:                                                                                                  
  1. 페이징 설정 (PageRequest)                                                                                
     ├─ pageSize = endRow - startRow                                                                          
     ├─ pageNumber = startRow / pageSize                                                                      
     └─ Sort.by("detectedAt").descending()                                                                    
                                                                                                              
  2. eventType 필터 추출                                                                                      
     └─ filterModel에서 "eventType" 키 탐색 → lowercase 변환                                                  
                                                                                                              
  3. 조건부 DB 조회                                                                                           
     ├─ eventTypeFilter가 있을 경우:                                                                          
     │  └─ findActiveEventsByTypeAndDateRangeAndZonePaged()                                                   
     └─ eventTypeFilter가 없을 경우:                                                                          
        └─ findActiveEventsByDateRangeAndZonePaged()                                                          
                                                                                                              
  4. EventDefinition 캐싱 조회                                                                                
     └─ getCachedEventDefinitions()                                                                           
                                                                                                              
  5. Event → EventWithStatusDto 변환                                                                          
     └─ convertToEventWithStatusDto()                                                                         
                                                                                                              
  6. 추가 필터 적용 (텍스트, Set 필터)                                                                        
     └─ applyFilters()                                                                                        
                                                                                                              
  7. 2001 이벤트 그룹핑 (connection만)                                                                        
     └─ groupEvent2001Optimized()                                                                             
                                                                                                              
  8. 결과 반환                                                                                                
                                                                                                              
  getEventCountsByAllTypesFiltered()                                                                          
                                                                                                              
  위치: DetectionService.java:861                                                                             
                                                                                                              
  유형별 이벤트 카운트 조회                                                                                   
                                                                                                              
  반환:                                                                                                       
  Map<String, EventCountDto> {                                                                                
    "connection": EventCountDto { violationCount, ignoreCount, actionedCount, pendingCount, totalCount },     
    "asset": EventCountDto { ... },                                                                           
    "operation": EventCountDto { ... }                                                                        
  }                                                                                                           
                                                                                                              
  applyFilters()                                                                                              
                                                                                                              
  위치: DetectionService.java:894                                                                             
                                                                                                              
  AG Grid 필터 적용                                                                                           
                                                                                                              
  지원 필터:                                                                                                  
  ┌────────────┬──────────┬───────────────────────────────┐                                                   
  │   필터명   │ 필터타입 │             로직              │                                                   
  ├────────────┼──────────┼───────────────────────────────┤                                                   
  │ status     │ Set      │ 값 목록 포함 여부             │                                                   
  ├────────────┼──────────┼───────────────────────────────┤                                                   
  │ eventCode  │ Set      │ 값 목록 포함 여부             │                                                   
  ├────────────┼──────────┼───────────────────────────────┤                                                   
  │ eventName  │ Text     │ 대소문자 무시 contains        │                                                   
  ├────────────┼──────────┼───────────────────────────────┤                                                   
  │ eventType  │ Set      │ 대소문자 무시 equals          │                                                   
  ├────────────┼──────────┼───────────────────────────────┤                                                   
  │ zone3      │ Set      │ 정확 매칭                     │                                                   
  ├────────────┼──────────┼───────────────────────────────┤                                                   
  │ detectedAt │ Text     │ contains/equals/startsWith    │                                                   
  ├────────────┼──────────┼───────────────────────────────┤                                                   
  │ srcIp      │ Text     │ contains (Base64 인코딩된 값) │                                                   
  ├────────────┼──────────┼───────────────────────────────┤                                                   
  │ dstIp      │ Text     │ contains (Base64 인코딩된 값) │                                                   
  ├────────────┼──────────┼───────────────────────────────┤                                                   
  │ dstPort    │ Text     │ contains                      │                                                   
  ├────────────┼──────────┼───────────────────────────────┤                                                   
  │ protocol   │ Set      │ 값 목록 포함 여부             │                                                   
  └────────────┴──────────┴───────────────────────────────┘                                                   
  ---                                                                                                         
  JavaScript 구조 (timesData.js)                                                                              
                                                                                                              
  전역 변수 및 캐시                                                                                           
                                                                                                              
  // 성능 최적화 캐시 (3개)                                                                                   
  const maskingCache = new Map();  // IP 마스킹 결과 캐시                                                     
  const decodeCache = new Map();   // Base64 디코딩 결과 캐시                                                 
  const detailCache = new Map();   // detail JSON 디코딩 결과 캐시                                            
                                                                                                              
  // 상태 변수                                                                                                
  let rowDatas;                    // 현재 선택된 row 데이터                                                  
  let gridApi;                     // AG Grid API 인스턴스                                                    
  const urlParams;                 // URL 쿼리 파라미터                                                       
  const initialEventType;          // URL의 eventType 파라미터                                                
                                                                                                              
  주요 함수 (16개)                                                                                            
  ┌───────────────────────────────────────────────┬─────────┬──────────────────────────────────────┐          
  │                    함수명                     │  라인   │                 역할                 │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ PageConfig.init()                             │ 14-39   │ HTML 요소에서 설정/메시지 로드       │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ PageConfig.get()                              │ 41-44   │ 설정값 조회                          │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ PageConfig.msg()                              │ 46-49   │ 메시지 조회                          │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ initEventGrid()                               │ 54-149  │ AG Grid 초기화, 무한 스크롤 설정     │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ getStatusBadge()                              │ 151-159 │ 상태별 배지 HTML 생성                │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ eventListColumn()                             │ 161-381 │ 컬럼 정의 배열 반환 (11개 컬럼)      │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ openEventDetailSidebar()                      │ 383-440 │ 사이드바 열기, 이벤트 상세 정보 표시 │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ loadComprehensiveJudgmentSupportInformation() │ 443-493 │ 관련 이벤트 조회                     │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ displayRelatedEvents()                        │ 496-599 │ 관련 이벤트를 Accordion으로 표시     │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ loadMoreRelatedEvents()                       │ 601-659 │ 더보기 클릭 시 추가 이벤트 로드      │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ saveAction()                                  │ 662-721 │ 조치사항 저장                        │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ loadAnalysisHistory()                         │ 724-746 │ 분석 기록 로드                       │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ saveAnalysisHistory()                         │ 749-795 │ 분석 기록 저장                       │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ optimizedDecodeDetail()                       │ 797-804 │ detail JSON 캐시된 디코딩            │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ safeDecode()                                  │ 806-817 │ Base64 안전 디코딩 (캐시 활용)       │          
  ├───────────────────────────────────────────────┼─────────┼──────────────────────────────────────┤          
  │ decodeDetailJson()                            │ 819-862 │ detail JSON 구조 디코딩              │          
  └───────────────────────────────────────────────┴─────────┴──────────────────────────────────────┘          
  AG Grid 설정                                                                                                
                                                                                                              
  const gridOptions = {                                                                                       
      columnDefs: eventListColumn(),                                                                          
      rowModelType: 'infinite',                // 무한 스크롤                                                 
      datasource: dataSource,                                                                                 
      styleNonce: <CSP nonce>,                                                                                
      cacheBlockSize: 100,                     // 블록 크기                                                   
      maxConcurrentDatasourceRequests: 1,      // 동시 요청 제한                                              
      infiniteInitialRowCount: 100,            // 초기 행 수                                                  
      cacheOverflowSize: 2,                    // 캐시 오버플로우                                             
      maxBlocksInCache: 10,                    // 최대 캐시 블록                                              
      animateRows: false,                      // 애니메이션 비활성                                           
      enableCellChangeFlash: false,                                                                           
      suppressLoadingOverlay: true,                                                                           
      rowBuffer: 5,                                                                                           
      defaultColDef: {                                                                                        
          sortable: false,                                                                                    
          filter: true,                                                                                       
          resizable: true                                                                                     
      }                                                                                                       
  };                                                                                                          
                                                                                                              
  컬럼 정의 (11개)                                                                                            
  ┌─────────────┬────────────┬──────┬──────┬────────────────────────┐                                         
  │   컬럼명    │    필드    │ 고정 │ 필터 │          특징          │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ No          │ id         │ left │ -    │ 역순 번호              │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ 호기        │ zone3      │ left │ Set  │ sp_03→3호기 변환       │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ 상태        │ status     │ left │ Set  │ 배지 렌더링            │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ 탐지일시    │ detectedAt │ -    │ Text │ dayjs 포맷             │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ 이벤트 유형 │ eventType  │ -    │ Set  │ 운전정보/네트워크/자산 │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ 이벤트명    │ eventName  │ -    │ Text │ -                      │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ 출발지 IP   │ srcIp      │ -    │ Text │ 마스킹 + 캐시          │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ 목적지 IP   │ dstIp      │ -    │ Text │ 마스킹                 │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ 목적지 포트 │ dstPort    │ -    │ Text │ -                      │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ 프로토콜    │ protocol   │ -    │ Set  │ 동적 API 로드          │                                         
  ├─────────────┼────────────┼──────┼──────┼────────────────────────┤                                         
  │ 조치        │ status     │ -    │ -    │ VIOLATION일 때만 버튼  │                                         
  └─────────────┴────────────┴──────┴──────┴────────────────────────┘                                         
  API 호출 함수                                                                                               
  API 엔드포인트: /detection/timesData/infinite                                                               
  메서드: GET                                                                                                 
  함수명: getRows()                                                                                           
  목적: 무한 스크롤 데이터                                                                                    
  ────────────────────────────────────────                                                                    
  API 엔드포인트: /detection/timesData/unique-protocols                                                       
  메서드: GET                                                                                                 
  함수명: eventListColumn()                                                                                   
  목적: 프로토콜 목록                                                                                         
  ────────────────────────────────────────                                                                    
  API 엔드포인트: /detection/related-events                                                                   
  메서드: GET                                                                                                 
  함수명: loadComprehensiveJudgmentSupportInformation()                                                       
  목적: 관련 이벤트                                                                                           
  ────────────────────────────────────────                                                                    
  API 엔드포인트: /detection/related-events/more                                                              
  메서드: GET                                                                                                 
  함수명: loadMoreRelatedEvents()                                                                             
  목적: 더보기                                                                                                
  ────────────────────────────────────────                                                                    
  API 엔드포인트: /detection/connection/save-action                                                           
  메서드: POST                                                                                                
  함수명: saveAction()                                                                                        
  목적: 조치 저장                                                                                             
  ────────────────────────────────────────                                                                    
  API 엔드포인트: /detection/connection/get-analysisHistory                                                   
  메서드: GET                                                                                                 
  함수명: loadAnalysisHistory()                                                                               
  목적: 분석 기록 조회                                                                                        
  ────────────────────────────────────────                                                                    
  API 엔드포인트: /detection/connection/save-analysisHistory                                                  
  메서드: POST                                                                                                
  함수명: saveAnalysisHistory()                                                                               
  목적: 분석 기록 저장                                                                                        
  이벤트 핸들러                                                                                               
  ┌─────────────────────┬───────────────────────┬───────────────────┐                                         
  │       이벤트        │         요소          │       함수        │                                         
  ├─────────────────────┼───────────────────────┼───────────────────┤                                         
  │ change              │ #darkModeToggle       │ AG Grid 테마 변경 │                                         
  ├─────────────────────┼───────────────────────┼───────────────────┤                                         
  │ hidden.bs.offcanvas │ #eventDetailSidebar   │ 사이드바 초기화   │                                         
  ├─────────────────────┼───────────────────────┼───────────────────┤                                         
  │ click               │ .btn-load-more-events │ 더보기 로드       │                                         
  ├─────────────────────┼───────────────────────┼───────────────────┤                                         
  │ shown.bs.tab        │ #whitelist_tab_2_tab  │ 관련 이벤트 로드  │                                         
  ├─────────────────────┼───────────────────────┼───────────────────┤                                         
  │ click               │ #btnSaveAction        │ 조치 저장         │                                         
  ├─────────────────────┼───────────────────────┼───────────────────┤                                         
  │ click               │ #btnSaveAnalysis      │ 분석 기록 저장    │                                         
  ├─────────────────────┼───────────────────────┼───────────────────┤                                         
  │ onRowClicked        │ AG Grid row           │ 사이드바 열기     │                                         
  └─────────────────────┴───────────────────────┴───────────────────┘                                         
  ---                                                                                                         
  Offcanvas 사이드바 구조                                                                                     
                                                                                                              
  탭 구성                                                                                                     
  ┌────────────────┬───────────────────────┬───────────┬──────────────────────────────┐                       
  │       탭       │       Fragment        │ 로드 방식 │             기능             │                       
  ├────────────────┼───────────────────────┼───────────┼──────────────────────────────┤                       
  │ 탭 1: 개요     │ overviewTab.html      │ 정적      │ 이벤트 상세 정보             │                       
  ├────────────────┼───────────────────────┼───────────┼──────────────────────────────┤                       
  │ 탭 2: 종합판단 │ relatedEventsTab.html │ AJAX 동적 │ 관련 이벤트 Accordion        │                       
  ├────────────────┼───────────────────────┼───────────┼──────────────────────────────┤                       
  │ 탭 3: 대응조치 │ actionTab.html        │ 정적      │ 조치 저장 (VIOLATION일 때만) │                       
  ├────────────────┼───────────────────────┼───────────┼──────────────────────────────┤                       
  │ 탭 4: 분석기록 │ analysisTab.html      │ AJAX 동적 │ 분석 기록 저장/조회          │                       
  └────────────────┴───────────────────────┴───────────┴──────────────────────────────┘                       
  탭 표시/숨기기 로직                                                                                         
                                                                                                              
  // 상태에 따라 조치 탭 표시/숨기기                                                                          
  if (rowData.status === 'IGNORE' || rowData.status === 'ACTIONED') {                                         
      $('#whitelist_tab_3_tab').parent().hide();  // 조치 탭 숨김                                             
  } else {                                                                                                    
      $('#whitelist_tab_3_tab').parent().show();  // 조치 탭 표시                                             
  }                                                                                                           
                                                                                                              
  ---                                                                                                         
  데이터 흐름                                                                                                 
                                                                                                              
  [세션] startDateTime, endDateTime, selectedZoneCode                                                         
           ↓                                                                                                  
  [Controller] timesData() - 라인 720-856                                                                     
           ↓ 날짜 변환 + 유형별 카운트 조회                                                                   
  [Service] getEventCountsByAllTypesFiltered() - 라인 861                                                     
           ↓                                                                                                  
  [Frontend] timesData.html 렌더링                                                                            
           ↓                                                                                                  
  [AG Grid] initEventGrid() - 무한 스크롤 초기화                                                              
           ↓                                                                                                  
  [AJAX] /detection/timesData/infinite                                                                        
           ↓                                                                                                  
  [Service] getAllEventsOptimized() - 라인 2944                                                               
           ↓ 필터링 + 그룹핑 + Base64 인코딩                                                                  
  [Repository] findActiveEventsByDateRangeAndZonePaged()                                                      
           ↓                                                                                                  
  [Frontend] AG Grid 렌더링 (캐시된 디코딩/마스킹)                                                            
           ↓                                                                                                  
  [사이드바] 상세보기 + 조치/분석 기록                                                                        
                                                                                                              
  ---                                                                                                         
  상태(Status) 정의                                                                                           
  ┌───────────┬──────────┬─────────────────────┬────────────────────────────────┬─────────┐                   
  │   상태    │  한글명  │      뱃지 색상      │              조건              │ 조치 탭 │                   
  ├───────────┼──────────┼─────────────────────┼────────────────────────────────┼─────────┤                   
  │ VIOLATION │ 조치대상 │ bg-danger (빨강)    │ isIgnore=false, isAction=false │ ✅ 표시 │                   
  ├───────────┼──────────┼─────────────────────┼────────────────────────────────┼─────────┤                   
  │ PENDING   │ 대기     │ bg-warning (노랑)   │ 대기 중                        │ ✅ 표시 │                   
  ├───────────┼──────────┼─────────────────────┼────────────────────────────────┼─────────┤                   
  │ ACTIONED  │ 조치완료 │ bg-success (초록)   │ isAction=true                  │ ❌ 숨김 │                   
  ├───────────┼──────────┼─────────────────────┼────────────────────────────────┼─────────┤                   
  │ IGNORE    │ 무시     │ bg-secondary (회색) │ isIgnore=true                  │ ❌ 숨김 │                   
  └───────────┴──────────┴─────────────────────┴────────────────────────────────┴─────────┘                   
  ---                                                                                                         
  이벤트 유형(EventType) 정의                                                                                 
  ┌────────────┬──────────┬────────────────────────┬─────────────────┐                                        
  │    유형    │  한글명  │          설명          │      탭 ID      │                                        
  ├────────────┼──────────┼────────────────────────┼─────────────────┤                                        
  │ connection │ 네트워크 │ 화이트리스트 위반 등   │ #connection-tab │                                        
  ├────────────┼──────────┼────────────────────────┼─────────────────┤                                        
  │ asset      │ 자산     │ 자산 변경, 미등록 자산 │ #asset-tab      │                                        
  ├────────────┼──────────┼────────────────────────┼─────────────────┤                                        
  │ operation  │ 운전정보 │ 운전 데이터 이상 탐지  │ #operation-tab  │                                        
  └────────────┴──────────┴────────────────────────┴─────────────────┘                                        
  ---                                                                                                         
  보안 처리                                                                                                   
                                                                                                              
  권한 기반 마스킹 (DataMaskingUtils)                                                                         
                                                                                                              
  // data_masking.js                                                                                          
  isReadOnlyUser: function () {                                                                               
      const permissions = window.APP_CONFIG.userPermissions || {};                                            
      if (permissions.isAdmin) return false;                                                                  
      if (permissions.canWrite || permissions.canDelete) return false;                                        
      return true;  // READ 전용: 마스킹 적용                                                                 
  }                                                                                                           
  ┌─────────────────────┬──────────────────────────┐                                                          
  │        권한         │       IP/MAC 표시        │                                                          
  ├─────────────────────┼──────────────────────────┤                                                          
  │ 관리자/WRITE/DELETE │ 원본 표시                │                                                          
  ├─────────────────────┼──────────────────────────┤                                                          
  │ READ 전용           │ 마스킹 (192.168.***.***) │                                                          
  └─────────────────────┴──────────────────────────┘                                                          
  Base64 인코딩/디코딩                                                                                        
                                                                                                              
  서버 → 클라이언트 (디코딩):                                                                                 
  // getRows() 내                                                                                             
  srcIp: safeDecode(item.srcIp),                                                                              
  dstIp: safeDecode(item.dstIp),                                                                              
  srcMac: safeDecode(item.srcMac),                                                                            
  dstMac: safeDecode(item.dstMac)                                                                             
                                                                                                              
  클라이언트 → 서버 (인코딩):                                                                                 
  // saveAction(), loadComprehensiveJudgmentSupportInformation() 내                                           
  srcIp: btoa(rowDatas.srcIp),                                                                                
  dstIp: btoa(rowDatas.dstIp)                                                                                 
                                                                                                              
  CSRF 토큰                                                                                                   
                                                                                                              
  beforeSend: function(xhr) {                                                                                 
      const header = $("meta[name='_csrf_header']").attr("content");                                          
      const token = $("meta[name='_csrf']").attr("content");                                                  
      xhr.setRequestHeader(header, token);                                                                    
  }                                                                                                           
                                                                                                              
  CSP Nonce                                                                                                   
                                                                                                              
  <script th:nonce="${nonce}"                                                                                 
          th:integrity="${sri.getHash('timesData.js')}"                                                       
          th:src="@{/js/page.detection/timesData.js}"></script>                                               
                                                                                                              
  // AG Grid 스타일 nonce                                                                                     
  styleNonce: document.querySelector('meta[name="csp-nonce"]')?.content                                       
                                                                                                              
  ---                                                                                                         
  캐싱 전략                                                                                                   
                                                                                                              
  프론트엔드 캐시 (3개)                                                                                       
                                                                                                              
  const maskingCache = new Map();  // IP 마스킹 결과 캐시                                                     
  const decodeCache = new Map();   // Base64 디코딩 결과 캐시                                                 
  const detailCache = new Map();   // detail JSON 디코딩 결과 캐시                                            
                                                                                                              
  백엔드 캐시                                                                                                 
                                                                                                              
  @Cacheable(value = "eventDefinitions", key = "'active_definitions'")                                        
  public Map<String, EventDefinition> getCachedEventDefinitions()                                             
                                                                                                              
  @Cacheable(value = "protocols", key = "'unique_protocols'")                                                 
  public List<String> getCachedUniqueProtocols()                                                              
                                                                                                              
  캐시 활용 패턴                                                                                              
                                                                                                              
  // 마스킹 캐시 사용 예시                                                                                    
  cellRenderer: function (params) {                                                                           
      let masked = maskingCache.get(params.value);                                                            
      if (!masked) {                                                                                          
          masked = DataMaskingUtils.maskSensitiveData(params.value);                                          
          maskingCache.set(params.value, masked);                                                             
      }                                                                                                       
      return `<span class="badge bg-info">${masked}</span>`;                                                  
  }                                                                                                           
                                                                                                              
  ---                                                                                                         
  성능 최적화                                                                                                 
  ┌─────────────────┬──────────────────────────────────────────┐                                              
  │      항목       │                구현 방식                 │                                              
  ├─────────────────┼──────────────────────────────────────────┤                                              
  │ AG Grid 모델    │ Infinite Row Model (무한 스크롤)         │                                              
  ├─────────────────┼──────────────────────────────────────────┤                                              
  │ 블록 크기       │ 100건 (cacheBlockSize: 100)              │                                              
  ├─────────────────┼──────────────────────────────────────────┤                                              
  │ 최대 캐시 블록  │ 10개 (maxBlocksInCache: 10)              │                                              
  ├─────────────────┼──────────────────────────────────────────┤                                              
  │ 동시 요청       │ 1개 (maxConcurrentDatasourceRequests: 1) │                                              
  ├─────────────────┼──────────────────────────────────────────┤                                              
  │ 애니메이션      │ 비활성화 (animateRows: false)            │                                              
  ├─────────────────┼──────────────────────────────────────────┤                                              
  │ 캐시 종류       │ 3개 (masking, decode, detail)            │                                              
  ├─────────────────┼──────────────────────────────────────────┤                                              
  │ EventDefinition │ 서버 캐싱 (@Cacheable)                   │                                              
  ├─────────────────┼──────────────────────────────────────────┤                                              
  │ 그룹핑          │ 2001 이벤트만 필터링 후 처리             │                                              
  └─────────────────┴──────────────────────────────────────────┘                                              
  ---                                                                                                         
  관련 문서                                                                                                   
                                                                                                              
  - detection-connection-system.md - connection 타입 상세                                                     
  - detection-timesereise-system.md - timeSereiseData 페이지                                                  
  - session-filtering.md - 날짜/호기 필터링 시스템                                                            
  - frontend-patterns.md - AG Grid, AJAX 패턴                                                                 
                                                                                                              
  ---                                                                                                         
  프로그램 명세서                                                                                             
                                                                                                              
  TSD_001 - 이상 이벤트 탐지 현황 페이지                                                                      
  ┌─────────────┬──────────────────────────┬────────────┬──────────────────────────────┐                      
  │ 프로그램 ID │         TSD_001          │ 프로그램명 │ 이상 이벤트 탐지 현황 페이지 │                      
  ├─────────────┼──────────────────────────┼────────────┼──────────────────────────────┤                      
  │ 분류        │ 이상탐지                 │ 처리유형   │ 화면                         │                      
  ├─────────────┼──────────────────────────┼────────────┼──────────────────────────────┤                      
  │ 클래스명    │ DetectionController.java │ 메서드명   │ timesData()                  │                      
  ├─────────────┼──────────────────────────┼────────────┼──────────────────────────────┤                      
  │ 라인        │ 720-856                  │ 메뉴 ID    │ 4060L                        │                      
  └─────────────┴──────────────────────────┴────────────┴──────────────────────────────┘                      
  ▣ 기능 설명                                                                                                 
                                                                                                              
  모든 이벤트 유형(네트워크/자산/운전정보)을 통합 조회하는 페이지를 렌더링한다. AG Grid 무한 스크롤로 대량    
  이벤트를 처리한다.                                                                                          
                                                                                                              
  ▣ 입력 항목 (Input)                                                                                         
  ┌─────┬──────────────┬──────────────┬────────────┬──────┬──────────────────────────────┐                    
  │ No  │ 항목명(물리) │ 항목명(논리) │ 데이터타입 │ 필수 │             설명             │                    
  ├─────┼──────────────┼──────────────┼────────────┼──────┼──────────────────────────────┤                    
  │ 1   │ eventType    │ 이벤트유형   │ String     │ N    │ URL 파라미터, 초기 필터 설정 │                    
  ├─────┼──────────────┼──────────────┼────────────┼──────┼──────────────────────────────┤                    
  │ -   │ -            │ -            │ -          │ -    │ 세션에서 날짜/호기 정보 사용 │                    
  └─────┴──────────────┴──────────────┴────────────┴──────┴──────────────────────────────┘                    
  ▣ 출력 항목 (Output)                                                                                        
  ┌─────┬──────────────────────┬──────────────────┬────────────┬──────┬─────────────────────┐                 
  │ No  │     항목명(물리)     │   항목명(논리)   │ 데이터타입 │ 필수 │        설명         │                 
  ├─────┼──────────────────────┼──────────────────┼────────────┼──────┼─────────────────────┤                 
  │ 1   │ grandTotalCount      │ 전체탐지수       │ Long       │ Y    │ 전체 이벤트 카운트  │                 
  ├─────┼──────────────────────┼──────────────────┼────────────┼──────┼─────────────────────┤                 
  │ 2   │ totalViolationCount  │ 조치대상수       │ Long       │ Y    │ 조치 필요 이벤트 수 │                 
  ├─────┼──────────────────────┼──────────────────┼────────────┼──────┼─────────────────────┤                 
  │ 3   │ totalActionedCount   │ 조치완료수       │ Long       │ Y    │ 조치 완료 이벤트 수 │                 
  ├─────┼──────────────────────┼──────────────────┼────────────┼──────┼─────────────────────┤                 
  │ 4   │ totalIgnoreCount     │ 무시수           │ Long       │ Y    │ 무시 처리 이벤트 수 │                 
  ├─────┼──────────────────────┼──────────────────┼────────────┼──────┼─────────────────────┤                 
  │ 5   │ connectionTotalCount │ 네트워크이벤트수 │ Long       │ Y    │ connection 타입 수  │                 
  ├─────┼──────────────────────┼──────────────────┼────────────┼──────┼─────────────────────┤                 
  │ 6   │ assetTotalCount      │ 자산이벤트수     │ Long       │ Y    │ asset 타입 수       │                 
  ├─────┼──────────────────────┼──────────────────┼────────────┼──────┼─────────────────────┤                 
  │ 7   │ operationTotalCount  │ 운전정보이벤트수 │ Long       │ Y    │ operation 타입 수   │                 
  ├─────┼──────────────────────┼──────────────────┼────────────┼──────┼─────────────────────┤                 
  │ 8   │ userInfo             │ 사용자정보       │ Map        │ Y    │ userId, userName    │                 
  └─────┴──────────────────────┴──────────────────┴────────────┴──────┴─────────────────────┘                 
  ▣ 처리 로직                                                                                                 
  ┌──────┬──────────────────────────────────────────────────────────┬────────────────────┐                    
  │ 순서 │                         처리내용                         │        비고        │                    
  ├──────┼──────────────────────────────────────────────────────────┼────────────────────┤                    
  │ 1    │ 권한 검사 (menuId: 4060L, READ)                          │ @RequirePermission │                    
  ├──────┼──────────────────────────────────────────────────────────┼────────────────────┤                    
  │ 2    │ 세션에서 startDateTime/endDateTime/zoneCode 조회         │                    │                    
  ├──────┼──────────────────────────────────────────────────────────┼────────────────────┤                    
  │ 3    │ 날짜 변환 (yyyy-MM-dd → LocalDateTime)                   │                    │                    
  ├──────┼──────────────────────────────────────────────────────────┼────────────────────┤                    
  │ 4    │ DetectionService.getEventCountsByAllTypesFiltered() 호출 │ 유형별 카운트      │                    
  ├──────┼──────────────────────────────────────────────────────────┼────────────────────┤                    
  │ 5    │ URL 파라미터 eventType으로 초기 필터 설정                │ 선택적             │                    
  ├──────┼──────────────────────────────────────────────────────────┼────────────────────┤                    
  │ 6    │ Model에 카운트/사용자 정보 추가                          │                    │                    
  ├──────┼──────────────────────────────────────────────────────────┼────────────────────┤                    
  │ 7    │ pages/detection/timesData 템플릿 반환                    │                    │                    
  └──────┴──────────────────────────────────────────────────────────┴────────────────────┘                    
  ---                                                                                                         
  TSD_002 - 이벤트 목록 무한 스크롤 조회                                                                      
  ┌─────────────┬──────────────────────────┬────────────┬──────────────────────────────┐                      
  │ 프로그램 ID │         TSD_002          │ 프로그램명 │ 이벤트 목록 무한 스크롤 조회 │                      
  ├─────────────┼──────────────────────────┼────────────┼──────────────────────────────┤                      
  │ 분류        │ 이상탐지                 │ 처리유형   │ 조회                         │                      
  ├─────────────┼──────────────────────────┼────────────┼──────────────────────────────┤                      
  │ 클래스명    │ DetectionController.java │ 메서드명   │ getTimesDataInfinite()       │                      
  ├─────────────┼──────────────────────────┼────────────┼──────────────────────────────┤                      
  │ 라인        │ 636-710                  │ 권한       │ - (페이지 접근 필요)         │                      
  └─────────────┴──────────────────────────┴────────────┴──────────────────────────────┘                      
  ▣ 기능 설명                                                                                                 
                                                                                                              
  AG Grid Infinite Row Model을 위한 이벤트 목록을 페이징 조회한다. 모든 이벤트                                
  유형(connection/asset/operation)을 통합 조회한다.                                                           
                                                                                                              
  ▣ 입력 항목 (Input)                                                                                         
  ┌─────┬──────────────┬──────────────┬────────────┬──────┬────────────────────┐                              
  │ No  │ 항목명(물리) │ 항목명(논리) │ 데이터타입 │ 필수 │        설명        │                              
  ├─────┼──────────────┼──────────────┼────────────┼──────┼────────────────────┤                              
  │ 1   │ startRow     │ 시작행       │ int        │ N    │ 기본값 0, @Min(0)  │                              
  ├─────┼──────────────┼──────────────┼────────────┼──────┼────────────────────┤                              
  │ 2   │ endRow       │ 종료행       │ int        │ N    │ 기본값 20, @Min(1) │                              
  ├─────┼──────────────┼──────────────┼────────────┼──────┼────────────────────┤                              
  │ 3   │ filterModel  │ 필터모델     │ String     │ N    │ AG Grid 필터 JSON  │                              
  └─────┴──────────────┴──────────────┴────────────┴──────┴────────────────────┘                              
  ▣ 출력 항목 (Output)                                                                                        
  ┌─────┬──────────────┬──────────────┬────────────────────────┬──────┬────────────────────────┐              
  │ No  │ 항목명(물리) │ 항목명(논리) │       데이터타입       │ 필수 │          설명          │              
  ├─────┼──────────────┼──────────────┼────────────────────────┼──────┼────────────────────────┤              
  │ 1   │ data         │ 이벤트목록   │ ListEventWithStatusDto │ Y    │ Base64 인코딩          │              
  ├─────┼──────────────┼──────────────┼────────────────────────┼──────┼────────────────────────┤              
  │ 2   │ totalCount   │ 전체건수     │ Long                   │ Y    │ 필터 적용 후 전체 건수 │              
  └─────┴──────────────┴──────────────┴────────────────────────┴──────┴────────────────────────┘              
  ▣ 처리 로직                                                                                                 
  ┌──────┬───────────────────────────────────────────────┬──────┐                                             
  │ 순서 │                   처리내용                    │ 비고 │                                             
  ├──────┼───────────────────────────────────────────────┼──────┤                                             
  │ 1    │ 세션에서 날짜/호기 정보 조회                  │      │                                             
  ├──────┼───────────────────────────────────────────────┼──────┤                                             
  │ 2    │ filterModel JSON 파싱                         │      │                                             
  ├──────┼───────────────────────────────────────────────┼──────┤                                             
  │ 3    │ eventType 필터 추출 (있으면 분기)             │      │                                             
  ├──────┼───────────────────────────────────────────────┼──────┤                                             
  │ 4    │ DetectionService.getAllEventsOptimized() 호출 │      │                                             
  ├──────┼───────────────────────────────────────────────┼──────┤                                             
  │ 5    │ IP/MAC Base64 인코딩                          │      │                                             
  ├──────┼───────────────────────────────────────────────┼──────┤                                             
  │ 6    │ { data, totalCount } 응답 반환                │      │                                             
  └──────┴───────────────────────────────────────────────┴──────┘                                             
  ---      