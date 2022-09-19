// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// DMT interface
interface IDragonToken {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

abstract contract DragonStakingV2Base is Pausable, Ownable {
    // <Energy Stone>
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
    event ReduceAccEnergy(address indexed owner, uint256 value);

    // pool event
    event SetPool(uint256 id, uint256 energy, uint256 earnDmp);

    // <Staking>
    //
    //
    // staking data event
    event Stake(
        address indexed account,
        uint256 indexed tokenId,
        uint256 poolId,
        uint256 energy,
        uint256 hashRate,
        uint256 sumProb,
        uint256 startTime,
        uint256 endTime
    );
    // stake earn event
    event TakeBenefit(
        address indexed account,
        uint256 indexed tokenId,
        uint256 amountDmp,
        uint256 amountDms,
        uint256 takeTime
    );
    event UnStake(
        address indexed account,
        uint256 indexed tokenId,
        uint256 amountDmp,
        uint256 amountDms,
        uint256 refund,
        uint8 state
    );
    event RefundTotal(address indexed account, uint256 value);

    event AddEnergy(
        address indexed account,
        uint256 indexed tokenId,
        uint256 hour,
        uint256 enengy,
        uint256 startTime,
        uint256 endTime,
        uint8 state
    );

    // pool
    struct Pool {
        // every hour
        uint256 energy;
        uint256 earnDmp;
        // uint256 earnDms;
    }
    // staking data
    struct StakingData {
        address account;
        uint256 poolId; // uint256 variety; //dragon variety
        uint256 energy;
        uint256 hashRate;
        uint256 sumProb;
        uint256 startTime;
        uint256 endTime;
        uint256 amountDmp;
        uint256 amountDms;
    }
    // stake para
    struct StakePara {
        uint256 poolId;
        uint256 hour;
        uint256 timestamp;
        bytes sign;
    }

    //Energy stone
    //
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
    // energy amounts
    mapping(address => mapping(uint256 => uint256)) public energyAmounts;

    // mine pool
    // poolId => pool
    // poolId 1,2,3
    mapping(uint256 => Pool) pools;

    // sign expiration time
    uint64 internal _expirationTime = 180;
    // 1 - 10000(100%)
    uint256 internal probBase = 10000;
    // per block
    uint256 internal perBlock = 1 hours;
    // dms base amount
    uint256 public dmsBase = 1 ether;

    // todo DMT token
    IDragonToken dragonToken =
        IDragonToken(0x0970A6E0676296C456bA6e6D789ec4fb2794d740);
    // todo sign account
    address public signAcc =
        address(0x0970A6E0676296C456bA6e6D789ec4fb2794d740);

    // dragon tokenId staking data
    mapping(uint256 => StakingData) public stakingDatas;
    // dragon tokenId staked state
    mapping(uint256 => bool) public stakedState;
    // account staking tokenId list
    mapping(address => uint256[]) internal stakingTokenIds;
    // account staked and staking tokenId list
    mapping(address => uint256[]) internal stakeTokenIds;
    // stake totals
    mapping(bytes => uint256) public stakeTotals;
    // dragon tokenId staked DMP earn total
    mapping(uint256 => uint256) public earnDmps;
    // dragon tokenId staked DMS earn total
    mapping(uint256 => uint256) public earnDmss;

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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
    function setAccount(address _burn, address _pool) external onlyOwner {
        emit BurnPoolAccount(_burn, _pool);
        burnAccount = _burn;
        poolAccount = _pool;
    }

    // set stone prices
    function setStonePrices(uint256[3] calldata _prices) external onlyOwner {
        for (uint256 i = 0; i < _prices.length; i++) {
            require(_prices[i] > 0, "invalid price");
            stonePrices[i] = _prices[i];
        }
        emit StonePrices(_prices);
    }

    // set stone energys
    // default 100 500 1000
    function setStoneEnergy(uint256[3] calldata _energy) external onlyOwner {
        for (uint256 i = 0; i < _energy.length; i++) {
            require(_energy[i] > 0, "invalid energy");
            stoneEnergy[i] = _energy[i];
        }
        emit StonePrices(_energy);
    }

    // update burn percentage default = 50%
    function setBurnPerc(uint256 _perc) external onlyOwner {
        require(_perc > 0 && _perc <= 100, "invalid BurnPerc");
        burnPerc = _perc;
        emit BurnPerc(_perc);
    }

    // set Pool (per block)
    function setPool(
        uint256 _id,
        uint256 _energy,
        uint256 _earnDmp
    ) public onlyOwner returns (bool) {
        Pool storage p = pools[_id];
        p.energy = _energy;
        p.earnDmp = _earnDmp;
        emit SetPool(_id, _energy, _earnDmp);
        return true;
    }
}

contract DragonStakingV2 is
    Pausable,
    ReentrancyGuard,
    ERC721Holder,
    DragonStakingV2Base
{
    using Strings for uint256;
    using ECDSA for bytes32;

    constructor() {
        // Common mining area
        setPool(1, 10, 0.009060054 ether);
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

    // stake dragon
    // _sumProbs (DMS probability per hour)
    function stake(
        uint256[] calldata _tokenIds,
        uint256[] calldata _hashRates,
        uint256[] calldata _varietys,
        uint256[] calldata _sumProbs,
        StakePara memory _sp
    ) external whenNotPaused returns (bool) {
        require(
            _tokenIds.length > 0 &&
                _tokenIds.length == _hashRates.length &&
                _tokenIds.length == _varietys.length &&
                _tokenIds.length == _sumProbs.length,
            "invalid tokenIds or hashRates"
        );
        require(
            _sp.timestamp + _expirationTime >= block.timestamp,
            "expiration time"
        );

        require(_sp.hour > 0, "invalid  hour");
        require(pools[_sp.poolId].energy > 0, "invalid energy points");

        // verify pool
        require(
            _verifyPool(_tokenIds, _hashRates, _varietys, _sp.poolId),
            "verify pool failure"
        );

        // verify sign message
        _verify(
            _signStake(
                _tokenIds,
                _hashRates,
                _varietys,
                _sumProbs,
                _sp.timestamp
            ),
            _sp.sign
        );

        // calculate spend total energy
        uint256 _energy = _sp.hour * pools[_sp.poolId].energy;
        uint256 _totalEnergy = _energy * _tokenIds.length;

        require(
            energyTotals[msg.sender] >= _totalEnergy,
            "energy insufficient"
        );
        energyTotals[msg.sender] -= _totalEnergy;

        if (stakingTokenIds[msg.sender].length == 0) {
            stakeTotals[bytes("accountTotal")] += 1;
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            dragonToken.safeTransferFrom(msg.sender, address(this), _tokenId);

            StakingData memory _data = StakingData({
                account: msg.sender,
                poolId: _sp.poolId,
                energy: _energy,
                hashRate: _hashRates[i],
                sumProb: _sumProbs[i],
                startTime: block.timestamp,
                endTime: block.timestamp + _sp.hour * 1 hours,
                amountDmp: 0,
                amountDms: 0
            });
            stakingDatas[_tokenId] = _data;
            emit Stake(
                _data.account,
                _tokenId,
                _data.poolId,
                _energy,
                _data.hashRate,
                _data.sumProb,
                _data.startTime,
                _data.endTime
            );

            //stakingTokenIds
            stakingTokenIds[msg.sender].push(_tokenId);

            //stakeTokenIds
            uint8 _state = 0;
            for (uint256 j = 0; j < stakeTokenIds[msg.sender].length; j++) {
                if (stakeTokenIds[msg.sender][j] == _tokenId) _state = 1;
            }
            if (_state == 0) stakeTokenIds[msg.sender].push(_tokenId);

            if (!stakedState[_tokenId]) {
                stakeTotals[bytes("dragonTotal")] += 1;
                stakedState[_tokenId] = true;
            }
        }
        return true;
    }

    // cancel stake dragon
    function unStake(uint256[] calldata _tokenIds)
        external
        whenNotPaused
        returns (bool)
    {
        require(_tokenIds.length > 0, "invalid tokenIds");
        uint256 _totalRemain = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(_tokenId > 0, "invalid tokenId");
            StakingData storage _data = stakingDatas[_tokenId];
            require(_data.account == msg.sender, "invalid account");
            require(stakedState[_tokenId], "invalid stake state");

            // dragon to account
            dragonToken.safeTransferFrom(
                address(this),
                _data.account,
                _tokenId
            );

            (uint256 _dmpAmt, uint256 _dmsAmt, uint256 _remainC, ) = _stakeCalc(
                _tokenId
            );

            stakeTotals[bytes("dmpTotal")] += _dmpAmt;
            stakeTotals[bytes("dmsTotal")] += _dmsAmt;
            earnDmps[_tokenId] += _dmpAmt;
            earnDmss[_tokenId] += _dmsAmt;
            _data.amountDmp += _dmpAmt;
            _data.amountDms += _dmsAmt;

            // calc refund energy
            uint256 _remain = _remainC * pools[_data.poolId].energy;
            _totalRemain += _remain;
            // _state = 0 (midway leave) _state = 1 (complete the expected)
            uint8 _state = block.timestamp >= _data.endTime ? 1 : 0;
            emit UnStake(
                msg.sender,
                _tokenId,
                _dmpAmt,
                _dmsAmt,
                _remain,
                _state
            );

            // delete tokenId
            uint256 _len = stakingTokenIds[msg.sender].length;
            for (uint256 j = 0; j < _len; j++) {
                if (stakingTokenIds[msg.sender][j] == _tokenId) {
                    stakingTokenIds[msg.sender][j] = stakingTokenIds[
                        msg.sender
                    ][_len - 1];
                    stakingTokenIds[msg.sender].pop();
                    break;
                }
            }

            // account total
            if (stakingTokenIds[msg.sender].length == 0) {
                stakeTotals[bytes("accountTotal")] -= 1;
            }

            // staked state
            if (stakedState[_tokenId]) {
                stakeTotals[bytes("dragonTotal")] -= 1;
                stakedState[_tokenId] = false;
            }

            // dragon data reset
            _data.startTime = 0;
            _data.endTime = 0;
            _data.energy = 0;
        }
        //  refund total energy
        energyTotals[msg.sender] += _totalRemain;
        emit RefundTotal(msg.sender, _totalRemain);

        return true;
    }

    // dragon stake earn DMP token
    function takeBenefit(uint256[] calldata _tokenIds)
        external
        whenNotPaused
        returns (bool)
    {
        require(_tokenIds.length > 0, "invalid tokenIds");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(_tokenId > 0, "invalid tokenId");
            StakingData storage _data = stakingDatas[_tokenId];
            require(_data.account == msg.sender, "invalid account");
            require(stakedState[_tokenId], "invalid stake state");

            (
                uint256 _dmpAmt,
                uint256 _dmsAmt,
                ,
                uint256 _actCycles
            ) = _stakeCalc(_tokenId);
            require(_actCycles > 0, "time is too short");
            stakeTotals[bytes("dmpTotal")] += _dmpAmt;
            stakeTotals[bytes("dmsTotal")] += _dmsAmt;
            earnDmps[_tokenId] += _dmpAmt;
            earnDmss[_tokenId] += _dmsAmt;
            _data.amountDmp += _dmpAmt;
            _data.amountDms += _dmsAmt;

            _data.startTime += _actCycles * perBlock;
            _data.energy -= _actCycles * pools[_data.poolId].energy;

            emit TakeBenefit(
                msg.sender,
                _tokenId,
                _dmpAmt,
                _dmsAmt,
                block.timestamp
            );
        }

        return true;
    }

    // add energy
    // burn energy stone
    function addEnergy(uint256[] calldata _tokenIds, uint256 _hour)
        external
        whenNotPaused
        returns (bool)
    {
        require(_tokenIds.length > 0, "invalid tokenIds");
        uint256 _energyNeed = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(_tokenId > 0, "invalid tokenId");
            StakingData storage _data = stakingDatas[_tokenId];
            require(_data.account == msg.sender, "invalid account");
            require(stakedState[_tokenId], "invalid stake state");
            // calc need energy
            uint256 _energy = _hour *
                pools[stakingDatas[_tokenId].poolId].energy;
            _energyNeed += _energy;

            // _state = 0 stake was not completed
            // _state = 1  stake has been completed
            uint8 _state = block.timestamp < _data.endTime ? 0 : 1;
            if (_state == 0) {
                _data.endTime += _hour * perBlock;
                _data.energy += _energy;
            } else {
                (uint256 _dmpAmt, uint256 _dmsAmt, , ) = _stakeCalc(_tokenId);
                stakeTotals[bytes("dmpTotal")] += _dmpAmt;
                stakeTotals[bytes("dmsTotal")] += _dmsAmt;
                earnDmps[_tokenId] += _dmpAmt;
                earnDmss[_tokenId] += _dmsAmt;

                _data.amountDmp += _dmpAmt;
                _data.amountDms += _dmsAmt;
                _data.startTime = block.timestamp;
                _data.endTime = block.timestamp + _hour * perBlock;
                _data.energy = _energy;

                emit TakeBenefit(
                    msg.sender,
                    _tokenId,
                    _dmpAmt,
                    _dmsAmt,
                    block.timestamp
                );
            }
            emit AddEnergy(
                msg.sender,
                _tokenId,
                _hour,
                _energy,
                _data.startTime,
                _data.endTime,
                _state
            );
        }
        require(
            _energyNeed <= energyTotals[msg.sender],
            "Please buy energy, energyTotals insufficient"
        );
        energyTotals[msg.sender] -= _energyNeed;
        //emit reduceEnergy
        emit ReduceAccEnergy(msg.sender, _energyNeed);
        return true;
    }

    // verify pool
    function _verifyPool(
        uint256[] calldata _tokenIds,
        uint256[] calldata _hashRates,
        uint256[] calldata _varietys,
        uint256 _poolId
    ) private view returns (bool) {
        require(_poolId >= 1 && _poolId <= 3, "invalid poolId");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] > 0, "invalid tokenId");
            require(_hashRates[i] > 0, "invalid hashRate");
            require(!stakedState[_tokenIds[i]], "invalid stake state");
            require(
                dragonToken.ownerOf(_tokenIds[i]) == msg.sender,
                "invalid owner"
            );
            if (_poolId == 2) {
                // only genesis dragon
                require(_tokenIds[i] <= 10000, "only genesis dragon can join");
            } else if (_poolId == 3) {
                // only Rare and mysterious dragon
                // Rare 1  mysterious 2
                require(
                    _varietys[i] == 1 || _varietys[i] == 2,
                    "only rare or mysterious dragons can join"
                );
            }
        }
        return true;
    }

    // verify
    function _verify(string memory data, bytes memory _sign) private view {
        bytes32 message = keccak256(abi.encodePacked(data));
        bytes32 ethSignedHash = message.toEthSignedMessageHash();
        require(ethSignedHash.recover(_sign) == signAcc, "sign message fault");
    }

    // sign stake data
    function _signStake(
        uint256[] calldata _tokenIds,
        uint256[] memory _hashRates,
        uint256[] memory _varietys,
        uint256[] memory _sumProbs,
        uint256 _timestamp
    ) private pure returns (string memory) {
        bytes memory message = abi.encodePacked(_timestamp.toString());
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            message = abi.encodePacked(
                message,
                _tokenIds[i].toString(),
                _hashRates[i].toString(),
                _varietys[i].toString(),
                _sumProbs[i].toString()
            );
        }
        return string(message);
    }

    function _stakeCalc(uint256 _tokenId)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        StakingData memory _data = stakingDatas[_tokenId];
        uint256 endTime = block.timestamp > _data.endTime
            ? _data.endTime
            : block.timestamp;

        // actual Cycles _actCycles
        uint256 _actCycles = (endTime - _data.startTime) / perBlock;
        uint256 _dmpAmt = _actCycles *
            _data.hashRate *
            pools[_data.poolId].earnDmp;

        // calc dms
        uint256 _dmsAmt = 0;
        for (uint256 i = 0; i < _actCycles; i++) {
            if (_random(i) <= _data.sumProb) {
                _dmsAmt += dmsBase;
            }
        }

        uint256 _remainCycles = (_data.endTime - endTime) / perBlock;

        return (_dmpAmt, _dmsAmt, _remainCycles, _actCycles);
    }

    // account staking tokenIds
    function getStakingTokenIds(address _account)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokenIds = stakingTokenIds[_account];
        return _tokenIds;
    }

    // account earn DMP,DMS token total
    function accountTotal(address _account)
        external
        view
        returns (uint256, uint256)
    {
        require(_account != address(0), "invalid account address");
        uint256[] memory _tokenIds = stakeTokenIds[_account];
        uint256 _totalDmp;
        uint256 _totalDms;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            _totalDmp += earnDmps[_tokenId];
            _totalDms += earnDmss[_tokenId];
        }
        return (_totalDmp, _totalDms);
    }

    // random
    function _random(uint256 _seed) private view returns (uint256) {
        bytes32 _rand = keccak256(
            abi.encodePacked(
                _seed +
                    block.timestamp +
                    uint256(keccak256(abi.encodePacked(block.coinbase))) /
                    block.timestamp +
                    uint256(keccak256(abi.encodePacked(msg.sender))) /
                    block.timestamp +
                    block.number
            )
        );
        uint256 _result = (uint256(_rand) % probBase) + 1;
        return _result;
    }
}
