// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ElventWorldToken interface
interface IEWToken {
    // create dragon egg
    function createEquipment(
        address _owner,
        uint8 _eqType,
        uint8 _job,
        uint256 _startTime
    ) external returns (uint256);
}

/**
 * @title equipment presale contract
 * @dev equipment buy and grow up.
 */
contract PreSaleEquipment is Pausable, Ownable {
    // buy event
    event Buy(
        address indexed account,
        uint256 tokenId,
        uint8 job,
        uint256 price
    );
    event NewPeriod(
        uint256 periodId,
        uint256 start,
        uint256 price,
        uint256 total
    );

    struct PreSale {
        // job 1-5 Water Fire Rock Storm Thunder
        uint256 id;
        uint8 eqType;
        uint8 job;
        uint256 price;
        string email;
    }

    struct Period {
        // start time
        uint256 start_time;
        // sale price
        uint256 price;
        // the period tatal
        uint256 total;
    }

    //  Elvent World Token
    IEWToken public eWToken;
    // recipient address
    address payable public recipient;
    // periodId total
    mapping(uint256 => uint256) public buyedPeriods;
    // periodId => Period
    mapping(uint256 => Period) public Periods;

    // period => account => is buyed
    mapping(uint256 => mapping(address => bool)) private _buyed;
    // period => email => is buyed
    mapping(uint256 => mapping(bytes32 => bool)) private _emails;
    // account => presale data
    mapping(address => PreSale) private _accounts;
    // presale tokenId => account
    mapping(uint256 => address) private _ids;

    constructor(address _ewtAddress, address _recipient) {
        eWToken = IEWToken(_ewtAddress);
        recipient = payable(_recipient);
        // initialize period
        Period storage _period = Periods[1];
        _period.start_time = 0;
        _period.price = 1 ether;
        _period.total = 2000;
    }

    modifier is_buyed(uint256 _periodId) {
        require(
            _buyed[_periodId][msg.sender] == false,
            "You've already bought it"
        );
        _;
    }

    modifier has_email(uint256 _periodId, string memory _email) {
        bytes32 key = keccak256(abi.encodePacked(_email));
        require(_emails[_periodId][key] == false, "email is exist");
        _;
    }

    function setRecipient(address _account) external onlyOwner {
        require(_account != address(0), "account address is zero");
        recipient = payable(_account);
    }

    function setNextPeriod(
        uint256 _periodId,
        uint256 _start,
        uint256 _price,
        uint256 _total
    ) external onlyOwner {
        require(_periodId > 0, "invalid periodId");
        require(_start >= block.timestamp, "invalid start");
        require(_total > 0, "invalid total");

        Period storage _period = Periods[_periodId];
        _period.start_time = _start;
        _period.price = _price;
        _period.total = _total;

        emit NewPeriod(_periodId, _start, _price, _total);
    }

    function setEWToken(address _token) external onlyOwner returns (bool) {
        require(_token != address(0), "invalid token address");
        eWToken = IEWToken(_token);
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
            uint8,
            uint256,
            string memory
        )
    {
        PreSale memory _presale = _accounts[account];
        return (
            _presale.id,
            _presale.eqType,
            _presale.job,
            _presale.price,
            _presale.email
        );
    }

    function buy(
        uint256 _periodId,
        uint8 _eqType,
        uint8 _job,
        string calldata _email
    )
        external
        payable
        whenNotPaused
        is_buyed(_periodId)
        has_email(_periodId, _email)
        returns (bool)
    {
        // is start
        require(
            block.timestamp > Periods[_periodId].start_time,
            "presale is not start"
        );
        // is end
        require(
            buyedPeriods[_periodId] < Periods[_periodId].total,
            "presale is end"
        );

        uint256 _price = msg.value;
        require(_job >= 1 && _job <= 5, "invalid job");
        require(_price > 0, "invalid price");
        bytes32 _mailKey = keccak256(abi.encodePacked(_email));
        require(_mailKey != keccak256(abi.encodePacked("")), "invalid email");
        require(_price >= Periods[_periodId].price, "invalid price");

        //transfer ether
        recipient.transfer(_price);

        // mine equipment token
        uint256 _tokenId = eWToken.createEquipment(
            msg.sender,
            _eqType,
            _job,
            0
        );
        require(_tokenId > 0, "create equipment failure");

        buyedPeriods[_periodId] += 1;

        // account data
        _accounts[msg.sender] = PreSale(
            _tokenId,
            _eqType,
            _job,
            _price,
            _email
        );
        _buyed[_periodId][msg.sender] = true;
        _emails[_periodId][_mailKey] = true;
        _ids[_tokenId] = msg.sender;

        emit Buy(msg.sender, _tokenId, _job, _price);

        return true;
    }

    receive() external payable {}

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
