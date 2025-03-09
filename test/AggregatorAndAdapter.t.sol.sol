// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";  
import "../src/Aggregator.sol";
import "../src/adapters/SimpleStakeAdapter.sol";
import "../src/protocols/SimpleStake.sol";
import "../src/util/ERC20.sol";

// 模擬的 WMOD 和 sWMOD 代幣
contract MockWMOD is ERC20 {
    constructor(address owner, uint8 _decimals) ERC20(owner, "Wrapped MOD", "WMOD", _decimals) {
        _mint(msg.sender, 1000000 * 10**_decimals); // 初始發行 1000000 WMOD
    }
}

contract MockSWMOD is ERC20 {
    constructor(address owner, uint8 _decimals) ERC20(owner, "Staked Wrapped MOD", "sWMOD", _decimals) {
        _mint(msg.sender, 1000000 * 10**_decimals); // 初始發行 1000000 sWMOD
    }
}

contract AggregatorAdapterTest is Test {
    Aggregator public aggregator;
    SimpleStakeAdapter public adapter;
    SimpleStake public simpleStake;
    MockWMOD public wmod;
    MockSWMOD public swmod;
    address public owner;
    address public user1;
    address public user2;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event FeesCollected(uint256 amount);

    uint256 public constant REWARD_RATE = 1e18; // 每秒 1 sWMOD 獎勵
    uint256 public constant STRATEGY_ID = 1;

    function setUp() public {
        owner = address(this); // 測試合約本身作為 owner
        user1 = address(0x1);
        user2 = address(0x2);

        wmod = new MockWMOD(owner, 18);
        swmod = new MockSWMOD(owner, 18);
        simpleStake = new SimpleStake(owner, address(wmod), address(swmod), REWARD_RATE);
        aggregator = new Aggregator(owner);
        adapter = new SimpleStakeAdapter(address(simpleStake), address(aggregator));

        // 為 user1 和 user2 充值 WMOD
        wmod.mint(user1, 1000e18);
        wmod.mint(user2, 1000e18);

        // 為合約充值 sWMOD 作為獎勵
        swmod.mint(address(simpleStake), 100000e18);

        // [MODIFIED] 明確通過 addStrategy 註冊 adapter
        vm.prank(owner);
        aggregator.addStrategy(STRATEGY_ID, address(adapter));
    }

    function testInitialState() public view {
        assertEq(aggregator.owner(), owner);
        assertEq(aggregator.strategyCount(), 1);
        assertEq(aggregator.strategies(STRATEGY_ID), address(adapter));
        assertEq(adapter.emergencyShutdown(), false);
        assertEq(simpleStake.emergencyShutdown(), false);
    }

    function testInvestInStrategy() public {
        uint256 amount = 100e18;
        uint256 duration = 100;

        // user1 批准 aggregator 使用 WMOD
        vm.prank(user1);
        wmod.approve(address(aggregator), amount);

        uint fee = amount * 1 / 100;
        uint stakeAmount = amount - fee;

        // 使用 strategyId 與特定 adapter 溝通
        vm.expectEmit(true, true, true, true);
        emit Deposited(user1, stakeAmount);
        vm.prank(user1);
        aggregator.investInStrategy(STRATEGY_ID, address(wmod), amount, duration);

        assertEq(simpleStake.stakedBalance(user1), stakeAmount); // 扣除 1% 費用
        assertEq(simpleStake.totalStaked(), stakeAmount);
        assertEq(wmod.balanceOf(address(simpleStake)), stakeAmount);
    }

    function testWithdrawFromStrategy() public {
        uint256 amount = 100e18;
        uint fee = amount * 1 / 100;
        uint stakeAmount = amount - fee;

        // 投資
        vm.prank(user1);
        wmod.approve(address(aggregator), amount);
        vm.prank(user1);
        aggregator.investInStrategy(STRATEGY_ID, address(wmod), amount, 100);

        // 提款
        vm.expectEmit(true, true, true, true);
        emit Withdrawn(user1, stakeAmount);
        vm.prank(user1);
        aggregator.withdrawFromStrategy(STRATEGY_ID, stakeAmount);

        assertEq(simpleStake.stakedBalance(user1), 0);
        assertEq(simpleStake.totalStaked(), 0);
        assertEq(wmod.balanceOf(user1), 1000e18 - fee); // 初始餘額 + 返還的質押

    }

    function testClaimRewards() public {
        uint256 amount = 100e18;

        // 投資
        vm.prank(user1);
        wmod.approve(address(aggregator), amount);
        vm.prank(user1);
        aggregator.investInStrategy(STRATEGY_ID, address(wmod), amount, 100);

        // 前進時間以累積獎勵
        vm.warp(block.timestamp + 10); // 10 秒，獎勵約為 10 sWMOD
        uint256 expectedReward = simpleStake.pendingReward(user1);
        
        vm.prank(user1);
        aggregator.claimRewards(STRATEGY_ID, user1);

        assertEq(swmod.balanceOf(user1), expectedReward);
        assertEq(simpleStake.rewards(user1), 0);
    }

    function testSetEmergencyShutdown() public {
        uint256 amount = 100e18;

        // 投資
        vm.prank(user1);
        wmod.approve(address(aggregator), amount);
        vm.prank(user1);
        aggregator.investInStrategy(STRATEGY_ID, address(wmod), amount, 100);

        // 設置緊急關閉
        vm.prank(owner); // 僅 owner 可調用
        aggregator.setEmergencyShutdown(STRATEGY_ID, true);
        assertEq(adapter.emergencyShutdown(), true);

        // 嘗試投資應失敗
        vm.prank(user1);
        wmod.approve(address(aggregator), amount);
        vm.expectRevert("Aggregator: Target Strategy is Emergency shutdown");
        vm.prank(user1);
        aggregator.investInStrategy(STRATEGY_ID, address(wmod), amount, 100);
    }

    function testCollectPlatformFees() public {
        uint256 amount = 100e18;
        uint fee = amount * 1 / 100;

        // 投資，產生 1% 費用
        vm.prank(user1);
        wmod.approve(address(aggregator), amount);
        vm.prank(user1);
        aggregator.investInStrategy(STRATEGY_ID, address(wmod), amount, 100);

        assertEq(adapter.platformFeesCollected(), fee);

        // 收集費用
        uint256 initialBalance = wmod.balanceOf(owner);

        vm.expectEmit(true, true, true, true);
        emit FeesCollected(fee);
        vm.prank(owner); // 僅 owner 可調用
        aggregator.collectPlatformFees(STRATEGY_ID);
        assertEq(adapter.platformFeesCollected(), 0);
        assertEq(wmod.balanceOf(owner), initialBalance + fee);
    }

    function testGetCurrentBalance() public {
        uint256 amount = 100e18;

        // 投資
        vm.prank(user1);
        wmod.approve(address(aggregator), amount);
        vm.prank(user1);
        aggregator.investInStrategy(STRATEGY_ID, address(wmod), amount, 100);

        uint256 balance = aggregator.getCurrentBalance(STRATEGY_ID, user1);
        assertEq(balance, amount - (amount * 1 / 100)); // 初始質押金額

        // 前進時間以累積獎勵
        vm.warp(block.timestamp + 10);
        balance = aggregator.getCurrentBalance(STRATEGY_ID, user1);
        assertGt(balance, amount - (amount * 1 / 100)); // 包含獎勵
    }

    function testGetPendingRewards() public {
        uint256 amount = 100e18;

        // 投資
        vm.prank(user1);
        wmod.approve(address(aggregator), amount);
        vm.prank(user1);
        aggregator.investInStrategy(STRATEGY_ID, address(wmod), amount, 100);

        // 前進時間
        vm.warp(block.timestamp + 5); // 5 秒，獎勵 = 5 * 1e18
        uint256 pending = aggregator.getPendingRewards(STRATEGY_ID, user1);
        assertApproxEqAbs(pending, 5e18, 1e18); // 考慮精確度誤差
    }

    function testMultiUserScenario() public {
        uint256 amount1 = 100e18;
        uint256 amount2 = 200e18;

        // user1 投資
        vm.prank(user1);
        wmod.approve(address(aggregator), amount1);
        vm.prank(user1);
        aggregator.investInStrategy(STRATEGY_ID, address(wmod), amount1, 100);

        // user2 投資
        vm.prank(user2);
        wmod.approve(address(aggregator), amount2);
        vm.prank(user2);
        aggregator.investInStrategy(STRATEGY_ID, address(wmod), amount2, 100);

        // 前進時間
        vm.warp(block.timestamp + 10); // 10 秒，總質押 300e18 WMOD

        uint256 pending1 = aggregator.getPendingRewards(STRATEGY_ID, user1); // user1 佔 1/3，約 3.33e18
        uint256 pending2 = aggregator.getPendingRewards(STRATEGY_ID, user2); // user2 佔 2/3，約 6.66e18
        assertApproxEqAbs(pending1, 3.33e18, 0.1e18);
        assertApproxEqAbs(pending2, 6.66e18, 0.1e18);
    }
}