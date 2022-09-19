// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// DMB abi
interface IDMBToken {
    function balanceOf(address account, uint256 id) external returns (uint256);

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

// DMT abi
interface IDragonToken {
    function getDragonStage(uint256 _tokenId) external returns (uint16 stage);

    function getDragonJob(uint256 _tokenId) external returns (uint8 job);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function burn(uint256 tokenId) external;

    function getDragonAttribute(uint256 _tokenId, uint256 _attrId)
        external
        view
        returns (uint256 attr);

    function getDragonSkill(uint256 _tokenId, uint256 _skillId)
        external
        view
        returns (uint256 skill, uint256 level);

    // dragon attribute update
    function setDragonAttribute(
        uint256 _tokenId,
        uint256 _attrId,
        uint256 _value
    ) external returns (bool);

    // dragon skill update
    function setDragonSkill(
        uint256 _tokenId,
        uint256 _skillId,
        uint256 _level
    ) external returns (bool);
}

abstract contract DragonUpgradeBase is Pausable, Ownable {
    // burn account event
    event BurnAccount(address newAddr);

    // dragon absorb MaxCount DmsFees DmpFees
    event AbsMaxCount(uint256 newMaxCount);
    event AbsDmsFees(uint256[3] newDmsFees);
    event AbsDmpFees(uint256[3] newDmpFees);

    // dragon devour maxLevel DmsFee DmpFee
    event MaxLevel(uint256 newLevel);
    event DevDmsFees(uint256[2] newFee);
    event DevDmpFees(uint256[2] newFee);

    // (Low Medium High) value
    event LowValue(uint256[3] newLowValue);
    event MediumValue(uint256[2] newMediumValue);
    event HighValue(uint256[1] newHighValue);

    // AttrWeight
    event AttrWeight(uint256[5] newAttrWeight);

    // preview event
    event Absorb(
        address indexed account,
        uint256 dragonId,
        uint256 boneId,
        uint256 attrId,
        uint256 addValue,
        uint256 attrValue
    );
    // Confirm event
    event Confirm(
        address indexed account,
        uint256 dragonId,
        uint256 boneId,
        uint256 attrId,
        uint256 addValue,
        uint256 attrValue,
        uint256 currCount
    );
    // Cancel event
    event Cancel(
        address indexed account,
        uint256 dragonId,
        uint256 boneId,
        uint256 currCount
    );

    // devour event
    event Skill(
        address indexed account,
        uint256 dragonId,
        uint256 devourDragonId,
        uint256 skillId,
        uint256 skillLevel
    );

    // talent event
    event Talent(
        address indexed account,
        uint256 dragonId,
        uint256 talentId,
        uint256 talentLevel
    );

    // Absourb Data
    struct AbsorbData {
        uint256 boneId;
        uint256 attrId;
        uint256 currValue;
        uint256 addValue;
        uint256 attrValue; // currValue + addValue
        bool state; // confirm need state == true
    }

    // Devour Data
    struct DevourData {
        uint256 devourDragonId;
        uint256 skillId;
        uint256 currLevel;
        uint256 skillLevel; // currLevel + 1
        // bool state; // confirm need state = true
    }

    // dragon absourb tokenId => predata
    mapping(uint256 => AbsorbData) public absorbDatas;
    // dragon absourb tokenId => count
    mapping(uint256 => uint256) public absorbCounts;
    // dragon tokenId =>level(1,2,3) => count
    mapping(uint256 => mapping(uint256 => uint256)) counts;

    // Absorption max count
    uint256 public absMaxCount = 3;

    // dms dmp fees
    uint256[3] public absdmsFees = [0.1 ether, 0.3 ether, 1 ether];
    uint256[3] public absdmpFees = [50 ether, 100 ether, 300 ether];

    // bone level Boost value (Low Medium High)
    uint256[3] public lowValue = [1, 2, 3];
    uint256[2] public mediumValue = [5, 6];
    uint256[1] public highValue = [10];

    // dragon devour tokenId => devour data
    //mapping(uint256 => DevourData) public devourDatas;

    // dragonId => skillId => talent State
    mapping(uint256 => mapping(uint256 => bool)) talentState;

    // devour max level
    uint256 public maxLevel = 4;
    uint256 internal constant talentId = 5;
    // tokenId => devoured tokenIs
    mapping(uint256 => uint256[]) public devourTotal;
    // devour dms dmp fees
    uint256[2] public devdmsFees = [1 ether, 1 ether];
    uint256[2] public devdmpFees = [300 ether, 600 ether];

    // contract
    IERC20 public dmsToken = IERC20(0x9a26e6D24Df036B0b015016D1b55011c19E76C87);
    IERC20 public dmpToken = IERC20(0x599107669322B0E72be939331f35A693ba71EBE2);
    IDragonToken public dragonToken =
        IDragonToken(0x3a70F8292F0053C97c4B394e2fC98389BdE765fb);
    IDMBToken public dmbToken =
        IDMBToken(0xF1a41450f7DDEce82F3ea389E201f3b1478C9893);
    address public burnAccount =
        address(0xdbCD59927b1D39cB9A01d5C3DbD910300e59d1F2);

    // attr Weight 1-5
    uint256[5] public attrWeight = [20, 40, 60, 80, 100];

    // set low bone value
    function setLowValue(uint256[3] calldata _value) external onlyOwner {
        for (uint256 i = 0; i < _value.length; i++) {
            require(_value[i] > 0, "invalid value");
        }
        lowValue = _value;
        emit LowValue(_value);
    }

    // set medium bone value
    function setMediumValue(uint256[2] calldata _value) external onlyOwner {
        for (uint256 i = 0; i < _value.length; i++) {
            require(_value[i] > 0, "invalid value");
        }
        mediumValue = _value;
        emit MediumValue(_value);
    }

    // set high bone value
    function setHighValue(uint256[1] calldata _value) external onlyOwner {
        require(_value[0] > 0, "invalid value");
        highValue = _value;
        emit HighValue(_value);
    }

    // set absorb max count
    function setAbsMaxCount(uint256 _maxCount) external onlyOwner {
        require(_maxCount > 0, "invalid absorb maxCount");
        absMaxCount = _maxCount;
        emit AbsMaxCount(_maxCount);
    }

    // set attribute weights
    function setAttrWeight(uint256[5] calldata _weight) external onlyOwner {
        for (uint256 i = 0; i < _weight.length; i++) {
            require(_weight[i] > 0, "invalid weight");
        }
        attrWeight = _weight;
        emit AttrWeight(_weight);
    }

    // set burn account address
    function setBurnAccount(address _address) external onlyOwner {
        require(_address != address(0), "address is zero");
        burnAccount = _address;
        emit BurnAccount(_address);
    }

    // set DMS amount
    function setAbsDmsFees(uint256[3] calldata _fees) external onlyOwner {
        for (uint256 i = 0; i < _fees.length; i++) {
            require(_fees[i] > 0, "invalid dmsFees");
        }
        absdmsFees = _fees;
        emit AbsDmsFees(_fees);
    }

    // set DMP amount
    function setAbsDmpFees(uint256[3] calldata _fees) external onlyOwner {
        for (uint256 i = 0; i < _fees.length; i++) {
            require(_fees[i] > 0, "invalid dmpFees");
        }
        absdmpFees = _fees;
        emit AbsDmpFees(_fees);
    }

    // set devour max level
    function setMaxLevel(uint256 _level) external onlyOwner {
        require(_level > 0, "invalid devour maxLevel");
        maxLevel = _level;
        emit MaxLevel(_level);
    }

    // set devour DMS amount
    function setDevDmsFee(uint256[2] calldata _fees) external onlyOwner {
        for (uint256 i = 0; i < _fees.length; i++) {
            require(_fees[i] > 0, "invalid DMS fee");
        }
        devdmsFees = _fees;
        emit DevDmsFees(_fees);
    }

    // set devour DMP amount
    function setDevDmpFee(uint256[2] calldata _fees) external onlyOwner {
        for (uint256 i = 0; i < _fees.length; i++) {
            require(_fees[i] > 0, "invalid DMP fee");
        }
        devdmpFees = _fees;
        emit DevDmpFees(_fees);
    }

    function getSkillLevels(uint256 _dragonId)
        external
        view
        returns (uint256[5] memory)
    {
        require(_dragonId > 0, "invalid dragonId");
        (, uint256 hornLevel) = dragonToken.getDragonSkill(_dragonId, 1);
        (, uint256 earLevel) = dragonToken.getDragonSkill(_dragonId, 2);
        (, uint256 wingLevel) = dragonToken.getDragonSkill(_dragonId, 3);
        (, uint256 tailLevel) = dragonToken.getDragonSkill(_dragonId, 4);
        (, uint256 talentLevel) = dragonToken.getDragonSkill(_dragonId, 5);
        return [hornLevel, earLevel, wingLevel, tailLevel, talentLevel];
    }

    function getTalentStates(uint256 _tokenId)
        external
        view
        returns (bool[4] memory)
    {
        require(_tokenId > 0, "invalid account");
        return [
            talentState[_tokenId][1],
            talentState[_tokenId][2],
            talentState[_tokenId][3],
            talentState[_tokenId][4]
        ];
    }

    function getTalentState(uint256 _tokenId, uint256 _skillId)
        external
        view
        returns (bool)
    {
        require(_tokenId > 0, "invalid tokenId");
        require(_skillId >= 1 && _skillId <= 4, "invalid skillId");
        return talentState[_tokenId][_skillId];
    }

    function getTalentLevel(uint256 _tokenId) external view returns (uint256) {
        (, uint256 _talentLevel) = dragonToken.getDragonSkill(_tokenId, 5);
        return _talentLevel;
    }

    // get dragon absorb bone's number
    function getAbsNumber(uint256 _tokenId, uint256 _level)
        external
        view
        returns (uint256)
    {
        return counts[_tokenId][_level];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// dragon upgrade attributes, skills, talent
contract DragonUpgrade is Pausable, ReentrancyGuard, DragonUpgradeBase {
    // judge dragon's owner
    modifier isOwner(uint256 tokenId) {
        require(
            dragonToken.ownerOf(tokenId) == msg.sender,
            "dragon not belong to owner"
        );
        _;
    }

    // preview bone
    // attr add random value
    function preview(uint256 _dragonId, uint256 _boneId)
        external
        whenNotPaused
        nonReentrant
        isOwner(_dragonId)
        returns (bool)
    {
        require(_dragonId > 0 && _boneId > 0, "invalid dragonId or boneId");
        require(
            absorbCounts[_dragonId] < absMaxCount,
            "Exceeded the maximum absorption"
        );
        require(
            dragonToken.getDragonStage(_dragonId) > 0,
            "Dragon egg is hatching"
        );
        require(
            dmbToken.balanceOf(msg.sender, _boneId) > 0,
            "Dragon bone is insufficient."
        );
        AbsorbData storage _data = absorbDatas[_dragonId];
        require(!_data.state, "Please confirm or cancel first");

        // job match
        require(
            dragonToken.getDragonJob(_dragonId) == _boneId / 10,
            "Job mismatch"
        );

        // get bone level
        uint256 _level = _boneId % 10;
        require(_level >= 1 && _level <= 3, "Bone level is wrong");

        // spend DMS DMP
        require(
            dmsToken.balanceOf(msg.sender) >= absdmsFees[_level - 1],
            "Your DMS balance is insufficient"
        );
        require(
            dmpToken.balanceOf(msg.sender) >= absdmpFees[_level - 1],
            "Your DMP balance is insufficient"
        );
        require(
            dmsToken.transferFrom(
                msg.sender,
                burnAccount,
                absdmsFees[_level - 1]
            ),
            "DMS transfer failure"
        );
        require(
            dmpToken.transferFrom(
                msg.sender,
                burnAccount,
                absdmpFees[_level - 1]
            ),
            "DMP transfer failure"
        );

        // burn bone
        dmbToken.burn(msg.sender, _boneId, 1);

        // get attrId, addValue
        (uint256 _random1, uint256 _random2) = _random();
        uint256 _attrId = _getAttr(_random1);
        uint256 _addValue = _getValue(_random2, _level);

        uint256 _currValue = dragonToken.getDragonAttribute(_dragonId, _attrId);

        // change data
        _data.state = true;
        _data.boneId = _boneId;
        _data.attrId = _attrId;
        _data.addValue = _addValue;
        _data.currValue = _currValue;
        _data.attrValue = _addValue + _currValue;

        emit Absorb(
            msg.sender,
            _dragonId,
            _boneId,
            _attrId,
            _addValue,
            _data.attrValue
        );
        return true;
    }

    // confirm absorb
    // count accumulated
    function confirm(uint256 _dragonId)
        external
        whenNotPaused
        nonReentrant
        isOwner(_dragonId)
        returns (bool)
    {
        require(
            absorbCounts[_dragonId] < absMaxCount,
            "Exceeded the maximum absorption"
        );
        AbsorbData memory _data = absorbDatas[_dragonId];
        require(_data.state, "Please preview first");
        uint256 _currValue = _data.currValue;
        absorbCounts[_dragonId]++;
        counts[_dragonId][_data.boneId % 10]++;

        // update Attribute
        require(
            dragonToken.setDragonAttribute(
                _dragonId,
                _data.attrId,
                _data.addValue + _currValue
            ),
            "Failed to promote attribute"
        );

        delete absorbDatas[_dragonId];
        emit Confirm(
            msg.sender,
            _dragonId,
            _data.boneId,
            _data.attrId,
            _data.addValue,
            _data.attrValue,
            absorbCounts[_dragonId]
        );
        return true;
    }

    // cancel absorb
    // count not accumulated
    function cancel(uint256 _dragonId)
        external
        whenNotPaused
        nonReentrant
        isOwner(_dragonId)
        returns (bool)
    {
        require(absorbDatas[_dragonId].state, "Please preview first");
        uint256 _boneId = absorbDatas[_dragonId].boneId;
        delete absorbDatas[_dragonId];
        emit Cancel(msg.sender, _dragonId, _boneId, absorbCounts[_dragonId]);
        return true;
    }

    // get attr Id 1<=id<=5
    function _getAttr(uint256 _rand) private view returns (uint256) {
        uint256 rand_ = _rand % attrWeight[4];
        for (uint256 i = 0; i < attrWeight.length; i++) {
            if (rand_ < attrWeight[i]) {
                return i + 1;
            }
        }
        return 0;
    }

    // get increase Value
    function _getValue(uint256 _rand, uint256 _level)
        private
        view
        returns (uint256)
    {
        if (_level == 3) {
            return highValue[0];
        }
        if (_level == 2) {
            uint256 _index = _rand % mediumValue.length;
            return mediumValue[_index];
        }
        if (_level == 1) {
            uint256 _index = _rand % lowValue.length;
            return lowValue[_index];
        }
        return 0;
    }

    // dragon devour
    // dragon burn & dms dms transfer to burn account
    // skill upgrade
    function skill(uint256 _dragonId, uint256 _devourDragonId)
        external
        whenNotPaused
        nonReentrant
        isOwner(_dragonId)
        isOwner(_devourDragonId)
        returns (bool)
    {
        require(
            _dragonId > 0 && _dragonId != _devourDragonId,
            "invalid dragonId or devour dragonId"
        );
        require(
            dragonToken.getDragonStage(_dragonId) > 0,
            "Dragon egg is hatching"
        );
        require(
            dragonToken.getDragonStage(_devourDragonId) > 0,
            "devour Dragon egg is hatching"
        );

        uint256 _skillId = _randomSkillId(_dragonId);
        (, uint256 _level) = dragonToken.getDragonSkill(_dragonId, _skillId);
        require(_level + 1 <= maxLevel, "Dragon level max");

        // transfer DMS DMP
        require(
            dmsToken.balanceOf(msg.sender) >= devdmsFees[0],
            "Your DMS balance is insufficient"
        );
        require(
            dmpToken.balanceOf(msg.sender) >= devdmpFees[0],
            "Your DMP balance is insufficient"
        );
        require(
            dmsToken.transferFrom(msg.sender, burnAccount, devdmsFees[0]),
            "DMS transfer failure"
        );
        require(
            dmpToken.transferFrom(msg.sender, burnAccount, devdmpFees[0]),
            "DMP transfer failure"
        );

        // burn dragon
        dragonToken.burn(_devourDragonId);

        // devour data
        DevourData memory _data;
        _data.devourDragonId = _devourDragonId;
        _data.skillId = _skillId;
        _data.currLevel = _level;
        _data.skillLevel = _level + 1;

        // update skill
        require(
            dragonToken.setDragonSkill(
                _dragonId,
                _data.skillId,
                _data.skillLevel
            ),
            "Failed to promote skill"
        );

        // change skillId talent state
        if (_data.skillLevel == maxLevel) {
            talentState[_dragonId][_data.skillId] == true;
        }
        // every dragon devour total
        devourTotal[_dragonId].push(_devourDragonId);

        emit Skill(
            msg.sender,
            _dragonId,
            _devourDragonId,
            _skillId,
            _data.skillLevel
        );
        return true;
    }

    function _randomSkillId(uint256 _dragonId) private view returns (uint256) {
        uint256[] memory _skillIds = new uint256[](maxLevel);
        uint256 _len = 0;
        for (uint256 id = 1; id <= maxLevel; id++) {
            (, uint256 _currLevel) = dragonToken.getDragonSkill(_dragonId, id);
            if (_currLevel < maxLevel) {
                _skillIds[_len] = id;
                _len++;
            }
        }
        if (_len == 0) {
            return 0;
        }
        (, uint256 _rand) = _random();
        // get skillId, addValue=1
        return _skillIds[_rand % _len];
    }

    // talent upgrade
    function talent(uint256 _dragonId, uint256 _skillId)
        external
        whenNotPaused
        nonReentrant
        isOwner(_dragonId)
        returns (bool)
    {
        require(_dragonId > 0, "invalid dragonId");
        require(_skillId >= 1 && _skillId <= 4, "invalid skillId");
        (, uint256 _skillLevel) = dragonToken.getDragonSkill(
            _dragonId,
            _skillId
        );
        require(_skillLevel == maxLevel, "The skill level is insufficient");
        require(
            talentState[_dragonId][_skillId],
            "The talent have been upgraded"
        );

        // talentLevel max level = 5
        (, uint256 _talentLevel) = dragonToken.getDragonSkill(
            _dragonId,
            talentId
        );
        require(_talentLevel < maxLevel + 1, "talent level is max");

        // transfer DMS DMP
        require(
            dmsToken.balanceOf(msg.sender) >= devdmsFees[1],
            "Your DMS balance is insufficient"
        );
        require(
            dmpToken.balanceOf(msg.sender) >= devdmpFees[1],
            "Your DMP balance is insufficient"
        );
        require(
            dmsToken.transferFrom(msg.sender, burnAccount, devdmsFees[1]),
            "DMS transfer failure"
        );
        require(
            dmpToken.transferFrom(msg.sender, burnAccount, devdmpFees[1]),
            "DMP transfer failure"
        );

        require(
            dragonToken.setDragonSkill(_dragonId, talentId, _talentLevel + 1),
            "Failed to promote skill"
        );
        talentState[_dragonId][_skillId] = false;

        emit Talent(msg.sender, _dragonId, talentId, _talentLevel + 1);

        return true;
    }

    // get 2 random numbers
    function _random() private view returns (uint256, uint256) {
        bytes32 _rand = keccak256(
            abi.encodePacked(
                block.timestamp +
                    block.difficulty +
                    uint256(keccak256(abi.encodePacked(block.coinbase))) /
                    block.timestamp +
                    block.gaslimit +
                    uint256(keccak256(abi.encodePacked(msg.sender))) /
                    block.timestamp +
                    block.number
            )
        );
        uint256 _rand1 = uint128(bytes16(_rand));
        uint256 _rand2 = uint128(bytes16(_rand << 128));
        return (_rand1, _rand2);
    }
}
