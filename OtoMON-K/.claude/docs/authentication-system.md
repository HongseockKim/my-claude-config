# 인증 시스템 명세서 (로그인/로그아웃/비밀번호 변경)

## 1. 개요

OtoMON-K의 인증 시스템은 **세션 기반 폼 로그인**과 **JWT 기반 REST API 로그인**을 모두 지원합니다.

---

## 2. 관련 파일 목록

### 2.1 로그인

| 구분 | 파일 경로 |
|------|----------|
| HTML 템플릿 | `src/main/resources/templates/login.html` |
| 컨트롤러 | `src/main/java/com/otoones/otomon/controller/HomeController.java` |
| REST API | `src/main/java/com/otoones/otomon/controller/AuthController.java` |
| 보안 설정 | `src/main/java/com/otoones/otomon/config/SecurityConfig.java` |
| 인증 서비스 | `src/main/java/com/otoones/otomon/service/UserService.java` |
| 성공 핸들러 | `src/main/java/com/otoones/otomon/security/CustomAuthSuccessHandler.java` |
| 실패 핸들러 | `src/main/java/com/otoones/otomon/security/CustomAuthFailureHandler.java` |
| JWT 프로바이더 | `src/main/java/com/otoones/otomon/security/JwtTokenProvider.java` |
| JWT 필터 | `src/main/java/com/otoones/otomon/security/JwtAuthenticationFilter.java` |

### 2.2 비밀번호 변경

| 구분 | 파일 경로 |
|------|----------|
| HTML 템플릿 | `src/main/resources/templates/pages/user/changePassword.html` |
| 컨트롤러 | `src/main/java/com/otoones/otomon/controller/UserController.java` |
| DTO | `src/main/java/com/otoones/otomon/dto/PasswordChangeDto.java` |
| 검증기 | `src/main/java/com/otoones/otomon/validator/PasswordValidator.java` |

### 2.3 공통

| 구분 | 파일 경로 |
|------|----------|
| User Entity | `src/main/java/com/otoones/otomon/model/User.java` |
| 비밀번호 인코더 | `src/main/java/com/otoones/otomon/security/MigrationPasswordEncoder.java` |
| ARIA 인코더 | `src/main/java/com/otoones/otomon/security/AriaPasswordEncoder.java` |
| 로그아웃 버튼 | `src/main/resources/templates/components/navbar.html` |

---

## 3. 로그인

### 3.1 흐름도

```
[사용자 입력] username, password
       ↓
[POST /login] 폼 제출
       ↓
[SecurityFilterChain]
       ↓
[UserService.loadUserByUsername()]
       ↓
[User 조회 + 상태 확인]
       ↓
[MigrationPasswordEncoder.matches()]
       ↓
   ┌───────┴───────┐
   ↓               ↓
[성공]          [실패]
   ↓               ↓
CustomAuth     CustomAuth
SuccessHandler FailureHandler
   ↓               ↓
/dashboard     /login?error=true
```

### 3.2 폼 기반 로그인 (세션)

**Security 설정** (`SecurityConfig.java`):
```java
.formLogin(form -> form
    .loginPage("/login")
    .defaultSuccessUrl("/dashboard", true)
    .successHandler(customAuthSuccessHandler)
    .failureHandler(customAuthFailureHandler)
    .permitAll()
)
```

### 3.3 로그인 성공 처리 (CustomAuthSuccessHandler)

1. 실패 카운트 리셋
2. 아이디 저장 쿠키 처리 (30일)
3. 사용자 Zone 정보 세션에 저장 (selectedZoneIdx, selectedZoneCode, selectedZoneName)
4. 비밀번호 변경 필요 시 `/user/changePassword` 리다이렉트
5. 로그인 로그 기록
6. `/dashboard` 리다이렉트

### 3.4 로그인 실패 처리 (CustomAuthFailureHandler)

- 실패 카운트 증가
- **5회 실패 시 30분 계정 잠금**
- 에러 메시지 세션에 저장
- `/login?error=true` 리다이렉트

**오류 메시지**:
| 상황 | 메시지 |
|------|--------|
| 계정 잠금 | "계정이 잠겼습니다. 30분 후에 다시 시도하세요" |
| 5회 실패로 잠금 | "5회 로그인 실패로 계정이 잠겼습니다. 30분 후에 다시 시도하세요" |
| 인증 실패 | "아이디 또는 비밀번호가 일치하지 않습니다. (남은 시도: N회)" |
| 비활성 계정 | "비활성화된 계정입니다. 관리자에게 문의하세요" |

### 3.5 REST API 로그인 (JWT)

**엔드포인트**:
```
POST /api/auth/login
Content-Type: application/json

{
    "username": "admin",
    "password": "qwe123!@#"
}
```

**응답**:
```json
{
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "type": "Bearer"
}
```

**JWT 설정**:
- 유효기간: 24시간 (86400000ms)
- 알고리즘: HS256
- Secret: 환경변수 `JWT_SECRET`

---

## 4. 로그아웃

### 4.1 설정

**Security 설정** (`SecurityConfig.java`):
```java
.logout(logout -> logout
    .logoutRequestMatcher(new AntPathRequestMatcher("/logout"))
    .logoutSuccessUrl("/login?logout=true")
    .invalidateHttpSession(true)
    .clearAuthentication(true)
    .permitAll()
)
```

### 4.2 처리 내용

| 항목 | 동작 |
|------|------|
| 로그아웃 URL | `GET /logout` |
| 성공 URL | `/login?logout=true` |
| 세션 무효화 | `invalidateHttpSession(true)` |
| 인증 정보 삭제 | `clearAuthentication(true)` |
| CSRF 토큰 | 자동 리셋 |

### 4.3 UI

**navbar.html**:
```html
<a class="dropdown-item" href="/logout">로그아웃</a>
```

---

## 5. 비밀번호 변경

### 5.1 API 엔드포인트

| Method | URL | 설명 |
|--------|-----|------|
| GET | `/user/changePassword` | 비밀번호 변경 페이지 |
| POST | `/user/changePassword` | 비밀번호 변경 처리 |

### 5.2 요청/응답

**요청**:
```json
{
    "currentPassword": "현재비밀번호",
    "newPassword": "새비밀번호",
    "confirmPassword": "새비밀번호확인"
}
```

**응답 (성공)**:
```json
{
    "ret": 0,
    "message": "비밀번호가 변경되었습니다."
}
```

**응답 (실패)**:
```json
{
    "ret": 1,
    "message": "새 비밀번호가 일치하지 않습니다."
}
```

### 5.3 처리 로직 (UserService)

```java
@Transactional
public void changePassword(Long userIdx, String currentPassword, String newPassword) {
    // 1. 사용자 조회
    User user = userRepository.findById(userIdx).orElseThrow(...);

    // 2. 현재 비밀번호 검증
    if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
        throw new IllegalArgumentException("현재 비밀번호가 일치하지 않습니다.");
    }

    // 3. 새 비밀번호 암호화 후 저장
    user.setPassword(passwordEncoder.encode(newPassword));

    // 4. 비밀번호 변경 필수 플래그 해제
    user.setPasswordChangeRequired(false);

    userRepository.save(user);
}
```

### 5.4 비밀번호 유효성 검증 규칙

**PasswordValidator.java** (`@ValidPassword` 어노테이션):

| 검증 항목 | 규칙 | 실패 메시지 |
|----------|------|-------------|
| 길이 | 8~16자 | "비밀번호는 8~16자여야 합니다" |
| 조합 수 | 최소 2가지 | "대문자, 소문자, 숫자, 특수문자 중 2가지 이상" |
| 2가지 조합 | 10자 이상 | "2가지 조합 사용시 10자리 이상이여야 합니다" |
| 3가지+ 조합 | 8자 이상 | "3가지 이상 조합 사용 시 8자리 이상이어야 합니다" |
| 연속 문자 | 3자 이상 불가 (abc, 123) | "3자리 이상 연속된 문자/숫자는 사용할 수 없습니다." |
| 키보드 배열 | 3자 이상 불가 (qwe, asd) | "키보드 배열 3자리 이상 연속된 값은 사용할 수 없습니다." |
| 반복 문자 | 3자 이상 불가 (aaa, 222) | "동일한 문자를 3자리 이상 연속 사용할 수 없습니다." |

### 5.5 비밀번호 변경 필수 플래그

**흐름**:
1. 신규 사용자 생성 시 `passwordChangeRequired = true`
2. 로그인 성공 후 `isPasswordChangeRequired()` 확인
3. true이면 `/user/changePassword`로 강제 리다이렉트
4. 비밀번호 변경 완료 시 `passwordChangeRequired = false`

---

## 6. 비밀번호 암호화

### 6.1 MigrationPasswordEncoder (이중 지원)

```java
@Override
public String encode(CharSequence rawPassword) {
    return ariaPasswordEncoder.encode(rawPassword);  // 새 암호화: ARIA
}

@Override
public boolean matches(CharSequence rawPassword, String encodedPassword) {
    // ARIA 암호화 확인
    if (ariaPasswordEncoder.isAriaPassword(encodedPassword)) {
        return ariaPasswordEncoder.matches(rawPassword, encodedPassword);
    }
    // BCrypt 호환성 (레거시)
    if (ariaPasswordEncoder.isBCryptPassword(encodedPassword)) {
        return bCryptPasswordEncoder.matches(rawPassword, encodedPassword);
    }
    return false;
}
```

### 6.2 암호화 방식 비교

| 항목 | ARIA | BCrypt |
|------|------|--------|
| 접두사 | `{ARIA}` | `$2a$` 또는 `$2b$` |
| 용도 | 신규 암호화 | 레거시 호환 |
| 구현 | `AriaUtil.encrypt/decrypt()` | Spring Security 내장 |

---

## 7. User Entity 주요 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `idx` | Long | PK |
| `userId` | String | 로그인 ID |
| `password` | String | 암호화된 비밀번호 |
| `name` | String | 사용자 이름 |
| `role` | UserRole | ADMIN / MANAGER / USER |
| `status` | String | Y=활성, N=비활성, D=삭제 |
| `passwordChangeRequired` | boolean | 비밀번호 변경 필요 여부 |
| `failedAttempt` | int | 로그인 실패 횟수 |
| `lockTime` | LocalDateTime | 계정 잠금 시간 |

---

## 8. 권한 체계

| 경로 | 접근 권한 |
|------|----------|
| `/login` | 모든 사용자 |
| `/logout` | 모든 사용자 |
| `/` | 모든 사용자 (로그인으로 리다이렉트) |
| `/dashboard` | 인증 필요 |
| `/user/changePassword` | 인증 필요 |
| `/api/auth/login` | 모든 사용자 |
| `/api/admin/**` | ADMIN 역할만 |
| `/api/widget/**` | 인증 필요 |

---

## 9. 보안 설정

| 항목 | 설정값 |
|------|--------|
| HTTPS | 강제 적용 |
| HSTS | 1년 유효, 서브도메인 포함 |
| CSP | 자체 호스트 + 허용된 외부 리소스 |
| Referrer-Policy | strict-origin-when-cross-origin |
| 세션 타임아웃 | 2시간 |
| 세션 쿠키 | HttpOnly, Secure, SameSite=Strict |
| 계정 잠금 | 5회 실패 시 30분 잠금 |
| CSRF | 활성화 (일부 API 제외) |

---

## 10. 기본 계정

```
ID: admin
PW: qwe123!@#
```
