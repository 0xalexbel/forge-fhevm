// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";

import {FFhevm} from "../src/FFhevm.sol";
import {FFhevmSetUp} from "../src/libs/forge/FFhevmSetUp.sol";
import {FFhevmDeployConfigLib} from "../src/libs/forge/config/FFhevmDeployConfigLib.sol";
import {FFhevmConfigLib} from "../src/libs/forge/config/FFhevmConfigLib.sol";

import {TFHE, euint32} from "../src/libs/fhevm-debug/lib/TFHE.sol";
import {AddressLib} from "../src/libs/common/AddressLib.sol";

import {FHEVMConfig} from "./FHEVMConfig.sol";

contract FFhevmSetUpTestRevert is Test {
    // Use "__" prefix, because forge does not support same function name as calling function!
    function __testRevert_access_TFHE_without_setup() public {
        // "A contract calls a function from the TFHE library without having initialized it beforehand. Call 'TFHE.setFHEVM(<your debug config>)' first!"
        TFHE.asEuint32(123);
    }    

    // Use "__" prefix, because forge does not support same function name as calling function!
    function __testRevert_access_TFHE_undeployed_config() public {
        FFhevm.Config memory ffhevmConfig = FFhevmConfigLib.initializeWithEnv();
        // in rpc mode, contracts are already deployed. Bypass the test.
        vm.assume(!AddressLib.isDeployed(ffhevmConfig.core.ACLAddress));

        // error: FFhevm debugger not deployed.
        TFHE.setFHEVM(FHEVMConfig.defaultConfig());
    }
}

contract FFhevmSetUpTest is Test {
    FFhevmSetUpTestRevert ffhevmSetUpTestRevert;

    function setUp() public {
        ffhevmSetUpTestRevert = new FFhevmSetUpTestRevert();
    }

    function test_setUpCore() public {
        FFhevm.DeployConfig memory deployConfig = FFhevmDeployConfigLib.initializeWithEnv();
        FFhevmSetUp.setUpCore(deployConfig);
    }

    function test_setUpGateway() public {
        FFhevm.DeployConfig memory deployConfig = FFhevmDeployConfigLib.initializeWithEnv();
        FFhevmSetUp.setUpGateway(deployConfig);
    }

    function test_setUpDebugger() public {
        FFhevm.DeployConfig memory deployConfig = FFhevmDeployConfigLib.initializeWithEnv();
        FFhevmSetUp.setUpDebugger(deployConfig);
    }

    function test_setUpFullSuite() public {
        FFhevm.setUp();
    }

    function test_access_TFHE() public {
        FFhevm.setUp();
        TFHE.asEuint32(123);
    }

    function testRevert_access_TFHE_without_setup() public {
        vm.expectRevert();
        ffhevmSetUpTestRevert.__testRevert_access_TFHE_without_setup();
    }

    function testRevert_access_TFHE_undeployed_config() public {
        vm.expectRevert();
        ffhevmSetUpTestRevert.__testRevert_access_TFHE_undeployed_config();
    }
}
