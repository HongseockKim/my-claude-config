# 화이트리스트 위반 현황 시스템

## 개요

| 항목 | 내용 |                                                                                             
  |------|------|                                                                                             
| **목적** | 화이트리스트 정책 위반 이벤트 탐지 및 조치 |                                                   
| **URL** | `/detection/connection` |                                                                       
| **권한** | menuId: 4020L (READ/WRITE) |                                                                   
| **레이아웃** | AG Grid 목록 + Offcanvas 상세 (4탭) |                                                      

### 핵심 특징

- **Server-Side Datasource**: AG Grid의 서버 사이드 무한 스크롤
- **이벤트 그룹핑**: srcIp + dstIp + dstPort + protocol + eventCode 조합으로 그룹화
- **상태 관리**: VIOLATION(위반), IGNORE(무시), ACTIONED(조치완료), PENDING(대기)
- **조치 기능**: 화이트리스트 등록 또는 무시 처리
- **분석 기록**: 이벤트별 분석 내역 저장
- **권한 기반 마스킹**: DataMaskingUtils로 READ 전용 사용자 IP/MAC 마스킹

  ---                                                                                                         

## 파일 구조

### 백엔드

| 파일 | 경로 | 줄수 |                                                                                      
  |------|------|------|                                                                                      
| DetectionController | `controller/DetectionController.java` | 1,419줄 |                                   
| DetectionService | `service/DetectionService.java` | 3,235줄 |                                            
| Event | `model/Event.java` | - |                                                                          
| EventActionLog | `model/EventActionLog.java` | - |                                                        
| AlarmAction | `model/AlarmAction.java` | - |                                                              
| WhitelistPolicy | `model/WhitelistPolicy.java` | - |                                                      
| ConnectionActionRequest | `dto/ConnectionActionRequest.java` | - |                                        
| AnalysisHistoryRequest | `dto/AnalysisHistoryRequest.java` | - |                                          
| EventCountDto | `dto/EventCountDto.java` | - |                                                            
| EventListResponseDto | `dto/EventListResponseDto.java` | - |                                              
| ConnectionExcelDto | `dto/ConnectionExcelDto.java` | - |                                                  

### 프론트엔드

| 파일 | 경로 | 줄수 |                                                                                      
  |------|------|------|                                                                                      
| 메인 페이지 | `templates/pages/detection/connection.html` | - |                                           
| Offcanvas | `templates/fragments/detection/eventDetailOffcanvas.html` | - |                               
| 개요 탭 | `templates/fragments/detection/tabs/overviewTab.html` | - |                                     
| 종합판단 탭 | `templates/fragments/detection/tabs/relatedEventsTab.html` | - |                            
| 대응조치 탭 | `templates/fragments/detection/tabs/actionTab.html` | - |                                   
| 분석기록 탭 | `templates/fragments/detection/tabs/analysisTab.html` | - |                                 
| JavaScript | `static/js/page.detection/connection.js` | 822줄 |                                           
| CSS | `static/css/pages/detection/connection.css` | - |                                                   
                                                                                                              
---                                                                                                         

## API 엔드포인트

### 페이지 및 데이터

| Method | Endpoint | 라인 | 권한 | 설명 |                                                                  
  |--------|----------|------|------|------|                                                                  
| GET | `/detection/connection` | 55-87 | READ | 페이지 렌더링 |                                            
| GET | `/detection/connection/data` | 113-153 | - | 이벤트 목록 (Server-Side) |                            
| POST | `/detection/connection/exportExcel` | 89-111 | WRITE | 엑셀 다운로드 |                             

### 관련 이벤트

| Method | Endpoint | 라인 | 설명 |                                                                         
  |--------|----------|------|------|                                                                         
| GET | `/detection/connection/related-events` | 155-188 | 관련 이벤트 JSON |                               
| GET | `/detection/connection/related-events-html` | 191-216 | 관련 이벤트 HTML Fragment |                 
| GET | `/detection/related-events` | - | 종합판단 지원정보 (공통) |                                        
| GET | `/detection/related-events/more` | - | 더보기 로드 |                                                

### 조치 및 분석

| Method | Endpoint | 라인 | 권한 | @ActivityLog | 설명 |                                                   
  |--------|----------|------|------|--------------|------|                                                   
| POST | `/detection/connection/save-action` | 378-461 | WRITE | ❌ | 조치 저장 |                           
| POST | `/detection/connection/save-analysisHistory` | 463-492 | WRITE | ✅ | 분석 기록 저장 |             
| GET | `/detection/connection/get-analysisHistory` | 605-634 | - | ❌ | 분석 기록 조회 |                   

### 테스트

| Method | Endpoint | 라인 | 설명 |                                                                         
  |--------|----------|------|------|                                                                         
| GET | `/detection/connection/whitelist-test` | 1176-1247 | 화이트리스트 매칭 테스트 |                     
                                                                                                              
---                                                                                                         

## 권한 및 마스킹 처리

### @RequirePermission 적용 현황

| 메서드 | 라인 | menuId | 권한 |                                                                           
  |--------|------|--------|------|                                                                           
| `connection()` | 55 | 4020 | READ |                                                                       
| `exportConnectionExcel()` | 89 | 4020 | WRITE |                                                           
| `saveConnectionAction()` | 378 | 4020 | WRITE |                                                           
| `saveAnalysisHistory()` | 463 | 4020 | WRITE |                                                            

**참고**: `getConnectionData()`, `getRelatedEvents()` 등은 `@RequirePermission` 없음
- 페이지 접근 자체가 READ 권한 필요
- DataMaskingUtils로 권한 기반 마스킹 처리됨

### DataMaskingUtils 권한 기반 마스킹

  ```javascript                                                                                               
  // data_masking.js                                                                                          
  isReadOnlyUser: function () {                                                                               
      const permissions = window.APP_CONFIG.userPermissions || {};                                            
      if (permissions.isAdmin) return false;           // 관리자: 마스킹 안함                                 
      if (permissions.canWrite || permissions.canDelete) return false;  // 쓰기/삭제 권한: 마스킹 안함        
      return true;  // READ 전용: 마스킹 적용                                                                 
  }                                                                                                           
  ┌─────────────────────┬──────────────────────────┬───────────────┐                                          
  │        권한         │       IP/MAC 표시        │ 엑셀 다운로드 │                                          
  ├─────────────────────┼──────────────────────────┼───────────────┤                                          
  │ 관리자/WRITE/DELETE │ 원본 표시                │ ✅ 가능       │                                          
  ├─────────────────────┼──────────────────────────┼───────────────┤                                          
  │ READ 전용           │ 마스킹 (192.168.***.***) │ ❌ 버튼 숨김  │                                          
  └─────────────────────┴──────────────────────────┴───────────────┘                                          
  ---                                                                                                         
  화이트리스트 위반 판정 로직                                                                                 
                                                                                                              
  판정 방식 (2가지)                                                                                           
                                                                                                              
  1. 기본 방식 (isViolation) - 정확하지만 느림                                                                
                                                                                                              
  private boolean isViolation(Event event, List<WhitelistPolicy> whitelistPolicies) {                         
      boolean isInWhitelist = whitelistPolicies.stream()                                                      
              .anyMatch(policy -> {                                                                           
                  boolean srcIpMatch = policy.getSrcIp().equals(event.getSrcIp());                            
                  boolean dstIpMatch = policy.getDstIp().equals(event.getDstIp());                            
                  boolean dstPortMatch = Objects.equals(policy.getDstPort(), event.getDstPort());             
                  boolean protocolMatch = policy.getProtocol().equalsIgnoreCase(event.getProtocol());         
                  return srcIpMatch && dstIpMatch && dstPortMatch && protocolMatch;                           
              });                                                                                             
      return !isInWhitelist;  // 화이트리스트에 없으면 위반                                                   
  }                                                                                                           
                                                                                                              
  2. 최적화 방식 (isViolationOptimized) - 캐시 사용                                                           
                                                                                                              
  @Cacheable(value = "whitelistPolicies", key = "'all'")                                                      
  public Map<String, WhitelistPolicy> getWhitelistPolicyMap() {                                               
      return policies.stream()                                                                                
              .collect(Collectors.toMap(                                                                      
                      policy -> generatePolicyKey(policy.getSrcIp(), policy.getDstIp(),                       
                                                 policy.getDstPort(), policy.getProtocol()),                  
                      policy -> policy                                                                        
              ));                                                                                             
  }                                                                                                           
                                                                                                              
  private boolean isViolationOptimized(Event event, Map<String, WhitelistPolicy> policyMap) {                 
      String eventKey = generatePolicyKey(event.getSrcIp(), event.getDstIp(),                                 
                                          event.getDstPort(), event.getProtocol());                           
      return !policyMap.containsKey(eventKey);  // O(1) 조회                                                  
  }                                                                                                           
                                                                                                              
  private String generatePolicyKey(String srcIp, String dstIp, Integer dstPort, String protocol) {            
      return srcIp + ":" + dstIp + ":" + dstPort + ":" + protocol;                                            
  }                                                                                                           
                                                                                                              
  판정 조건                                                                                                   
  ┌─────────────────────────────────────────┬──────────────────────┐                                          
  │                  조건                   │         결과         │                                          
  ├─────────────────────────────────────────┼──────────────────────┤                                          
  │ event_code = '2001' + 화이트리스트 없음 │ VIOLATION (위반)     │                                          
  ├─────────────────────────────────────────┼──────────────────────┤                                          
  │ event_code = '2001' + 화이트리스트 있음 │ WHITELISTED (필터됨) │                                          
  ├─────────────────────────────────────────┼──────────────────────┤                                          
  │ is_ignore = true                        │ IGNORE (무시)        │                                          
  ├─────────────────────────────────────────┼──────────────────────┤                                          
  │ is_action = true                        │ ACTIONED (조치완료)  │                                          
  └─────────────────────────────────────────┴──────────────────────┘                                          
  ---                                                                                                         
  데이터 흐름                                                                                                 
                                                                                                              
  목록 조회                                                                                                   
                                                                                                              
  사용자 접속 → /detection/connection                                                                         
    ↓                                                                                                         
  DetectionController.connection() [라인 55-87]                                                               
    ↓ 세션에서 startDateTime, endDateTime, selectedZoneCode 추출                                              
  DetectionService.getEventCountFiltered("connection", ...)                                                   
    ↓ 상태별 카운트 조회 (violationCount, ignoreCount, totalCount)                                            
  connection.html 렌더링                                                                                      
    ↓                                                                                                         
  AG Grid 초기화 → /detection/connection/data                                                                 
    ↓ Server-Side 무한 스크롤 (startRow, endRow)                                                              
  DetectionService.getEventsPagedFiltered(...)                                                                
    ↓ 화이트리스트 위반 필터링 (isViolationOptimized)                                                         
    ↓ 그룹핑 (srcIp+dstIp+dstPort+protocol+eventCode)                                                         
    ↓ IP/MAC Base64 인코딩                                                                                    
  JSON Response → AG Grid 렌더링                                                                              
                                                                                                              
  상세 조회 (Offcanvas)                                                                                       
                                                                                                              
  Row 클릭 → openEventDetailSidebar(rowData)                                                                  
    ↓                                                                                                         
  Offcanvas 열림 (4개 탭)                                                                                     
    ├── Tab 1: 개요 - 이벤트 기본 정보 (DataMaskingUtils 마스킹)                                              
    ├── Tab 2: 종합판단 - loadComprehensiveJudgmentSupportInformation()                                       
    │           ↓ /detection/related-events (AJAX)                                                            
    │           JSON 응답 → displayRelatedEvents() → Accordion 동적 생성                                      
    ├── Tab 3: 대응조치 - saveAction()                                                                        
    │           ↓ /detection/connection/save-action (POST)                                                    
    │           화이트리스트 등록 또는 무시 처리                                                              
    └── Tab 4: 분석기록 - loadAnalysisHistory() / saveAnalysisHistory()                                       
                ↓ /detection/connection/get-analysisHistory                                                   
                ↓ /detection/connection/save-analysisHistory                                                  
                                                                                                              
  조치 처리 흐름                                                                                              
                                                                                                              
  조치 저장 요청 (actionType: "add" 또는 "ignore")                                                            
    ↓                                                                                                         
  DetectionController.saveConnectionAction() [라인 378-461]                                                   
    ↓ IP Base64 디코딩 (ValidationUtils.safeBase64DecodeOrNull)                                               
  DetectionService.saveEventActionLog()                                                                       
    ↓ EventActionLog 저장                                                                                     
    ↓                                                                                                         
  actionType == "add"                                                                                         
    ├── DetectionService.addToWhitelistFromAction()                                                           
    │     ↓ 동일 srcIp + dstIp 이벤트 조회                                                                    
    │     ↓ protocol + port 조합별 화이트리스트 생성                                                          
    │     ↓ 관련 이벤트 isAction = true 업데이트                                                              
    │     ↓ WhitelistPolicy 저장                                                                              
    │     ↓ @CacheEvict("whitelistPolicies") 캐시 무효화                                                      
    └── 결과: "화이트리스트에 추가되었습니다"                                                                 
    ↓                                                                                                         
  actionType == "ignore"                                                                                      
    ├── DetectionService.processIgnoreAction()                                                                
    │     ↓ 관련 이벤트 isIgnore = true 업데이트                                                              
    └── 결과: "무시 처리되었습니다"                                                                           
                                                                                                              
  ---                                                                                                         
  JavaScript 구조 (connection.js)                                                                             
                                                                                                              
  전역 변수                                                                                                   
  ┌────────────┬────────┬───────────────────────┐                                                             
  │   변수명   │  타입  │         용도          │                                                             
  ├────────────┼────────┼───────────────────────┤                                                             
  │ PageConfig │ Object │ 모듈 패턴 설정 객체   │                                                             
  ├────────────┼────────┼───────────────────────┤                                                             
  │ rowDatas   │ Object │ 현재 선택된 행 데이터 │                                                             
  ├────────────┼────────┼───────────────────────┤                                                             
  │ gridApi    │ Object │ AG Grid API 참조      │                                                             
  └────────────┴────────┴───────────────────────┘                                                             
  주요 함수 (14개)                                                                                            
  ┌───────────────────────────────────────────────┬─────────┬───────────────────────┐                         
  │                    함수명                     │  라인   │         용도          │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ PageConfig.init()                             │ -       │ 설정/메시지 초기화    │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ PageConfig.get()                              │ -       │ 설정값 조회           │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ PageConfig.msg()                              │ -       │ 메시지 텍스트 조회    │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ initAssetGrid()                               │ 54-86   │ AG Grid 초기화        │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ createServerSideDatasource()                  │ 420-475 │ 서버사이드 데이터소스 │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ whiteListColum()                              │ 558-671 │ 컬럼 정의 (13개)      │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ openEventDetailSidebar()                      │ 477-556 │ Offcanvas 열기        │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ loadComprehensiveJudgmentSupportInformation() │ 88-134  │ 관련 이벤트 조회      │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ displayRelatedEvents()                        │ 135-234 │ Accordion 렌더링      │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ loadMoreRelatedEvents()                       │ 236-295 │ 더보기 로드           │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ saveAction()                                  │ 297-390 │ 조치 저장             │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ loadAnalysisHistory()                         │ 392-418 │ 분석 기록 조회        │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ saveAnalysisHistory()                         │ -       │ 분석 기록 저장        │                         
  ├───────────────────────────────────────────────┼─────────┼───────────────────────┤                         
  │ decodeDetailJson()                            │ 674-712 │ 상세 JSON 디코딩      │                         
  └───────────────────────────────────────────────┴─────────┴───────────────────────┘                         
  AG Grid 설정                                                                                                
                                                                                                              
  const gridOptions = {                                                                                       
      columnDefs: whiteListColum(),              // 13개 컬럼                                                 
      rowModelType: 'serverSide',                // 서버사이드 모델                                           
      serverSideDatasource: createServerSideDatasource(),                                                     
      pagination: false,                         // 무한 스크롤                                               
      paginationPageSize: 20,                                                                                 
      styleNonce: document.querySelector('meta[name="csp-nonce"]')?.content,                                  
      defaultColDef: {                                                                                        
          sortable: true,                                                                                     
          filter: true,                                                                                       
          resizable: true                                                                                     
      }                                                                                                       
  };                                                                                                          
                                                                                                              
  컬럼 정의 (13개)                                                                                            
  ┌────────────┬─────────────┬──────┬─────────────────────────┐                                               
  │    필드    │    헤더     │ 고정 │         렌더러          │                                               
  ├────────────┼─────────────┼──────┼─────────────────────────┤                                               
  │ status     │ 상태        │ left │ 배지 (VIOLATION/IGNORE) │                                               
  ├────────────┼─────────────┼──────┼─────────────────────────┤                                               
  │ rowNum     │ No          │ left │ 역순 번호               │                                               
  ├────────────┼─────────────┼──────┼─────────────────────────┤                                               
  │ detectedAt │ 탐지일시    │ left │ dayjs 포맷              │                                               
  ├────────────┼─────────────┼──────┼─────────────────────────┤                                               
  │ eventCount │ 그룹 카운트 │ left │ 배지                    │                                               
  ├────────────┼─────────────┼──────┼─────────────────────────┤                                               
  │ srcIp      │ 출발지 IP   │ left │ DataMaskingUtils 마스킹 │                                               
  ├────────────┼─────────────┼──────┼─────────────────────────┤                                               
  │ dstIp      │ 목적지 IP   │ left │ DataMaskingUtils 마스킹 │                                               
  ├────────────┼─────────────┼──────┼─────────────────────────┤                                               
  │ dstPort    │ 목적지 Port │ left │ -                       │                                               
  ├────────────┼─────────────┼──────┼─────────────────────────┤                                               
  │ protocol   │ 프로토콜    │ left │ 배지                    │                                               
  ├────────────┼─────────────┼──────┼─────────────────────────┤                                               
  │ actionBtn  │ 조치 등록   │ left │ 권한별 버튼             │                                               
  └────────────┴─────────────┴──────┴─────────────────────────┘                                               
  ---                                                                                                         
  Base64 인코딩/디코딩                                                                                        
                                                                                                              
  서버 → 클라이언트 (디코딩)                                                                                  
                                                                                                              
  // createServerSideDatasource() 내                                                                          
  const decodedData = response.data.map(function(item) {                                                      
      return {                                                                                                
          ...item,                                                                                            
          srcIp: item.srcIp ? atob(item.srcIp) : null,                                                        
          srcMac: item.srcMac ? atob(item.srcMac) : null,                                                     
          dstIp: item.dstIp ? atob(item.dstIp) : null,                                                        
          dstMac: item.dstMac ? atob(item.dstMac) : null                                                      
      };                                                                                                      
  });                                                                                                         
                                                                                                              
  클라이언트 → 서버 (인코딩)                                                                                  
                                                                                                              
  // saveAction() 내                                                                                          
  const actionData = {                                                                                        
      srcIp: srcIp ? btoa(srcIp) : null,                                                                      
      dstIp: dstIp ? btoa(dstIp) : null                                                                       
  };                                                                                                          
                                                                                                              
  // loadComprehensiveJudgmentSupportInformation() 내                                                         
  srcIp: btoa(rowDatas.srcIp)                                                                                 
                                                                                                              
  상세 JSON 디코딩 (decodeDetailJson)                                                                         
                                                                                                              
  // event_info.data 배열 디코딩                                                                              
  // detected_sample 배열의 IP/MAC 필드 디코딩                                                                
                                                                                                              
  ---                                                                                                         
  Offcanvas 탭 구조                                                                                           
                                                                                                              
  Tab 1: 개요 (overviewTab)                                                                                   
  ┌────────────────┬───────────────────────┬─────────────────────────┐                                        
  │      항목      │          ID           │          설명           │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 이벤트 타입    │ #event_type           │ 네트워크/자산/운전정보  │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 이벤트명       │ #event_name           │ 이벤트 정의 이름        │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 이벤트 설명    │ #event_des            │ 상세 설명               │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 탐지 횟수      │ #event_count          │ 그룹 내 이벤트 수       │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 최종 탐지 시간 │ #final_detection_time │ 마지막 탐지 시각        │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 최초 탐지 시간 │ #first_detection_time │ 첫 탐지 시각            │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 출발지 IP      │ #event_ip             │ DataMaskingUtils 마스킹 │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 출발지 MAC     │ #event_mac            │ DataMaskingUtils 마스킹 │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 목적지 Port    │ #event_dsc_port       │ 포트 번호               │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 프로토콜       │ #event_protocol       │ TCP/UDP 등              │                                        
  ├────────────────┼───────────────────────┼─────────────────────────┤                                        
  │ 상세 정보      │ #event_detail         │ JSON 파싱된 상세        │                                        
  └────────────────┴───────────────────────┴─────────────────────────┘                                        
  Tab 2: 종합판단 지원정보 (relatedEventsTab)                                                                 
                                                                                                              
  - JavaScript에서 AJAX로 동적 HTML 삽입                                                                      
  - Accordion 형태로 eventType별 그룹화                                                                       
  - 더보기 버튼으로 추가 로드                                                                                 
                                                                                                              
  Tab 3: 대응 조치 (actionTab)                                                                                
  ┌─────────────┬────────────────┬────────────────────┬───────────────────┐                                   
  │    요소     │       ID       │        권한        │       설명        │                                   
  ├─────────────┼────────────────┼────────────────────┼───────────────────┤                                   
  │ 조치 라디오 │ #add           │ canWrite           │ 화이트리스트 등록 │                                   
  ├─────────────┼────────────────┼────────────────────┼───────────────────┤                                   
  │ 무시 라디오 │ #ignore        │ canDelete          │ 무시 처리         │                                   
  ├─────────────┼────────────────┼────────────────────┼───────────────────┤                                   
  │ 조치 사유   │ #action_story  │ -                  │ 텍스트 입력       │                                   
  ├─────────────┼────────────────┼────────────────────┼───────────────────┤                                   
  │ 저장 버튼   │ #btnSaveAction │ canWrite/canDelete │ saveAction() 호출 │                                   
  └─────────────┴────────────────┴────────────────────┴───────────────────┘                                   
  Tab 4: 분석 기록 (analysisTab)                                                                              
  ┌───────────┬───────────────────┬──────────┬────────────────────────────┐                                   
  │   요소    │        ID         │   권한   │            설명            │                                   
  ├───────────┼───────────────────┼──────────┼────────────────────────────┤                                   
  │ 분석 내용 │ #analysis_history │ -        │ textarea                   │                                   
  ├───────────┼───────────────────┼──────────┼────────────────────────────┤                                   
  │ 저장 버튼 │ #btnSaveAnalysis  │ canWrite │ saveAnalysisHistory() 호출 │                                   
  └───────────┴───────────────────┴──────────┴────────────────────────────┘                                   
  ---                                                                                                         
  보안 처리                                                                                                   
                                                                                                              
  CSP Nonce                                                                                                   
                                                                                                              
  <script th:integrity="${sri.getHash('connection_js')}"                                                      
          th:nonce="${nonce}"                                                                                 
          th:src="@{/js/page.detection/connection.js}"></script>                                              
                                                                                                              
  // AG Grid 동적 스타일용                                                                                    
  styleNonce: document.querySelector('meta[name="csp-nonce"]')?.content                                       
                                                                                                              
  CSRF 토큰                                                                                                   
                                                                                                              
  beforeSend: function (xhr) {                                                                                
      const header = $("meta[name='_csrf_header']").attr("content");                                          
      const token = $("meta[name='_csrf']").attr("content");                                                  
      xhr.setRequestHeader(header, token);                                                                    
  }                                                                                                           
                                                                                                              
  ---                                                                                                         
  캐싱                                                                                                        
                                                                                                              
  // 화이트리스트 정책 캐싱                                                                                   
  @Cacheable(value = "whitelistPolicies", key = "'all'")                                                      
  public Map<String, WhitelistPolicy> getWhitelistPolicyMap() { ... }                                         
                                                                                                              
  // 캐시 무효화 (등록/수정/삭제 시)                                                                          
  @CacheEvict(value = "whitelistPolicies", key = "'analysis_active'")                                         
  public WhiteListPolicyDto createWhitelist(...) { ... }                                                      
                                                                                                              
  ---                                                                                                         
  DTO 구조                                                                                                    
                                                                                                              
  ConnectionActionRequest (조치 요청)                                                                         
                                                                                                              
  public class ConnectionActionRequest {                                                                      
      @NotNull                                                                                                
      private Long eventId;           // 이벤트 ID                                                            
      @NotBlank                                                                                               
      private String eventCode;       // 이벤트 코드 (예: 2001)                                               
      @NotBlank                                                                                               
      private String actionType;      // "add" 또는 "ignore"                                                  
      private String actionStory;     // 조치 사유                                                            
      private String srcIp;           // 출발지 IP (Base64)                                                   
      private String dstIp;           // 목적지 IP (Base64)                                                   
      private String zone1;           // 구역 1                                                               
      private String zone2;           // 구역 2                                                               
      private String zone3;           // 구역 3 (호기)                                                        
  }                                                                                                           
                                                                                                              
  EventCountDto (카운트)                                                                                      
                                                                                                              
  public class EventCountDto {                                                                                
      private Long violationCount;    // 위반 건수                                                            
      private Long ignoreCount;       // 무시 건수                                                            
      private Long totalCount;        // 전체 건수                                                            
      private Long actionedCount;     // 조치 완료 건수                                                       
      private Long pendingCount;      // 미처리 건수                                                          
  }                                                                                                           
                                                                                                              
  EventWithStatusDto (이벤트 + 상태)                                                                          
                                                                                                              
  public class EventWithStatusDto {                                                                           
      private Long id;                                                                                        
      private LocalDateTime timestamp;                                                                        
      private String eventCode;                                                                               
      private String zone1, zone2, zone3;                                                                     
      private String srcIp;              // Base64 인코딩됨                                                   
      private String srcMac;             // Base64 인코딩됨                                                   
      private Integer srcPort;                                                                                
      private String dstIp;              // Base64 인코딩됨                                                   
      private String dstMac;             // Base64 인코딩됨                                                   
      private Integer dstPort;                                                                                
      private String protocol;                                                                                
      private String detail;             // JSON 형식                                                         
      private String status;             // VIOLATION, IGNORE, ACTIONED, PENDING                              
      private String eventName;                                                                               
      private String eventType;                                                                               
      private Integer eventCount;        // 그룹화된 이벤트 수량                                              
  }                                                                                                           
                                                                                                              
  ConnectionExcelDto (엑셀)                                                                                   
  ┌───────────────┬─────────────┬──────┐                                                                      
  │     필드      │    헤더     │ 순서 │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ detectionTime │ 탐지시간    │ 1    │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ eventName     │ 이벤트명    │ 2    │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ srcIp         │ 출발지 IP   │ 3    │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ dstIp         │ 목적지 IP   │ 4    │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ srcPort       │ 출발지 포트 │ 5    │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ dstPort       │ 목적지 포트 │ 6    │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ protocol      │ 프로토콜    │ 7    │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ zone3         │ 호기        │ 8    │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ alarmLevel    │ 알람레벨    │ 9    │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ status        │ 상태        │ 10   │                                                                      
  ├───────────────┼─────────────┼──────┤                                                                      
  │ eventCount    │ 이벤트 수   │ 11   │                                                                      
  └───────────────┴─────────────┴──────┘                                                                      
  ---                                                                                                         
  관련 테이블                                                                                                 
                                                                                                              
  Event                                                                                                       
  ┌─────────────┬─────────────┬──────────────────────────────────────────┐                                    
  │    컬럼     │    타입     │                   설명                   │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ id          │ BIGINT (PK) │ 이벤트 ID                                │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ event_code  │ VARCHAR     │ 이벤트 코드 (2001: 화이트리스트 위반)    │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ event_type  │ VARCHAR     │ 이벤트 타입 (connection/asset/operation) │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ src_ip      │ VARCHAR     │ 출발지 IP                                │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ dst_ip      │ VARCHAR     │ 목적지 IP                                │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ dst_port    │ INT         │ 목적지 포트                              │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ protocol    │ VARCHAR     │ 프로토콜                                 │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ is_action   │ BOOLEAN     │ 조치 여부                                │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ is_ignore   │ BOOLEAN     │ 무시 여부                                │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ detected_at │ DATETIME    │ 탐지 시각                                │                                    
  ├─────────────┼─────────────┼──────────────────────────────────────────┤                                    
  │ zone3       │ VARCHAR     │ 호기 코드                                │                                    
  └─────────────┴─────────────┴──────────────────────────────────────────┘                                    
  EventActionLog                                                                                              
  ┌──────────────┬─────────────┬────────────────────────┐                                                     
  │     컬럼     │    타입     │          설명          │                                                     
  ├──────────────┼─────────────┼────────────────────────┤                                                     
  │ id           │ BIGINT (PK) │ 로그 ID                │                                                     
  ├──────────────┼─────────────┼────────────────────────┤                                                     
  │ event_id     │ BIGINT      │ 이벤트 ID              │                                                     
  ├──────────────┼─────────────┼────────────────────────┤                                                     
  │ event_code   │ VARCHAR     │ 이벤트 코드            │                                                     
  ├──────────────┼─────────────┼────────────────────────┤                                                     
  │ action_type  │ VARCHAR     │ 조치 유형 (add/ignore) │                                                     
  ├──────────────┼─────────────┼────────────────────────┤                                                     
  │ action_user  │ VARCHAR     │ 조치자 ID              │                                                     
  ├──────────────┼─────────────┼────────────────────────┤                                                     
  │ action_story │ TEXT        │ 조치 사유              │                                                     
  ├──────────────┼─────────────┼────────────────────────┤                                                     
  │ src_ip       │ VARCHAR     │ 출발지 IP              │                                                     
  ├──────────────┼─────────────┼────────────────────────┤                                                     
  │ dst_ip       │ VARCHAR     │ 목적지 IP              │                                                     
  ├──────────────┼─────────────┼────────────────────────┤                                                     
  │ created_at   │ DATETIME    │ 생성 시각              │                                                     
  └──────────────┴─────────────┴────────────────────────┘                                                     
  AlarmAction (분석 기록)                                                                                     
  ┌───────────────────────┬─────────────┬─────────────┐                                                       
  │         컬럼          │    타입     │    설명     │                                                       
  ├───────────────────────┼─────────────┼─────────────┤                                                       
  │ id                    │ BIGINT (PK) │ 분석 ID     │                                                       
  ├───────────────────────┼─────────────┼─────────────┤                                                       
  │ event_id              │ BIGINT      │ 이벤트 ID   │                                                       
  ├───────────────────────┼─────────────┼─────────────┤                                                       
  │ event_code            │ VARCHAR     │ 이벤트 코드 │                                                       
  ├───────────────────────┼─────────────┼─────────────┤                                                       
  │ action_create_manager │ VARCHAR     │ 작성자 ID   │                                                       
  ├───────────────────────┼─────────────┼─────────────┤                                                       
  │ action_content        │ TEXT        │ 분석 내용   │                                                       
  ├───────────────────────┼─────────────┼─────────────┤                                                       
  │ created_at            │ DATETIME    │ 생성 시각   │                                                       
  └───────────────────────┴─────────────┴─────────────┘                                                       
  ---                                                                                                         
  관련 페이지                                                                                                 
  ┌────────────────────┬──────────────────────────────┬──────────────────┐                                    
  │       페이지       │             URL              │       설명       │                                    
  ├────────────────────┼──────────────────────────────┼──────────────────┤                                    
  │ 시계열 이상 이벤트 │ /detection/timeSereiseData   │ 10분 단위 집계   │                                    
  ├────────────────────┼──────────────────────────────┼──────────────────┤                                    
  │ 이상탐지 현황      │ /detection/timesData         │ 전체 이벤트 목록 │                                    
  ├────────────────────┼──────────────────────────────┼──────────────────┤                                    
  │ 분석 및 조치 이력  │ /detection/analysisAndAction │ 조치 이력 조회   │                                    
  ├────────────────────┼──────────────────────────────┼──────────────────┤                                    
  │ 화이트리스트 정책  │ /policy/whitelist            │ 정책 관리        │                                    
  └────────────────────┴──────────────────────────────┴──────────────────┘                                    
  ---                                                                                                         
  새 기능 추가 시                                                                                             
                                                                                                              
  새 조치 유형 추가                                                                                           
                                                                                                              
  1. actionType 추가: Controller의 save-action에서 새 분기 추가                                               
  2. Service 메서드: DetectionService에 처리 로직 구현                                                        
  3. UI 라디오 버튼: actionTab.html에 새 옵션 추가                                                            
                                                                                                              
  새 이벤트 타입 추가                                                                                         
                                                                                                              
  1. EventDefinition: 데이터베이스에 새 이벤트 정의 등록                                                      
  2. eventType 분기: Controller/Service에서 타입별 처리 추가                                                  
  3. 관련 이벤트 조회: findRelatedEventsByIp 쿼리 확장                                                        
                                                                                                              
  ---  