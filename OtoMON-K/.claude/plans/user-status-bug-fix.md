# 사용자 상태 저장 버그 수정 플랜

> **작성일**: 2026-01-15
> **버그 유형**: 잘못된 필드명 참조
> **확실도**: 100%

---

## 1. 버그 요약

| 항목 | 내용 |
|------|------|
| **현상** | 사용자 수정 시 "활성" 상태로 저장해도 "비활성"으로 저장됨 |
| **영향 페이지** | `/setting/userList` |
| **영향 API** | `POST /user/saveUser` |

---

## 2. 원인 분석

### 데이터 흐름

```
[프론트엔드]
체크박스 체크 → status: "1" 전송
         ↓
[백엔드 - saveUser]
Line 145: requestData.get("isAdmin") → null (존재하지 않음)
Line 147: userDto.setStatus("N")  ← 버그! 항상 "N"
         ↓
[백엔드 - saveExistingUser]
Line 253: userDto.getStatus() → "N" (이미 잘못 설정됨)
         ↓
[DB] status = "N" 저장
```

### 버그 위치

**파일**: `src/main/java/com/otoones/otomon/controller/UserController.java`

**Line 145-147:**
```java
// 상태 설정 (isAdmin이 "on"이면 활성화)
String isAdmin = (String) requestData.get("isAdmin");  // ❌ 잘못된 필드명
userDto.setStatus("on".equals(isAdmin) || "Y".equals(isAdmin) ? "Y" : "N");
```

### 문제점

| 구분 | 프론트엔드 | 백엔드 |
|------|-----------|--------|
| 필드명 | `status` | `isAdmin` |
| 값 | `"1"` (체크시) | 읽지 못함 (null) |
| 결과 | - | 항상 `"N"` |

---

## 3. 수정 방안

### 수정 파일

`src/main/java/com/otoones/otomon/controller/UserController.java`

### 수정 내용 (Line 145-147)

```java
// Before
// 상태 설정 (isAdmin이 "on"이면 활성화)
String isAdmin = (String) requestData.get("isAdmin");
userDto.setStatus("on".equals(isAdmin) || "Y".equals(isAdmin) ? "Y" : "N");

// After
// 상태 설정 (status가 "1", "Y", "on" 이면 활성화)
Object statusObj = requestData.get("status");
String status = statusObj != null ? String.valueOf(statusObj) : "N";
userDto.setStatus("1".equals(status) || "Y".equals(status) || "on".equals(status) ? "Y" : "N");
```

### 수정 이유

1. `requestData.get("status")` → 프론트엔드가 보내는 필드명과 일치
2. `Object`로 받아 `String.valueOf()` 처리 → 숫자/문자열 모두 대응
3. `"1"`, `"Y"`, `"on"` 체크 → `saveExistingUser`의 로직과 일관성 유지

---

## 4. 체크박스 동작 확인

| 상태 | 전송 데이터 | statusObj | 결과 |
|------|-----------|-----------|------|
| 체크됨 | `status: "1"` | `"1"` | `"Y"` ✅ |
| 체크 해제 | status 필드 없음 | `null` | `"N"` ✅ |

---

## 5. 검증 방법

### 테스트 시나리오

1. **활성화 테스트**
   - `/setting/userList` 접속
   - 기존 사용자 수정 클릭
   - 상태 체크박스 **체크** 후 저장
   - DB 또는 목록에서 status = "Y" 확인

2. **비활성화 테스트**
   - 상태 체크박스 **해제** 후 저장
   - DB 또는 목록에서 status = "N" 확인

### DB 확인 쿼리
```sql
SELECT idx, user_id, name, status FROM user WHERE user_id = 'test';
```

---

## 6. 영향 범위

| 항목 | 영향 |
|------|------|
| 신규 사용자 등록 | 영향 없음 (Line 197에서 `status = "Y"` 고정) |
| 기존 사용자 수정 | ✅ 수정 대상 |
| 다른 API | 영향 없음 |

---

## 7. 체크리스트

- [ ] `UserController.java` Line 145-147 수정
- [ ] 서버 재시작
- [ ] 활성화 상태 저장 테스트
- [ ] 비활성화 상태 저장 테스트
- [ ] DB에서 status 값 확인
