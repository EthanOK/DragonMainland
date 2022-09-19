// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./DragonTransfer.sol";

// dragon mainland token interface
interface IDragonToken {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    // create dragon eggs
    function createDragonEggs(
        uint8 _job,
        uint256 _tokenId,
        address _owner,
        uint256 _timestamp,
        bytes calldata _sign
    ) external returns (bool);

    // add dragon breed count
    function addDragonBreedCount(
        uint256 _tokenId,
        uint256 _timestamp,
        bytes calldata _sign
    ) external returns (bool);
}

// breed Contract
interface IBreedContract {
    function breedCounts(uint256 _tokenId) external view returns (uint256);

    function cooldownTimeEnd(uint256 _tokenId) external view returns (uint256);
}

/**
 * dragon contract exchange
 */

/// dragon mainland token ERC721 exchange
contract DragonExchange is
    Pausable,
    Ownable,
    DragonTransfer,
    ERC721Holder,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    Counters.Counter private _orderIds;

    // add market
    event AddMarket(
        address indexed from,
        uint256 tokenId,
        uint256 price,
        uint8 exType,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 timeHours,
        uint256 createTime,
        uint256 orderId
    );

    // remove market
    event RemoveMarket(address indexed from, uint256 tokenId, uint256 orderId);

    // nft exchange
    event Exchange(
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 price,
        uint256 fee,
        uint8 exType,
        uint256 orderId
    );

    // dragon breed count
    event BreedCount(address indexed from, uint256 tokenId, uint256 count);
    // breed count max
    event BreedCountMax(uint256 newCount, uint256 oldCount);
    // breed cooldown time end
    event CooldownTimeEnd(uint256 tokenId, uint256 cooldownEnd);
    // breed data
    event BreedData(
        uint8 job,
        uint256 tokenId,
        uint256 matronId,
        uint256 sireId,
        address owner
    );
    // breed cooldown event
    event BreedCooldown(uint256[] _days);
    // exchange expiration time
    uint64 internal _expirationTime = 180;

    // DMT token contract
    IDragonToken public dragonToken;
    // breed contract
    IBreedContract public breedContOld =
        IBreedContract(0xD1cb5878A65666407CC40bC0C429b27AD4474016);
    // breed contract 12-11
    IBreedContract public breedContV1 =
        IBreedContract(0xBC6F5354043c430508Ced776Bd8A7e6B2524C568);
    // breed contract exchangev1_addr
    IBreedContract public breedContExV1 =
        IBreedContract(0x7316a41945D98b7fb1D6c773ba7516C8054deb9E);
    // breed contract exchangev1_order_addr
    IBreedContract public breedContExOrderV1 =
        IBreedContract(0x6648991e4D4f0E760f0ee8cb44371BFb52D6c1c6);

    // exchange data
    struct ExchangeData {
        address from;
        address to;
        uint256 price; // price
        uint256 create;
        uint8 ex_type; // 1=exchange 2=auction
        bool state;
        uint256 min_price;
        uint256 max_price;
        uint256 time_hours;
        uint256 order_id;
    }

    // dragon breed cooldown time config
    mapping(uint256 => uint256) public breedCooldown;
    // matron sire dragon cooldown time
    mapping(uint256 => uint256) public cooldownTimeEnd;
    // nft tokenId => exchange data & price
    mapping(uint256 => ExchangeData) public exchangeDatas;
    // dragon breed count
    mapping(uint256 => uint256) public breedCounts;
    // dragon breed count max
    uint256 public breedCountMax = 7;
    // hour cycle
    uint256 public constant CYCLE = 3600;

    function setBreedCountMax(uint256 _count) external onlyOwner {
        require(_count > 0, "invalid count");
        emit BreedCountMax(_count, breedCountMax);
        breedCountMax = _count;
    }

    //  breed cooldown next time init data
    function _breedCooldownInit() private {
        breedCooldown[1] = 0 days;
        breedCooldown[2] = 2 days;
        breedCooldown[3] = 4 days;
        breedCooldown[4] = 6 days;
        breedCooldown[5] = 9 days;
        breedCooldown[6] = 12 days;
        breedCooldown[7] = 15 days;
    }

    // breed dragon DMP token amount
    function setBreedCooldown(uint256[] calldata _days) external onlyOwner {
        for (uint256 i = 0; i < _days.length; i++) {
            require(_days[i] > 0, "amount is zero");
            breedCooldown[i + 1] = _days[i];
        }
        emit BreedCooldown(_days);
    }

    modifier isExchange(uint256 _tokenId) {
        require(exchangeDatas[_tokenId].state, "invalid nft state");
        _;
    }

    constructor(address payable _dragon) {
        require(_dragon != address(0), "dragon address is zero");
        dragonToken = IDragonToken(_dragon);
        _breedCooldownInit();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // nft join market
    // _price dms price
    function addMarket(
        uint256 _tokenId,
        uint256 _price,
        uint8 _exType,
        uint256 _minPrice,
        uint256 _maxPrice,
        uint256 _timeHours
    ) external whenNotPaused nonReentrant returns (bool) {
        require(!exchangeDatas[_tokenId].state, "nft is in market");
        require(
            dragonToken.ownerOf(_tokenId) == msg.sender,
            "invalid nft owner"
        );
        require(_exType == 1 || _exType == 2, "invalid exType");
        if (_exType == 2) {
            require(_minPrice > 0, "invalid minPrice");
            require(_maxPrice > _minPrice, "invalid maxPrice");
            require(_timeHours >= 24, "invalid timeHours");
        }
        _orderIds.increment();
        uint256 _newOrderId = _orderIds.current();
        dragonToken.safeTransferFrom(msg.sender, address(this), _tokenId);
        exchangeDatas[_tokenId] = ExchangeData(
            msg.sender,
            address(0),
            _price,
            block.timestamp,
            _exType,
            true,
            _minPrice,
            _maxPrice,
            _timeHours,
            _newOrderId
        );
        emit AddMarket(
            msg.sender,
            _tokenId,
            _price,
            _exType,
            _minPrice,
            _maxPrice,
            _timeHours,
            block.timestamp,
            _newOrderId
        );
        return true;
    }

    // nft remove market
    function removeMarket(uint256 _tokenId, uint256 _orderId)
        external
        whenNotPaused
        nonReentrant
        isExchange(_tokenId)
        returns (bool)
    {
        require(
            exchangeDatas[_tokenId].from == msg.sender,
            "invalid nft owner"
        );

        ExchangeData storage _exdata = exchangeDatas[_tokenId];
        _exdata.state = false;
        dragonToken.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit RemoveMarket(msg.sender, _tokenId, _orderId);
        return true;
    }

    // current exchange price
    function exchangePrice(uint256 _tokenId)
        public
        view
        returns (uint256, uint256)
    {
        ExchangeData memory _exdata = exchangeDatas[_tokenId];
        if (_exdata.ex_type == 1) {
            return (_exdata.price, 0);
        } else if (_exdata.ex_type == 2) {
            if (
                block.timestamp >= _exdata.create + _exdata.time_hours * CYCLE
            ) {
                return (_exdata.min_price, 0);
            }
            uint256 _hour = (block.timestamp - _exdata.create) / CYCLE;
            uint256 _one = (_exdata.max_price - _exdata.min_price) /
                _exdata.time_hours;
            uint256 _price = _exdata.max_price - (_one * _hour);
            return (_price, _hour);
        } else {
            return (0, 0);
        }
    }

    // nft exchange
    // transfer dms token
    function exchange(uint256 _tokenId, uint256 _orderId)
        external
        whenNotPaused
        nonReentrant
        isExchange(_tokenId)
        returns (bool)
    {
        ExchangeData storage _exdata = exchangeDatas[_tokenId];
        require(_exdata.state, "order not in market");
        uint256 _balance = dmsToken.balanceOf(msg.sender);
        uint8 _exType = _exdata.ex_type;
        require(_exType == 1 || _exType == 2, "invalid exchange type");
        uint256 _price;
        if (_exType == 1) {
            _price = _exdata.price;
        } else if (_exType == 2) {
            (uint256 _currPrice, ) = exchangePrice(_tokenId);
            _price = _currPrice;
        }
        require(_exdata.order_id == _orderId, "invalid order_id");
        require(_price > 0, "invalid price");
        require(_balance >= _price, "DMS balance is not enough");
        uint256 _fee = exchangeFee(_price);
        // DMS token
        dmsTransferEarn(msg.sender, _fee);
        dmsTransferFrom(msg.sender, _exdata.from, _price - _fee);
        // dragon nft
        dragonToken.safeTransferFrom(address(this), msg.sender, _tokenId);
        _exdata.to = msg.sender;
        _exdata.state = false;

        emit Exchange(
            msg.sender,
            _exdata.from,
            _tokenId,
            _price,
            _fee,
            _exType,
            _orderId
        );
        return true;
    }

    function _breedCountVal(uint256 _tokenId) private view returns (uint256) {
        if (breedCounts[_tokenId] == 0) {
            return
                breedContOld.breedCounts(_tokenId) +
                breedContV1.breedCounts(_tokenId) +
                breedContExV1.breedCounts(_tokenId) +
                breedContExOrderV1.breedCounts(_tokenId);
        } else {
            return breedCounts[_tokenId];
        }
    }

    function _cooldownTimeEndVal(uint256 _tokenId)
        private
        view
        returns (uint256)
    {
        uint256 _end = cooldownTimeEnd[_tokenId];
        uint256 _end1 = breedContOld.cooldownTimeEnd(_tokenId);
        uint256 _end2 = breedContV1.cooldownTimeEnd(_tokenId);
        uint256 _end3 = breedContExV1.cooldownTimeEnd(_tokenId);
        uint256 _end4 = breedContExOrderV1.cooldownTimeEnd(_tokenId);
        if (_end1 > _end) {
            _end = _end1;
        }
        if (_end2 > _end) {
            _end = _end2;
        }
        if (_end3 > _end) {
            _end = _end3;
        }
        if (_end4 > _end) {
            _end = _end4;
        }
        return _end;
    }

    // breed dragon eggs
    function breedDragonEggs(
        uint8 _job,
        uint256 _tokenId,
        uint256 _matronId,
        uint256 _sireId,
        address _owner,
        uint256 _timestamp,
        bytes calldata _sign,
        bytes calldata _signMatron,
        bytes calldata _signSire
    ) external whenNotPaused nonReentrant returns (bool) {
        require(_job >= 1 && _job <= 5, "invalid job");
        require(_tokenId > 10000, "invalid tokenId");
        require(
            dragonToken.ownerOf(_matronId) == msg.sender,
            "invalid matronId"
        );
        require(dragonToken.ownerOf(_sireId) == msg.sender, "invalid sireId");

        // breed count
        require(
            _breedCountVal(_matronId) < breedCountMax,
            "matron breed count max"
        );
        require(
            _breedCountVal(_sireId) < breedCountMax,
            "sire breed count max"
        );

        // breed cooldown
        require(
            block.timestamp >= _cooldownTimeEndVal(_matronId),
            "matronId is cooldown"
        );
        require(
            block.timestamp >= _cooldownTimeEndVal(_sireId),
            "sireId is cooldown"
        );

        _breedCounts(_matronId, _sireId);

        require(
            dragonToken.addDragonBreedCount(_matronId, _timestamp, _signMatron),
            "addDragonBreedCount matron failure"
        );
        require(
            dragonToken.addDragonBreedCount(_sireId, _timestamp, _signSire),
            "addDragonBreedCount sire failure"
        );
        // dragon token create dragon egg
        require(
            dragonToken.createDragonEggs(
                _job,
                _tokenId,
                _owner,
                _timestamp,
                _sign
            ),
            "createDragonEggs failure"
        );
        emit BreedData(_job, _tokenId, _matronId, _sireId, _owner);
        return true;
    }

    function _breedCounts(uint256 _matronId, uint256 _sireId) private {
        // dragon token breed count add
        if (breedCounts[_matronId] == 0) {
            breedCounts[_matronId] = 1 + _breedCountVal(_matronId);
        } else {
            breedCounts[_matronId] += 1;
        }
        if (breedCounts[_sireId] == 0) {
            breedCounts[_sireId] = 1 + _breedCountVal(_sireId);
        } else {
            breedCounts[_sireId] += 1;
        }
        uint256 _matronIdBreed = breedCounts[_matronId];
        uint256 _sireIdBreed = breedCounts[_sireId];
        emit BreedCount(msg.sender, _matronId, _matronIdBreed);
        emit BreedCount(msg.sender, _sireId, _sireIdBreed);

        // breed cooldown
        uint256 _matronCooldown = block.timestamp +
            breedCooldown[_matronIdBreed + 1];
        uint256 _sireCooldown = block.timestamp +
            breedCooldown[_sireIdBreed + 1];
        cooldownTimeEnd[_matronId] = _matronCooldown;
        cooldownTimeEnd[_sireId] = _sireCooldown;
        emit CooldownTimeEnd(_matronId, _matronCooldown);
        emit CooldownTimeEnd(_sireId, _sireCooldown);

        // dms token
        // dmsTransferEarn(
        //     msg.sender,
        //     breedDmsAmt[_matronIdBreed] + breedDmsAmt[_sireIdBreed]
        // );
        // dmpTransferEarn(
        //     msg.sender,
        //     breedDmpAmt[_matronIdBreed] + breedDmpAmt[_sireIdBreed]
        // );
        uint256 dmsBalance = dmsToken.balanceOf(msg.sender);
        require(
            dmsBalance >=
                breedDmsAmt[_matronIdBreed] + breedDmsAmt[_sireIdBreed],
            "DMS balance is not enough"
        );
        dmsToken.transferFrom(
            msg.sender,
            burnAccount,
            breedDmsAmt[_matronIdBreed] + breedDmsAmt[_sireIdBreed]
        );

        uint256 dmpBalance = dmpToken.balanceOf(msg.sender);
        require(
            dmpBalance >=
                breedDmpAmt[_matronIdBreed] + breedDmpAmt[_sireIdBreed],
            "DMP balance is not enough"
        );
        dmpToken.transferFrom(
            msg.sender,
            burnAccount,
            breedDmpAmt[_matronIdBreed] + breedDmpAmt[_sireIdBreed]
        );
    }
}
