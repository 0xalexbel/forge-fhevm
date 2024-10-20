// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ACL} from "fhevm/lib/ACL.sol";
import {
    TFHE,
    ebool,
    euint4,
    euint8,
    euint16,
    euint32,
    euint64,
    eaddress,
    ebytes256,
    einput,
    Common
} from "fhevm/lib/TFHE.sol";

import {TFHEExecutorDB} from "./executor/TFHEExecutorDB.sol";

import {FhevmEnv} from "./vm/FhevmEnv.sol";
import {fhevmEnvAdd} from "./vm/FhevmEnvAddress.sol";
import {ReencryptLib} from "./reencrypt/Reencrypt.sol";

import {EncryptedInputSigner} from "./encrypted-input/EncryptedInputSigner.sol";
import {EncryptedInput} from "./encrypted-input/EncryptedInput.sol";

enum ArithmeticCheckingMode {
    Operands,
    OperandsAndResult
}

library fhevm {
    FhevmEnv private constant fhevmEnv = FhevmEnv(fhevmEnvAdd);

    function isCoprocessor() public view returns (bool) {
        return fhevmEnv.isCoprocessor();
    }

    function createEncryptedInput(address contractAddress, address userAddress)
        internal
        view
        returns (EncryptedInput memory)
    {
        return fhevmEnv.createEncryptedInput(contractAddress, userAddress);
    }

    /// Reencrypt function
    function generateKeyPair() public returns (bytes memory publicKey, bytes memory privateKey) {
        return ReencryptLib.generateKeyPair();
    }

    /// Reencrypt function
    function createEIP712Digest(bytes calldata publicKey, address contractAddress) public view returns (bytes32) {
        return ReencryptLib.createEIP712Digest(publicKey, block.chainid, contractAddress);
    }

    /// Reencrypt function
    function sign(bytes32 digest, uint256 signer) public pure returns (bytes memory signature) {
        return ReencryptLib.sign(digest, signer);
    }

    function _verifyReencryptSig(
        bytes memory, /*privateKey*/
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) private view {
        address signerAddr = ReencryptLib.verifySig(publicKey, block.chainid, contractAddress, signature);
        require(userAddress == signerAddr, "Invalid EIP-712 signature");
    }

    /// Reencrypt ebool value
    function reencryptBool(
        ebool value,
        bytes calldata privateKey,
        bytes calldata publicKey,
        bytes calldata signature,
        address contractAddress,
        address userAddress
    ) public view returns (bool) {
        uint256 handle = ebool.unwrap(value);
        require(handle != 0, "Handle is null");

        _verifyReencryptSig(privateKey, publicKey, signature, contractAddress, userAddress);

        return decryptBool(value, contractAddress, userAddress);
    }

    /// Reencrypt euint4 value
    function reencryptU4(
        euint4 value,
        bytes calldata privateKey,
        bytes calldata publicKey,
        bytes calldata signature,
        address contractAddress,
        address userAddress
    ) public view returns (uint8) {
        uint256 handle = euint4.unwrap(value);
        require(handle != 0, "Handle is null");

        _verifyReencryptSig(privateKey, publicKey, signature, contractAddress, userAddress);

        return decryptU4(value, contractAddress, userAddress);
    }

    /// Reencrypt euint8 value
    function reencryptU8(
        euint8 value,
        bytes calldata privateKey,
        bytes calldata publicKey,
        bytes calldata signature,
        address contractAddress,
        address userAddress
    ) public view returns (uint8) {
        uint256 handle = euint8.unwrap(value);
        require(handle != 0, "Handle is null");

        _verifyReencryptSig(privateKey, publicKey, signature, contractAddress, userAddress);

        return decryptU8(value, contractAddress, userAddress);
    }

    /*
    Missing : reencryptU16, reencryptU32, reencryptU128, reencryptU256, reencryptBytes256
    */

    /// Reencrypt euint64 value
    function reencryptU64(
        euint64 value,
        bytes calldata privateKey,
        bytes calldata publicKey,
        bytes calldata signature,
        address contractAddress,
        address userAddress
    ) public view returns (uint64) {
        uint256 handle = euint64.unwrap(value);
        require(handle != 0, "Handle is null");

        _verifyReencryptSig(privateKey, publicKey, signature, contractAddress, userAddress);

        return decryptU64(value, contractAddress, userAddress);
    }

    /// Helper: encrypts a single bool value and returns the handle+inputProof pair
    function encryptBool(bool value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.addBool(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single bool value using a given random salt and returns the handle+inputProof pair
    function encryptBool(bool value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.addBool(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint4 value and returns the handle+inputProof pair
    function encryptU4(uint8 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add4(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint4 value using a given random salt and returns the handle+inputProof pair
    function encryptU4(uint8 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add4(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint8 value and returns the handle+inputProof pair
    function encryptU8(uint8 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add8(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint8 value using a given random salt and returns the handle+inputProof pair
    function encryptU8(uint8 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add8(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint16 value and returns the handle+inputProof pair
    function encryptU16(uint16 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add16(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint16 value using a given random salt and returns the handle+inputProof pair
    function encryptU16(uint16 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add16(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint32 value and returns the handle+inputProof pair
    function encryptU32(uint32 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add32(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint32 value using a given random salt and returns the handle+inputProof pair
    function encryptU32(uint32 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add32(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint64 value and returns the handle+inputProof pair
    function encryptU64(uint64 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add64(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint64 value using a given random salt and returns the handle+inputProof pair
    function encryptU64(uint64 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add64(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint128 value and returns the handle+inputProof pair
    function encryptU128(uint128 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add128(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint128 value using a given random salt and returns the handle+inputProof pair
    function encryptU128(uint128 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add128(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint256 value and returns the handle+inputProof pair
    function encryptU256(uint256 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add256(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint256 value using a given random salt and returns the handle+inputProof pair
    function encryptU256(uint256 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.add256(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 64-bytes value and returns the handle+inputProof pair
    /// Fails if value.length > 64
    function encryptBytes64(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.addBytes64(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 64-bytes value using a given random salt and returns the handle+inputProof pair
    /// Fails if value.length > 64
    function encryptBytes64(bytes memory value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.addBytes64(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 128-bytes value and returns the handle+inputProof pair
    /// Fails if value.length > 128
    function encryptBytes128(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.addBytes128(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 128-bytes value using a given random salt and returns the handle+inputProof pair
    /// Fails if value.length > 128
    function encryptBytes128(bytes memory value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.addBytes128(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 256-bytes value and returns the handle+inputProof pair
    /// Fails if value.length > 256
    function encryptBytes256(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.addBytes256(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 256-bytes value using a given random salt and returns the handle+inputProof pair
    function encryptBytes256(bytes memory value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = fhevmEnv.createEncryptedInput(contractAddress, userAddress);
        input.addBytes256(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Decrypts an encrypted bool value given a contract and a user
    /// The function will fail if:
    /// - the contact does not have the permission to decrypt the value
    /// - the user does not have the permission to decrypt the value
    function decryptBool(ebool value, address contractAddress, address userAddress) public view returns (bool result) {
        uint256 handle = ebool.unwrap(value);
        if (handle == 0) {
            return false;
        }

        _onlyAllowedHandle(handle, contractAddress, userAddress);

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);
        return (entry.value != 0);
    }

    /// Decrypts an encrypted bool value given a contract and a user
    /// The function will fail if:
    /// - the contact does not have the permission to decrypt the value
    /// - the user does not have the permission to decrypt the value
    function decryptBoolStrict(ebool value, address contractAddress, address userAddress)
        public
        view
        returns (bool result)
    {
        uint256 handle = ebool.unwrap(value);

        _onlyArithmeticallyValidHandle(handle);
        _onlyAllowedHandle(handle, contractAddress, userAddress);

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);
        return (entry.value != 0);
    }

    /// Decrypts an encrypted uint8 value given a contract and a user
    /// The function will fail if:
    /// - the contact does not have the permission to decrypt the value
    /// - the user does not have the permission to decrypt the value
    function decryptU4(euint4 value, address contractAddress, address userAddress) public view returns (uint8 result) {
        uint256 handle = euint4.unwrap(value);
        if (handle == 0) {
            return 0;
        }

        _onlyAllowedHandle(handle, contractAddress, userAddress);

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);
        return uint8(entry.value);
    }

    function decryptU4Strict(euint4 value, address contractAddress, address userAddress)
        internal
        view
        returns (uint8 result)
    {
        uint256 handle = euint4.unwrap(value);

        _onlyArithmeticallyValidHandle(handle);
        _onlyAllowedHandle(handle, contractAddress, userAddress);

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);
        return uint8(entry.value);
    }

    /// Decrypts an encrypted uint8 value given a contract and a user
    /// The function will fail if:
    /// - the contact does not have the permission to decrypt the value
    /// - the user does not have the permission to decrypt the value
    function decryptU8(euint8 value, address contractAddress, address userAddress) public view returns (uint8 result) {
        uint256 handle = euint8.unwrap(value);
        if (handle == 0) {
            return 0;
        }

        _onlyAllowedHandle(handle, contractAddress, userAddress);

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);
        return uint8(entry.value);
    }

    function decryptU8Strict(euint8 value, address contractAddress, address userAddress)
        internal
        view
        returns (uint8 result)
    {
        uint256 handle = euint8.unwrap(value);

        _onlyArithmeticallyValidHandle(handle);
        _onlyAllowedHandle(handle, contractAddress, userAddress);

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);
        return uint8(entry.value);
    }

    /// Decrypts an encrypted uint64 value given a contract and a user
    /// The function will fail if:
    /// - the contact does not have the permission to decrypt the value
    /// - the user does not have the permission to decrypt the value
    function decryptU64(euint64 value, address contractAddress, address userAddress)
        public
        view
        returns (uint64 result)
    {
        uint256 handle = euint64.unwrap(value);
        if (handle == 0) {
            return 0;
        }

        _onlyAllowedHandle(handle, contractAddress, userAddress);

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);
        return uint64(entry.value);
    }

    /// Decrypts an encrypted uint64 value given a contract and a user
    /// The function will fail if:
    /// - the contact does not have the permission to decrypt the value
    /// - the user does not have the permission to decrypt the value
    function decryptU64Strict(euint64 value, address contractAddress, address userAddress)
        public
        view
        returns (uint64 result)
    {
        uint256 handle = euint64.unwrap(value);

        _onlyArithmeticallyValidHandle(handle);
        _onlyAllowedHandle(handle, contractAddress, userAddress);

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);
        return uint64(entry.value);
    }

    /// Decrypts an encrypted 256-bytes value given a contract and a user
    /// The function will fail if:
    /// - the contact does not have the permission to decrypt the value
    /// - the user does not have the permission to decrypt the value
    function decryptBytes256(ebytes256 value, address contractAddress, address userAddress)
        public
        view
        returns (bytes memory result)
    {
        uint256 handle = ebytes256.unwrap(value);
        if (handle == 0) {
            return "";
        }

        _onlyAllowedHandle(handle, contractAddress, userAddress);

        TFHEExecutorDB.Entry2048 memory entry = fhevmEnv.db().get2048(handle);
        return entry.value;
    }

    /*
    type ebool is uint256;
    type euint4 is uint256;
    type euint8 is uint256;
    type euint16 is uint256;
    type euint32 is uint256;
    type euint64 is uint256;
    type eaddress is uint256;
    type ebytes256 is uint256;
    type einput is bytes32;
    */

    /// Asserts that the `ebool` value is arithmetically valid.
    function assertArithmeticallyValid(ebool value) internal view {
        fhevmEnv.assertArithmeticallyValidHandle(ebool.unwrap(value));
    }

    /// Asserts that the `euint4` value is arithmetically valid.
    function assertArithmeticallyValid(euint4 value) internal view {
        fhevmEnv.assertArithmeticallyValidHandle(euint4.unwrap(value));
    }

    /// Asserts that the `euint8` value is arithmetically valid.
    function assertArithmeticallyValid(euint8 value) internal view {
        fhevmEnv.assertArithmeticallyValidHandle(euint8.unwrap(value));
    }

    /// Asserts that the `euint16` value is arithmetically valid.
    function assertArithmeticallyValid(euint16 value) internal view {
        fhevmEnv.assertArithmeticallyValidHandle(euint16.unwrap(value));
    }

    /// Asserts that the `euint32` value is arithmetically valid.
    function assertArithmeticallyValid(euint32 value) internal view {
        fhevmEnv.assertArithmeticallyValidHandle(euint32.unwrap(value));
    }

    /// Asserts that the `euint64` value is arithmetically valid.
    function assertArithmeticallyValid(euint64 value) internal view {
        fhevmEnv.assertArithmeticallyValidHandle(euint64.unwrap(value));
    }

    /// Asserts that the `eaddress` value is arithmetically valid.
    function assertArithmeticallyValid(eaddress value) internal view {
        fhevmEnv.assertArithmeticallyValidHandle(eaddress.unwrap(value));
    }

    function isArithmeticallyValid(ebool value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(ebool.unwrap(value));
    }

    function isArithmeticallyValid(euint4 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint4.unwrap(value));
    }

    function isArithmeticallyValid(euint8 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint8.unwrap(value));
    }

    function isArithmeticallyValid(euint16 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint16.unwrap(value));
    }

    function isArithmeticallyValid(euint32 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint32.unwrap(value));
    }

    function isArithmeticallyValid(euint64 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint64.unwrap(value));
    }

    function isArithmeticallyValid(eaddress value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(eaddress.unwrap(value));
    }

    function _isArithmeticallyValidHandle(uint256 handle) private view returns (bool) {
        if (handle == 0) {
            return false;
        }

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);
        if (entry.valueType == 0) {
            return false;
        }

        return !entry.divisionByZero && !entry.overflow && !entry.underflow;
    }

    function _onlyArithmeticallyValidHandle(uint256 handle) private view {
        require(handle != 0, "Handle is null");

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);

        require(entry.valueType != 0, "Handle does not exist");
        require(!entry.divisionByZero, "Handle inherits from a division by zero");
        require(!entry.overflow, "Handle inherits from an arithmetic overflow");
        require(!entry.underflow, "Handle inherits from an arithmetic underflow");
    }

    function _onlyAllowedHandle(uint256 handle, address contractAddress, address userAddress) internal view {
        require(
            fhevmEnv.acl().isAllowed(handle, contractAddress), "contract does not have permission to decrypt handle"
        );
        require(fhevmEnv.acl().isAllowed(handle, userAddress), "user does not have permission to decrypt handle");
    }

    function isTrivial(ebool value) internal view returns (bool) {
        return _isTrivialHandle(ebool.unwrap(value));
    }

    function isTrivial(euint4 value) internal view returns (bool) {
        return _isTrivialHandle(euint4.unwrap(value));
    }

    function isTrivial(euint8 value) internal view returns (bool) {
        return _isTrivialHandle(euint8.unwrap(value));
    }

    function isTrivial(euint16 value) internal view returns (bool) {
        return _isTrivialHandle(euint16.unwrap(value));
    }

    function isTrivial(euint32 value) internal view returns (bool) {
        return _isTrivialHandle(euint32.unwrap(value));
    }

    function isTrivial(euint64 value) internal view returns (bool) {
        return _isTrivialHandle(euint64.unwrap(value));
    }

    function isTrivial(eaddress value) internal view returns (bool) {
        return _isTrivialHandle(eaddress.unwrap(value));
    }

    function isTrivial(ebytes256 value) internal view returns (bool) {
        return _isTrivialHandle(ebytes256.unwrap(value));
    }

    function _isTrivialHandle(uint256 handle) private view returns (bool) {
        if (handle == 0) {
            return false;
        }

        TFHEExecutorDB.Entry256 memory entry = fhevmEnv.db().get256(handle);
        if (entry.valueType == 0) {
            return false;
        }

        return entry.trivial;
    }

    /// Check any arithmetic error in all subsequent fhevm operations with
    /// mode equal to 'ArithmeticCheckingMode.Operands'
    function startCheckArithmetic() public {
        fhevmEnv.db().startCheckArithmetic();
    }

    /// Check any arithmetic error in all subsequent fhevm operations.
    /// if mode = 'ArithmeticCheckingMode.Operands', test only applies to operands, for example c = a + b,
    /// both a and b are checked, c is ignored.
    /// if mode = 'ArithmeticCheckingMode.OperandsAndResult', test applies to both operands and result, for example c = a + b,
    /// a, b and c are all checked.
    function startCheckArithmetic(ArithmeticCheckingMode mode) public {
        fhevmEnv.db().startCheckArithmetic(uint8(mode));
    }

    /// Stops checking fhevm arithmetic errors.
    function stopCheckArithmetic() public {
        fhevmEnv.db().stopCheckArithmetic();
    }

    /// Check any arithmetic error in the next fhevm operation with
    /// mode equal to 'ArithmeticCheckingMode.Operands'
    function checkArithmetic() public {
        fhevmEnv.db().checkArithmetic();
    }

    /// Check any arithmetic error in the next fhevm operation
    /// using specified mode.
    function checkArithmetic(ArithmeticCheckingMode mode) public {
        fhevmEnv.db().checkArithmetic(uint8(mode));
    }
}
