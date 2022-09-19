// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * dragon mainland token contract
 * NFT ERC721
 */

// dragon base
abstract contract DragonBase is AccessControl, Pausable {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event Birth(
        address indexed owner,
        uint256 tokenId,
        uint8 jobId,
        uint256 matronId,
        uint256 sireId,
        uint64 birthTime,
        uint64 cooldownTime
    );

    event DragonMeta(
        uint256 indexed tokenId,
        uint256 geneDomi,
        uint256 geneRece,
        uint16 stage
    );

    event DragonAttributes(
        uint256 indexed tokenId,
        uint256 health,
        uint256 attack,
        uint256 defense,
        uint256 speed,
        uint256 lifeForce
    );

    event DragonAttribute(
        uint256 indexed tokenId,
        uint256 attrId,
        uint256 oldValue,
        uint256 newValue
    );

    event DragonSkills(
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

    event DragonSkill(
        uint256 indexed tokenId,
        uint256 skillId,
        uint256 oldLevel,
        uint256 newLevel
    );

    event DragonBreed(
        uint256 indexed tokenId,
        uint8 job,
        uint256 matronId,
        uint256 sireId,
        address owner
    );

    event Cooldowns(uint64[2] oldTimes, uint64[2] newTimes);

    event MaxLevel(uint256 oldLevel, uint256 newLevel);

    event BreedCountMax(uint256 oldCount, uint256 newCount);

    event BreedCooldown(uint256[] _days);

    event BreedCount(address indexed from, uint256 tokenId, uint256 count);

    event BoneCountMax(uint256 oldCount, uint256 newCount);

    event GenesisTotal(uint256 oldTotal, uint256 newTotal);

    // breed cooldown time end
    event CooldownTimeEnd(uint256 tokenId, uint256 cooldownEnd);

    enum JobType {
        None,
        Water,
        Fire,
        Rock,
        Storm,
        Thunder
    }

    // dragon attributes
    enum AttrType {
        None,
        Health,
        Attack,
        Defense,
        Speed,
        LifeForce
    }

    // dragon skill
    enum SkillType {
        None,
        Horn,
        Ear,
        Wing,
        Tail,
        Talent
    }

    // dragon attribute 5
    struct Attribute {
        uint256 health;
        uint256 attack;
        uint256 defense;
        uint256 speed;
        uint256 lifeForce;
    }

    // dragon skill 5
    struct Skill {
        uint256 horn;
        uint256 ear;
        uint256 wing;
        uint256 tail;
        uint256 talent;
    }

    // dragon skills level 5
    struct Skills {
        uint256 horn;
        uint256 hornLevel;
        uint256 ear;
        uint256 earLevel;
        uint256 wing;
        uint256 wingLevel;
        uint256 tail;
        uint256 tailLevel;
        uint256 talent;
        uint256 talentLevel;
    }

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
    // dragon breed count max
    uint256 public breedCountMax = 7;
    // dragon bone count max
    uint256 public boneCountMax = 3;
    // dragon breed cooldown time config
    mapping(uint256 => uint256) public breedCooldown;
    // matron sire dragon cooldown time
    mapping(uint256 => uint256) public cooldownTimeEnd;
    // dragon.tokenId => dragon metadata
    mapping(uint256 => Metadata) public dragons;
    // dragon.tokenId => children.tokenId
    mapping(uint256 => uint256[]) internal dragonChildrens;
    // dragon.tokenId => dragon attribute
    mapping(uint256 => Attribute) public dragonAttributes;
    // dragon.tokenId => dragon skill
    mapping(uint256 => Skills) public dragonSkills;
    // dragon.breedCount => count
    mapping(uint256 => uint256) public dragonBreedCounts;
    // dragon.boneCount => count
    mapping(uint256 => uint256) public dragonBoneCounts;
    // total number of genesis dragon
    uint256 public genesisTotal = 10000;

    function setCooldowns(uint64[2] memory _times)
        external
        onlyRole(OWNER_ROLE)
    {
        emit Cooldowns(cooldowns, _times);
        cooldowns = _times;
    }

    function setMaxLevel(uint256 _level) external onlyRole(OWNER_ROLE) {
        emit MaxLevel(maxLevel, _level);
        maxLevel = _level;
    }

    function setBreedCountMax(uint256 _count) external onlyRole(OWNER_ROLE) {
        emit BreedCountMax(breedCountMax, _count);
        breedCountMax = _count;
    }

    // breed cooldown init data
    function _breedCooldownInit() internal {
        breedCooldown[1] = 0 days;
        breedCooldown[2] = 2 days;
        breedCooldown[3] = 4 days;
        breedCooldown[4] = 6 days;
        breedCooldown[5] = 9 days;
        breedCooldown[6] = 12 days;
        breedCooldown[7] = 15 days;
    }

    // set breed cooldown
    function setBreedCooldown(uint256[] calldata _days)
        external
        onlyRole(OWNER_ROLE)
    {
        for (uint256 i = 0; i < _days.length; i++) {
            require(_days[i] > 0, "amount is zero");
            breedCooldown[i + 1] = _days[i];
        }
        emit BreedCooldown(_days);
    }

    function setGenesisTotal(uint256 _total) external onlyRole(OWNER_ROLE) {
        emit GenesisTotal(genesisTotal, _total);
        genesisTotal = _total;
    }

    function setBoneCountMax(uint256 _count) external onlyRole(OWNER_ROLE) {
        emit BoneCountMax(boneCountMax, _count);
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

    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }
}

// dragon mainland token ERC721
contract DragonMainlandToken is
    ERC721,
    ERC721URIStorage,
    ERC721Burnable,
    ReentrancyGuard,
    DragonBase
{
    constructor(address[] memory owners, address[] memory operators)
        ERC721("Dragon Mainland Token", "DMT")
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
        _breedCooldownInit();
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

    modifier hasTokenId(uint256 _tokenId) {
        require(_exists(_tokenId) == true, "tokenId is not existent");
        _;
    }

    function getDragonJob(uint256 _tokenId) external view returns (uint8 job) {
        Metadata memory _meta = dragons[_tokenId];
        job = _meta.job;
    }

    function getDragonStage(uint256 _tokenId)
        external
        view
        returns (uint16 stage)
    {
        Metadata memory _meta = dragons[_tokenId];
        stage = _meta.stage;
    }

    // create dragon eggs
    function createDragonEggs(
        uint256 _tokenId,
        uint8 _job,
        uint256 _matronId,
        uint256 _sireId,
        address _owner,
        uint256 _startTime
    ) public whenNotPaused nonReentrant onlyRole(OPERATOR_ROLE) returns (bool) {
        require(_tokenId > 0, "invalid tokenId");
        require(_exists(_tokenId) == false, "tokenId is exist");
        require(_job >= 1 && _job <= 5, "invalid job");

        if (_tokenId > genesisTotal) {
            require(
                _matronId > 0 && _sireId > 0 && _matronId != _sireId,
                "invalid matronId or sireId"
            );
            require(ownerOf(_matronId) != address(0), "invalid matronId owner");
            require(ownerOf(_sireId) != address(0), "invalid sireId owner");
        } else {
            require(
                _matronId == 0 && _sireId == 0,
                "invalid matronId or sireId"
            );
        }
        // birthTime
        uint256 _birthTime = _startTime > 0 ? _startTime : block.timestamp;

        uint64 cooldown = _tokenId <= genesisTotal
            ? cooldowns[1]
            : cooldowns[0];
        dragons[_tokenId] = Metadata({
            job: _job,
            birthTime: uint64(_birthTime),
            cooldownTime: uint64(_birthTime) + cooldown,
            geneDomi: 0,
            geneRece: 0,
            matronId: _matronId,
            sireId: _sireId,
            stage: 0
        });

        if (_matronId > 0) {
            dragonChildrens[_matronId].push(_tokenId);
            // add breed count
            dragonBreedCounts[_matronId]++;
        }
        if (_sireId > 0) {
            dragonChildrens[_sireId].push(_tokenId);
            // add breed count
            dragonBreedCounts[_sireId]++;
        }

        _safeMint(_owner, _tokenId);

        emit Birth(
            _owner,
            _tokenId,
            _job,
            _matronId,
            _sireId,
            uint64(block.timestamp),
            uint64(block.timestamp) + cooldown
        );
        return true;
    }

    // hatch dragon eggs
    function hatchDragonEggs(
        uint256 _tokenId,
        uint256 _geneDomi,
        uint256 _geneRece,
        uint16 _stage,
        Attribute memory _attr,
        Skill memory _skill,
        string memory _uri
    )
        external
        whenNotPaused
        nonReentrant
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        require(_exists(_tokenId) == true, "tokenId is not existent");

        Metadata storage _dragon = dragons[_tokenId];
        require(
            _dragon.stage == 0 && _stage > _dragon.stage,
            "invalid dragon stage"
        );
        require(block.timestamp >= _dragon.cooldownTime, "dragon is cooldown");

        _setDragonMeta(_dragon, _tokenId, _geneDomi, _geneRece, _stage);

        dragonAttributes[_tokenId] = _attr;
        emit DragonAttributes(
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
        emit DragonSkills(
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
        return true;
    }

    // dragon set metadata
    function _setDragonMeta(
        Metadata storage _dragon,
        uint256 _tokenId,
        uint256 _geneDomi,
        uint256 _geneRece,
        uint16 _stage
    ) private {
        _dragon.geneDomi = _geneDomi;
        _dragon.geneRece = _geneRece;
        _dragon.stage = _tokenId <= genesisTotal ? 1 : _stage;
        _dragon.cooldownTime = 0;
        emit DragonMeta(_tokenId, _geneDomi, _geneRece, _stage);
    }

    function getDragonAttribute(uint256 _tokenId, uint256 _attrId)
        public
        view
        hasTokenId(_tokenId)
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
        hasTokenId(_tokenId)
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
        uint256 _value
    )
        external
        whenNotPaused
        nonReentrant
        hasTokenId(_tokenId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        AttrType attr_id = AttrType(_attrId);
        require(uint256(attr_id) > 0, "invalid attrId");
        uint256 curr = getDragonAttribute(_tokenId, _attrId);
        require(_value > curr, "invalid value");
        require(
            dragonBoneCounts[_tokenId] < boneCountMax,
            "invalid boneCountMax"
        );

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
        dragonBoneCounts[_tokenId] += 1;
        emit DragonAttribute(_tokenId, _attrId, curr, _value);
        return true;
    }

    // dragon skill update
    function setDragonSkill(
        uint256 _tokenId,
        uint256 _skillId,
        uint256 _level
    )
        external
        whenNotPaused
        nonReentrant
        hasTokenId(_tokenId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        SkillType skill_id = SkillType(_skillId);
        require(uint256(skill_id) > 0, "invalid skillId");
        if (skill_id == SkillType.Talent) {
            require(_level > 0 && _level <= maxLevel + 1, "invalid value");
        } else {
            require(_level > 0 && _level <= maxLevel, "invalid value");
        }
        (, uint256 _oldLevel) = getDragonSkill(_tokenId, _skillId);
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

        emit DragonSkill(_tokenId, _skillId, _oldLevel, _level);
        return true;
    }

    // breed dragon eggs
    // Deduct token in business contract
    function breedDragonEggs(
        uint256 _tokenId,
        uint8 _job,
        uint256 _matronId,
        uint256 _sireId,
        address _owner
    )
        external
        whenNotPaused
        hasTokenId(_matronId)
        hasTokenId(_sireId)
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        require(_exists(_tokenId) == false, "tokenId is exist");
        require(_job >= 1 && _job <= 5, "invalid job");
        require(_tokenId > genesisTotal, "invalid tokenId");

        // tokenId's owner
        require(ownerOf(_matronId) == msg.sender, "invalid matronId");
        require(ownerOf(_sireId) == msg.sender, "invalid sireId");

        // breed count
        require(
            dragonBreedCounts[_matronId] < breedCountMax,
            "matron breed count max"
        );
        require(
            dragonBreedCounts[_sireId] < breedCountMax,
            "sire breed count max"
        );

        // breed cooldown
        require(
            block.timestamp >= cooldownTimeEnd[_matronId],
            "matronId is cooldown"
        );
        require(
            block.timestamp >= cooldownTimeEnd[_sireId],
            "sireId is cooldown"
        );

        // create dragon egg
        require(
            createDragonEggs(_tokenId, _job, _matronId, _sireId, _owner, 0),
            "createDragonEggs failure"
        );

        emit BreedCount(msg.sender, _matronId, dragonBreedCounts[_matronId]);
        emit BreedCount(msg.sender, _sireId, dragonBreedCounts[_sireId]);

        // set cooldown endTime
        cooldownTimeEnd[_matronId] =
            block.timestamp +
            breedCooldown[dragonBreedCounts[_matronId] + 1];
        cooldownTimeEnd[_sireId] =
            block.timestamp +
            breedCooldown[dragonBreedCounts[_sireId] + 1];

        emit CooldownTimeEnd(_matronId, cooldownTimeEnd[_matronId]);
        emit CooldownTimeEnd(_sireId, cooldownTimeEnd[_sireId]);

        emit DragonBreed(_tokenId, _job, _matronId, _sireId, _owner);
        return true;
    }
}
