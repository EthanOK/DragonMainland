## 龙合约


合约地址

bsc测试网：0xd4DBDcCb87c68f4e0030D37d36Fa4aED66B7277e

bsc主网：


1. 购买龙蛋

```
// create dragon egg
function newDragonEgg(
  uint8 _job,
  uint256 _id,
  address _owner,
  uint256 _timestamp,
  bytes memory _sign
) external returns (bool)

```

job 职业 （1到5）

id 龙id（创世龙1到10000，繁殖龙10000以上）

owner 龙拥有者钱包地址

sign 钱包签名

```
sign_str = id + job + timestamp(秒)
```


2. 成年龙（开龙蛋）

```
// grow up dragon
function growupDragon(
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

id 龙id

geneDomi 龙显性基因

geneRece 龙隐性基因+次基因

metronId 父亲龙id （创世龙传0）

sireId 母亲龙id（创世龙传0）

stage 龙阶段 0=创世 1=繁殖

attr 龙属性

```
// dragon attribute 5
struct Attribute {
  uint256 lift;
  uint256 attack;
  uint256 defense;
  uint256 speed;
  uint256 wisdom;
}
```

skill 龙技能

```
// dragon skill 5
struct Skill {
  uint256 horn;
  uint256 ear;
  uint256 wing;
  uint256 tail;
  uint256 talent;
}
```

uri 龙数据保存在ipfs上链接地址

sign 钱包签名

```
sign_str = id + geneDomi + geneRece + matronId + sireId + stage + 
  attr.lift + attr.attack + attr.defense + attr.speed + attr.wisdom 
  skill.one + skill.two + skill.three + skill.four + skill.talent + timestamp
```


3. 属性升级

```
function setDragonAttribute(
  uint256 _id,
  uint256 _attrId,
  uint256 _value,
  uint256 _timestamp,
  bytes memory _sign
) external returns (bool)
```

id 龙id

attrId 属性id (1到5)

value 属性最终值（不是增加值）

sign 钱包签名

```
sign_str = id + attrId + value + timestamp
```


4. 技能升级

```
function setDragonSkill(
  uint256 _id,
  uint256 _skillId,
  uint256 _value,
  uint256 _timestamp,
  bytes memory _sign
) external returns (bool)
```

id 龙id

skillId 属性id (1到5)

value 属性最终值（不是增加值）

sign 钱包签名

```
sign_str = id + skillId + value + timestamp
```