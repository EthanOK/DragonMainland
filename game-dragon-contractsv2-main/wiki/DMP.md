
## DMP合约

* DMP提现

```
function mint(
    address to,
    uint256 amount,
    uint256 _feeAmt,
    uint64 _timestamp
) external whenNotPaused onlyRole(MINTER_ROLE) returns (bool)
```

address to  提现人钱包地址
uint256 amount 收账dmp金额（单位wei）
uint256 _feeAmt 提现费用dmp金额（单位wei）
uint256 _timestamp 提现时间（秒）
