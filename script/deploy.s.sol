pragma solidity ^0.8.20;

// SPDX-License-Identifier: MIT

import "forge-std/Test.sol";
import "../src/Aggregator.sol";
import "../src/protocols/SimpleStake.sol";
import "../src/protocols/HappyStake.sol";
import "../src/protocols/EasyStake.sol";
import "../src/protocols/CakeStake.sol";
import "../src/adapters/SimpleStakeAdapter.sol";
import "../src/adapters/HappyStakeAdapter.sol";
import "../src/adapters/EasyStakeAdapter.sol";
import "../src/adapters/CakeStakeAdapter.sol";
import "../src/util/ERC20.sol";

import "forge-std/Script.sol";

contract WMOD is ERC20 {
    constructor(address owner, uint8 _decimals) ERC20(owner, "Wrapped MOD", "WMOD", _decimals) {
        _mint(msg.sender, 1000000 * 10**_decimals); // 初始發行 1000000 WMOD
    }
}

contract sWMOD is ERC20 {
    constructor(address owner, uint8 _decimals) ERC20(owner, "Staked Wrapped MOD", "sWMOD", _decimals) {
        _mint(msg.sender, 1000000 * 10**_decimals); // 初始發行 1000000 sWMOD
    }
}        

contract Deploy is Script {
    SimpleStake public simpleStake;
    HappyStake public happyStake;
    EasyStake public easyStake;
    CakeStake public cakeStake;

    SimpleStakeAdapter public simpleStakeAdapter;
    HappyStakeAdapter public happyStakeAdapter;
    EasyStakeAdapter public easyStakeAdapter;
    CakeStakeAdapter public cakeStakeAdapter;

    WMOD public wmod;
    sWMOD public swmod;
    Aggregator public aggregator;

    address anvilUser1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address anvilUser2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address anvilUser3 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    uint amount = 3000e18;

    uint256 public constant SIMPLE_REWARD_RATE = 4e18; // 每秒 4 sWMOD 獎勵
    uint256 public constant HAPPY_REWARD_RATE = 3e18; 
    uint256 public constant EASY_REWARD_RATE = 2e18; 
    uint256 public constant CAKE_REWARD_RATE = 1e18; 

    uint256 public constant SIMPLE_STRATEGY_ID = 1;
    uint256 public constant HAPPY_STRATEGY_ID = 2;
    uint256 public constant EASY_STRATEGY_ID = 3;
    uint256 public constant CAKE_STRATEGY_ID = 4;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        wmod = new WMOD(deployer, 18);
        swmod = new sWMOD(deployer, 18);
        aggregator = new Aggregator(deployer);
        simpleStake = new SimpleStake(deployer, address(wmod), address(swmod), SIMPLE_REWARD_RATE);
        happyStake = new HappyStake(deployer, address(wmod), address(swmod), HAPPY_REWARD_RATE);
        easyStake = new EasyStake(deployer, address(wmod), address(swmod), EASY_REWARD_RATE);
        cakeStake = new CakeStake(deployer, address(wmod), address(swmod), CAKE_REWARD_RATE);
        
        simpleStakeAdapter = new SimpleStakeAdapter(address(simpleStake), address(aggregator));
        happyStakeAdapter = new HappyStakeAdapter(address(happyStake), address(aggregator));
        easyStakeAdapter = new EasyStakeAdapter(address(easyStake), address(aggregator));
        cakeStakeAdapter = new CakeStakeAdapter(address(cakeStake), address(aggregator));

             
        // 為 user1 和 user2 充值 WMOD
        wmod.mint(anvilUser1, 1000e18);
        wmod.mint(anvilUser2, 1000e18);
        wmod.mint(anvilUser3, 1000e18);

        // 為合約充值 sWMOD 作為獎勵
        swmod.mint(address(simpleStake), 100000e18);

        // 明確通過 addStrategy 註冊 adapter
        aggregator.addStrategy(SIMPLE_STRATEGY_ID, address(simpleStakeAdapter));
        aggregator.addStrategy(HAPPY_STRATEGY_ID, address(happyStakeAdapter));
        aggregator.addStrategy(EASY_STRATEGY_ID, address(easyStakeAdapter));
        aggregator.addStrategy(CAKE_STRATEGY_ID, address(cakeStakeAdapter));

        
        console.log("WMOD deployed at:", address(wmod));
        console.log("sWMOD deployed at:", address(swmod));
        console.log("Aggregator deployed at:", address(aggregator));
        console.log("SimpleStake deployed at:", address(simpleStake));
        console.log("HappyStake deployed at:", address(happyStake));
        console.log("EasyStake deployed at:", address(easyStake));
        console.log("CakeStake deployed at:", address(cakeStake));
        console.log("SimpleStakeAdapter deployed at:", address(simpleStakeAdapter));
        console.log("HappyStakeAdapter deployed at:", address(happyStakeAdapter));
        console.log("EasyStakeAdapter deployed at:", address(easyStakeAdapter));
        console.log("CakeStakeAdapter deployed at:", address(cakeStakeAdapter));

        console.log("Deploy script successfully completed");
        vm.stopBroadcast();
    }

}