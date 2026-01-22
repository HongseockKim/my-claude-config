create table Asset
(
    idx                       int auto_increment
        primary key,
    zone1                     varchar(50)  null comment '사업장/사업소',
    zone2                     varchar(50)  null comment '발전소',
    zone3                     varchar(50)  null comment '호기',
    importance                varchar(50)  null comment '중요도',
    confidentiality           varchar(50)  null comment '정보자산 가치 평가(기밀성)',
    integrity                 varchar(50)  null comment '정보자산 가치 평가(무결성)',
    Availability              varchar(50)  null comment '정보자산 가치 평가(가용성)',
    installCategory           varchar(50)  null comment '설치구분',
    systemName                varchar(50)  null comment '시스템명',
    processWork               varchar(50)  null comment '처리업무',
    manageNumber              varchar(100) null comment '관리번호',
    manufactureCompany        varchar(50)  null comment 'H/W 제조사',
    model_name                varchar(50)  null comment '장비/모델명',
    softwareCompany           varchar(50)  null comment 'S/W/ 제조사',
    softwareName              varchar(128) null comment 'S/W 제품명',
    systemUpdateDate          datetime     null comment '시스템 업데이트 일자',
    dbms_wep_division         varchar(128) null comment 'DBMS/WEB',
    os                        varchar(100) null comment '운영체제',
    osInstallDate             datetime     null comment '설치날짜',
    introduceDate             varchar(50)  null comment '도입년월',
    asset_position            varchar(50)  null comment '자산위치',
    proprietary               varchar(50)  null comment '자산관리(소유자)',
    administrator_chief       varchar(50)  null comment '자산관리(관리자(정))',
    administrator_deputy      varchar(50)  null comment '자산관리(관리자(부))',
    contact                   varchar(50)  null comment '연락처',
    note                      varchar(50)  null comment '비고',
    registrant_date           datetime     null comment '등록 일자',
    updateDate                datetime     null comment '업데이트 일자',
    ip_address                varchar(100) null comment 'ip주소',
    mac_address               varchar(100) null comment 'Mac 주소',
    adepter_type              varchar(16)  null,
    facility                  varchar(50)  null comment '설비구분',
    inspectionCaptainUpdateAt datetime     null comment '점검대장 기준 업데이트 일자',
    category_type             varchar(50)  null,
    status                    varchar(50)  null comment '자산 운전 상태 : 0|STOP, 1|RUN, 2|FAIL, 3|COMM FAIL',
    update_status_date        datetime     null comment '자산 운전 상태 업데이트 일자',
    asset_raw_idx             bigint       null comment 'AssetRaw 테이블 참조 ID (동기화용)',
    is_disregard              tinyint      not null comment '무시상태',
    is_deleted                tinyint      not null comment '삭제 여부',
    service                   varchar(100) null comment '사용 서비스',
    secondary_office          varchar(100) null comment '2차 사업소',
    facility_classification   varchar(100) null comment '설비분류',
    vulnerability_assessment  varchar(100) null comment '취약점분석평가 수행구분',
    facility_purpose          varchar(200) null comment '설비용도',
    document_editor_list      varchar(500) null comment '문서편집프로그램 목록',
    used_services             varchar(500) null comment '사용 서비스',
    shared_folder             varchar(200) null comment '공유폴더'
)
    comment '자산_테이블';

create index idx_asset_raw_idx
    on Asset (asset_raw_idx);

create table AssetRaw
(
    idx                          int auto_increment
        primary key,
    ip                           varchar(100) null comment 'IP',
    mac                          varchar(100) null comment 'MAC',
    zone1                        varchar(50)  null comment '사업장/사업소',
    zone2                        varchar(50)  null comment '발전소',
    zone3                        varchar(50)  null comment '호기',
    reg_date                     datetime     null comment '최초 등록 일자',
    update_date                  datetime     null comment '업데이트 일자',
    adepter_type                 varchar(16)  null comment '등록 타입 : MANUAL|수동, NODE|NODE, NAC|NAC 등',
    number                       int          null comment '엑셀_넘버링',
    importance                   varchar(50)  null comment '중요도',
    confidentiality              int          null comment '기밀성',
    integrity                    int          null comment '무결성',
    availability                 int          null comment '가용성',
    facility                     varchar(50)  null comment '설비구분',
    system_name                  varchar(50)  null comment '시스템명',
    processing_work              varchar(50)  null comment '처리 업무',
    managerment_number           varchar(100) null comment '관리번호',
    model_name                   varchar(100) null comment '모델명',
    hardware_survey              varchar(50)  null comment '하드웨어 제조사',
    software_survey              varchar(50)  null comment '소프트웨어 제조사',
    software_product             varchar(100) null comment '소프트웨어 명',
    update_at                    datetime     null comment '업데이트 일자',
    inspection_captain_upadte_at datetime     null comment '점검 대장 기준 업데이트 일자',
    dbms_wep_division            varchar(100) null comment 'DBMS/WEB 구분',
    os_installation_at           varchar(100) null comment 'os 설치날짜',
    introduction_year            varchar(50)  null comment '도입연월',
    asset_position               varchar(50)  null comment '자산 위치',
    proprietary                  varchar(50)  null comment '소유자',
    administrator_chief          varchar(50)  null comment '관리자(정)',
    administrator_deputy         varchar(50)  null comment '관리자(부)',
    contact                      varchar(50)  null comment '연락처',
    note                         varchar(50)  null comment '비고',
    category                     varchar(50)  null comment '수동_자산_카테고리',
    asset_idx                    bigint       null comment 'Asset 테이블 참조 ID (동기화용)',
    secondary_office             varchar(100) null comment '2차 사업소',
    facility_classification      varchar(100) null comment '설비분류',
    vulnerability_assessment     varchar(100) null comment '취약점분석평가 수행구분',
    facility_purpose             varchar(200) null comment '설비용도',
    document_editor_list         varchar(500) null comment '문서편집프로그램 목록',
    used_services                varchar(500) null comment '사용 서비스',
    shared_folder                varchar(200) null comment '공유폴더'
);

create index idx_assetraw_asset_idx
    on AssetRaw (asset_idx);

create table BATCH_JOB_EXECUTION_SEQ
(
    ID         bigint not null,
    UNIQUE_KEY char   not null,
    constraint UNIQUE_KEY_UN
        unique (UNIQUE_KEY)
);

create table BATCH_JOB_INSTANCE
(
    JOB_INSTANCE_ID bigint       not null
        primary key,
    VERSION         bigint       null,
    JOB_NAME        varchar(100) not null,
    JOB_KEY         varchar(32)  not null,
    constraint JOB_INST_UN
        unique (JOB_NAME, JOB_KEY)
);

create table BATCH_JOB_EXECUTION
(
    JOB_EXECUTION_ID bigint        not null
        primary key,
    VERSION          bigint        null,
    JOB_INSTANCE_ID  bigint        not null,
    CREATE_TIME      datetime(6)   not null,
    START_TIME       datetime(6)   null,
    END_TIME         datetime(6)   null,
    STATUS           varchar(10)   null,
    EXIT_CODE        varchar(2500) null,
    EXIT_MESSAGE     varchar(2500) null,
    LAST_UPDATED     datetime(6)   null,
    constraint JOB_INST_EXEC_FK
        foreign key (JOB_INSTANCE_ID) references BATCH_JOB_INSTANCE (JOB_INSTANCE_ID)
);

create table BATCH_JOB_EXECUTION_CONTEXT
(
    JOB_EXECUTION_ID   bigint        not null
        primary key,
    SHORT_CONTEXT      varchar(2500) not null,
    SERIALIZED_CONTEXT text          null,
    constraint JOB_EXEC_CTX_FK
        foreign key (JOB_EXECUTION_ID) references BATCH_JOB_EXECUTION (JOB_EXECUTION_ID)
);

create table BATCH_JOB_EXECUTION_PARAMS
(
    JOB_EXECUTION_ID bigint        not null,
    PARAMETER_NAME   varchar(100)  not null,
    PARAMETER_TYPE   varchar(100)  not null,
    PARAMETER_VALUE  varchar(2500) null,
    IDENTIFYING      char          not null,
    constraint JOB_EXEC_PARAMS_FK
        foreign key (JOB_EXECUTION_ID) references BATCH_JOB_EXECUTION (JOB_EXECUTION_ID)
);

create table BATCH_JOB_SEQ
(
    ID         bigint not null,
    UNIQUE_KEY char   not null,
    constraint UNIQUE_KEY_UN
        unique (UNIQUE_KEY)
);

create table BATCH_STEP_EXECUTION
(
    STEP_EXECUTION_ID  bigint        not null
        primary key,
    VERSION            bigint        not null,
    STEP_NAME          varchar(100)  not null,
    JOB_EXECUTION_ID   bigint        not null,
    CREATE_TIME        datetime(6)   not null,
    START_TIME         datetime(6)   null,
    END_TIME           datetime(6)   null,
    STATUS             varchar(10)   null,
    COMMIT_COUNT       bigint        null,
    READ_COUNT         bigint        null,
    FILTER_COUNT       bigint        null,
    WRITE_COUNT        bigint        null,
    READ_SKIP_COUNT    bigint        null,
    WRITE_SKIP_COUNT   bigint        null,
    PROCESS_SKIP_COUNT bigint        null,
    ROLLBACK_COUNT     bigint        null,
    EXIT_CODE          varchar(2500) null,
    EXIT_MESSAGE       varchar(2500) null,
    LAST_UPDATED       datetime(6)   null,
    constraint JOB_EXEC_STEP_FK
        foreign key (JOB_EXECUTION_ID) references BATCH_JOB_EXECUTION (JOB_EXECUTION_ID)
);

create table BATCH_STEP_EXECUTION_CONTEXT
(
    STEP_EXECUTION_ID  bigint        not null
        primary key,
    SHORT_CONTEXT      varchar(2500) not null,
    SERIALIZED_CONTEXT text          null,
    constraint STEP_EXEC_CTX_FK
        foreign key (STEP_EXECUTION_ID) references BATCH_STEP_EXECUTION (STEP_EXECUTION_ID)
);

create table BATCH_STEP_EXECUTION_SEQ
(
    ID         bigint not null,
    UNIQUE_KEY char   not null,
    constraint UNIQUE_KEY_UN
        unique (UNIQUE_KEY)
);

create table Code
(
    idx           int auto_increment
        primary key,
    type_code     varchar(16)             not null,
    code          varchar(16)             not null,
    value         varchar(64)             null,
    parent_code   varchar(16)             null,
    display_order varchar(16) default '1' null
);

create table CodeGroup
(
    idx           int auto_increment
        primary key,
    code          varchar(16)             not null,
    name          varchar(16)             not null,
    display_order varchar(16) default '1' null,
    is_show       tinyint(1)              null comment '활성상태'
);

create table CodeType
(
    idx           int auto_increment
        primary key,
    group_code    varchar(16)             not null,
    code          varchar(16)             not null,
    name          varchar(16)             not null,
    parent_type   varchar(16)             null,
    display_order varchar(16) default '1' null
);

create table DataDetectionPolicy
(
    idx               bigint auto_increment
        primary key,
    zone1             varchar(255) not null,
    zone2             varchar(255) not null,
    zone3             varchar(255) not null,
    name              varchar(255) not null,
    nameMessageCode   varchar(48)  null comment '정책명 다국어 코드',
    dataSet           varchar(255) not null,
    dataCode          varchar(16)  null comment '정책 적용 대상 데이터 코드',
    dataName          varchar(255) not null,
    dataUnit          varchar(255) not null,
    policyLevel       varchar(255) not null,
    procStat          int          null comment '정책 동작 여부',
    alarmStat         int          null comment '알람화 동작 여부',
    discoverType      varchar(255) not null,
    diffVal           varchar(255) not null,
    discoverTimeRange int          null comment '값 비교 시간 범위(min)',
    stdVal            varchar(255) not null,
    detectedAt        varchar(255) not null,
    tagId             varchar(255) not null,
    value             varchar(255) not null,
    getStdVal         varchar(255) not null
);

create table DetectedIp
(
    ip                varchar(50) not null comment 'IP 주소'
        primary key,
    zone1             varchar(50) not null comment '발전사',
    zone2             varchar(50) not null comment '발전본부',
    zone3             varchar(50) not null comment '호기',
    first_detected_at datetime    not null comment '최초 탐지 일시',
    last_detected_at  datetime    not null comment '마지막 탐지 일시'
)
    comment '네트워크 상에서 발견된 IP 정보 저장 테이블';

create index zone3
    on DetectedIp (zone3);

create table DetectionPolicyAsset
(
    idx                      smallint(6) unsigned         not null comment '시퀀스'
        primary key,
    zone1                    char(20)          default '' not null comment '남동발전',
    zone2                    char(20)          default '' not null comment '삼천포발전본부',
    zone3                    char(20)          default '' not null comment '호기',
    asset_count_add          smallint unsigned default 0  not null comment '자산 수 추가를 탐지',
    asset_count_remove       smallint unsigned default 0  not null comment '자산 수 감소를 탐지',
    asset_count_stop         smallint unsigned default 0  not null comment '정지 상태 자산 탐지',
    asset_count_unauthorized smallint unsigned default 0  not null comment '비인가 자산 탐지'
)
    comment '자산 탐지정책';

create table DetectionPolicyConnection
(
    idx                       smallint(6) unsigned         not null comment '시퀀스'
        primary key,
    zone1                     char(20)          default '' not null comment '남동발전',
    zone2                     char(20)          default '' not null comment '삼천포발전본부',
    zone3                     char(20)          default '' not null comment '호기',
    conn_new_service          smallint unsigned default 0  not null comment '신규 서비스 연결 수 탐지',
    conn_size_over_session    smallint unsigned default 0  not null comment '사이즈 초과가 탐지된 세션 수',
    conn_count_over_session   smallint unsigned default 0  not null comment '카운트 초과가 탐지된 세션 수',
    conn_timeout_session      smallint unsigned default 0  not null comment '유지시간 초과가 탐지된 세션 수',
    conn_unauthorized_service smallint unsigned default 0  not null comment '비인가 서비스 연결 수'
)
    comment '자산연결 탐지정책';

create table DetectionPolicyOIS
(
    idx                              smallint(6) unsigned not null comment '시퀀스'
        primary key,
    zone1                            char(20) default ''  not null comment '남동발전',
    zone2                            char(20) default ''  not null comment '삼천포발전본부',
    zone3                            char(20) default ''  not null comment '호기',
    threshold_power_generation_full  smallint unsigned    null comment '풀가동 발전량 임계치 초과 감소',
    threshold_power_generation_half  smallint unsigned    null comment '절반 수준 가동 발전량 임계치 초과 감소',
    threshold_power_generation_range smallint unsigned    null comment '발전량 임계비율 초과 감소'
)
    comment '운전정보 탐지정책';

create table Event
(
    id          bigint auto_increment
        primary key,
    timestamp   datetime                     null comment '이벤트 발생일시',
    event_code  varchar(20)                  null comment '이벤트 코드',
    zone1       varchar(50)                  null comment '발전사',
    zone2       varchar(50)                  null comment '발전본부',
    zone3       varchar(50)                  null comment '호기',
    src_ip      varchar(50)                  null comment '출발지 IP (이벤트 발생 주체)',
    src_mac     varchar(50)                  null comment '출발지 MAC',
    src_port    int                          null comment '출발지 PORT',
    dst_ip      varchar(50)                  null comment '목적지 IP',
    dst_mac     varchar(50)                  null comment '목적지 MAC',
    dst_port    int                          null comment '목적지 PORT',
    protocol    varchar(50)                  null comment '프로토콜',
    detected_at datetime                     null comment '이벤트 탐지일시',
    detail      longtext collate utf8mb4_bin null comment '이벤트 세부 정보 JSON',
    is_ignore   tinyint                      not null comment '무시 상태',
    is_action   tinyint                      not null comment '조치사항 등록 여부'
)
    comment '자산, 운전정보, 네트워크 전체에서 발생하는 이벤트 저장 테이블';

create index idx_event_action_ignore_timestamp
    on Event (is_action, is_ignore, timestamp);

create index idx_event_code_zone3_timestamp
    on Event (event_code, zone3, timestamp);

create index idx_event_detected_zone
    on Event (detected_at desc, zone3 asc);

create index idx_event_detection_composite
    on Event (detected_at, zone3, event_code, is_ignore, is_action);

create index idx_event_dst_ip_detected_at
    on Event (dst_ip, detected_at);

create index idx_event_dst_zone_detected
    on Event (dst_ip, zone3, detected_at);

create index idx_event_performance
    on Event (detected_at desc, zone3 asc, event_code asc);

create index idx_event_src_ip_detected_at
    on Event (src_ip, detected_at);

create index idx_event_src_zone_detected
    on Event (src_ip, zone3, detected_at);

create index idx_event_violation
    on Event (event_code, detected_at, zone3, is_ignore);

create index idx_event_whitelist
    on Event (event_code, src_ip, dst_ip, dst_port, protocol);

create index idx_event_zone3_timestamp
    on Event (zone3, timestamp);

create index idx_event_zone_first
    on Event (zone3, detected_at, event_code, is_ignore, is_action);

create index idx_event_zone_time
    on Event (zone3 asc, detected_at desc);

create index idx_events_detected_at_id
    on Event (detected_at desc, id asc);

create index idx_events_dst_ip
    on Event (dst_ip asc, detected_at desc);

create index idx_events_dst_mac
    on Event (dst_mac asc, detected_at desc);

create index idx_events_dst_port
    on Event (dst_port asc, detected_at desc);

create index idx_events_event_code
    on Event (event_code asc, detected_at desc);

create index idx_events_src_ip
    on Event (src_ip asc, detected_at desc);

create index idx_events_src_mac
    on Event (src_mac asc, detected_at desc);

create index idx_events_timestamp
    on Event (timestamp);

create table EventDefinition
(
    event_code          varchar(15) default '0'    not null comment '이벤트 코드'
        primary key,
    event_name          varchar(50)                null comment '이벤트 명',
    event_type          varchar(10)                null comment 'operation / asset / connection',
    description         text                       null comment '설명',
    event_active        tinyint(1)                 not null comment '이벤트 활성여부',
    is_alarm            tinyint                    not null comment '알람활성화여부',
    alarm_level         varchar(20) default 'INFO' null comment 'INFO, WARNING, CRITICAL',
    is_action           tinyint                    not null comment '조치여부',
    is_show_time_series tinyint                    not null comment '시계열 노출 여부',
    is_favorit          tinyint                    not null comment '즐겨찾는_이상이벤트',
    is_show             tinyint(1)                 not null comment '정책 숨김처리 (숨길시 모든 토글 기능 비활성 됨)'
)
    comment '이벤트 정의 테이블 (코드와 매핑)';

create index idx_event_def_active
    on EventDefinition (event_code, event_active, is_show, event_type);

create index idx_eventdef_active
    on EventDefinition (event_code, event_active);

create table GroupCodeMapping
(
    idx       bigint auto_increment comment '매핑 고유번호'
        primary key,
    groupIdx  bigint                               not null comment '그룹 idx',
    codeIdx   bigint                               not null comment '코드 idx (사업소/발전소/호기)',
    createdAt datetime default current_timestamp() null comment '매핑 생성일시',
    constraint uk_group_code
        unique (groupIdx, codeIdx)
)
    comment '그룹-코드 매핑';

create index idx_code
    on GroupCodeMapping (codeIdx);

create index idx_group
    on GroupCodeMapping (groupIdx);

create table GroupMenuMapping
(
    idx       bigint auto_increment
        primary key,
    groupIdx  bigint                               not null comment '그룹 인덱스',
    menuId    bigint                               not null comment '메뉴 ID',
    createdAt datetime default current_timestamp() null,
    constraint uk_group_menu
        unique (groupIdx, menuId)
)
    comment '그룹별 메뉴 접근 권한' collate = utf8mb4_unicode_ci;

create index idx_group
    on GroupMenuMapping (groupIdx);

create index idx_menu
    on GroupMenuMapping (menuId);

create table GroupPermission
(
    idx            bigint auto_increment
        primary key,
    groupIdx       bigint                               not null comment '그룹 인덱스',
    resourceType   varchar(50)                          not null comment '리소스 타입: MENU, CODE, ASSET, EVENT, USER, POLICY 등',
    resourceId     varchar(100)                         null comment '특정 리소스 ID (NULL이면 타입 전체, 값 있으면 특정 리소스만)',
    permissionType varchar(20)                          not null comment '권한 타입: CREATE, READ, UPDATE, DELETE, EXECUTE',
    createdAt      datetime default current_timestamp() null,
    updatedAt      datetime default current_timestamp() null on update current_timestamp(),
    constraint uk_group_resource_permission
        unique (groupIdx, resourceType, resourceId, permissionType)
)
    comment '그룹별 리소스 작업 권한 (호기별 세밀한 권한 제어)' collate = utf8mb4_unicode_ci;

create index idx_group
    on GroupPermission (groupIdx);

create index idx_permission
    on GroupPermission (permissionType);

create index idx_resource
    on GroupPermission (resourceType, resourceId);

create table IpRangePolicy
(
    id          bigint auto_increment comment '출발지 IP 주소'
        primary key,
    zone1       varchar(50)  not null comment '발전사',
    zone2       varchar(50)  not null comment '발전본부',
    zone3       varchar(50)  not null comment '호기',
    name        varchar(255) not null comment '정책명',
    ip_range    varchar(100) not null comment 'IP 대역대 (CIDR 형태 - 192.168.0.0/24)',
    description text         null comment '정책 설명',
    created_at  datetime     not null comment '정책 생성 일시',
    updated_at  datetime     not null comment '마지막 정책 수정 일시',
    user_id     varchar(5)   not null comment '대상 사용자 ID',
    is_show     tinyint(1)   not null comment '삭제 여부'
)
    comment 'IP 대역대 설정 정책 정보를 저장하는 테이블';

create table Link
(
    src_ip            varchar(50) not null comment '출발지 IP 주소',
    dst_ip            varchar(50) not null comment '목적지 IP 주소',
    dst_port          int         not null comment '목적지 포트 번호 (서비스 포트)',
    protocol          varchar(50) not null comment '프로토콜',
    zone1             varchar(50) not null comment '발전사',
    zone2             varchar(50) not null comment '발전본부',
    zone3             varchar(50) not null comment '호기',
    first_detected_at datetime    not null comment '최초 탐지 일시',
    last_detected_at  datetime    not null comment '마지막 탐지 일시',
    is_policy         tinyint     null comment '화이트리스트 정책 추가 여부',
    primary key (src_ip, dst_ip, dst_port, protocol)
)
    comment '4-tuple (src_ip, dst_ip, dst_port, protocol) 기반의 unique 연결 정보를 저장하는 테이블';

create table Menu
(
    id           bigint               not null
        primary key,
    createdAt    datetime(6)          null,
    displayOrder int                  null,
    icon         varchar(36)          null,
    messageCode  varchar(48)          null,
    name         varchar(48)          not null,
    updatedAt    datetime(6)          null,
    url          varchar(128)         null,
    parentId     bigint               null,
    status       tinyint(1)           null,
    has_children tinyint(1) default 0 null comment '자식 메뉴 추가 버튼 표시 여부',
    constraint FKac516ygdqb8nky2qfhvmqh4ws
        foreign key (parentId) references Menu (id)
);

create table MenuRole
(
    menuId bigint                            not null,
    role   enum ('ADMIN', 'MANAGER', 'USER') null,
    constraint FKbxlhtyox9gjw1w3rru1xdvncj
        foreign key (menuId) references Menu (id)
);

create table Node
(
    mac               varchar(50) not null comment 'MAC 주소'
        primary key,
    ip                varchar(50) not null comment 'IP 주소',
    zone1             varchar(50) not null comment '발전사',
    zone2             varchar(50) not null comment '발전본부',
    zone3             varchar(50) not null comment '호기',
    first_detected_at datetime    not null comment '최초 탐지 일시',
    last_detected_at  datetime    not null comment '마지막 탐지 일시'
)
    comment '네트워크 상에서 발견된 노드 정보 저장 테이블';

create index zone3
    on Node (zone3);

create table NodeOnlySource
(
    mac               varchar(50) not null comment 'MAC 주소'
        primary key,
    ip                varchar(50) not null comment 'IP 주소',
    zone1             varchar(50) not null comment '발전사',
    zone2             varchar(50) not null comment '발전본부',
    zone3             varchar(50) not null comment '호기',
    first_detected_at datetime    not null comment '최초 탐지 일시',
    last_detected_at  datetime    not null comment '마지막 탐지 일시'
)
    comment '네트워크 상에서 발견된 노드 정보 저장 테이블 (source 정보만 저장)';

create index zone3
    on NodeOnlySource (zone3);

create table OpTag
(
    idx        bigint auto_increment
        primary key,
    tagValue   longtext     null,
    detectedAt varchar(255) null,
    zone1      varchar(255) null,
    zone2      varchar(255) null,
    zone3      varchar(255) null,
    createdAt  varchar(255) null
)
    comment '운전정보_테이블';

create index idx_optag_zone3_createdat
    on OpTag (zone3, createdAt);

create table OpTagRel_transfer
(
    id                   bigint auto_increment
        primary key,
    plant_code           varchar(10)                            null,
    tag_type             varchar(50)                            null,
    tag_pattern          varchar(100)                           null,
    description          varchar(200)                           null,
    is_active            tinyint(1) default 1                   null,
    created_at           timestamp  default current_timestamp() null,
    tag_unit             varchar(50)                            null,
    updated_at           timestamp                              null,
    collection_config_id bigint                                 null,
    node_id              varchar(255)                           null,
    namespace_index      int        default 1                   null,
    data_type            varchar(20)                            null,
    target_ip            varchar(50)                            null comment 'DROP 태그 대상 IP (DROP 태그 전용)',
    constraint uk_plant_tag_pattern
        unique (plant_code, tag_type, tag_pattern)
);

create index idx_collection_config
    on OpTagRel_transfer (collection_config_id);

create index idx_plant_code
    on OpTagRel_transfer (plant_code);

create index idx_target_ip
    on OpTagRel_transfer (target_ip);

create table OpTag_transfer
(
    idx        bigint auto_increment
        primary key,
    tagValue   longtext     null,
    detectedAt varchar(255) null,
    zone1      varchar(255) null,
    zone2      varchar(255) null,
    zone3      varchar(255) null,
    createdAt  varchar(255) null
)
    comment '운전정보_테이블';

create table PermissionPreset
(
    idx         bigint auto_increment
        primary key,
    presetName  varchar(50)                          not null comment '프리셋 이름: READ_ONLY, FULL_ACCESS, OPERATOR 등',
    description varchar(255)                         null comment '설명',
    permissions longtext collate utf8mb4_bin         null comment '권한 JSON: {"CREATE": false, "READ": true, "UPDATE": false, "DELETE": false, "EXECUTE": false}'
        check (json_valid(`permissions`)),
    createdAt   datetime default current_timestamp() null,
    updatedAt   datetime default current_timestamp() null on update current_timestamp(),
    constraint presetName
        unique (presetName)
)
    comment '권한 프리셋 (읽기전용, 전체권한 등)' collate = utf8mb4_unicode_ci;

create table ServicePortPolicy
(
    id           bigint auto_increment
        primary key,
    zone1        varchar(50)                            not null comment '발전사',
    zone2        varchar(50)                            not null comment '발전본부',
    zone3        varchar(50)                            null comment '호기',
    port         int                                    not null comment '포트 번호',
    service_name varchar(100)                           null comment '서비스명 (HTTP, SSH 등)',
    description  text                                   null comment '설명',
    created_at   timestamp  default current_timestamp() null comment '생성일시',
    updated_at   timestamp  default current_timestamp() null on update current_timestamp() comment '수정일시',
    user_id      varchar(50)                            not null comment '대상 사용자 ID',
    is_show      tinyint(1) default 1                   null comment '삭제 여부'
);

create index idx_is_show
    on ServicePortPolicy (is_show);

create index idx_zone3_port
    on ServicePortPolicy (zone3, port);

create table Stat1MinRawEvent
(
    idx               bigint unsigned auto_increment,
    timestamp         datetime                     not null comment '통계 대상의 시작 시각',
    zone1             varchar(255)                 null,
    zone2             varchar(255)                 null,
    zone3             varchar(255)                 null,
    raw_idx           bigint unsigned              not null,
    event_type        varchar(50)                  not null,
    event_type_detail varchar(50)                  not null,
    event_title       varchar(150)                 not null,
    event_content     varchar(500)                 not null,
    event_json        longtext collate utf8mb4_bin not null
        check (json_valid(`event_json`)),
    created_at        datetime                     not null comment '통계 작업이 완료된 시각',
    primary key (idx, timestamp)
)
    partition by range (to_days(`timestamp`)) (
        partition p202505 values less than (739768),
        partition p202506 values less than (739798),
        partition p_max values less than (MAXVALUE)
        );

create index idx_timestamp
    on Stat1MinRawEvent (timestamp);

create table TimeSeriesRawAsset
(
    idx        bigint unsigned auto_increment comment '시퀀스',
    time_stamp datetime                         not null comment '타임스탬프',
    zone1      varchar(20) default 'koen'       not null comment '남동발전',
    zone2      varchar(20) default 'samcheonpo' not null comment '삼천포발전본부',
    zone3      varchar(20) default ''           not null comment '호기',
    `1001`     int         default 0            not null comment '신규 IP 자산 (이벤트 개수)',
    `1002`     int         default 0            not null comment '신규 MAC 자산 (이벤트 개수)',
    `1003`     int         default 0            not null comment '운전 정지 자산 (이벤트 개수)',
    `1004`     int         default 0            not null comment '운전 이상 자산 (이벤트 개수)',
    `1005`     int         default 0            not null comment '네트워크 통신 탐지 0회 자산 (이벤트 개수)',
    `1006`     int         default 0            not null comment '네트워크 통신 장기 미탐지 자산 (이벤트 개수)',
    `1007`     int         default 0            not null comment '외부 IP 통신 자산 (이벤트 개수)',
    `1008`     int         default 0            not null comment '안전하지 않은 프로토콜 사용 자산 (이벤트 개수)',
    `1009`     int         default 0            not null comment 'IT 프로토콜 통신 컨트롤러 자산 (이벤트 개수)',
    `1010`     int         default 0            not null comment 'DHCP 서버 자산 (이벤트 개수)',
    `1011`     int         default 0            not null comment 'Ghost 통신 자산 (이벤트 개수)',
    `1012`     int         default 0            not null comment '과다 연결 자산 (이벤트 개수)',
    `1013`     int         default 0            not null comment 'SNMP 쿼리 자산 (이벤트 개수)',
    `1014`     int         default 0            not null comment '웹서버 자산 (이벤트 개수)',
    `1015`     int         default 0            not null comment 'ARP 스캔 자산 (이벤트 개수)',
    `1016`     int         default 0            not null comment '외부 ARP 전송 자산 (이벤트 개수)',
    `1017`     int         default 0            not null comment '요청되지 않은 ARP 응답 자산 (이벤트 개수)',
    `1018`     int         default 0            not null comment '중간자 ARP 공격 자산 (이벤트 개수)',
    `1019`     int         default 0            not null comment 'DNS ARPA 스캔 자산 (이벤트 개수)',
    `1020`     int         default 0            not null comment '빈 연결 다중 시도 자산 (이벤트 개수)',
    `1021`     int         default 0            not null comment '포트 스캔 자산 (이벤트 개수)',
    `1022`     int         default 0            not null comment 'IP 주소 스캔 자산 (이벤트 개수)',
    `1023`     int         default 0            not null comment '비밀번호 추측 자산 (이벤트 개수)',
    `1024`     int         default 0            not null comment 'SMTP 로그인 무차별 시도 자산 (이벤트 개수)',
    `1025`     int         default 0            not null comment 'SSH 연결 성공 자산 (이벤트 개수)',
    `1026`     int         default 0            not null comment 'SSH 버전 변경 자산 (이벤트 개수)',
    `1027`     int         default 0            not null comment 'ICMP 타임스탬프 스캔 자산 (이벤트 개수)',
    `1028`     int         default 0            not null comment 'ICMP 주소 스캔 자산 (이벤트 개수)',
    `1029`     int         default 0            not null comment 'ICMP 주소 마스크 스캔 자산 (이벤트 개수)',
    `1030`     int         default 0            not null comment '게이트웨이 주소 탐지 자산 (이벤트 개수)',
    `1031`     int         default 0            not null comment 'DHCP 스캔 자산 (이벤트 개수)',
    `1032`     int         default 0            not null comment '과도한 송신 트래픽 자산 (이벤트 개수)',
    `1033`     int         default 0            not null comment '과도한 수신 트래픽 자산 (이벤트 개수)',
    `1034`     int         default 0            not null comment 'DGA 자산 (이벤트 개수)',
    `1035`     int         default 0            not null comment '장치 IP 변경 자산 (이벤트 개수)',
    `1036`     int         default 0            not null comment 'GRE 스캔 자산 (이벤트 개수)',
    primary key (idx, time_stamp),
    constraint time_stamp_zone1_zone2_zone3
        unique (time_stamp, zone1, zone2, zone3)
)
    comment '자산 1분 통계 데이터';

create index idx_timestamp
    on TimeSeriesRawAsset (time_stamp);

create table TimeSeriesRawConnection
(
    idx        bigint unsigned auto_increment comment '시퀀스',
    time_stamp datetime                         not null comment '타임스탬프',
    zone1      varchar(20) default 'koen'       not null comment '남동발전',
    zone2      varchar(20) default 'samcheonpo' not null comment '삼천포발전본부',
    zone3      varchar(20) default ''           not null comment '호기',
    `2001`     int         default 0            not null comment '화이트리스트 위반 (이벤트 개수)',
    `2002`     int         default 0            not null comment '망간 통신 정책 위반 (이벤트 개수)',
    `2003`     int         default 0            not null comment '블랙리스트 탐지 연결 (이벤트 개수)',
    `2004`     int         default 0            not null comment '패킷 수 과다 연결 (이벤트 개수)',
    `2005`     int         default 0            not null comment '패킷 수 부족 연결 (이벤트 개수)',
    `2006`     int         default 0            not null comment '트래픽 양 과다 연결 (이벤트 개수)',
    `2007`     int         default 0            not null comment '트래픽 양 부족 연결 (이벤트 개수)',
    `2008`     int         default 0            not null comment '지속 시간 과다 연결 (이벤트 개수)',
    `2009`     int         default 0            not null comment '지속 시간 부족 연결 (이벤트 개수)',
    `2010`     int         default 0            not null comment '세션 간격 과다 연결 (이벤트 개수)',
    `2011`     int         default 0            not null comment '세션 간격 부족 연결 (이벤트 개수)',
    `2012`     int         default 0            not null comment 'DNS TXT 엔트로피 과다 (이벤트 개수)',
    `2013`     int         default 0            not null comment '무효한 DNS 응답 (이벤트 개수)',
    `2014`     int         default 0            not null comment '0번 포트 연결 (이벤트 개수)',
    `2015`     int         default 0            not null comment '다중 포트 연결 (이벤트 개수)',
    `2016`     int         default 0            not null comment '다중 재연결 시도 (이벤트 개수)',
    `2017`     int         default 0            not null comment '외부에서 내부 IP 연결 시도 (이벤트 개수)',
    `2018`     int         default 0            not null comment '외부 사설IP 연결 시도 (이벤트 개수)',
    `2019`     int         default 0            not null comment '유효하지 않은 인증서 연결 (이벤트 개수)',
    `2020`     int         default 0            not null comment 'DoH 사용 연결 (이벤트 개수)',
    `2021`     int         default 0            not null comment '과도한 전체 네트워크 트래픽 연결 (이벤트 개수)',
    `2022`     int         default 0            not null comment '의심스러운 HTTP 메서드 연결 (이벤트 개수)',
    `2023`     int         default 0            not null comment 'GRE 터널 연결 (이벤트 개수)',
    `2024`     int         default 0            not null comment '대용량 파일 전송 연결 (이벤트 개수)',
    primary key (idx, time_stamp),
    constraint time_stamp_zone1_zone2_zone3
        unique (time_stamp, zone1, zone2, zone3)
)
    comment '네트워크 1분 통계 데이터';

create index idx_timestamp
    on TimeSeriesRawConnection (time_stamp);

create table TimeSeriesRawOis
(
    idx               bigint unsigned auto_increment comment '시퀀스',
    time_stamp        datetime                         not null comment '타임스탬프',
    zone1             varchar(20) default 'koen'       not null comment '남동발전',
    zone2             varchar(20) default 'samcheonpo' not null comment '삼천포발전본부',
    zone3             varchar(20) default ''           not null comment '호기',
    generation_output int                              null comment '발전량 (MW)',
    turbine_speed     int                              null comment '터빈속도 (RPM)',
    `0001`            int         default 0            not null comment '발전량 10분 과다 변화량 (MW)',
    `0002`            int         default 0            not null comment '터빈속도 임계값 위반 (RPM)',
    `0003`            int         default 0            not null comment '발전량 10분 과다 변화율 (%)',
    `0004`            int         default 0            not null comment '터빈속도 임계율 위반 (%)',
    primary key (idx, time_stamp),
    constraint time_stamp_zone1_zone2_zone3
        unique (time_stamp, zone1, zone2, zone3)
)
    comment '운전정보 1분 통계 데이터';

create index idx_timestamp
    on TimeSeriesRawOis (time_stamp);

create table TopologyDevice
(
    idx          bigint unsigned auto_increment
        primary key,
    zone1        varchar(255) not null,
    zone2        varchar(255) not null,
    zone3        varchar(255) not null,
    switchSlotNo varchar(255) not null,
    portNo       varchar(255) not null,
    assetIdx     varchar(255) not null,
    name         varchar(255) not null,
    portCount    varchar(255) not null,
    slotNo       varchar(255) not null,
    switchIdx    bigint       not null
);

create table TopologySwitch
(
    idx       bigint unsigned auto_increment
        primary key,
    zone1     varchar(255) not null,
    zone2     varchar(255) not null,
    zone3     varchar(255) not null,
    name      varchar(255) null,
    portCount varchar(255) not null,
    slotNo    varchar(255) not null,
    assetIdx  varchar(255) not null
);

create table User
(
    idx                      bigint auto_increment
        primary key,
    createdAt                datetime(6)                       null,
    email                    varchar(255)                      null,
    name                     varchar(255)                      not null,
    password                 varchar(255)                      not null,
    role                     enum ('ADMIN', 'MANAGER', 'USER') not null,
    updatedAt                datetime(6)                       null,
    userId                   varchar(255)                      not null,
    status                   varchar(255)                      null,
    password_change_required tinyint(1) default 1              null,
    failed_attempt           int        default 0              not null,
    lock_time                datetime                          null,
    constraint UK5ir1yd4k8cjxl4oaeksk9mu3a
        unique (userId)
);

create table UserGroup
(
    idx           bigint auto_increment comment '그룹 고유번호'
        primary key,
    groupName     varchar(100)                            not null comment '그룹명',
    groupCode     varchar(50)                             not null comment '그룹 코드',
    description   varchar(255)                            null comment '그룹 설명',
    status        varchar(20) default 'Y'                 null comment '상태 (Y:활성, N:비활성)',
    createdAt     datetime    default current_timestamp() null comment '생성일시',
    updatedAt     datetime    default current_timestamp() null on update current_timestamp() comment '수정일시',
    alarm_enabled tinyint(1)  default 0                   null comment '그룹 알람 수신 활성화 여부',
    alarm_level   varchar(20) default 'INFO'              null comment '그룹 알람 수신 최소 레벨',
    constraint groupCode
        unique (groupCode),
    constraint chk_alarm_level
        check (`alarm_level` in ('INFO', 'WARNING', 'CRITICAL'))
)
    comment '사용자 그룹';

create index idx_usergroup_alarm_enabled
    on UserGroup (alarm_enabled);

create index idx_usergroup_alarm_level
    on UserGroup (alarm_level);

create index idx_usergroup_code
    on UserGroup (groupCode);

create index idx_usergroup_status
    on UserGroup (status);

create table UserGroupMapping
(
    idx       bigint auto_increment comment '매핑 고유번호'
        primary key,
    userIdx   bigint                               not null comment '사용자 idx',
    groupIdx  bigint                               not null comment '그룹 idx',
    createdAt datetime default current_timestamp() null comment '매핑 생성일시',
    constraint uk_user_group
        unique (userIdx, groupIdx),
    constraint UserGroupMapping_ibfk_1
        foreign key (userIdx) references User (idx)
            on delete cascade,
    constraint UserGroupMapping_ibfk_2
        foreign key (groupIdx) references UserGroup (idx)
            on delete cascade
)
    comment '사용자-그룹 매핑';

create index idx_group
    on UserGroupMapping (groupIdx);

create index idx_user
    on UserGroupMapping (userIdx);

create table WhitelistPolicy
(
    id          bigint auto_increment
        primary key,
    zone1       varchar(50)               not null comment '발전사',
    zone2       varchar(50)               not null comment '발전본부',
    zone3       varchar(50)               not null comment '호기',
    name        varchar(255)              not null comment '정책명',
    src_ip      varchar(50)               not null comment '출발지 IP 주소',
    src_port    int(11) unsigned zerofill null comment '출발지 PORT 번호 (Null = wildcard)',
    dst_ip      varchar(50)               not null comment '목적지 IP 주소',
    dst_port    int                       not null comment '목적지 PORT 번호',
    protocol    varchar(50)               null comment '프로토콜 (Null = wildcard)',
    description text                      null comment '정책 설명',
    created_at  datetime                  not null comment '정책 생성 일시',
    updated_at  datetime                  not null comment '마지막 정책 수정 일시',
    user_id     varchar(50)               not null comment '대상 사용자 ID',
    is_show     tinyint(1)                not null comment '삭제 여부'
)
    comment '화이트리스트 정책 정보를 저장하는 테이블';

create index idx_whitelist_lookup
    on WhitelistPolicy (src_ip, dst_ip, dst_port, protocol, is_show);

create table alarm_config
(
    id          bigint auto_increment
        primary key,
    alarm_name  varchar(100)                            not null comment '알람명',
    alarm_code  varchar(50)                             not null comment '알람코드',
    alarm_type  varchar(30)                             null comment '알람타입',
    alarm_level varchar(20) default 'INFO'              null comment '알람레벨',
    is_enabled  tinyint(1)  default 1                   null comment '알랑활성화상태',
    description text                                    null comment '알람주석',
    created_at  timestamp   default current_timestamp() null comment '알람생성일',
    updated_at  timestamp   default current_timestamp() null on update current_timestamp() comment '알람수정일',
    trap_level  varchar(30)                             null comment '조치사항레벨',
    url         varchar(50)                             null comment '알람링크',
    constraint alarm_code
        unique (alarm_code)
)
    comment '알람 설정';

create table alarm_action
(
    id                    bigint auto_increment
        primary key,
    alarm_config_id       bigint                                not null comment '알람설정_아이디',
    action_order          int       default 1                   null comment '조치사항레벨',
    action_content        text                                  not null comment '조차사항내용',
    created_at            timestamp default current_timestamp() null,
    action_create_manager varchar(50)                           null comment '조치사항_담당자',
    alarm_history_id      int                                   null comment '알람리스트_아이디',
    constraint alarm_action_ibfk_1
        foreign key (alarm_config_id) references alarm_config (id)
            on delete cascade
)
    comment '조치사항_테이블';

create index idx_alarm_config
    on alarm_action (alarm_config_id);

create table alarm_history
(
    id             bigint auto_increment
        primary key,
    alarm_code     varchar(50)                            not null comment '알람 코드 (alarm_config 참조)',
    alarm_type     varchar(20)                            not null comment '알람 타입 (ASSET/NETWORK/OPERATION/AUDIT)',
    alarm_level    varchar(20)                            not null comment '알람 레벨 (INFO/WARNING/CRITICAL/FATAL)',
    title          varchar(200)                           not null comment '알람 제목',
    message        text                                   null comment '알람 내용',
    source_ip      varchar(50)                            null comment '발생 IP',
    source_name    varchar(100)                           null comment '발생 장비명',
    user_id        varchar(50)                            null comment '대상 사용자 ID',
    is_read        tinyint(1) default 0                   null comment '읽음 여부',
    read_date      datetime                               null comment '읽은 시간',
    created_date   datetime   default current_timestamp() null comment '발생 시간',
    url            varchar(50)                            null,
    action_date    datetime                               null,
    action_manager varchar(50)                            null comment '조치자',
    action_status  tinyint(1) default 0                   null,
    is_show        tinyint(1) default 0                   null comment '삭제여부'
)
    comment '알람 발생 이력';

create index idx_created
    on alarm_history (created_date);

create index idx_user_read
    on alarm_history (user_id, is_read);

create table alarm_level_code
(
    code        varchar(20)                            not null comment '알람코드(CRITICAL,INFO,WARNING)'
        primary key,
    name        varchar(50)                            not null comment '알람코드표시명',
    priority    int                                    not null comment '우선순위',
    color_class varchar(20)                            null comment '알람별_색상',
    description text                                   null comment '알람_주석',
    is_active   tinyint(1) default 1                   null comment '알람코드_활성화상태',
    created_at  timestamp  default current_timestamp() null comment '알람생성일'
)
    comment '알람_레벨_코드';

create table alarm_manager
(
    id              bigint auto_increment
        primary key,
    alarm_config_id bigint                                 not null,
    user_name       varchar(100)                           not null,
    email           varchar(100)                           null,
    phone           varchar(20)                            null,
    is_primary      tinyint(1) default 0                   null,
    created_at      timestamp  default current_timestamp() null,
    role            enum ('ADMIN', 'MANAGER', 'USER')      null,
    user_id         varchar(50)                            null,
    constraint alarm_manager_ibfk_1
        foreign key (alarm_config_id) references alarm_config (id)
            on delete cascade
)
    comment '알람_담당자_테이블';

create index idx_alarm_config
    on alarm_manager (alarm_config_id);

create table alarm_type_code
(
    code          varchar(50)                            not null comment '알람타입별_코드'
        primary key,
    name          varchar(100)                           not null comment '알람타입_명',
    category      varchar(50)                            null comment '알람_카테고리',
    description   text                                   null comment '알람주석',
    is_active     tinyint(1) default 1                   null comment '알람타입활성화상태',
    display_order int        default 0                   null comment '우선순위',
    created_at    timestamp  default current_timestamp() null comment '알람타입생성일',
    url           varchar(50)                            null comment '알람링크'
)
    comment '알람_타입별_설정';

create table audit_log_settings
(
    id             bigint auto_increment
        primary key,
    is_alarm       char      default 'N'                 null comment '알람 여부',
    created_date   timestamp default current_timestamp() null,
    updated_date   timestamp default current_timestamp() null on update current_timestamp(),
    user_group_idx bigint                                not null comment '그룹 FK',
    constraint uk_user_group
        unique (user_group_idx),
    constraint fk_audit_settings_group
        foreign key (user_group_idx) references UserGroup (idx)
            on delete cascade
)
    comment '감사로그 설정 테이블';

create table dashboard_templates
(
    id            bigint auto_increment
        primary key,
    template_name varchar(100)                           not null comment '템플릿 이름',
    description   varchar(255)                           null comment '템플릿 설명',
    is_default    tinyint(1) default 0                   null comment '기본 템플릿 여부',
    created_at    timestamp  default current_timestamp() null comment '생성일시',
    updated_at    timestamp  default current_timestamp() null on update current_timestamp() comment '수정일시',
    zone_code     varchar(20)                            null comment '호기 코드 (null=전체, sp_03=3호기, sp_04=4호기)',
    constraint template_name
        unique (template_name)
)
    comment '대시보드 템플릿';

create table dashboard_template_widgets
(
    id            bigint auto_increment
        primary key,
    template_id   bigint                                 not null comment '템플릿 ID',
    fragment_name varchar(100)                           not null comment 'Fragment 파일명',
    widget_title  varchar(100)                           not null comment '위젯 제목',
    x_position    int                                    not null comment 'X 좌표',
    y_position    int                                    not null comment 'Y 좌표',
    width         int                                    not null comment '너비',
    height        int                                    not null comment '높이',
    is_visible    tinyint(1) default 1                   null comment '표시 여부',
    sort_order    int        default 0                   null comment '정렬 순서',
    created_at    timestamp  default current_timestamp() null comment '생성일시',
    updated_at    timestamp  default current_timestamp() null on update current_timestamp() comment '수정일시',
    zone_code     varchar(20)                            null comment '호기 코드 (null이면 모든
   호기에서 표시)',
    constraint dashboard_template_widgets_ibfk_1
        foreign key (template_id) references dashboard_templates (id)
            on delete cascade
)
    comment '대시보드 템플릿 위젯';

create index idx_dashboard_template_widgets_zone_code
    on dashboard_template_widgets (zone_code);

create index idx_template_sort
    on dashboard_template_widgets (template_id, sort_order);

create index idx_template_visible
    on dashboard_template_widgets (template_id, is_visible);

create index idx_is_default
    on dashboard_templates (is_default);

create table dashboard_widget_layout
(
    id            bigint auto_increment
        primary key,
    widget_id     varchar(100)                                   not null comment '위젯 식별자 (generationBox, assetEventList 등)',
    widget_type   enum ('chart', 'list', 'status', 'pie', 'bar') not null comment '위젯 타입',
    widget_title  varchar(100)                                   not null comment '위젯 제목',
    x_position    int                                            not null comment 'GridStack X 좌표 (0~11)',
    y_position    int                                            not null comment 'GridStack Y 좌표',
    width         int                                            not null comment 'GridStack 너비 (1~12)',
    height        int                                            not null comment 'GridStack 높이',
    widget_config longtext collate utf8mb4_bin                   null comment '위젯별 설정 (차트 옵션, API 엔드포인트 등)'
        check (json_valid(`widget_config`)),
    is_visible    tinyint(1) default 1                           null comment '표시 여부',
    sort_order    int        default 0                           null comment '정렬 순서',
    created_at    timestamp  default current_timestamp()         null,
    updated_at    timestamp  default current_timestamp()         null on update current_timestamp(),
    constraint unique_widget
        unique (widget_id)
)
    comment '대시보드 위젯 레이아웃 (전역 관리)';

create index idx_visible_order
    on dashboard_widget_layout (is_visible, sort_order);

create table detection_policy
(
    id           bigint auto_increment comment '설정 ID'
        primary key,
    config_key   varchar(100)                                          not null comment '설정 키 (예: operation.power.threshold)',
    config_value varchar(500)                                          null comment '설정 값',
    data_type    enum ('NUMBER', 'BOOLEAN', 'STRING', 'DECIMAL')       not null comment '데이터 타입',
    category     enum ('OPERATION', 'ASSET', 'CONNECTION', 'SECURITY') null,
    description  varchar(500)                                          null comment '설정 설명',
    unit         varchar(20)                                           null comment '단위 (MW, RPM, 개 등)',
    is_active    tinyint(1) default 1                                  null comment '활성화 여부',
    created_at   timestamp  default current_timestamp()                null comment '생성일시',
    updated_at   timestamp  default current_timestamp()                null on update current_timestamp() comment '수정일시',
    updated_by   varchar(50)                                           null comment '수정자',
    constraint config_key
        unique (config_key)
)
    comment '사용 하지 않는 정책 테이블 - 2025-10-22';

create index idx_active
    on detection_policy (is_active);

create index idx_category
    on detection_policy (category);

create index idx_config_key
    on detection_policy (config_key);

create table event_action_log
(
    id               bigint auto_increment
        primary key,
    event_id         bigint                                not null,
    event_code       varchar(20)                           null,
    action_type      varchar(50)                           not null,
    action_user      varchar(100)                          not null,
    action_story     text                                  null,
    src_ip           varchar(45)                           null,
    dst_ip           varchar(45)                           null,
    action_timestamp timestamp default current_timestamp() null,
    created_at       timestamp default current_timestamp() null,
    zone1            varchar(50)                           null,
    zone2            varchar(50)                           null,
    zone3            varchar(50)                           null,
    constraint event_action_log_ibfk_1
        foreign key (event_id) references Event (id)
);

create index idx_action_type
    on event_action_log (action_type);

create index idx_event_id
    on event_action_log (event_id);

create index idx_timestamp
    on event_action_log (action_timestamp);

create table op_collection_config
(
    id                bigint auto_increment
        primary key,
    config_name       varchar(100)                             not null,
    plant_code        varchar(10)                              not null,
    server_ip         varchar(50)                              not null,
    server_port       int          default 4840                null,
    endpoint_url      varchar(255) default '/OPC'              null,
    auth_type         varchar(20)  default 'ANONYMOUS'         null,
    username          varchar(100)                             null,
    password          varchar(255)                             null,
    is_active         tinyint(1)   default 1                   null,
    last_connected_at timestamp                                null,
    connection_status varchar(20)  default 'DISCONNECTED'      null,
    created_at        timestamp    default current_timestamp() null,
    updated_at        timestamp    default current_timestamp() null on update current_timestamp(),
    constraint config_name
        unique (config_name)
);

create table OpTagRel
(
    id                   bigint auto_increment
        primary key,
    plant_code           varchar(10)                             null,
    tag_type             varchar(50)                             null,
    tag_pattern          varchar(100)                            null,
    description          varchar(200)                            null,
    is_active            tinyint(1)  default 1                   null,
    created_at           timestamp   default current_timestamp() null,
    tag_unit             varchar(50)                             null,
    updated_at           timestamp                               null,
    collection_config_id bigint                                  null,
    node_id              varchar(255)                            null,
    namespace_index      int         default 1                   null,
    data_type            varchar(20)                             null,
    target_ip            varchar(50)                             null comment 'DROP 태그 대상 IP (DROP 태그 전용)',
    tag_purpose          varchar(20) default 'COLLECTION'        not null comment '태그 용도: COLLECTION(수집용), TRANSFER(송부용)',
    constraint uk_plant_tag_pattern
        unique (plant_code, tag_type, tag_pattern),
    constraint OpTagRel_ibfk_1
        foreign key (collection_config_id) references op_collection_config (id)
);

create index idx_collection_config
    on OpTagRel (collection_config_id);

create index idx_optag_purpose
    on OpTagRel (tag_purpose, plant_code);

create index idx_plant_code
    on OpTagRel (plant_code);

create index idx_target_ip
    on OpTagRel (target_ip);

create index idx_plant_code
    on op_collection_config (plant_code);

create table op_transfer_config
(
    id                bigint auto_increment
        primary key,
    config_name       varchar(100)                             not null,
    plant_code        varchar(10)                              not null,
    server_ip         varchar(50)                              not null,
    server_port       int          default 4840                null,
    endpoint_url      varchar(255) default '/OPC'              null,
    auth_type         varchar(20)  default 'ANONYMOUS'         null,
    username          varchar(100)                             null,
    password          varchar(255)                             null,
    is_active         tinyint(1)   default 1                   null,
    last_connected_at timestamp                                null,
    connection_status varchar(20)  default 'DISCONNECTED'      null,
    created_at        timestamp    default current_timestamp() null,
    updated_at        timestamp    default current_timestamp() null on update current_timestamp(),
    constraint config_name
        unique (config_name)
);

create index idx_plant_code
    on op_transfer_config (plant_code);

create table report
(
    id          bigint auto_increment
        primary key,
    title       varchar(200)                            not null comment '리포트 제목',
    zone_code   varchar(20)                             null comment '호기 코드',
    report_date date                                    null comment '리포트 기준일',
    created_by  varchar(50)                             null comment '작성자',
    created_at  datetime    default current_timestamp() null,
    updated_at  datetime    default current_timestamp() null on update current_timestamp(),
    status      varchar(20) default 'DRAFT'             null comment 'DRAFT, PUBLISHED'
)
    comment '리포트';

create index idx_report_created_by
    on report (created_by);

create index idx_report_zone_code
    on report (zone_code);

create table report_widget
(
    id          bigint auto_increment
        primary key,
    report_id   bigint        not null comment '리포트 ID',
    widget_type varchar(50)   not null comment 'TEXT, CHART, TABLE',
    widget_key  varchar(100)  null comment '차트 종류 (asset_status 등)',
    chart_type  varchar(20)   null,
    content     text          null comment '텍스트 내용',
    grid_x      int default 0 null comment 'GridStack x 좌표',
    grid_y      int default 0 null comment 'GridStack y 좌표',
    grid_w      int default 6 null comment '너비',
    grid_h      int default 4 null comment '높이',
    sort_order  int default 0 null,
    constraint fk_report_widget_report
        foreign key (report_id) references report (id)
            on delete cascade
)
    comment '리포트 위젯';

create index idx_report_widget_report_id
    on report_widget (report_id);

create table snap_asset
(
    idx                     int auto_increment
        primary key,
    zone1                   varchar(50) null comment '사업소',
    zone2                   varchar(50) null comment '발전소',
    zone3                   varchar(50) null comment '호기',
    hash                    varchar(50) null comment '해쉬값',
    asset_data_json_before  longtext    null comment '변경 전 자산 정보',
    asset_data_json_current longtext    null comment '변경 후 자산 정보',
    type                    varchar(50) null comment '타입 : count_new_asset|신규 자산, count_stop_asset|정지 자산, hash|현재 자산(Asset) hash값',
    create_date             datetime    null comment '생성일자'
);

create table stats_10min
(
    idx               bigint unsigned auto_increment comment '시퀀스',
    time_stamp        datetime                         not null comment '통계 대상의 시작 시각',
    zone1             varchar(20) default 'koen'       not null comment '남동발전',
    zone2             varchar(20) default 'samcheonpo' not null comment '삼천포발전본부',
    zone3             varchar(20) default ''           not null comment '호기',
    generation_output int                              null,
    turbine_speed     int                              null,
    `0001`            int         default 0            not null,
    `0002`            int         default 0            not null,
    `0003`            int         default 0            not null,
    `0004`            int         default 0            not null,
    `1001`            int         default 0            not null,
    `1002`            int         default 0            not null,
    `1003`            int         default 0            not null,
    `1004`            int         default 0            not null,
    `1005`            int         default 0            not null,
    `1006`            int         default 0            not null,
    `1007`            int         default 0            not null,
    `1008`            int         default 0            not null,
    `1009`            int         default 0            not null,
    `1010`            int         default 0            not null,
    `1011`            int         default 0            not null,
    `1012`            int         default 0            not null,
    `1013`            int         default 0            not null,
    `1014`            int         default 0            not null,
    `1015`            int         default 0            not null,
    `1016`            int         default 0            not null,
    `1017`            int         default 0            not null,
    `1018`            int         default 0            not null,
    `1019`            int         default 0            not null,
    `1020`            int         default 0            not null,
    `1021`            int         default 0            not null,
    `1022`            int         default 0            not null,
    `1023`            int         default 0            not null,
    `1024`            int         default 0            not null,
    `1025`            int         default 0            not null,
    `1026`            int         default 0            not null,
    `1027`            int         default 0            not null,
    `1028`            int         default 0            not null,
    `1029`            int         default 0            not null,
    `1030`            int         default 0            not null,
    `1031`            int         default 0            not null,
    `1032`            int         default 0            not null,
    `1033`            int         default 0            not null,
    `1034`            int         default 0            not null,
    `1035`            int         default 0            not null,
    `1036`            int         default 0            not null,
    `2001`            int         default 0            not null,
    `2002`            int         default 0            not null,
    `2003`            int         default 0            not null,
    `2004`            int         default 0            not null,
    `2005`            int         default 0            not null,
    `2006`            int         default 0            not null,
    `2007`            int         default 0            not null,
    `2008`            int         default 0            not null,
    `2009`            int         default 0            not null,
    `2010`            int         default 0            not null,
    `2011`            int         default 0            not null,
    `2012`            int         default 0            not null,
    `2013`            int         default 0            not null,
    `2014`            int         default 0            not null,
    `2015`            int         default 0            not null,
    `2016`            int         default 0            not null,
    `2017`            int         default 0            not null,
    `2018`            int         default 0            not null,
    `2019`            int         default 0            not null,
    `2020`            int         default 0            not null,
    `2021`            int         default 0            not null,
    `2022`            int         default 0            not null,
    `2023`            int         default 0            not null,
    `2024`            int         default 0            not null,
    primary key (idx, time_stamp),
    constraint time_stamp_zone1_zone2_zone3
        unique (time_stamp, zone1, zone2, zone3)
)
    comment '시계열 10분 통계 데이터';

create index idx_timestamp
    on stats_10min (time_stamp);

create table stats_1min
(
    idx               bigint unsigned auto_increment comment '시퀀스',
    time_stamp        datetime                         not null comment '통계 대상의 시작 시각',
    zone1             varchar(20) default 'koen'       not null comment '남동발전',
    zone2             varchar(20) default 'samcheonpo' not null comment '삼천포발전본부',
    zone3             varchar(20) default ''           not null comment '호기',
    generation_output int                              null,
    turbine_speed     int                              null,
    `0001`            int         default 0            not null,
    `0002`            int         default 0            not null,
    `0003`            int         default 0            not null,
    `0004`            int         default 0            not null,
    `1001`            int         default 0            not null,
    `1002`            int         default 0            not null,
    `1003`            int         default 0            not null,
    `1004`            int         default 0            not null,
    `1005`            int         default 0            not null,
    `1006`            int         default 0            not null,
    `1007`            int         default 0            not null,
    `1008`            int         default 0            not null,
    `1009`            int         default 0            not null,
    `1010`            int         default 0            not null,
    `1011`            int         default 0            not null,
    `1012`            int         default 0            not null,
    `1013`            int         default 0            not null,
    `1014`            int         default 0            not null,
    `1015`            int         default 0            not null,
    `1016`            int         default 0            not null,
    `1017`            int         default 0            not null,
    `1018`            int         default 0            not null,
    `1019`            int         default 0            not null,
    `1020`            int         default 0            not null,
    `1021`            int         default 0            not null,
    `1022`            int         default 0            not null,
    `1023`            int         default 0            not null,
    `1024`            int         default 0            not null,
    `1025`            int         default 0            not null,
    `1026`            int         default 0            not null,
    `1027`            int         default 0            not null,
    `1028`            int         default 0            not null,
    `1029`            int         default 0            not null,
    `1030`            int         default 0            not null,
    `1031`            int         default 0            not null,
    `1032`            int         default 0            not null,
    `1033`            int         default 0            not null,
    `1034`            int         default 0            not null,
    `1035`            int         default 0            not null,
    `1036`            int         default 0            not null,
    `2001`            int         default 0            not null,
    `2002`            int         default 0            not null,
    `2003`            int         default 0            not null,
    `2004`            int         default 0            not null,
    `2005`            int         default 0            not null,
    `2006`            int         default 0            not null,
    `2007`            int         default 0            not null,
    `2008`            int         default 0            not null,
    `2009`            int         default 0            not null,
    `2010`            int         default 0            not null,
    `2011`            int         default 0            not null,
    `2012`            int         default 0            not null,
    `2013`            int         default 0            not null,
    `2014`            int         default 0            not null,
    `2015`            int         default 0            not null,
    `2016`            int         default 0            not null,
    `2017`            int         default 0            not null,
    `2018`            int         default 0            not null,
    `2019`            int         default 0            not null,
    `2020`            int         default 0            not null,
    `2021`            int         default 0            not null,
    `2022`            int         default 0            not null,
    `2023`            int         default 0            not null,
    `2024`            int         default 0            not null,
    primary key (idx, time_stamp),
    constraint time_stamp_zone1_zone2_zone3
        unique (time_stamp, zone1, zone2, zone3)
)
    comment '시계열 1분 통계 데이터';

create index idx_stats_1min_zone3_timestamp
    on stats_1min (zone3, time_stamp);

create index idx_timestamp
    on stats_1min (time_stamp);

create table system_activity_log
(
    id            bigint auto_increment
        primary key,
    timestamp     timestamp(3)                                                          null comment '로그등록시간',
    log_id        varchar(36)                                                           not null comment '로그아이디',
    log_type      enum ('USER_ACTION', 'SECURITY_EVENT', 'SYSTEM_ERROR', 'MENU_ACCESS') not null comment '로그타입',
    category      varchar(50)                                                           not null comment '로그카테고리',
    action        varchar(50)                                                           not null comment '로그조치사항',
    severity      enum ('INFO', 'WARN', 'ERROR', 'CRITICAL') default 'INFO'             null comment '로그레벨',
    user_id       varchar(50)                                                           null comment '로그액션사용자아이디',
    user_name     varchar(100)                                                          null comment '로그액션사용자명',
    user_role     varchar(50)                                                           null comment '로그액션사용자권한',
    session_id    varchar(100)                                                          null comment '센션_아이디',
    ip_address    varchar(45)                                                           null comment '발생_ip',
    user_agent    text                                                                  null,
    resource_type varchar(50)                                                           null comment '로그발생리소스타입',
    resource_id   varchar(100)                                                          null comment '로그발생리소스고유값',
    resource_name varchar(200)                                                          null comment '로그발생리소스명',
    details       longtext collate utf8mb4_bin                                          null comment '로그상세'
        check (json_valid(`details`)),
    result        enum ('SUCCESS', 'FAILURE', 'PARTIAL')     default 'SUCCESS'          null comment '로그결과',
    error_message text                                                                  null,
    duration_ms   int unsigned                                                          null,
    constraint log_id
        unique (log_id)
);

create index idx_category_action
    on system_activity_log (category, action);

create index idx_log_type_time
    on system_activity_log (log_type, timestamp);

create index idx_resource
    on system_activity_log (resource_type, resource_id);

create index idx_severity_time
    on system_activity_log (severity, timestamp);

create index idx_user_time
    on system_activity_log (user_id, timestamp);

create table system_config
(
    id           bigint auto_increment
        primary key,
    config_key   varchar(100)                          not null,
    config_value varchar(500)                          null,
    description  varchar(500)                          null,
    updated_at   timestamp default current_timestamp() null on update current_timestamp(),
    config_name  varchar(255)                          null,
    constraint config_key
        unique (config_key)
)
    comment '시스템 전역 설정';

create table topology_net
(
    idx         int auto_increment
        primary key,
    zone1       varchar(50) null,
    zone2       varchar(50) null,
    zone3       varchar(50) null,
    name        varchar(50) null comment '망 이름',
    switch_list longtext    null comment '스위치 리스트',
    able        varchar(50) null comment '사용/미사용',
    create_at   timestamp   null comment '생성 일자',
    update_at   timestamp   null comment '수정 일자'
)
    comment '망';

create table topology_switch
(
    idx              int auto_increment
        primary key,
    zone1            varchar(50)                         null,
    zone2            varchar(50)                         null,
    zone3            varchar(50)                         null,
    ip               varchar(15)                         null comment '스위치 IP',
    subnet_mask      varchar(15) default '255.255.255.0' null,
    name             varchar(50)                         null comment '스위치 이름',
    port_ip_tag_list longtext                            null comment '스위치 포트별 IP, op_tag 리스트 ',
    create_at        timestamp                           null comment '생성 일자',
    update_at        timestamp                           null comment '수정 일자'
)
    comment '스위치';

create
definer = ailog@`%` procedure InsertLastThirtyMinutesData()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE curr_time DATETIME;
    DECLARE total_records INT DEFAULT 0;


    SET curr_time  = NOW();


    WHILE i < 1440 DO

        INSERT INTO stats_1min (
            `timestamp`,
            `generation_output`,
            `turbine_speed`,
            `count_total_asset`,
            `count_drive_asset`,
            `count_stop_asset`,
            `count_unauthorized_asset`,
            `count_total_connection`,
            `count_new_connection`,
            `count_over_threshold`
        ) VALUES (
            DATE_SUB(curr_time, INTERVAL i MINUTE),
            FLOOR(RAND() * 1000000000),
            FLOOR(RAND() * 65535),
            FLOOR(RAND() * 65535),
            FLOOR(RAND() * 65535),
            FLOOR(RAND() * 65535),
            FLOOR(RAND() * 65535),
            FLOOR(RAND() * 65535),
            FLOOR(RAND() * 65535),
            FLOOR(RAND() * 65535)
        );

        SET total_records = total_records + 1;
        SET i = i + 1;
END WHILE;


SELECT CONCAT('성공적으로 ', i, '개의 레코드가 삽입되었습니다.') AS result;
END;

