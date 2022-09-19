// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

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

contract PreSaleDragonEgg is Pausable {
    struct PreSale {
        // 水土火雷风 1-5
        uint8 kind;
        uint256 price;
        uint256 id;
        string email;
    }

    // 开始
    uint256 public start = 0;
    // 已预售总量
    uint256 public total_buy = 0;
    // 预售总量
    uint256 private _total = 95;
    // 当前期数
    uint256 public stage = 0;
    // 提现钱包
    address private _wdAccount = address(0);

    // 预售每周数量表
    uint16[5] private _amounts = [uint16(10), 15, 20, 25, 25];
    // 预售每周价格表
    uint256[5] private _prices = [
        0.01 ether,
        0.02 ether,
        0.03 ether,
        0.04 ether,
        0.05 ether
    ];

    event Buy(
        address indexed account,
        uint8 kind,
        uint256 price,
        uint256 id,
        string email
    );

    // 账号是否已预售
    mapping(address => bool) private _buyed;
    // 邮箱是否已存在
    mapping(bytes32 => bool) private _emails;
    // 账号已预售数据
    mapping(address => PreSale) private _accounts;
    // 已预售ID
    mapping(uint256 => address) private _ids;

    constructor() {
        start = block.timestamp + 10 * 1 minutes;
    }

    modifier is_start() {
        require(block.timestamp > start, "presale is not start");
        _;
    }

    modifier is_end() {
        require(total_buy <= _total, "presale is end");
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

    function totay_amount() public view returns (uint256) {
        return _amounts[stage];
    }

    function today_price() public view returns (uint256) {
        return _prices[stage];
    }

    function _lock_time() internal {
        uint256 t = block.timestamp;
        uint256 sub = 86400 - (t % 86400);
        // 20点-8时区差 12 * 3600
        start = t + sub + 43200;
    }

    function _today_stage() internal {
        if (total_buy == 10) {
            stage = 1;
            _lock_time();
        } else if (total_buy == 10 + 15) {
            stage = 2;
            _lock_time();
        } else if (total_buy == 10 + 15 + 20) {
            stage = 3;
            _lock_time();
        } else if (total_buy == 10 + 15 + 20 + 25) {
            stage = 4;
            _lock_time();
        }
    }

    function buy(
        uint8 _kind,
        uint256 _id,
        string calldata _email
    )
        public
        payable
        is_start
        is_end
        is_buyed
        has_email(_email)
        id_exist(_id)
        whenNotPaused
        returns (bool)
    {
        uint256 _price = msg.value;
        require(_kind >= 1 && _kind <= 5, "kind value fail");
        require(_price > 0, "price value fail");
        require(_id > 0, "id value fail");
        require(
            keccak256(abi.encodePacked(_email)) !=
                keccak256(abi.encodePacked("")),
            "email value fail"
        );
        require(_price >= today_price(), "price is too low");
        total_buy += 1;
        _today_stage();
        _accounts[msg.sender] = PreSale(_kind, _price, _id, _email);
        _buyed[msg.sender] = true;
        _ids[_id] = msg.sender;
        emit Buy(msg.sender, _kind, _price, _id, _email);
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
        return (_presale.kind, _presale.price, _presale.id, _presale.email);
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function setWdAccount(address _account) external onlyOwner returns (bool) {
        require(_account != address(0), "account address is zero");
        _wdAccount = _account;
        return true;
    }

    function withdraw() external returns (bool) {
        require(msg.sender == _wdAccount, "withdraw account fail");
        require(balance() > 0, "balance is zero");
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }

    receive() external payable {}

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}
