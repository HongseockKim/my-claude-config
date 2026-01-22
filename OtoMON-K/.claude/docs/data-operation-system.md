# 운전정보 (data/operation) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/data/operation` |
| **메뉴 ID** | - (권한 체크 없음) |
| **한글명** | 운전정보 |
| **목적** | 발전소 운전 데이터(발전출력, 터빈속도, DROP 신호) 호기별 조회 |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/DataController.java
Service:    src/main/java/com/otoones/otomon/service/DataService.java
Template:   src/main/resources/templates/pages/data/operation.html
Model:      src/main/java/com/otoones/otomon/model/OpTag.java
Repository: src/main/java/com/otoones/otomon/repository/OpTagRepository.java
```

---

## 컨트롤러 (DataController.java)

### 페이지 렌더링 (`GET /data/operation`)

**위치**: `DataController.java:76-112`

**주요 로직**:
1. 세션에서 호기/날짜 정보 가져오기
2. 호기 코드 변환 (sp_03 → "3", sp_04 → "4")
3. system_config에서 zone1, zone2 가져오기
4. DataService 호출하여 데이터 조회
5. Model에 데이터 추가

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| opList | 운전정보 데이터 리스트 |
| selectedUnit | 선택된 호기 코드 |
| dateRangeType | 날짜 범위 타입 (7d/1m/3m) |
| startDate | 시작 날짜 |
| endDate | 종료 날짜 |

### 운전정보 API (`GET /data/api/operations`)

**위치**: `DataController.java:262-329`

**파라미터**:
| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| startDate | 세션값 또는 7일 전 | 시작 날짜 |
| endDate | 세션값 또는 오늘 | 종료 날짜 |
| page | 0 | 페이지 번호 |
| size | 100 | 페이지 크기 |

**응답 형식**:
```json
{
  "success": true,
  "data": [...],
  "totalCount": 100,
  "startDate": "2025-12-22",
  "endDate": "2025-12-29",
  "message": "조회 성공"
}
```

---

## 서비스 (DataService.java)

### `getOpTagsByZoneAndDateRange()` - 위치: 73줄

호기와 날짜 범위로 OpTag 데이터 조회

```java
public Map<String, Object> getOpTagsByZoneAndDateRange(
    String zone1,
    String zone2,
    String zone3,
    String startDateStr,
    String endDateStr
)
```

**처리 로직**:
1. 날짜 문자열 → LocalDateTime 변환 (기본값: 최근 7일)
2. zone3가 null이면 전체 호기 조회
3. zone3 형식 호환 처리 ("3" ↔ "sp_03", "4" ↔ "sp_04")
4. 조회 결과를 Map에 담아 반환

---

## 모델 (OpTag.java)

운전정보 데이터 엔티티

### 필드 구성

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| idx | Long | idx | PK (자동 생성) |
| tagValue | String | tagValue | JSON 형식 태그 값 |
| detectedAt | LocalDateTime | detectedAt | 탐지 시간 |
| zoneInfo | ZoneInfo | (Embedded) | zone1, zone2, zone3 |
| createdAt | LocalDateTime | createdAt | 생성 시간 |

### tagValue JSON 구조

```json
[
  { "nodeId": "ns=1;s=SP03_GENMW", "value": 882 },
  { "nodeId": "ns=1;s=SP03_SPDSEL", "value": 1943 },
  { "nodeId": "ns=1;s=SP03_DROP1", "value": 0 },
  { "nodeId": "ns=1;s=SP03_DROP2", "value": 0 },
  ...
]
```

### 태그 의미

| 태그 패턴 | 의미 | 단위 |
|-----------|------|------|
| SP0X_GENMW | 발전출력 (Generator Megawatt) | MW |
| SP0X_SPDSEL | 터빈 회전속도 (Speed Select) | RPM |
| SP0X_DROP* | 디지털 출력 신호 (0=정상, 1=경보/트립) | - |

### DROP 신호 범위

| 범위 | 의미 |
|------|------|
| DROP1~24 | 주요 보호 계전기 신호 |
| DROP31~32 | 보조 계전기 신호 |
| DROP51~74 | 터빈 관련 신호 |
| DROP81~82 | 발전기 관련 신호 |
| DROP160~221 | 기타 보조 시스템 신호 |

---

## 프론트엔드 (operation.html)

### 핵심 기능

1. **호기별 그리드 분리**: 데이터를 호기별로 그룹핑하여 별도 그리드 표시
2. **요약 정보 표시**: 평균/최대/최소 출력, 데이터 건수
3. **상태 뱃지**: 출력량에 따른 상태 표시 (고부하/중부하/저부하/정지)
4. **경보 표시**: DROP 신호 활성화 시 경보 카운트 표시

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `groupByUnit(data)` | 데이터를 호기별로 그룹핑 (Lodash 사용) |
| `createGridContainers(units)` | 호기별 그리드 컨테이너 HTML 생성 |
| `initializeUnitGrids(unitGroups)` | 호기별 AG Grid 초기화 |
| `displayUnitSummary(unit)` | 호기별 요약 정보 표시 |
| `initializeAllGrids()` | 전체 그리드 초기화 |
| `getColumnDefs(unitCode)` | 컬럼 정의 반환 |

### AG Grid 컬럼 정의

| 컬럼명 | 필드 | 너비 | 설명 |
|--------|------|------|------|
| 시간 | createdAt | 120 | moment.js 포맷팅 |
| 발전정보 | tagValue | 300 | 출력(MW), 속도(RPM), 경보 표시 |
| 상태 | status | 120 | 고부하/중부하/저부하/정지 뱃지 |
| 경보 | alarmCount | 100 | DROP 활성화 개수 |

### 부하 상태 기준

| 상태 | 조건 | 뱃지 색상 |
|------|------|----------|
| 고부하 | > 800 MW | bg-success (초록) |
| 중부하 | > 400 MW | bg-warning (노랑) |
| 저부하 | > 0 MW | bg-info (청록) |
| 정지 | 0 MW | bg-secondary (회색) |

### 데이터 초기화

```javascript
const initialOperationList = /*[[${opList}]]*/ [];
const selectedUnit = /*[[${selectedUnit}]]*/ 'all';
const dateRangeType = /*[[${dateRangeType}]]*/ '7d';
const startDate = /*[[${startDate}]]*/ '';
const endDate = /*[[${endDate}]]*/ '';
```

### 이벤트 리스너

```javascript
window.addEventListener('storage', function(e) {
    if (e.key === 'dateRangeChanged' || e.key === 'unitChanged') {
        location.reload();
    }
});
```

---

## API 엔드포인트 요약

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/data/operation` | 페이지 렌더링 |
| GET | `/data/api/operations` | 운전정보 데이터 API |
| GET | `/data/grid-data-operation` | 전체 운전정보 조회 |

---

## 데이터 흐름

```
[세션] selectedZoneCode, startDateTime, endDateTime
         ↓
[Controller] 호기 코드 변환 (sp_03 → "3")
         ↓
[Service] getOpTagsByZoneAndDateRange()
         ↓
[Repository] opTagRepository.findAllByZoneInfo*AndCreatedAtBetween()
         ↓
[Model] OpTag 리스트
         ↓
[Frontend] groupByUnit() → 호기별 분리
         ↓
[AG Grid] 호기별 그리드 표시
```

---

## 호기 코드 변환

| 세션 값 | DB 조회 값 | 설명 |
|---------|-----------|------|
| sp_03 | "3" 또는 "sp_03" | 3호기 |
| sp_04 | "4" 또는 "sp_04" | 4호기 |
| all / null | 전체 | 모든 호기 |

※ 구형/신형 데이터 모두 호환을 위해 두 형식 모두 조회

---

## 사용 라이브러리

| 라이브러리 | 버전 | 용도 |
|-----------|------|------|
| Lodash | - | 데이터 그룹핑, 집계 |
| Moment.js | - | 날짜 포맷팅 (한국어) |
| AG Grid Community | - | 데이터 그리드 표시 |

---

## 그리드 스타일

```css
#operationGrid {
    height: 600px;
    width: 100%;
}

.unit-grid-wrapper {
    border: 1px solid #495057;
    border-radius: 8px;
    padding: 20px;
    background: #2d353c;
}
```

호기별 행 배경색:
- SP03: `rgba(13, 110, 253, 0.05)` (파란 톤)
- SP04: `rgba(25, 135, 84, 0.05)` (초록 톤)
- SP05: `rgba(255, 193, 7, 0.05)` (노란 톤)
- SP06: `rgba(220, 53, 69, 0.05)` (빨간 톤)

---

## 요약 정보 표시

각 호기 그리드 상단에 표시:
- 평균 출력 (MW)
- 최대 출력 (MW)
- 최소 출력 (MW)
- 데이터 건수

```javascript
const summary = {
    avgPower: _.meanBy(allTags.filter(t => t.nodeId.includes('GENMW')), 'value'),
    maxPower: _.maxBy(allTags.filter(t => t.nodeId.includes('GENMW')), 'value')?.value,
    minPower: _.minBy(allTags.filter(t => t.nodeId.includes('GENMW')), 'value')?.value,
    totalAlarms: _.sumBy(allTags.filter(t => t.nodeId.includes('DROP')), 'value'),
    dataCount: unit.data.length
};
```

---

## 관련 문서

- [세션 필터링](session-filtering.md) - 날짜/호기 필터링
- [프론트엔드 패턴](frontend-patterns.md) - AG Grid 패턴
- [시계열 이종 데이터 분석](detection-timesereise-system.md) - 시계열 데이터 표시

---

## 프로그램 명세서

### OPR_001 - 운전정보 페이지

| 프로그램 ID | OPR_001 | 프로그램명 | 운전정보 페이지 |
|------------|---------|----------|----------------|
| 분류 | 데이터 조회 | 처리유형 | 화면 |
| 클래스명 | DataController.java | 메서드명 | operationPage() |

▣ 기능 설명

발전소 운전 데이터(발전출력, 터빈속도, DROP 신호)를 호기별로 조회하는 페이지를 렌더링한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | session.selectedZoneCode | 호기 코드 | String | N | 세션에서 자동 조회 |
| 2 | session.startDateTime | 시작일시 | String | N | 세션에서 자동 조회 |
| 3 | session.endDateTime | 종료일시 | String | N | 세션에서 자동 조회 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | opList | 운전정보 리스트 | List<OpTag> | Y | 호기별 운전정보 데이터 |
| 2 | selectedUnit | 선택 호기 | String | Y | 선택된 호기 코드 |
| 3 | dateRangeType | 날짜 범위 타입 | String | Y | 7d/1m/3m |
| 4 | startDate | 시작 날짜 | String | Y | 조회 시작일 |
| 5 | endDate | 종료 날짜 | String | Y | 조회 종료일 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 호기/날짜 정보 조회 | SessionHelper 사용 |
| 2 | 호기 코드 변환 | sp_03→"3", sp_04→"4" |
| 3 | system_config에서 zone1, zone2 조회 | - |
| 4 | DataService 호출하여 데이터 조회 | getOpTagsByZoneAndDateRange() |
| 5 | Model에 데이터 추가 및 뷰 반환 | pages/data/operation |

---

### OPR_002 - 운전정보 데이터 조회 API

| 프로그램 ID | OPR_002 | 프로그램명 | 운전정보 데이터 조회 API |
|------------|---------|----------|------------------------|
| 분류 | 데이터 조회 | 처리유형 | 조회 |
| 클래스명 | DataController.java | 메서드명 | getOperationData() |

▣ 기능 설명

운전정보 데이터를 API로 조회한다. 날짜 범위와 페이지네이션을 지원한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | startDate | 시작 날짜 | String | N | 기본값: 세션값 또는 7일 전 |
| 2 | endDate | 종료 날짜 | String | N | 기본값: 세션값 또는 오늘 |
| 3 | page | 페이지 번호 | Integer | N | 기본값: 0 |
| 4 | size | 페이지 크기 | Integer | N | 기본값: 100 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공 여부 | Boolean | Y | true/false |
| 2 | data | 데이터 리스트 | List<OpTag> | Y | 운전정보 목록 |
| 3 | totalCount | 총 건수 | Long | Y | 전체 데이터 수 |
| 4 | startDate | 시작일 | String | Y | 조회 시작일 |
| 5 | endDate | 종료일 | String | Y | 조회 종료일 |
| 6 | message | 메시지 | String | Y | 처리 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 날짜 파라미터 검증 및 기본값 설정 | 세션값 우선 |
| 2 | 세션에서 호기/zone 정보 조회 | - |
| 3 | DataService 호출하여 데이터 조회 | 페이지네이션 적용 |
| 4 | 결과 Map으로 반환 | JSON 형식 |

---

### OPR_003 - 전체 운전정보 조회

| 프로그램 ID | OPR_003 | 프로그램명 | 전체 운전정보 조회 |
|------------|---------|----------|-------------------|
| 분류 | 데이터 조회 | 처리유형 | 조회 |
| 클래스명 | DataController.java | 메서드명 | getGridDataOperation() |

▣ 기능 설명

프론트엔드 AG Grid에서 사용하는 전체 운전정보 데이터를 조회한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | session.selectedZoneCode | 호기 코드 | String | N | 세션에서 자동 조회 |
| 2 | session.startDateTime | 시작일시 | String | N | 세션에서 자동 조회 |
| 3 | session.endDateTime | 종료일시 | String | N | 세션에서 자동 조회 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | success | 성공 여부 | Boolean | Y | true/false |
| 2 | data | 데이터 리스트 | List<OpTag> | Y | 전체 운전정보 목록 |
| 3 | message | 메시지 | String | Y | 처리 결과 메시지 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 세션에서 호기/날짜 정보 조회 | SessionHelper 사용 |
| 2 | zone 정보 변환 | sp_03→"3", sp_04→"4" |
| 3 | DataService 호출하여 전체 데이터 조회 | 페이지네이션 없음 |
| 4 | 결과 Map으로 반환 | JSON 형식 |
