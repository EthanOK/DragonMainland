
## 龙骨盲盒合约

* 参与报名

```
function applyJoin() external returns (bool);
```

DMS合约上授权给龙骨盲盒合约及数额

[mq]
```
emit ApplyJoin(_currBatch, msg.sender, dmsAmount);

exchange = dragon.blindbox

queue = apply_join

body = 

{"currBatch":1, "account":"0xabc", "dmsAmount":50000}
```


* 提取DMS金额

```
function withdraw() external;
```

余额全部提取

没有MQ



* 打开盲盒

```
function openBlindbox() external;
```

入参 无

[mq]

```
emit OpenBlindbox(_batchId.current(), msg.sender, _box.tokenId);

exchange = dragon.blindbox

queue = open_blindbox

body = 

{"batch":1, "account":"0xabc", "tokenId":12}
```

* 程序开奖python或java

```
function luckyBlindbox(uint256 _batchNo) external onlyRole(OPERATOR_ROLE);
```

_batchNo 批次数 目前每批次200人中奖

[mq]

```
event LuckyBlindbox(uint256 batch, address account, uint256 tokenId);

queue = lucky_blindbox

body = 

{"batch":1, "account":"0xabc", "tokenId":12}
```

