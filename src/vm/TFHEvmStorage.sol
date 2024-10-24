// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {EncryptedInputSigner} from "../encrypted-input/EncryptedInputSigner.sol";
import {EncryptedInput} from "../encrypted-input/EncryptedInput.sol";
import {FhevmDeployConfig} from "./FhevmDeployConfig.sol";
import {FHEVMConfig} from "fhevm/lib/FHEVMConfig.sol";

struct TFHEvmStorage {
    bool initialized;
    FhevmDeployConfig deployConfig;
    address IRandomGeneratorAddress;
    FHEVMConfig.FHEVMConfigStruct fhevmConfig;
    // InputVerifiers
    address InputVerifierNativeAddress;
    address InputVerifierCoprocessorAddress;
    address InputVerifierAddress;
    // Gateway
    address GatewayContractAddress;
    // Extra
    address TFHEExecutorDBAddress;
}

library TFHEvmStorageLib {
    function getEncryptedInputSigner(TFHEvmStorage memory self) internal view returns (EncryptedInputSigner memory) {
        EncryptedInputSigner memory s;
        s.chainId = block.chainid;
        s.acl = self.fhevmConfig.ACLAddress;
        s.kmsVerifier = self.fhevmConfig.KMSVerifierAddress;
        s.inputVerifier = self.InputVerifierAddress;
        s.kmsSigners = self.deployConfig.getKmsSignersPk();
        s.coprocSigner = self.deployConfig.coprocessorAccount.privateKey;
        return s;
    }

    function createEncryptedInput(TFHEvmStorage memory self, address contractAddress, address userAddress)
        internal
        view
        returns (EncryptedInput memory input)
    {
        input._signer = getEncryptedInputSigner(self);
        input._contractAddress = contractAddress;
        input._userAddress = userAddress;
        input._dbAddress = self.TFHEExecutorDBAddress;
        input._randomGeneratorAddress = self.IRandomGeneratorAddress;
    }
}

using TFHEvmStorageLib for TFHEvmStorage global;
