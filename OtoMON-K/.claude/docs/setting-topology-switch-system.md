# 스위치 관리 (setting/topology-switch) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/setting/topology-switch` |
| **메뉴 ID** | 9000L |
| **권한** | READ/WRITE/DELETE |
| **한글명** | 스위치 관리 |
| **목적** | 네트워크 토폴로지용 스위치 정보 관리 (포트별 연결 IP, 자산 연동) |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/SettingController.java
Service:    src/main/java/com/otoones/otomon/service/TopologySwitchService.java
Template:   src/main/resources/templates/pages/setting/topology-switch.html
Model:      src/main/java/com/otoones/otomon/model/TopologySwitch.java
Repository: src/main/java/com/otoones/otomon/repository/TopologySwitchRepository.java
Mapper:     src/main/java/com/otoones/otomon/mapper/TopologySwitchMapper.java
```

---

## 컨트롤러 (SettingController.java)

### 페이지 렌더링 (`GET /setting/topology-switch`)

**위치**: `SettingController.java:194-202`

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| zone3List | 활성화된 호기 목록 (sp_03, sp_04) |

### CRUD API

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/setting/topology-switch/list/{zone3}` | 호기별 스위치 목록 조회 |
| POST | `/setting/topology-switch/save` | 스위치 저장 (생성/수정) |
| POST | `/setting/topology-switch/delete/{idx}` | 스위치 삭제 |

---

## 프론트엔드 (topology-switch.html)

### 페이지 레이아웃

```
┌─────────────────────────────────────────────────────────────────┐
│ 스위치 관리                                                      │
├─────────────────────────────────────────────────────────────────┤
│ [3호기] [4호기]  (탭)                                            │
├───────────────────────┬─────────────────────────────────────────┤
│ 스위치 목록    [추가] │ 스위치 상세                              │
├───────────────────────┼─────────────────────────────────────────┤
│ ┌───────────────────┐│ 스위치 명: [Switch-1          ]         │
│ │ Switch-1          ││ IP:        [192.168.1.1      ]          │
│ │ 192.168.1.1/24    ││ 서브넷:    [255.255.255.0    ]          │
│ │         [24포트] ││ 포트 수:   [24              ]          │
│ └───────────────────┘│                                          │
│ ┌───────────────────┐│ 포트 목록                                 │
│ │ Switch-2          ││ ┌────┬──────────────┬──────┬──────────┐ │
│ │ 192.168.1.2/24    ││ │포트│연결 IP       │연결포트│자산명    │ │
│ │         [24포트] ││ ├────┼──────────────┼──────┼──────────┤ │
│ └───────────────────┘││ │ 1 │[192.168.1.10]│[ 1 ] │PLC-01    │ │
│                       ││ │ 2 │[192.168.1.11]│[ 2 ] │HMI-01    │ │
│ 등록된 스위치가       ││ │...│              │      │          │ │
│ 없습니다.            ││ └────┴──────────────┴──────┴──────────┘ │
└───────────────────────┴─────────────────────────────────────────┘
│                                              [저장] [삭제]       │
└─────────────────────────────────────────────────────────────────┘
```

### 탭 구조 (호기별)

```html
<ul class="nav nav-tabs mb-3">
    <li th:each="zone,iterStat : ${zone3List}">
        <a class="nav-link" th:data-zone="${zone}"
           th:text="${zone == 'sp_03' ? '3호기' : (zone == 'sp_04' ? '4호기' : zone)}">
        </a>
    </li>
</ul>
```

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `loadSwitchList(zone)` | 호기별 스위치 목록 로드 |
| `renderSwitchList(zone, list)` | 스위치 목록 렌더링 |
| `selectSwitch(zone, idx)` | 스위치 선택 + 상세 표시 |
| `showSwitchForm(zone, sw)` | 스위치 폼 표시 (추가/수정) |
| `renderPortTable(zone, ports, portCount)` | 포트 테이블 렌더링 |
| `collectPortData(zone)` | 포트 데이터 수집 (저장용) |
| `saveSwitch()` | 스위치 저장 |
| `deleteSwitch()` | 스위치 삭제 |
| `resetDetailPanel(zone)` | 상세 패널 초기화 |

### IP Base64 처리

서버에서 받은 IP는 Base64 인코딩:
```javascript
// 목록 로드 시 디코딩
const decodedData = res.data.map(function(sw) {
    return {
        ...sw,
        ip: sw.ip ? atob(sw.ip) : null
    };
});

// 저장 시 인코딩
const data = {
    ip: switchIp ? btoa(switchIp) : '',
    portIpTagList: JSON.stringify(collectPortData(zone))
};
```

### 포트 테이블 필드

| 필드 | 설명 | 편집 |
|------|------|------|
| 포트 | 포트 번호 (1~48) | X |
| 연결 IP | 해당 포트에 연결된 장비 IP | O |
| 연결포트 | 연결된 스위치 포트 번호 | O |
| 자산명 | IP 기반 자산 자동 조회 | X |

---

## 모델 (TopologySwitch.java)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| idx | Long | idx | PK |
| zone1 | String | zone1 | 사업소 코드 (koen) |
| zone2 | String | zone2 | 발전소 코드 (samcheonpo) |
| zone3 | String | zone3 | 호기 코드 (sp_03, sp_04) |
| ip | String | ip | 스위치 IP |
| subnetMask | String | subnet_mask | 서브넷 마스크 (기본: 255.255.255.0) |
| name | String | name | 스위치 이름 |
| portIpTagList | String | port_ip_tag_list | 포트별 연결 정보 (JSON TEXT) |
| createAt | LocalDateTime | create_at | 생성일시 |
| updateAt | LocalDateTime | update_at | 수정일시 |

### portIpTagList JSON 구조

```json
[
  {
    "portNumber": 1,
    "connectedIp": "192.168.1.10",
    "connectedSwitchPort": 24
  },
  {
    "portNumber": 2,
    "connectedIp": "192.168.1.11",
    "connectedSwitchPort": null
  }
]
```

---

## 서비스 (TopologySwitchService.java)

### 주요 메서드

| 메서드 | 위치 | 설명 |
|--------|------|------|
| `getSwitchListByZone3WithAsset()` | 363줄 | 호기별 스위치 목록 (자산 연동) |
| `addTopologySwitch()` | 387줄 | 스위치 추가 |
| `editTopologySwitch()` | 395줄 | 스위치 수정 |
| `deleteTopologySwitch()` | 71줄 | 스위치 삭제 |
| `decodeTopologySwitchData()` | 408줄 | Base64 디코딩 |
| `parsePortsWithAsset()` | 474줄 | 포트 + 자산 정보 파싱 |
| `buildAssetIpMap()` | 434줄 | IP별 자산 매핑 |
| `selectTopologySwitchListWithPortStatus()` | 138줄 | 포트 상태 포함 조회 |

### Base64 인코딩/디코딩

**프론트 → 서버 (저장 시)**:
1. 스위치 IP: Base64 인코딩
2. 포트별 connectedIp: Base64 인코딩

**서버 → 프론트 (조회 시)**:
1. 스위치 IP: Base64 인코딩
2. 포트별 connectedIp: Base64 인코딩
3. 자산명 (assetName): Base64 인코딩

```java
// 저장 시 디코딩
private void decodeTopologySwitchData(TopologySwitch topologySwitch) {
    // 스위치 IP 디코딩
    String encodedIp = topologySwitch.getIp();
    if (encodedIp != null && !encodedIp.isEmpty()) {
        topologySwitch.setIp(new String(
            Base64.getDecoder().decode(encodedIp), StandardCharsets.UTF_8
        ));
    }

    // portIpTagList 내 connectedIp 디코딩
    // ...
}

// 조회 시 인코딩
private Map<String, Object> convertSwitchToMap(TopologySwitch sw) {
    map.put("ip", sw.getIp() != null
        ? Base64.getEncoder().encodeToString(sw.getIp().getBytes(StandardCharsets.UTF_8))
        : null
    );
}
```

### 자산 연동

포트에 연결된 IP로 자산을 자동 조회:

```java
private Map<String, Asset> buildAssetIpMap() {
    List<Asset> allAssets = assetRepository.findAll();
    Map<String, Asset> assetByIp = new HashMap<>();

    for (Asset asset : allAssets) {
        String ipAddress = asset.getIpAddress();
        // 쉼표/공백으로 구분된 IP 처리
        String[] ips = ipAddress.split("[,/\\s]+");
        for (String ip : ips) {
            assetByIp.put(ip.trim(), asset);
        }
    }
    return assetByIp;
}
```

### 포트 상태 계산

토폴로지 뷰에서 포트 색상 표시용:

| 상태 | 색상 | 자산 status |
|------|------|-------------|
| 정상 운전 | green | 1 |
| 정지 | grey | 0 |
| 장애 | red | 2 |
| 통신 장애 | orange | 3 |
| 자산 없음 | yellow | null |
| 미사용 | lightgray | IP 없음 |

---

## API 엔드포인트 요약

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/setting/topology-switch` | 페이지 렌더링 |
| GET | `/setting/topology-switch/list/{zone3}` | 호기별 스위치 목록 |
| POST | `/setting/topology-switch/save` | 스위치 저장 |
| POST | `/setting/topology-switch/delete/{idx}` | 스위치 삭제 |

---

## 데이터 흐름

### 페이지 로드

```
[Controller] /setting/topology-switch
         ↓
[Service] systemConfigService.getActiveZone3List()
         ↓
[Model] zone3List (sp_03, sp_04)
         ↓
[Template] 탭 렌더링
         ↓
[JS] loadSwitchList(firstZone)
         ↓
[AJAX] GET /setting/topology-switch/list/{zone3}
         ↓
[Service] getSwitchListByZone3WithAsset()
         ↓
[Repository] findAll() → Zone3Util.matches() 필터링
         ↓
[Service] buildAssetIpMap() → parsePortsWithAsset()
         ↓
[Response] JSON (IP Base64 인코딩)
         ↓
[JS] atob() 디코딩 → renderSwitchList()
```

### 스위치 저장

```
[Form] switchName, switchIp, subnetMask, portCount
         ↓
[JS] collectPortData() → 포트별 IP 수집
         ↓
[JS] btoa() → IP Base64 인코딩
         ↓
[AJAX] POST /setting/topology-switch/save
         ↓
[Controller] saveSwitch()
         ↓
[Service] idx null → addTopologySwitch() / else editTopologySwitch()
         ↓
[Service] decodeTopologySwitchData() → Base64 디코딩
         ↓
[Repository] save()
         ↓
[ActivityLog] 감사 로그 기록
         ↓
[JS] loadSwitchList() 새로고침
```

---

## 감사 로그

`@ActivityLog` 어노테이션으로 CRUD 작업 자동 기록:

| 작업 | category | action | resourceType |
|------|----------|--------|--------------|
| 생성 | SETTING | ADD | TOPOLOGY_SWITCH |
| 수정 | SETTING | UPDATE | TOPOLOGY_SWITCH |
| 삭제 | SETTING | DELETE | TOPOLOGY_SWITCH |

---

## 권한 처리

프론트엔드에서 권한에 따라 버튼 표시/숨김:

```html
<!-- 추가 버튼: WRITE 권한 -->
<button class="btn-add-switch" th:if="${userPermissions?.canWrite}">
    추가
</button>

<!-- 저장 버튼: WRITE 권한 -->
<button class="btn-save-switch" th:if="${userPermissions?.canWrite}">
    저장
</button>

<!-- 삭제 버튼: DELETE 권한 -->
<button class="btn-delete-switch" th:if="${userPermissions?.canDelete}">
    삭제
</button>
```

---

## 다국어 메시지

| 메시지 키 | 설명 |
|----------|------|
| `menu.setting.topologySwitch` | 페이지 제목 |
| `setting.switch.header.title` | 스위치 목록 카드 제목 |
| `setting.switch.add.btn` | 추가 버튼 |
| `setting.switch.detail.title` | 스위치 상세 제목 |
| `setting.switch.detail.save.btn` | 저장 버튼 |
| `setting.switch.detail.deleted.btn` | 삭제 버튼 |
| `setting.switch.delete.confirm.message` | 삭제 확인 메시지 |
| `setting.switch.empty.switch.message` | 빈 목록 메시지 |
| `setting.switch.form.*` | 폼 라벨/플레이스홀더 |

---

## 연동 시스템

### 물리 토폴로지 페이지

`/asset/topologyPhysical` 페이지에서 스위치 정보를 활용:
- `selectTopologySwitchListWithPortStatus()` 호출
- 포트별 상태 색상 표시
- 자산 연결 시각화

### 자산 현황

포트에 연결된 IP로 자산 자동 조회:
- Asset 테이블의 ipAddress 컬럼과 매칭
- 시스템명 (systemName) 표시

---

## 보안 고려사항

1. **IP Base64 인코딩**: 서버-클라이언트 간 IP 주소 보호
2. **CSRF 토큰**: POST 요청에 자동 포함 (jQuery ajaxSetup)
3. **권한 체크**: WRITE/DELETE 권한 분리

---

## 관련 문서

- [물리 토폴로지](topology-physical-system.md) - 스위치 시각화
- [자산현황](asset-operation-spec.md) - 자산 연동
- [감사 로그](audit-log-system.md) - 변경 이력

---

## 프로그램 명세서

### STS_001 - 스위치 관리 페이지

| 프로그램 ID | STS_001 | 프로그램명 | 스위치 관리 페이지 |
|------------|---------|----------|-----------------|
| 분류 | 설정 관리 | 처리유형 | 화면 |
| 클래스명 | SettingController.java | 메서드명 | topologySwitchPage() |

▣ 기능 설명

네트워크 토폴로지용 스위치 정보를 관리하는 페이지를 렌더링한다. 호기별 탭으로 구분되며, 스위치 목록과 포트별 연결 정보를 관리한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 파라미터 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | zone3List | 호기 목록 | List<String> | Y | 활성화된 호기 (sp_03, sp_04) |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | @RequirePermission(menuId = 9000L) |
| 2 | 활성화된 호기 목록 조회 | getActiveZone3List() |
| 3 | Model에 zone3List 추가 | - |
| 4 | 뷰 반환 | pages/setting/topology-switch |

---

### STS_002 - 호기별 스위치 목록 조회 API

| 프로그램 ID | STS_002 | 프로그램명 | 호기별 스위치 목록 조회 API |
|------------|---------|----------|--------------------------|
| 분류 | 스위치 조회 | 처리유형 | 조회 |
| 클래스명 | SettingController.java | 메서드명 | getSwitchList() |

▣ 기능 설명

특정 호기에 등록된 스위치 목록을 조회한다. 각 스위치의 포트별 연결 IP와 연동된 자산 정보를 함께 반환한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | zone3 | 호기 코드 | String | Y | PathVariable (sp_03, sp_04) |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공 |
| 2 | data | 스위치 목록 | List<Map> | Y | 스위치 정보 |
| 3 | data[].idx | 스위치 ID | Long | Y | PK |
| 4 | data[].name | 스위치명 | String | Y | - |
| 5 | data[].ip | 스위치 IP | String | Y | Base64 인코딩 |
| 6 | data[].subnetMask | 서브넷 마스크 | String | Y | - |
| 7 | data[].portCount | 포트 수 | Integer | Y | 포트 개수 |
| 8 | data[].ports | 포트 목록 | List<Map> | Y | 포트별 연결 정보 |
| 9 | data[].ports[].portNumber | 포트 번호 | Integer | Y | 1~48 |
| 10 | data[].ports[].connectedIp | 연결 IP | String | N | Base64 인코딩 |
| 11 | data[].ports[].connectedSwitchPort | 연결 포트 | Integer | N | - |
| 12 | data[].ports[].assetName | 자산명 | String | N | Base64 인코딩 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | zone3으로 스위치 목록 조회 | findAll() + Zone3Util.matches() |
| 2 | 전체 자산 IP 맵 생성 | buildAssetIpMap() |
| 3 | 각 스위치의 portIpTagList 파싱 | JSON 파싱 |
| 4 | 포트별 자산 매칭 | IP로 자산 조회 |
| 5 | IP/자산명 Base64 인코딩 | 보안 처리 |
| 6 | 결과 반환 | JSON 응답 |

▣ IP 인코딩 규칙

| 필드 | 방향 | 처리 |
|------|------|------|
| ip | 서버 → 프론트 | Base64 인코딩 |
| connectedIp | 서버 → 프론트 | Base64 인코딩 |
| assetName | 서버 → 프론트 | Base64 인코딩 |

---

### STS_003 - 스위치 저장 API

| 프로그램 ID | STS_003 | 프로그램명 | 스위치 저장 API |
|------------|---------|----------|---------------|
| 분류 | 스위치 관리 | 처리유형 | 등록/수정 |
| 클래스명 | SettingController.java | 메서드명 | saveSwitch() |

▣ 기능 설명

스위치 정보를 저장한다. idx가 없으면 신규 등록, 있으면 수정 처리한다. IP는 Base64 디코딩 후 저장한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 스위치 ID | Long | N | null이면 신규 |
| 2 | zone3 | 호기 코드 | String | Y | sp_03, sp_04 |
| 3 | name | 스위치명 | String | Y | - |
| 4 | ip | 스위치 IP | String | Y | Base64 인코딩 |
| 5 | subnetMask | 서브넷 마스크 | String | Y | 기본: 255.255.255.0 |
| 6 | portCount | 포트 수 | Integer | Y | 8/16/24/48 |
| 7 | portIpTagList | 포트 연결 정보 | String | N | JSON 문자열 |

▣ portIpTagList 구조

```json
[
  {
    "portNumber": 1,
    "connectedIp": "MTkyLjE2OC4xLjEw",  // Base64
    "connectedSwitchPort": 24
  }
]
```

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |
| 3 | data | 저장된 스위치 | TopologySwitch | N | 성공 시 스위치 정보 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | Base64 디코딩 | decodeTopologySwitchData() |
| 3 | 스위치 IP 디코딩 | ip 필드 |
| 4 | portIpTagList 내 connectedIp 디코딩 | 각 포트 IP |
| 5 | zone1, zone2 자동 설정 | koen, samcheonpo |
| 6 | idx 분기 | null → add / else → edit |
| 7 | 저장 | topologySwitchRepository.save() |
| 8 | 감사 로그 기록 | @ActivityLog(ADD/UPDATE) |
| 9 | 결과 반환 | JSON 응답 |

▣ Base64 디코딩 처리

| 단계 | 대상 | 처리 |
|------|------|------|
| 1 | ip | Base64 → 평문 IP |
| 2 | portIpTagList.connectedIp | 각 포트 IP Base64 → 평문 |

---

### STS_004 - 스위치 삭제 API

| 프로그램 ID | STS_004 | 프로그램명 | 스위치 삭제 API |
|------------|---------|----------|---------------|
| 분류 | 스위치 관리 | 처리유형 | 삭제 |
| 클래스명 | SettingController.java | 메서드명 | deleteSwitch() |

▣ 기능 설명

스위치를 삭제한다. 관련 포트 연결 정보도 함께 삭제된다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | idx | 스위치 ID | Long | Y | PathVariable |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | DELETE 권한 필요 |
| 2 | 스위치 존재 확인 | findById() |
| 3 | 스위치 삭제 | deleteById() |
| 4 | 감사 로그 기록 | @ActivityLog(DELETE) |
| 5 | 결과 반환 | JSON 응답 |

---

▣ 포트 상태 코드 (물리 토폴로지 연동)

| 상태 | 색상 | 자산 status | 설명 |
|------|------|-------------|------|
| 정상 운전 | green | 1 | 자산 정상 운전 중 |
| 정지 | grey | 0 | 자산 정지 상태 |
| 장애 | red | 2 | 자산 장애 발생 |
| 통신 장애 | orange | 3 | 통신 두절 |
| 자산 없음 | yellow | null | IP 있으나 자산 미등록 |
| 미사용 | lightgray | - | 포트에 IP 미할당 |

▣ 자산 연동 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 전체 자산 조회 | assetRepository.findAll() |
| 2 | IP별 자산 맵 생성 | ipAddress → Asset |
| 3 | 쉼표/공백 구분 IP 처리 | 복수 IP 지원 |
| 4 | 포트 connectedIp로 자산 조회 | 자동 매칭 |
| 5 | 자산명(systemName) 반환 | Base64 인코딩 |

