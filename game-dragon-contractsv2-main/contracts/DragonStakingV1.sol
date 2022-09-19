// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./Adminable.sol";

/**
 * dragon contract staking V1
 * earn DMP token
 * DMP token transfer or withdraw not in this contract
 */

// dragon mainland token interface
interface IDragonToken {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

abstract contract DragonStakingV1Base is Pausable, Ownable {
    // per block event
    event PerBlock(uint256 block);
    // per cycle event
    event PerCycle(uint256 cycle);
    // staking data event
    event StakeData(
        address indexed account,
        uint256 power,
        uint256 hashRate,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 amount
    );
    // stake earn event
    event StakedEarn(
        address indexed account,
        uint256 indexed tokenId,
        uint256 power,
        uint256 amount
    );

    // staking data
    struct StakingData {
        address account;
        uint256 power;
        uint256 hashRate;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
    }

    // per block 9 DMP token
    uint256 public perBlock = 9 ether;

    // base hashrate
    uint256 public baseHashRate = 331;

    // per cycle 3 hours
    uint256 public perCycle = 3 hours;

    // sign expiration time
    uint64 internal _expirationTime = 180;

    // dragon tokenId staking data
    mapping(uint256 => StakingData) public stakingDatas;

    // dragon tokenId staked state
    mapping(uint256 => bool) public stakedState;

    // dragon tokenId staked DMP earn total
    mapping(uint256 => uint256) public stakedDatas;

    // account staking tokenId list
    mapping(address => uint256[]) internal stakingTokenIds;

    // stake total
    // dragonTotal => 0x647261676f6e546f74616c
    // accountTotal => 0x6163636f756e74546f74616c
    // dmpTotal => 0x646d70546f74616c
    mapping(bytes => uint256) public stakeTotals;

    // set pre block
    function setPerBlock(uint256 _block) external onlyOwner {
        require(_block > 0, "invalid perblock");
        perBlock = _block;
        emit PerBlock(_block);
    }

    // set pre cycle
    function setPerCycle(uint256 _cycle) external onlyOwner {
        require(_cycle > 0, "invalid perCycle");
        perCycle = _cycle;
        emit PerCycle(_cycle);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

/// dragon mainland token ERC721 staking V1
contract DragonStakingV1 is
    Pausable,
    ERC721Holder,
    DragonStakingV1Base,
    Adminable
{
    using Strings for uint256;
    using ECDSA for bytes32;

    // dragon token
    IDragonToken public dragonToken;

    constructor(address _dragon, address admin_) {
        require(_dragon != address(0), "dragon address is zero");
        require(admin_ != address(0), "admin address is zero");
        dragonToken = IDragonToken(_dragon);
        _admin = admin_;
    }

    // hashRate calc
    function _hashRateCalc(uint256 _hashRate) private view returns (uint256) {
        return (perBlock * _hashRate) / baseHashRate;
    }

    // stake calc
    // returns (dmsAmt, power)
    function _stakeCalc(uint256 _tokenId, uint256 _hashRate)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _value = _hashRateCalc(_hashRate);
        StakingData memory _data = stakingDatas[_tokenId];
        uint256 endTime = block.timestamp > _data.endTime
            ? _data.endTime
            : block.timestamp;
        // floor cycle value (math.floor)
        uint256 _cycle = (endTime - _data.startTime) / perCycle;
        // ceil power value (math.ceil)
        uint256 _power = (endTime - _data.startTime + perCycle - 1) / perCycle;
        if (_cycle < 1) {
            return (0, 0, _cycle);
        }
        return (_cycle * _value, _data.power - _power, _cycle);
    }

    // stake dragon token
    // earn DMP token
    function stake(
        uint256[] calldata _tokenIds,
        uint256[] calldata _hashRates,
        uint256 _powers,
        uint64 _timestamp,
        bytes memory _sign
    ) external whenNotPaused returns (bool) {
        require(
            _tokenIds.length > 0 && _tokenIds.length == _hashRates.length,
            "invalid tokenIds or hashRates"
        );
        require(
            _timestamp + _expirationTime >= block.timestamp,
            "expiration time"
        );
        require(
            _powers > 0 && _powers % _tokenIds.length == 0,
            "invalid power"
        );

        uint256 _powerOne = _powers / _tokenIds.length;
        require(_powerOne <= 8, "invalid powerOne");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] > 0, "invalid tokenId");
            require(_hashRates[i] > 0, "invalid hashRate");
            require(!stakedState[_tokenIds[i]], "invalid stake state");
            require(
                dragonToken.ownerOf(_tokenIds[i]) == msg.sender,
                "invalid owner"
            );
        }

        // verify sign message
        string memory _message = _signStake(
            _tokenIds,
            _hashRates,
            _powers,
            _timestamp
        );
        _verifyAdmin(_message, _sign);

        if (stakingTokenIds[msg.sender].length == 0) {
            stakeTotals[bytes("accountTotal")] += 1;
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            dragonToken.safeTransferFrom(msg.sender, address(this), _tokenId);

            StakingData memory _data = StakingData({
                account: msg.sender,
                power: _powerOne,
                hashRate: _hashRates[i],
                tokenId: _tokenId,
                startTime: block.timestamp,
                endTime: block.timestamp + perCycle * _powerOne,
                amount: 0
            });
            stakingDatas[_tokenId] = _data;
            emit StakeData(
                _data.account,
                _data.power,
                _data.hashRate,
                _data.tokenId,
                _data.startTime,
                _data.endTime,
                _data.amount
            );

            if (stakingTokenIds[msg.sender].length == 0) {
                stakingTokenIds[msg.sender] = [_tokenId];
            } else {
                stakingTokenIds[msg.sender].push(_tokenId);
            }
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
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(_tokenId > 0, "invalid tokenId");
            StakingData storage _data = stakingDatas[_tokenId];
            require(_data.account == msg.sender, "invalid account");
            require(stakedState[_tokenId], "invalid stake state");
            uint256 _currHashRate = _data.hashRate;

            // dragon to account
            dragonToken.safeTransferFrom(
                address(this),
                _data.account,
                _tokenId
            );

            // earn log
            uint256 _dmpAmt;
            uint256 _power;
            uint256 _cycle;
            (_dmpAmt, _power, _cycle) = _stakeCalc(_tokenId, _currHashRate);
            stakeTotals[bytes("dmpTotal")] += _dmpAmt;
            stakedDatas[_tokenId] += _dmpAmt;
            _data.amount += _dmpAmt;
            _data.power = _power;
            emit StakedEarn(msg.sender, _tokenId, _power, _dmpAmt);

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
        }

        return true;
    }

    // dragon stake earn DMP token
    function stakeEarn(uint256[] calldata _tokenIds)
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
            uint256 _currHashRate = _data.hashRate;

            // earn log
            uint256 _dmpAmt;
            uint256 _power;
            uint256 _cycle;
            (_dmpAmt, _power, _cycle) = _stakeCalc(_tokenId, _currHashRate);
            require(_cycle > 0, "time is too short");
            stakeTotals[bytes("dmpTotal")] += _dmpAmt;
            stakedDatas[_tokenId] += _dmpAmt;
            _data.startTime += perCycle * _cycle;
            _data.amount += _dmpAmt;
            _data.power -= _cycle;
            emit StakedEarn(msg.sender, _tokenId, 0, _dmpAmt);
        }

        return true;
    }

    // dragon stake power earn DMP token
    function stakePower(
        uint256[] calldata _tokenIds,
        uint256 _powers,
        uint64 _timestamp,
        bytes memory _sign
    ) external whenNotPaused returns (bool) {
        require(
            _timestamp + _expirationTime >= block.timestamp,
            "expiration time"
        );
        require(_tokenIds.length > 0, "invalid tokenIds");
        require(
            _powers > 0 && _powers % _tokenIds.length == 0,
            "invalid power"
        );
        uint256 _powerOne = _powers / _tokenIds.length;
        require(_powerOne <= 8, "invalid powerOne");

        uint256[] memory _hashRates = new uint256[](_tokenIds.length);

        // verify sign message
        string memory _message = _signStake(
            _tokenIds,
            _hashRates,
            _powers,
            _timestamp
        );
        _verifyAdmin(_message, _sign);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(_tokenId > 0, "invalid tokenId");
            StakingData storage _data = stakingDatas[_tokenId];
            require(_data.account == msg.sender, "invalid account");
            require(stakedState[_tokenId], "invalid stake state");
            require(
                block.timestamp >= _data.endTime,
                "stake was not completed"
            );
            uint256 _currHashRate = _data.hashRate;

            // earn log
            uint256 _dmpAmt;
            uint256 _power;
            uint256 _cycle;
            (_dmpAmt, _power, _cycle) = _stakeCalc(_tokenId, _currHashRate);
            stakeTotals[bytes("dmpTotal")] += _dmpAmt;
            stakedDatas[_tokenId] += _dmpAmt;
            _data.startTime = block.timestamp;
            _data.amount += _dmpAmt;
            _data.power = _power;
            emit StakedEarn(msg.sender, _tokenId, 0, _dmpAmt);

            // add power & endTime
            _data.endTime = block.timestamp + perCycle * _powerOne;
            _data.power += _powerOne;
        }

        return true;
    }

    // account earn DMP token total
    function accountTotal(address _account) external view returns (uint256) {
        require(_account != address(0), "invalid account address");
        uint256[] memory _tokenIds = stakingTokenIds[_account];
        uint256 _total;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            _total += stakedDatas[_tokenId];
        }
        return _total;
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

    // verify admin
    function _verifyAdmin(string memory data, bytes memory _sign) private view {
        bytes32 message = keccak256(abi.encodePacked(data));
        bytes32 ethSignedHash = message.toEthSignedMessageHash();
        require(ethSignedHash.recover(_sign) == admin(), "sign message fault");
    }

    // sign stake data
    function _signStake(
        uint256[] calldata _tokenIds,
        uint256[] memory _hashRates,
        uint256 _powers,
        uint64 _timestamp
    ) private pure returns (string memory) {
        bytes memory message = bytes(_powers.toString());
        message = abi.encodePacked(message, uint256(_timestamp).toString());
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            message = abi.encodePacked(
                message,
                _tokenIds[i].toString(),
                _hashRates[i].toString()
            );
        }
        return string(message);
    }
}
