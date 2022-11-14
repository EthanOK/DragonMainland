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
    struct Metadata {
        uint8 job;
        uint64 birthTime;
        uint64 cooldownTime;
        uint256 geneDomi;
        uint256 geneRece;
        uint256 matronId;
        uint256 sireId;
        uint16 stage;
    }

    function dragons(uint256 _tokenId)
        external
        returns (Metadata calldata data);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getDragonJob(uint256 _tokenId) external view returns (uint8 job);

    function getDragonAttribute(uint256 _tokenId, uint256 _attrId)
        external
        view
        returns (uint256 attr);

    // set Dragon Attribute
    function setDragonAttribute(
        uint256 _tokenId,
        uint256 _attrId,
        uint256 _value,
        uint256 _timestamp,
        bytes memory _sign
    ) external returns (bool);
}

abstract contract DragonBoneAbsorbBase is Pausable, Ownable {
    // burn account event
    event BurnAccount(address newAddr);

    // MaxCount DmsFees DmpFees
    event MaxCount(uint256 newMaxCount);
    event DmsFees(uint256[3] newDmsFees);
    event DmpFees(uint256[3] newDmpFees);

    // (Low Medium High) value
    event LowValue(uint256[3] newLowValue);
    event MediumValue(uint256[2] newMediumValue);
    event HighValue(uint256[1] newHighValue);

    // AttrWeight
    event AttrWeight(uint256[5] newAttrWeight);

    // preview event
    event Preview(
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

    struct PreviewData {
        uint256 boneId;
        uint256 attrId;
        uint256 currValue;
        uint256 addValue;
        uint256 attrValue; // currValue + addValue
        bool state; // confirm need state = true
    }

    // dragon tokenId => predata
    mapping(uint256 => PreviewData) public previewDatas;
    // dragon tokenId => count
    mapping(uint256 => uint256) public absorbCount;

    // Absorption max count
    uint256 public absMaxCount = 3;

    // dms dmp fees
    uint256[3] public dmsFees = [0.1 ether, 0.3 ether, 1 ether];
    uint256[3] public dmpFees = [50 ether, 100 ether, 300 ether];

    // bone level Boost value (Low Medium High)
    uint256[3] public lowValue = [1, 2, 3];
    uint256[2] public mediumValue = [5, 6];
    uint256[1] public highValue = [10];

    // contract
    IERC20 public dmsToken = IERC20(0x9a26e6D24Df036B0b015016D1b55011c19E76C87);
    IERC20 public dmpToken = IERC20(0x599107669322B0E72be939331f35A693ba71EBE2);
    IDragonToken public dragonToken =
        IDragonToken(0x3a70F8292F0053C97c4B394e2fC98389BdE765fb);
    IDMBToken public dmbToken =
        IDMBToken(0xF1a41450f7DDEce82F3ea389E201f3b1478C9893);
    address public burnAccount =
        address(0xdbCD59927b1D39cB9A01d5C3DbD910300e59d1F2);

    // expiration time
    uint64 internal _expirationTime = 180;

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
        emit MaxCount(_maxCount);
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
    function setDmsFees(uint256[3] calldata _fees) external onlyOwner {
        for (uint256 i = 0; i < _fees.length; i++) {
            require(_fees[i] > 0, "invalid dmsFees");
        }
        dmsFees = _fees;
        emit DmsFees(_fees);
    }

    // set DMP amount
    function setDmpFees(uint256[3] calldata _fees) external onlyOwner {
        for (uint256 i = 0; i < _fees.length; i++) {
            require(_fees[i] > 0, "invalid dmpFees");
        }
        dmpFees = _fees;
        emit DmpFees(_fees);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// dragon absorb bone
// dragon bone burn
// dms dmp transfer to burn account
contract DragonBoneAbsorb is Pausable, ReentrancyGuard, DragonBoneAbsorbBase {
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
            absorbCount[_dragonId] < absMaxCount,
            "Exceeded the maximum absorption"
        );
        require(
            dragonToken.dragons(_dragonId).stage > 0,
            "Dragon egg is hatching"
        );
        require(
            dmbToken.balanceOf(msg.sender, _boneId) > 0,
            "Dragon bone is insufficient."
        );
        PreviewData storage _data = previewDatas[_dragonId];
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
            dmsToken.balanceOf(msg.sender) >= dmsFees[_level - 1],
            "Your DMS balance is insufficient"
        );
        require(
            dmpToken.balanceOf(msg.sender) >= dmpFees[_level - 1],
            "Your DMP balance is insufficient"
        );
        require(
            dmsToken.transferFrom(msg.sender, burnAccount, dmsFees[_level - 1]),
            "DMS transfer failure"
        );
        require(
            dmpToken.transferFrom(msg.sender, burnAccount, dmpFees[_level - 1]),
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

        emit Preview(
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
    function confirm(
        uint256 _dragonId,
        uint256 _timestamp,
        bytes memory _sign
    ) external whenNotPaused nonReentrant isOwner(_dragonId) returns (bool) {
        require(
            _timestamp + _expirationTime >= block.timestamp,
            "expiration time"
        );
        require(
            absorbCount[_dragonId] < absMaxCount,
            "Exceeded the maximum absorption"
        );
        PreviewData memory _data = previewDatas[_dragonId];
        require(_data.state, "Please preview first");
        uint256 _currValue = _data.currValue;
        absorbCount[_dragonId]++;

        // update Attribute
        require(
            dragonToken.setDragonAttribute(
                _dragonId,
                _data.attrId,
                _data.addValue + _currValue,
                _timestamp,
                _sign
            ),
            "Failed to promote attribute"
        );

        delete previewDatas[_dragonId];
        emit Confirm(
            msg.sender,
            _dragonId,
            _data.boneId,
            _data.attrId,
            _data.addValue,
            _data.attrValue,
            absorbCount[_dragonId]
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
        require(previewDatas[_dragonId].state, "Please preview first");
        uint256 _boneId = previewDatas[_dragonId].boneId;
        delete previewDatas[_dragonId];
        emit Cancel(msg.sender, _dragonId, _boneId, absorbCount[_dragonId]);
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
