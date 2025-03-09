// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IERC20.sol";
import "./interfaces/IAdapter.sol";

contract Aggregator {
    mapping(uint256 => address) public strategies;
    uint256 public strategyCount;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Aggregator: FORBIDDEN");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function investInStrategy(address user, uint256 strategyId, address token, uint256 amount) external {
        require(amount > 0, "Aggregator: Amount must be greater than 0");
        require(IERC20(token).balanceOf(msg.sender) >= amount, "Aggregator: Insufficient sender balance");

        address adapter = strategies[strategyId];
        
        require(
            !IAdapter(adapter).emergencyShutdown(),
            "Aggregator: Target Strategy is Emergency shutdown"
        );
        require(adapter != address(0), "Aggregator: Strategy not found");
        require(
            IERC20(token).transferFrom(msg.sender, adapter, amount),
            "Aggregator: Transfer failed"
        );
        IAdapter(adapter).deposit(amount, user);
    }

    function withdrawFromStrategy(address user, uint256 strategyId, uint256 amount) external {
        address adapter = strategies[strategyId];
        require(adapter != address(0), "Aggregator: Strategy not found");
        IAdapter(adapter).withdraw(amount, user);
    }

    function addStrategy(uint256 strategyId, address adapter) external {
        require(
            strategies[strategyId] == address(0),
            "Aggregator: Strategy already exists"
        );
        strategies[strategyId] = adapter;
        strategyCount++;
    }

    function setEmergencyShutdown(
        uint256 strategyId,
        bool _shutdown
    ) external onlyOwner {
        address adapter = strategies[strategyId];
        IAdapter(adapter).setEmergencyShutdown(_shutdown);
    }

    function collectPlatformFees(uint256 strategyId) external onlyOwner {
        address adapter = strategies[strategyId];
        IAdapter(adapter).transferFees(msg.sender);
    }

    function claimRewards(uint256 strategyId, address user) external {
        address adapter = strategies[strategyId];
        IAdapter(adapter).claimRewards(user);
    }

    /**
     * @notice Get total staked amount of user.
     * @return stakedBalance User's staked balance.
     */
    function getStakedBalance(uint256 strategyId, address user) external view returns (uint256) {
        address adapter = strategies[strategyId];
        return IAdapter(adapter).getStakedBalance(user);
    }

    /**
     * @notice Get user's current balance (staked + pending rewards).
     * @param user User address.
     * @return balance User's total balance.
     */
    function getCurrentBalance(uint256 strategyId, address user) external view returns (uint256) {
        address adapter = strategies[strategyId];
        return IAdapter(adapter).getCurrentBalance(user);
    }

    /**
     * @notice Get user's pending rewards.
     * @param user User address.
     * @return rewards User's pending reward amount.
     */
    function getPendingRewards(uint256 strategyId, address user) external view returns (uint256) {
        address adapter = strategies[strategyId];
        return IAdapter(adapter).getPendingRewards(user);
    }
}
