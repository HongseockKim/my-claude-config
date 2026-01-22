# OtoMON-K 아키텍처

> 삼천포발전소 산업용 모니터링 시스템 구조                                                                  
> 최종 업데이트: 2026-01-19
                                                                                                              
---                                                                                                         

## 1. 레이어 아키텍처

┌─────────────────────────────────────────────────────────────┐                                             
│                      PRESENTATION LAYER                      │                                            
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │                                             
│  │  Thymeleaf  │  │  AG Grid    │  │  WebSocket (STOMP)  │  │                                             
│  │  Templates  │  │  Enterprise │  │  Real-time Updates  │  │                                             
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │                                             
└─────────────────────────────────────────────────────────────┘                                             
│                                                                             
┌─────────────────────────────────────────────────────────────┐                                             
│                      CONTROLLER LAYER (25개)                 │                                            
│  AssetController, AlarmController, DashboardController ...   │                                            
│  @RequirePermission → 권한 체크                              │                                            
└─────────────────────────────────────────────────────────────┘                                             
│                                                                             
┌─────────────────────────────────────────────────────────────┐                                             
│                       SERVICE LAYER (37개)                   │                                            
│  AssetService, AlarmService, PermissionService ...          │                                             
│  @ActivityLog → 감사 로그                                    │                                            
└─────────────────────────────────────────────────────────────┘                                             
│                                                                             
┌─────────────────────────────────────────────────────────────┐                                             
│                     REPOSITORY LAYER (50개)                  │                                            
│  AssetRepository, AlarmRepository, UserRepository ...       │                                             
│  JPA + @Query (Native SQL)                                  │                                             
└─────────────────────────────────────────────────────────────┘                                             
│                                                                             
┌─────────────────────────────────────────────────────────────┐                                             
│                       DATA LAYER                             │                                            
│  ┌─────────────────────┐  ┌─────────────────────────────┐   │                                             
│  │     MariaDB         │  │       ClickHouse            │   │                                             
│  │   (메타데이터, JPA)   │  │   (시계열 데이터, JDBC)      │   │                                          
│  │   ~60개 Entity      │  │   ~9개 Entity               │   │                                             
│  └─────────────────────┘  └─────────────────────────────┘   │                                             
└─────────────────────────────────────────────────────────────┘
                                                                                                              
---                                                                                                         

## 2. 패키지 구조

src/main/java/com/otoones/otomon/                                                                           
├── controller/     # 25개 - HTTP 요청 처리                                                                 
├── service/        # 37개 - 비즈니스 로직                                                                  
├── repository/     # 50개 - 데이터 접근 (JPA)                                                              
├── model/          # 69개 - Entity 클래스                                                                  
├── dto/            # 108개 - Data Transfer Objects                                                         
├── config/         # 26개 - Spring 설정                                                                    
├── interceptor/    # 7개 - 요청 가로채기                                                                   
├── aspect/         # 22개 - AOP (감사 로그, 권한)                                                          
├── filter/         # 4개 - 보안 필터                                                                       
├── util/           # 27개 - 유틸리티                                                                       
└── annotation/     # 3개 - 커스텀 어노테이션
                                                                                                              
---                                                                                                         

## 3. Controller 목록 (25개)

### 3.1 @RestController (11개)

| Controller | URL Prefix | 역할 |                                                                          
  |------------|------------|------|                                                                          
| AlarmController | `/setting/alarm` | 알람 CRUD, 담당자 관리 |                                             
| AlarmNotificationController | `/alarm` | 미읽음 알람, 읽음 처리 |                                         
| AuthController | `/api/auth` | JWT 로그인 |                                                               
| DateRangeController | `/daterange` | 날짜 범위 선택 |                                                     
| OperationApiController | `/operation/api` | 외부 수집 서버용 API |                                        
| TopologyPhysicalController | `/topology-physical` | 물리 토폴로지 데이터 |                                
| WidgetController | `/widget` | 위젯 데이터 조회 |                                                         
| ZoneController | `/zone` | 호기 선택 |                                                                    

### 3.2 @Controller (14개)

| Controller | URL Prefix | 역할 |                                                                          
  |------------|------------|------|                                                                          
| HomeController | `/` | 메인/로그인 페이지 |                                                               
| DashboardController | `/dashboard` | 대시보드 |                                                           
| DashboardTemplateController | `/setting/dashboard` | 대시보드 템플릿 |                                    
| AssetController | `/asset` | 자산 관리 (1008줄) |                                                         
| DetectionController | `/detection` | 이상 탐지 (1418줄, 가장 복잡) |                                      
| AnalysisController | `/analysis` | 시계열 분석, 리포트 |                                                  
| PolicyController | `/policy` | 정책 관리 |                                                                
| DataController | `/data` | 세션/운전정보/시스템 리소스 |                                                  
| OperationController | `/operation` | 감사로그 조회 |                                                      
| SettingController | `/setting` | 시스템 설정 (@PreAuthorize ADMIN) |                                      
| UserController | `/user` | 사용자 관리 |                                                                  
| MenuController | `/menu` | 메뉴 관리 |                                                                    
| CodeController | `/code` | 코드 관리 |                                                                    
| NotificationController | `/notification` | 실시간 알림 |                                                  
| LangController | `/lang` | 언어 변경 |                                                                    
| CustomErrorController | `/error` | 에러 페이지 |                                                          

### 3.3 @ControllerAdvice (1개)

| Controller | 역할 |                                                                                       
  |------------|------|                                                                                       
| BaseController | 모든 컨트롤러에 accessibleMenuIds 자동 제공 |                                            
                                                                                                              
---                                                                                                         

## 4. Service 목록 (37개)

### 4.1 인증/사용자 관리

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| UserService | 사용자 인증, 계정 잠금, 비밀번호 | ❌ |                                                     
| UserNormalService | 일반 사용자 조회, Excel | ❌ |                                                        
| UserGroupService | 사용자 그룹, 권한 매핑 | ✅ |                                                          
| PermissionService | 권한 체크, 그룹 권한 | ❌ |                                                           

### 4.2 메뉴/설정

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| MenuService (Interface) | 메뉴 인터페이스 | - |                                                           
| MenuServiceImpl | 메뉴 CRUD | ✅ |                                                                        
| MenuCacheService | 메뉴 캐싱 | ❌ |                                                                       
| SystemConfigService | Zone/시스템 설정 | ❌ |                                                             

### 4.3 감사/로깅

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| AuditSettingService | 감사 설정 (그룹별) | ✅ |                                                           
| AuditLogDataService | 감사 로그 조회, Excel | ❌ |                                                        
| SystemActivityLogService | 감사 로그 저장 | ❌ |                                                          

### 4.4 알람/이벤트

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| AlarmService | 알람 설정 CRUD | ✅ |                                                                      
| AlarmEventService | 감사→알람 변환 | ❌ |                                                                 
| AlarmNotificationService | 알람 발송 (WebSocket) | ❌ |                                                   
| NotificationService | 실시간 공지 | ❌ |                                                                  

### 4.5 대시보드/위젯

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| DashboardService | 대시보드 데이터 | ❌ |                                                                 
| DashboardTemplateService | 템플릿 CRUD | ✅ |                                                             
| DashboardWidgetService | 위젯 표시/숨김 (캐싱) | ❌ |                                                     
| DashboardZoneInitService | 호기별 위젯 자동 생성 | ❌ |                                                   
| WidgetService | 위젯 데이터 계산 | ❌ |                                                                   

### 4.6 토폴로지

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| TopologyPhysicalService | 물리 토폴로지 조회 | ❌ |                                                       
| TopologyNetService | 망 등록/조회/삭제 | ❌ |                                                             
| TopologySwitchService | 스위치 CRUD | ✅ |                                                                
| TopologyDeviceService | 장비 토폴로지 | ❌ |                                                              

### 4.7 자산/트래픽

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| AssetService | 자산 CRUD | ✅ |                                                                           
| AssetRawService | 미등록 자산 | ❌ |                                                                      
| AssetTrafficService | 트래픽 분석 | ❌ |                                                                  

### 4.8 이상탐지/정책

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| DetectionService | 탐지 정책, 화이트리스트 | ✅ |                                                         
| CodeService | 코드 관리 | ✅ |                                                                            

### 4.9 운영 정보

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| OperationService | 알람 이력 조회 | ✅ |                                                                  
| OperationInfoService | 운전 정보, OpTag (캐싱) | ✅ |                                                     
| DataService | 노드/OpTag 시계열 | ❌ |                                                                    

### 4.10 보고서/데이터

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| ReportService | 리포트 CRUD | ❌ |                                                                        
| TimeSeriesService | 시계열 데이터 | ❌ |                                                                  

### 4.11 기타

| Service | 역할 | @ActivityLog |                                                                           
  |---------|------|--------------|                                                                           
| MessageService | 다국어 (i18n) | ❌ |                                                                     
| ClickHouseService | ClickHouse 조회 | ❌ |                                                                
| BatchRandomService | 테스트 데이터 생성 | ❌ |                                                            
                                                                                                              
---                                                                                                         

## 5. Config 클래스 (26개)

### 5.1 보안

| Config | 역할 |                                                                                           
  |--------|------|                                                                                           
| SecurityConfig | Spring Security (2개 FilterChain: API/Web) |                                             
| PasswordEncoderConfig | BCrypt 암호화 |                                                                   
| RateLimitConfig | Bucket4j + Caffeine 요청 제한 |                                                         
| SriProperties | SRI 해시 설정 |                                                                           

### 5.2 데이터베이스

| Config | 역할 |                                                                                           
  |--------|------|                                                                                           
| PrimaryDataSourceConfig | MariaDB 연결 |                                                                  
| ClickHouseConfig | ClickHouse 연결 (JdbcTemplate) |                                                       
| JpaConfig | JPA/Hibernate 설정 |                                                                          
| EntityConfig | Entity 패키지 스캔 |                                                                       

### 5.3 웹

| Config | 역할 |                                                                                           
  |--------|------|                                                                                           
| WebMvcConfig | MVC + 인터셉터 등록 |                                                                      
| WebSocketConfig | STOMP WebSocket |                                                                       
| WebServerFactoryConfig | Server 헤더 제거, X-Powered-By 비활성화 |                                        
| JacksonConfig | JSON 직렬화 (LocalDateTime) |                                                             
| MessageConfig | 다국어 |                                                                                  

### 5.4 ControllerAdvice

| Config | 역할 |                                                                                           
  |--------|------|                                                                                           
| GlobalControllerAdvice | 전역 예외 처리, 시스템 설정 주입 |                                               
| CspNonceAdvice | CSP Nonce 자동 주입 |                                                                    
| SriControllerAdvice | SRI 속성 주입 |                                                                     
| GlobalModelAttributes | 전역 Model 속성 |                                                                 

### 5.5 배치

| Config | 역할 |                                                                                           
  |--------|------|                                                                                           
| BatchSchedulerConfig | 1분마다 테스트 데이터 생성 |                                                       
| TimeSeriesBatchConfig | 시계열 배치 처리 |                                                                
| JobRepositoryConfig | Spring Batch 저장소 |                                                               

### 5.6 기타

| Config | 역할 |                                                                                           
  |--------|------|                                                                                           
| CacheConfig | Caffeine 캐시 (1시간, 1000개) |                                                             
| DataMaskinConfig | 데이터 마스킹 |                                                                        
| DataInitializer | 초기 데이터 (Admin/User/메뉴/그룹) |                                                    
                                                                                                              
---                                                                                                         

## 6. 요청 처리 흐름

[HTTP 요청]                                                                                                 
│                                                                                                       
▼                                                                                                       
┌─────────────────────────────────────────────────────────────┐                                             
│                    FILTER CHAIN (4개)                        │                                            
│  ┌─────────────────────────────────────────────────────┐    │                                             
│  │ 1. AllowedHostsFilter (HIGHEST) → 호스트 헤더 검증   │    │                                            
│  │ 2. ControlCharacterFilter (@Order 1) → 제어문자 제거 │    │                                            
│  │ 3. JsonSecurityFilter (@Order 2) → AJAX 요청 검증   │    │                                             
│  │ 4. CspNonceFilter → CSP 헤더 + Nonce 생성          │    │                                              
│  └─────────────────────────────────────────────────────┘    │                                             
└─────────────────────────────────────────────────────────────┘                                             
│                                                                                                       
▼                                                                                                       
┌─────────────────────────────────────────────────────────────┐                                             
│                 SPRING SECURITY FILTERS                      │                                            
│  ┌─────────────────────────────────────────────────────┐    │                                             
│  │ API 경로 (/api/**): JwtAuthenticationFilter        │    │                                              
│  │ Web 경로: UsernamePasswordAuthenticationFilter     │    │                                              
│  │ 권한 검증, CORS, CSRF                              │    │                                              
│  └─────────────────────────────────────────────────────┘    │                                             
└─────────────────────────────────────────────────────────────┘                                             
│                                                                                                       
▼                                                                                                       
┌─────────────────────────────────────────────────────────────┐                                             
│                 INTERCEPTOR CHAIN (7개)                      │                                            
│  ┌─────────────────────────────────────────────────────┐    │                                             
│  │ 1. RateLimitInterceptor (@Order 0) → 요청 제한      │    │                                             
│  │ 2. AjaxOnlyInterceptor → AJAX 전용 검사            │    │                                              
│  │ 3. PermissionInterceptor → 권한 정보 주입          │    │                                              
│  │ 4. ZoneInterceptor → 호기 세션 관리                │    │                                              
│  │ 5. DateRangeInterceptor → 날짜 범위 세션           │    │                                              
│  │ 6. RequestAttributesInterceptor → 요청 정보        │    │                                              
│  │ 7. WebSocketAuthInterceptor → WS 인증              │    │                                              
│  └─────────────────────────────────────────────────────┘    │                                             
└─────────────────────────────────────────────────────────────┘                                             
│                                                                                                       
▼                                                                                                       
[Controller] → @RequirePermission                                                                           
│                                                                                                       
▼                                                                                                       
[Service] → @ActivityLog                                                                                    
│                                                                                                       
▼                                                                                                       
[Repository] → JPA / JdbcTemplate                                                                           
│                                                                                                       
▼                                                                                                       
[Database] → MariaDB / ClickHouse
                                                                                                              
---                                                                                                         

## 7. Aspect (AOP) 구조 (22개)

### 7.1 핵심 Aspect (2개)

| Aspect | 역할 |                                                                                           
  |--------|------|                                                                                           
| ActivityLogAspect | @ActivityLog 처리, Before/After 캡처 |                                                
| PermissionCheckAspect | @RequirePermission 권한 검증 |                                                    

### 7.2 ActivityLog Extractor (20개)

도메인별 감사 로그 데이터 추출:

| Extractor | 도메인 |                                                                                      
  |-----------|--------|                                                                                      
| MenuActivityLogExtractor | 메뉴 CRUD |                                                                    
| UserActivityLogExtractor | 사용자 CRUD |                                                                  
| AssetActivityLogExtractor | 자산 CRUD |                                                                   
| CodeActivityLogExtractor | 코드 관리 |                                                                    
| AlarmActivityLogExtractor | 알람 설정 |                                                                   
| AlarmManagerActivityLogExtractor | 알람 담당자 |                                                          
| AlarmActionLogExtractor | 알람 조치 |                                                                     
| DetectionPolicyActivityLogExtractor | 탐지 정책 |                                                         
| WhiteListPolicyActivityLogExtractor | 화이트리스트 |                                                      
| ServicePortPolicyActivityLogExtractor | 서비스 포트 정책 |                                                
| SystemConfigActivityLogExtractor | 시스템 설정 |                                                          
| GroupActivityLogExtractor | 그룹 관리 |                                                                   
| UserGroupActivityLogExtractor | 사용자-그룹 |                                                             
| TemplateActivityLogExtractor | 대시보드 템플릿 |                                                          
| TopologySwitchExtractor | 토폴로지 스위치 |                                                               
| OpTagInfoActivityLogExtractor | 운전정보 태그 |                                                           
| EventDefinitionLogExtractor | 이벤트 정의 |                                                               
| EventActionLogExtractor | 이벤트 조치 |                                                                   
| AuditLogSettingExtractor | 감사 설정 |                                                                    
                                                                                                              
---                                                                                                         

## 8. Util 구조 (27개)

### 8.1 공통 유틸

| Util | 역할 |                                                                                             
  |------|------|                                                                                             
| ResultCode | 결과 코드 Enum (RES_OK=0, RES_ERROR=-1) |                                                    
| DateTimeUtil | LocalDateTime 변환/포맷팅 |                                                                
| Zone3Util | 호기 정규화 (sp_03, sp_04) |                                                                  
| MacAddressUtils | MAC 주소 추출/정규화 |                                                                  
| ClientIpUtil | X-Forwarded-For IP 추출 |                                                                  

### 8.2 Excel/Export

| Util | 역할 |                                                                                             
  |------|------|                                                                                             
| ExcelExportUtil | @ExcelColumn 기반 Excel 생성 |                                                          
| ExcelAnalyzer | Excel 파일 분석/검증 |                                                                    

### 8.3 검증/보안

| Util | 역할 |                                                                                             
  |------|------|                                                                                             
| ValidationUtils | IP/MAC/Zone3 검증, Base64 안전 디코딩 |                                                 
| ValidationMessageHolder | 검증 메시지 관리 |                                                              

### 8.4 암호화 (ARIA-256)

| Util | 역할 |                                                                                             
  |------|------|                                                                                             
| AriaUtil | ARIA-256 암호화/복호화 |                                                                       
| Aria256Coder | ARIA-256 코더 |                                                                            
| Aria | ARIA 알고리즘 코어 |                                                                               
| AriaConstants | ARIA 상수/테이블 |                                                                        
| AriaProvider | ARIA 보안 제공자 |                                                                         
| Pkcs5 | PKCS#5 패딩 |                                                                                     
| Buffer | 바이트 배열 처리 |                                                                               
| Base64Util | Base64 인코딩/디코딩 |                                                                       

### 8.5 기타

| Util | 역할 |                                                                                             
  |------|------|                                                                                             
| MenuUtil | i18n 메뉴 라벨 |                                                                               
| CustomFileLogger | 파일 기반 감사 로그 |                                                                  
| JsonMapConverter | JSON ↔ Map 변환 |                                                                      
| JsonAssetIpMacListTypeHandler | JPA TypeHandler |                                                         
                                                                                                              
---                                                                                                         

## 9. 커스텀 어노테이션 (3개)

| Annotation | Target | 역할 |                                                                              
  |------------|--------|------|                                                                              
| @ActivityLog | METHOD | 감사 로그 기록 |                                                                  
| @RequirePermission | METHOD | 권한 체크 |                                                                 
| @ExcelColumn | FIELD | Excel 컬럼 정의 |                                                                  
                                                                                                              
---                                                                                                         

## 10. 주요 패턴

### 10.1 권한 체크
  ```java                                                                                                     
  @RequirePermission(menuId = 2010L, resourceType = MENU, permissionType = READ)                              
  @GetMapping("/operation")                                                                                   
  public String operation() { ... }                                                                           
                                                                                                              
  10.2 감사 로그                                                                                              
                                                                                                              
  @ActivityLog(category = "ASSET", action = "UPDATE")                                                         
  public void updateAsset(AssetDto dto) { ... }                                                               
                                                                                                              
  10.3 응답 형식                                                                                              
                                                                                                              
  return Map.of("ret", 0, "message", "성공", "data", result);                                                 
                                                                                                              
  10.4 DI 패턴                                                                                                
                                                                                                              
  @RequiredArgsConstructor  // 권장                                                                           
  public class AssetService {                                                                                 
      private final AssetRepository assetRepository;                                                          
  }                                                                                                           
                                                                                                              
  ---                                                                                                         
  11. 보안 레이어                                                                                             
  ┌───────────────────────┬──────────────────────────────────────┬──────┐                                     
  │       보안 항목       │              구현 위치               │ 상태 │                                     
  ├───────────────────────┼──────────────────────────────────────┼──────┤                                     
  │ Host Header Injection │ AllowedHostsFilter                   │ ✅   │                                     
  ├───────────────────────┼──────────────────────────────────────┼──────┤                                     
  │ CSP (strict-dynamic)  │ CspNonceFilter + CspNonceAdvice      │ ✅   │                                     
  ├───────────────────────┼──────────────────────────────────────┼──────┤                                     
  │ SRI                   │ SriControllerAdvice + sri.properties │ ✅   │                                     
  ├───────────────────────┼──────────────────────────────────────┼──────┤                                     
  │ CORS                  │ SecurityConfig                       │ ✅   │                                     
  ├───────────────────────┼──────────────────────────────────────┼──────┤                                     
  │ Rate Limiting         │ RateLimitInterceptor                 │ ✅   │                                     
  ├───────────────────────┼──────────────────────────────────────┼──────┤                                     
  │ HSTS                  │ SecurityConfig (1년)                 │ ✅   │                                     
  ├───────────────────────┼──────────────────────────────────────┼──────┤                                     
  │ 제어문자 필터링       │ ControlCharacterFilter               │ ✅   │                                     
  ├───────────────────────┼──────────────────────────────────────┼──────┤                                     
  │ ARIA-256 암호화       │ AriaUtil                             │ ✅   │                                     
  ├───────────────────────┼──────────────────────────────────────┼──────┤                                     
  │ WebSocket 인증        │ WebSocketAuthInterceptor             │ ✅   │                                     
  └───────────────────────┴──────────────────────────────────────┴──────┘                                     
  ---                                                                                                         
  12. 참조 파일                                                                                               
  ┌─────────────┬───────────────────────────────────────────────┐                                             
  │    구분     │                     경로                      │                                             
  ├─────────────┼───────────────────────────────────────────────┤                                             
  │ Controller  │ src/main/java/com/otoones/otomon/controller/  │                                             
  ├─────────────┼───────────────────────────────────────────────┤                                             
  │ Service     │ src/main/java/com/otoones/otomon/service/     │                                             
  ├─────────────┼───────────────────────────────────────────────┤                                             
  │ Repository  │ src/main/java/com/otoones/otomon/repository/  │                                             
  ├─────────────┼───────────────────────────────────────────────┤                                             
  │ Config      │ src/main/java/com/otoones/otomon/config/      │                                             
  ├─────────────┼───────────────────────────────────────────────┤                                             
  │ Filter      │ src/main/java/com/otoones/otomon/filter/      │                                             
  ├─────────────┼───────────────────────────────────────────────┤                                             
  │ Interceptor │ src/main/java/com/otoones/otomon/interceptor/ │                                             
  ├─────────────┼───────────────────────────────────────────────┤                                             
  │ Aspect      │ src/main/java/com/otoones/otomon/aspect/      │                                             
  ├─────────────┼───────────────────────────────────────────────┤                                             
  │ Util        │ src/main/java/com/otoones/otomon/util/        │                                             
  ├─────────────┼───────────────────────────────────────────────┤                                             
  │ Annotation  │ src/main/java/com/otoones/otomon/annotation/  │                                             
  └─────────────┴───────────────────────────────────────────────┘                                             
  ---    