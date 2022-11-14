
## 龙骨交易合约

* 添加市场

```
function addMarket(
    uint256 _orderId,
    uint256 _tokenId,
    uint256 _price,
    uint256 _amount,
    uint8 _exType,
    uint256 _minPrice,
    uint256 _maxPrice,
    uint256 _timeHours
)
```

uin256 _orderId 订单ID后端生成
uint256 _tokenId  龙骨ID
uint256 _price 出售DMS价格
uint256 _amount 出售龙骨数量
uint8 _exType 类型 1=普通 2=竞拍
uint256 _minPrice 竞拍最小价格（普通传0）
uint256 _maxPrice 竞拍最大价格（普通传0）
uint256 _timeHours 竞拍时长（小时）

[mq]
```
event AddMarket(
    address indexed from,
    uint256 tokenId,
    uint256 price,
    uint256 amount,
    uint8 exType,
    uint256 minPrice,
    uint256 maxPrice,
    uint256 timeHours,
    uint256 createTime,
    uint256 orderId
);

queue = bone_add_market

body = 

普通
{"from":"0xabc","tokenId":10000,"price":1e18,"amount":10,"exType":1,"minPrice":0,"maxPrice":0,"timeHours":0,"createTime":12345678,"orderId":100}

竞拍
{"from":"0xabc","tokenId":10000,"price":0,"amount":10,"exType":2,"minPrice":1e18,"maxPrice":10e18,"timeHours":24,"createTime":12345678,"orderId":100}
```


* 下架市场

```
function removeMarket(uint256 _orderId)
```

_orderId 订单ID

[mq]

```
event RemoveMarket(
    address indexed from,
    uint256 orderId,
    uint256 tokenId,
    uint256 amount
);

queue = bone_remove_market

body = {"from":"0xabc","orderId":100,"tokenId":10000,"amount":10}

```

* 查看当前出售价格

```
function exchangePrice(uint256 _orderId)
public
view
returns (uint256, uint256)
```

入参 _orderId 订单ID

出参

第1参数值 是 价格

第2参数值 是 已过去时长（小时）


* 交易成交

```
function exchange(uint256 _orderId, uint256 _amount)
```

_orderId 订单ID

_amount 成交数量

[mq]

```
event Exchange(
    address indexed from,
    address to,
    uint256 tokenId,
    uint256 price,
    uint256 amount,
    uint256 fee,
    uint8 exType,
    uint256 orderId
);

queue = bone_exchange

body = 

普通
{"from":"0xabc","to":"0xbcd","tokenId":10000,"price":1e18,"amount":10,"fee":1e17,"exType":1,"orderId":100}

竞拍
{"from":"0xabc","to":"0xbcd","tokenId":10000,"price":1e18,"amount":10,"fee":1e17,"exType":2,"orderId":100}

```

