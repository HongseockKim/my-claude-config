# IP 마스킹 미적용 페이지 수정 플랜

> **작성일**: 2026-01-15
> **상태**: 🔄 계획 중
> **목표**: 읽기 전용 사용자에게 IP/MAC 주소 마스킹 일관 적용

---

## 1. 현재 상태

### 마스킹 시스템 구조
| 파일 | 역할 |
|------|------|
| `config/DataMaskinConfig.java` | 서버 설정 (enabled, usePost) |
| `js/global/data_masking.js` | 클라이언트 마스킹 유틸리티 |

### 마스킹 조건 (`data_masking.js:12-24`)
- 관리자 (`isAdmin`) → 마스킹 안함
- 쓰기/삭제 권한 (`canWrite`, `canDelete`) → 마스킹 안함
- 위 권한 모두 없음 → **마스킹 적용**

### 마스킹 형식
- **IP**: `192.168.1.100` → `192.168.***.**`
- **MAC**: `AA:BB:CC:DD:EE:FF` → `AA:BB:**:**:**:**`

---

## 2. 적용 현황 요약

| 구분 | 페이지 수 |
|------|----------|
| ✅ 마스킹 적용 | 5개 |
| ❌ 마스킹 미적용 | 6개 |

### ✅ 적용 완료 (5개)
- `/asset/operation` - 자산현황
- `/detection/connection` - 화이트리스트 위반 현황
- `/detection/timesData` - 이상 이벤트 탐지 현황
- `/detection/timeSereiseData` - 시계열 이종 데이터 분석
- `/detection/analysisAndAction` - 분석 및 조치 이력

### ❌ 미적용 (6개)
- `/asset/topology-physical` - 토폴로지맵
- `/asset/trafficAsset` - 자산별 트래픽 현황
- `/asset/gap` - 자산갭분석
- `/policy/sessionWhite` - 화이트리스트 정책
- `/setting/topology-switch` - 스위치 관리 (설정 페이지)

---

## 3. 수정 대상 파일 상세

### Phase 1: 토폴로지맵 (HIGH)

#### 파일 1: `static/js/page/asset/topologyPhysicalDetail.js`

| Line | 현재 코드 | 수정 방향 |
|------|----------|----------|
| 746 | `.text(device.ipAddress)` | `DataMaskingUtils.maskSensitiveData()` 적용 |
| 1100-1101 | `assetData.ipAddress = decodeBase64(...)` | 디코딩 후 마스킹 적용 |
| 1468 | `<span>${data.ipAddress}</span>` | 마스킹 적용 |
| 1472 | `<span>${data.macAddress || '-'}</span>` | 마스킹 적용 |
| 1648-1649 | `<td>${conn.srcIp || '-'}</td>` | 마스킹 적용 |

#### 파일 2: `static/js/page/asset/topologyPhysicalDetailFragment.js`

| Line | 현재 코드 | 수정 방향 |
|------|----------|----------|
| 617 | `.text(device.ipAddress)` | 마스킹 적용 |
| 947-948 | `assetData.ipAddress = decodeBase64(...)` | 디코딩 후 마스킹 적용 |
| 1290, 1294 | `<span>${data.ipAddress}</span>` | 마스킹 적용 |
| 1466-1467 | `<td>${conn.srcIp || '-'}</td>` | 마스킹 적용 |

---

### Phase 2: 자산별 트래픽 현황 (HIGH)

#### 파일: `static/js/page.traffic/trafficAsset.js`

**✅ 적용 완료:**
| Line | 현재 코드 | 상태 |
|------|----------|------|
| 197-203 | AG Grid `ipAddress` 컬럼 valueFormatter | ✅ 마스킹 적용됨 |
| 205-210 | AG Grid `macAddress` 컬럼 valueFormatter | ✅ 마스킹 적용됨 |
| 721-726 | AG Grid 연결상세 `srcIp` 컬럼 cellRenderer | ✅ 마스킹 적용됨 |
| 729-733 | AG Grid 연결상세 `dstIp` 컬럼 cellRenderer | ✅ 마스킹 적용됨 |

**❌ 미적용 (수정 필요):**
| Line | 현재 코드 | 수정 방향 |
|------|----------|----------|
| 410 | `$('#detailIpAddress').text(decodedIpAddress)` | 상세 헤더 IP 마스킹 적용 |
| 411 | `$('#detailMacAddress').text(decodedMacAddress \|\| '-')` | 상세 헤더 MAC 마스킹 적용 |

**⚠️ 엑셀 다운로드 관련 (검토 필요):**
| Line | 현재 코드 | 설명 |
|------|----------|------|
| 398-406 | `connectionDetails` srcIp/dstIp Base64 디코딩 | 원본 IP로 변환됨 |
| 431 | `currentConnectionDetails = data.connectionDetails` | 디코딩된 원본 IP 저장 |
| 874 | `JSON.stringify(currentConnectionDetails)` | 엑셀 다운로드 시 원본 IP 서버 전송 |

> **참고**: 엑셀 다운로드는 서버(`AssetController.exportDetailExcel`)에서 처리됨.
> 서버 측에서 마스킹 여부 확인 필요 (권한 없는 사용자의 엑셀에도 원본 IP 노출 가능성)

---

### Phase 3: 자산갭분석 (MEDIUM)

#### 파일: `static/js/page/asset/gap.js`

| Line | 현재 코드 | 수정 방향 |
|------|----------|----------|
| 129 | `{field: 'ipAddress', ...}` | `cellRenderer` 추가 |
| 130 | `{field: 'macAddress', ...}` | `cellRenderer` 추가 |
| 184-185 | `data?.ipAddress?.split(...)` | 표시 시 마스킹 적용 |

---

### Phase 4: 화이트리스트 정책 (MEDIUM)

#### 파일: `static/js/page.policy/sessionWhite.js`

| Line | 현재 코드 | 수정 방향 |
|------|----------|----------|
| 153-158 | AG Grid `srcIp` 컬럼 | `cellRenderer` 수정 |
| 160-165 | AG Grid `dstIp` 컬럼 | `cellRenderer` 수정 |
| 416-421 | 배지에 IP 직접 표시 | 마스킹 적용 |

---

### Phase 5: 스위치 관리 (LOW - 선택)

#### 파일: `static/js/page.setting/topologySwitch.js`

| Line | 현재 코드 | 수정 방향 |
|------|----------|----------|
| 153 | `value="${sw ? sw.ip : ''}"` | 설정 페이지라 권한자만 접근 (선택적 적용) |

---

## 4. 수정 패턴

### 4.1 AG Grid cellRenderer 추가

```javascript
// Before
{field: 'ipAddress', headerName: 'IP주소', flex: 1.2}

// After
{
    field: 'ipAddress',
    headerName: 'IP주소',
    flex: 1.2,
    cellRenderer: params => DataMaskingUtils.maskSensitiveData(params.value)
}
```

### 4.2 HTML 삽입 시 마스킹

```javascript
// Before
<span>${data.ipAddress}</span>

// After
<span>${DataMaskingUtils.maskSensitiveData(data.ipAddress)}</span>
```

### 4.3 SVG 텍스트 마스킹

```javascript
// Before
.text(device.ipAddress)

// After
.text(DataMaskingUtils.maskSensitiveData(device.ipAddress))
```

### 4.4 배지 마스킹

```javascript
// Before
<span class="badge bg-primary">${traffic.id.srcIp}</span>

// After
<span class="badge bg-primary">${DataMaskingUtils.maskSensitiveData(traffic.id.srcIp)}</span>
```

---

## 5. 작업 순서

| Phase | 파일 | 수정 건수 | 우선순위 |
|-------|------|----------|----------|
| 1 | topologyPhysicalDetail.js | ~10건 | HIGH |
| 1 | topologyPhysicalDetailFragment.js | ~10건 | HIGH |
| 2 | trafficAsset.js | ~6건 | HIGH |
| 3 | gap.js | ~4건 | MEDIUM |
| 4 | sessionWhite.js | ~6건 | MEDIUM |
| 5 | topologySwitch.js | ~2건 | LOW (선택) |

**총 수정 건수**: ~38건

---

## 6. 검증 방법

### 6.1 권한별 테스트

1. **읽기 전용 사용자 계정 생성/사용**
   - canRead만 있고 canWrite, canDelete 없는 그룹에 할당

2. **각 페이지 접속 후 IP 마스킹 확인**
   - IP가 `xxx.xxx.***.**` 형식으로 표시되는지 확인
   - MAC이 `XX:XX:**:**:**:**` 형식으로 표시되는지 확인

### 6.2 페이지별 확인 항목

| 페이지 | 확인 위치 |
|--------|----------|
| 토폴로지맵 | SVG 디바이스 라벨, 자산 상세 사이드바, 연결 상세 테이블 |
| 트래픽 현황 | AG Grid 목록, 상세 Offcanvas |
| 갭분석 | AG Grid 목록, 자산 상세 |
| 화이트리스트 정책 | AG Grid 목록, 트래픽 배지 |

### 6.3 관리자 계정 확인

- 관리자 계정으로 동일 페이지 접속
- IP/MAC이 마스킹 없이 원본으로 표시되는지 확인

---

## 7. 체크리스트

### Phase 1
- [ ] topologyPhysicalDetail.js 수정
- [ ] topologyPhysicalDetailFragment.js 수정
- [ ] 토폴로지맵 페이지 테스트

### Phase 2 ✅ 완료 (2026-01-15)
- [x] trafficAsset.js AG Grid 목록 마스킹 (ipAddress, macAddress)
- [x] trafficAsset.js 연결상세 Grid 마스킹 (srcIp, dstIp)
- [x] trafficAsset.js 상세 헤더 마스킹 (Line 410-411)
- [x] 엑셀 다운로드 - 권한 있는 사용자만 접근 가능 (추가 조치 불필요)
- [x] 연결상세 Grid 높이 CSS 수정 (#connectionDetailGrid: 400px)
- [x] 자산별 트래픽 현황 페이지 테스트

### Phase 3
- [ ] gap.js 수정
- [ ] 자산갭분석 페이지 테스트

### Phase 4
- [ ] sessionWhite.js 수정
- [ ] 화이트리스트 정책 페이지 테스트

### Phase 5 (선택)
- [ ] topologySwitch.js 수정 (필요시)

### 최종 검증
- [ ] 읽기 전용 사용자로 전체 페이지 마스킹 확인
- [ ] 관리자로 전체 페이지 원본 표시 확인
- [ ] 브라우저 콘솔 오류 없음 확인

---

## 8. 역할 분담

| 역할 | 담당 |
|------|------|
| 수정할 코드 위치/내용 안내 | Claude |
| 실제 코드 수정 | 사용자 |
| 수정 결과 검토 | Claude |
