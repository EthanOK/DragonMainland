购买能量石

`function buyEnergy(uint256 _level, uint256 _amount)`

​	uint256 _level   ： 能量石等级（ 1 /5 /10）

​	uint256 _amount：购买能量石的数量

​	价格合约写死：暂定默认（1 ether，5ether, 10 ether）

`function getEnergyTotal(address account) external view returns (uint256)`

​	获得地址account的能量余额

`function getAmountTotal(address account, uint256 level) external view returns (uint256)`

  获得account购买等级为level能量石的数量


【mq】

`event BuyEnergy(`

​    `address indexed account,`

​    `uint256 level,`

​    `uint256 energyValue,`

​    `uint256 amount,`

​    `uint256 totalFees`

  `);`

​	account：用户地址

​	level：能量石等级（1、5、10）

​	energyValue：对应等级能量石的单价（1 ether、5 ether、10 ether）

​	amount：用户购买的数量

​	totalFees：花费的总DMS数



