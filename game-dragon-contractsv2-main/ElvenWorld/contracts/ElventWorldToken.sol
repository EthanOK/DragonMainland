// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * elven world token contract
 * NFT ERC721
 */

// elven world base
abstract contract ElventWorldBase is AccessControl, Pausable {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event CreateEquipment(
        address indexed owner,
        uint256 tokenId,
        uint8 eqType,
        uint8 jobId,
        uint64 birthTime,
        uint64 cooldownTime
    );

    event EquipmentAttributes(
        uint256 indexed tokenId,
        uint256 life,
        uint256 attack,
        uint256 defense,
        uint256 agility,
        uint256 wisdom
    );
    event EquipmentAttribute(
        uint256 indexed tokenId,
        uint256 attrId,
        uint256 oldValue,
        uint256 newValue
    );
    event SetSkillCard(uint256 tokenId, uint256 level);

    event Unfreeze(uint256 indexed tokenId, uint256 stage);

    event Cooldowns(uint64[2] oldTimes, uint64[2] newTimes);

    event EnchantCountMax(uint256 oldCount, uint256 newCount);

    // arming attribute 5
    struct Attribute {
        uint256 life;
        uint256 attack;
        uint256 defense;
        uint256 agility;
        uint256 wisdom;
    }

    // // equipment type
    // enum EquipmentType {
    //     None,
    //     Weapon,
    //     Headgear,
    //     Wing,
    //     Clothes,
    //     Shoe,
    //     Pet
    // }
    // // occupation type
    // enum OccupationType {
    //     None,
    //     Warrior,
    //     Assassin,
    //     Archer,
    //     Mage,
    //     Priest
    // }

    // Metadata
    struct Metadata {
        uint8 equipType; // equipment type 1 2 3 4 5 6
        uint8 occupation; // job 1 2 3 4 5
        uint64 birthTime;
        uint64 cooldownTime;
        // uint64 level;
        uint64 skillCard;
        uint8 state; // if state = 1 ,the equipment being used
        uint8 stage; // if stage = 1, cooldown time end
    }

    // equipment skill card states
    // Weapons, headgears, wings, clothes, shoes, pets
    bool[7] internal cardStates = [false, true, false, true, true, false, true];
    // todo cooldown time
    uint64[2] public cooldowns = [uint64(3), uint64(7)];
    // Enchanting stones max count
    uint256 public enchantCountMax = 3;
    // tokenId => Metadata
    mapping(uint256 => Metadata) public equipments;
    // tokenId => equipment Attribute
    mapping(uint256 => Attribute) public Attributes;
    // tokenId => Enchanting stones count
    mapping(uint256 => uint256) public enchantingCounts;
    // todo total number of genesis equipment
    uint256 public genesisTotal = 10000;

    function setCooldowns(uint64[2] memory _times)
        external
        onlyRole(OWNER_ROLE)
    {
        emit Cooldowns(cooldowns, _times);
        cooldowns = _times;
    }

    function setEnchantCountMax(uint256 _count) external onlyRole(OWNER_ROLE) {
        emit EnchantCountMax(enchantCountMax, _count);
        enchantCountMax = _count;
    }

    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }
}

contract ElventWorldToken is
    ERC721,
    ERC721URIStorage,
    ERC721Burnable,
    ReentrancyGuard,
    ElventWorldBase
{
    using Counters for Counters.Counter;
    Counters.Counter private eqTokenId;

    modifier hasTokenId(uint256 _tokenId) {
        require(_exists(_tokenId) == true, "tokenId is not existent");
        _;
    }

    constructor(address[] memory owners, address[] memory operators)
        ERC721("Elvent World Token", "EWT")
    {
        require(owners.length > 0, "invalid owners");
        require(operators.length > 0, "invalid operators");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < owners.length; i++) {
            require(owners[i] != address(0), "invalid owners");
            _setupRole(OWNER_ROLE, owners[i]);
        }
        for (uint256 i = 0; i < operators.length; i++) {
            require(operators[i] != address(0), "invalid operators");
            _setupRole(OPERATOR_ROLE, operators[i]);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        external
        onlyRole(OWNER_ROLE)
        nonReentrant
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getOccupation(uint256 _tokenId) external view returns (uint8 job) {
        Metadata memory _meta = equipments[_tokenId];
        job = _meta.occupation;
    }

    function getType(uint256 _tokenId) external view returns (uint8 eqType) {
        Metadata memory _meta = equipments[_tokenId];
        eqType = _meta.equipType;
    }

    function getState(uint256 _tokenId) external view returns (uint8 state) {
        Metadata memory _meta = equipments[_tokenId];
        state = _meta.state;
    }

    function getStage(uint256 _tokenId) external view returns (uint8 stage) {
        Metadata memory _meta = equipments[_tokenId];
        stage = _meta.stage;
    }

    function getAttribute(uint256 _tokenId, uint256 _attrId)
        public
        view
        hasTokenId(_tokenId)
        returns (uint256 value)
    {
        require(_attrId > 1 && _attrId <= 5, "invalid attrId");
        Attribute memory _attr = Attributes[_tokenId];
        if (_attrId == 1) {
            value = _attr.life;
        } else if (_attrId == 2) {
            value = _attr.attack;
        } else if (_attrId == 3) {
            value = _attr.defense;
        } else if (_attrId == 4) {
            value = _attr.agility;
        } else if (_attrId == 5) {
            value = _attr.wisdom;
        }
    }

    // create equipment
    function createEquipment(
        address _owner,
        uint8 _eqType,
        uint8 _job,
        uint256 _startTime
    )
        external
        whenNotPaused
        nonReentrant
        onlyRole(OPERATOR_ROLE)
        returns (uint256)
    {
        eqTokenId.increment();
        uint256 _tokenId = eqTokenId.current();
        // birthTime
        uint256 _birthTime = _startTime > 0 ? _startTime : block.timestamp;
        uint64 cooldown = _tokenId <= genesisTotal
            ? cooldowns[1]
            : cooldowns[0];

        Metadata storage _data = equipments[_tokenId];
        _data.equipType = _eqType;
        _data.occupation = _job;
        _data.birthTime = uint64(_birthTime);
        _data.cooldownTime = uint64(_birthTime) + cooldown;

        _safeMint(_owner, _tokenId);

        emit CreateEquipment(
            _owner,
            _tokenId,
            _eqType,
            _job,
            uint64(block.timestamp),
            uint64(block.timestamp) + cooldown
        );

        return _tokenId;
    }

    // unfreeze equipment
    function unfreeze(
        uint256 _tokenId,
        uint8 _stage,
        string memory _uri,
        Attribute memory _attr
    ) external whenNotPaused nonReentrant onlyRole(OPERATOR_ROLE) {
        require(_exists(_tokenId) == true, "tokenId is not existent");
        Metadata storage _data = equipments[_tokenId];
        require(
            _data.stage == 0 && _stage > _data.stage,
            "invalid dragon stage"
        );
        require(block.timestamp >= _data.cooldownTime, "equipment is cooldown");

        _data.stage = _tokenId <= genesisTotal ? 1 : _stage;
        _data.cooldownTime = 0;

        // set equipment attribute
        Attributes[_tokenId] = _attr;

        emit EquipmentAttributes(
            _tokenId,
            _attr.life,
            _attr.attack,
            _attr.defense,
            _attr.agility,
            _attr.wisdom
        );

        _setTokenURI(_tokenId, _uri);

        emit Unfreeze(_tokenId, _stage);
    }

    // equipment attribute update
    function setAttribute(
        uint256 _tokenId,
        uint256 _attrId,
        uint256 _value
    )
        external
        whenNotPaused
        nonReentrant
        hasTokenId(_tokenId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        require(_attrId >= 1 && _attrId <= 5, "invalid attrId");
        uint256 curr = getAttribute(_tokenId, _attrId);
        require(_value > curr, "invalid value");
        require(
            enchantingCounts[_tokenId] < enchantCountMax,
            "invalid boneCountMax"
        );

        Attribute storage _attr = Attributes[_tokenId];
        if (_attrId == 1) {
            _attr.life = _value;
        } else if (_attrId == 2) {
            _attr.attack = _value;
        } else if (_attrId == 3) {
            _attr.defense = _value;
        } else if (_attrId == 4) {
            _attr.agility = _value;
        } else if (_attrId == 5) {
            _attr.wisdom = _value;
        }
        enchantingCounts[_tokenId] += 1;

        emit EquipmentAttribute(_tokenId, _attrId, curr, _value);
        return true;
    }

    // equipment skill card update
    function setSkillCard(uint256 _tokenId, uint8 _level)
        external
        whenNotPaused
        nonReentrant
        hasTokenId(_tokenId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        require(_level > 0, "invalid skill card level");
        Metadata storage _data = equipments[_tokenId];
        uint8 _eqId = _data.equipType;
        // equipment hold skill cards (F/T)
        require(cardStates[_eqId], "the equipment can't hold skill card");
        _data.skillCard = _level;
        emit SetSkillCard(_tokenId, _level);
        return true;
    }
}
