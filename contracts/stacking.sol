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
        uint256 amount;         // amount of tokens currently staked to contract
        uint256 rewardAllowed;  // amount of tokens that allowed to use
        uint256 rewardDebt;     // Debt of staking to staker 
        uint256 lastTimeUpdate;
        uint64  lastPercentID;
    }
    
    // StakeInfo contain information for stake
    struct StakeInfo {
        uint256 _startTime; // time of staking start
        uint256 _endTime; // time of staking end
        uint256 _unlockClaimTime;
        uint256 _rewardTotal;
        uint256 _totalStaked;
    }

    struct PercentInfo {
        uint256 Value; 
        uint256 StartTime;
        uint256 EndTime;
        uint64 NextID;
    }

    mapping (address => Staker) _stakers;
    mapping (uint64 => PercentInfo) _percentValues; // 

    uint256 public startTime;
    uint256 public endTime;
    uint256 public unlockClaimTime;
    uint256 public rewardTotal;
    uint256 public totalStaked;

    uint64 private percentID;
    uint256 private constant weekInSec = 604800;
    uint256 private constant weekInSecX100 = 60480000;

    uint256 public minStakingAmount = 1e18;

    ERC20 public tokenForStake;
    ERC20 public tokenForReward;

    event tokensStaked(uint256 amount, uint256 time, address indexed sender);
    event tokensClaimed(uint256 amount, uint256 time, address indexed sender);
    event tokensUnstaked(uint256 amount, uint256 time, address indexed sender);
    event rewardTokensIsEmpty(uint256 time); // 

    constructor(
        uint256 _rewardTotal,
        uint256 _startTime,
        uint256 _unlockClaimTime,
    ) public {
        // Give role of admin to contract deployer
        _setupRole(ADMIN, msg.sender);

        rewardTotal = _rewardTotal;
        startTime = _startTime;
        endTime = _endTime;
        unlockClaimTime = _startTime + weekInSec;       // Claiming after one week

        producedTime = _startTime;
    }

    function initialize(address _rewardToken, address _stakingToken) public {
        require(
            hasRole(ADMIN, msg.sender), 
            "initialize:: caller is not an admin"
        );
        require(
            address(stakingToken) == address(0) && address(rewardToken) == address(0),
            "initialize:: tokens addresses are zeros"
        );

        tokenForReward = ERC20(_rewardToken);
        tokenForStake = ERC20(_stakingToken);
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

        staker.amount = staker.amount.sub(_amount);
        totalStaked = totalStaked.sub(_amount);

        IERC20(stakingToken).safeTransfer(msg.sender, _amount);

        emit TokensUnstaked(_amount, block.timestamp, msg.sender);
    }

    function claim() public nonReentrant returns (bool) {
        Staker storage staker = _stakers[msg.sender];
        
        require(
            block.timestamp > unlockClaimTime,
            "Staking: Claiming is locked"
        );
        
        if (totalStaked > 0) {
            update();
        }

        uint256 reward = calcReward(msg.sender, TokensPerStake);
        require(reward > 0, "Staking: Nothing to claim");

        staker.distributed = staker.distributed.add(reward);
        totalDistributed = totalDistributed.add(reward);

        IERC20(rewardToken).safeTransfer(msg.sender, reward);
        emit tokensClaimed(reward, block.timestamp, msg.sender);
        return true;
    }


    /*************************************
     * REWARD CALCULATION SECTION STARTS *
     *************************************/

    function update() internal {
        Staker storage staker = _stakers[msg.sender];
        PercentInfo storage percent = _percentValues[staker.lastPercentID]
        if (staker.lastPercentID = percentID) {
            require(
                percent.EndTime == 0,
                "update:: normal_update error, there is new percent value"
            );
            require(
                percent.NextID == 0,
                "update:: normal_update error, there is another percent value"
            );
            
            staker.rewardDebt = rewardDebt.add(calcReward( staker.amount,
                                                           percent.Value,
                                                           staker.lastTimeUpdate,
                                                           block.timestamp        ));
            staker.lastTimeUpdate = block.timestamp;
        }
        else { // recursion 
            // don't invent something better, then using recursion calls for //
            // calculation accumulated profit on different percent intervals //
            staker.rewardDebt = rewardDebt.add(calcReward( staker.amount,
                                                           percent.Value,
                                                           staker.lastTimeUpdate,
                                                           percent.EndTime       ));
            staker.lastTimeUpdate = add(percent.endTime, 1);
            staker.lastPercentID = percent.NextID;
            update();
        }
    }

    function calcReward(
        uint256 _staked_amount,
        uint256 _percent,
        uint256 _time_now,
        uint256 _time_start
    ) 
        internal returns (uint256)
    {
        /***********************************************************************
         *                  staked_amount × percent × (time_now - time_start) 
         * reward_amount = ———————————————————————————————————————————————————
         *                                   weekInSec × 100
         ***********************************************************************/
        uint256 reward_amount = div( mul( staked_amount, mul(percent, sub(time_now, time_start))), weekInSecX100); 
        return reward_amount;
    }


    function changePercent(uint _percent) external returns (bool) {
        require(
            hasRole(ADMIN, msg.sender),
            "changePercent:: you should have admin role to do that"
        ); 
        
        PercentInfo storage percentPrev = _percentValues[percentID];
        PercentInfo storage percentNow = _percentValues[percentID.add(1)];

        percentPrev.EndTime = block.timestamp;
        percentPrev.NextID = percentID.add(1);

        percentNow.Value = _percent;
        percentNow.startTime = block.timestamp.add(1);
        percentNow.Endtime = 0;
        percentNow.NextID = 0;
    }


    /****************************
     * VIEWING FUNCTIONS STARTS *
     ****************************/

    function setReward(uin256 _amount) public {
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

    /**************************
     * VIEWING FUNCTIONS ENDS *
     **************************/


}