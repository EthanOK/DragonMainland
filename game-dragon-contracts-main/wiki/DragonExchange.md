
## 交易合约

* 添加市场

```
function addMarket(
    uint256 _tokenId,
    uint256 _price,
    uint8 _exType,
    uint256 _minPrice,
    uint256 _maxPrice,
    uint256 _timeHours
)
```

uint256 _tokenId  龙ID
uint256 _price 出售DMS价格
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
    uint8 exType,
    uint256 minPrice,
    uint256 maxPrice,
    uint256 timeHours
);

queue = ex_add_market

body = 

普通
{"from":"0xabc","tokenId":10000,"price":1e18,"exType":1,"minPrice":0,"maxPrice":0,"timeHours":0}

竞拍
{"from":"0xabc","tokenId":10000,"price":0,"exType":2,"minPrice":1e18,"maxPrice":10e18,"timeHours":24}
```


* 下架市场

```
function removeMarket(uint256 _tokenId)
```

_tokenId 龙ID

[mq]

```
event RemoveMarket(address indexed from, uint256 tokenId);

queue = ex_remove_market

body = {"from":"0xabc","tokenId":10000}

```

* 查看当前出售价格

```
function exchangePrice(uint256 _tokenId)
public
view
returns (uint256, uint256)
```

入参 _tokenId 龙ID

出参

第1参数值 是 价格

第2参数值 是 余下时长（小时）


* 交易成交

```
function exchange(uint256 _tokenId, uint256 _price)
```

_tokenId 龙ID

_price 成交价格

* 繁殖龙

```
function breedDragonEggs(
    uint8 _job,
    uint256 _tokenId,
    uint256 _matronId,
    uint256 _sireId,
    address _owner,
    uint256 _timestamp,
    bytes memory _sign,
    bytes memory _signMatron,
    bytes memory _signSire
)
```

uint8 _job 龙职业
uint256 _tokenId 龙ID
uint256 _matronId 母亲龙ID
uint256 _sireId 父亲龙ID
address _owner 钱包地址
uint256 _timestamp 当前时间戳（秒）

签名

_signMatron => _matronId.toString() + _timestamp

_signSire => _sireId.toString() + _timestamp

_sign => _tokenId.toString() + uint256(_job).toString() + _timestamp.toString()

[mq]

```
event Exchange(
    address indexed from,
    address to,
    uint256 tokenId,
    uint256 price,
    uint256 fee,
    uint8 exType
);

queue = ex_exchange

body = 

普通
{"from":"0xabc","to":"0xbcd","tokenId":10000,"price":1e18,"fee":1e17,"exType":1}

竞拍
{"from":"0xabc","to":"0xbcd","tokenId":10000,"price":1e18,"fee":1e17,"exType":2}

```


* 繁殖龙Log

1）繁殖龙数据

emit BreedData(_job, _tokenId, _matronId, _sireId, _owner);

toppc = exchange
tag = breedData
body = {"job":2, "tokenId":10001, "matronId":10, "sireId":20, "owner":"0xabc"}

2）父母龙冷却时间

emit CooldownTimeEnd(_matronId, _matronCooldown);
emit CooldownTimeEnd(_sireId, _sireCooldown);

toppc = exchange
tag = cooldownTimeEnd
body = {"tokenId":10, "cooldown":1637387967} // 母龙 cooldown 冷却结束时间（秒）
body = {"tokenId":20, "cooldown":1637387967} // 父龙 cooldown 冷却结束时间（秒）

