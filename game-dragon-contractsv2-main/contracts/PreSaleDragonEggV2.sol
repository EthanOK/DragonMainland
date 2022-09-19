// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDragonToken {
    // create dragon egg
    function createDragonEggs(
        uint256 _tokenId,
        uint8 _job,
        uint256 _matronId,
        uint256 _sireId,
        address _owner,
        uint256 _startTime
    ) external returns (bool);
}

/**
 * @title dragon egg presale contract
 * @dev dragon egg buy and grow up.
 */
contract PreSaleDragonEgg is Pausable, Ownable {
    // buy event
    event Buy(
        address indexed account,
        uint256 tokenId,
        uint8 job,
        uint256 price
    );
    event NewPeriod(uint256 periodId, uint256 start, uint256 total);

    struct PreSale {
        // job 1-5 Water Fire Rock Storm Thunder
        uint256 id;
        uint8 job;
        uint256 price;
        string email;
    }

    // dragonToken
    IDragonToken public dragonToken;

    // start time
    uint256 public start_time;
    // presale total
    uint256 public total_buy;
    // recipient address
    address payable public recipient;
    // sale price
    uint256 public prices = 0.1 ether;
    // sale job
    uint256 public job = 2;
    // period Id
    uint256 public periodId = 1;
    // periodId total
    mapping(uint256 => uint256) public periodTotals;

    // period => account => is buyed
    mapping(uint256 => mapping(address => bool)) private _buyed;
    // period => email => is buyed
    mapping(uint256 => mapping(bytes32 => bool)) private _emails;
    // account => presale data
    mapping(address => PreSale) private _accounts;
    // presale tokenId => account
    mapping(uint256 => address) private _ids;

    constructor(address _dragon, address _recipient) {
        // 2021.10.15（16:00:00 UTC+4）
        start_time = 1634299200;
        dragonToken = IDragonToken(_dragon);
        recipient = payable(_recipient);
        periodTotals[periodId] = 1000;
    }

    modifier is_start() {
        require(block.timestamp > start_time, "presale is not start");
        _;
    }

    modifier is_end() {
        require(total_buy < periodTotals[periodId], "presale is end");
        _;
    }

    modifier id_exist(uint256 _id) {
        require(_ids[_id] == address(0), "id is exist");
        _;
    }

    modifier is_buyed() {
        require(
            _buyed[periodId][msg.sender] == false,
            "You've already bought it"
        );
        _;
    }

    modifier has_email(string memory _email) {
        bytes32 key = keccak256(abi.encodePacked(_email));
        require(_emails[periodId][key] == false, "email is exist");
        _;
    }

    function setRecipient(address _account) external onlyOwner {
        require(_account != address(0), "account address is zero");
        recipient = payable(_account);
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "invalid price");
        prices = _price;
    }

    function setJob(uint256 _job) external onlyOwner {
        require(_job > 0, "invalid job");
        job = _job;
    }

    function setNextPeriod(
        uint256 _periodId,
        uint256 _start,
        uint256 _total
    ) external onlyOwner {
        require(_periodId > 0, "invalid periodId");
        require(_start >= block.timestamp, "invalid start");
        require(_total > 0, "invalid total");
        periodId = _periodId;
        start_time = _start;
        periodTotals[periodId] = _total;
        emit NewPeriod(_periodId, _start, _total);
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

    function getId(uint256 _id) public view returns (address) {
        return _ids[_id];
    }

    function result(address account, uint256 _periodId)
        public
        view
        returns (bool)
    {
        return _buyed[_periodId][account];
    }

    function getPresale(address account)
        public
        view
        returns (
            uint256,
            uint8,
            uint256,
            string memory
        )
    {
        PreSale memory _presale = _accounts[account];
        return (_presale.id, _presale.job, _presale.price, _presale.email);
    }

    function buy(
        uint256 _id,
        uint8 _job,
        string calldata _email
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
        _accounts[msg.sender] = PreSale(_id, _job, _price, _email);
        _buyed[periodId][msg.sender] = true;
        _emails[periodId][_mailKey] = true;
        _ids[_id] = msg.sender;

        //transfer ether
        recipient.transfer(_price);
        // mine dragon token
        require(dragonToken.createDragonEggs(_id, _job, 0, 0, msg.sender, 0));

        emit Buy(msg.sender, _id, _job, _price);

        return true;
    }

    receive() external payable {}

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}
