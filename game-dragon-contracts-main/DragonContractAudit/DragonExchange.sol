// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
    // add market
    event AddMarket(
        address indexed from,
        uint256 tokenId,
        uint256 price,
        uint8 exType,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 timeHours
    );

    // remove market
    event RemoveMarket(address indexed from, uint256 tokenId);

    // nft exchange
    event Exchange(
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 price,
        uint256 fee,
        uint8 exType
    );

    // dragon breed count
    event BreedCount(address indexed from, uint256 tokenId, uint256 count);

    // breed count max
    event BreedCountMax(uint256 newCount, uint256 oldCount);

    // DMT token contract
    IDragonToken public dragonToken;

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
    }

    // nft tokenId => exchange data & price
    mapping(uint256 => ExchangeData) public exchangeDatas;
    // dragon breed count
    mapping(uint256 => uint256) public breedCounts;
    // dragon breed count max
    uint256 public breedCountMax = 7;

    function setBreedCountMax(uint256 _count) external onlyOwner {
        require(_count > 0, "invalid count");
        emit BreedCountMax(_count, breedCountMax);
        breedCountMax = _count;
    }

    modifier isExchange(uint256 _tokenId) {
        require(exchangeDatas[_tokenId].state, "invalid nft state");
        _;
    }

    constructor(address payable _dragon) {
        require(_dragon != address(0), "dragon address is zero");
        dragonToken = IDragonToken(_dragon);
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
        if (_exType == 2) {
            require(_minPrice > 0, "invalid minPrice");
            require(_maxPrice > _minPrice, "invalid maxPrice");
            require(_timeHours >= 24, "invalid timeHours");
        }

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
            _timeHours
        );
        emit AddMarket(
            msg.sender,
            _tokenId,
            _price,
            _exType,
            _minPrice,
            _maxPrice,
            _timeHours
        );
        return true;
    }

    // nft remove market
    function removeMarket(uint256 _tokenId)
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
        emit RemoveMarket(msg.sender, _tokenId);
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
            if (block.timestamp >= _exdata.create + _exdata.time_hours * 3600) {
                return (_exdata.min_price, 0);
            }
            uint256 _hour = (block.timestamp - _exdata.create) / 3600;
            uint256 _one = (_exdata.max_price - _exdata.min_price) /
                _exdata.time_hours;
            uint256 _price = _exdata.max_price - _one * _hour;
            return (_price, (block.timestamp - _exdata.create) % 3600);
        } else {
            return (0, 0);
        }
    }

    // nft exchange
    // transfer dms token
    function exchange(uint256 _tokenId, uint256 _price)
        external
        whenNotPaused
        nonReentrant
        isExchange(_tokenId)
        returns (bool)
    {
        ExchangeData storage _exdata = exchangeDatas[_tokenId];
        uint256 _balance = dmsToken.balanceOf(msg.sender);
        require(_balance >= _price, "DMS balance is not enough");

        uint8 _exType = _exdata.ex_type;
        require(_exType != 1 && _exType != 2, "invalid exchange type");
        if (_exType == 1) {
            require(_price >= _exdata.price, "invalid price");
        } else if (_exType == 2) {
            uint256 _currPrice;
            uint256 _currTime;
            (_currPrice, _currTime) = exchangePrice(_tokenId);
            require(_price >= _currPrice, "invalid price");
        }
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
            _exType
        );
        return true;
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
            breedCounts[_matronId] < breedCountMax,
            "matron breed count max"
        );
        require(breedCounts[_sireId] < breedCountMax, "sire breed count max");

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

        return true;
    }

    function _breedCounts(uint256 _matronId, uint256 _sireId) private {
        // dragon token breed count add
        breedCounts[_matronId] += 1;
        breedCounts[_sireId] += 1;
        uint256 _matronIdBreed = breedCounts[_matronId];
        uint256 _sireIdBreed = breedCounts[_sireId];
        emit BreedCount(msg.sender, _matronId, _matronIdBreed);
        emit BreedCount(msg.sender, _sireId, _sireIdBreed);

        // dms token
        dmsTransferEarn(
            msg.sender,
            breedDmsAmt[_matronIdBreed] + breedDmsAmt[_sireIdBreed]
        );
        dmpTransferEarn(
            msg.sender,
            breedDmpAmt[_matronIdBreed] + breedDmpAmt[_sireIdBreed]
        );
    }
}
