// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import "./Adminable.sol";

/// dragon mainland bone
contract DragonMainlandBone is
    ERC1155,
    Ownable,
    Adminable,
    Pausable,
    ERC1155Burnable
{
    // compound event
    event Compound(
        address indexed account,
        uint256 id,
        uint256 amount,
        uint256 newid
    );

    // compound limit
    event CompoundLimit(uint256 newLimit, uint256 oldLimit);

    // compound amount
    event CompoundAmount(uint256 newAmount, uint256 oldAmount);

    // compound weight
    event CompoundWeight(uint256 newWeight, uint256 oldWeight);

    uint256 public constant WATER1 = 11;
    uint256 public constant WATER2 = 12;
    uint256 public constant WATER3 = 13;

    uint256 public constant FIRE1 = 21;
    uint256 public constant FIRE2 = 22;
    uint256 public constant FIRE3 = 23;

    uint256 public constant ROCK1 = 31;
    uint256 public constant ROCK2 = 32;
    uint256 public constant ROCK3 = 33;

    uint256 public constant STORM1 = 41;
    uint256 public constant STORM2 = 42;
    uint256 public constant STORM3 = 43;

    uint256 public constant THUNDER1 = 51;
    uint256 public constant THUNDER2 = 52;
    uint256 public constant THUNDER3 = 53;

    uint256 public compoundLimit = 3;
    uint256 public compoundAmount = 5;
    uint256 public compoundWeight = 80;

    constructor() ERC1155("https://dragonmainland.io/storage/item/{id}.json") {}

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyAdmin {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyAdmin {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // set compound limit
    function setCompoundLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "invalid compound limit");
        emit CompoundLimit(_limit, compoundLimit);
        compoundLimit = _limit;
    }

    // set compound amount
    function setCompoundAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "invalid compound amount");
        emit CompoundAmount(_amount, compoundAmount);
        compoundAmount = _amount;
    }

    // set compound weight
    function setCompoundWeight(uint256 _weight) external onlyOwner {
        require(_weight > 0, "invalid compound weight");
        emit CompoundWeight(_weight, compoundWeight);
        compoundWeight = _weight;
    }

    function _random() internal view returns (uint256) {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number),
                    block.coinbase
                )
            )
        );
        return rand % 100 < compoundWeight ? 0 : 1;
    }

    // compound dragon bone
    // 80%=0 20%=1
    function compound(uint256 _id, uint256 _amount)
        external
        whenNotPaused
        returns (uint256)
    {
        require(_amount == compoundAmount, "invalid compound amount");
        require(_id % 10 < compoundLimit, "invalid compound limit");
        require(balanceOf(msg.sender, _id) >= _amount, "balance is not enough");
        _burn(msg.sender, _id, _amount);
        uint256 newid = _id + _random();
        _mint(msg.sender, newid, 1, "");
        emit Compound(msg.sender, _id, _amount, newid);
        return newid;
    }

    receive() external payable {}

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}
