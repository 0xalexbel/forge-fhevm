// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {console} from "forge-std/src/Console.sol";
import {Test} from "forge-std/src/Test.sol";
import "../src/env.default.sol";
import {FhevmDeployConfig} from "../src/vm/FhevmDeployConfig.sol";
import {BytesLib} from "../src/utils/BytesLib.sol";

contract EnvTest is Test {
    function setUp() public {}

    function test_EnvDefault() public pure {
        uint256[] memory arr = new uint256[](4);
        arr[0] = PRIVATE_KEY_KMS_SIGNER_0;
        arr[1] = PRIVATE_KEY_KMS_SIGNER_1;
        arr[2] = PRIVATE_KEY_KMS_SIGNER_2;
        arr[3] = PRIVATE_KEY_KMS_SIGNER_3;
        bytes memory b1 = abi.encode(arr);
        bytes memory b2 = abi.encode(
            bytes32(uint256(32)),
            bytes32(uint256(4)),
            PRIVATE_KEY_KMS_SIGNER_0,
            PRIVATE_KEY_KMS_SIGNER_1,
            PRIVATE_KEY_KMS_SIGNER_2,
            PRIVATE_KEY_KMS_SIGNER_3
        );

        uint256[] memory arr2 = new uint256[](4);
        arr2 = abi.decode(b2, (uint256[]));

        vm.assertEq(b1, b2);
        vm.assertEq(arr, arr2);
    }

    function test_Wallet() public {
        uint256 privateKey = uint256(keccak256("forge-fhevm cheat code"));
        //0xB6998ffdC1D00d8F2493B13326c65CcB32b19c14
        console.logBytes32(bytes32(vm.createWallet("forge-fhevm cheat code").privateKey));
        console.logBytes32(bytes32(privateKey));
        console.logAddress(vm.addr(privateKey));
        console.logAddress(address(uint160(uint256(keccak256("forge-fhevm cheat code")))));
    }

    function test_FhevmEnvConfig() public view {
        FhevmDeployConfig memory cfg;
        cfg.initializeWithEnv();
        vm.assertEq(cfg.fhevmDeployer.privateKey, PRIVATE_KEY_FHEVM_DEPLOYER);
        vm.assertEq(cfg.gatewayDeployer.privateKey, PRIVATE_KEY_GATEWAY_DEPLOYER);
        vm.assertEq(cfg.gatewayRelayer.privateKey, PRIVATE_KEY_GATEWAY_RELAYER);
        vm.assertEq(cfg.numKmsSigners, NUM_KMS_SIGNERS);
        vm.assertEq(cfg.isCoprocessor, IS_COPROCESSOR);
        vm.assertEq(cfg.coprocessorAccount.privateKey, PRIVATE_KEY_COPROCESSOR_ACCOUNT);
    }
}
