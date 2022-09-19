// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// dragon mainland shard IDO base contract
abstract contract DragonMainlandShardIDOBase is Ownable {
    // add whitelist
    event AddWhitelist(address indexed account);
    // deposit
    event Deposit(address indexed account, uint256 amount);
    // withdraw
    event Withdraw(address indexed account, uint256 amount);
    // dms price
    event DmsPrice(address indexed account, uint256 oldPrice, uint256 newPrice);
    // dms amount
    event DmsAmount(
        address indexed account,
        uint256 oldAmount,
        uint256 newAmount
    );
    // Deposit time
    event DepositTime(
        address indexed account,
        uint256 oldTime,
        uint256 newTime
    );
    // Withdraw time
    event WithdrawTime(
        address indexed account,
        uint256 oldTime,
        uint256 newTime
    );
    // Operator
    event Operator(address indexed account, address oldOpe, address newOpe);

    // DMS token
    IERC20 public DmsToken;

    // DMS max supply
    uint256 public maxSupply;

    // each DMS price
    uint256 public dmsPrice = 0.25 ether;

    // each DMS amount = 1000
    uint256 public dmsAmount = 1000000000000000000000;

    // deposit start time
    uint256 public depositTime = 1636113600;

    // withdraw start time
    uint256 public withdrawTime = depositTime + 5 days;

    // operator account
    address public operator;

    // set dms token price
    function setDmsPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "invalid price");
        uint256 _old = dmsPrice;
        dmsPrice = _price;
        emit DmsPrice(msg.sender, _old, _price);
    }

    // set dms token amount
    function setDmsAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "invalid amount");
        uint256 _old = dmsAmount;
        dmsAmount = _amount;
        emit DmsAmount(msg.sender, _old, _amount);
    }

    // set deposit start time
    function setDepositTime(uint256 _time) external onlyOwner {
        require(_time > block.timestamp, "invalid deposit time");
        uint256 _old = depositTime;
        depositTime = _time;
        emit DepositTime(msg.sender, _old, _time);
    }

    // set withdraw start time
    function setWithdrawTime(uint256 _time) external onlyOwner {
        require(_time > block.timestamp, "invalid withdraw time");
        uint256 _old = withdrawTime;
        withdrawTime = _time;
        emit WithdrawTime(msg.sender, _old, _time);
    }

    // set operator account
    function setOperator(address _account) external onlyOwner {
        require(_account != address(0), "invalid account");
        address _old = operator;
        operator = _account;
        emit Operator(msg.sender, _old, _account);
    }
}

// dragon mainland shard ido contract
contract DragonMainlandShardIDO is
    Ownable,
    Pausable,
    DragonMainlandShardIDOBase
{
    // whitelist account
    mapping(address => bool) public whitelistAccounts;

    // deposit amount
    mapping(address => uint256) public depositAmounts;

    // account withdraw
    mapping(address => bool) public withdrawed;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    constructor(
        address _dmsToken,
        uint256 _supply,
        address _operator
    ) {
        require(_dmsToken != address(0), "token address is zero");
        require(_operator != address(0), "operator address is zero");
        require(_supply > 0, "invalid supply");

        DmsToken = IERC20(_dmsToken);
        maxSupply = _supply;
        operator = _operator;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "invalid operator");
        _;
    }

    // add whitelist
    function addWhitelist(address[] calldata accounts)
        external
        onlyOperator
        whenNotPaused
        returns (bool)
    {
        require(accounts.length <= 200, "accounts length too long");
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelistAccounts[accounts[i]] = true;
            emit AddWhitelist(accounts[i]);
        }
        return true;
    }

    // account deposit bnb
    function deposit() external payable whenNotPaused {
        require(block.timestamp > depositTime, "deposit time is not start");
        require(
            block.timestamp < depositTime + 1 days,
            "deposit time is finish"
        );
        require(msg.value == dmsPrice, "invalid deposit price");
        require(whitelistAccounts[msg.sender], "account is not whitelist");
        require(depositAmounts[msg.sender] == 0, "account is deposited");

        depositAmounts[msg.sender] = msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // batch widthdraw
    function batchWithdraw(address[] calldata accounts)
        external
        onlyOperator
        whenNotPaused
    {
        require(block.timestamp > withdrawTime, "withdraw is not start");
        uint256 _balance = dmsBalance();
        require(
            _balance >= dmsAmount * accounts.length,
            "insufficient balance"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            address _currAcct = accounts[i];
            bool ok = whitelistAccounts[_currAcct] &&
                depositAmounts[_currAcct] > 0 &&
                !withdrawed[_currAcct];
            if (ok) {
                bool succ = DmsToken.transfer(_currAcct, dmsAmount);
                require(succ, "dms token transfer failure");
                withdrawed[_currAcct] = true;
                emit Withdraw(_currAcct, _balance);
            }
        }
    }

    // dms token balance
    function dmsBalance() public view returns (uint256) {
        return DmsToken.balanceOf(address(this));
    }

    // withdraw contract dms token balance
    function withdrawBalance() external onlyOwner {
        require(
            block.timestamp > withdrawTime + 5 days,
            "withdraw dms balance is not start"
        );
        uint256 _balance = dmsBalance();
        require(_balance > 0, "balance is zero");

        bool succ = DmsToken.transfer(msg.sender, _balance);
        require(succ, "dms token transfer failure");

        emit Withdraw(msg.sender, _balance);
    }

    // withdraw contract bnb balance
    function withdrawBnb() external onlyOwner {
        require(
            block.timestamp > withdrawTime + 5 days,
            "withdraw bnb balance is not start"
        );
        uint256 _balance = address(this).balance;
        require(_balance > 0, "balance is zero");

        payable(msg.sender).transfer(_balance);
        emit Withdraw(msg.sender, _balance);
    }
}
