// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ERC1155 energy stone
// Low  1
// medium 5
// high 10
contract EnergyStone is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Burn Pool Account event
    event BurnPoolAccount(address newBurnAddr, address newPoolAddr);
    // stone price event
    event StonePrices(uint256[3] prices);
    // burn perc event
    event BurnPerc(uint256 perc);
    // buy stone event
    event BuyEnergy(
        address indexed account,
        uint256 level,
        uint256 energyValue,
        uint256 amount,
        uint256 totalFees
    );
    event AddEnergy(address owner, uint256 value);
    event ReduceEnergy(address owner, uint256 value);

    // todo stone price
    uint256[3] public stonePrices = [1 ether, 5 ether, 10 ether];
    // todo stone energy
    uint256[3] public stoneEnergy = [100, 500, 1000];
    // todo dms token
    IERC20 public dmsToken = IERC20(0x70E76c217AF66b6893637FABC1cb2EbEd254C90c);

    // todo burnAccount address
    address public burnAccount =
        address(0x39838C3866968B9DAd5E1aFAec59304ffCE9f843);
    address public poolAccount =
        address(0x7A072661bF3F64e8050A9Ad98B9c6E4c02feD5d2);

    // burn 50%
    uint256 public burnPerc = 50;
    // energyTotals
    mapping(address => uint256) public energyTotals;
    // energyTotals
    mapping(address => mapping(uint256 => uint256)) public energyAmounts;

    constructor(address[] memory owners, address[] memory operators) {
        require(owners.length > 0, "invalid owners");
        require(operators.length > 0, "invalid operators");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < owners.length; i++) {
            _setupRole(OWNER_ROLE, owners[i]);
        }
        for (uint256 i = 0; i < operators.length; i++) {
            _setupRole(OPERATOR_ROLE, operators[i]);
        }
    }

    modifier checkAddr(address _address) {
        require(_address != address(0), "address is zero");
        _;
    }

    function getEnergyTotal(address account) external view returns (uint256) {
        return energyTotals[account];
    }

    function getAmountTotal(address account, uint256 level)
        external
        view
        returns (uint256)
    {
        return energyAmounts[account][level];
    }

    // set account address
    function setAccount(address _burn, address _pool)
        external
        onlyRole(OWNER_ROLE)
        checkAddr(_burn)
        checkAddr(_pool)
    {
        emit BurnPoolAccount(_burn, _pool);
        burnAccount = _burn;
        poolAccount = _pool;
    }

    // set stone prices
    function setStonePrices(uint256[3] calldata _prices)
        external
        onlyRole(OWNER_ROLE)
    {
        for (uint256 i = 0; i < _prices.length; i++) {
            require(_prices[i] > 0, "invalid price");
            stonePrices[i] = _prices[i];
        }
        emit StonePrices(_prices);
    }

    // set stone energys
    function setStoneEnergy(uint256[3] calldata _energy)
        external
        onlyRole(OWNER_ROLE)
    {
        for (uint256 i = 0; i < _energy.length; i++) {
            require(_energy[i] > 0, "invalid energy");
            stoneEnergy[i] = _energy[i];
        }
        emit StonePrices(_energy);
    }

    // update burn percentage default = 50%
    function setBurnPerc(uint256 _perc) external onlyRole(OWNER_ROLE) {
        require(_perc > 0 && _perc <= 100, "invalid BurnPerc");
        burnPerc = _perc;
        emit BurnPerc(_perc);
    }

    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }

    function buyEnergy(uint256 _level, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(_level == 1 || _level == 5 || _level == 10, "invalid level");
        require(_amount > 0, "invalid amount");
        uint256 _index;
        if (_level == 1) {
            _index = 0;
        } else if (_level == 5) {
            _index = 1;
        } else if (_level == 10) {
            _index = 2;
        }
        uint256 _totalPrice = stonePrices[_index] * _amount;
        require(
            dmsToken.balanceOf(msg.sender) >= _totalPrice,
            "DMS balance insufficient"
        );

        uint256 _total = _amount * stoneEnergy[_index];
        energyTotals[msg.sender] += _total;

        if (burnPerc < 100) {
            uint256 _dmsBurn = (_totalPrice * burnPerc) / 100;
            dmsToken.transferFrom(msg.sender, burnAccount, _dmsBurn);
            dmsToken.transferFrom(
                msg.sender,
                poolAccount,
                _totalPrice - _dmsBurn
            );
        } else if (burnPerc == 100) {
            dmsToken.transferFrom(msg.sender, burnAccount, _totalPrice);
        }

        energyAmounts[msg.sender][_level] += _amount;

        emit BuyEnergy(
            msg.sender,
            _level,
            stoneEnergy[_index],
            _amount,
            _totalPrice
        );
        return true;
    }

    function addEnergy(address _owner, uint256 _value)
        external
        whenNotPaused
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        energyTotals[_owner] += _value;
        emit AddEnergy(_owner, _value);
        return true;
    }

    function reduceEnergy(address _owner, uint256 _value)
        external
        whenNotPaused
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        require(energyTotals[_owner] >= _value, "energy insufficient");
        energyTotals[_owner] -= _value;
        emit ReduceEnergy(_owner, _value);
        return true;
    }
}
