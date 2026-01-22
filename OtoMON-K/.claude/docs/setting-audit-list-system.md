# 감사로그 목록 시스템 (Audit List System)

## 개요

시스템 내 모든 사용자 활동, 보안 이벤트, 시스템 오류를 기록하고 조회하는 감사로그 목록 페이지. 권한 기반 접근 제어와 엑셀 다운로드 기능 지원.

## URL

| 경로 | 위치 | 용도 |
|------|------|------|
| `/setting/auditList` | SettingController:323-357 | 감사로그 목록 페이지 |
| `/operation/audit/grid-data` | OperationController:121-156 | 그리드 데이터 API |
| `/operation/audit/export-excel` | OperationController:158-195 | 전체 엑셀 다운로드 |
| `/setting/audit/export-excel-current` | SettingController:360-385 | 현재 페이지 엑셀 다운로드 |

## 아키텍처

```
[auditList.html]
        │
        ├──► [SettingController] - 페이지 렌더링
        │
        └──► [OperationController] - 데이터 API
                    │
                    ▼
            [AuditSettingService] ──► 권한 체크
                    │
                    ▼
            [AuditLogDataService] ──► 데이터 조회/엑셀 생성
                    │
                    ▼
        [SystemActivityLogRepository]
                    │
                    ▼
            [MariaDB: system_activity_log]
```

## 권한 체크 로직

### 접근 권한 (AuditSettingService.userViewAuditLogs)
```java
1. ADMIN 사용자 → 항상 접근 가능
2. USER 사용자 → 소속 그룹 중 하나라도 메뉴 ID 9090L 권한이 있으면 접근 가능
```

### 데이터 조회 범위
| 권한 | 조회 범위 |
|------|----------|
| ADMIN | 모든 사용자의 모든 로그 |
| USER | 자신의 로그만 |

## 핵심 모델

### SystemActivityLog (감사로그)
```
src/main/java/com/otoones/otomon/model/SystemActivityLog.java

@Entity
@Table(name = "system_activity_log")
public class SystemActivityLog {
    Long id;                      // PK
    String logId;                 // UUID (자동 생성)
    LocalDateTime timestamp;      // 발생 시간 (TIMESTAMP(3))
    LogType logType;              // USER_ACTION, SECURITY_EVENT, SYSTEM_ERROR, MENU_ACCESS
    String category;              // 카테고리 (AUTH, SETTING_MANAGE, OpTagInfo 등)
    String action;                // 액션 (LOGIN, UPDATE, DELETE, ADD 등)
    Severity severity;            // INFO, WARN, ERROR, CRITICAL
    String userId;                // 사용자 ID
    String userName;              // 사용자명
    String userRole;              // 권한
    String sessionId;             // 세션 ID
    String ipAddress;             // IP 주소
    String userAgent;             // User Agent
    String resourceType;          // 리소스 타입
    String resourceId;            // 리소스 ID
    String resourceName;          // 리소스명
    String details;               // 상세 내용 (JSON)
    Result result;                // SUCCESS, FAILURE, PARTIAL
    String errorMessage;          // 오류 메시지
    Integer durationMs;           // 소요 시간 (ms)
}
```

### Enum 정의
```java
public enum LogType {
    USER_ACTION,      // 사용자 액션
    SECURITY_EVENT,   // 보안 이벤트
    SYSTEM_ERROR,     // 시스템 오류
    MENU_ACCESS       // 메뉴 접근
}

public enum Severity {
    INFO,      // 정보
    WARN,      // 경고
    ERROR,     // 오류
    CRITICAL   // 심각
}

public enum Result {
    SUCCESS,   // 성공
    FAILURE,   // 실패
    PARTIAL    // 부분 성공
}
```

## API 엔드포인트

| Method | URL | 설명 | 권한 |
|--------|-----|------|------|
| GET | `/setting/auditList` | 페이지 렌더링 | 메뉴 권한 |
| POST | `/operation/audit/grid-data` | 그리드 데이터 조회 | 인증 + 권한 체크 |
| POST | `/operation/audit/export-excel` | 전체 엑셀 다운로드 | 인증 + 권한 체크 |
| POST | `/setting/audit/export-excel-current` | 현재 페이지 엑셀 다운로드 | 인증 + 권한 체크 |

### POST /operation/audit/grid-data

**Request:**
```json
{
    "size": 1000
}
```

**Response:**
```json
[
    {
        "id": 1,
        "logId": "550e8400-e29b-41d4-a716-446655440000",
        "timestamp": "2025-12-29T10:30:00",
        "logType": "USER_ACTION",
        "category": "AUTH",
        "action": "LOGIN",
        "severity": "INFO",
        "userId": "admin",
        "userName": "관리자",
        "userRole": "ADMIN",
        "resourceType": "User",
        "resourceId": "admin",
        "details": "{\"browser\": \"Chrome\"}",
        "result": "SUCCESS"
    }
]
```

### POST /setting/audit/export-excel-current

**Request:**
```json
{
    "ids": [1, 2, 3, 4, 5]
}
```

**Response:** Excel 파일 (Blob)

## JavaScript 함수 (auditList.html)

### 그리드 초기화
```javascript
function initGrid() {
    const gridOptions = getGridOptions();
    gridApi = agGrid.createGrid(gridDiv, gridOptions);
}

function getGridOptions() {
    return {
        columnDefs: getColumnDefs(),
        animateRows: true,
        pagination: true,
        paginationPageSize: 20,
        paginationPageSizeSelector: [10, 20, 50, 100],
        onGridReady: function(params) {
            loadAuditData();
        }
    };
}
```

### 데이터 로드
```javascript
function loadAuditData() {
    $.ajax({
        url: '/operation/audit/grid-data',
        method: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ size: 1000 }),
        success: function(data) {
            gridApi.setGridOption('rowData', data);
        }
    });
}
```

### 엑셀 다운로드
```javascript
// 현재 페이지 다운로드 (화면에 표시된 데이터만)
function exportCurrentPageData() {
    const visibleDataIds = [];
    gridApi.forEachNodeAfterFilterAndSort(function(node) {
        if (node.data && node.data.id) {
            visibleDataIds.push(node.data.id);
        }
    });

    $.ajax({
        url: '/setting/audit/export-excel-current',
        method: 'POST',
        data: JSON.stringify({ ids: visibleDataIds }),
        xhrFields: { responseType: 'blob' },
        success: function(data) {
            // Blob 다운로드 처리
        }
    });
}

// 전체 다운로드
function exportAllData() {
    $.ajax({
        url: '/operation/audit/export-excel',
        method: 'POST',
        xhrFields: { responseType: 'blob' },
        success: function(data) {
            // Blob 다운로드 처리
        }
    });
}
```

### 상세보기 패널
```javascript
function showDetailPanel(data) {
    // Offcanvas에 데이터 표시
    $('#detail-timestamp').text(moment(data.timestamp).format('YYYY-MM-DD HH:mm:ss'));
    $('#detail-userId').text(data.userId);
    $('#detail-severity').text(data.severity);
    // ... 나머지 필드들

    // JSON 상세 내용 포맷팅
    if (data.details) {
        const detailsObj = JSON.parse(data.details);
        $('#detail-details').text(JSON.stringify(detailsObj, null, 2));
    }

    new bootstrap.Offcanvas(document.getElementById('detailOffcanvas')).show();
}
```

## 그리드 컬럼

| 컬럼 | 필드명 | 너비 | 설명 |
|------|--------|------|------|
| 심각도 | severity | 120 | 색상 구분 (critical=빨강, error=주황, warn=노랑, info=파랑) |
| 시간 | timestamp | 160 | YYYY-MM-DD HH:mm:ss 포맷 |
| 로그 타입 | logType | 140 | USER_ACTION, SECURITY_EVENT 등 |
| 액션 | action | 120 | 수정, 추가, 로그인 등 한글 변환 |
| 사용자 | userId | 120 | |
| 권한 | userRole | 120 | |
| 리소스 타입 | resourceType | 150 | |
| 상세 내용 | details | flex | 툴팁 표시 |
| 결과 | result | 110 | 색상 구분 (success=녹색, failure=빨강, partial=노랑) |
| 상세 | actions | 100 | 보기 버튼 |

## 엑셀 다운로드 컬럼

Apache POI (XSSFWorkbook) 사용

```
ID, 로그ID, 시간, 로그타입, 카테고리, 액션, 심각도,
사용자ID, 사용자명, 권한, 리소스타입, 리소스ID, 리소스명,
상세내용, 결과, 오류메시지, 소요시간(ms), 세션ID, IP주소, User Agent
```

## Repository 쿼리

### SystemActivityLogRepository
```java
// 전체 조회 (시간 내림차순)
List<SystemActivityLog> findAllByOrderByTimestampDesc();

// 사용자별 전체 조회
List<SystemActivityLog> findAllByUserIdOrderByTimestampDesc(String userId);

// 페이징 조회
Page<SystemActivityLog> findByUserIdOrderByTimestampDesc(String userId, Pageable pageable);

// ID 목록으로 조회 (현재 페이지 다운로드용)
List<SystemActivityLog> findByIdInOrderByTimestampDesc(List<Long> ids);

// ID + 사용자 조회 (USER 권한 다운로드용)
List<SystemActivityLog> findByIdInAndUserIdOrderByTimestampDesc(List<Long> ids, String userId);

// 복합 필터 조회
@Query("SELECT s FROM SystemActivityLog s WHERE " +
       "(:userId IS NULL OR s.userId = :userId) AND " +
       "(:logType IS NULL OR s.logType = :logType) AND " +
       "(:category IS NULL OR s.category = :category) AND " +
       "(:severity IS NULL OR s.severity = :severity) AND " +
       "s.timestamp BETWEEN :startTime AND :endTime " +
       "ORDER BY s.timestamp DESC")
Page<SystemActivityLog> findLogsWithFilters(...);

// 실패 로그인 조회
@Query("SELECT s FROM SystemActivityLog s WHERE s.category = 'AUTH'
        AND s.action = 'LOGIN' AND s.result = 'FAILURE'
        AND s.timestamp >= :since ORDER BY s.timestamp DESC")
List<SystemActivityLog> findFailedLoginAttempts(@Param("since") LocalDateTime since);
```

## 서비스 계층

### AuditLogDataService
```java
// 사용자 권한 기반 데이터 조회
public List<SystemActivityLogDto> getAuditLogDataByUser(User currentUser, int size) {
    if (currentUser.getRole() == UserRole.ADMIN) {
        // 전체 로그 조회
        if (size == -1) {
            return findAllByOrderByTimestampDesc();
        } else {
            return findAll(PageRequest.of(0, size, Sort.DESC, "timestamp"));
        }
    } else {
        // 자신의 로그만 조회
        return findByUserId(currentUser.getUserId());
    }
}

// 전체 엑셀 생성
public ByteArrayResource makeExcelDataByUser(User currentUser);

// 현재 페이지 엑셀 생성
public ByteArrayResource makeExcelDataByIds(User currentUser, List<Long> ids);
```

### AuditSettingService
```java
// 감사로그 접근 권한 체크
public boolean userViewAuditLogs(User user) {
    if (user.getRole() == UserRole.ADMIN) {
        return true;  // ADMIN은 항상 허용
    }

    // 소속 그룹 중 메뉴 ID 9090L 권한 체크
    for (UserGroup group : user.getGroups()) {
        if (isLogDisplayAllowed(group.getIdx())) {
            return true;
        }
    }
    return false;
}

// 알람 활성화 여부 체크
public boolean alarmEnabledForRole(User user);
```

## 다크모드 지원

```javascript
// 다크모드 감지 및 그리드 테마 전환
document.addEventListener('DOMContentLoaded', function() {
    grid.className = getAgGridThemeClass();  // ag-theme-quartz-dark 또는 ag-theme-quartz

    document.getElementById('darkModeToggle').addEventListener('change', function() {
        grid.className = getAgGridThemeClass();
    });
});
```

## 상세보기 Offcanvas 구조

```html
<div class="offcanvas offcanvas-end" id="detailOffcanvas">
    <div class="offcanvas-header">감사로그 상세정보</div>
    <div class="offcanvas-body">
        <!-- 기본 정보 -->
        <dl class="row">
            <dt>시간:</dt><dd id="detail-timestamp"></dd>
            <dt>사용자:</dt><dd id="detail-userId"></dd>
            <dt>권한:</dt><dd id="detail-userRole"></dd>
            <dt>로그 타입:</dt><dd id="detail-logType"></dd>
            <dt>액션:</dt><dd id="detail-action"></dd>
            <dt>심각도:</dt><dd><span class="badge" id="detail-severity"></span></dd>
            <dt>결과:</dt><dd><span class="badge" id="detail-result"></span></dd>
        </dl>

        <!-- 리소스 정보 -->
        <dl class="row">
            <dt>리소스 타입:</dt><dd id="detail-resourceType"></dd>
            <dt>리소스 ID:</dt><dd id="detail-resourceId"></dd>
            <dt>리소스명:</dt><dd id="detail-resourceName"></dd>
        </dl>

        <!-- 상세 내용 (JSON) -->
        <pre id="detail-details"></pre>
    </div>
</div>
```

## Model Attribute (페이지 렌더링 시)

| 속성 | 타입 | 설명 |
|------|------|------|
| accessDenied | Boolean | 접근 거부 여부 |
| error | Boolean | 시스템 오류 여부 |
| message | String | 오류/거부 메시지 |
| userRole | String | 현재 사용자 권한 |
| canViewAllLogs | Boolean | 전체 로그 조회 가능 여부 (ADMIN) |
| alarmEnabled | Boolean | 알람 활성화 여부 |

## 심각도/결과 색상 맵핑

### Severity
| 값 | CSS 클래스 | 배지 색상 |
|----|------------|----------|
| CRITICAL | severity-critical | bg-danger (빨강) |
| ERROR | severity-error | bg-warning (주황) |
| WARN | severity-warn | bg-warning (노랑) |
| INFO | severity-info | bg-info (파랑) |

### Result
| 값 | CSS 클래스 | 배지 색상 |
|----|------------|----------|
| SUCCESS | result-success | bg-success (녹색) |
| FAILURE | result-failure | bg-danger (빨강) |
| PARTIAL | result-partial | bg-warning (노랑) |

## 연관 문서

- 감사로그 설정: `docs/setting-audit-system.md`
- 감사로그 기록: `docs/audit-log-system.md`
- 권한 시스템: `docs/permission-system.md`
- 엑셀 다운로드: `docs/excel-download-system.md`

---

## 프로그램 명세서

### AUD_001 - 감사로그 목록 페이지

| 프로그램 ID | AUD_001 | 프로그램명 | 감사로그 목록 페이지 |
|------------|---------|----------|-------------------|
| 분류 | 감사관리 | 처리유형 | 조회 |
| 클래스명 | SettingController.java | 메서드명 | auditList() |

▣ 기능 설명

시스템 활동 감사로그 목록 페이지를 렌더링한다. 사용자 권한에 따라 조회 범위가 달라진다 (ADMIN: 전체, USER: 본인만).

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | authentication | 인증정보 | Authentication | Y | Spring Security 인증 객체 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | accessDenied | 접근거부 | Boolean | N | 권한 없을 시 true |
| 2 | userRole | 사용자권한 | String | Y | ADMIN/USER |
| 3 | canViewAllLogs | 전체조회권한 | Boolean | Y | ADMIN이면 true |
| 4 | alarmEnabled | 알람활성화 | Boolean | Y | 알람 수신 여부 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | Authentication에서 User 객체 추출 | |
| 2 | AuditSettingService.userViewAuditLogs() 호출 | 접근 권한 체크 |
| 3 | 권한 없으면 accessDenied=true 설정 | |
| 4 | 사용자 역할별 조회 권한 설정 | ADMIN: 전체, USER: 본인 |
| 5 | pages/setting/auditList 템플릿 반환 | |

---

### AUD_002 - 감사로그 그리드 데이터 조회

| 프로그램 ID | AUD_002 | 프로그램명 | 감사로그 그리드 데이터 조회 |
|------------|---------|----------|-------------------------|
| 분류 | 감사관리 | 처리유형 | 조회 |
| 클래스명 | OperationController.java | 메서드명 | getAuditGridData() |

▣ 기능 설명

AG Grid에 표시할 감사로그 데이터를 조회한다. 사용자 권한에 따라 조회 범위가 다르다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | size | 조회건수 | int | N | 기본값 1000 |
| 2 | authentication | 인증정보 | Authentication | Y | Spring Security 인증 객체 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | data | 감사로그목록 | List\<SystemActivityLogDto\> | Y | 감사로그 DTO 목록 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | Authentication에서 User 객체 추출 | |
| 2 | 사용자 역할 확인 | ADMIN/USER |
| 3 | ADMIN이면 전체 로그 조회 | findAllByOrderByTimestampDesc |
| 4 | USER이면 본인 로그만 조회 | findByUserIdOrderByTimestampDesc |
| 5 | size로 페이징 처리 | |
| 6 | DTO 목록 반환 | |

---

### AUD_003 - 감사로그 전체 엑셀 다운로드

| 프로그램 ID | AUD_003 | 프로그램명 | 감사로그 전체 엑셀 다운로드 |
|------------|---------|----------|-------------------------|
| 분류 | 감사관리 | 처리유형 | 조회 |
| 클래스명 | OperationController.java | 메서드명 | exportAuditExcel() |

▣ 기능 설명

사용자 권한에 따른 감사로그 전체를 엑셀 파일로 다운로드한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | authentication | 인증정보 | Authentication | Y | Spring Security 인증 객체 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | file | 엑셀파일 | ByteArrayResource | Y | Excel 바이너리 |
| 2 | filename | 파일명 | String | Y | 감사로그_YYYYMMDD.xlsx |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | Authentication에서 User 객체 추출 | |
| 2 | AuditLogDataService.makeExcelDataByUser() 호출 | |
| 3 | Apache POI XSSFWorkbook 생성 | |
| 4 | 20개 컬럼 헤더 작성 | ID, 시간, 로그타입 등 |
| 5 | 데이터 행 작성 | |
| 6 | Content-Disposition 헤더 설정 | attachment |
| 7 | 엑셀 파일 반환 | |

---

### AUD_004 - 감사로그 현재 페이지 엑셀 다운로드

| 프로그램 ID | AUD_004 | 프로그램명 | 감사로그 현재 페이지 엑셀 다운로드 |
|------------|---------|----------|-------------------------------|
| 분류 | 감사관리 | 처리유형 | 조회 |
| 클래스명 | SettingController.java | 메서드명 | exportCurrentPageExcel() |

▣ 기능 설명

화면에 표시된 감사로그만 선택하여 엑셀 파일로 다운로드한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ids | ID목록 | List\<Long\> | Y | 다운로드할 로그 ID 목록 |
| 2 | authentication | 인증정보 | Authentication | Y | Spring Security 인증 객체 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | file | 엑셀파일 | ByteArrayResource | Y | Excel 바이너리 |
| 2 | filename | 파일명 | String | Y | 감사로그_현재페이지_YYYYMMDD.xlsx |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | Authentication에서 User 객체 추출 | |
| 2 | AuditLogDataService.makeExcelDataByIds() 호출 | |
| 3 | ID 목록으로 로그 조회 | findByIdInOrderByTimestampDesc |
| 4 | USER 권한이면 본인 로그만 필터 | findByIdInAndUserIdOrderByTimestampDesc |
| 5 | 엑셀 파일 생성 및 반환 | |
