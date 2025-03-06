// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/protocols/SimpleStake.sol";
import "../src/ERC20.sol";
import "forge-std/console.sol";  

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

contract SimpleStakeTest is Test {
    SimpleStake public simpleStake;
    MockWMOD public wmod;
    MockSWMOD public swmod;
    address public owner;
    address public user1;
    address public user2;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event EmergencyShutdown(bool status);

    uint256 public constant REWARD_RATE = 1e18; // 每秒 1 sWMOD 獎勵（模擬）

    function setUp() public {
        owner = address(this); // 測試合約本身作為 owner
        user1 = address(0x1);
        user2 = address(0x2);

        wmod = new MockWMOD(owner, 18);
        swmod = new MockSWMOD(owner, 18);
        simpleStake = new SimpleStake(owner, address(wmod), address(swmod), REWARD_RATE);

        // 為 user1 和 user2 充值 WMOD
        wmod.mint(user1, 1000e18);
        wmod.mint(user2, 1000e18);

        // 為合約充值 sWMOD 作為獎勵
        swmod.mint(address(simpleStake), 100000e18);
    }

    function testInitialState() public {
        assertEq(simpleStake.owner(), owner);
        assertEq(address(simpleStake.stakingToken()), address(wmod));
        assertEq(address(simpleStake.rewardToken()), address(swmod));
        assertEq(simpleStake.rewardRate(), REWARD_RATE);
        assertEq(simpleStake.totalStaked(), 0);
        assertEq(simpleStake.emergencyShutdown(), false);
    }

    function testStake() public {
        uint256 amount = 100e18;

        // user1 批准合約使用 WMOD
        vm.prank(user1);
        wmod.approve(address(simpleStake), amount);

        vm.expectEmit(true, true, true, true);
        emit Staked(user1, amount);
        // user1 質押 100 WMOD
        vm.prank(user1);
        simpleStake.stake(user1, amount);

        assertEq(simpleStake.stakedBalance(user1), amount);
        assertEq(simpleStake.totalStaked(), amount);
        assertEq(wmod.balanceOf(address(simpleStake)), amount);
    }

    function testUnstake() public {
        uint256 amount = 100e18;

        // 質押
        vm.prank(user1);
        wmod.approve(address(simpleStake), amount);
        vm.prank(user1);
        simpleStake.stake(user1, amount);

        // 前進時間以累積獎勵
        vm.warp(block.timestamp + 10); // 前進 10 秒

        // 提款
        vm.expectEmit(true, true, true, true);
        emit Unstaked(user1, amount);
        vm.prank(user1);
        simpleStake.unstake(user1, amount);

        assertEq(simpleStake.stakedBalance(user1), 0);
        assertEq(simpleStake.totalStaked(), 0);
        assertEq(wmod.balanceOf(user1), 1000e18); // 初始餘額 + 返還的質押
    }

    function testClaimReward() public {
        uint256 amount = 100e18;

        // 質押
        vm.prank(user1);
        wmod.approve(address(simpleStake), amount);
        vm.prank(user1);
        simpleStake.stake(user1, amount);

        // 前進時間以累積獎勵
        vm.warp(block.timestamp + 10); // 10 秒，獎勵 = 10 * 1e18 = 10e18 sWMOD
        uint256 expectedReward = 10e18;

        vm.expectEmit(true, true, true, true);
        emit RewardClaimed(user1, expectedReward);
        vm.prank(user1);
        simpleStake.claimReward(user1);
        
        assertEq(swmod.balanceOf(user1), expectedReward);
        assertEq(simpleStake.rewards(user1), 0);
    }

    function testEmergencyShutdown() public {
        uint256 amount = 100e18;

        // 質押
        vm.prank(user1);
        wmod.approve(address(simpleStake), amount);
        vm.prank(user1);
        simpleStake.stake(user1, amount);

        // 設置緊急關閉
        simpleStake.setEmergencyShutdown(true);
        assertEq(simpleStake.emergencyShutdown(), true);

        // 嘗試質押應失敗
        vm.prank(user1);
        vm.expectRevert("Staking paused");
        simpleStake.stake(user1, amount);

        // 檢查事件
        vm.expectEmit(true, true, true, true);
        emit EmergencyShutdown(true);
        simpleStake.setEmergencyShutdown(true);
    }

    function testPendingReward() public {
        uint256 amount = 100e18;

        // 質押
        vm.prank(user1);
        wmod.approve(address(simpleStake), amount);
        vm.prank(user1);
        simpleStake.stake(user1, amount);

        // 前進時間
        vm.warp(block.timestamp + 5); // 5 秒，獎勵 = 5 * 1e18 = 5e18 sWMOD
        uint256 pending = simpleStake.pendingReward(user1);
        assertGt(pending, 0);
        assertApproxEqAbs(pending, 5e18, 1e18); // 考慮精確度誤差
    }

    function testMultiUser() public {
        uint256 amount1 = 100e18;
        uint256 amount2 = 200e18;

        // user1 質押
        vm.prank(user1);
        wmod.approve(address(simpleStake), amount1);
        vm.prank(user1);
        simpleStake.stake(user1, amount1);

        // user2 質押
        vm.prank(user2);
        wmod.approve(address(simpleStake), amount2);
        vm.prank(user2);
        simpleStake.stake(user2, amount2);

        // 前進時間
        vm.warp(block.timestamp + 10); // 10 秒，總質押 300 WMOD

        uint256 pending1 = simpleStake.pendingReward(user1); // user1 佔 1/3，獎勵約 3.33e18
        uint256 pending2 = simpleStake.pendingReward(user2); // user2 佔 2/3，獎勵約 6.66e18
        assertApproxEqAbs(pending1, 3.33e18, 0.1e18);
        assertApproxEqAbs(pending2, 6.66e18, 0.1e18);
    }
}