# 계정 잠금(Account Lockout) AppScan 감지 개선 플랜

## 문제 요약

AppScan이 10회 로그인 실패 후에도 정상 로그인이 가능하다고 보고함.
현재 5회 실패 시 30분 잠금 기능이 구현되어 있으나, `loadUserByUsername()`에서 명시적인 잠금 체크가 누락됨.

## 현재 구현 상태

| 구성요소 | 상태 | 비고 |
|---------|------|------|
| User.isAccountNonLocked() | ✅ 구현됨 | 30분 자동 해제 로직 포함 |
| UserRepository.lockAccount() | ✅ 구현됨 | lockTime 설정 |
| UserService.processFailedLogin() | ✅ 구현됨 | 5회 실패 시 잠금 |
| CustomAuthFailureHandler | ✅ 구현됨 | LockedException 처리 코드 있음 |
| CustomAuthSuccessHandler | ✅ 구현됨 | 성공 시 초기화 |
| **loadUserByUsername() 잠금 체크** | ❌ 누락 | **핵심 문제** |

## 문제 원인

```
[현재 흐름]
loadUserByUsername()
    ↓
status 체크만 수행 (isAccountNonLocked 미확인)
    ↓
Spring Security DaoAuthenticationProvider에 의존
    ↓
비밀번호 검증 실패 시 BadCredentialsException 먼저 발생
    ↓
LockedException이 throw되지 않음
```

---

## 수정 가이드

### 파일: `src/main/java/com/otoones/otomon/service/UserService.java`

#### 1. import 추가 (라인 7 근처)

```java
// 기존 import 들...
import org.springframework.security.authentication.DisabledException;
// ↓ 아래 추가
import org.springframework.security.authentication.LockedException;
```

#### 2. loadUserByUsername 메서드 수정 (라인 35-44)

**Before (현재 코드):**
```java
@Override
public UserDetails loadUserByUsername(String userId) throws UsernameNotFoundException {
    User user = userRepository.findByUserId(userId)
            .orElseThrow(() -> new UsernameNotFoundException("사용자를 찾을 수 없습니다: "));

    if (!"Y".equals(user.getStatus())) {
        throw new DisabledException("비활성화된 계정입니다.");
    }

    return user;
}
```

**After (수정 후):**
```java
@Override
public UserDetails loadUserByUsername(String userId) throws UsernameNotFoundException {
    User user = userRepository.findByUserId(userId)
            .orElseThrow(() -> new UsernameNotFoundException("사용자를 찾을 수 없습니다: "));

    if (!"Y".equals(user.getStatus())) {
        throw new DisabledException("비활성화된 계정입니다.");
    }

    // ===== 추가: 계정 잠금 체크 =====
    if (!user.isAccountNonLocked()) {
        throw new LockedException("계정이 잠겼습니다. 30분 후에 다시 시도하세요.");
    }
    // ================================

    return user;
}
```

---

## 수정 후 예상 흐름

```
[수정 후 흐름]
loadUserByUsername()
    ↓
status 체크
    ↓
isAccountNonLocked() 체크 ← 추가됨
    ↓
잠금 상태면 LockedException throw
    ↓
CustomAuthFailureHandler가 LockedException 감지
    ↓
"계정이 잠겼습니다. 30분 후에 다시 시도하세요" 메시지 표시
```

---

## 검증 방법

### 1. 수동 테스트
1. 로그인 페이지 접속
2. admin 계정으로 틀린 비밀번호 5회 입력
3. 5회차에 "5회 로그인 실패로 계정이 잠겼습니다" 메시지 확인
4. 6회차 시도 시 "계정이 잠겼습니다. 30분 후에 다시 시도하세요" 메시지 확인
5. 올바른 비밀번호로도 로그인 차단 확인

### 2. DB 확인
```sql
SELECT user_id, failed_attempt, lock_time
FROM user
WHERE user_id = 'admin';
-- failed_attempt = 5, lock_time IS NOT NULL 확인
```

### 3. 테스트 후 잠금 해제
```sql
UPDATE user SET failed_attempt = 0, lock_time = NULL
WHERE user_id = 'admin';
```

### 4. AppScan 재스캔
- 수정 후 동일한 테스트 수행
- "올바르지 않은 계정 잠금" 취약점 해결 확인

---

## 참고 문서

- `.claude/docs/authentication-system.md`