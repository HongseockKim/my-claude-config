# 알람 리스트 시스템 (Alarm List System)

## 개요

시스템에서 발생한 알람 이력을 조회하고 관리하는 페이지. 무한 스크롤 기반의 AG Grid로 대량 데이터 처리 지원. 사용자별로 자신에게 할당된 알람만 표시.

## URL

| 경로 | 위치 | 용도 |
|------|------|------|
| `/setting/alarmList` | SettingController:391-401 | 알람 리스트 페이지 |
| `/setting/alarmList/infinite` | SettingController:403-422 | 무한 스크롤 데이터 API |
| `/operation/alarmAllRead` | OperationController:265-278 | 모든 알람 읽음 처리 |

## 아키텍처

```
[alarmList.html]
        │
        ├──► [SettingController] - 페이지 렌더링 / 무한 스크롤 API
        │
        └──► [OperationController] - 모두 읽음 API
                    │
                    ▼
            [OperationService]
                    │
                    ├──► [AlarmHistoryRepository]
                    ├──► [AlarmConfigRepository]
                    └──► [AlarmManagerRepository]
                    │
                    ▼
            [MariaDB]
              ├── alarm_history
              ├── alarm_config
              └── alarm_manager
```

## 핵심 모델

### AlarmHistory (알람 이력)
```
src/main/java/com/otoones/otomon/model/AlarmHistory.java

@Entity
@Table(name = "alarm_history")
public class AlarmHistory {
    Long id;                    // PK
    String alarmCode;           // 알람 코드 (AlarmConfig와 연결)
    String alarmType;           // NETWORK, AUDIT, ASSET, OPERATION
    String alarmLevel;          // INFO, WARNING, CRITICAL, FATAL
    String title;               // 알람 제목
    String message;             // 알람 메시지
    String sourceIp;            // 발생 IP
    String sourceName;          // 발생 소스명
    String userId;              // 대상 사용자 ID
    String url;                 // 관련 URL
    String actionManager;       // 조치자
    Boolean actionStatus;       // 조치 여부 (기본값: false)
    Boolean isShow;             // 삭제 여부 (true=숨김)
    Boolean isRead;             // 읽음 여부 (기본값: false)
    LocalDateTime actionDate;   // 조치일자
    LocalDateTime readDate;     // 읽은 시간
    LocalDateTime createdDate;  // 발생 시간
}
```

### AlarmConfig (알람 설정)
```
src/main/java/com/otoones/otomon/model/AlarmConfig.java

@Entity
@Table(name = "alarm_config")
public class AlarmConfig {
    Long id;                    // PK
    String alarmName;           // 알람명
    String alarmCode;           // 알람 코드 (unique)
    String alarmType;           // NETWORK, AUDIT, OPERATION
    String alarmLevel;          // INFO, WARNING, CRITICAL
    String trapLevel;           // 조치항목 레벨
    Boolean isEnabled;          // 활성화 여부
    String url;                 // 관련 URL
    String description;         // 설명

    // 관계
    List<AlarmManager> managers;  // 담당자 목록
    List<AlarmAction> actions;    // 조치 이력
}
```

### AlarmHistoryDto
```java
@Data
public class AlarmHistoryDto {
    Long id;
    String alarmCode;
    String alarmType;           // AUDIT, ASSET, NETWORK, OPERATION
    String alarmLevel;          // INFO, WARNING, CRITICAL, FATAL
    String title;
    String message;
    String sourceIp;
    String sourceName;
    String userId;
    String url;
    String actionDate;
    String actionManager;
    Boolean actionStatus;
    Boolean isShow;
    Boolean isRead;
    String readDate;
    String createdDate;         // 포맷팅된 문자열
    String timeAgo;             // "5분 전" 표시용
    Boolean canTakeAction;      // 조치 버튼 표시 여부
}
```

## API 엔드포인트

| Method | URL | 설명 |
|--------|-----|------|
| GET | `/setting/alarmList` | 페이지 렌더링 |
| GET | `/setting/alarmList/infinite` | 무한 스크롤 데이터 |
| POST | `/operation/alarmAllRead` | 모든 알람 읽음 처리 |
| POST | `/operation/action` | 알람 조치 등록 |
| POST | `/operation/action/detail` | 조치 상세 조회 |

### GET /setting/alarmList/infinite

**Request:**
```
?startRow=0&endRow=100
```

**Response:**
```json
{
    "data": [
        {
            "id": 1,
            "alarmCode": "NET_001",
            "alarmType": "NETWORK",
            "alarmLevel": "WARNING",
            "title": "네트워크 이상 감지",
            "message": "192.168.1.100 포트 스캔 감지",
            "sourceIp": "192.168.1.100",
            "isRead": false,
            "createdDate": "2025-12-29 10:30:00"
        }
    ],
    "totalCount": 150
}
```

### POST /operation/alarmAllRead

**Response:**
```json
{
    "success": true,
    "message": "모든 알람을 읽음 처리했습니다."
}
```

## JavaScript 함수 (alarmList.html)

### 그리드 초기화 (Infinite Row Model)
```javascript
function initAlarmGrid() {
    const dataSource = {
        rowCount: null,
        getRows: function(param) {
            $.ajax({
                url: '/setting/alarmList/infinite',
                method: 'GET',
                data: {
                    startRow: param.startRow,
                    endRow: param.endRow
                },
                success: function(res) {
                    param.successCallback(res.data, res.totalCount);
                },
                error: function() {
                    param.failCallback();
                }
            });
        }
    };

    const gridOptions = {
        columnDefs: AlarmListColum(),
        rowModelType: 'infinite',        // 무한 스크롤 모드
        datasource: dataSource,
        cacheBlockSize: 100,             // 블록당 100행
        maxBlocksInCache: 10,            // 최대 10블록 캐시
        infiniteInitialRowCount: 100,
        maxConcurrentDatasourceRequests: 1
    };

    agGrid.createGrid(gridDiv, gridOptions);
}
```

### 모든 알람 읽음 처리
```javascript
function alarmAllRead() {
    showLoading();
    $.ajax({
        url: '/operation/alarmAllRead',
        method: 'POST',
        contentType: 'application/json',
        success: function(result) {
            if (result.success) {
                alert(result.message);
                gridApi.purgeInfiniteCache();  // 캐시 갱신
            }
        },
        complete: function() {
            hideLoading();
        }
    });
}
```

### 새로고침
```javascript
function refreshAlarmList() {
    if (confirm('새로고침 하시겠습니까?')) {
        gridApi.purgeInfiniteCache();
    }
}
```

## 그리드 컬럼

| 컬럼 | 필드명 | 너비 | 설명 |
|------|--------|------|------|
| 읽음 | isRead | 100 | 체크 아이콘 (녹색=읽음, 파랑=안읽음) |
| 레벨 | alarmLevel | 100 | 색상별 한글 표시 |
| 유형 | alarmType | 100 | 배지로 표시 |
| 메시지 | message | flex | 50자 초과 시 말줄임 |
| 발생 IP | sourceIp | 120 | |
| 발생 시간 | createdDate | 140 | YYYY-MM-DD HH:mm |

### 알람 레벨 색상
| 레벨 | CSS 클래스 | 색상 | 한글 |
|------|------------|------|------|
| INFO | alarm-level-info | #0dcaf0 (파랑) | 정보 |
| WARNING | alarm-level-warning | #ffc107 (노랑) | 경고 |
| CRITICAL | alarm-level-critical | #dc3545 (빨강) | 심각 |
| FATAL | alarm-level-fatal | #6f42c1 (보라) | 치명 |

### 알람 유형 맵핑
| 값 | 한글 표시 |
|----|----------|
| AUDIT | 감사 |
| ASSET | 자산 |
| NETWORK | 네트워크 |
| OPERATION | 운영 |

## 서비스 계층

### OperationService

#### 알람 목록 조회 (페이징)
```java
public Map<String, Object> getAlarmHistoryPaginated(String userId, int startRow, int endRow) {
    // 1. 활성화된 알람 코드만 필터링
    List<AlarmConfig> alarmConfigs = alarmConfigRepository.findAll();
    Set<String> enabledAlarmCodes = alarmConfigs.stream()
            .filter(AlarmConfig::getIsEnabled)
            .map(AlarmConfig::getAlarmCode)
            .collect(Collectors.toSet());

    // 2. 총 개수 조회
    long totalCount = alarmHistoryRepository.countFiltered(userId, enabledAlarmCodes);

    // 3. 페이징 데이터 조회
    Pageable pageable = PageRequest.of(page, size);
    List<AlarmHistory> pageHistories = alarmHistoryRepository
            .findFilteredPaged(userId, enabledAlarmCodes, pageable);

    // 4. DTO 변환 및 반환
    return Map.of("data", dtoList, "totalCount", totalCount);
}
```

#### 모든 알람 읽음 처리
```java
public void alarmAllRead(String userId) {
    alarmHistoryRepository.markAllAsRead(userId);
}
```

## Repository 쿼리

### AlarmHistoryRepository
```java
// 필터링된 알람 페이징 조회
@Query("""
    SELECT ah FROM AlarmHistory ah
    WHERE ah.userId = :userId
    AND ah.isShow = false
    AND ah.alarmCode IN :enabledAlarmCodes
    ORDER BY ah.createdDate DESC
""")
List<AlarmHistory> findFilteredPaged(
    @Param("userId") String userId,
    @Param("enabledAlarmCodes") Set<String> enabledAlarmCodes,
    Pageable pageable
);

// 필터링된 알람 개수
@Query("""
    SELECT COUNT(ah) FROM AlarmHistory ah
    WHERE ah.userId = :userId
    AND ah.isShow = false
    AND ah.alarmCode IN :enabledAlarmCodes
""")
long countFiltered(
    @Param("userId") String userId,
    @Param("enabledAlarmCodes") Set<String> enabledAlarmCodes
);

// 모든 알람 읽음 처리
@Modifying
@Query("UPDATE AlarmHistory a SET a.isRead = true, a.readDate = CURRENT_TIMESTAMP
        WHERE a.userId = :userId AND a.isRead = false")
void markAllAsRead(@Param("userId") String userId);
```

## 필터링 로직

### 표시 조건
1. `isShow = false` (삭제되지 않은 알람만)
2. `alarmCode IN enabledAlarmCodes` (활성화된 알람 설정만)
3. `userId = 현재 사용자 ID` (자신의 알람만)

### 정렬
- `createdDate DESC` (최신순)

## Model Attribute (페이지 렌더링 시)

| 속성 | 타입 | 설명 |
|------|------|------|
| userList | List<UserProjection> | 조치자 선택용 사용자 목록 |
| alarmList | List<AlarmHistoryDto> | 초기 알람 목록 (사용 안 함, 무한 스크롤로 대체) |

## 조치 기능 (주석 처리됨)

현재 템플릿에서 조치 관련 UI가 주석 처리되어 있음:
- 조치 등록 Offcanvas (`#alarmActionSidebar`)
- 조치 상세 Offcanvas (`#alarmActionDetailSideBar`)
- 조치자 선택, 조치 내용 입력

### 조치 등록 API (주석 처리된 코드에서 사용)
```javascript
function ActionRequest() {
    $.ajax({
        url: '/operation/action',
        method: 'POST',
        data: JSON.stringify({
            alarmHistoryId: Number(currentAlarmId),
            actionContent: $('#actionNote').val(),
            actionCreateManager: $('#actionManager').val(),
            actionOrder: 1
        }),
        success: function(result) {
            if (result.success) {
                location.reload();
            }
        }
    });
}
```

## 다크모드 지원

```javascript
document.addEventListener('DOMContentLoaded', function() {
    grid.className = getAgGridThemeClass();

    document.getElementById('darkModeToggle').addEventListener('change', function() {
        grid.className = getAgGridThemeClass();
    });
});
```

## 버튼 기능

| 버튼 | ID | 기능 |
|------|----|------|
| 모두 읽음 | btnMarkAllRead | 모든 알람을 읽음 처리 |
| 새로고침 | btnRefresh | 그리드 캐시 갱신 |

## 관련 테이블

### alarm_history
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | BIGINT | PK |
| alarm_code | VARCHAR | 알람 코드 |
| alarm_type | VARCHAR | 알람 유형 |
| alarm_level | VARCHAR | 알람 레벨 |
| title | VARCHAR | 제목 |
| message | TEXT | 메시지 |
| source_ip | VARCHAR | 발생 IP |
| source_name | VARCHAR | 소스명 |
| user_id | VARCHAR | 대상 사용자 |
| url | VARCHAR | 관련 URL |
| action_manager | VARCHAR | 조치자 |
| action_status | TINYINT(1) | 조치 여부 |
| is_show | TINYINT(1) | 삭제 여부 |
| is_read | TINYINT(1) | 읽음 여부 |
| action_date | DATETIME | 조치일 |
| read_date | DATETIME | 읽은 시간 |
| created_date | DATETIME | 발생 시간 |

## 연관 문서

- 알람 설정: `docs/setting-alarm-system.md`
- 감사로그 설정: `docs/setting-audit-system.md`
- 프론트엔드 패턴: `docs/frontend-patterns.md`

---

## 프로그램 명세서

### ALM_001 - 알람 리스트 페이지

| 프로그램 ID | ALM_001 | 프로그램명 | 알람 리스트 페이지 |
|------------|---------|----------|------------------|
| 분류 | 알람관리 | 처리유형 | 조회 |
| 클래스명 | SettingController.java | 메서드명 | alarmList() |

▣ 기능 설명

알람 이력 목록 페이지를 렌더링한다. AG Grid 무한 스크롤 방식으로 대량 알람 이력을 효율적으로 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | userId | 사용자ID | String | Y | 세션에서 추출 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | userList | 사용자목록 | List\<UserProjection\> | Y | 조치자 선택용 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 사용자 정보 추출 | |
| 2 | 조치자 선택용 사용자 목록 조회 | |
| 3 | Model에 사용자 목록 추가 | |
| 4 | pages/setting/alarmList 템플릿 반환 | |

---

### ALM_002 - 알람 목록 무한 스크롤 조회

| 프로그램 ID | ALM_002 | 프로그램명 | 알람 목록 무한 스크롤 조회 |
|------------|---------|----------|------------------------|
| 분류 | 알람관리 | 처리유형 | 조회 |
| 클래스명 | SettingController.java | 메서드명 | getAlarmListInfinite() |

▣ 기능 설명

AG Grid Infinite Row Model을 위한 알람 이력 페이징 조회. 활성화된 알람 코드만 필터링하여 반환한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | startRow | 시작행 | int | N | 기본값 0 |
| 2 | endRow | 종료행 | int | N | 기본값 100 |
| 3 | userId | 사용자ID | String | Y | 세션에서 추출 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | data | 알람목록 | List\<AlarmHistoryDto\> | Y | 페이징된 알람 이력 |
| 2 | totalCount | 전체건수 | Long | Y | 필터 적용 후 전체 건수 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 사용자 ID 추출 | |
| 2 | AlarmConfigRepository에서 활성화된 알람 코드 조회 | isEnabled=true |
| 3 | AlarmHistoryRepository.countFiltered() 호출 | 전체 건수 |
| 4 | AlarmHistoryRepository.findFilteredPaged() 호출 | isShow=false, userId 필터 |
| 5 | Entity → DTO 변환 (timeAgo 계산) | "5분 전" 형태 |
| 6 | { data, totalCount } 응답 반환 | |

---

### ALM_003 - 모든 알람 읽음 처리

| 프로그램 ID | ALM_003 | 프로그램명 | 모든 알람 읽음 처리 |
|------------|---------|----------|------------------|
| 분류 | 알람관리 | 처리유형 | 수정 |
| 클래스명 | OperationController.java | 메서드명 | alarmAllRead() |

▣ 기능 설명

현재 사용자의 모든 미읽음 알람을 읽음 상태로 일괄 변경한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | userId | 사용자ID | String | Y | 세션에서 추출 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공여부 | Boolean | Y | true/false |
| 2 | message | 메시지 | String | Y | 처리 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 사용자 ID 추출 | |
| 2 | AlarmHistoryRepository.markAllAsRead() 호출 | @Modifying 쿼리 |
| 3 | isRead = true, readDate = CURRENT_TIMESTAMP 설정 | 조건: isRead = false |
| 4 | 성공 응답 반환 | |
