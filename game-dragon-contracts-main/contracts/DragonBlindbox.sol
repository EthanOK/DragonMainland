// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// DMB token abi
interface IDMBToken is IERC1155 {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

// dragon blindbox base
abstract contract DragonBlindboxBase is AccessControl, Pausable {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // set event list
    event LevelWeight(uint256[3] oldWeight, uint256[3] newWeight);
    event DmsAmount(uint256 oldAmount, uint256 newAmount);
    event BoxMax(uint256 oldMax, uint256 newMax);
    event AccountMax(uint256 oldMax, uint256 newMax);
    event StartTime(uint256 oldTime, uint256 newTime);
    event EndTime(uint256 oldTime, uint256 newTime);
    event OpenTime(uint256 oldTime, uint256 newTime);
    event Withdraw(address indexed account, uint256 amount);

    // apply join event dms amount
    event ApplyJoin(uint256 batch, address account, uint256 amount);
    // open blindbox event
    event OpenBlindbox(uint256 batch, address account, uint256 tokenId);
    // lucky blindbox event
    event LuckyBlindbox(uint256 batch, address account, uint256 tokenId);

    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }

    struct BlindboxData {
        address account;
        uint256 batch;
        uint256 number;
        uint256 amount;
        uint256 tokenId;
        bool opened;
    }

    // fee recipient
    address public recipient;
    // dms token
    IERC20 public dmsToken;
    // dmb token
    IDMBToken public dmbToken;

    // batch config
    uint256 public dmsAmount = 50 ether;
    uint256 public boxMax = 50;
    uint256 public accountMax = 1000;

    // level weight 2%,18%,80%
    uint256[3] public levelWeight = [2, 20, 100];

    // batch time
    uint256 public startTime = 1638964800;
    uint256 public endTime = startTime + 1 days;
    uint256 public openTime = endTime + 1 hours;
    // total supply opened
    uint256 public totalSupply;

    // id list
    uint256[] internal blindboxId;
    // batch => id => account
    mapping(uint256 => mapping(uint256 => address)) public blindboxAccount;
    // batch => account => BlindboxData
    mapping(uint256 => mapping(address => BlindboxData)) public blindboxList;
    // account => balance
    mapping(address => uint256) public balances;

    // set level weight
    function setLevelWeight(uint256[3] calldata _weight)
        external
        onlyRole(OWNER_ROLE)
    {
        for (uint256 i = 0; i < _weight.length; i++) {
            require(_weight[i] > 0, "invalid weight");
        }
        emit LevelWeight(levelWeight, _weight);
        levelWeight = _weight;
    }

    // set dms amount
    function setDmsAmount(uint256 _amount) public onlyRole(OWNER_ROLE) {
        require(_amount > 0, "invalid amount");
        emit DmsAmount(dmsAmount, _amount);
        dmsAmount = _amount;
    }

    // set blindbox max
    function setBoxMax(uint256 _max) public onlyRole(OWNER_ROLE) {
        require(_max > 0, "invalid max");
        emit BoxMax(boxMax, _max);
        boxMax = _max;
    }

    // set account max
    function setAccountMax(uint256 _max) public onlyRole(OWNER_ROLE) {
        require(_max > 0, "invalid max");
        emit AccountMax(accountMax, _max);
        accountMax = _max;
    }

    // set start time
    function setStartTime(uint256 _time) public onlyRole(OWNER_ROLE) {
        require(_time > 0, "invalid time");
        emit StartTime(startTime, _time);
        startTime = _time;
    }

    // set end time
    function setEndTime(uint256 _time) public onlyRole(OWNER_ROLE) {
        require(_time > 0, "invalid time");
        emit EndTime(endTime, _time);
        endTime = _time;
    }

    // set open time
    function setOpenTime(uint256 _time) public onlyRole(OWNER_ROLE) {
        require(_time > 0, "invalid time");
        emit OpenTime(openTime, _time);
        openTime = _time;
    }
}

// dragon blindbox
contract DragonBlindbox is DragonBlindboxBase, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _batchId;
    Counters.Counter private _id;

    constructor(
        address _dmsToken,
        address _dmbToken,
        address[] memory owners,
        address[] memory operators,
        address _recipient
    ) {
        require(owners.length > 0, "invalid owners");
        require(operators.length > 0, "invalid operators");
        require(_dmsToken != address(0), "invalid DMS Token");
        require(_dmbToken != address(0), "invalid DMB Token");
        require(_recipient != address(0), "invalid recipient");
        dmsToken = IERC20(_dmsToken);
        dmbToken = IDMBToken(_dmbToken);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < owners.length; i++) {
            _setupRole(OWNER_ROLE, owners[i]);
        }
        for (uint256 i = 0; i < operators.length; i++) {
            _setupRole(OPERATOR_ROLE, operators[i]);
        }
        recipient = _recipient;
        _batchId.increment();
    }

    // next batch config
    function setNextBatch(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _openTime,
        uint256 _amount,
        uint256 _boxMax,
        uint256 _accountMax
    ) external onlyRole(OWNER_ROLE) {
        require(block.timestamp > openTime, "next batch after open time");
        _batchId.increment();
        delete blindboxId;
        require(_startTime > block.timestamp, "invalid start time");
        require(_endTime > _startTime, "invalid end time");
        require(_openTime > _endTime, "invalid open time");
        require(_amount > 0, "invalid dms amount");
        require(_boxMax > 0, "invalid box max");
        require(_accountMax > 0, "invalid account max");
        setStartTime(_startTime);
        setEndTime(_endTime);
        setOpenTime(_openTime);
        setDmsAmount(_amount);
        setBoxMax(_boxMax);
        setAccountMax(_accountMax);
        // id reset
        _id.reset();
    }

    modifier checkBatch(uint256 _batch) {
        require(_batch <= _batchId.current(), "invalid batch");
        _;
    }

    // apply to join
    // dms transfer
    function applyJoin() external returns (bool) {
        require(
            block.timestamp >= startTime &&
                block.timestamp <= endTime &&
                startTime > 0 &&
                endTime > 0,
            "invalid time"
        );
        uint256 _currBatch = _batchId.current();
        require(
            !isApplyJoin(_currBatch, msg.sender),
            "The current user is already registered"
        );
        _id.increment();
        require(
            _id.current() <= accountMax,
            "The Blind Box registration is full"
        );
        require(
            dmsToken.balanceOf(msg.sender) >= dmsAmount,
            "Your DMS balance is insufficient"
        );
        require(
            dmsToken.transferFrom(msg.sender, recipient, dmsAmount),
            "DMS transfer failure"
        );
        balances[msg.sender] += dmsAmount;

        uint256 _newId = _id.current();
        blindboxId.push(_newId);
        blindboxAccount[_currBatch][_newId] = msg.sender;
        blindboxList[_currBatch][msg.sender] = BlindboxData(
            msg.sender,
            _currBatch,
            _id.current(),
            dmsAmount,
            0,
            false
        );
        emit ApplyJoin(_currBatch, msg.sender, dmsAmount);

        return true;
    }

    // get batch id
    function getBatchId() external view returns (uint256) {
        return _batchId.current();
    }

    // get apply count
    function getApplyCount() external view returns (uint256) {
        return blindboxId.length;
    }

    // get blindboxId list
    function getBlindboxId() external view returns (uint256[] memory) {
        return blindboxId;
    }

    // is apply join succ
    function isApplyJoin(uint256 _batch, address _account)
        public
        view
        checkBatch(_batch)
        returns (bool)
    {
        return blindboxList[_batch][_account].number > 0;
    }

    // is lucky blindbox
    function isLuckyBlindbox(uint256 _batch, address _account)
        external
        view
        checkBatch(_batch)
        returns (bool)
    {
        return blindboxList[_batch][_account].tokenId > 0;
    }

    // is opened blindbox
    function isOpenedBlindbox(uint256 _batch, address _account)
        external
        view
        checkBatch(_batch)
        returns (bool)
    {
        return blindboxList[_batch][_account].opened;
    }

    // withdraw dms token
    function withdraw() external {
        require(block.timestamp > openTime, "invalid withdraw time");
        uint256 _balance = balances[msg.sender];
        require(_balance > 0, "DMS balance is zero");
        balances[msg.sender] = 0;
        // deploy successful recipient manual approve 1e18 * 1e9
        dmsToken.transferFrom(recipient, msg.sender, _balance);
        emit Withdraw(msg.sender, _balance);
    }

    // open blindbox
    function openBlindbox(uint256 _batch)
        external
        checkBatch(_batch)
        nonReentrant
    {
        if (_batch == _batchId.current()) {
            require(
                block.timestamp > openTime && openTime > 0,
                "invalid open time"
            );
        }
        BlindboxData memory _box = blindboxList[_batch][msg.sender];
        require(!_box.opened, "The blind box has been opened");
        require(_box.tokenId > 0, "You did not win a blind box");
        blindboxList[_batch][msg.sender].opened = true;
        dmbToken.mint(msg.sender, _box.tokenId, 1, "0x");
        totalSupply += 1;
        emit OpenBlindbox(_batch, msg.sender, _box.tokenId);
    }

    function _random(uint256 _seed, uint256 _modulus)
        private
        view
        returns (uint256)
    {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    _seed,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number),
                    block.coinbase,
                    msg.sender
                )
            )
        );
        return rand % _modulus;
    }

    function _levelId(uint256 _level) private view returns (uint256) {
        if (_level <= levelWeight[0]) {
            return 3;
        } else if (_level <= levelWeight[1]) {
            return 2;
        } else if (_level <= levelWeight[2]) {
            return 1;
        }
        return 1;
    }

    // lucky blindbox -> tokenId
    // Run before OpenTime
    function luckyBlindbox(uint256 _start, uint256 _end)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(block.timestamp > endTime && endTime > 0, "invalid end time");
        require(_start < _end && _end - _start <= 500, "invalid params");
        uint256 _currBatch = _batchId.current();
        uint256 _len = blindboxId.length <= boxMax ? blindboxId.length : boxMax;
        require(_end <= _len, "invalid end");
        uint256 _seed = _random(_id.current(), _len);
        for (uint256 i = _start; i <= _end; i++) {
            uint256 _job = _random(_seed, 5) + 1; // 1 <= job <= 5
            uint256 _index = _random(_seed, blindboxId.length);
            uint256 _curr = blindboxId[_index];
            _seed = _curr;
            address _account = blindboxAccount[_currBatch][_curr];
            if (blindboxList[_currBatch][_account].tokenId > 0) {
                continue;
            }
            blindboxId[_index] = blindboxId[blindboxId.length - 1];
            blindboxId.pop();

            uint256 _level = _random(
                uint256(uint160(_account)),
                levelWeight[2]
            ) + 1; // 1 <= level <= 100
            uint256 _newTokenId = _job * 10 + _levelId(_level);
            BlindboxData storage _data = blindboxList[_currBatch][_account];
            _data.tokenId = _newTokenId;
            blindboxList[_currBatch][_account] = _data;
            balances[_account] -= dmsAmount;
            emit LuckyBlindbox(_batchId.current(), _account, _newTokenId);
        }
    }
}
