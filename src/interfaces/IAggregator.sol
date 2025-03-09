// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IAggregator Interface
/// @notice Interface for managing multiple staking strategies
interface IAggregator {
    /// @notice Invest tokens into a specific strategy
    /// @param user Address of the user to credit the investment
    /// @param strategyId ID of the target strategy
    /// @param token Address of token to invest
    /// @param amount Amount of tokens to invest
    function investInStrategy(
        address user,
        uint256 strategyId, 
        address token,
        uint256 amount
    ) external;

    /// @notice Withdraw tokens from a strategy
    /// @param user Address to receive the withdrawn tokens
    /// @param strategyId ID of the target strategy
    /// @param amount Amount to withdraw
    function withdrawFromStrategy(
        address user,
        uint256 strategyId,
        uint256 amount
    ) external;

    /// @notice Add a new strategy to the aggregator
    /// @param strategyId ID for the new strategy
    /// @param adapter Address of the strategy adapter
    function addStrategy(uint256 strategyId, address adapter) external;

    /// @notice Set emergency shutdown status for a strategy
    /// @param strategyId ID of the target strategy
    /// @param _shutdown New shutdown status
    function setEmergencyShutdown(
        uint256 strategyId,
        bool _shutdown
    ) external;

    /// @notice Collect platform fees from a strategy
    /// @param strategyId ID of the target strategy
    function collectPlatformFees(uint256 strategyId) external;

    /// @notice Claim rewards from a strategy
    /// @param strategyId ID of the target strategy
    /// @param user Address to receive the rewards
    function claimRewards(uint256 strategyId, address user) external;

    /// @notice Get user's staked balance in a strategy
    /// @param strategyId ID of the target strategy
    /// @param user Address of the user
    /// @return User's staked balance
    function getStakedBalance(uint256 strategyId, address user) external view returns (uint256);

    /// @notice Get user's current balance including rewards
    /// @param strategyId ID of the target strategy
    /// @param user Address of the user
    /// @return User's total balance
    function getCurrentBalance(uint256 strategyId, address user) external view returns (uint256);

    /// @notice Get user's pending rewards
    /// @param strategyId ID of the target strategy
    /// @param user Address of the user
    /// @return Amount of pending rewards
    function getPendingRewards(uint256 strategyId, address user) external view returns (uint256);

    /// @notice Get strategy address for given ID
    /// @param strategyId ID of the strategy
    /// @return Address of the strategy
    function strategies(uint256 strategyId) external view returns (address);

    /// @notice Get total number of strategies
    /// @return Number of strategies
    function strategyCount() external view returns (uint256);

    /// @notice Get owner address
    /// @return Address of the owner
    function owner() external view returns (address);
}