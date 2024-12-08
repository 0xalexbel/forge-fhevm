// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {
    TFHE,
    einput,
    ebool,
    euint4,
    euint8,
    euint16,
    euint32,
    euint64,
    euint128,
    euint256,
    ebytes64,
    ebytes128,
    ebytes256,
    eaddress
} from "../../fhevm-debug/lib/TFHE.sol";
import {FFhevm, EncryptedInput} from "../../../FFhevm.sol";
import {IRandomGenerator} from "../../common/interfaces/IRandomGenerator.sol";
import {EncryptedInputSigner} from "../input/EncryptedInputSigner.sol";
import {IFFhevmInput} from "../interfaces/IFFhevmInput.sol";
import {FFhevmPrecompile} from "./FFhevmPrecompile.sol";

contract FFhevmInputPrecompile is FFhevmPrecompile, IFFhevmInput, IRandomGenerator {
    uint256 private _randCounter;

    //keccak256("FFhevmInputPrecompile")
    bytes32 constant RANDSEED = 0xd82ea4982244dfd4d19c09e2c50cbf8f646848c6162830030c3245c8ffc5dd6f;

    constructor(FFhevm.Config memory fhevmConfig) FFhevmPrecompile(fhevmConfig) {}

    function randomUint() external noGasMetering returns (uint256) {
        bytes32 pseudoRand = keccak256(bytes.concat(RANDSEED, bytes32(_randCounter)));
        _randCounter += 1;
        return uint256(pseudoRand);
    }

    function _createEncryptedInput(address contractAddress, address userAddress)
        private
        view
        debuggerDeployed
        returns (EncryptedInput memory input)
    {
        FFhevm.Config storage config = _config();

        input._signer = EncryptedInputSigner({
            chainId: block.chainid,
            acl: config.core.ACLAddress,
            kmsVerifier: config.core.KMSVerifierAddress,
            inputVerifier: config.core.InputVerifierAddress,
            kmsSigners: config.deployConfig.kmsSigners,
            coprocSigner: config.deployConfig.coprocessorAccount
        });

        input._contractAddress = contractAddress;
        input._userAddress = userAddress;
        input._debuggerAddress = config.debugger.TFHEDebuggerAddress;
        input._debuggerDBAddress = config.debugger.TFHEDebuggerDBAddress;

        if (config.IRandomGeneratorAddress == address(0)) {
            input._randomGeneratorAddress = address(this);
        } else {
            input._randomGeneratorAddress = config.IRandomGeneratorAddress;
        }
    }

    function createEncryptedInput(address contractAddress, address userAddress)
        external
        noGasMetering
        returns (EncryptedInput memory input)
    {
        input = _createEncryptedInput(contractAddress, userAddress);
    }

    // ====================================================================== //
    //
    //                      ⭐️ API: Encrypt functions ⭐️
    //
    // ====================================================================== //

    function encryptBool(bool value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptBool(value, contractAddress, userAddress);
    }

    function encryptU4(uint8 value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptU4(value, contractAddress, userAddress);
    }

    function encryptU8(uint8 value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptU8(value, contractAddress, userAddress);
    }

    function encryptU16(uint16 value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptU16(value, contractAddress, userAddress);
    }

    function encryptU32(uint32 value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptU32(value, contractAddress, userAddress);
    }

    function encryptU64(uint64 value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptU64(value, contractAddress, userAddress);
    }

    function encryptU128(uint128 value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptU128(value, contractAddress, userAddress);
    }

    function encryptAddress(address value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptAddress(value, contractAddress, userAddress);
    }

    function encryptU256(uint256 value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptU256(value, contractAddress, userAddress);
    }

    function encryptBytes64(bytes calldata value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptBytes64(value, contractAddress, userAddress);
    }

    function encryptBytes128(bytes calldata value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptBytes128(value, contractAddress, userAddress);
    }

    function encryptBytes256(bytes calldata value, address contractAddress, address userAddress)
        external
        noGasMetering
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _encryptBytes256(value, contractAddress, userAddress);
    }

    // ====================================================================== //
    //
    //               🔒 Private: Encrypt shared functions 🔒
    //
    // ====================================================================== //

    function _encryptBool(bool value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.addBool(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptU4(uint8 value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.add4(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptU8(uint8 value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.add8(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptU16(uint16 value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.add16(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptU32(uint32 value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.add32(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptU64(uint64 value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.add64(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptU128(uint128 value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.add128(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptAddress(address value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.addAddress(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptU256(uint256 value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.add256(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptBytes64(bytes calldata value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.addBytes64(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptBytes128(bytes calldata value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.addBytes128(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    function _encryptBytes256(bytes calldata value, address contractAddress, address userAddress)
        private
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = _createEncryptedInput(contractAddress, userAddress);
        input.addBytes256(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    // ====================================================================== //
    //
    //            ⭐️ Cheat API: encrypt and allow without proof ⭐️
    //
    // ====================================================================== //

    function newEBool(bool value, address allowedAddress) external noGasMetering returns (ebool result) {
        (einput handle, bytes memory inputProof) = _encryptBool(value, address(this), msg.sender);
        result = TFHE.asEbool(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEUint4(uint8 value, address allowedAddress) external noGasMetering returns (euint4 result) {
        (einput handle, bytes memory inputProof) = _encryptU4(value, address(this), msg.sender);
        result = TFHE.asEuint4(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEUint8(uint8 value, address allowedAddress) external noGasMetering returns (euint8 result) {
        (einput handle, bytes memory inputProof) = _encryptU8(value, address(this), msg.sender);
        result = TFHE.asEuint8(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEUint16(uint16 value, address allowedAddress) external noGasMetering returns (euint16 result) {
        (einput handle, bytes memory inputProof) = _encryptU16(value, address(this), msg.sender);
        result = TFHE.asEuint16(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEUint32(uint32 value, address allowedAddress) external noGasMetering returns (euint32 result) {
        (einput handle, bytes memory inputProof) = _encryptU32(value, address(this), msg.sender);
        result = TFHE.asEuint32(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEUint64(uint64 value, address allowedAddress) external noGasMetering returns (euint64 result) {
        (einput handle, bytes memory inputProof) = _encryptU64(value, address(this), msg.sender);
        result = TFHE.asEuint64(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEUint128(uint128 value, address allowedAddress) external noGasMetering returns (euint128 result) {
        (einput handle, bytes memory inputProof) = _encryptU128(value, address(this), msg.sender);
        result = TFHE.asEuint128(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEAddress(address value, address allowedAddress) external noGasMetering returns (eaddress result) {
        (einput handle, bytes memory inputProof) = _encryptAddress(value, address(this), msg.sender);
        result = TFHE.asEaddress(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEUint256(uint256 value, address allowedAddress) external noGasMetering returns (euint256 result) {
        (einput handle, bytes memory inputProof) = _encryptU256(value, address(this), msg.sender);
        result = TFHE.asEuint256(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEBytes64(bytes calldata value, address allowedAddress)
        external
        noGasMetering
        returns (ebytes64 result)
    {
        (einput handle, bytes memory inputProof) = _encryptBytes64(value, address(this), msg.sender);
        result = TFHE.asEbytes64(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEBytes128(bytes calldata value, address allowedAddress)
        external
        noGasMetering
        returns (ebytes128 result)
    {
        (einput handle, bytes memory inputProof) = _encryptBytes128(value, address(this), msg.sender);
        result = TFHE.asEbytes128(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    function newEBytes256(bytes calldata value, address allowedAddress)
        external
        noGasMetering
        returns (ebytes256 result)
    {
        (einput handle, bytes memory inputProof) = _encryptBytes256(value, address(this), msg.sender);
        result = TFHE.asEbytes256(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }
}
