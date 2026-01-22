# 시스템 설정 (setting/systemConfig) 시스템

## 개요

| 항목 | 내용 |
|------|------|
| **URL** | `/setting/systemConfig` |
| **메뉴 ID** | 9000L |
| **권한** | READ/WRITE |
| **한글명** | 시스템 설정 |
| **목적** | 사업소/발전소/호기 기본 설정 관리 (zone1, zone2, zone3) |

---

## 파일 구조

```
Controller: src/main/java/com/otoones/otomon/controller/SettingController.java
Service:    src/main/java/com/otoones/otomon/service/SystemConfigService.java
Template:   src/main/resources/templates/pages/setting/systemConfig.html
Model:      src/main/java/com/otoones/otomon/model/SystemConfig.java
Repository: src/main/java/com/otoones/otomon/repository/SystemConfigRepository.java
DTO:        src/main/java/com/otoones/otomon/dto/SystemConfigRequest.java
```

---

## 컨트롤러 (SettingController.java)

### 페이지 렌더링 (`GET /setting/systemConfig`)

**위치**: `SettingController.java:425-434`

**권한**:
```java
@RequirePermission(menuId = 9000L)
```

**모델 속성**:
| 속성명 | 설명 |
|--------|------|
| configs | 시스템 설정 목록 (List<SystemConfig>) |
| codesMap | 설정별 코드 목록 (Map<String, List<Code>>) |

### 저장 API (`POST /setting/systemConfig/save`)

**위치**: `SettingController.java:436-462`

**권한**:
```java
@RequirePermission(menuId = 9000L, resourceType = ResourceType.MENU, permissionType = PermissionType.WRITE)
```

**요청 본문**:
```json
{
  "configs": {
    "zone1": "koen",
    "zone2": "samcheonpo",
    "zone3": ["sp_03", "sp_04"]
  }
}
```

---

## 프론트엔드 (systemConfig.html)

### 페이지 레이아웃

```
┌─────────────────────────────────────────────────────────────────┐
│ 시스템 설정                                                      │
├─────────────────────────────────────────────────────────────────┤
│ 사업소 설정                                              [저장]  │
├─────────────────────────────────────────────────────────────────┤
│ 사업소                                                          │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ [한국동서발전                                          ▼] │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ 발전소                                                          │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ [삼천포발전소                                          ▼] │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ 호기                                                            │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ [✓] 3호기    [✓] 4호기                                     │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 설정 필드

| 필드 | configKey | 타입 | 설명 |
|------|-----------|------|------|
| 사업소 | zone1 | select | 단일 선택 (코드 테이블) |
| 발전소 | zone2 | select | 단일 선택 (코드 테이블) |
| 호기 | zone3 | checkbox | 다중 선택 (JSON 배열) |

### 주요 JavaScript 함수

| 함수명 | 역할 |
|--------|------|
| `createZone3CheckboxesFromServer()` | zone3 체크박스 동적 생성 |
| `saveSystemConfig()` | 시스템 설정 저장 |

### zone3 체크박스 생성

```javascript
function createZone3CheckboxesFromServer() {
    const checkboxContainer = document.getElementById('zone3-checkboxes');
    checkboxContainer.innerHTML = '';

    for (let code of allZone3Codes) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = 'zone3-' + code.code;
        checkbox.value = code.code;
        checkbox.name = 'zone3';

        // 저장된 값과 일치하면 체크
        if (currentZone3Values.includes(code.code)) {
            checkbox.checked = true;
        }
    }
}
```

### 저장 요청

```javascript
function saveSystemConfig() {
    const configData = {};

    // zone1, zone2 값 수집
    configData.zone1 = document.getElementById('config-zone1').value;
    configData.zone2 = document.getElementById('config-zone2').value;

    // zone3 값 수집 (체크된 체크박스)
    const zone3Checkboxes = document.querySelectorAll('[name="zone3"]:checked');
    const zone3Values = [];
    zone3Checkboxes.forEach(checkbox => {
        zone3Values.push(checkbox.value);
    });

    // 최소 1개 호기 필수
    if (zone3Values.length === 0) {
        alert('최소 1개 이상의 호기가 활성화되어야 합니다.');
        return;
    }

    configData.zone3 = zone3Values;

    $.ajax({
        url: '/setting/systemConfig/save',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({configs: configData})
    });
}
```

---

## 모델 (SystemConfig.java)

| 필드 | 타입 | 컬럼명 | 설명 |
|------|------|--------|------|
| id | Long | id | PK |
| configKey | String | config_key | 설정 키 (zone1, zone2, zone3) (unique) |
| configValue | String | config_value | 설정 값 (TEXT, JSON 가능) |
| configName | String | config_name | 설정명 (표시용) |
| description | String | description | 설명 |
| updatedAt | LocalDate | updated_at | 수정일 |

### 편의 메서드

```java
// zone 설정인지 확인
public boolean isZoneConfig() {
    return configKey != null && configKey.startsWith("zone");
}

// JSON 형식 값인지 확인
public boolean isJsonValue() {
    return configValue != null &&
           (configValue.startsWith("[") || configValue.startsWith("{"));
}
```

---

## 서비스 (SystemConfigService.java)

### 주요 메서드

| 메서드 | 위치 | 설명 |
|--------|------|------|
| `getZone1()` | 32줄 | zone1 값 조회 |
| `getZone2()` | 42줄 | zone2 값 조회 |
| `getActiveZone3List()` | 66줄 | 활성화된 zone3 목록 조회 |
| `getSystemConfig()` | 92줄 | 설정별 코드 목록 조회 |
| `getSystemConfigWidthCode()` | 116줄 | 설정 + 코드 맵 조회 |
| `saveSystemConfig()` | 131줄 | 시스템 설정 저장 |
| `logSystemConfigChange()` | 204줄 | 변경 로그 기록 |

### zone3 목록 조회

```java
public List<String> getActiveZone3List() {
    SystemConfig zone3Config = systemConfigRepository
            .findByConfigKey("zone3")
            .orElse(null);

    if (zone3Config == null || zone3Config.getConfigValue() == null) {
        return Collections.emptyList();
    }

    String jsonValue = zone3Config.getConfigValue();
    if (jsonValue.startsWith("[")) {
        // JSON 배열 형식: ["sp_03","sp_04"]
        String cleaned = jsonValue.replaceAll("[\\[\\]\"]", "");
        return Arrays.asList(cleaned.split(","));
    } else {
        // 단일 값 형식: sp_03
        return Collections.singletonList(jsonValue.trim());
    }
}
```

### 저장 시 검증 로직

```java
@Transactional
public void saveSystemConfig(Map<String, Object> configData, HttpSession session) {
    for (Map.Entry<String, Object> entry : configData.entrySet()) {
        String key = entry.getKey();
        Object value = entry.getValue();

        if ("zone3".equals(key) && value instanceof List) {
            List<String> codeListValue = (List<String>) value;

            // 1. 최소 1개 호기 필수
            if (codeListValue == null || codeListValue.isEmpty()) {
                throw new RuntimeException("활성화된 호기가 필요합니다.");
            }

            // 2. 현재 선택된 호기가 비활성화되지 않도록 체크
            String currentSelectedZoneCode = (String) session.getAttribute("selectedZoneCode");
            if (currentSelectedZoneCode != null && !codeListValue.contains(currentSelectedZoneCode)) {
                throw new RuntimeException("현재 선택된 호기는 비활성화할 수 없습니다.");
            }

            // JSON 배열로 저장
            String jsonValue = objectMapper.writeValueAsString(value);
            config.setConfigValue(jsonValue);
        }
    }
}
```

### 감사 로그 기록

```java
@Transactional(propagation = Propagation.REQUIRES_NEW)
public void logSystemConfigChange(Map<String, Object> configData, Map<String, String> beforeData) {
    Map<String, Object> detailsMap = new HashMap<>();
    Map<String, Object> changes = new HashMap<>();
    boolean hasChanges = false;

    for (Map.Entry<String, Object> entry : configData.entrySet()) {
        String key = entry.getKey();
        String newValue = ...;
        String oldValue = beforeData.get(key);

        changes.put(key, Map.of("before", oldValue, "after", newValue));

        if (oldValue == null || !oldValue.equals(newValue)) {
            hasChanges = true;
        }
    }

    detailsMap.put("action", hasChanges ? "설정 변경" : "설정 확인");
    detailsMap.put("changes", changes);

    systemActivityLogService.logUserAction(
        "SYS_CONFIG",
        hasChanges ? "UPDATE" : "VIEW",
        "SYS_CONFIG",
        String.join(",", configData.keySet()),
        hasChanges ? "설정 변경" : "설정 확인",
        detailsJson
    );
}
```

---

## API 엔드포인트 요약

| 메서드 | URL | 권한 | 설명 |
|--------|-----|------|------|
| GET | `/setting/systemConfig` | 9000L READ | 페이지 렌더링 |
| POST | `/setting/systemConfig/save` | 9000L WRITE | 설정 저장 |

---

## 데이터 흐름

### 페이지 로드

```
[Controller] /setting/systemConfig
         ↓
[Service] getSystemConfigWidthCode()
         ↓
[Repository] findAll() → SystemConfig 목록
         ↓
[Service] getSystemConfig() → 설정별 코드 목록
         ↓
[Repository] codeRepository.findByTypeCode() / findByTypeCodeAndParentCode()
         ↓
[Model] configs, codesMap
         ↓
[Template] 드롭다운/체크박스 렌더링
         ↓
[JS] createZone3CheckboxesFromServer() → zone3 체크박스 생성
```

### 설정 저장

```
[Form] zone1 select, zone2 select, zone3 checkboxes
         ↓
[JS] saveSystemConfig() → configData 수집
         ↓
[AJAX] POST /setting/systemConfig/save
         ↓
[Controller] saveSystemConfig()
         ↓
[Service] 저장 전 beforeData 수집
         ↓
[Service] saveSystemConfig()
    ├─ zone3 최소 1개 검증
    ├─ 현재 선택 호기 비활성화 방지
    └─ 각 설정 저장 (JSON 형식 포함)
         ↓
[Service] logSystemConfigChange() → 감사 로그
         ↓
[Response] success + message
         ↓
[JS] location.reload()
```

---

## 시스템 전역 영향

### zone3 활성화 설정의 영향

| 영향 범위 | 설명 |
|----------|------|
| 헤더 호기 선택 | 활성화된 호기만 선택 가능 |
| 스위치 관리 탭 | 활성화된 호기만 탭 표시 |
| 토폴로지 뷰 | 활성화된 호기만 표시 |
| 데이터 조회 | zone3 필터에 활성 호기만 사용 |

### 세션 연동

```java
// InterceptorConfig에서 세션에 zone3 저장
session.setAttribute("selectedZoneCode", zone3Code);

// 저장 시 현재 선택 호기 보호
String currentSelectedZoneCode = (String) session.getAttribute("selectedZoneCode");
if (!newZone3List.contains(currentSelectedZoneCode)) {
    throw new RuntimeException("현재 선택된 호기는 비활성화할 수 없습니다.");
}
```

---

## 감사 로그

`systemActivityLogService.logUserAction()` 호출로 변경 기록:

| 작업 | category | action | resourceType |
|------|----------|--------|--------------|
| 설정 변경 | SYS_CONFIG | UPDATE | SYS_CONFIG |
| 설정 확인 | SYS_CONFIG | VIEW | SYS_CONFIG |

### 로그 상세 정보

```json
{
  "action": "설정 변경",
  "hasChanges": true,
  "changes": {
    "zone1": {"before": "old_value", "after": "new_value"},
    "zone2": {"before": "old_value", "after": "new_value"},
    "zone3": {"before": "[\"sp_03\"]", "after": "[\"sp_03\",\"sp_04\"]"}
  }
}
```

---

## 권한 처리

프론트엔드에서 권한에 따라 버튼 표시/숨김:

```html
<!-- 저장 버튼: WRITE 권한 -->
<button onclick="saveSystemConfig()" th:if="${userPermissions?.canWrite}">
    저장
</button>
```

---

## 다국어 메시지

| 메시지 키 | 설명 |
|----------|------|
| `menu.setting.system-config` | 페이지 제목 |
| `setting.system.zone3.min.one.required` | 호기 최소 1개 필수 |
| `setting.system.add.fail` | 저장 실패 |
| `ValidationMessage.SystemConfig.*` | 검증 메시지 |

---

## 저장된 데이터 예시

| configKey | configValue | configName | description |
|-----------|-------------|------------|-------------|
| zone1 | koen | 한국동서발전 | 사업소 |
| zone2 | samcheonpo | 삼천포발전소 | 발전소 |
| zone3 | ["sp_03","sp_04"] | 3호기, 4호기 | 호기 |

---

## 관련 문서

- [인터셉터 시스템](interceptor-system.md) - 세션 zone 설정
- [코드관리](setting-code-system.md) - zone1/zone2/zone3 코드
- [감사 로그](audit-log-system.md) - 변경 이력

---

## 프로그램 명세서

### SSC_001 - 시스템 설정 페이지

| 프로그램 ID | SSC_001 | 프로그램명 | 시스템 설정 페이지 |
|------------|---------|----------|-----------------|
| 분류 | 설정 관리 | 처리유형 | 화면 |
| 클래스명 | SettingController.java | 메서드명 | systemConfigPage() |

▣ 기능 설명

사업소/발전소/호기 기본 설정을 관리하는 페이지를 렌더링한다. zone1, zone2는 드롭다운, zone3는 다중 선택 체크박스로 제공한다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | - | - | - | - | 파라미터 없음 |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | configs | 시스템 설정 목록 | List<SystemConfig> | Y | 전체 설정 |
| 2 | configs[].configKey | 설정 키 | String | Y | zone1, zone2, zone3 |
| 3 | configs[].configValue | 설정 값 | String | Y | 값 또는 JSON 배열 |
| 4 | configs[].configName | 설정명 | String | Y | 표시용 이름 |
| 5 | codesMap | 설정별 코드 목록 | Map<String, List<Code>> | Y | 선택 옵션 |
| 6 | codesMap.zone1 | 사업소 코드 | List<Code> | Y | 사업소 목록 |
| 7 | codesMap.zone2 | 발전소 코드 | List<Code> | Y | 발전소 목록 |
| 8 | codesMap.zone3 | 호기 코드 | List<Code> | Y | 호기 목록 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | @RequirePermission(menuId = 9000L) |
| 2 | 전체 시스템 설정 조회 | findAll() |
| 3 | 설정별 코드 목록 조회 | getSystemConfig() |
| 4 | zone1: 사업소 코드 조회 | findByTypeCode("zone1") |
| 5 | zone2: 발전소 코드 조회 | findByTypeCodeAndParentCode() |
| 6 | zone3: 호기 코드 조회 | findByTypeCodeAndParentCode() |
| 7 | Model에 데이터 추가 | configs, codesMap |
| 8 | 뷰 반환 | pages/setting/systemConfig |

---

### SSC_002 - 시스템 설정 저장 API

| 프로그램 ID | SSC_002 | 프로그램명 | 시스템 설정 저장 API |
|------------|---------|----------|-------------------|
| 분류 | 설정 관리 | 처리유형 | 수정 |
| 클래스명 | SettingController.java | 메서드명 | saveSystemConfig() |

▣ 기능 설명

사업소/발전소/호기 시스템 설정을 저장한다. zone3는 최소 1개 이상 필수이며, 현재 세션에서 선택된 호기는 비활성화할 수 없다.

▣ 입력 항목 (Input)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | configs | 설정 데이터 | Map<String, Object> | Y | RequestBody |
| 2 | configs.zone1 | 사업소 코드 | String | Y | 단일 값 (예: koen) |
| 3 | configs.zone2 | 발전소 코드 | String | Y | 단일 값 (예: samcheonpo) |
| 4 | configs.zone3 | 호기 코드 | List<String> | Y | 다중 값 (예: ["sp_03","sp_04"]) |

▣ 출력 항목 (Output)

| No | 항목명(물리) | 항목명(논리) | 데이터타입 | 필수 | 설명 |
|----|--------------|--------------|------------|------|------|
| 1 | ret | 결과 코드 | Integer | Y | 0: 성공, -1: 실패 |
| 2 | message | 결과 메시지 | String | Y | 처리 결과 |

▣ 처리 로직

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 권한 체크 | WRITE 권한 필요 |
| 2 | 저장 전 현재값 수집 | beforeData |
| 3 | zone3 최소 1개 검증 | 빈 배열 거부 |
| 4 | 현재 세션 호기 보호 | selectedZoneCode 포함 필수 |
| 5 | 각 설정별 저장 | - |
| 6 | zone3 JSON 배열 변환 | ["sp_03","sp_04"] |
| 7 | 저장 | systemConfigRepository.save() |
| 8 | 감사 로그 기록 | logSystemConfigChange() |
| 9 | 결과 반환 | JSON 응답 |

▣ zone3 검증 규칙

| 조건 | 오류 메시지 | 설명 |
|------|------------|------|
| 빈 배열 | "활성화된 호기가 필요합니다." | 최소 1개 필수 |
| 현재 선택 호기 제외 | "현재 선택된 호기는 비활성화할 수 없습니다." | 세션 selectedZoneCode 보호 |

▣ 데이터 저장 형식

| configKey | 저장 형식 | 예시 |
|-----------|----------|------|
| zone1 | 단일 문자열 | koen |
| zone2 | 단일 문자열 | samcheonpo |
| zone3 | JSON 배열 | ["sp_03","sp_04"] |

▣ 감사 로그 상세

```json
{
  "action": "설정 변경",
  "hasChanges": true,
  "changes": {
    "zone1": {"before": "old_value", "after": "new_value"},
    "zone2": {"before": "old_value", "after": "new_value"},
    "zone3": {"before": "[\"sp_03\"]", "after": "[\"sp_03\",\"sp_04\"]"}
  }
}
```

---

▣ 시스템 전역 영향

zone3 활성화 설정 변경 시 다음 기능에 영향:

| 영향 범위 | 설명 |
|----------|------|
| 헤더 호기 선택 | 활성화된 호기만 드롭다운에 표시 |
| 스위치 관리 탭 | 활성화된 호기만 탭으로 표시 |
| 토폴로지 뷰 | 활성화된 호기만 시각화 |
| 데이터 조회 | zone3 필터에 활성 호기만 사용 |
| 코드 삭제 제한 | 활성화된 호기는 코드관리에서 삭제 불가 |

▣ 세션 연동

| 순서 | 처리내용 | 비고 |
|------|----------|------|
| 1 | 현재 세션의 selectedZoneCode 조회 | session.getAttribute() |
| 2 | 새 zone3 목록에 포함 여부 확인 | 포함 필수 |
| 3 | 미포함 시 저장 거부 | RuntimeException |

