### DMS IDO 合约

* 前端

```
// account deposit bnb
function deposit() external payable {
```

用户充值bnb

contract.functions.deposit({value: 0.1BNB})



* 后端

2.1 添加白名单

```
// add whitelist
function addWhitelist(address[] calldata accounts)
    external
    onlyOperator
    returns (bool)
```

一次最多200（包含）个钱包地址

accounts 1000个钱包地址分5次调用 


2.2 批量转账DMS(空投)

```
// batch widthdraw
function batchWithdraw(address[] calldata accounts) external onlyOperator {
````

一次最多200（包含）个钱包地址

accounts 1000个钱包地址分5次调用

