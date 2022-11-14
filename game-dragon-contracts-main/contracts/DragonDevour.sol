// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

    function burn(uint256 tokenId) external;

    function getDragonSkill(uint256 _tokenId, uint256 _skillId)
        external
        view
        returns (uint256 skill, uint256 level);

    // dragon skill update
    function setDragonSkill(
        uint256 _tokenId,
        uint256 _skillId,
        uint256 _level,
        uint256 _timestamp,
        bytes memory _sign
    ) external returns (bool);
}

abstract contract DragonDevourBase is Pausable, Ownable {
    // burn account event
    event BurnAccount(address newAddr);
    // maxLevel DmsFee DmpFee
    event MaxLevel(uint256 newLevel);
    event DmsFees(uint256[2] newFee);
    event DmpFees(uint256[2] newFee);

    // devour event
    event Devour(
        address indexed account,
        uint256 dragonId,
        uint256 devourDragonId,
        uint256 skillId,
        uint256 skillLevel
    );
    // Confirm event
    event Confirm(
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

    struct DevourData {
        uint256 devourDragonId;
        uint256 skillId;
        uint256 currLevel;
        uint256 skillLevel; // currLevel + 1
        bool state; // confirm need state = true
    }

    // dragon tokenId => devour data
    mapping(uint256 => DevourData) public devourDatas;
    // dragonId => skillId => talent State
    mapping(uint256 => mapping(uint256 => bool)) public talentState;

    // devour max level
    uint256 public maxLevel = 4;
    uint256 internal constant talentId = 5;

    // dms dmp fees
    uint256[2] public dmsFees = [1 ether, 1 ether];
    uint256[2] public dmpFees = [300 ether, 600 ether];

    // contract
    IERC20 public dmsToken = IERC20(0x9a26e6D24Df036B0b015016D1b55011c19E76C87);
    IERC20 public dmpToken = IERC20(0x599107669322B0E72be939331f35A693ba71EBE2);
    IDragonToken public dragonToken =
        IDragonToken(0x3a70F8292F0053C97c4B394e2fC98389BdE765fb);
    address public burnAccount =
        address(0xdbCD59927b1D39cB9A01d5C3DbD910300e59d1F2);

    // expiration time
    uint64 internal constant _expirationTime = 180;

    // set devour max level
    function setMaxLevel(uint256 _level) external onlyOwner {
        require(_level > 0, "invalid devour maxLevel");
        maxLevel = _level;
        emit MaxLevel(_level);
    }

    // set burn account address
    function setBurnAccount(address _address) external onlyOwner {
        require(_address != address(0), "address is zero");
        burnAccount = _address;
        emit BurnAccount(_address);
    }

    // set DMS amount
    function setDmsFee(uint256[2] calldata _fees) external onlyOwner {
        for (uint256 i = 0; i < _fees.length; i++) {
            require(_fees[i] > 0, "invalid DMS fee");
            dmsFees[i] = _fees[i];
        }
        emit DmsFees(_fees);
    }

    // set DMP amount
    function setDmpFee(uint256[2] calldata _fees) external onlyOwner {
        for (uint256 i = 0; i < _fees.length; i++) {
            require(_fees[i] > 0, "invalid DMP fee");
            dmpFees[i] = _fees[i];
        }
        emit DmpFees(_fees);
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

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// dragon devour dragon
// other dragon burn
// dms dmp transfer to burn account
contract DragonDevour is Pausable, ReentrancyGuard, DragonDevourBase {
    // dragon owner
    modifier isOwner(uint256 tokenId) {
        require(
            dragonToken.ownerOf(tokenId) == msg.sender,
            "dragon not belong to owner"
        );
        _;
    }

    // dragon devour
    // dragon burn & dms dms transfer to burn account
    function devour(uint256 _dragonId, uint256 _devourDragonId)
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
            dragonToken.dragons(_dragonId).stage > 0,
            "Dragon egg is hatching"
        );
        require(
            dragonToken.dragons(_devourDragonId).stage > 0,
            "devour Dragon egg is hatching"
        );

        DevourData storage _data = devourDatas[_dragonId];
        require(!_data.state, "Please confirm first");

        uint256 _skillId = _randomSkillId(_dragonId);
        require(_skillId != 0, "Dragon absorption to complete");
        (, uint256 _level) = dragonToken.getDragonSkill(_dragonId, _skillId);
        require(_level + 1 <= maxLevel, "Dragon level max");

        // transfer DMS DMP
        require(
            dmsToken.balanceOf(msg.sender) >= dmsFees[0],
            "Your DMS balance is insufficient"
        );
        require(
            dmpToken.balanceOf(msg.sender) >= dmpFees[0],
            "Your DMP balance is insufficient"
        );
        require(
            dmsToken.transferFrom(msg.sender, burnAccount, dmsFees[0]),
            "DMS transfer failure"
        );
        require(
            dmpToken.transferFrom(msg.sender, burnAccount, dmpFees[0]),
            "DMP transfer failure"
        );

        // burn dragon
        dragonToken.burn(_devourDragonId);

        // change data
        _data.state = true;
        _data.devourDragonId = _devourDragonId;
        _data.skillId = _skillId;
        _data.currLevel = _level;
        _data.skillLevel = _level + 1;

        emit Devour(
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
        uint256 _seed = 4;
        for (uint256 id = 1; id <= maxLevel; id++) {
            (, uint256 _currLevel) = dragonToken.getDragonSkill(_dragonId, id);
            if (_currLevel < maxLevel) {
                _skillIds[_len] = id;
                _len++;
            }
            _seed += _currLevel;
        }
        if (_len == 0) {
            return 0;
        }
        // get skillId, addValue=1
        return _skillIds[_random(_seed, _len)];
    }

    // confirm devour
    function confirm(
        uint256 _dragonId,
        uint256 _timestamp,
        bytes memory _sign
    ) external whenNotPaused nonReentrant isOwner(_dragonId) returns (bool) {
        require(_dragonId > 0, "invalid dragonId");
        require(_timestamp > 0, "invalid timestamp");
        require(_sign.length > 0, "invalid sign");
        require(
            _timestamp + _expirationTime >= block.timestamp,
            "expiration time"
        );
        DevourData memory _data = devourDatas[_dragonId];
        require(_data.state, "Please devour first");

        // update skill
        require(
            dragonToken.setDragonSkill(
                _dragonId,
                _data.skillId,
                _data.skillLevel,
                _timestamp,
                _sign
            ),
            "Failed to promote skill"
        );

        // change skillId talent state
        if (_data.skillLevel == maxLevel) {
            talentState[_dragonId][_data.skillId] = true;
        }

        emit Confirm(
            msg.sender,
            _dragonId,
            _data.devourDragonId,
            _data.skillId,
            _data.skillLevel
        );
        delete devourDatas[_dragonId];
        return true;
    }

    // talent upgrade
    function talent(
        uint256 _dragonId,
        uint256 _skillId,
        uint256 _timestamp,
        bytes memory _sign
    ) external whenNotPaused nonReentrant isOwner(_dragonId) returns (bool) {
        require(_dragonId > 0, "invalid dragonId");
        require(_skillId >= 1 && _skillId <= 4, "invalid skillId");
        require(_timestamp > 0, "invalid timestamp");
        require(_sign.length > 0, "invalid sign");
        require(
            talentState[_dragonId][_skillId],
            "talent cannot be upgraded about skillId"
        );
        require(
            _timestamp + _expirationTime >= block.timestamp,
            "expiration time"
        );

        // talentLevel max level = 5
        (, uint256 _talentLevel) = dragonToken.getDragonSkill(
            _dragonId,
            talentId
        );
        require(_talentLevel < maxLevel + 1, "talent level is max");
        (, uint256 _skillLevel) = dragonToken.getDragonSkill(
            _dragonId,
            _skillId
        );
        require(_skillLevel == maxLevel, "invalid skill level");

        // transfer DMS DMP
        require(
            dmsToken.balanceOf(msg.sender) >= dmsFees[1],
            "Your DMS balance is insufficient"
        );
        require(
            dmpToken.balanceOf(msg.sender) >= dmpFees[1],
            "Your DMP balance is insufficient"
        );
        require(
            dmsToken.transferFrom(msg.sender, burnAccount, dmsFees[1]),
            "DMS transfer failure"
        );
        require(
            dmpToken.transferFrom(msg.sender, burnAccount, dmpFees[1]),
            "DMP transfer failure"
        );

        require(
            dragonToken.setDragonSkill(
                _dragonId,
                talentId,
                _talentLevel + 1,
                _timestamp,
                _sign
            ),
            "Failed to promote skill"
        );
        talentState[_dragonId][_skillId] = false;

        emit Talent(msg.sender, _dragonId, talentId, _talentLevel + 1);

        return true;
    }

    // get random numbers
    function _random(uint256 seed_, uint256 _modulus)
        private
        view
        returns (uint256)
    {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    seed_ +
                        block.timestamp +
                        block.difficulty +
                        uint256(keccak256(abi.encodePacked(block.coinbase))) /
                        block.timestamp +
                        block.gaslimit +
                        uint256(keccak256(abi.encodePacked(msg.sender))) /
                        block.timestamp +
                        block.number
                )
            )
        );
        return rand % _modulus;
    }
}
