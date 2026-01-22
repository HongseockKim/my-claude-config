# 프론트엔드 패턴

> AJAX, AG Grid, WebSocket, Thymeleaf 패턴 가이드

---

## 1. AJAX 패턴

### 1.1 jQuery $.ajax 기본
```javascript
$.ajax({
    url: '/api/data',
    method: 'POST',
    dataType: 'json',
    data: { zone3: selectedZone },
    success: function (response) {
        if (response.ret === 0) {
            // 성공 처리
        }
    },
    error: function (xhr) {
        GlobalErrorHandler.handle(xhr);
    }
});
```

### 1.2 GlobalErrorHandler
**경로:** `static/js/common.js`

| 상태코드 | 동작 |
|---------|------|
| 401, 409 | 로그인 페이지로 이동 |
| 403 | 권한 오류 페이지 |
| 410 | 삭제된 계정 처리 |
| 기타 | 오류 메시지 알림 |

### 1.3 JSON 요청 (POST Body)
```javascript
$.ajax({
    url: '/api/endpoint',
    method: 'POST',
    contentType: 'application/json',
    data: JSON.stringify(requestData),
    success: function (response) { ... }
});
```

---

## 2. AG Grid 패턴

### 2.1 기본 그리드 초기화
```javascript
const gridOptions = {
    columnDefs: columnDefs,
    rowData: data,
    defaultColDef: {
        flex: 1,
        minWidth: 100,
        resizable: true,
        sortable: true,
        filter: true
    },
    onGridReady: function (params) {
        gridApi = params.api;
        gridApi.sizeColumnsToFit();
    }
};

// 그리드 생성
const gridDiv = document.querySelector('#myGrid');
agGrid.createGrid(gridDiv, gridOptions);
```

### 2.2 Server-Side 무한 스크롤
**참조:** `static/js/tsGrid.js`

```javascript
const gridOptions = {
    rowModelType: 'serverSide',
    serverSideDatasource: {
        getRows: function (params) {
            $.ajax({
                url: '/api/data',
                method: 'POST',
                contentType: 'application/json',
                data: JSON.stringify({
                    startRow: params.request.startRow,
                    endRow: params.request.endRow,
                    sortModel: params.request.sortModel,
                    filterModel: params.request.filterModel
                }),
                success: function (response) {
                    params.success({
                        rowData: response.data,
                        rowCount: response.totalCount
                    });
                }
            });
        }
    },
    cacheBlockSize: 100,
    pagination: true,
    paginationPageSize: 20
};
```

### 2.3 컬럼 정의 예시
```javascript
const columnDefs = [
    {
        headerName: '이름',
        field: 'name',
        pinned: 'left',
        filter: 'agTextColumnFilter'
    },
    {
        headerName: '수량',
        field: 'count',
        filter: 'agNumberColumnFilter',
        valueFormatter: params => params.value?.toLocaleString()
    },
    {
        headerName: '날짜',
        field: 'date',
        filter: 'agDateColumnFilter',
        valueFormatter: params => dayjs(params.value).format('YYYY-MM-DD')
    }
];
```

---

## 3. WebSocket (STOMP) 패턴

### 3.1 연결 설정
**참조:** `layouts/default.html:651-675`

```javascript
function initAlarmWebSocket() {
    const socket = new SockJS('/ws');
    const stompClient = new StompJs.Client({
        webSocketFactory: () => socket,
        reconnectDelay: 5000,
        heartbeatIncoming: 4000,
        heartbeatOutgoing: 4000
    });

    stompClient.onConnect = function (frame) {
        // 구독
        stompClient.subscribe('/user/topic/alarm', function (message) {
            const data = JSON.parse(message.body);
            handleMessage(data);
        });
    };

    stompClient.onStompError = function (frame) {
        ErrorLog.log(frame.headers['message']);
    };

    stompClient.activate();
}
```

### 3.2 메시지 발송 (서버 측)
```java
@Autowired
private SimpMessagingTemplate messagingTemplate;

public void sendAlarm(String userId, AlarmDto alarm) {
    messagingTemplate.convertAndSendToUser(
        userId, "/topic/alarm", alarm
    );
}
```

---

## 4. Thymeleaf Fragment

### 4.1 레이아웃 구조
```html
<!-- layouts/default.html -->
<th:block layout:fragment="content"></th:block>
<th:block layout:fragment="style"></th:block>
<th:block layout:fragment="scripts"></th:block>
```

### 4.2 페이지에서 레이아웃 사용
```html
<html layout:decorate="~{layouts/default}">
<head>
    <th:block layout:fragment="style">
        <link rel="stylesheet" th:href="@{/css/custom.css}">
    </th:block>
</head>
<body>
    <th:block layout:fragment="content">
        <!-- 페이지 내용 -->
    </th:block>

    <th:block layout:fragment="scripts">
        <script th:src="@{/js/page.js}"></script>
    </th:block>
</body>
</html>
```

### 4.3 Fragment 동적 로딩
```javascript
// AJAX로 Fragment 가져오기
$.get('/fragment/detail?id=' + id, function (html) {
    $('#container').html(html);
});
```

```java
// Controller
@GetMapping("/fragment/detail")
public String getDetailFragment(@RequestParam Long id, Model model) {
    model.addAttribute("data", service.findById(id));
    return "fragments/detailFragment :: content";
}
```

---

## 5. ECharts 패턴

### 5.1 차트 초기화
```javascript
const chart = echarts.init(document.getElementById('chartContainer'));

const option = {
    title: { text: '제목' },
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: labels },
    yAxis: { type: 'value' },
    series: [{
        type: 'line',
        data: values
    }]
};

chart.setOption(option);

// 리사이즈 대응
window.addEventListener('resize', () => chart.resize());
```

### 5.2 데이터 갱신
```javascript
function updateChart(newData) {
    chart.setOption({
        series: [{ data: newData }]
    });
}
```

---

## 6. Zone3Util (JS)

**경로:** `static/js/common.js:58-117`

```javascript
// sp_03 → 3
Zone3Util.normalize('sp_03');  // "3"

// 3 → sp_03
Zone3Util.toCode('3');         // "sp_03"

// 표시용
Zone3Util.toDisplayText('sp_03');  // "3호기"

// 비교
Zone3Util.matches('sp_03', '3');   // true
```

---

## 7. 참조 파일

| 파일 | 역할 |
|------|------|
| `static/js/common.js` | GlobalErrorHandler, Zone3Util |
| `static/js/tsGrid.js` | AG Grid 시계열 모듈 |
| `layouts/default.html` | 레이아웃, WebSocket 초기화 |
| `config/WebSocketConfig.java` | STOMP 설정 |
