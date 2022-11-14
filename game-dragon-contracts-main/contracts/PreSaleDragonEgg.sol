// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

struct Attribute {
    uint256 health;
    uint256 attack;
    uint256 defense;
    uint256 speed;
    uint256 lifeForce;
}

struct Skill {
    uint256 horn;
    uint256 ear;
    uint256 wing;
    uint256 tail;
    uint256 talent;
}

interface IDragonToken {
    // create dragon egg
    function createDragonEggs(
        uint8 _job,
        uint256 _id,
        address _owner,
        uint256 _timestamp,
        bytes memory _sign
    ) external returns (bool);

    // hatch dragon egg
    function hatchDragonEggs(
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
    ) external returns (bool);
}

/**
 * @title dragon egg presale contract
 * @dev dragon egg buy and grow up.
 */
contract PreSaleDragonEgg is Pausable {
    struct PreSale {
        // job 1-5 Water Fire Rock Storm Thunder
        uint8 job;
        uint256 price;
        uint256 id;
        string email;
    }

    // dragonToken
    IDragonToken public dragonToken;

    // start time
    uint256 public start_time;
    // presale total
    uint256 public total_buy;
    // total
    uint256 public total = 1000;
    // recipient address
    address payable public recipient;
    // sale price
    uint256 public prices = 0.1 ether;
    // sale job
    uint256 public job = 2;

    event Buy(
        address indexed account,
        uint8 job,
        uint256 price,
        uint256 tokenId
    );

    // account is buyed
    mapping(address => bool) private _buyed;
    // email is buyed
    mapping(bytes32 => bool) private _emails;
    // account => presale data
    mapping(address => PreSale) private _accounts;
    // presale tokenId => account
    mapping(uint256 => address) private _ids;

    constructor(address _dragon, address _recipient) {
        // 2021.10.15（16:00:00 UTC+4）
        start_time = 1634299200;
        dragonToken = IDragonToken(_dragon);
        recipient = payable(_recipient);
    }

    modifier is_start() {
        require(block.timestamp > start_time, "presale is not start");
        _;
    }

    modifier is_end() {
        require(total_buy <= total, "presale is end");
        _;
    }

    modifier id_exist(uint256 _id) {
        require(_ids[_id] == address(0), "id is exist");
        _;
    }

    modifier is_buyed() {
        require(_buyed[msg.sender] == false, "your is buyed");
        _;
    }

    modifier has_email(string memory _email) {
        bytes32 key = keccak256(abi.encodePacked(_email));
        require(_emails[key] == false, "email is exist");
        _;
    }

    function getId(uint256 _id) public view returns (address) {
        return _ids[_id];
    }

    function buy(
        uint8 _job,
        uint256 _id,
        string calldata _email,
        uint256 _timestamp,
        bytes memory _sign
    )
        external
        payable
        whenNotPaused
        is_start
        is_end
        is_buyed
        has_email(_email)
        id_exist(_id)
        returns (bool)
    {
        uint256 _price = msg.value;
        require(_job >= 1 && _job <= 5 && _job == job, "invalid job");
        require(_price > 0, "invalid price");
        require(_id > 0, "invalid tokenId");
        bytes32 _mailKey = keccak256(abi.encodePacked(_email));
        require(_mailKey != keccak256(abi.encodePacked("")), "invalid email");
        require(_price >= prices, "invalid price");
        total_buy += 1;
        _accounts[msg.sender] = PreSale(_job, _price, _id, _email);
        _buyed[msg.sender] = true;
        _emails[_mailKey] = true;
        _ids[_id] = msg.sender;
        emit Buy(msg.sender, _job, _price, _id);
        recipient.transfer(_price);
        // dragon token
        require(
            dragonToken.createDragonEggs(
                _job,
                _id,
                msg.sender,
                _timestamp,
                _sign
            )
        );
        return true;
    }

    //  hatch dragon egg
    function hatchDragonEgg(
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
    ) external returns (bool) {
        require(_ids[_id] != address(0), "id is not exist");
        require(
            dragonToken.hatchDragonEggs(
                _id,
                _geneDomi,
                _geneRece,
                _matronId,
                _sireId,
                _stage,
                _attr,
                _skill,
                _uri,
                _timestamp,
                _sign
            )
        );
        return true;
    }

    function result(address account) public view returns (bool) {
        return _buyed[account];
    }

    function getPresale(address account)
        public
        view
        returns (
            uint8,
            uint256,
            uint256,
            string memory
        )
    {
        PreSale memory _presale = _accounts[account];
        return (_presale.job, _presale.price, _presale.id, _presale.email);
    }

    function setRecipient(address _account) external onlyOwner {
        require(_account != address(0), "account address is zero");
        recipient = payable(_account);
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "invalid price");
        prices = _price;
    }

    function setTotal(uint256 _total) external onlyOwner {
        require(_total > 0, "invalid total");
        total = _total;
    }

    function setJob(uint256 _job) external onlyOwner {
        require(_job > 0, "invalid job");
        job = _job;
    }

    function setStart(uint256 _start) external onlyOwner returns (bool) {
        require(_start >= block.timestamp, "invalid start");
        start_time = _start;
        return true;
    }

    function setDragonToken(address _token) external onlyOwner returns (bool) {
        require(_token != address(0), "invalid token address");
        dragonToken = IDragonToken(_token);
        return true;
    }

    receive() external payable {}

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}
