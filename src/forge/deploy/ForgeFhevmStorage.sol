// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {EncryptedInputSigner} from "../input/EncryptedInputSigner.sol";
import {EncryptedInput} from "../EncryptedInput.sol";
import {ForgeFhevmConfig} from "./ForgeFhevmConfig.sol";
import {FHEVMConfig} from "../../debug/fhevm/lib/FHEVMConfig.sol";

//import {console} from "forge-std/src/console.sol";

struct ForgeFhevmStorage {
    bool initialized;
    ForgeFhevmConfig deployConfig;
    address IRandomGeneratorAddress;
    FHEVMConfig.FHEVMConfigStruct fhevmConfig;
    // InputVerifiers
    address InputVerifierNativeAddress;
    address InputVerifierCoprocessorAddress;
    address InputVerifierAddress;
    // Gateway
    address GatewayContractAddress;
    // Extra
    address TFHEDebuggerAddress;
}

library ForgeFhevmStorageLib {
    // keccak256(abi.encode(uint256(keccak256("forge-fhevm.storage.ForgeFhevm")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 internal constant ForgeFhevmStorageLocation =
        0xf3a1fb4bf47d0e9f750ac012dec60cd0fce24da39994865917c48339eefd8200;

    function get() internal pure returns (ForgeFhevmStorage storage $) {
        require(
            keccak256(abi.encode(uint256(keccak256("forge-fhevm.storage.ForgeFhevm")) - 1)) & ~bytes32(uint256(0xff))
                == ForgeFhevmStorageLocation,
            "Wrong ForgevmStorageLocation, recompute needed"
        );

        assembly {
            $.slot := ForgeFhevmStorageLocation
        }
    }

    function getEncryptedInputSigner(ForgeFhevmStorage memory self)
        internal
        view
        returns (EncryptedInputSigner memory)
    {
        EncryptedInputSigner memory s;
        s.chainId = block.chainid;
        s.acl = self.fhevmConfig.ACLAddress;
        s.kmsVerifier = self.fhevmConfig.KMSVerifierAddress;
        s.inputVerifier = self.InputVerifierAddress;
        s.kmsSigners = self.deployConfig.getKmsSignersPk();
        s.coprocSigner = self.deployConfig.coprocessorAccount.privateKey;
        return s;
    }

    function createEncryptedInput(ForgeFhevmStorage memory self, address contractAddress, address userAddress)
        internal
        view
        returns (EncryptedInput memory input)
    {
        input._signer = getEncryptedInputSigner(self);
        input._contractAddress = contractAddress;
        input._userAddress = userAddress;
        input._dbAddress = self.TFHEDebuggerAddress;
        input._randomGeneratorAddress = self.IRandomGeneratorAddress;
    }
}

using ForgeFhevmStorageLib for ForgeFhevmStorage global;
