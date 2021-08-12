//"SPDX-License-Identifier: MIT"
pragma solidity >=0.8.4;


import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/ReentrancyGuard.sol";


contract Staking is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN = keccak256("ADMIN");

    // Staker contain info for each staker
    struct Staker {
        uint256 amount; // amount of tokens currently staked to contract
        uint256 rewardAllowed; // amount of tokens
        uint256 rewardDebt; // value needed for correct calculation of staker's share 
        uint256 unstakeAmount; // amount of tokens that will be able to withdraw
        uint256 ustakeTime; // time when tokens are available to withdraw
    }
    
    // StakeInfo contain information for stake
    struct StakeInfo {
        uint256 _startTime; // time of staking start
        uint256 _endTime; // time of staking end
        uint256 _distributionTime;
        uint256 _unlockClaimTime;
        uint256 _unstakeLockTime;
        uint256 _rewardTotal;
        uint256 _totalStaked;
        uint256 _totalDistributed;
    }

    uint256 public totalDistributed;

    uint256 public minStakingAmount;
    uint256 public maxStakingAmount;

    event tokensStaked(uint256 amount, uint256 time, address indexed sender);
    event tokensClaimed(uint256 amount, uint256 time, address indexed sender);
    event tokensUnstaked(uint256 amount, uint256 time, address indexed sender);

    constructor(
        uint256 _rewardTotal,
        uint256 _startTime,
        uint256 _distributionTime,
        uint256 _unlockClaimTime,
        uint256 _unstakeLockTime
    ) public {
        // Give role of admin to contract deployer
        _setupRole(ADMIN, msg.sender);

        rewardTotal = _rewardTotal;
        startTime = _startTime;
        endTime = _endTime;
        distributionTime = _distributionTime;
        unlockClaimTime = _unlockClaimTime;
        unstakeLockTime = _unstakeLockTime;

        producedTime = _startTime;
    }

    function initialize(address _rewardToken, address _stakingToken) public {
        require(
            hasRole(ADMIN, msg.sender), 
            "Staking:: caller is not an admin"
        );

        require(
            address(stakingToken) == address(0) && 
                address(rewardToken) == address(0),
            "Staking:: contract already initialized"
        );
        rewardToken = ERC20(_rewardToken);
        stakingToken = ERC20(_stakingToken);
    } 

    function stake(uint256 _amount) public {
        require(
            block.timestamp > startTime,
            "stake:: staking time is not come"
        );
        Staker storage staker = _stakers[msg.sender];

        // Transfer specified amount of staking tokens to the contract 
        IERC20(stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (totalStaked > 0) {
            update();
        }
        staker.rewardDebt = staker.rewardDebt.add(
            _amount.mul(tokensPerStake).div(1e20)
        );

        totalStaked = totalStaked.add(_amount);
        staker.amount = staker.amount.add(_amount);

        update();

        emit tokensStaked(_amount, block.timestamp, msg.sender);
    }

    function unstake(uint256 _amount) public nonReentrant {
        Staker storage staker = _stakers[msg.sender];

        require(
            staker.amount > _amount,
            "Staking:: not enough tokens to unstake"  
        );

        update();

        staker.rewardAllowed = staker.rewardAllowed.add(
            _amount.mul(tokensPerStake).div(1e20)
        );
        staker.amount = staker.amount.sub(_amount);
        totalStaked = totalStaked.sub(_amount);

        IERC20(stakingToken).safeTransfer(msg.sender, _amount);

        emit TokensUnstaked(_amount, block.timestamp, msg.sender);
    }

    function claim() public nonReentrant returns (bool) {
        require(
            block.timestamp > unlockClaimTime,
            "claim:: Claiming is locked"
        );
        if (totalStaked > 0) {
            update();
        }
    }



    function getClaim(address _staker) public view return (uint reward) {
        /*
         *
         */
        uint256 _tps = TokensPerStake;
        if (totalStaked > 0) {
            uint256 rewardProducedAtNow = produced();
            if (rewardProducedAtNow > rewardProduced) {
                uint256 producedNew = rewardProducedAtNow.sub(rewardProduced);
                _tps = _tps.add(producedNew.mul(1e20).div(totalStaked));
            }
        } 
        reward = calcReward(_staker, _tps);

        return reward;
    }



    function setReward{uin256 _amount} public {
        require(hasRole(ADMIN_ROLE, msg.sender));
        allProduced = produced();
        producedTime = block.timestamp;
        rewardTotal = _amount;
    }

    function staked() public view returns (uint256) {
        return totalStaked;
    }

    function distributed() public view returns (uint256) {
        return totalDistributed;
    }

    function getInfoByAddress(address _address)
        external 
        view
        returns (
            uint256 staked_,
            uint256 claim_,
            uint256 unstakeAmount_, 
            uint256 unstakeTime_
        )
    {
        Staker storage staker = _stakers[_address];
        staked_ = staker.amount;
        unstakeAmount_ = staker.unstakeAmount;
        unstakeTime_ = staker.unstakeTime_;

        claim_ = getClaim(_address);

        return(staked_, claim_, unstakeAmount_, unstakeTime_)
    }

    function getStakingInfo() 
        extarnal
        view
        returns (
            StakeInfo memory info_
        )
    {
        info_ = StakeInfo({
            _startTime: startTime, 
            _endTime: endTime,
            _distributionTime: distirbutionTime,
            _unlockClaimTime: unlockClaimTime,
            _unstakeLockTime: unstakeLockTime,
            _rewardTotal: rewardTotal,
            _totalStaked: totalStaked, 
            _totalDistributed: totalDistributed,
            _stakeTokenAddres: address(stakingToken),
            _rewardTokenAddress: address(rewardToken)
        });

        return info_;
    }

    function claim() public nonReentrant returns (bool) {
        require(
            block.timestamp > unlockClaimTime,
            "Staking: Claiming is locked"
        );
        if (totalStaked > 0) {
            update();
        }

        uint256 reward = calcReward(msg.sender, TokensPerStake);
        require(reward > 0, "Staking: Nothing to claim");

        Staker storage staker = _stakers[msg.sender];

        staker.distributed = staker.distributed.add(reward);
        totalDistributed = totalDistributed.add(reward);

        IERC20(rewardToken).safeTransfer(msg.sender, reward);
        emit tokensClaimed(reward, block.timestamp, msg.sender);
        return true;
    }




}