// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {AddressLib} from "../../common/AddressLib.sol";

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "../interfaces/IForgeStdVm.sol";
import {FFhevm} from "../../../FFhevm.sol";
import {EnvLib} from "../utils/EnvLib.sol";

import {MNEMONIC, NUM_KMS_SIGNERS, IS_COPROCESSOR} from "./env.default.sol";
import {USE_DETERMINISTIC_RANDOM_GENERATOR} from "./envDebugger.default.sol";
import {
    CORE_DEPLOYER_PK,
    COPROCESSOR_PK,
    GATEWAY_DEPLOYER_PK,
    FFHEVM_DEBUGGER_DEPLOYER_PK
} from "forge-fhevm-config/addresses.sol";

library FFhevmDeployConfigLib {
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    function initializeWithEnv() internal returns (FFhevm.DeployConfig memory config) {
        config.mnemonic = EnvLib.envMnemonicOr("MNEMONIC", MNEMONIC);
        config.numKmsSigners = EnvLib.envUIntOr("NUM_KMS_SIGNERS", NUM_KMS_SIGNERS);
        config.isCoprocessor = EnvLib.envBoolOr("IS_COPROCESSOR", IS_COPROCESSOR);

        config.fhevmDeployer = EnvLib.envSigner("PRIVATE_KEY_FHEVM_DEPLOYER", CORE_DEPLOYER_PK);
        config.gatewayDeployer = EnvLib.envSigner("PRIVATE_KEY_GATEWAY_DEPLOYER", GATEWAY_DEPLOYER_PK);
        config.gatewayRelayer = EnvLib.envSigner("PRIVATE_KEY_GATEWAY_RELAYER", _getDefaultRelayer());
        config.coprocessorAccount = EnvLib.envSigner("PRIVATE_KEY_COPROCESSOR_ACCOUNT", COPROCESSOR_PK);

        config.kmsSigners =
            EnvLib.envSignersArray("PRIVATE_KEY_KMS_SIGNER_", _getDefaultKmsSigners(config.numKmsSigners));

        // Extra
        config.useDeterministicRandomGenerator =
            EnvLib.envBoolOr("USE_DETERMINISTIC_RANDOM_GENERATOR", USE_DETERMINISTIC_RANDOM_GENERATOR);
        config.ffhevmDebuggerDeployer =
            EnvLib.envSigner("PRIVATE_KEY_FFHEVM_DEBUGGER_DEPLOYER", FFHEVM_DEBUGGER_DEPLOYER_PK);
    }

    function _getDefaultRelayer() private pure returns (uint256) {
        return uint256(keccak256(bytes("ffhevm.default_gateway_relayer.wallet.")));
    }

    function _getDefaultKmsSigners(uint256 count) private pure returns (uint256[] memory) {
        uint256[] memory pks = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            pks[i] = uint256(keccak256(bytes(string.concat("ffhevm.default_kms_signer.wallet.", vm.toString(i)))));
        }
        return pks;
    }

    function copyToStorage(FFhevm.DeployConfig memory src, FFhevm.DeployConfig storage dst) internal {
        dst.mnemonic = src.mnemonic;
        dst.numKmsSigners = src.numKmsSigners;
        dst.isCoprocessor = src.isCoprocessor;
        dst.fhevmDeployer = src.fhevmDeployer;
        dst.gatewayDeployer = src.gatewayDeployer;
        dst.gatewayRelayer = src.gatewayRelayer;
        dst.coprocessorAccount = src.coprocessorAccount;
        for (uint8 i = 0; i < src.numKmsSigners; ++i) {
            dst.kmsSigners.push(src.kmsSigners[i]);
        }
        dst.useDeterministicRandomGenerator = src.useDeterministicRandomGenerator;
        dst.ffhevmDebuggerDeployer = src.ffhevmDebuggerDeployer;
    }

    function getKmsSignersAddr(FFhevm.DeployConfig memory config) internal pure returns (address[] memory) {
        address[] memory arr = new address[](config.numKmsSigners);
        for (uint8 i = 0; i < config.numKmsSigners; ++i) {
            arr[i] = config.kmsSigners[i].addr;
        }
        return arr;
    }
}
