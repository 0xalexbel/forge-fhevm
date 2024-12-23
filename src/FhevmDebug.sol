// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {
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
} from "./libs/fhevm-debug/lib/TFHE.sol";
import {Impl} from "./libs/fhevm-debug/lib/Impl.sol";
import {GasMetering} from "./libs/fhevm-debug/lib/GasMetering.sol";

import {IACL} from "./libs/core/interfaces/IACL.sol";

import {IFhevmDebugger} from "./libs/debugger/interfaces/IFhevmDebugger.sol";
import {IFhevmDebuggerDB} from "./libs/debugger/interfaces/IFhevmDebuggerDB.sol";

//import {console} from "forge-std/src/console.sol";

library FhevmDebug {
    /// Warning! 'enum ArithmeticCheckMode' must be equal to 'IFhevmDebugger.ArithmeticCheckMode'
    enum ArithmeticCheckMode {
        OperandsOnly,
        OperandsAndResult,
        ResultOnly
    }

    modifier noGasMetering() {
        address forgeVmAddress = __forgeVmAddress();
        GasMetering.pause(forgeVmAddress);

        _;

        GasMetering.resume(forgeVmAddress);
    }

    // ====================================================================== //
    //
    //                             🚦 Errors 🚦
    //
    // ====================================================================== //

    error ContractAddressNotPermanentlyAllowed(uint256 handle, address contractAddress);
    error UserAddressNotPermanentlyAllowed(uint256 handle, address userAddress);
    error ContractAddressEqualToUserAddress(uint256 handle, address contractAddress);
    error NullHandle();

    // ====================================================================== //
    //
    //                      🔒 Private Getters 🔒
    //
    // ====================================================================== //

    function __dbg() private view returns (IFhevmDebugger) {
        return IFhevmDebugger(Impl.getFHEVMConfig().TFHEDebuggerAddress);
    }

    function __db() private view returns (IFhevmDebuggerDB) {
        return IFhevmDebuggerDB(Impl.getFHEVMConfig().TFHEDebuggerDBAddress);
    }

    function __acl() private view returns (IACL) {
        return IACL(Impl.getFHEVMConfig().ACLAddress);
    }

    function __forgeVmAddress() private view returns (address) {
        return Impl.getFHEVMConfig().forgeVmAddress;
    }

    // ====================================================================== //
    //
    //                  ⭐️ API: getClear cheat functions ⭐️
    //
    // ====================================================================== //

    function getClear(ebool value) internal view returns (bool) {
        return __db().getBool(ebool.unwrap(value));
    }

    function getClear(euint4 value) internal view returns (uint8) {
        return __db().getU4(euint4.unwrap(value));
    }

    function getClear(euint8 value) internal view returns (uint8) {
        return __db().getU8(euint8.unwrap(value));
    }

    function getClear(euint16 value) internal view returns (uint16) {
        return __db().getU16(euint16.unwrap(value));
    }

    function getClear(euint32 value) internal view returns (uint32) {
        return __db().getU32(euint32.unwrap(value));
    }

    function getClear(euint64 value) internal view returns (uint64) {
        return __db().getU64(euint64.unwrap(value));
    }

    function getClear(euint128 value) internal view returns (uint128) {
        return __db().getU128(euint128.unwrap(value));
    }

    function getClear(euint256 value) internal view returns (uint256) {
        return __db().getU256(euint256.unwrap(value));
    }

    function getClear(ebytes64 value) internal view returns (bytes memory) {
        return __db().getBytes64(ebytes64.unwrap(value));
    }

    function getClear(ebytes128 value) internal view returns (bytes memory) {
        return __db().getBytes128(ebytes128.unwrap(value));
    }

    function getClear(ebytes256 value) internal view returns (bytes memory) {
        return __db().getBytes256(ebytes256.unwrap(value));
    }

    // ====================================================================== //
    //
    //                     ⭐️ API: Decrypt functions ⭐️
    //
    // ====================================================================== //

    /**
     * @dev Decrypts an encrypted boolean value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptBool(ebool value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (bool result)
    {
        uint256 handle = ebool.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getBool(handle);
    }

    /**
     * @dev Decrypts an encrypted boolean value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero/overfow/underflow)
     */
    function decryptBoolStrict(ebool value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (bool result)
    {
        uint256 handle = ebool.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getBool(handle);
    }

    /**
     * @dev Decrypts an encrypted 4bits unsigned integer value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptU4(euint4 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint8 result)
    {
        uint256 handle = euint4.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU4(handle);
    }

    /**
     * @dev Decrypts an encrypted 4bits unsigned integer value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero/overfow/underflow)
     */
    function decryptU4Strict(euint4 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint8 result)
    {
        uint256 handle = euint4.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU4(handle);
    }

    /**
     * @dev Decrypts an encrypted uint8 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptU8(euint8 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint8 result)
    {
        uint256 handle = euint8.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU8(handle);
    }

    /**
     * @dev Decrypts an encrypted uint8 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero/overfow/underflow)
     */
    function decryptU8Strict(euint8 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint8 result)
    {
        uint256 handle = euint8.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU8(handle);
    }

    /**
     * @dev Decrypts an encrypted uint16 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptU16(euint16 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint16 result)
    {
        uint256 handle = euint16.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU16(handle);
    }

    /**
     * @dev Decrypts an encrypted uint16 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero/overfow/underflow)
     */
    function decryptU16Strict(euint16 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint16 result)
    {
        uint256 handle = euint16.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU16(handle);
    }

    /**
     * @dev Decrypts an encrypted uint32 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptU32(euint32 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint32 result)
    {
        uint256 handle = euint32.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU32(handle);
    }

    /**
     * @dev Decrypts an encrypted uint32 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero/overfow/underflow)
     */
    function decryptU32Strict(euint32 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint32 result)
    {
        uint256 handle = euint32.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU32(handle);
    }

    /**
     * @dev Decrypts an encrypted uint64 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptU64(euint64 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint64 result)
    {
        uint256 handle = euint64.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU64(handle);
    }

    /**
     * @dev Decrypts an encrypted uint64 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero/overfow/underflow)
     */
    function decryptU64Strict(euint64 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint64 result)
    {
        uint256 handle = euint64.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU64(handle);
    }

    /**
     * @dev Decrypts an encrypted uint128 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptU128(euint128 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint128 result)
    {
        uint256 handle = euint128.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU128(handle);
    }

    /**
     * @dev Decrypts an encrypted uint128 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero/overfow/underflow)
     */
    function decryptU128Strict(euint128 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint128 result)
    {
        uint256 handle = euint128.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU128(handle);
    }

    /**
     * @dev Decrypts an encrypted address value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptAddress(eaddress value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (address result)
    {
        uint256 handle = eaddress.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getAddress(handle);
    }

    /**
     * @dev Decrypts an encrypted address value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero/overfow/underflow)
     */
    function decryptAddressStrict(eaddress value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (address result)
    {
        uint256 handle = eaddress.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getAddress(handle);
    }

    /**
     * @dev Decrypts an encrypted uint256 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptU256(euint256 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint256 result)
    {
        uint256 handle = euint256.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU256(handle);
    }

    /**
     * @dev Decrypts an encrypted uint256 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero/overfow/underflow)
     */
    function decryptU256Strict(euint256 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (uint256 result)
    {
        uint256 handle = euint256.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getU256(handle);
    }

    /**
     * @dev Decrypts an encrypted 64-bytes value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptBytes64(ebytes64 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (bytes memory result)
    {
        uint256 handle = ebytes64.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getBytes64(handle);
    }

    /**
     * @dev Decrypts an encrypted 128-bytes value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptBytes128(ebytes128 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (bytes memory result)
    {
        uint256 handle = ebytes128.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getBytes128(handle);
    }

    /**
     * @dev Decrypts an encrypted 256-bytes value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the user address and the contract address are equal
     */
    function decryptBytes256(ebytes256 value, address contractAddress, address userAddress)
        internal
        noGasMetering
        returns (bytes memory result)
    {
        uint256 handle = ebytes256.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        result = __db().getBytes256(handle);
    }

    // ====================================================================== //
    //
    //               ⭐️ API: Arithmetic checking functions ⭐️
    //
    // ====================================================================== //

    /// Asserts that the `ebool` value is arithmetically valid.
    function assertArithmeticallyValid(ebool value) internal view {
        __assertArithmeticallyValidHandle(ebool.unwrap(value));
    }

    /// Asserts that the `euint4` value is arithmetically valid.
    function assertArithmeticallyValid(euint4 value) internal view {
        __assertArithmeticallyValidHandle(euint4.unwrap(value));
    }

    /// Asserts that the `euint8` value is arithmetically valid.
    function assertArithmeticallyValid(euint8 value) internal view {
        __assertArithmeticallyValidHandle(euint8.unwrap(value));
    }

    /// Asserts that the `euint16` value is arithmetically valid.
    function assertArithmeticallyValid(euint16 value) internal view {
        __assertArithmeticallyValidHandle(euint16.unwrap(value));
    }

    /// Asserts that the `euint32` value is arithmetically valid.
    function assertArithmeticallyValid(euint32 value) internal view {
        __assertArithmeticallyValidHandle(euint32.unwrap(value));
    }

    /// Asserts that the `euint64` value is arithmetically valid.
    function assertArithmeticallyValid(euint64 value) internal view {
        __assertArithmeticallyValidHandle(euint64.unwrap(value));
    }

    /// Asserts that the `eaddress` value is arithmetically valid.
    function assertArithmeticallyValid(eaddress value) internal view {
        __assertArithmeticallyValidHandle(eaddress.unwrap(value));
    }

    /// Asserts that the `euint128` value is arithmetically valid.
    function assertArithmeticallyValid(euint128 value) internal view {
        __assertArithmeticallyValidHandle(euint128.unwrap(value));
    }

    /// Asserts that the `euint256` value is arithmetically valid.
    function assertArithmeticallyValid(euint256 value) internal view {
        __assertArithmeticallyValidHandle(euint256.unwrap(value));
    }

    function isArithmeticallyValid(ebool value) internal view returns (bool) {
        return __isArithmeticallyValidHandle(ebool.unwrap(value));
    }

    function isArithmeticallyValid(euint4 value) internal view returns (bool) {
        return __isArithmeticallyValidHandle(euint4.unwrap(value));
    }

    function isArithmeticallyValid(euint8 value) internal view returns (bool) {
        return __isArithmeticallyValidHandle(euint8.unwrap(value));
    }

    function isArithmeticallyValid(euint16 value) internal view returns (bool) {
        return __isArithmeticallyValidHandle(euint16.unwrap(value));
    }

    function isArithmeticallyValid(euint32 value) internal view returns (bool) {
        return __isArithmeticallyValidHandle(euint32.unwrap(value));
    }

    function isArithmeticallyValid(euint64 value) internal view returns (bool) {
        return __isArithmeticallyValidHandle(euint64.unwrap(value));
    }

    function isArithmeticallyValid(eaddress value) internal view returns (bool) {
        return __isArithmeticallyValidHandle(eaddress.unwrap(value));
    }

    function isArithmeticallyValid(euint128 value) internal view returns (bool) {
        return __isArithmeticallyValidHandle(euint128.unwrap(value));
    }

    function isArithmeticallyValid(euint256 value) internal view returns (bool) {
        return __isArithmeticallyValidHandle(euint256.unwrap(value));
    }

    /// Check any arithmetic error in all subsequent fhevm operations with
    /// mode equal to 'ArithmeticCheckMode.Operands'
    function startArithmeticCheck() internal {
        __dbg().startArithmeticCheck();
    }

    /// Check any arithmetic error in all subsequent fhevm operations.
    /// if mode = 'ArithmeticCheckMode.Operands', test only applies to operands, for example c = a + b,
    /// both a and b are checked, c is ignored.
    /// if mode = 'ArithmeticCheckMode.OperandsAndResult', test applies to both operands and result, 
    /// for example if c = a + b: a, b and c are all checked.
    function startArithmeticCheck(ArithmeticCheckMode mode) internal {
        __dbg().startArithmeticCheck(IFhevmDebugger.ArithmeticCheckMode(uint8(mode)));
    }

    /// Stops checking fhevm arithmetic errors.
    function stopArithmeticCheck() internal {
        __dbg().stopArithmeticCheck();
    }

    /// Check any arithmetic error in the next fhevm operation with
    /// mode equal to 'ArithmeticCheckMode.Operands'
    function checkArithmetic() internal {
        __dbg().checkArithmetic();
    }

    /// Check any arithmetic error in the next fhevm operation
    /// using specified mode.
    function checkArithmetic(ArithmeticCheckMode mode) internal {
        __dbg().checkArithmetic(IFhevmDebugger.ArithmeticCheckMode(uint8(mode)));
    }

    // ====================================================================== //
    //
    //                ⭐️ API : Trivial testing functions ⭐️
    //
    // ====================================================================== //

    function isTrivial(ebool value) internal view returns (bool) {
        return __isTrivialHandle(ebool.unwrap(value));
    }

    function isTrivial(euint4 value) internal view returns (bool) {
        return __isTrivialHandle(euint4.unwrap(value));
    }

    function isTrivial(euint8 value) internal view returns (bool) {
        return __isTrivialHandle(euint8.unwrap(value));
    }

    function isTrivial(euint16 value) internal view returns (bool) {
        return __isTrivialHandle(euint16.unwrap(value));
    }

    function isTrivial(euint32 value) internal view returns (bool) {
        return __isTrivialHandle(euint32.unwrap(value));
    }

    function isTrivial(euint64 value) internal view returns (bool) {
        return __isTrivialHandle(euint64.unwrap(value));
    }

    function isTrivial(euint128 value) internal view returns (bool) {
        return __isTrivialHandle(euint128.unwrap(value));
    }

    function isTrivial(euint256 value) internal view returns (bool) {
        return __isTrivialHandle(euint256.unwrap(value));
    }

    function isTrivial(eaddress value) internal view returns (bool) {
        return __isTrivialHandle(eaddress.unwrap(value));
    }

    function isTrivial(ebytes64 value) internal view returns (bool) {
        return __isTrivialHandle(ebytes64.unwrap(value));
    }

    function isTrivial(ebytes128 value) internal view returns (bool) {
        return __isTrivialHandle(ebytes128.unwrap(value));
    }

    function isTrivial(ebytes256 value) internal view returns (bool) {
        return __isTrivialHandle(ebytes256.unwrap(value));
    }

    function __isTrivialHandle(uint256 handle) private view returns (bool) {
        return __db().isTrivial(handle);
    }

    // ====================================================================== //
    //
    //                  📦 Private testing functions 📦
    //
    // ====================================================================== //

    function __isArithmeticallyValidHandle(uint256 handle) private view returns (bool) {
        return __db().isArithmeticallyValid(handle);
    }

    function __assertDecryptAllowed(uint256 handle, address contractAddress, address userAddress) private view {
        if (handle == 0) {
            revert NullHandle();
        }
        if (userAddress == contractAddress) {
            // userAddress should not be equal to contractAddress when requesting reencryption!
            revert ContractAddressEqualToUserAddress(handle, contractAddress);
        }
        IACL acl = __acl();
        if (!acl.persistAllowed(handle, contractAddress)) {
            revert ContractAddressNotPermanentlyAllowed(handle, contractAddress);
        }
        if (!acl.persistAllowed(handle, userAddress)) {
            revert UserAddressNotPermanentlyAllowed(handle, userAddress);
        }
    }

    function __assertArithmeticallyValidHandle(uint256 handle) private view {
        __db().checkHandle(handle);
    }
}
