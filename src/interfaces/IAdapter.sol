// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IAdapter Interface
/// @notice Interface for interacting with staking protocol adapters
/// @dev Implements core staking functionality with platform fees
interface IAdapter {
    /// @notice Emitted when tokens are deposited
    /// @param user Address of the user who deposited
    /// @param amount Amount of tokens deposited
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when tokens are withdrawn
    /// @param user Address of the user who withdrew
    /// @param amount Amount of tokens withdrawn
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Emitted when rewards are claimed
    /// @param user Address of the user who claimed
    /// @param amount Amount of rewards claimed
    event RewardClaimed(address indexed user, uint256 amount);

    /// @notice Emitted when platform fees are collected
    /// @param amount Amount of fees collected
    event FeesCollected(uint256 amount);

    /// @notice Get the staking token address
    /// @return Address of the staking token
    function stakeToken() external view returns (address);

    /// @notice Get the reward token address
    /// @return Address of the reward token
    function rewardToken() external view returns (address);

    /// @notice Check if emergency shutdown is active
    /// @return Status of emergency shutdown
    function emergencyShutdown() external view returns (bool);

    /// @notice Get total platform fees collected
    /// @return Amount of fees collected
    function platformFeesCollected() external view returns (uint256);

    /// @notice Get user's staked balance
    /// @param user Address of the user
    /// @return Amount of tokens staked
    function getStakedBalance(address user) external view returns (uint256);

    /// @notice Get user's total balance including rewards
    /// @param user Address of the user
    /// @return Total balance including staked and pending rewards
    function getCurrentBalance(address user) external view returns (uint256);

    /// @notice Get user's pending rewards
    /// @param user Address of the user
    /// @return Amount of pending rewards
    function getPendingRewards(address user) external view returns (uint256);

    /// @notice Deposit tokens into the protocol
    /// @param amount Amount of tokens to deposit
    /// @param user Address to credit the deposit
    /// @param duration Staking duration (if applicable)
    function deposit(uint256 amount, address user, uint256 duration) external;

    /// @notice Withdraw staked tokens
    /// @param amount Amount of tokens to withdraw
    /// @param user Address to receive the tokens
    function withdraw(uint256 amount, address user) external;

    /// @notice Claim pending rewards
    /// @param user Address to receive the rewards
    function claimRewards(address user) external;

    /// @notice Withdraw all staked tokens and rewards
    /// @param user Address to receive the assets
    function withdrawAll(address user) external;

    /// @notice Set emergency shutdown status
    /// @param _shutdown New shutdown status
    function setEmergencyShutdown(bool _shutdown) external;

    /// @notice Transfer collected platform fees
    /// @param to Address to receive the fees
    function transferFees(address to) external;
}