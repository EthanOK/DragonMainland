// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IDmbToken {
    function balanceOf(address account, uint256 id) external returns (uint256);

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

contract BoneCompound is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _seed;

    event DmsFees(uint256[2] newDmsFees);
    event DmpFees(uint256[2] newDmpFees);
    // compound limit
    event CompoundLimit(uint256 newLimit, uint256 oldLimit);
    // compound amount
    event CompoundAmount(uint256 newAmount, uint256 oldAmount);
    // compound weight
    event CompoundWeight(uint256[2] newWeight, uint256[2] oldWeight);
    // burnAccount event
    event BurnAccount(address newAddr, address oldAddr);
    // compound event
    event Compound(
        address indexed account,
        uint256 id,
        uint256 amount,
        uint256 newid
    );

    // 5:5 =>[5, 10]
    uint256[2] public compoundWeight = [5, 10];
    uint256 public compoundLimit = 3;
    uint256 public compoundAmount = 5;
    //dms fees
    uint256[2] public dmsFees = [0.1 ether, 0.2 ether];
    //dmp fees
    uint256[2] public dmpFees = [50 ether, 100 ether];
    // todo
    IDmbToken public dmbToken =
        IDmbToken(0xF1a41450f7DDEce82F3ea389E201f3b1478C9893);
    // todo
    IERC20 public dmsToken = IERC20(0x9a26e6D24Df036B0b015016D1b55011c19E76C87);
    // todo
    IERC20 public dmpToken = IERC20(0x1e1Ae1A767a80a6C4bd97F9a2983756e4A6E8aa7);
    // todo
    address public burnAccount = address(0xbCB428268DF6a25617513c0555d06e1e3809bCF3);

    modifier checkAddr(address _address) {
        require(_address != address(0), "address is zero");
        _;
    }

    // set compound weight
    function setCompoundWeight(uint256[2] calldata _weight) external onlyOwner {
        emit CompoundWeight(_weight, compoundWeight);
        compoundWeight = _weight;
    }

    // set burnAccount address
    function setBurnAccount(address _address)
        external
        onlyOwner
        checkAddr(_address)
    {
        emit BurnAccount(_address, burnAccount);
        burnAccount = _address;
    }

    // set DMS amount
    function setDmsFees(uint256[2] calldata _dmsFees) external onlyOwner {
        dmsFees = _dmsFees;
        emit DmsFees(_dmsFees);
    }

    // set DMP amount
    function setDmpFees(uint256[2] calldata _dmpFees) external onlyOwner {
        dmpFees = _dmpFees;
        emit DmpFees(_dmpFees);
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

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //compound
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
            dmbToken.balanceOf(msg.sender, _id) >= _amount,
            "balance is not enough"
        );
        //dms dmp transfer
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
        dmbToken.burn(msg.sender, _id, _amount);
        uint256 newid = _id + _random();
        dmbToken.mint(msg.sender, newid, 1, "");
        emit Compound(msg.sender, _id, _amount, newid);
        return newid;
    }

    function _random() internal returns (uint256) {
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
}
