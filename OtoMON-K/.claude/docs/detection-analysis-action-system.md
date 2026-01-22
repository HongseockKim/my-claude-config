# 분석 및 조치 이력 (analysisAndAction) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/detection/analysisAndAction` |
| **메뉴 ID** | 4080L |
| **권한** | READ 권한 필요 |
| **한글명** | 분석 및 조치 이력 |
| **목적** | 이벤트에 대한 분석 기록과 조치 이력을 통합 조회 |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/DetectionController.java (1,400+ lines)
Service:    src/main/java/com/otoones/otomon/service/DetectionService.java (3,200+ lines)
Template:   src/main/resources/templates/pages/detection/analysisAndAction.html
JavaScript: src/main/resources/static/js/page.detection/analysisAndAction.js (293 lines)
CSS:        src/main/resources/static/css/pages/detection/analysisAndAction.css
DTO:        src/main/java/com/otoones/otomon/dto/AnalysisAndActionHistoryDto.java
            src/main/java/com/otoones/otomon/dto/AnalysisAndActionExcelDto.java
Repository: EventActionLogRepository, AlarmActionRepository
```

---

## 컨트롤러 (DetectionController.java)

### 페이지 렌더링 (`GET /detection/analysisAndAction`)

**위치**: `DetectionController.java:1111-1114`

**권한**:
```java
@RequirePermission(menuId = 4080L, resourceType = ResourceType.MENU, permissionType = PermissionType.READ)
```

단순 페이지 렌더링 (데이터는 AJAX로 별도 조회)

### 데이터 조회 API (`GET /detection/api/analysisAndAction`)

**위치**: `DetectionController.java:1136-1169`

**권한**: 4080L READ

**세션 파라미터**:
| 속성 | 설명 |
|------|------|
| startDateTime | 시작 날짜 |
| endDateTime | 종료 날짜 |
| selectedZoneCode | 호기 코드 |

**응답 형식**:
```json
{
  "ret": 0,
  "message": "조회 성공",
  "data": [
    {
      "id": 1,
      "historyType": "ACTION",
      "eventCode": "2001",
      "zone3": "sp_03",
      "actionUser": "admin",
      "content": "조치 내용",
      "actionType": "add",
      "srcIp": "base64encoded",
      "dstIp": "base64encoded",
      "createdAt": "2025-12-29T10:00:00"
    }
  ]
}
```

### 엑셀 다운로드 (`POST /detection/analysisAndAction/exportExcel`)

**위치**: `DetectionController.java:1116-1134`

**권한**: 4080L WRITE

**파일명**: `분석및조치이력_yyyyMMdd_HHmmss.xlsx`

---

## 서비스 (DetectionService.java)

### `getAnalysisAndActionHistory()` - 위치: 1076-1143줄

분석 및 조치 이력 통합 조회

```java
public List<AnalysisAndActionHistoryDto> getAnalysisAndActionHistory(
    String zone3,
    LocalDateTime startDate,
    LocalDateTime endDate
)
```

**처리 로직**:
1. **조치 이력 조회** (`EventActionLog`) - 라인 1079-1084
   - `eventActionLogRepository.findByZone3AndCreatedAtBetweenOrderByCreatedAtDesc()`
   - historyType: "ACTION"
   - 조치유형(actionType), 조치내용(actionStory) 포함

2. **분석 이력 조회** (`AlarmAction`) - 라인 1113
   - `alarmActionRepository.findByCreatedAtBetweenOrderByCreatedAtDesc()`
   - historyType: "ANALYSIS"
   - 분석내용(actionContent) 포함

3. **통합 및 정렬** - 라인 1138-1142
   - 두 이력을 합쳐서 createdAt 기준 내림차순 정렬
   - IP 정보 Base64 인코딩 (`toEncoded()`)

### `exportAnalysisAndActionToExcel()` - 위치: 264-295줄

엑셀 내보내기

```java
public ByteArrayOutputStream exportAnalysisAndActionToExcel(HttpSession session)
```

**처리 로직**:
1. 세션에서 zone3, startDateTime, endDateTime 추출
2. `getAnalysisAndActionHistory()` 호출
3. `convertToExcelDto()`로 변환
4. `ExcelExportUtil.exportToExcel()` 호출

### `convertToExcelDto()` - 위치: 2847-2863줄 (private)

DTO 변환 메서드

```java
private AnalysisAndActionExcelDto convertToExcelDto(AnalysisAndActionHistoryDto dto)
```

**변환 로직**:
- `Zone3Util.toDisplayText()` - 호기명 변환 ("sp_03" → "3호기")
- `decodeBase64()` - IP Base64 디코딩
- `getActionTypeText()` - 조치 유형 텍스트 변환 ("add" → "조치", "ignore" → "무시")

---

## DTO (AnalysisAndActionHistoryDto.java)

### 필드 구성

| 필드 | 타입 | 설명 |
|------|------|------|
| id | Long | 이력 ID |
| historyType | String | 유형 ("ACTION" 또는 "ANALYSIS") |
| eventId | Long | 이벤트 ID |
| eventCode | String | 이벤트 코드 |
| eventName | String | 이벤트명 |
| zone3 | String | 호기 코드 |
| actionUser | String | 작성자 |
| content | String | 내용 (조치내용/분석내용) |
| actionType | String | 조치유형 ("add"=화이트리스트 추가, "ignore"=무시) |
| srcIp | String | 출발지 IP (Base64 인코딩) |
| dstIp | String | 목적지 IP (Base64 인코딩) |
| srcPort | Integer | 출발지 포트 |
| dstPort | Integer | 목적지 포트 |
| protocol | String | 프로토콜 |
| createdAt | LocalDateTime | 기록일시 |

### 메서드

```java
public AnalysisAndActionHistoryDto toEncoded()
```
- srcIp, dstIp를 Base64 인코딩하여 새 DTO 반환

---

## DTO (AnalysisAndActionExcelDto.java)

엑셀 내보내기 전용 DTO

| 순서 | 헤더명 | 필드 | 너비 |
|------|--------|------|------|
| 1 | No | id | 8 |
| 2 | 호기 | zone3Name | 10 |
| 3 | 기록일시 | createdAt | 18 |
| 4 | 유형 | historyTypeText | 10 |
| 5 | 출발지IP | srcIp | 15 |
| 6 | 목적지IP | dstIp | 15 |
| 7 | 이벤트코드 | eventCode | 12 |
| 8 | 등록자 | actionUser | 12 |
| 9 | 조치유형 | actionTypeText | 15 |
| 10 | 내용 | content | 40 |

---

## 프론트엔드 (analysisAndAction.html)

### 페이지 구조

| 요소 | 설명 |
|------|------|
| 레이아웃 | `layouts/default` |
| Breadcrumb | 네비게이션 (18-24줄) |
| 메인 패널 | 31-134줄 |
| AG Grid | `#historyGrid` (40-42줄) |
| Offcanvas | `#detailSidebar` (44-133줄) |

### 보안 준수 사항

- ✅ `th:nonce="${nonce}"` 적용 (137-139줄)
- ✅ SRI 해시 적용 (`sri.getHash('analysisAndAction_js')`)
- ✅ 인라인 스크립트 없음 (외부 파일만 사용)
- ✅ 국제화 메시지 사용 (`th:text="${@messageSource.getMessage(...)}"`)

### Fragment 사용

- `layout:fragment="style"` - CSS 스타일
- `layout:fragment="content"` - 메인 콘텐츠
- `layout:fragment="script"` - 스크립트

### Thymeleaf 변수

```html
th:data-can-delete="${userPermissions['canDelete']}"
th:data-can-write="${userPermissions['canWrite']}"
```

### 사이드바 탭 구조

1. **대응 조치 탭** (`#actionTabItem`, `#actionPane`) - historyType="ACTION"일 때 표시
   - 조치유형 (`#view_actionType`)
   - 조치자 (`#view_actionUser`)
   - 기록일시 (`#view_createdAt`)
   - 조치 내용 (`#view_actionContent`)

2. **분석 기록 탭** (`#analysisTabItem`, `#analysisPane`) - historyType="ANALYSIS"일 때 표시
   - 분석자 (`#view_analysisUser`)
   - 기록일시 (`#view_analysisCreatedAt`)
   - 분석 내용 (`#view_analysisContent`)

---

## 프론트엔드 (analysisAndAction.js - 293줄)

### 주요 JavaScript 함수

| 함수명 | 위치 | 역할 |
|--------|------|------|
| `PageConfig.init()` | :14-31 | 페이지 설정 및 메시지 초기화 |
| `PageConfig.get()` | :33-36 | 설정값 조회 |
| `PageConfig.msg()` | :38-41 | 메시지 텍스트 조회 |
| `downloadAnalysisAndActionExcel()` | :47-75 | 엑셀 다운로드 (CSRF 토큰 포함) |
| `showDetail()` | :77-112 | 상세 사이드바 열기 (ACTION/ANALYSIS 탭 분기) |
| `loadData()` | :114-138 | API 호출하여 데이터 로드 (Base64 디코딩) |
| `formatDateTime()` | :140-150 | 날짜 포맷팅 (한국어 로케일) |
| `getColumnDefs()` | :152-234 | AG Grid 열 정의 생성 |
| `initGrid()` | :236-269 | AG Grid 초기화 |

### 이벤트 핸들러

| 이벤트 | 라인 | 동작 |
|--------|------|------|
| `document.ready` | :272-293 | 페이지 초기화 |
| `toggle.change` | :278-280 | 다크모드 토글 시 그리드 테마 재설정 |
| `dateRangeChanged` | :284-286 | 날짜 범위 변경 시 데이터 새로고침 |
| `click .btn-detail` | :289-292 | 상세 버튼 클릭 시 `showDetail()` 호출 |
| `click #btnDownloadExcel` | :287 | 엑셀 다운로드 버튼 클릭 |
| `onGridReady` | :260-263 | 그리드 준비 완료 시 `loadData()` 호출 |

### AG Grid 설정

| 설정 | 값 |
|------|-----|
| 그리드 ID | `#historyGrid` |
| 테마 | `ag-theme-quartz` (다크모드 자동 전환) |
| 페이지네이션 | 50건 기본 (20, 50, 100 선택 가능) |
| 행 선택 | 단일 선택 (rowSelection: 'single') |

### 컬럼 정의

| 컬럼명 | 필드 | 너비 | 특징 |
|--------|------|------|------|
| No | rowNum | 70 | 자동 행 번호 |
| 호기 | zone3 | 80 | Zone3Util 변환 |
| 기록일시 | createdAt | 160 | formatDateTime() |
| 유형 | historyType | 100 | ACTION=조치(파랑), ANALYSIS=분석(청록) |
| 출발지IP | srcIp | 130 | DataMaskingUtils 마스킹 |
| 목적지IP | dstIp | 130 | DataMaskingUtils 마스킹 |
| 이벤트코드 | eventCode | 130 | - |
| 등록자 | actionUser | 100 | - |
| 조치유형 | actionType | 120 | add=조치(초록), ignore=무시(회색) |
| 상세 | - | 80 | 상세 버튼 |

### DataMaskingUtils 사용

```javascript
// 라인 199, 207
DataMaskingUtils.maskSensitiveData(params.value) || '-'
```

- srcIp, dstIp 컬럼에 권한 기반 마스킹 적용
- READ 전용 사용자: IP 마스킹 표시 (`192.168.***.**`)

### Base64 처리

```javascript
// 라인 123-125 - API 응답 후 디코딩
if (item.srcIp) item.srcIp = atob(item.srcIp);
if (item.dstIp) item.dstIp = atob(item.dstIp);
```

---

## 권한 및 보안

### 권한 검사

| 기능 | @RequirePermission | @ActivityLog |
|------|-------------------|--------------|
| 페이지 접근 | 4080L READ | - |
| 데이터 조회 | 4080L READ | - |
| 엑셀 다운로드 | 4080L WRITE | - |

### 보안 처리

1. **IP 마스킹**: 프론트엔드에서 `DataMaskingUtils.maskSensitiveData()` 사용
2. **Base64 인코딩**: srcIp, dstIp 필드는 서버에서 인코딩, 프론트에서 디코딩
3. **CSRF 토큰**: 엑셀 다운로드 POST 요청 시 CSRF 토큰 헤더 포함
4. **SRI 해시**: JS 파일에 integrity 속성 적용

---

## API 엔드포인트 요약

| 메서드 | URL | 권한 | 위치 | 설명 |
|--------|-----|------|------|------|
| GET | `/detection/analysisAndAction` | 4080L READ | :1111 | 페이지 렌더링 |
| GET | `/detection/api/analysisAndAction` | 4080L READ | :1136 | 데이터 조회 |
| POST | `/detection/analysisAndAction/exportExcel` | 4080L WRITE | :1116 | 엑셀 다운로드 |

---

## 데이터 흐름

```
[세션] startDateTime, endDateTime, selectedZoneCode
         ↓
[Controller] 날짜 변환 (:1136-1169)
         ↓
[Service] getAnalysisAndActionHistory() (:1076-1143)
         ↓
[Repository] EventActionLogRepository + AlarmActionRepository
         ↓
[DTO] AnalysisAndActionHistoryDto.toEncoded()
         ↓
[Frontend] AG Grid 표시 + atob() 디코딩 + DataMaskingUtils 마스킹
```

---

## 이력 유형 (historyType)

| 유형 | 한글명 | 뱃지 색상 | 소스 테이블 | 설명 |
|------|--------|----------|------------|------|
| ACTION | 조치 | bg-primary (파랑) | event_action_log | 화이트리스트 추가/무시 조치 |
| ANALYSIS | 분석 | bg-info (청록) | alarm_action | 분석 기록 저장 |

---

## 조치 유형 (actionType)

| 유형 | 한글명 | 뱃지 색상 | 설명 |
|------|--------|----------|------|
| add | 조치 | bg-success (초록) | 화이트리스트에 추가 |
| ignore | 무시 | bg-secondary (회색) | 이벤트 무시 처리 |

---

## 데이터 소스

### 조치 이력 (EventActionLog)

| 필드 | 매핑 |
|------|------|
| id | id |
| eventId | eventId |
| eventCode | eventCode |
| zone3 | zone3 |
| actionUser | actionUser |
| actionStory | content |
| actionType | actionType |
| srcIp | srcIp |
| dstIp | dstIp |
| createdAt | createdAt |

### 분석 이력 (AlarmAction)

| 필드 | 매핑 |
|------|------|
| id | id |
| alarmHistoryId | eventId |
| actionCreateManager | actionUser |
| actionContent | content |
| createdAt | createdAt |
| (Event 조회) | eventCode, zone3, srcIp, dstIp, srcPort, dstPort, protocol |

---

## 관련 문서

- [이상 이벤트 탐지 현황](detection-timesdata-system.md) - 이벤트 목록에서 조치/분석 저장
- [시계열 이종 데이터 분석](detection-timesereise-system.md) - 시계열 페이지에서 분석/조치 저장
- [화이트리스트 위반 현황](detection-connection-system.md) - connection 이벤트 조치
- [엑셀 다운로드](excel-download-system.md) - 엑셀 내보내기 패턴

---

## 프로그램 명세서

### AAH_001 - 분석 및 조치 이력 페이지

| 프로그램 ID | AAH_001 | 프로그램명 | 분석 및 조치 이력 페이지 |
|------------|---------|----------|---------------------|
| 분류 | 이상탐지 | 처리유형 | 화면 |
| 클래스명 | DetectionController.java | 메서드명 | analysisAndAction() |
| 위치 | 1111줄 | | |

▣ 기능 설명

이벤트에 대한 분석 기록과 조치 이력을 통합 조회하는 페이지를 렌더링한다. 데이터는 AJAX로 별도 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| - | - | - | - | - | 없음 (데이터는 AJAX 조회) |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | HTML | 이력 페이지 | String | Y | Thymeleaf 렌더링 HTML |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 검사 (menuId: 4080L, READ) | @RequirePermission |
| 2 | pages/detection/analysisAndAction 템플릿 반환 | AG Grid + Offcanvas |

---

### AAH_002 - 분석 및 조치 이력 데이터 조회

| 프로그램 ID | AAH_002 | 프로그램명 | 분석 및 조치 이력 데이터 조회 |
|------------|---------|----------|--------------------------|
| 분류 | 이상탐지 | 처리유형 | 조회 |
| 클래스명 | DetectionController.java | 메서드명 | getAnalysisAndAction() |
| 위치 | 1136줄 | | |

▣ 기능 설명

조치 이력(EventActionLog)과 분석 이력(AlarmAction)을 통합 조회하여 반환한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | startDateTime | 시작일시 | String | N | 세션 기본값 사용 |
| 2 | endDateTime | 종료일시 | String | N | 세션 기본값 사용 |
| 3 | selectedZoneCode | 호기코드 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과코드 | int | Y | 0: 성공 |
| 2 | message | 메시지 | String | Y | 처리 결과 메시지 |
| 3 | data | 이력목록 | List\<AnalysisAndActionHistoryDto\> | Y | 통합 이력 목록 |

▣ 출력 데이터 상세 (AnalysisAndActionHistoryDto)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | id | 이력ID | Long | Y | 이력 고유 ID |
| 2 | historyType | 유형 | String | Y | ACTION/ANALYSIS |
| 3 | eventId | 이벤트ID | Long | N | 이벤트 ID |
| 4 | eventCode | 이벤트코드 | String | N | 이벤트 코드 |
| 5 | eventName | 이벤트명 | String | N | 이벤트명 |
| 6 | zone3 | 호기 | String | N | 호기 코드 |
| 7 | actionUser | 작성자 | String | Y | 작성자 ID |
| 8 | content | 내용 | String | Y | 조치/분석 내용 |
| 9 | actionType | 조치유형 | String | N | add/ignore |
| 10 | srcIp | 출발지IP | String | N | Base64 인코딩 |
| 11 | dstIp | 목적지IP | String | N | Base64 인코딩 |
| 12 | createdAt | 기록일시 | LocalDateTime | Y | 생성 일시 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 검사 (menuId: 4080L, READ) | @RequirePermission |
| 2 | 세션에서 startDateTime/endDateTime/selectedZoneCode 조회 | |
| 3 | EventActionLogRepository 조회 | 조치 이력 (historyType=ACTION) |
| 4 | AlarmActionRepository 조회 | 분석 이력 (historyType=ANALYSIS) |
| 5 | 두 이력 통합 후 createdAt 기준 정렬 | DESC |
| 6 | IP 정보 Base64 인코딩 | toEncoded() |
| 7 | JSON 응답 반환 | |

---

### AAH_003 - 분석 및 조치 이력 엑셀 다운로드

| 프로그램 ID | AAH_003 | 프로그램명 | 분석 및 조치 이력 엑셀 다운로드 |
|------------|---------|----------|---------------------------|
| 분류 | 이상탐지 | 처리유형 | 조회 |
| 클래스명 | DetectionController.java | 메서드명 | exportAnalysisAndActionExcel() |
| 위치 | 1116줄 | | |

▣ 기능 설명

분석 및 조치 이력을 엑셀 파일로 다운로드한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | startDateTime | 시작일시 | String | N | 세션 기본값 사용 |
| 2 | endDateTime | 종료일시 | String | N | 세션 기본값 사용 |
| 3 | zone3 | 호기코드 | String | N | 세션 기본값 사용 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | file | 엑셀파일 | ByteArrayResource | Y | Excel 바이너리 |
| 2 | filename | 파일명 | String | Y | 분석및조치이력_yyyyMMdd_HHmmss.xlsx |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 검사 (menuId: 4080L, WRITE) | @RequirePermission |
| 2 | 세션에서 날짜/호기 정보 조회 | |
| 3 | DetectionService.exportAnalysisAndActionToExcel() 호출 | :264-295 |
| 4 | getAnalysisAndActionHistory() → convertToExcelDto() | |
| 5 | ExcelExportUtil.exportToExcel() 호출 | |
| 6 | 엑셀 파일 반환 | |