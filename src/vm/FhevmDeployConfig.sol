// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "./IForgeStdVmSafe.sol";
import {EnvLib} from "./EnvLib.sol";
import {AddressLib} from "../utils/AddressLib.sol";
import {
    MNEMONIC,
    NUM_KMS_SIGNERS,
    IS_COPROCESSOR,
    PRIVATE_KEY_FHEVM_DEPLOYER,
    PRIVATE_KEY_GATEWAY_DEPLOYER,
    PRIVATE_KEY_GATEWAY_RELAYER,
    PRIVATE_KEY_COPROCESSOR_ACCOUNT,
    PRIVATE_KEY_KMS_SIGNERS
} from "../env.default.sol";
import {USE_DETERMINISTIC_RANDOM_GENERATOR} from "../envExtra.default.sol";

struct FhevmDeployConfig {
    string mnemonic;
    uint256 numKmsSigners;
    bool isCoprocessor;
    AddressLib.Signer fhevmDeployer;
    AddressLib.Signer gatewayDeployer;
    AddressLib.Signer gatewayRelayer;
    AddressLib.Signer[] kmsSigners;
    AddressLib.Signer coprocessorAccount;
    /// Extra
    bool useDeterministicRandomGenerator;
}

library FhevmDeployConfigLib {
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    function initializeWithEnv(FhevmDeployConfig memory self) internal view {
        self.mnemonic = EnvLib.envMnemonicOr("MNEMONIC", MNEMONIC);
        self.numKmsSigners = EnvLib.envUIntOr("NUM_KMS_SIGNERS", NUM_KMS_SIGNERS);
        self.isCoprocessor = EnvLib.envBoolOr("IS_COPROCESSOR", IS_COPROCESSOR);

        self.fhevmDeployer = EnvLib.envSigner("PRIVATE_KEY_FHEVM_DEPLOYER", PRIVATE_KEY_FHEVM_DEPLOYER);
        self.gatewayDeployer = EnvLib.envSigner("PRIVATE_KEY_GATEWAY_DEPLOYER", PRIVATE_KEY_GATEWAY_DEPLOYER);
        self.gatewayRelayer = EnvLib.envSigner("PRIVATE_KEY_GATEWAY_RELAYER", PRIVATE_KEY_GATEWAY_RELAYER);
        self.coprocessorAccount = EnvLib.envSigner("PRIVATE_KEY_COPROCESSOR_ACCOUNT", PRIVATE_KEY_COPROCESSOR_ACCOUNT);

        uint256[] memory defaultKmsSigners = abi.decode(PRIVATE_KEY_KMS_SIGNERS, (uint256[]));

        self.kmsSigners = new AddressLib.Signer[](self.numKmsSigners);
        for (uint8 i = 0; i < self.numKmsSigners; ++i) {
            AddressLib.Signer memory s =
                EnvLib.envSigner(string.concat("PRIVATE_KEY_KMS_SIGNER_", vm.toString(i)), defaultKmsSigners[i]);
            self.kmsSigners[i] = s;
        }

        // Extra
        self.useDeterministicRandomGenerator =
            EnvLib.envBoolOr("USE_DETERMINISTIC_RANDOM_GENERATOR", USE_DETERMINISTIC_RANDOM_GENERATOR);
    }

    function storageCopyFrom(FhevmDeployConfig storage self, FhevmDeployConfig memory src) internal {
        self.mnemonic = src.mnemonic;
        self.numKmsSigners = src.numKmsSigners;
        self.isCoprocessor = src.isCoprocessor;
        self.fhevmDeployer = src.fhevmDeployer;
        self.gatewayDeployer = src.gatewayDeployer;
        self.gatewayRelayer = src.gatewayRelayer;
        self.coprocessorAccount = src.coprocessorAccount;
        for (uint8 i = 0; i < src.numKmsSigners; ++i) {
            self.kmsSigners.push(src.kmsSigners[i]);
        }

        // Extra
        self.useDeterministicRandomGenerator = src.useDeterministicRandomGenerator;
    }

    function getKmsSignersPk(FhevmDeployConfig memory self) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](self.numKmsSigners);
        for (uint8 i = 0; i < self.numKmsSigners; ++i) {
            arr[i] = self.kmsSigners[i].privateKey;
        }
        return arr;
    }

    function getKmsSignersAddr(FhevmDeployConfig memory self) internal pure returns (address[] memory) {
        address[] memory arr = new address[](self.numKmsSigners);
        for (uint8 i = 0; i < self.numKmsSigners; ++i) {
            arr[i] = self.kmsSigners[i].addr;
        }
        return arr;
    }
}

using FhevmDeployConfigLib for FhevmDeployConfig global;
