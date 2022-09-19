
## 龙质押挖矿 DMP


* 质押

```
// stake dragon token
// earn DMP token
function stake(
    uint256[] calldata _tokenIds,
    uint256[] calldata _hashRates,
    uint256 _powers,
    uint64 _timestamp,
    bytes memory _sign
) returns (bool);
```

可以一次质押多条龙

_tokenIds 各个龙的TokenId列表

_hashRates 各个龙的算力列表

_powers 几条龙质押多少小时的总体力

_timestamp 当前时间（秒）

_sign 数据签名bytes

数据签名格式 _powers + _timestamp + _tokenIds[0] + _hashRates[0] + _tokenIds[1] + _hashRates[1] + ...



* 取消质押

```
// cancel stake dragon
function unStake(uint256[] calldata _tokenIds) returns (bool);
```

可以一次取消质押多条龙

_tokenIds 各个龙的TokenId列表


* 提取DMP

```
// dragon stake earn DMP token
function stakeEarn(uint256[] calldata _tokenIds) returns (bool);
```

可以一次提取多条龙的DMP收益，各个龙的收益记录在链上Log中，可以通过合约事件来获取数据

_tokenIds 各个龙的TokenId列表


* 增加体力 继续挖矿
```
function stakePower(uint256[] calldata _tokenIds, uint256 _powers, uint64 _timestamp, bytes _sign) returns (bool);
```

增加体力，龙继续质押挖矿

各条龙的DMP收益自动发放，收益数据记录在链上Log中，可以通过合约事件来获取数据

_tokenIds 各个龙的TokenId列表

_powers 几条龙质押多少小时的总体力

_timestamp 当前时间（秒）

_sign 数据签名bytes

数据签名格式 _powers + _timestamp + _tokenIds[0] + 0 + _tokenIds[1] + 0 + ...


* 统计数据

```
// stake total
// dragonTotal => 0x647261676f6e546f74616c
// accountTotal => 0x6163636f756e74546f74616c
// dmpTotal => 0x646d70546f74616c
function stakeTotals(bytes key) returns(uint256);
```

通过不用的key值，获取不同的数据

dragonTotal 质押龙的总条数（去重后的）

accountTotal 质押钱包的总数（去重后的）

dmpTotal 质押挖出DMP总量


* 钱包数据

```
// account staking tokenIds
function getStakingTokenIds(address _account) returns (uint256[] memory)
```

_account 钱包地址

获取某个钱包当前正在质押的龙TokenId列表


* 龙的质押数据

```
function stakingDatas(uint256 _tokenId) returns (StakingData);

// staking data
struct StakingData {
    address account;
    uint256 power;
    uint256 hashRate;
    uint256 tokenId;
    uint256 startTime;
    uint256 endTime;
    uint256 release;
}
```

_tokenId 龙TokenId

account 钱包地址
power 体力
hashRate 算力
tokenId 龙TokenId
startTime 开始时间
endTime 结束时间
release 已领取的DMP总值


* 某条龙的质押状态

```
function stakedState(uint256 _tokenId) returns(bool);
```
_tokenId 龙TokenId

true 当前质押中 / false 未质押


* 某条龙的DMP总收益

```
stakedDatas(uint256 _tokenId) returns(uint256);
```

_tokenId 龙TokenId

某条龙的历史总的DMP收益


[mq]

```
event StakeData(
    address indexed account,
    uint256 power,
    uint256 hashRate,
    uint256 tokenId,
    uint256 startTime,
    uint256 endTime,
    uint256 amount
);

event StakedEarn(
    address indexed account,
    uint256 indexed tokenId,
    uint256 power,
    uint256 amount
);
```

* 质押

exchange = dragon.exchange

queue = ex_stake

{"account": "0x2D41F1A83Adac376aB88377Ee9783A89C9F3ec29", "power": 8, "hashRate": 331, "tokenId": 8925, "startTime": 1637762996, "endTime": 1637765396, "amount": 0}


* 取消质押

exchange = dragon.exchange

queue = ex_unstake

{"account": "0x94dDD7F32830372bEdbc38ec430AFe5B1813C3d8", "power": 0, "hashRate": 0, "tokenId": 8921, "startTime": 0, "endTime": 0, "amount": 9000000000000000000}

