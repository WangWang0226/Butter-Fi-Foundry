// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC20.sol";
import "../util/ReentrancyGuard.sol";
import "../protocols/EasyStake.sol";

contract EasyStakeAdapter is ReentrancyGuard {
    IERC20 public immutable stakeToken;
    IERC20 public immutable rewardToken;
    EasyStake public immutable easyStake;
    address public immutable aggregator;

    bool public emergencyShutdown;

    uint256 public constant PLATFORM_FEE = 1; // 1%
    uint256 public constant PLATFORM_FEE_BASE = 100;
    uint256 public platformFeesCollected;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event FeesCollected(uint256 amount);

    constructor(address _easyStake, address _aggregator) {
        easyStake = EasyStake(_easyStake);
        stakeToken = IERC20(easyStake.stakingToken());
        rewardToken = IERC20(easyStake.rewardToken());
        aggregator = _aggregator;
    }

    modifier onlyAggregator() {
        require(msg.sender == aggregator, "Adapter: Only aggregator");
        _;
    }

    /**
     * @notice Deposit tokens into EasyStake via adapter with 1% platform fee.
     * @param amount Amount of tokens to deposit.
     * @param user User address to credit the deposit.
     */
    function deposit(uint256 amount, address user) external nonReentrant onlyAggregator {
        require(!emergencyShutdown, "Adapter: Emergency shutdown");
        
        uint256 fee = (amount * PLATFORM_FEE) / PLATFORM_FEE_BASE;
        uint256 stakeAmount = amount - fee;
        platformFeesCollected += fee;
        stakeToken.approve(address(easyStake), stakeAmount);
        easyStake.depositTokens(user, stakeAmount); 

        emit Deposited(user, stakeAmount);
    }

    /**
     * @notice Withdraw staked tokens from EasyStake via adapter.
     * @param amount Amount of tokens to withdraw.
     * @param user User address to receive the tokens.
     */
    function withdraw(uint256 amount, address user) external nonReentrant onlyAggregator {
        easyStake.withdrawTokens(user, amount); 
        emit Withdrawn(user, amount);
    }

    /**
     * @notice Claim rewards for a user (pass-through to EasyStake).
     * @param user User address to send the rewards.
     */
    function claimRewards(address user) external nonReentrant onlyAggregator {
        easyStake.claimReward(user); 
    }

    /**
     * @notice Withdraw all staked tokens and rewards in emergency.
     * @param user User address to send the assets.
     */
    function withdrawAll(address user) external nonReentrant onlyAggregator {
        uint256 amount = easyStake.stakedBalance(user); // 直接查詢 EasyStake 的質押餘額
        if (amount > 0) {
            easyStake.withdrawTokens(user, amount);
            emit Withdrawn(user, amount);
        }

        easyStake.claimReward(user); 
    }

    /**
     * @notice Set emergency shutdown state.
     * @param _shutdown True to enable shutdown, false to disable.
     */
    function setEmergencyShutdown(bool _shutdown) external onlyAggregator {
        emergencyShutdown = _shutdown;
    }

    /**
     * @notice Transfer collected platform fees to a recipient.
     * @param to Recipient address.
     */
    function transferFees(address to) external nonReentrant onlyAggregator {
        uint256 fees = platformFeesCollected;
        require(fees > 0, "Adapter: No fees to collect");
        platformFeesCollected = 0;
        require(stakeToken.transfer(to, fees), "Adapter: Fee transfer failed"); // 使用 token 轉移費用
        emit FeesCollected(fees);
    }

    /**
     * @notice Get total staked amount of user.
     * @return stakedBalance User's staked balance.
     */
    function getStakedBalance(address user) external view returns (uint256) {
        return easyStake.stakedBalance(user);
    }

    /**
     * @notice Get user's current balance (staked + pending rewards).
     * @param user User address.
     * @return balance User's total balance.
     */
    function getCurrentBalance(address user) external view returns (uint256) {
        return easyStake.stakedBalance(user) + easyStake.pendingReward(user);
    }

    /**
     * @notice Get user's pending rewards.
     * @param user User address.
     * @return rewards User's pending reward amount.
     */
    function getPendingRewards(address user) external view returns (uint256) {
        return easyStake.pendingReward(user);
    }
}