// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC20.sol";
import "../util/ReentrancyGuard.sol";

contract HappyStake is ReentrancyGuard {

    address public owner;
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    uint256 public rewardRate; // Reward per second
    uint256 public lastRewardTime; // Last time rewards were updated
    uint256 public totalStaked;
    uint256 public rewardPerTokenStored; // Cumulative reward per staked token
    bool public emergencyShutdown;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public userRewardPerTokenPaid; // User's paid reward baseline
    mapping(address => uint256) public rewards; // User's unclaimed rewards

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event EmergencyShutdown(bool status);

    constructor(address _owner, address _stakingToken, address _rewardToken, uint256 _rewardRate) {
        owner = _owner;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate; // Now interpreted as reward per second
        lastRewardTime = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FORBIDDEN");
        _;
    }

    /**
     * @notice Stake tokens into the contract.
     * @param to User address who owns this stake.
     * @param _amount Amount of tokens to stake.
     */
    function stakeTokens(address to, uint256 _amount) external nonReentrant {
        require(!emergencyShutdown, "Staking paused");
        require(_amount > 0, "Amount must be greater than 0");

        _updateRewards();
        _distributeRewards(to);

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakedBalance[to] += _amount;
        totalStaked += _amount;

        emit Staked(to, _amount);
    }

    /**
     * @notice Withdraw staked tokens from the contract.
     * @param _amount Amount of tokens to withdraw.
     */
    function unstakeTokens(address to, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(stakedBalance[to] >= _amount, "Insufficient balance");

        _updateRewards();
        _distributeRewards(to);

        stakedBalance[to] -= _amount;
        totalStaked -= _amount;
        stakingToken.transfer(to, _amount);

        emit Unstaked(to, _amount);
    }

    /**
     * @notice Claim accumulated rewards.
     */
    function claimReward(address to) external nonReentrant {
        _updateRewards();
        _distributeRewards(to);

        uint256 reward = rewards[to];
        if (reward > 0) {
            rewards[to] = 0;
            require(rewardToken.transfer(to, reward), "Transfer failed");
            emit RewardClaimed(to, reward);
        }
    }

    /**
     * @notice View function to check pending rewards for a user.
     * @param _user The user address.
     * @return The pending reward amount.
     */
    function pendingReward(address _user) external view returns (uint256) {
        uint256 rewardPerToken = rewardPerTokenStored + _pendingRewardPerToken();
        uint256 earned = (stakedBalance[_user] * (rewardPerToken - userRewardPerTokenPaid[_user])) / 1e18;
        return rewards[_user] + earned;
    }

    /**
     * @notice Set emergency shutdown state.
     * @param _shutdown True to enable shutdown, false to disable.
     */
    function setEmergencyShutdown(bool _shutdown) external onlyOwner {
        emergencyShutdown = _shutdown;
        emit EmergencyShutdown(_shutdown);
    }

    /**
     * @dev Updates the contract reward state.
     */
    function _updateRewards() internal {
        rewardPerTokenStored += _pendingRewardPerToken();
        lastRewardTime = block.timestamp;
    }

    /**
     * @dev Calculates pending reward per token since last update.
     * @return The pending reward per token (scaled by 1e18).
     */
    function _pendingRewardPerToken() internal view returns (uint256) {
        if (totalStaked == 0 || block.timestamp <= lastRewardTime) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - lastRewardTime;
        return (timeElapsed * rewardRate * 1e18) / totalStaked;
    }

    /**
     * @dev Updates user's reward balance.
     * @param _user The user's address.
     */
    function _distributeRewards(address _user) internal {
        uint256 rewardPerToken = rewardPerTokenStored + _pendingRewardPerToken();
        uint256 earned = (stakedBalance[_user] * (rewardPerToken - userRewardPerTokenPaid[_user])) / 1e18;
        rewards[_user] += earned;
        userRewardPerTokenPaid[_user] = rewardPerToken;
    }
}