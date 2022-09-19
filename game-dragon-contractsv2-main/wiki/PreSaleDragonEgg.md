
## 龙蛋抢购合约

* PreSaleDragonEgg

抢购：（1000 只） 

目前已确定第一轮抢购时间/数量/价格，后边抢购将根据市场情况设置并公布

第一轮数量：1000 只 

价格：0.1BNB

属性：火龙 

时间：2021.10.15 （16:00:00 UTC+4）

注：官方以迪拜时间展示，迪拜下午 4 点，对应北 京时间晚上 8 点

* 流程

1）判断是否已预售 result()

2）buy() 预售交易

3）预售数据查询 getPresale()

* 购买方法

```
function buy(
    uint8 _job,
    uint256 _id,
    string calldata _email,
    uint256 _timestamp,
    bytes memory _sign
) external
    payable
    whenNotPaused
    is_start
    is_end
    is_buyed
    has_email(_email)
    id_exist(_id)
    returns (bool)
```

job 龙的职业（本次抢购值为2）
id 龙蛋的id
email 购买人的邮箱地址
timestamp 当前时间
sign 签名字符串


* 成年龙

```
function growupDragonEgg(
    uint256 _id,
    uint256 _geneDomi,
    uint256 _geneRece,
    uint256 _matronId,
    uint256 _sireId,
    uint16 _stage,
    Attribute memory _attr,
    Skill memory _skill,
    string memory _uri,
    uint256 _timestamp,
    bytes memory _sign
) external returns (bool)
```


* 提现合约金额

```
function withdraw() external {}
```


* 是否已预售

```
function result(address account) public view returns (bool)
```
account 钱包地址

返回 true(不能再购买) 或 false



* 预售数据

```
function getPresale(address account)
    public
    view
    returns (
        uint8,
        uint256,
        uint256,
        string memory
    )
```

返回
job 龙蛋职业
price 购买价格 wei为单位
id 龙蛋id
email 账号邮箱

* 龙蛋id查询钱包地址

```
function getId(uint256 _id) public view returns (address)
```

id 龙蛋id 

返回 钱包地址

* 当天（当前）价格

prices 无参数

返回 0.1bnb 或 0.2bnb 到 0.5bnb

* 当前预售数量

total_buy 无参数
