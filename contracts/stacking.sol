//"SPDX-License-Identifier: MIT"
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./bulldogtoken.sol";
import "./puppytoken.sol";


contract Staking is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    //using SafeERC20 for IERC20;

    bytes32 public constant ADMIN = keccak256("ADMIN");

    // Staker contain info for each staker
    struct Staker {
        uint256 amount;         // amount of tokens currently staked to contract
        uint256 rewardAllowed;  // amount of tokens that allowed to use
        uint256 rewardDebt;     // Debt of staking to staker 
        uint256 lastTimeUpdate;
        uint256  lastPercentID;
    }
    
    // StakeInfo contain information for stake
    struct StakeInfo {
        uint256 _startTime; // time of staking start
        uint256 _unlockClaimTime;
        uint256 _rewardTotal;
        uint256 _totalStaked;
    }

    struct PercentInfo {
        uint256 Value; 
        uint256 StartTime;
        uint256 EndTime;
        uint256 NextID;
    }

    mapping (address => Staker) _stakers;
    mapping (uint256 => PercentInfo) _percentValues; // 

    uint256 public startTime;
    uint256 public unlockClaimTime;
    uint256 public rewardTotal;
    uint256 public totalStaked;

    uint256 public percentID;
    uint256 private constant weekInSec = 604800;
    uint256 private constant weekInSecX100 = 60480000;

    uint256 public minStakingAmount = 1e18;

    address tokenForStake;
    address tokenForReward;

    event tokensStaked(uint256 amount, uint256 time, address indexed sender);
    event tokensClaimed(uint256 amount, uint256 time, address indexed sender);
    event tokensUnstaked(uint256 amount, uint256 time, address indexed sender);
    event rewardTokensIsEmpty(uint256 time); // 

    constructor(
        uint256 _rewardTotal,
        uint256 _startTime
    ) public {
        // Give role of admin to contract deployer
        _setupRole(ADMIN, msg.sender);

        rewardTotal = _rewardTotal;
        startTime = _startTime;
        unlockClaimTime = _startTime + weekInSec;       // Claiming after one week
        percentID = 1;
        _percentValues[percentID].Value = 15;
        _percentValues[percentID].StartTime = startTime;
        _percentValues[percentID].EndTime = 0;
        _percentValues[percentID].NextID = 0;
    
        // tokenForReward = ERC20(0x521C9cCF16265e549EB5b97af055792bc50a73e3);
        // tokenForStake = ERC20(0xdF21bDd8e2CD17c7d1C61000c5E3122136FeCd47);
    }

    function initialize(address _rewardToken, address _stakingToken) 
        external returns (bool)
    {
        require(
            hasRole(ADMIN, msg.sender), 
            "initialize:: caller is not an admin"
        );
        require(
            address(_rewardToken) != address(0) 
            && address(_stakingToken) != address(0),
            "initialize:: tokens addresses are zeros"
        );

        tokenForReward = _rewardToken;
        tokenForStake = _stakingToken;

        return true;
    } 

    function stake(uint256 _amount) public {
        require(
            block.timestamp > startTime,
            "stake:: staking time is not come"
        );
        Staker storage staker = _stakers[msg.sender];

        // Transfer specified amount of staking tokens to the contract 
        BullDogToken(tokenForStake).transferFrom(
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

        BullDogToken(tokenForStake).transfer(msg.sender, _amount);

        emit tokensUnstaked(_amount, block.timestamp, msg.sender);
    }

    function claim() public nonReentrant returns (bool) {
        Staker storage staker = _stakers[msg.sender];
        
        require(
            block.timestamp > unlockClaimTime,
            "claim:: Claiming is locked"
        );
        require(
            rewardTotal > 0,
            "claim:: the owner hasn't got tokens for you"
        );

        if (totalStaked > 0) {
            update();
        }

        uint256 reward;
        if (rewardTotal > staker.rewardDebt) {
            staker.rewardAllowed = staker.rewardDebt;
            staker.rewardDebt = 0;
            rewardTotal = rewardTotal.sub(staker.rewardAllowed);
        }
        else {
            staker.rewardAllowed = rewardTotal;
            staker.rewardDebt = staker.rewardDebt.sub(rewardTotal);
            rewardTotal = 0;
            emit rewardTokensIsEmpty(block.timestamp);
        }   

        require(reward > 0, "Staking: Nothing to claim");

        PuppyToken(tokenForReward).transfer(msg.sender, reward);
        emit tokensClaimed(reward, block.timestamp, msg.sender);
        return true;
    }


    /*************************************
     * REWARD CALCULATION SECTION STARTS *
     *************************************/

    function update() internal {
        Staker storage staker = _stakers[msg.sender];
        PercentInfo storage percent = _percentValues[staker.lastPercentID];
        if (staker.lastPercentID == percentID) {
            require(
                percent.EndTime == 0,
                "update:: normal_update error, there is new percent value"
            );
            require(
                percent.NextID == 0,
                "update:: normal_update error, there is another percent value"
            );
            
            staker.rewardDebt = staker.rewardDebt.add(calcReward( staker.amount,
                                                                  percent.Value,
                                                                  staker.lastTimeUpdate,
                                                                  block.timestamp        ));
            staker.lastTimeUpdate = block.timestamp;
        }
        else { // recursion 
            // don't invent something better, then using recursion calls for //
            // calculation accumulated profit on different percent intervals //
            staker.rewardDebt = staker.rewardDebt.add(calcReward( staker.amount,
                                                                  percent.Value,
                                                                  staker.lastTimeUpdate,
                                                                  percent.EndTime       ));
            staker.lastTimeUpdate = percent.EndTime.add(1);
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
        uint256 reward_amount = _staked_amount.mul(_percent.mul(_time_now - _time_start)).div(weekInSecX100);
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
        percentNow.StartTime = block.timestamp.add(1);
        percentNow.EndTime = 0;
        percentNow.NextID = 0;
        return true;
    }


    /****************************
     * VIEWING FUNCTIONS STARTS *
     ****************************/

    function setReward(uint256 _amount) public {
        require(hasRole(ADMIN, msg.sender));
        rewardTotal = _amount;
    }

    function staked() public view returns (uint256) {
        return totalStaked;
    }

    function getInfoByAddress(address _address)
        external 
        view
        returns (
            uint256 _amount,
            uint256 _rewardAllowed,
            uint256 _rewardDebt,
            uint256 _lastTimeUpdate,
            uint256 _lastPercentValue
        )
    {
        Staker storage staker = _stakers[_address];
        
        _amount = staker.amount;
        _rewardAllowed = staker.rewardAllowed;
        _rewardDebt = staker.rewardDebt;
        _lastTimeUpdate = staker.lastTimeUpdate;
        _lastPercentValue = _percentValues[staker.lastPercentID].Value;
        
        return(
            _amount,
            _rewardAllowed,
            _rewardDebt,
            _lastTimeUpdate,
            _lastPercentValue
        );
    }

    function getStakingInfo() 
        external
        view
        returns (
            StakeInfo memory info_
        )
    {
        info_ = StakeInfo({
            _startTime: startTime,
            _unlockClaimTime: unlockClaimTime,
            _rewardTotal: rewardTotal,
            _totalStaked: totalStaked
        });

        return info_;
    }

    /**************************
     * VIEWING FUNCTIONS ENDS *
     **************************/


}