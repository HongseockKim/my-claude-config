# 정수 오버플로우 취약점 수정 플랜

**작성일**: 2026-01-16
**심각도**: 상 (CVSS 8.6)
**대상 URL**: `/topology-physical/select-asset-list` 외 다수

---

## 1. 취약점 요약

### 1.1 AppScan 스캔 결과
- **취약점**: 정수 오버플로우
- **테스트 값**: `idx=4294967297` (2^32 + 1)
- **결과**: HTTP 500 에러 + 민감한 디버깅 정보 노출 가능
- **원인**: 입력 매개변수 값의 범위 점검 미흡 + 예외 메시지 직접 노출

### 1.2 근본 원인 분석
1. **컨트롤러에서 직접 500 에러 반환** → GlobalExceptionHandler 우회
2. **e.getMessage() 응답 노출** → 민감한 시스템 정보 유출
3. **int 파라미터 범위 검증 누락** → 오버플로우 가능

---

## 2. 수정 대상 파일

### 2.1 우선순위 높음 - e.getMessage() 노출 제거

| 파일 | 수정 라인 |
|------|-----------|
| `DetectionController.java` | 147, 316, 452, 482, 514, 548, 593, 624, 1157, 1235 |
| `PolicyController.java` | 76, 112, 150, 169, 232, 266, 301, 335, 367, 399, 420, 482, 648, 716, 758, 784 |
| `AuthController.java` | 85 |

### 2.2 우선순위 높음 - 500 에러 직접 반환 제거

| 파일 | 경로 |
|------|------|
| `TopologyPhysicalController.java` | `src/main/java/.../controller/` |
| `DetectionController.java` | `src/main/java/.../controller/` |
| `AssetController.java` | `src/main/java/.../controller/` |
| `CodeController.java` | `src/main/java/.../controller/` |
| `PolicyController.java` | `src/main/java/.../controller/` |
| `DataController.java` | `src/main/java/.../controller/` |
| `SettingController.java` | `src/main/java/.../controller/` |
| `DashboardController.java` | `src/main/java/.../controller/` |
| `OperationController.java` | `src/main/java/.../controller/` |
| `WidgetController.java` | `src/main/java/.../controller/` |

### 2.3 우선순위 중간 - int 파라미터 범위 검증 추가

| 파일 | 파라미터 | 라인 |
|------|----------|------|
| `AssetController.java` | startRow, endRow, startRaw, endRaw | 167-168, 199-200, 225-226 |
| `DetectionController.java` | startRow, endRow, offset, limit | 113-114, 326-327, 632-633, 997 |
| `DataController.java` | hours, page, size | 129, 270-271 |
| `SettingController.java` | startRow, endRow | 402-403 |
| `TopologyPhysicalController.java` | startRaw, endRaw | 110-111 |
| `AlarmNotificationController.java` | limit | 33 |

---

## 3. 수정 방법

### 3.1 Step 1: e.getMessage() 노출 제거

**Before:**
```java
catch (Exception e) {
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(Map.of("message", "조회 실패: " + e.getMessage()));
}
```

**After:**
```java
catch (Exception e) {
    log.error("조회 실패", e);
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(Map.of(
                "ret", -1,
                "success", false,
                "message", messageService.getMessage(ValidationMessage.Common.ERROR_UNEXPECTED)
            ));
}
```

### 3.2 Step 2: 500 에러 → 400 에러로 변경 (사용자 입력 오류 시)

**입력 유효성 문제일 경우:**
```java
catch (IllegalArgumentException e) {
    log.warn("잘못된 입력: {}", e.getMessage());
    return ResponseEntity.badRequest()
            .body(Map.of(
                "ret", -1,
                "success", false,
                "message", messageService.getMessage(ValidationMessage.Common.COMMON_INCORRECT_VALUE)
            ));
}
```

### 3.3 Step 3: int 파라미터에 @Min/@Max 추가

**Before:**
```java
@RequestParam(defaultValue = "0") int startRow,
@RequestParam(defaultValue = "100") int endRow
```

**After:**
```java
@RequestParam(defaultValue = "0") @Min(0) @Max(100000) int startRow,
@RequestParam(defaultValue = "100") @Min(1) @Max(100000) int endRow
```

**컨트롤러 클래스에 @Validated 확인:**
```java
@RestController
@RequestMapping("/...")
@Validated  // ← 필수 확인
public class XxxController {
```

### 3.4 Step 4: 기존 ValidationMessage 상수 활용

**이미 존재하는 상수 (추가 작업 불필요):**
```java
// ValidationMessage.Common 클래스에 이미 존재
public static final String ERROR_UNEXPECTED = "error.unexpected";  // "예기치 않은 오류가 발생했습니다."
public static final String COMMON_INCORRECT_VALUE = "common.incorrect.value";
public static final String COMMON_UNKNOW_PARAM = "common.unknow.parameters";
```

**사용 예시:**
```java
catch (Exception e) {
    log.error("조회 실패", e);
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(Map.of(
                "ret", -1,
                "success", false,
                "message", messageService.getMessage(ValidationMessage.Common.ERROR_UNEXPECTED)
            ));
}
```

---

## 4. 작업 순서

### Phase 1: 핵심 취약점 수정 (높음) - e.getMessage() 노출 제거
- [ ] `TopologyPhysicalController.java` 수정 (스캔된 엔드포인트)
- [ ] `DetectionController.java` 수정 (e.getMessage() 10건)
- [ ] `PolicyController.java` 수정 (e.getMessage() 16건)
- [ ] `AuthController.java` 수정 (e.getMessage() 1건)

### Phase 2: 500 에러 반환 패턴 수정 (높음)
- [ ] `AssetController.java` 수정
- [ ] `CodeController.java` 수정
- [ ] `DataController.java` 수정
- [ ] `SettingController.java` 수정
- [ ] `DashboardController.java` 수정
- [ ] `OperationController.java` 수정
- [ ] `WidgetController.java` 수정

### Phase 3: int 파라미터 범위 검증 (중간)
- [ ] `AssetController.java` - @Min/@Max 추가
- [ ] `DetectionController.java` - @Min/@Max 추가
- [ ] `DataController.java` - @Min/@Max 추가
- [ ] `SettingController.java` - @Min/@Max 추가
- [ ] `TopologyPhysicalController.java` - @Min/@Max 추가
- [ ] `AlarmNotificationController.java` - @Min/@Max 추가

### Phase 4: 검증
- [ ] 빌드 테스트 (`mvnw.cmd clean compile -DskipTests`)
- [ ] 로컬 실행 테스트
- [ ] AppScan 재스캔 대상 엔드포인트 수동 테스트

---

## 5. 검증 방법

### 5.1 빌드 검증
```bash
mvnw.cmd clean compile -DskipTests
```

### 5.2 수동 테스트 (curl 또는 Postman)

**정수 오버플로우 테스트:**
```bash
# 큰 정수값 입력 시 400 Bad Request 반환 확인
curl -k "https://localhost:8080/topology-physical/select-asset-list?idx=4294967297"
# 예상 응답: {"ret":-1,"success":false,"message":"잘못된 파라미터 형식입니다."}
```

**범위 초과 테스트:**
```bash
# int 범위 초과 시
curl -k "https://localhost:8080/detection/connection/data?startRow=-1&endRow=100"
# 예상 응답: 400 Bad Request
```

### 5.3 확인할 응답 조건
1. ✅ HTTP 500 대신 400 또는 적절한 상태 코드 반환
2. ✅ e.getMessage()가 응답에 포함되지 않음
3. ✅ 일관된 에러 응답 포맷: `{"ret":-1,"success":false,"message":"..."}`
4. ✅ 스택 트레이스 또는 시스템 정보 미노출

---

## 6. 참고 사항

### 6.1 GlobalExceptionHandler 활용
`GlobalExceptionHandler.java`에 이미 다음 예외들이 처리되어 있음:
- `MethodArgumentTypeMismatchException` → 400 반환
- `NumberFormatException` → 400 반환
- `ConstraintViolationException` → 400 반환
- `Exception` (catch-all) → 500 반환 (메시지: "서버 오류가 발생했습니다.")

**컨트롤러에서 예외를 던지면 GlobalExceptionHandler가 안전하게 처리함.**

### 6.2 기존 코드 패턴 유지
- 응답 포맷: `{"ret": 0/1/-1, "success": true/false, "message": "...", "data": {...}}`
- 로깅: `log.error("설명", e)` 형태로 스택 트레이스 기록
- 메시지: `messageService.getMessage()` 사용

### 6.3 주의사항
- 기존 프론트엔드 JS에서 `ret` 값으로 성공/실패 판단하는 경우가 있으므로 포맷 유지
- `@Validated` 어노테이션이 없는 컨트롤러는 추가 필요
