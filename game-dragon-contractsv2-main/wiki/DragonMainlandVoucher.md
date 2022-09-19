
* 批量铸造 DMV券

https://testnet.bscscan.com/tx/0xab4f1eb4d8718f29ddfdbea9f31dddc683aca288fe15af007bc0381b89d825a3


* 批量转账 DMV券给币安钱包

https://testnet.bscscan.com/tx/0xe45b893f77b44104fc8f6a49aa260c3abf0e16c483b56eabdb0fb8118c7e645b


* exchange 兑换成功示例

https://testnet.bscscan.com/tx/0x4bd3db241c59d227e33a168fa969451ef2289780d59b1f82ad54f18a405e4ac8


* 前端

```
// exchange voucher to dragon
// burn voucher
// create dragon egg
function exchange(
    uint256 _tokenId,
    uint256 _timestamp,
    bytes memory _sign
) external returns (bool) {
```

_tokenId 龙ID

_timestamp 当前时间（秒）

_sign 签名值

