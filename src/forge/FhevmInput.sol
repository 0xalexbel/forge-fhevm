// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {
    TFHE,
    einput,
    eaddress,
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
    ebytes256
} from "../debug/fhevm/lib/TFHE.sol";
import {Impl} from "../debug/fhevm/lib/Impl.sol";
import {FHEVMConfig} from "../debug/fhevm/lib/FHEVMConfig.sol";
import {FhevmDebugger} from "../debug/FhevmDebugger.sol";

import {GasMetering} from "../common/GasMetering.sol";
import {IRandomGenerator} from "../common/interfaces/IRandomGenerator.sol";

import {ACL} from "fhevm-core-contracts/contracts/ACL.sol";

import {
    IForgeStdVmSafe as IVmSafe,
    IForgeStdVmUnsafe as IVmUnsafe,
    forgeStdVmSafeAdd,
    forgeStdVmUnsafeAdd
} from "./interfaces/IForgeStdVm.sol";

import {ForgeFhevmConfig} from "./deploy/ForgeFhevmConfig.sol";
import {ForgeFhevmStorage, ForgeFhevmStorageLib} from "./deploy/ForgeFhevmStorage.sol";

import {ReencryptLib} from "./reencrypt/Reencrypt.sol";
import {EncryptedInput} from "./EncryptedInput.sol";

library FhevmInput {
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);
    IVmUnsafe private constant vmUnsafe = IVmUnsafe(forgeStdVmUnsafeAdd);

    function __getInputVerifierAddress() private view returns (address) {
        (bool success, bytes memory returnData) =
            Impl.getFHEVMConfig().TFHEExecutorAddress.staticcall(abi.encodeWithSignature("getInputVerifierAddress()"));
        if (!success || returnData.length == 0) {
            return address(0);
        }
        return abi.decode(returnData, (address));
    }

    function __getCoprocessorAddress() private view returns (address) {
        address ivAdd = __getInputVerifierAddress();
        if (ivAdd == address(0)) {
            return address(0);
        }
        (bool success, bytes memory returnData) = ivAdd.staticcall(abi.encodeWithSignature("getCoprocessorAddress()"));
        if (!success || returnData.length == 0) {
            return address(0);
        }

        return abi.decode(returnData, (address));
    }

    function __acl() private view returns (ACL) {
        return ACL(Impl.getFHEVMConfig().ACLAddress);
    }
// FhevmInput.createInstance()
// FhevmDebugger.decryptBoolStrict()
    function __randomGenerator() private view returns (IRandomGenerator) {
        ForgeFhevmStorage storage $ = ForgeFhevmStorageLib.get();
        return IRandomGenerator($.IRandomGeneratorAddress);
    }

    // ====================================================================== //
    //
    //                      ⭐️ Public API ⭐️
    //
    // ====================================================================== //

    function isCoprocessor() internal view returns (bool) {
        address coprocAddr = __getCoprocessorAddress();
        return (coprocAddr != address(0));
    }

    // ====================================================================== //
    //
    //                      ⭐️ API: Encrypt functions ⭐️
    //
    // ====================================================================== //

    function createEncryptedInput(address contractAddress, address userAddress)
        internal
        returns (EncryptedInput memory input)
    {
        GasMetering.pause(forgeStdVmSafeAdd);
        ForgeFhevmStorage storage $ = ForgeFhevmStorageLib.get();
        input = $.createEncryptedInput(contractAddress, userAddress);
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    /// Helper: encrypts a single bool value and returns the handle+inputProof pair
    function encryptBool(bool value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBool(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single bool value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptBool(bool value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBool(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 4-bits unsigned integer value and returns the handle+inputProof pair
    function encryptU4(uint8 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add4(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single 4-bits unsigned integer value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU4(uint8 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add4(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint8 value and returns the handle+inputProof pair
    function encryptU8(uint8 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add8(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint8 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU8(uint8 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add8(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint16 value and returns the handle+inputProof pair
    function encryptU16(uint16 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add16(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint16 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU16(uint16 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add16(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint32 value and returns the handle+inputProof pair
    function encryptU32(uint32 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add32(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint32 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU32(uint32 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add32(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint64 value and returns the handle+inputProof pair
    function encryptU64(uint64 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add64(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint64 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU64(uint64 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add64(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint128 value and returns the handle+inputProof pair
    function encryptU128(uint128 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add128(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint128 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU128(uint128 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add128(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint256 value and returns the handle+inputProof pair
    function encryptU256(uint256 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add256(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint256 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU256(uint256 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add256(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 64-bytes value and returns the handle+inputProof pair
    /// Fails if value.length > 64
    function encryptBytes64(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes64(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single 64-bytes value value using
    /// a given random salt and returns the handle+inputProof pair
    /// Fails if value.length > 64
    function encryptBytes64(bytes memory value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes64(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 128-bytes value and returns the handle+inputProof pair
    /// Fails if value.length > 128
    function encryptBytes128(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes128(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single 128-bytes value value using
    /// a given random salt and returns the handle+inputProof pair
    /// Fails if value.length > 128
    function encryptBytes128(bytes memory value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes128(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 256-bytes value and returns the handle+inputProof pair
    /// Fails if value.length > 256
    function encryptBytes256(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes256(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single 256-bytes value value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptBytes256(bytes memory value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes256(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    // ====================================================================== //
    //
    //            ⭐️ Cheat API: encrypt and allow without proof ⭐️
    //
    // ====================================================================== //

    function __getThisAddress() private returns (address) {
        (IVmUnsafe.CallerMode callerMode, address msgSender,) = vmUnsafe.readCallers();

        address thisAddress = address(this);
        if (uint8(callerMode) == 2 || uint8(callerMode) == 4) {
            thisAddress = msgSender;
        }
        return thisAddress;
    }

    /// Helper: encrypts a single bool value and give permanent TFHE permissions to 'allowedAddress'
    function newEBool(bool value, address allowedAddress) internal returns (ebool result) {
        (einput handle, bytes memory inputProof) = encryptBool(value, __getThisAddress(), msg.sender);
        result = TFHE.asEbool(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    /// Helper: encrypts a single uint8 value and give permanent TFHE permissions to 'allowedAddress'
    function newEUint4(uint8 value, address allowedAddress) internal returns (euint4 result) {
        (einput handle, bytes memory inputProof) = encryptU4(value, __getThisAddress(), msg.sender);
        result = TFHE.asEuint4(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    /// Helper: encrypts a single uint8 value and give permanent TFHE permissions to 'allowedAddress'
    function newEUint8(uint8 value, address allowedAddress) internal returns (euint8 result) {
        (einput handle, bytes memory inputProof) = encryptU8(value, __getThisAddress(), msg.sender);
        result = TFHE.asEuint8(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    /// Helper: encrypts a single uint16 value and give permanent TFHE permissions to 'allowedAddress'
    function newEUint16(uint16 value, address allowedAddress) internal returns (euint16 result) {
        (einput handle, bytes memory inputProof) = encryptU16(value, __getThisAddress(), msg.sender);
        result = TFHE.asEuint16(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    /// Helper: encrypts a single uint32 value and give permanent TFHE permissions to 'allowedAddress'
    function newEUint32(uint32 value, address allowedAddress) internal returns (euint32 result) {
        (einput handle, bytes memory inputProof) = encryptU32(value, __getThisAddress(), msg.sender);
        result = TFHE.asEuint32(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    /// Helper: encrypts a single uint64 value and give permanent TFHE permissions to 'allowedAddress'
    function newEUint64(uint64 value, address allowedAddress) internal returns (euint64 result) {
        (einput handle, bytes memory inputProof) = encryptU64(value, __getThisAddress(), msg.sender);
        result = TFHE.asEuint64(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    /// Helper: encrypts a single uint128 value and give permanent TFHE permissions to 'allowedAddress'
    function newEUint128(uint128 value, address allowedAddress) internal returns (euint128 result) {
        (einput handle, bytes memory inputProof) = encryptU128(value, __getThisAddress(), msg.sender);
        result = TFHE.asEuint128(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    /// Helper: encrypts a single uint128 value and give permanent TFHE permissions to 'allowedAddress'
    function newEUint256(uint128 value, address allowedAddress) internal returns (euint256 result) {
        (einput handle, bytes memory inputProof) = encryptU256(value, __getThisAddress(), msg.sender);
        result = TFHE.asEuint256(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    /// Helper: encrypts a single bytes 64 value and give permanent TFHE permissions to 'allowedAddress'
    function newEBytes64(bytes memory value, address allowedAddress) internal returns (ebytes64 result) {
        (einput handle, bytes memory inputProof) = encryptBytes64(value, __getThisAddress(), msg.sender);
        result = TFHE.asEbytes64(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    /// Helper: encrypts a single bytes 128 value and give permanent TFHE permissions to 'allowedAddress'
    function newEBytes128(bytes memory value, address allowedAddress) internal returns (ebytes128 result) {
        (einput handle, bytes memory inputProof) = encryptBytes128(value, __getThisAddress(), msg.sender);
        result = TFHE.asEbytes128(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    /// Helper: encrypts a single bytes 256 value and give permanent TFHE permissions to 'allowedAddress'
    function newEBytes256(bytes memory value, address allowedAddress) internal returns (ebytes256 result) {
        (einput handle, bytes memory inputProof) = encryptBytes256(value, __getThisAddress(), msg.sender);
        result = TFHE.asEbytes256(handle, inputProof);
        TFHE.allow(result, allowedAddress);
    }

    // ====================================================================== //
    //
    //                      ⭐️ API: Reencrypt ⭐️
    //
    // ====================================================================== //

    function generateKeyPair() internal returns (bytes memory publicKey, bytes memory privateKey) {
        return ReencryptLib.generateKeyPair(__randomGenerator());
    }

    function createEIP712Digest(bytes memory publicKey, address contractAddress) internal view returns (bytes32) {
        return ReencryptLib.createEIP712Digest(publicKey, block.chainid, contractAddress);
    }

    function sign(bytes32 digest, uint256 signer) internal pure returns (bytes memory signature) {
        return ReencryptLib.sign(digest, signer);
    }

    function reencryptBool(
        ebool value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (bool result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = ebool.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptBool(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    function reencryptU4(
        euint4 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint8 result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = euint4.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptU4(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    function reencryptU8(
        euint8 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint8 result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = euint8.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptU8(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    function reencryptU16(
        euint16 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint16 result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = euint16.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptU16(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    function reencryptU32(
        euint32 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint32 result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = euint32.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptU32(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    function reencryptU64(
        euint64 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint64 result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = euint64.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptU64(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    function reencryptU128(
        euint128 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint128 result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = euint128.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptU128(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    function reencryptU256(
        euint256 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint256 result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = euint256.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptU256(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    function reencryptBytes64(
        ebytes64 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (bytes memory result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = ebytes64.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptBytes64(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    function reencryptBytes128(
        ebytes128 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (bytes memory result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = ebytes128.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptBytes128(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }

    function reencryptBytes256(
        ebytes256 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (bytes memory result) {
        GasMetering.pause(forgeStdVmSafeAdd);
        {
            uint256 handle = ebytes256.unwrap(value);
            vm.assertNotEq(handle, 0, "Handle is null");

            ReencryptLib.assertValidEIP712Sig(
                privateKey, publicKey, signature, block.chainid, contractAddress, userAddress
            );

            result = FhevmDebugger.decryptBytes256(value, contractAddress, userAddress);
        }
        GasMetering.resume(forgeStdVmSafeAdd);
    }
}
