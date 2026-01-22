# 감사 로그 시스템

> @ActivityLog 어노테이션 기반 감사 추적

---

## 1. 개요

```
[@ActivityLog 어노테이션]
        │
        ▼
[ActivityLogAspect] ─── AOP Around
        │
        ├── findExtractor(resourceType)
        │
        ▼
[ActivityLogExtractor 구현체]
        │
        ▼
[SystemActivityLogService] → DB 저장
```

---

## 2. @ActivityLog 어노테이션

**경로:** `annotation/ActivityLog.java`

```java
@ActivityLog(
    category = "ASSET_MANAGE",    // 카테고리
    action = "UPDATE",            // 액션
    resourceType = "ASSET"        // 리소스 타입 (Extractor 매칭용)
)
```

### 2.1 속성

| 속성 | 설명 | 예시 |
|------|------|------|
| `category` | 기능 카테고리 | `USER_MANAGE`, `ASSET_MANAGE` |
| `action` | 수행 작업 | `CREATE`, `UPDATE`, `DELETE` |
| `resourceType` | 리소스 타입 | `USER`, `ASSET`, `MENU` |

---

## 3. Action 목록

| Action | 설명 | beforeData 캡처 |
|--------|------|:---------------:|
| `CREATE` / `ADD` | 생성 | O |
| `UPDATE` / `EDIT` | 수정 | O |
| `DELETE` | 삭제 | O |
| `EXCEL_DOWN_ALL` | 전체 엑셀 다운로드 | O |
| `EXCEL_DOWN_PAGE` | 페이지 엑셀 다운로드 | O |
| `LOGIN` | 로그인 | O |

---

## 4. Category 목록

| Category | 설명 |
|----------|------|
| `USER_MANAGE` | 사용자 관리 |
| `USER_GROUP` | 사용자 그룹 |
| `ASSET_MANAGE` | 자산 관리 |
| `POLICY_MANAGE` | 정책 관리 |
| `ALARM_MANAGE` | 알람 관리 |
| `SETTING_MANAGE` | 설정 관리 |
| `ANALYSIS` | 분석 |
| `AUTH` | 인증 |

---

## 5. ActivityLogExtractor

**경로:** `aspect/ActivityLogExtractor.java`

### 5.1 인터페이스
```java
public interface ActivityLogExtractor {
    // 이 리소스 타입을 지원하는지 확인
    boolean supports(String resourceType);

    // 리소스 ID 추출
    String extractResourceId(Object[] args, Object result);

    // 리소스 이름 추출
    String extractResourceName(Object[] args, Object result);

    // 변경 전 데이터 캡처 (UPDATE용)
    String captureBeforeData(Object[] args);

    // 상세 정보 구성
    String buildDetails(String action, String beforeData,
                       Object[] args, Object result);
}
```

### 5.2 등록된 Extractor (20개)

| Extractor | resourceType |
|-----------|-------------|
| `AssetActivityLogExtractor` | `ASSET` |
| `UserActivityLogExtractor` | `USER` |
| `UserGroupActivityLogExtractor` | `USER_GROUP` |
| `GroupActivityLogExtractor` | `GROUP` |
| `MenuActivityLogExtractor` | `MENU` |
| `AlarmActivityLogExtractor` | `ALARM` |
| `AlarmActionLogExtractor` | `ALARM_ACTION` |
| `AlarmManagerActivityLogExtractor` | `ALARM_MANAGER` |
| `CodeActivityLogExtractor` | `CODE` |
| `SystemConfigActivityLogExtractor` | `SYSTEM_CONFIG` |
| `TemplateActivityLogExtractor` | `TEMPLATE` |
| `DetectionPolicyActivityLogExtractor` | `DETECTION_POLICY` |
| `WhiteListPolicyActivityLogExtractor` | `WHITE_LIST_POLICY` |
| `ServicePortPolicyActivityLogExtractor` | `SERVICE_PORT_POLICY` |
| `TopologySwitchExtractor` | `TOPOLOGY_SWITCH` |
| `OpTagInfoActivityLogExtractor` | `OP_TAG_INFO` |
| `EventDefinitionLogExtractor` | `EVENT_DEFINITION` |
| `EventActionLogExtractor` | `ANALYSIS_ACTION` |
| `AuditLogSettingExtractor` | `AUDIT_LOG_SETTING` |

---

## 6. 새 Extractor 추가

### 6.1 구현 예시
```java
@Component
@RequiredArgsConstructor
@Slf4j
public class FeatureActivityLogExtractor implements ActivityLogExtractor {

    private final FeatureRepository featureRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public boolean supports(String resourceType) {
        return "FEATURE".equals(resourceType);
    }

    @Override
    public String extractResourceId(Object[] args, Object result) {
        if (args != null && args.length > 0) {
            if (args[0] instanceof FeatureDto dto) {
                return String.valueOf(dto.getId());
            }
        }
        return "";
    }

    @Override
    public String extractResourceName(Object[] args, Object result) {
        if (args != null && args.length > 0) {
            if (args[0] instanceof FeatureDto dto) {
                return dto.getName();
            }
        }
        return "";
    }

    @Override
    public String captureBeforeData(Object[] args) {
        try {
            if (args != null && args.length > 0 && args[0] instanceof FeatureDto dto) {
                Long id = dto.getId();
                if (id != null) {
                    return featureRepository.findById(id)
                        .map(entity -> toJson(entity))
                        .orElse(null);
                }
            }
        } catch (Exception e) {
            log.error("captureBeforeData 실패", e);
        }
        return null;
    }

    @Override
    public String buildDetails(String action, String beforeData,
                              Object[] args, Object result) {
        Map<String, Object> details = new HashMap<>();
        details.put("action", action);
        if (beforeData != null) {
            details.put("before", beforeData);
        }
        if (args != null && args.length > 0) {
            details.put("after", toJson(args[0]));
        }
        return toJson(details);
    }

    private String toJson(Object obj) {
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (Exception e) {
            return obj.toString();
        }
    }
}
```

### 6.2 Controller/Service에 적용
```java
@ActivityLog(
    category = "FEATURE_MANAGE",
    action = "UPDATE",
    resourceType = "FEATURE"  // Extractor의 supports()와 일치
)
@PostMapping("/save")
public Map<String, Object> save(@RequestBody FeatureDto dto) {
    // ...
}
```

---

## 7. 데이터 저장

### 7.1 SystemActivityLog 테이블

| 컬럼 | 설명 |
|------|------|
| `id` | PK |
| `user_id` | 사용자 ID |
| `category` | 카테고리 |
| `action` | 액션 |
| `resource_type` | 리소스 타입 |
| `resource_id` | 리소스 ID |
| `resource_name` | 리소스 이름 |
| `details` | JSON 상세 정보 |
| `ip_address` | IP 주소 |
| `created_at` | 생성 시각 |

---

## 8. 참조 파일

| 파일 | 역할 |
|------|------|
| `annotation/ActivityLog.java` | 어노테이션 정의 |
| `aspect/ActivityLogAspect.java` | AOP 처리 |
| `aspect/ActivityLogExtractor.java` | Extractor 인터페이스 |
| `aspect/*Extractor.java` | 개별 Extractor 구현 (20개) |
| `service/SystemActivityLogService.java` | 로그 저장 서비스 |
| `model/SystemActivityLog.java` | Entity |
