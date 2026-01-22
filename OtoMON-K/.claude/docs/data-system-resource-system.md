# 시스템 리소스 현황 (data/systemResource) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/data/systemResource` |
| **메뉴 ID** | 3020L |
| **권한** | READ 권한 필요 |
| **한글명** | 시스템 리소스 현황 |
| **목적** | 수집서버의 CPU, 메모리, 디스크 사용률 모니터링 및 파일 전송/무결성 검증 이력 조회 |
| **데이터 소스** | ClickHouse - ResourceMonitoring, FileProcessingRecord 테이블 |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/DataController.java
Service:    src/main/java/com/otoones/otomon/service/ClickHouseService.java
Template:   src/main/resources/templates/pages/data/systemResource.html
```

---

## 컨트롤러 (DataController.java)

### 페이지 렌더링 (`GET /data/systemResource`)

**위치**: `DataController.java:114-124`

**권한**:
```java
@RequirePermission(menuId = 3020, resourceType = ResourceType.MENU, permissionType = PermissionType.READ, skipForAdmin = true)
```

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| availableZone3List | 활성화된 호기 목록 |
| systemResourceSummary | 시스템 리소스 요약 |

### 시스템 리소스 데이터 API (`GET /data/grid-data-systemResource`)

**위치**: `DataController.java:128-146`

**응답 형식**: `ApiResponse<List<Map>>` (JavaScript 하이재킹 방어)

**파라미터**:
| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| hours | 24 | 조회 시간 범위 (시간) |

세션의 dateRangeType에 따라 자동 조정:
- 1m: 24 * 30 시간
- 3m: 24 * 90 시간
- 기본: 24 * 7 시간

### 파일 전송 현황 API (`GET /data/api/file-transfer-status`)

**위치**: `DataController.java:148-171`

최근 24시간 내 파일 전송 상태 조회

### 무결성 검증 이력 API

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/data/api/integrity-failure-history` | 무결성 검증 실패 이력 |
| GET | `/data/api/integrity-success-history` | 무결성 검증 성공 이력 |

---

## 서비스 (ClickHouseService.java)

### `getSystemResourceData()` - 위치: 345줄

시스템 리소스 시계열 데이터 조회

```java
public List<Map<String, Object>> getSystemResourceData(
    String zone1, String zone2, String zone3, int hours
)
```

**쿼리 테이블**: `NetworkData.ResourceMonitoring`

**조회 필드**:
| 필드 | 설명 |
|------|------|
| cpu_usage_percent | CPU 사용률 (%) |
| memory_used_gb | 메모리 사용량 (GB) |
| memory_total_gb | 메모리 전체 (GB) |
| memory_usage_percent | 메모리 사용률 (%) |
| disk_root_used_gb | 루트 디스크 사용량 (GB) |
| disk_root_total_gb | 루트 디스크 전체 (GB) |
| disk_root_usage_percent | 루트 디스크 사용률 (%) |
| disk_data_used_gb | 데이터 디스크 사용량 (GB) |
| disk_data_total_gb | 데이터 디스크 전체 (GB) |
| disk_data_usage_percent | 데이터 디스크 사용률 (%) |

### `getSystemResourceSummary()` - 위치: 378줄

최신 시스템 리소스 요약 정보 조회 (최근 1시간)

### `getFileTransferStatus()` - 위치: 428줄

파일 전송 현황 조회 (최근 24시간)

**쿼리 테이블**: `FileProcessingRecord`

**반환 필드**:
| 필드 | 설명 |
|------|------|
| zone3 | 호기 코드 |
| latest_file_name | 최신 파일명 |
| latest_status | 최신 상태 (SUCCESS/FAIL) |
| latest_completed_at | 최신 완료 시간 |
| total_files | 전체 파일 수 |
| success_count | 성공 건수 |
| fail_count | 실패 건수 |

### `getIntegrityFailureHistory()` - 위치: 454줄

무결성 검증 실패 이력 조회

**조건**: `integrity_verified = 0`

### `getIntegritySuccessHistory()` - 위치: 485줄

무결성 검증 성공 이력 조회

**조건**: `integrity_verified = 1`

---

## 프론트엔드 (systemResource.html)

### 페이지 구성

1. **리소스 모니터링 섹션**: 호기별 CPU/메모리/디스크 차트
2. **파일 전송 현황 섹션**: 호기별 최신 파일 전송 상태
3. **무결성 검증 이력 섹션**: 실패/성공 탭으로 분리

### 차트 (ECharts)

호기별로 3개의 시계열 차트 표시:
- **CPU 차트**: 파란색 (#2196F3)
- **메모리 차트**: 초록색 (#4CAF50)
- **디스크 차트**: 주황색 (#FF9800)

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `initializeCharts()` | ECharts 초기화 |
| `loadChartData()` | 시스템 리소스 데이터 로드 |
| `processResourceData(data)` | 차트 데이터 처리 |
| `updateResourceChart()` | 차트 업데이트 |
| `loadFileTransferData()` | 파일 전송 현황 로드 |
| `renderFileTransferStatus(data)` | 파일 전송 현황 렌더링 |
| `loadIntegrityFailureData()` | 무결성 실패 이력 로드 |
| `loadIntegritySuccessData()` | 무결성 성공 이력 로드 |
| `initializeTabs()` | 탭 네비게이션 초기화 |

### 탭 구조

```html
<div class="tab-navigation">
    <button class="tab-button active" data-tab="failure">실패 이력</button>
    <button class="tab-button" data-tab="success">성공 이력</button>
</div>
```

---

## API 엔드포인트 요약

| 메서드 | URL | 권한 | 설명 |
|--------|-----|------|------|
| GET | `/data/systemResource` | 3020L READ | 페이지 렌더링 |
| GET | `/data/grid-data-systemResource` | 3020L READ | 시스템 리소스 데이터 |
| GET | `/data/api/file-transfer-status` | 3020L READ | 파일 전송 현황 |
| GET | `/data/api/integrity-failure-history` | 3020L READ | 무결성 실패 이력 |
| GET | `/data/api/integrity-success-history` | 3020L READ | 무결성 성공 이력 |

---

## 데이터 흐름

```
[세션] dateRangeType, selectedZoneCode
         ↓
[Controller] 시간 범위 계산
         ↓
[ClickHouseService] getSystemResourceData() / getFileTransferStatus()
         ↓
[ClickHouse] ResourceMonitoring / FileProcessingRecord 테이블
         ↓
[Frontend] ECharts 차트 / 테이블 렌더링
```

---

## ClickHouse 테이블

### ResourceMonitoring (시스템 리소스)

| 필드 | 타입 | 설명 |
|------|------|------|
| timestamp | DateTime | 수집 시간 |
| zone1, zone2, zone3 | String | 영역 정보 |
| cpu_usage_percent | Float | CPU 사용률 |
| memory_used_gb | Float | 메모리 사용량 |
| memory_total_gb | Float | 메모리 전체 |
| memory_usage_percent | Float | 메모리 사용률 |
| disk_root_used_gb | Float | 루트 디스크 사용량 |
| disk_root_total_gb | Float | 루트 디스크 전체 |
| disk_data_used_gb | Float | 데이터 디스크 사용량 |
| disk_data_total_gb | Float | 데이터 디스크 전체 |

### FileProcessingRecord (파일 처리 기록)

| 필드 | 타입 | 설명 |
|------|------|------|
| zone1, zone2, zone3 | String | 영역 정보 |
| file_name | String | 파일명 |
| status | String | 상태 (SUCCESS/FAIL) |
| completed_at | DateTime | 완료 시간 |
| integrity_verified | UInt8 | 무결성 검증 여부 (0/1) |
| failure_reason | String | 실패 사유 |
| original_hash | String | 원본 해시 |
| calculated_hash | String | 계산된 해시 |
| file_size | UInt64 | 파일 크기 |

---

## UI 섹션별 스타일

### 서버 행
```css
.server-row {
    background-color: #2a2a2a;
    padding: 15px;
    margin-bottom: 15px;
    border-radius: 8px;
}
```

### 차트 래퍼
```css
.chart-wrapper {
    background-color: #1a1a1a;
    height: 200px;
    border-radius: 6px;
}
```

### 파일 전송 상태
```css
.file-item {
    border-left: 4px solid #4CAF50;  /* 성공 */
}
.file-item.failed {
    border-left-color: #f44336;       /* 실패 */
}
```

---

## 차트 설정

```javascript
function getBaseChartOption() {
    return {
        grid: { top: 20, left: 10, right: 10, bottom: 10 },
        xAxis: {
            type: 'category',
            data: generateTimeLabels()  // 24시간 라벨
        },
        yAxis: {
            type: 'value',
            max: 100,
            axisLabel: { formatter: '{value}%' }
        },
        series: [{
            type: 'line',
            smooth: true,
            areaStyle: { opacity: 0.3 }
        }]
    };
}
```

---

## 날짜 범위 처리

| dateRangeType | hours 값 |
|---------------|----------|
| 1m (1개월) | 720 (24 * 30) |
| 3m (3개월) | 2160 (24 * 90) |
| 기본 (7일) | 168 (24 * 7) |

---

## 관련 문서

- [세션 필터링](session-filtering.md) - 날짜 필터링
- [데이터베이스](database.md) - ClickHouse 쿼리
- [프론트엔드 패턴](frontend-patterns.md) - ECharts 패턴

---

## 프로그램 명세서

### SYS_001 - 시스템 리소스 현황 페이지

| 프로그램 ID | SYS_001 | 프로그램명 | 시스템 리소스 현황 페이지 |
|------------|---------|----------|--------------------------|
| 분류 | 시스템 모니터링 | 처리유형 | 화면 |
| 클래스명 | DataController.java | 메서드명 | systemResourcePage() |

▣ 기능 설명

수집서버의 CPU, 메모리, 디스크 사용률을 모니터링하고 파일 전송/무결성 검증 이력을 조회하는 페이지를 렌더링한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | session.selectedZoneCode | 호기 코드 | String | N | 세션에서 자동 조회 |
| 2 | session.dateRangeType | 날짜 범위 타입 | String | N | 7d/1m/3m |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | availableZone3List | 활성 호기 목록 | List<String> | Y | 활성화된 호기 코드 목록 |
| 2 | systemResourceSummary | 리소스 요약 | Map | Y | CPU/메모리/디스크 현재 상태 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 호기 정보 조회 | SessionHelper 사용 |
| 2 | system_config에서 활성 호기 목록 조회 | - |
| 3 | ClickHouseService로 리소스 요약 조회 | getSystemResourceSummary() |
| 4 | Model에 데이터 추가 및 뷰 반환 | pages/data/systemResource |

---

### SYS_002 - 시스템 리소스 데이터 조회 API

| 프로그램 ID | SYS_002 | 프로그램명 | 시스템 리소스 데이터 조회 API |
|------------|---------|----------|------------------------------|
| 분류 | 시스템 모니터링 | 처리유형 | 조회 |
| 클래스명 | DataController.java | 메서드명 | getGridDataSystemResource() |

▣ 기능 설명

시스템 리소스(CPU, 메모리, 디스크) 시계열 데이터를 조회하여 차트에 표시할 데이터를 제공한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | hours | 조회 시간 범위 | Integer | N | 기본값: 24시간 |
| 2 | session.dateRangeType | 날짜 범위 타입 | String | N | 자동 시간 조정에 사용 |
| 3 | session.selectedZoneCode | 호기 코드 | String | N | 조회 대상 호기 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, 1: 실패 |
| 2 | data | 리소스 데이터 | List<Map> | Y | 시계열 리소스 사용률 |
| 3 | message | 메시지 | String | Y | 처리 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | dateRangeType에 따라 시간 범위 계산 | 1m: 720h, 3m: 2160h, 기본: 168h |
| 2 | 세션에서 호기/zone 정보 조회 | - |
| 3 | ClickHouse에서 ResourceMonitoring 조회 | getSystemResourceData() |
| 4 | ApiResponse 래핑 후 반환 | JavaScript 하이재킹 방어 |

---

### SYS_003 - 파일 전송 현황 조회 API

| 프로그램 ID | SYS_003 | 프로그램명 | 파일 전송 현황 조회 API |
|------------|---------|----------|------------------------|
| 분류 | 파일 관리 | 처리유형 | 조회 |
| 클래스명 | DataController.java | 메서드명 | getFileTransferStatus() |

▣ 기능 설명

최근 24시간 내 파일 전송 상태와 통계를 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | session.selectedZoneCode | 호기 코드 | String | N | 세션에서 자동 조회 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, 1: 실패 |
| 2 | data | 파일 전송 현황 | List<Map> | Y | 호기별 전송 상태 |
| 3 | data[].zone3 | 호기 코드 | String | Y | 호기 식별자 |
| 4 | data[].latest_file_name | 최신 파일명 | String | Y | 가장 최근 처리 파일 |
| 5 | data[].latest_status | 최신 상태 | String | Y | SUCCESS/FAIL |
| 6 | data[].success_count | 성공 건수 | Integer | Y | 성공한 파일 수 |
| 7 | data[].fail_count | 실패 건수 | Integer | Y | 실패한 파일 수 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 호기/zone 정보 조회 | - |
| 2 | ClickHouse FileProcessingRecord 조회 | 최근 24시간 |
| 3 | 호기별 통계 계산 | 성공/실패 카운트 |
| 4 | 결과 JSON으로 반환 | ResponseEntity |

---

### SYS_004 - 무결성 검증 실패 이력 조회 API

| 프로그램 ID | SYS_004 | 프로그램명 | 무결성 검증 실패 이력 조회 API |
|------------|---------|----------|------------------------------|
| 분류 | 무결성 검증 | 처리유형 | 조회 |
| 클래스명 | DataController.java | 메서드명 | getIntegrityFailureHistory() |

▣ 기능 설명

파일 무결성 검증 실패 이력을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | session.selectedZoneCode | 호기 코드 | String | N | 세션에서 자동 조회 |
| 2 | limit | 조회 건수 | Integer | N | 기본값: 100 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, 1: 실패 |
| 2 | data | 실패 이력 | List<Map> | Y | 무결성 검증 실패 목록 |
| 3 | data[].file_name | 파일명 | String | Y | 검증 실패 파일 |
| 4 | data[].failure_reason | 실패 사유 | String | Y | 실패 원인 |
| 5 | data[].original_hash | 원본 해시 | String | Y | 기대 해시값 |
| 6 | data[].calculated_hash | 계산 해시 | String | Y | 실제 해시값 |
| 7 | data[].completed_at | 처리 시간 | DateTime | Y | 검증 시도 시간 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 호기/zone 정보 조회 | - |
| 2 | FileProcessingRecord 조회 | integrity_verified = 0 |
| 3 | 결과 정렬 | 최신순 |
| 4 | 결과 JSON으로 반환 | ResponseEntity |

---

### SYS_005 - 무결성 검증 성공 이력 조회 API

| 프로그램 ID | SYS_005 | 프로그램명 | 무결성 검증 성공 이력 조회 API |
|------------|---------|----------|------------------------------|
| 분류 | 무결성 검증 | 처리유형 | 조회 |
| 클래스명 | DataController.java | 메서드명 | getIntegritySuccessHistory() |

▣ 기능 설명

파일 무결성 검증 성공 이력을 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | session.selectedZoneCode | 호기 코드 | String | N | 세션에서 자동 조회 |
| 2 | limit | 조회 건수 | Integer | N | 기본값: 100 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, 1: 실패 |
| 2 | data | 성공 이력 | List<Map> | Y | 무결성 검증 성공 목록 |
| 3 | data[].file_name | 파일명 | String | Y | 검증 성공 파일 |
| 4 | data[].file_size | 파일 크기 | Long | Y | 파일 사이즈 (bytes) |
| 5 | data[].original_hash | 해시값 | String | Y | 검증된 해시값 |
| 6 | data[].completed_at | 처리 시간 | DateTime | Y | 검증 완료 시간 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 호기/zone 정보 조회 | - |
| 2 | FileProcessingRecord 조회 | integrity_verified = 1 |
| 3 | 결과 정렬 | 최신순 |
| 4 | 결과 JSON으로 반환 | ResponseEntity |
