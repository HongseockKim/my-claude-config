# JavaScript 하이재킹 취약점 수정 계획

## 개요
| 항목 | 내용 |
|------|------|
| 취약점 | JavaScript Hijacking |
| 심각도 | Low (CVSS 3.7) |
| 탐지 URL | `/asset/grid-data-topology-switch-optimized` |
| 원인 | JSON 배열 직접 반환 + AJAX 헤더 검증 누락 |

---

## 수정 전략: 다층 방어

### 1단계: AjaxOnlyInterceptor 경로 추가 (즉시 적용)

**파일**: `src/main/java/com/otoones/otomon/config/WebMvcConfig.java`

**추가할 경로** (`.addPathPatterns()` 내):
```
"/asset/grid-data-topology-switch",
"/asset/grid-data-topology-switch-optimized",
"/data/grid-data-systemResource"
```

---

### 2단계: 응답 래핑 (근본 해결)

**대상 엔드포인트 7개**:

| # | 파일 | 메서드 | 라인 |
|---|------|--------|------|
| 1 | AssetController.java | selectGridDataAssetList | 551 |
| 2 | AssetController.java | selectGridDataTopologySwitchList | 614 |
| 3 | AssetController.java | selectGridDataTopologySwitchOptimized | 626 |
| 4 | TopologyPhysicalController.java | selectTopologySwitchList | 31 |
| 5 | TopologyPhysicalController.java | selectTopologySwitchAssetList | 47 |
| 6 | TopologyPhysicalController.java | selectRelatedAssetList | 84 |
| 7 | DataController.java | getGridDataSystemResource | 129 |

**변경 패턴**:
- 반환 타입: `List<...>` → `Map<String, Object>`
- 응답 형식: `{"ret": 0, "message": "조회 성공", "data": [...]}`

---

### 3단계: 클라이언트 JS 수정

**대상 파일**:
- `static/js/page.topology/topology_physical.js`
- `static/js/page.asset/asset_list.js` (해당 시)
- `static/js/page.data/system_resource.js` (해당 시)

**변경 패턴**:
- `response` → `response.data`

---

## 검증 방법

1. 빌드 후 실행
2. 브라우저에서 해당 페이지 접속
3. DevTools Network 탭에서 응답 형식 확인
4. 그리드 데이터 정상 표시 확인

---

## 역할 분담

| 역할 | 담당 |
|------|------|
| 수정할 코드 위치/내용 확인 | Claude |
| 실제 코드 수정 | 사용자 |
| 수정 결과 검토 | Claude |
