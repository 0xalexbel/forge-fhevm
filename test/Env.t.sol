// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {console} from "forge-std/src/console.sol";
import {Test} from "forge-std/src/Test.sol";

import {BytesLib} from "../src/libs/common/BytesLib.sol";
import {FFhevmDeployConfigLib} from "../src/libs/forge/config/FFhevmDeployConfigLib.sol";
import {EnvLib} from "../src/libs/forge/utils/EnvLib.sol";
import {NUM_KMS_SIGNERS, IS_COPROCESSOR} from "../src/libs/forge/config/env.default.sol";

import {FFhevm} from "../src/FFhevm.sol";

import {CORE_DEPLOYER_PK, COPROCESSOR_PK, GATEWAY_DEPLOYER_PK} from "forge-fhevm-config/addresses.sol";

contract EnvTest is Test {
    function setUp() public {}

    function test_FhevmEnvConfig() public {
        FFhevm.DeployConfig memory cfg = FFhevmDeployConfigLib.initializeWithEnv();
        vm.assertEq(cfg.fhevmDeployer.privateKey, CORE_DEPLOYER_PK, "CORE_DEPLOYER_PK");
        vm.assertEq(cfg.gatewayDeployer.privateKey, GATEWAY_DEPLOYER_PK, "GATEWAY_DEPLOYER_PK");
        vm.assertEq(cfg.numKmsSigners, NUM_KMS_SIGNERS);
        vm.assertEq(cfg.isCoprocessor, IS_COPROCESSOR);
        vm.assertEq(cfg.coprocessorAccount.privateKey, COPROCESSOR_PK, "COPROCESSOR_PK");
    }

    function testFail_missing_kms_signer_pk() public {
        uint256[] memory defaultPks = new uint256[](10);
        for (uint256 i = 0; i < defaultPks.length; ++i) {
            defaultPks[i] =
                uint256(keccak256(bytes(string.concat("ffhevm.default_kms_signer.wallet.", vm.toString(i)))));
        }
        FFhevm.Signer[] memory signers = EnvLib.envSignersArray("PRIVATE_KEY_KMS_SIGNER_", defaultPks);
        for (uint256 i = 0; i < signers.length; ++i) {
            console.log("signers[%s] = %s", i, signers[i].privateKey);
        }
    }

    function test_env_kms_signer_pk() public {
        uint256[] memory defaultPks = new uint256[](NUM_KMS_SIGNERS);
        for (uint256 i = 0; i < defaultPks.length; ++i) {
            defaultPks[i] =
                uint256(keccak256(bytes(string.concat("ffhevm.default_kms_signer.wallet.", vm.toString(i)))));
        }
        EnvLib.envSignersArray("PRIVATE_KEY_KMS_SIGNER_", defaultPks);
    }

    function test_default_kms_signer_pk() public {
        uint256[] memory defaultPks = new uint256[](NUM_KMS_SIGNERS);
        for (uint256 i = 0; i < defaultPks.length; ++i) {
            defaultPks[i] =
                uint256(keccak256(bytes(string.concat("ffhevm.default_kms_signer.wallet.", vm.toString(i)))));
        }
        FFhevm.Signer[] memory signers = EnvLib.envSignersArray("DEADBEEF_VAR_NAME_", defaultPks);
        vm.assertEq(signers.length, defaultPks.length);
        for (uint256 i = 0; i < defaultPks.length; ++i) {
            vm.assertEq(defaultPks[i], signers[i].privateKey);
        }
    }
}
