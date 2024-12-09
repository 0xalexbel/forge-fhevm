// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Script} from "forge-std/src/Script.sol";
import {console} from "forge-std/src/console.sol";

import {FFhevmDeployConfigLib} from "../src/libs/forge/config/FFhevmDeployConfigLib.sol";
import {FFhevmSetUp} from "../src/libs/forge/FFhevmSetUp.sol";
import {FFhevm} from "../src/FFhevm.sol";

// 1. anvil
// 2. cast send --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0xea63e594de67c2b32545c4b8fec9676285602852 -r http://127.0.0.1:8545
//    cast send --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x305F1F471e9baCFF2b3549F9601f9A4BEafc94e1 -r http://127.0.0.1:8545
//    cast send --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x5e85529F07A87868b853fda7eB518Ce1B6f58B92 -r http://127.0.0.1:8545
//    cast send --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x568294c3043895f54d076Dd453345bAA2f35015e -r http://127.0.0.1:8545
// 3. forge script ./script/DeployGateway.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
contract DeployGatewayScript is Script {
    FFhevm.DeployConfig deployConfig;

    function setUp() public {
        FFhevmDeployConfigLib.copyToStorage(FFhevmDeployConfigLib.initializeWithEnv(), deployConfig);
    }

    function run() public {
        FFhevmSetUp.setUpGateway(deployConfig);
    }
}
