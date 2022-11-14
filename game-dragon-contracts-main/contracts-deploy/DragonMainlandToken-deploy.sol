// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./Adminable.sol";
import "./DragonMetadata.sol";

/**
 * dragon mainland token contract
 * NFT ERC721
 */

// dragon base
contract DragonBase is DragonMetadata, Ownable {
    event Birth(
        address indexed owner,
        uint256 tokenId,
        uint8 jobId,
        uint64 birthTime,
        uint64 cooldownTime
    );

    event DragonMetaLog(
        uint256 indexed tokenId,
        uint256 geneDomi,
        uint256 geneRece,
        uint256 matronId,
        uint256 sireId,
        uint16 stage
    );

    event DragonAttributesLog(
        uint256 indexed tokenId,
        uint256 health,
        uint256 attack,
        uint256 defense,
        uint256 speed,
        uint256 lifeForce
    );

    event DragonAttributeLog(
        uint256 indexed tokenId,
        uint256 attrId,
        uint256 oldValue,
        uint256 newValue
    );

    event DragonSkillsLog(
        uint256 indexed tokenId,
        uint256 horn,
        uint256 hornLevel,
        uint256 ear,
        uint256 earLevel,
        uint256 wing,
        uint256 wingLevel,
        uint256 tail,
        uint256 tailLevel,
        uint256 talent,
        uint256 talentLevel
    );

    event DragonSkillLog(
        uint256 indexed tokenId,
        uint256 skillId,
        uint256 oldLevel,
        uint256 newLevel
    );

    event DragonBreed(uint256 indexed tokenId, uint256 count);

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

    // cooldown time
    uint64[2] public cooldowns = [uint64(3 days), uint64(7 days)];
    // skill max level
    uint256 public maxLevel = 4;
    // sign expiration time
    uint256 public expirationTime = 600;
    // dragon breed count max
    uint256 public breedCountMax = 7;
    // dragon bone count max
    uint256 public boneCountMax = 3;

    // dragon.tokenId => dragon metadata
    mapping(uint256 => Metadata) public dragons;
    // dragon.tokenId => children.tokenId
    mapping(uint256 => uint256[]) internal dragonChildrens;
    // dragon.tokenId => dragon attribute
    mapping(uint256 => Attribute) public dragonAttributes;
    // dragon.tokenId => dragon skill
    mapping(uint256 => Skills) public dragonSkills;
    // dragon.breedCount => count
    mapping(uint256 => uint256) public dragonBreedCount;
    // dragon.boneCount => count
    mapping(uint256 => uint256) public dragonBoneCount;

    function setCooldowns(uint64[2] memory _times) external onlyOwner {
        cooldowns = _times;
    }

    function setMaxLevel(uint256 _level) external onlyOwner {
        maxLevel = _level;
    }

    function setExpirationTime(uint256 _time) external onlyOwner {
        expirationTime = _time;
    }

    function setBreedCountMax(uint256 _count) external onlyOwner {
        breedCountMax = _count;
    }

    function setBoneCountMax(uint256 _count) external onlyOwner {
        boneCountMax = _count;
    }

    // get dragon Children list
    function dragonChildren(uint256 _tokenId)
        external
        view
        returns (uint256[] memory)
    {
        return dragonChildrens[_tokenId];
    }
}

// dragon mainland token ERC721
contract DragonMainlandToken is
    ERC721,
    ERC721URIStorage,
    Pausable,
    Ownable,
    ERC721Burnable,
    ReentrancyGuard,
    Adminable,
    DragonBase
{
    using Strings for uint256;
    using ECDSA for bytes32;

    constructor() ERC721("Dragon Mainland Token", "DMT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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

    modifier hasTokenId(uint256 _tokenId) {
        require(_exists(_tokenId) == true, "tokenId is not existent");
        _;
    }

    modifier isExpirationTime(uint256 _timestamp) {
        require(
            _timestamp + expirationTime >= block.timestamp,
            "expiration time"
        );
        _;
    }

    function verifyAdmin(string memory data, bytes memory _sign) public view {
        bytes32 message = keccak256(abi.encodePacked(data));
        bytes32 ethSignedHash = message.toEthSignedMessageHash();
        require(ethSignedHash.recover(_sign) == admin(), "sign message fault");
    }

    function getDragonJob(uint256 _tokenId) external view returns (uint8 job) {
        Metadata memory _meta = dragons[_tokenId];
        job = _meta.job;
    }

    // create dragon eggs
    function createDragonEggs(
        uint8 _job,
        uint256 _tokenId,
        address _owner,
        uint256 _timestamp,
        bytes memory _sign
    )
        external
        whenNotPaused
        nonReentrant
        isExpirationTime(_timestamp)
        returns (bool)
    {
        require(_exists(_tokenId) == false, "tokenId is exist");
        require(_job >= 1 && _job <= 5, "invalid job");
        string memory message = string(
            abi.encodePacked(
                _tokenId.toString(),
                uint256(_job).toString(),
                _timestamp.toString()
            )
        );
        verifyAdmin(message, _sign);

        uint64 cooldown = _tokenId <= 10000 ? cooldowns[1] : cooldowns[0];
        dragons[_tokenId] = Metadata({
            job: _job,
            birthTime: uint64(block.timestamp),
            cooldownTime: uint64(block.timestamp) + cooldown,
            geneDomi: 0,
            geneRece: 0,
            matronId: 0,
            sireId: 0,
            stage: 0
        });
        emit Birth(
            _owner,
            _tokenId,
            _job,
            uint64(block.timestamp),
            uint64(block.timestamp) + cooldown
        );
        _safeMint(_owner, _tokenId);
        return true;
    }

    function _hatchMessage(
        uint256 _tokenId,
        uint256 _geneDomi,
        uint256 _geneRece,
        uint256 _matronId,
        uint256 _sireId,
        uint16 _stage,
        Attribute memory _attr,
        Skill memory _skill,
        uint256 _timestamp
    ) private pure returns (string memory) {
        string memory message = string(
            abi.encodePacked(
                _tokenId.toString(),
                _geneDomi.toString(),
                _geneRece.toString(),
                _matronId.toString(),
                _sireId.toString(),
                uint256(_stage).toString()
            )
        );
        message = string(
            abi.encodePacked(
                message,
                _attr.health.toString(),
                _attr.attack.toString(),
                _attr.defense.toString(),
                _attr.speed.toString(),
                _attr.lifeForce.toString()
            )
        );
        message = string(
            abi.encodePacked(
                message,
                _skill.horn.toString(),
                _skill.ear.toString(),
                _skill.wing.toString(),
                _skill.tail.toString(),
                _skill.talent.toString(),
                _timestamp.toString()
            )
        );
        return message;
    }

    // hatch dragon eggs
    function hatchDragonEggs(
        uint256 _tokenId,
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
    ) external whenNotPaused nonReentrant returns (bool) {
        require(_exists(_tokenId) == true, "tokenId is not existent");
        require(
            _timestamp + expirationTime >= block.timestamp,
            "expiration time"
        );
        Metadata storage _dragon = dragons[_tokenId];
        require(
            _dragon.stage == 0 && _stage > _dragon.stage,
            "invalid dragon stage"
        );
        require(block.timestamp >= _dragon.cooldownTime, "dragon is cooldown");
        if (_tokenId > 10000) {
            require(
                _matronId > 0 && _sireId > 0 && _matronId != _sireId,
                "invalid matronId or sireId"
            );
        } else {
            require(
                _matronId == 0 && _sireId == 0,
                "invalid matronId or sireId"
            );
        }

        verifyAdmin(
            _hatchMessage(
                _tokenId,
                _geneDomi,
                _geneRece,
                _matronId,
                _sireId,
                _stage,
                _attr,
                _skill,
                _timestamp
            ),
            _sign
        );

        _setDragonMeta(
            _dragon,
            _tokenId,
            _geneDomi,
            _geneRece,
            _matronId,
            _sireId,
            _stage
        );
        dragonAttributes[_tokenId] = _attr;
        emit DragonAttributesLog(
            _tokenId,
            _attr.health,
            _attr.attack,
            _attr.defense,
            _attr.speed,
            _attr.lifeForce
        );

        dragonSkills[_tokenId] = Skills(
            _skill.horn,
            1,
            _skill.ear,
            1,
            _skill.wing,
            1,
            _skill.tail,
            1,
            _skill.talent,
            1
        );
        emit DragonSkillsLog(
            _tokenId,
            _skill.horn,
            1,
            _skill.ear,
            1,
            _skill.wing,
            1,
            _skill.tail,
            1,
            _skill.talent,
            1
        );

        _setTokenURI(_tokenId, _uri);
        if (_matronId > 0) {
            dragonChildrens[_matronId].push(_tokenId);
        }
        if (_sireId > 0) {
            dragonChildrens[_sireId].push(_tokenId);
        }
        return true;
    }

    // dragon set metadata
    function _setDragonMeta(
        Metadata storage _dragon,
        uint256 _tokenId,
        uint256 _geneDomi,
        uint256 _geneRece,
        uint256 _matronId,
        uint256 _sireId,
        uint16 _stage
    ) private {
        _dragon.geneDomi = _geneDomi;
        _dragon.geneRece = _geneRece;
        _dragon.matronId = _matronId;
        _dragon.sireId = _sireId;
        _dragon.stage = _tokenId <= 10000 ? 1 : _stage;
        _dragon.cooldownTime = 0;
        emit DragonMetaLog(
            _tokenId,
            _geneDomi,
            _geneRece,
            _matronId,
            _sireId,
            _stage
        );
    }

    function getDragonAttribute(uint256 _tokenId, uint256 _attrId)
        public
        view
        returns (uint256 attr)
    {
        Attribute memory _attr = dragonAttributes[_tokenId];
        AttrType attr_id = AttrType(_attrId);
        require(uint256(attr_id) > 0, "invalid attrId");
        if (attr_id == AttrType.Health) {
            attr = _attr.health;
        } else if (attr_id == AttrType.Attack) {
            attr = _attr.attack;
        } else if (attr_id == AttrType.Defense) {
            attr = _attr.defense;
        } else if (attr_id == AttrType.Speed) {
            attr = _attr.speed;
        } else if (attr_id == AttrType.LifeForce) {
            attr = _attr.lifeForce;
        }
    }

    function getDragonSkill(uint256 _tokenId, uint256 _skillId)
        public
        view
        returns (uint256 skill, uint256 level)
    {
        Skills memory _skill = dragonSkills[_tokenId];
        SkillType skill_id = SkillType(_skillId);
        require(uint256(skill_id) > 0, "invalid skillId");
        if (skill_id == SkillType.Horn) {
            skill = _skill.horn;
            level = _skill.hornLevel;
        } else if (skill_id == SkillType.Ear) {
            skill = _skill.ear;
            level = _skill.earLevel;
        } else if (skill_id == SkillType.Wing) {
            skill = _skill.wing;
            level = _skill.wingLevel;
        } else if (skill_id == SkillType.Tail) {
            skill = _skill.tail;
            level = _skill.tailLevel;
        } else if (skill_id == SkillType.Talent) {
            skill = _skill.talent;
            level = _skill.talentLevel;
        }
    }

    // dragon attribute update
    function setDragonAttribute(
        uint256 _tokenId,
        uint256 _attrId,
        uint256 _value,
        uint256 _timestamp,
        bytes memory _sign
    )
        external
        whenNotPaused
        nonReentrant
        hasTokenId(_tokenId)
        isExpirationTime(_timestamp)
        returns (bool)
    {
        AttrType attr_id = AttrType(_attrId);
        require(uint256(attr_id) > 0, "invalid attrId");
        uint256 curr = getDragonAttribute(_tokenId, _attrId);
        require(_value > curr, "invalid value");
        require(
            dragonBoneCount[_tokenId] < boneCountMax,
            "invalid boneCountMax"
        );

        string memory message = string(
            abi.encodePacked(
                _tokenId.toString(),
                _attrId.toString(),
                _value.toString(),
                _timestamp.toString()
            )
        );
        verifyAdmin(message, _sign);

        Attribute storage _attr = dragonAttributes[_tokenId];
        if (attr_id == AttrType.Health) {
            _attr.health = _value;
        } else if (attr_id == AttrType.Attack) {
            _attr.attack = _value;
        } else if (attr_id == AttrType.Defense) {
            _attr.defense = _value;
        } else if (attr_id == AttrType.Speed) {
            _attr.speed = _value;
        } else if (attr_id == AttrType.LifeForce) {
            _attr.lifeForce = _value;
        }
        dragonBoneCount[_tokenId] += 1;
        emit DragonAttributeLog(_tokenId, _attrId, curr, _value);
        return true;
    }

    // dragon skill update
    function setDragonSkill(
        uint256 _tokenId,
        uint256 _skillId,
        uint256 _level,
        uint256 _timestamp,
        bytes memory _sign
    )
        external
        whenNotPaused
        nonReentrant
        hasTokenId(_tokenId)
        isExpirationTime(_timestamp)
        returns (bool)
    {
        SkillType skill_id = SkillType(_skillId);
        require(uint256(skill_id) > 0, "invalid skillId");
        if (skill_id == SkillType.Talent) {
            require(_level > 0 && _level <= maxLevel + 1, "invalid value");
        } else {
            require(_level > 0 && _level <= maxLevel, "invalid value");
        }

        string memory message = string(
            abi.encodePacked(
                _tokenId.toString(),
                _skillId.toString(),
                _level.toString(),
                _timestamp.toString()
            )
        );
        verifyAdmin(message, _sign);

        uint256 _oldSkill;
        uint256 _oldLevel;
        (_oldSkill, _oldLevel) = getDragonSkill(_tokenId, _skillId);
        require(_oldLevel < _level, "invalid level");

        Skills storage _skill = dragonSkills[_tokenId];
        if (skill_id == SkillType.Horn) {
            _skill.hornLevel = _level;
        } else if (skill_id == SkillType.Ear) {
            _skill.earLevel = _level;
        } else if (skill_id == SkillType.Wing) {
            _skill.wingLevel = _level;
        } else if (skill_id == SkillType.Tail) {
            _skill.tailLevel = _level;
        } else if (skill_id == SkillType.Talent) {
            _skill.talentLevel = _level;
        }

        emit DragonSkillLog(_tokenId, _skillId, _oldLevel, _level);
        return true;
    }

    // add dragon breed count
    function addDragonBreedCount(
        uint256 _tokenId,
        uint256 _timestamp,
        bytes memory _sign
    )
        external
        whenNotPaused
        nonReentrant
        hasTokenId(_tokenId)
        isExpirationTime(_timestamp)
        returns (bool)
    {
        string memory message = string(
            abi.encodePacked(_tokenId.toString(), _timestamp.toString())
        );
        verifyAdmin(message, _sign);

        uint256 _count = dragonBreedCount[_tokenId] + 1;
        require(_count <= breedCountMax, "invalid breed count");
        dragonBreedCount[_tokenId] = _count;
        emit DragonBreed(_tokenId, _count);
        return true;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        external
        onlyAdmin
        nonReentrant
    {
        _setTokenURI(tokenId, _tokenURI);
    }
}
