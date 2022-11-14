// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Adminable.sol";

abstract contract DragonMiraclePotionBase is Pausable, Ownable {
    // mint max amount event
    event MintMaxAmount(uint256 newAmt, uint256 oldAmt);

    // 10w eth
    uint256 public mintMaxAmount = 100000 ether;

    // totalSupplys
    uint256 public totalSupplys = 0;

    // minted time
    mapping(address => uint256) public mintedTime;

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // set mint max amount
    function setMintMaxAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "invalid amount");
        uint256 _old = mintMaxAmount;
        mintMaxAmount = _amount;
        emit MintMaxAmount(_amount, _old);
    }
}

/**
 * Dragon Miracle Potion ERC20 Token
 */
contract DragonMiraclePotionToken is
    ERC20,
    ERC20Burnable,
    Pausable,
    Ownable,
    Adminable,
    DragonMiraclePotionBase
{
    constructor() ERC20("Dragon Miracle Potion", "DMP") {}

    function mint(address to, uint256 amount) external onlyAdmin {
        require(amount <= mintMaxAmount, "invalid mintMaxAmount");
        require(
            block.timestamp >= mintedTime[msg.sender] + 86400,
            "invalid mint time"
        );
        mintedTime[msg.sender] = block.timestamp;
        totalSupplys += amount;
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
