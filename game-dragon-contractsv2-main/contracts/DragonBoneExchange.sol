// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./DragonTransfer.sol";

contract DragonBoneExchange is
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC1155Holder,
    DragonTransfer
{
    // bone add market
    event AddMarket(
        address indexed from,
        uint256 tokenId,
        uint256 price,
        uint256 amount,
        uint8 exType,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 timeHours,
        uint256 createTime,
        uint256 orderId
    );

    // bone remove Market
    event RemoveMarket(
        address indexed from,
        uint256 orderId,
        uint256 tokenId,
        uint256 amount
    );

    // bone exchange
    event Exchange(
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 price,
        uint256 amount,
        uint256 fee,
        uint8 exType,
        uint256 orderId
    );

    struct ExchangeData {
        uint256 tokenId;
        address from;
        address to;
        uint256 price; // price
        uint256 amount; // amount
        uint256 amountLimit; // amount limit
        uint256 create;
        uint8 ex_type; // 1=exchange 2=auction
        bool state; // order state
        uint256 min_price;
        uint256 max_price;
        uint256 time_hours;
    }

    struct OrderData {
        uint256 orderId;
        uint256 tokenId;
        uint256 price;
        uint256 amount;
    }

    struct OrderType {
        uint8 exType;
        uint256 minPrice;
        uint256 maxPrice;
        uint256 timeHours;
    }

    // orderId => exchange data & price
    mapping(uint256 => ExchangeData) public exchangeDatas;
    // hour cycle
    uint256 public constant CYCLE = 3600;
    // prev orderId
    uint256 public prevOrderId = 0;

    modifier isOrderExchange(uint256 _orderId) {
        require(exchangeDatas[_orderId].state, "invalid order state");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // add bone market
    function addMarket(OrderData memory _data, OrderType memory _type)
        external
        whenNotPaused
        nonReentrant
    {
        require(
            dmbToken.balanceOf(msg.sender, _data.tokenId) >= _data.amount,
            "dragon bone balance not enough"
        );
        require(_type.exType == 1 || _type.exType == 2, "invalid exType");
        if (_type.exType == 2) {
            require(_type.minPrice > 0, "invalid minPrice");
            require(_type.maxPrice > _type.minPrice, "invalid maxPrice");
            require(_type.timeHours >= 24, "invalid timeHours");
        }
        dmbToken.safeTransferFrom(
            msg.sender,
            address(this),
            _data.tokenId,
            _data.amount,
            "0x"
        );

        require(
            !exchangeDatas[_data.orderId].state && _data.orderId > prevOrderId,
            "orderId is exist"
        );
        prevOrderId = _data.orderId;

        exchangeDatas[_data.orderId] = ExchangeData(
            _data.tokenId,
            msg.sender,
            address(0),
            _data.price,
            _data.amount,
            _data.amount,
            block.timestamp,
            _type.exType,
            true,
            _type.minPrice,
            _type.maxPrice,
            _type.timeHours
        );

        emit AddMarket(
            msg.sender,
            _data.tokenId,
            _data.price,
            _data.amount,
            _type.exType,
            _type.minPrice,
            _type.maxPrice,
            _type.timeHours,
            block.timestamp,
            _data.orderId
        );
    }

    // remove bone market
    function removeMarket(uint256 _orderId)
        external
        whenNotPaused
        nonReentrant
        isOrderExchange(_orderId)
        returns (bool)
    {
        require(
            exchangeDatas[_orderId].from == msg.sender,
            "invalid dragon bone owner"
        );
        ExchangeData storage _exdata = exchangeDatas[_orderId];
        _exdata.state = false;
        uint256 _tokenId = _exdata.tokenId;
        uint256 _amount = _exdata.amount;
        dmbToken.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            "0x"
        );

        emit RemoveMarket(msg.sender, _orderId, _tokenId, _amount);
        return true;
    }

    // dragon bone exchange
    // transfer dms token
    function exchange(uint256 _orderId, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        ExchangeData storage _exdata = exchangeDatas[_orderId];
        require(_exdata.state, "order not in market");
        require(_exdata.amount >= _amount, "stock not enough");
        require(_exdata.state, "invalid order state");
        (uint256 _currPrice, ) = exchangePrice(_orderId);
        uint256 _totalPrice = _currPrice * _amount;
        require(
            dmsToken.balanceOf(msg.sender) >= _totalPrice && _totalPrice > 0,
            "DMS balance is not enough"
        );
        uint256 _fee = exchangeFee(_totalPrice);
        _exdata.amount -= _amount;
        _exdata.to = msg.sender;
        // DMS token
        dmsTransferEarn(msg.sender, _fee);
        dmsTransferFrom(msg.sender, _exdata.from, _totalPrice - _fee);
        // dragon bone transfer
        uint256 _tokenId = _exdata.tokenId;
        dmbToken.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            "0x"
        );
        if (_exdata.amount == 0) {
            _exdata.state = false;
            emit RemoveMarket(msg.sender, _orderId, _tokenId, 0);
        }
        emit Exchange(
            msg.sender,
            _exdata.from,
            _tokenId,
            _currPrice,
            _amount,
            _fee,
            _exdata.ex_type,
            _orderId
        );
        return true;
    }

    // current exchange Bone price
    function exchangePrice(uint256 _orderId)
        public
        view
        returns (uint256, uint256)
    {
        ExchangeData memory _exdata = exchangeDatas[_orderId];
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
}
