// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// dragon mainland bone
// WATER 11 12 13
// FIRE 21 22 23
// ROCK 31 32 33
// STORM 41 42 43
// THUNDER 51 52 53
contract DragonMainlandBone is
    ERC1155,
    AccessControl,
    Pausable,
    ERC1155Burnable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    Counters.Counter private _seed;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // set dmsToken event
    event DmsToken(address newAddress);
    // set dmpToken event
    event DmpToken(address newAddress);
    // burn account event
    event BurnAccount(address newAddr, address oldAddr);
    event DmsFees(uint256[2] newDmsFees);
    event DmpFees(uint256[2] newDmpFees);
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
    event CompoundWeight(uint256[2] newWeight, uint256[2] oldWeight);

    uint256 public compoundLimit = 3;
    uint256 public compoundAmount = 5;
    // 5:5 => [5, 10]
    uint256[2] public compoundWeight = [5, 10];
    // dms fees
    uint256[2] public dmsFees = [0.1 ether, 0.2 ether];
    // dmp fees
    uint256[2] public dmpFees = [50 ether, 100 ether];
    // token
    IERC20 public dmsToken = IERC20(0x9a26e6D24Df036B0b015016D1b55011c19E76C87);
    // DMP token
    IERC20 public dmpToken = IERC20(0x599107669322B0E72be939331f35A693ba71EBE2);
    // burn account address
    address public burnAccount =
        address(0x54C3Aaa72632E1CbE6D5eC4e6e4F2D148E438bea);

    constructor(address[] memory owners, address[] memory minters)
        ERC1155("https://dragonmainland.io/storage/item/{id}.json")
    {
        require(owners.length > 0, "invalid owners");
        require(minters.length > 0, "invalid minters");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < owners.length; i++) {
            _setupRole(OWNER_ROLE, owners[i]);
        }
        for (uint256 i = 0; i < minters.length; i++) {
            _setupRole(MINTER_ROLE, minters[i]);
        }
    }

    modifier checkAddr(address _address) {
        require(_address != address(0), "address is zero");
        _;
    }

    function setURI(string memory newuri) external onlyRole(OWNER_ROLE) {
        _setURI(newuri);
    }

    // set DMS token address
    function setDmsToken(address _address)
        external
        onlyRole(OWNER_ROLE)
        checkAddr(_address)
    {
        emit DmsToken(_address);
        dmsToken = IERC20(_address);
    }

    // set DMP token address
    function setDmpToken(address _address)
        external
        onlyRole(OWNER_ROLE)
        checkAddr(_address)
    {
        emit DmpToken(_address);
        dmpToken = IERC20(_address);
    }

    // set burn address
    function setBurnAccount(address _address)
        external
        onlyRole(OWNER_ROLE)
        checkAddr(_address)
    {
        emit BurnAccount(_address, burnAccount);
        burnAccount = _address;
    }

    // set DMS fee
    function setDmsFees(uint256[2] calldata _dmsFees)
        external
        onlyRole(OWNER_ROLE)
    {
        dmsFees = _dmsFees;
        emit DmsFees(_dmsFees);
    }

    // set DMP fee
    function setDmpFees(uint256[2] calldata _dmpFees)
        external
        onlyRole(OWNER_ROLE)
    {
        dmpFees = _dmpFees;
        emit DmpFees(_dmpFees);
    }

    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external whenNotPaused onlyRole(MINTER_ROLE) nonReentrant {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external whenNotPaused onlyRole(MINTER_ROLE) nonReentrant {
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
    function setCompoundLimit(uint256 _limit) external onlyRole(OWNER_ROLE) {
        require(_limit > 0, "invalid compound limit");
        emit CompoundLimit(_limit, compoundLimit);
        compoundLimit = _limit;
    }

    // set compound amount
    function setCompoundAmount(uint256 _amount) external onlyRole(OWNER_ROLE) {
        require(_amount > 0, "invalid compound amount");
        emit CompoundAmount(_amount, compoundAmount);
        compoundAmount = _amount;
    }

    // set compound weight
    function setCompoundWeight(uint256[2] calldata _weight)
        external
        onlyRole(OWNER_ROLE)
    {
        emit CompoundWeight(_weight, compoundWeight);
        compoundWeight = _weight;
    }

    // compound dragon bone
    // 50%=0 50%=1
    function compound(uint256 _id, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(_amount == compoundAmount, "invalid compound amount");
        uint256 _currLevel = _id % 10;
        require(_currLevel < compoundLimit, "invalid compound limit");
        require(
            balanceOf(msg.sender, _id) >= _amount,
            "dragon bone not enough"
        );
        // dms dmp transfer
        uint256 _dmsFee = dmsFees[_currLevel - 1];
        uint256 _dmpFee = dmpFees[_currLevel - 1];
        require(
            dmsToken.balanceOf(msg.sender) >= _dmsFee,
            "DMS balance not enough"
        );
        require(
            dmpToken.balanceOf(msg.sender) >= _dmpFee,
            "DMP balance not enough"
        );
        require(
            dmsToken.transferFrom(msg.sender, burnAccount, _dmsFee),
            "dms transfer failure"
        );
        require(
            dmpToken.transferFrom(msg.sender, burnAccount, _dmpFee),
            "dmp transfer failure"
        );
        _burn(msg.sender, _id, _amount);
        uint256 newid = _id + _random();
        _mint(msg.sender, newid, 1, "");
        emit Compound(msg.sender, _id, _amount, newid);
        return newid;
    }

    function _random() private returns (uint256) {
        _seed.increment();
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    _seed.current() +
                        block.timestamp +
                        block.difficulty +
                        uint256(keccak256(abi.encodePacked(block.coinbase))) /
                        block.timestamp +
                        block.gaslimit +
                        uint256(keccak256(abi.encodePacked(msg.sender))) /
                        block.timestamp +
                        block.number
                )
            )
        ) % compoundWeight[1];

        uint256 _result = rand < compoundWeight[0] ? 0 : 1;
        return _result;
    }

    // todo copy dragon bone absorb code here
}
