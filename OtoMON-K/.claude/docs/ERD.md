# OtoMON-K ERD 문서

> **프로젝트**: OtoMON-K (산업제어시스템 위협탐지 모니터링)  
> **기술 스택**: Spring Boot 3.4.5, Java 17, JPA, MariaDB  
> **최종 수정일**: 2025-01-22  
> **작성자**: 김홍석

---

## 📋 목차

1. [개요](#1-개요)
2. [도메인별 ERD](#2-도메인별-erd)
3. [JPA 관계 매핑 요약](#3-jpa-관계-매핑-요약)
4. [독립 엔티티 목록](#4-독립-엔티티-목록)
5. [엔티티 상세 명세](#5-엔티티-상세-명세)

---

## 1. 개요

### 1.1 시스템 구성

| 구분 | 내용 |
|------|------|
| 총 엔티티 수 | 약 45개 |
| JPA 관계 매핑 | 15개 |
| 독립 엔티티 | 30개+ |
| 주요 도메인 | 사용자, 알람, 대시보드, 자산, 이벤트, 정책 |

### 1.2 도메인 구조

```
OtoMON-K
├── 🔐 사용자/권한 시스템
├── 🔔 알람 시스템
├── 📊 대시보드/리포트
├── 🖥️ 자산 관리
├── ⚡ 이벤트/탐지
├── 🌐 토폴로지
└── ⚙️ 시스템 설정
```

---

## 2. 도메인별 ERD

### 2.1 사용자/그룹 시스템 (핵심)

```
┌──────────────────────┐                    ┌──────────────────────┐
│        User          │                    │      UserGroup       │
├──────────────────────┤                    ├──────────────────────┤
│ idx (PK)             │                    │ idx (PK)             │
│ userId (UNI)         │    @ManyToMany     │ groupCode (UNI)      │
│ password             │◄──────────────────►│ groupName            │
│ name                 │  UserGroupMapping  │ description          │
│ email                │  (중간 테이블)      │ status               │
│ role (ENUM)          │                    │ alarm_enabled        │
│ status               │                    │ alarm_level          │
│ failed_attempt       │                    └──────────┬───────────┘
│ lock_time            │                               │
│ password_change_req  │                               │ @OneToMany
└──────────────────────┘                               │
                                                       ▼
                            ┌──────────────────────────┼──────────────────────────┐
                            │                          │                          │
                            ▼                          ▼                          ▼
                ┌───────────────────┐    ┌───────────────────┐    ┌───────────────────┐
                │ GroupCodeMapping  │    │ GroupMenuMapping  │    │  GroupPermission  │
                ├───────────────────┤    ├───────────────────┤    ├───────────────────┤
                │ @ManyToOne        │    │ @ManyToOne        │    │ @ManyToOne        │
                │ → UserGroup       │    │ → UserGroup       │    │ → UserGroup       │
                │ @ManyToOne        │    │ @ManyToOne        │    │ resourceType      │
                │ → Code            │    │ → Menu            │    │ permissionType    │
                └───────────────────┘    └───────────────────┘    └───────────────────┘
```

#### 관계 설명

| 관계 | 설명 |
|------|------|
| `User` ↔ `UserGroup` | 다대다 관계, `UserGroupMapping` 중간 테이블 사용 |
| `UserGroup` → `GroupCodeMapping` | 그룹별 접근 가능한 호기(발전소) 코드 매핑 |
| `UserGroup` → `GroupMenuMapping` | 그룹별 접근 가능한 메뉴 매핑 |
| `UserGroup` → `GroupPermission` | 그룹별 리소스 권한 (CRUD) 매핑 |

---

### 2.2 메뉴 시스템 (Self-Reference)

```
┌──────────────────────┐
│        Menu          │
├──────────────────────┤
│ id (PK)              │
│ name                 │
│ url                  │
│ icon                 │◄───┐
│ messageCode          │    │ @ManyToOne (Self)
│ displayOrder         │    │ parentId → Menu.id
│ status               │    │
│ has_children         │    │ @OneToMany
│ parentId (FK)────────┼────┘ children → Menu
└──────────────────────┘
```

#### 특징
- **Self-Reference 패턴**: 계층형 메뉴 구조
- **양방향 매핑**: `parent` ↔ `children`
- `has_children`: 자식 존재 여부 캐싱 (성능 최적화)

---

### 2.3 알람 시스템

```
┌──────────────────────┐
│     AlarmConfig      │
├──────────────────────┤
│ id (PK)              │
│ alarm_name           │
│ alarm_code (UNI)     │
│ alarm_type           │
│ alarm_level          │────────────────────────┐
│ is_enabled           │                        │
│ trap_level           │                        │
│ url                  │                        │
└──────────┬───────────┘                        │
           │                                    │
           │ @OneToMany                         │ @OneToMany
           │ (mappedBy="alarmConfig")           │ (단방향)
           ▼                                    ▼
┌──────────────────────┐            ┌──────────────────────┐
│    AlarmManager      │            │     AlarmAction      │
├──────────────────────┤            ├──────────────────────┤
│ id (PK)              │            │ id (PK)              │
│ @ManyToOne           │            │ alarm_config_id (FK) │
│ → AlarmConfig        │            │ action_order         │
│ userGroupIdx         │            │ action_type          │
│ is_enabled           │            │ action_content       │
└──────────────────────┘            └──────────────────────┘
```

#### 관계 설명

| 관계 | 타입 | 설명 |
|------|------|------|
| `AlarmConfig` → `AlarmManager` | 양방향 | 알람별 담당 그룹 지정 |
| `AlarmConfig` → `AlarmAction` | 단방향 | 알람 발생 시 실행할 액션 |

---

### 2.4 대시보드 템플릿

```
┌──────────────────────┐         ┌────────────────────────────┐
│  DashboardTemplate   │ 1 ─── N │  DashboardTemplateWidget   │
├──────────────────────┤         ├────────────────────────────┤
│ id (PK)              │         │ id (PK)                    │
│ name                 │         │ @ManyToOne                 │
│ description          │◄────────│ → DashboardTemplate        │
│ is_default           │         │ widget_type                │
│ created_at           │         │ widget_config (JSON)       │
│ @OneToMany           │         │ position_x, position_y     │
│ → widgets            │         │ width, height              │
└──────────────────────┘         └────────────────────────────┘
```

#### 특징
- `widget_config`: JSON 타입으로 유연한 위젯 설정 저장
- 위젯 위치/크기 정보 포함 (Grid Layout 지원)

---

### 2.5 리포트 시스템

```
┌──────────────────────┐         ┌──────────────────────┐
│       Report         │ 1 ─── N │    ReportWidget      │
├──────────────────────┤         ├──────────────────────┤
│ id (PK)              │         │ id (PK)              │
│ name                 │         │ @ManyToOne           │
│ start_date           │◄────────│ → Report             │
│ end_date             │         │ widget_type          │
│ status               │         │ title                │
│ @OneToMany           │         │ config (JSON)        │
│ → widgets            │         └──────────────────────┘
└──────────────────────┘
```

---

### 2.6 감사 로그 설정

```
┌──────────────────────┐         ┌──────────────────────┐
│      UserGroup       │ 1 ─── N │   AuditLogSetting    │
├──────────────────────┤         ├──────────────────────┤
│ idx (PK)             │◄────────│ @ManyToOne           │
└──────────────────────┘         │ → UserGroup          │
                                 │ entity_name          │
                                 │ action_type          │
                                 │ is_enabled           │
                                 └──────────────────────┘
```

#### 용도
- 그룹별로 감사 로그 수집 대상 엔티티/액션 설정
- `entity_name`: 감사 대상 엔티티명
- `action_type`: CREATE, UPDATE, DELETE 등

---

## 3. JPA 관계 매핑 요약

### 3.1 전체 관계 매핑표 (15개)

| 엔티티 | 관계 | 대상 엔티티 | 방향 |
|--------|------|-------------|------|
| User | `@ManyToMany` | UserGroup | 양방향 |
| UserGroup | `@OneToMany` | GroupCodeMapping | 양방향 |
| UserGroup | `@OneToMany` | GroupMenuMapping | 양방향 |
| UserGroup | `@OneToMany` | GroupPermission | 양방향 |
| GroupCodeMapping | `@ManyToOne` | UserGroup | - |
| GroupCodeMapping | `@ManyToOne` | Code | - |
| GroupMenuMapping | `@ManyToOne` | UserGroup | - |
| GroupMenuMapping | `@ManyToOne` | Menu | - |
| GroupPermission | `@ManyToOne` | UserGroup | - |
| Menu | `@ManyToOne` | Menu (Self) | 양방향 |
| Menu | `@OneToMany` | Menu (children) | 양방향 |
| AlarmConfig | `@OneToMany` | AlarmManager | 양방향 |
| AlarmConfig | `@OneToMany` | AlarmAction | 단방향 |
| DashboardTemplate | `@OneToMany` | DashboardTemplateWidget | 양방향 |
| Report | `@OneToMany` | ReportWidget | 양방향 |
| AuditLogSetting | `@ManyToOne` | UserGroup | - |

### 3.2 관계 유형별 분류

| 관계 유형 | 개수 | 비고 |
|-----------|------|------|
| `@ManyToMany` | 1 | User ↔ UserGroup |
| `@OneToMany` | 8 | 부모 → 자식 |
| `@ManyToOne` | 9 | 자식 → 부모 |
| Self-Reference | 1 | Menu 계층 구조 |

---

## 4. 독립 엔티티 목록

> JPA 관계 매핑 없이 독립적으로 운영되는 엔티티 (30개+)

| 도메인 | 엔티티 | 설명 |
|--------|--------|------|
| **자산** | `Asset` | 관리 대상 자산 정보 |
| | `AssetRaw` | 원시 자산 데이터 |
| **이벤트** | `Event` | 발생 이벤트 |
| | `EventDefinition` | 이벤트 정의 |
| | `EventActionLog` | 이벤트 조치 이력 |
| **정책** | `WhitelistPolicy` | 화이트리스트 정책 |
| | `ServicePortPolicy` | 서비스 포트 정책 |
| | `DetectionPolicy` | 탐지 정책 |
| **탐지** | `DetectionPolicyAsset` | 자산 기반 탐지 |
| | `DetectionPolicyConnection` | 연결 기반 탐지 |
| | `DetectionPolicyOIS` | OIS 기반 탐지 |
| **토폴로지** | `TopologySwitch` | 스위치 토폴로지 |
| | `TopologyDevice` | 디바이스 토폴로지 |
| | `TopologyNet` | 네트워크 토폴로지 |
| | `Node` | 노드 정보 |
| | `Link` | 링크 정보 |
| **운전정보** | `OpTag` | 운전 태그 |
| | `OpTagRel` | 운전 태그 관계 |
| | `OpCollectionConfig` | 수집 설정 |
| | `OpTransferConfig` | 전송 설정 |
| **통계** | `Stats1Min` | 1분 통계 |
| | `Stat1MinRawEvent` | 1분 원시 이벤트 통계 |
| | `TrafficMetricUnit` | 트래픽 메트릭 (단위) |
| | `TrafficMetricNode` | 트래픽 메트릭 (노드) |
| | `TrafficMetricPort` | 트래픽 메트릭 (포트) |
| **설정** | `SystemConfig` | 시스템 설정 |
| | `MonitoringConfig` | 모니터링 설정 |
| | `Code` | 공통 코드 |
| | `CodeGroup` | 코드 그룹 |
| | `CodeType` | 코드 타입 |
| **알람** | `AlarmHistory` | 알람 이력 |
| | `AlarmTypeCode` | 알람 유형 코드 |
| | `AlarmLevelCode` | 알람 레벨 코드 |

---

## 5. 엔티티 상세 명세

### 5.1 User

| 컬럼명 | 타입 | NULL | 제약조건 | 설명 |
|--------|------|------|----------|------|
| idx | BIGINT | NO | PK, AUTO | 기본키 |
| userId | VARCHAR(50) | NO | UNIQUE | 로그인 ID |
| password | VARCHAR(255) | NO | - | BCrypt 암호화 |
| name | VARCHAR(100) | NO | - | 사용자 이름 |
| email | VARCHAR(100) | YES | - | 이메일 |
| role | ENUM | NO | - | ADMIN/MANAGER/USER |
| status | VARCHAR(20) | NO | DEFAULT 'ACTIVE' | 계정 상태 |
| failed_attempt | INT | NO | DEFAULT 0 | 로그인 실패 횟수 |
| lock_time | DATETIME | YES | - | 계정 잠금 시간 |
| password_change_req | BOOLEAN | NO | DEFAULT FALSE | 비밀번호 변경 필요 |

### 5.2 UserGroup

| 컬럼명 | 타입 | NULL | 제약조건 | 설명 |
|--------|------|------|----------|------|
| idx | BIGINT | NO | PK, AUTO | 기본키 |
| groupCode | VARCHAR(50) | NO | UNIQUE | 그룹 코드 |
| groupName | VARCHAR(100) | NO | - | 그룹 이름 |
| description | VARCHAR(500) | YES | - | 설명 |
| status | VARCHAR(20) | NO | DEFAULT 'ACTIVE' | 상태 |
| alarm_enabled | BOOLEAN | NO | DEFAULT TRUE | 알람 수신 여부 |
| alarm_level | VARCHAR(20) | YES | - | 수신 알람 레벨 |

### 5.3 Menu

| 컬럼명 | 타입 | NULL | 제약조건 | 설명 |
|--------|------|------|----------|------|
| id | BIGINT | NO | PK, AUTO | 기본키 |
| name | VARCHAR(100) | NO | - | 메뉴 이름 |
| url | VARCHAR(255) | YES | - | 메뉴 URL |
| icon | VARCHAR(50) | YES | - | 아이콘 클래스 |
| messageCode | VARCHAR(100) | YES | - | 다국어 메시지 코드 |
| displayOrder | INT | NO | DEFAULT 0 | 표시 순서 |
| status | VARCHAR(20) | NO | DEFAULT 'ACTIVE' | 상태 |
| has_children | BOOLEAN | NO | DEFAULT FALSE | 자식 메뉴 존재 여부 |
| parentId | BIGINT | YES | FK → Menu.id | 부모 메뉴 |

### 5.4 AlarmConfig

| 컬럼명 | 타입 | NULL | 제약조건 | 설명 |
|--------|------|------|----------|------|
| id | BIGINT | NO | PK, AUTO | 기본키 |
| alarm_name | VARCHAR(100) | NO | - | 알람 이름 |
| alarm_code | VARCHAR(50) | NO | UNIQUE | 알람 코드 |
| alarm_type | VARCHAR(50) | NO | - | 알람 유형 |
| alarm_level | VARCHAR(20) | NO | - | 알람 레벨 |
| is_enabled | BOOLEAN | NO | DEFAULT TRUE | 활성화 여부 |
| trap_level | VARCHAR(20) | YES | - | SNMP Trap 레벨 |
| url | VARCHAR(255) | YES | - | 관련 URL |

---

## 📝 변경 이력

| 버전 | 일자 | 작성자 | 내용 |
|------|------|--------|------|
| 1.0 | 2025-01-22 | 김홍석 | 최초 작성 |

---

## 🔗 관련 문서

- [보안 취약점 조치 가이드](./security-vulnerability-guide.md)
- [API 명세서](./api-specification.md)
- [시스템 아키텍처](./system-architecture.md)