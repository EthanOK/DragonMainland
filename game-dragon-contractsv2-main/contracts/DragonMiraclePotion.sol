// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// dragon miracle potion base contract
abstract contract DragonMiraclePotionBase is Pausable, AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
        _setupRole(
            OWNER_ROLE,
            address(0xe0C33CD3296ce1cdb3b102afDbaC43d35016954e)
        );
        _setupRole(
            OWNER_ROLE,
            address(0x1443E0447037903a02eD45050C7b4B49a81fB6Be)
        );
    }

    // mint max amount event
    event MintMaxAmount(uint256 newAmt, uint256 oldAmt);

    // set platform account event
    event PlatformAccount(address newAcct, address oldAcct);

    // mint withdraw data
    event MintWithdraw(
        address indexed to,
        uint256 amount,
        uint256 fee,
        uint64 _timestamp
    );

    // 10w eth
    uint256 public mintMaxAmount = 100000 ether;

    // totalSupplys
    uint256 public totalSupplys;

    // platform account
    address public platformAccount;

    // minted sign
    mapping(address => bytes) public mintedSign;
    // minted last timestamp
    mapping(address => uint64) public mintedTime;
    // minted withdraw
    mapping(address => uint256) public mintedWithdraw;
    // minted withdraw total
    mapping(address => uint256) public mintedTotal;
    mapping(address => uint256) public mintedTotalFee;

    // sign expiration time
    uint64 internal _expirationTime = 180;

    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }

    // set mint max amount
    function setMintMaxAmount(uint256 _amount) external onlyRole(OWNER_ROLE) {
        require(_amount > 0, "invalid amount");
        uint256 _old = mintMaxAmount;
        mintMaxAmount = _amount;
        emit MintMaxAmount(_amount, _old);
    }

    // set platform account
    function setPlatformAccount(address _account)
        external
        onlyRole(OWNER_ROLE)
    {
        require(_account != address(0), "invalid account");
        emit PlatformAccount(_account, platformAccount);
        platformAccount = _account;
    }
}

/**
 * Dragon Miracle Potion ERC20 Token
 */
contract DragonMiraclePotionToken is
    ERC20,
    ERC20Burnable,
    Pausable,
    DragonMiraclePotionBase
{
    using Strings for uint256;
    using ECDSA for bytes32;

    constructor(address _account, address[] memory _minters)
        ERC20("Dragon Miracle Potion", "DMP")
    {
        require(_account != address(0), "invalid platform account");
        require(_minters.length > 0, "invalid minter");

        platformAccount = _account;
        for (uint256 i = 0; i < _minters.length; i++) {
            _setupRole(MINTER_ROLE, _minters[i]);
        }
    }

    function isSameday(uint256 _timestamp) public view returns (bool) {
        uint256 _days = block.timestamp / 86400;
        return _timestamp >= _days * 86400 && _timestamp < (_days + 1) * 86400;
    }

    // mint
    // _feeAmt >= 0
    // one day mint let maxAmount
    function mint(
        address to,
        uint256 amount,
        uint256 _feeAmt,
        uint64 _timestamp
    ) external whenNotPaused onlyRole(MINTER_ROLE) returns (bool) {
        require(amount > 0 && amount <= mintMaxAmount, "invalid mintMaxAmount");
        require(
            _timestamp + _expirationTime >= block.timestamp,
            "expiration time"
        );
        require(mintedTime[to] < _timestamp, "invalid minted time");

        bool sameDay = isSameday(_timestamp);
        if (!sameDay) {
            mintedWithdraw[to] = amount;
        } else {
            mintedWithdraw[to] += amount;
        }
        require(
            mintedWithdraw[to] <= mintMaxAmount,
            "mintedWithdraw gt mintMaxAmount"
        );

        totalSupplys += amount;
        _mint(to, amount);
        mintedTotal[to] += amount;
        if (_feeAmt > 0) {
            _mint(platformAccount, _feeAmt);
            mintedTotalFee[to] += _feeAmt;
        }
        mintedTime[to] = _timestamp;
        emit MintWithdraw(to, amount, _feeAmt, _timestamp);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
