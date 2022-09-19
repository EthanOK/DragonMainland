// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// dragon transfer dms dmp token
contract DragonTransfer is Ownable {
    // change dmsToken event
    event ChangeDmsToken(address newAddress);
    // change dmpToken event
    event ChangeDmpToken(address newAddress);
    // change dmbToken event
    event ChangeDmbToken(address newAddress);
    // feeRate event
    event FeeRate(uint256 newFee, uint256 oldFee);
    // beneficiary event
    event Beneficiary(address newAddr, address oldAddr);
    // DMS amount event
    event DmsAmount(uint256 newAmt, uint256 oldAmt);
    // DMP amount event
    event DmpAmount(uint256 newAmt, uint256 oldAmt);
    // DMB amount event
    event DmbAmount(uint256 newAmt, uint256 oldAmt);
    // talent DMS amount event
    event TalentDmsAmt(uint256 newAmt, uint256 oldAmt);
    // talent DMP amount event
    event TalentDmpAmt(uint256 newAmt, uint256 oldAmt);
    // skill DMS amount event
    event SkillDmsAmt(uint256 newAmt, uint256 oldAmt);
    // skill DMP amount event
    event SkillDmpAmt(uint256 newAmt, uint256 oldAmt);
    // breed DMS amounts event
    event BreedDmsAmt(uint256[] amounts);
    // Breed DMP amounts event
    event BreedDmpAmt(uint256[] amounts);

    // dragon mainland token
    IERC20 public dmsToken = IERC20(0x70E76c217AF66b6893637FABC1cb2EbEd254C90c);
    // DMP token
    IERC20 public dmpToken = IERC20(0x37d42C82f7EFdA80E50e0c28e92CE742ff3C9f4b);
    // dragon bone token
    IERC1155 public dmbToken =
        IERC1155(0xBD44234387Ecdaf236BEA4E3979Cd2856F03df51);

    // beneficiary address
    address public beneficiary = address(0xdA2B827D0CF49C511D2bB2656c04931E7bF0cC2C);
    // burn address
    address public burnAccount = address(0xdbCD59927b1D39cB9A01d5C3DbD910300e59d1F2);
    // exchange fee rate
    uint256 public feeRate = 500;

    uint256 public dmsAmount = 1 * 1000000;
    uint256 public dmpAmount = 1 ether;
    uint256 public dmbAmount = 5;

    //  talent update
    uint256 public talentDmsAmt = 1 * 1000000;
    uint256 public talentDmpAmt = 1 ether;

    //  skill update
    uint256 public skillDmsAmt = 1 * 1000000;
    uint256 public skillDmpAmt = 1 ether;

    // breed dragon
    mapping(uint256 => uint256) public breedDmsAmt;
    mapping(uint256 => uint256) public breedDmpAmt;

    //  breed DMS amount init data
    function _breedDmsAmtInit() private {
        breedDmsAmt[1] = 0.2 ether;
        breedDmsAmt[2] = 0.4 ether;
        breedDmsAmt[3] = 0.6 ether;
        breedDmsAmt[4] = 1 ether;
        breedDmsAmt[5] = 1.5 ether;
        breedDmsAmt[6] = 2 ether;
        breedDmsAmt[7] = 2.5 ether;
    }

    //  breed DMP amount init data
    function _breedDmpAmtInit() private {
        breedDmpAmt[1] = 200 ether;
        breedDmpAmt[2] = 400 ether;
        breedDmpAmt[3] = 600 ether;
        breedDmpAmt[4] = 1000 ether;
        breedDmpAmt[5] = 1600 ether;
        breedDmpAmt[6] = 2400 ether;
        breedDmpAmt[7] = 3400 ether;
    }

    constructor() {
        _breedDmsAmtInit();
        _breedDmpAmtInit();
    }

    modifier checkAddr(address _address) {
        require(_address != address(0), "address is zero");
        _;
    }

    modifier checkAmt(uint256 _amount) {
        require(_amount > 0, "amount is zero");
        _;
    }

    // set DMS token address
    function setDmsToken(address _address)
        external
        onlyOwner
        checkAddr(_address)
    {
        emit ChangeDmsToken(_address);
        dmsToken = IERC20(_address);
    }

    // set DMP token address
    function setDmpToken(address _address)
        external
        onlyOwner
        checkAddr(_address)
    {
        emit ChangeDmpToken(_address);
        dmpToken = IERC20(_address);
    }

    // set beneficiary address
    function setBeneficiary(address _address)
        external
        onlyOwner
        checkAddr(_address)
    {
        emit Beneficiary(_address, beneficiary);
        beneficiary = _address;
    }

    // set DMS amount
    function setDmsAmount(uint256 _amount)
        external
        onlyOwner
        checkAmt(_amount)
    {
        emit DmsAmount(_amount, dmsAmount);
        dmsAmount = _amount;
    }

    // set DMP amount
    function setDmpAmount(uint256 _amount)
        external
        onlyOwner
        checkAmt(_amount)
    {
        emit DmpAmount(_amount, dmpAmount);
        dmpAmount = _amount;
    }

    // set DMB amount
    function setDmbAmount(uint256 _amount)
        external
        onlyOwner
        checkAmt(_amount)
    {
        emit DmbAmount(_amount, dmbAmount);
        dmbAmount = _amount;
    }

    // set DMB token address
    function setDmbToken(address _address)
        external
        onlyOwner
        checkAddr(_address)
    {
        emit ChangeDmbToken(_address);
        dmbToken = IERC1155(_address);
    }

    // set talent DMS token amount
    function setTalentDmsAmt(uint256 _amount)
        external
        onlyOwner
        checkAmt(_amount)
    {
        emit TalentDmsAmt(_amount, talentDmsAmt);
        talentDmsAmt = _amount;
    }

    // set talent DMP token amount
    function setTalentDmpAmt(uint256 _amount)
        external
        onlyOwner
        checkAmt(_amount)
    {
        emit TalentDmpAmt(_amount, talentDmpAmt);
        talentDmpAmt = _amount;
    }

    // set skill DMS token amount
    function setSkillDmsAmt(uint256 _amount)
        external
        onlyOwner
        checkAmt(_amount)
    {
        emit SkillDmsAmt(_amount, skillDmsAmt);
        skillDmsAmt = _amount;
    }

    // set skill DMP token amount
    function setSkillDmpAmt(uint256 _amount)
        external
        onlyOwner
        checkAmt(_amount)
    {
        emit SkillDmpAmt(_amount, skillDmpAmt);
        skillDmpAmt = _amount;
    }

    // breed dragon DMS token amount
    function setBreedDmsAmt(uint256[] calldata _amounts) external onlyOwner {
        for (uint256 i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0, "amount is zero");
            breedDmsAmt[i + 1] = _amounts[i];
        }
        emit BreedDmsAmt(_amounts);
    }

    // breed dragon DMP token amount
    function setBreedDmpAmt(uint256[] calldata _amounts) external onlyOwner {
        for (uint256 i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0, "amount is zero");
            breedDmpAmt[i + 1] = _amounts[i];
        }
        emit BreedDmpAmt(_amounts);
    }

    // set fee rate
    function setFeeRate(uint256 _fee) external onlyOwner {
        require(_fee > 0, "fee value invalid");
        emit FeeRate(_fee, feeRate);
        feeRate = _fee;
    }

    // dms token transfer earn
    function dmsTransferEarn(address _from, uint256 _amount) internal {
        uint256 dmsBalance = dmsToken.balanceOf(_from);
        require(dmsBalance >= _amount, "DMS balance is not enough");
        dmsToken.transferFrom(_from, beneficiary, _amount);
    }

    // dmp token transfer earn
    function dmpTransferEarn(address _from, uint256 _amount) internal {
        uint256 dmpBalance = dmpToken.balanceOf(_from);
        require(dmpBalance >= _amount, "DMP balance is not enough");
        dmpToken.transferFrom(_from, beneficiary, _amount);
    }

    // dms token transferFrom
    function dmsTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        uint256 dmsBalance = dmsToken.balanceOf(_from);
        require(dmsBalance >= _amount, "DMS balance is not enough");
        dmsToken.transferFrom(_from, _to, _amount);
    }

    // dmp token transferFrom
    function dmpTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        uint256 dmpBalance = dmpToken.balanceOf(_from);
        require(dmpBalance >= _amount, "DMP balance is low");
        dmpToken.transferFrom(_from, _to, _amount);
    }

    // exchange fee
    function exchangeFee(uint256 _price) public view returns (uint256) {
        return (_price * feeRate) / 10000;
    }
}
