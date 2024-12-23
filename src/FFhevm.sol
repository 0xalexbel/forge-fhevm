// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

//import {console} from "forge-std/src/console.sol";
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

import {FFhevmDebugConfigStruct} from "./libs/debugger/config/FFhevmDebugConfig.sol";

import "forge-fhevm-config/addresses.sol" as ADDRESSES;

import {IFFhevmGateway} from "./libs/forge/interfaces/IFFhevmGateway.sol";
import {IFFhevmInput} from "./libs/forge/interfaces/IFFhevmInput.sol";
import {IFFhevmReencrypt} from "./libs/forge/interfaces/IFFhevmReencrypt.sol";

import {EncryptedInputLib} from "./libs/forge/input/EncryptedInputLib.sol";
import {EncryptedInputList} from "./libs/forge/input/EncryptedInputList.sol";
import {EncryptedInputSigner} from "./libs/forge/input/EncryptedInputSigner.sol";

import {FFhevmSetUp} from "./libs/forge/FFhevmSetUp.sol";

import {
    FFHEVM_INPUT_PRECOMPILE_ADDRESS,
    FFHEVM_GATEWAY_PRECOMPILE_ADDRESS,
    FFHEVM_REENCRYPT_PRECOMPILE_ADDRESS
} from "./libs/forge/precompile/FFhevmPrecompileAddresses.sol";

struct EncryptedInput {
    EncryptedInputList _list;
    EncryptedInputSigner _signer;
    address _contractAddress;
    address _userAddress;
    address _debuggerAddress;
    address _debuggerDBAddress;
    address _randomGeneratorAddress;
}

using EncryptedInputLib for EncryptedInput global;

library FFhevm {
    struct Signer {
        uint256 privateKey;
        address addr;
    }

    struct DeployConfig {
        string mnemonic;
        uint256 numKmsSigners;
        bool isCoprocessor;
        Signer fhevmDeployer;
        Signer gatewayDeployer;
        Signer gatewayRelayer;
        Signer[] kmsSigners;
        Signer coprocessorAccount;
        /// Extra
        bool useDeterministicRandomGenerator;
        Signer ffhevmDebuggerDeployer;
        Signer randomGeneratorDeployer;
    }

    struct CoreAddresses {
        // Fhevm Core
        address ACLAddress;
        address TFHEExecutorAddress;
        address FHEGasLimitAddress;
        address KMSVerifierAddress;
        // InputVerifiers
        address InputVerifierNativeAddress;
        address InputVerifierCoprocessorAddress;
        address InputVerifierAddress;
    }

    struct GatewayAddresses {
        address GatewayContractAddress;
    }

    struct DebuggerAddresses {
        address TFHEDebuggerAddress;
        address TFHEDebuggerDBAddress;
    }

    struct Config {
        DeployConfig deployConfig;
        CoreAddresses core;
        GatewayAddresses gateway;
        DebuggerAddresses debugger;
        // Random generator
        address IRandomGeneratorAddress;
    }

    IFFhevmInput private constant _inputPc = IFFhevmInput(FFHEVM_INPUT_PRECOMPILE_ADDRESS);
    IFFhevmGateway private constant _gatewayPc = IFFhevmGateway(FFHEVM_GATEWAY_PRECOMPILE_ADDRESS);
    IFFhevmReencrypt private constant _reencryptPc = IFFhevmReencrypt(FFHEVM_REENCRYPT_PRECOMPILE_ADDRESS);

    function setUp() internal {
        FFhevmSetUp.setUpFullSuite();
    }

    function defaultFHEVMConfig() internal pure returns (FFhevmDebugConfigStruct memory) {
        return FFhevmDebugConfigStruct({
            ACLAddress: ADDRESSES.ACL_ADDRESS,
            TFHEExecutorAddress: ADDRESSES.TFHE_EXECUTOR_ADDRESS,
            InputVerifierAddress: ADDRESSES.INPUT_VERIFIER_ADDRESS,
            KMSVerifierAddress: ADDRESSES.KMS_VERIFIER_ADDRESS,
            // ffhevm addresses
            TFHEDebuggerAddress: ADDRESSES.FFHEVM_DEBUGGER_ADDRESS,
            TFHEDebuggerDBAddress: ADDRESSES.FFHEVM_DEBUGGER_DB_ADDRESS,
            forgeVmAddress: address(uint160(uint256(keccak256("hevm cheat code"))))
        });
    }

    function getConfig() internal returns (Config memory config) {
        config = _inputPc.getConfig();
    }

    function isCoprocessor() internal returns (bool) {
        return _inputPc.isCoprocessor();
    }

    function gatewayFulfillRequests() internal {
        _gatewayPc.fulfillRequests();
    }

    function createEncryptedInput(address contractAddress, address userAddress)
        internal
        returns (EncryptedInput memory input)
    {
        input = _inputPc.createEncryptedInput(contractAddress, userAddress);
    }

    function encryptBool(bool value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptBool(value, contractAddress, userAddress);
    }

    function encryptU4(uint8 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptU4(value, contractAddress, userAddress);
    }

    function encryptU8(uint8 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptU8(value, contractAddress, userAddress);
    }

    function encryptU16(uint16 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptU16(value, contractAddress, userAddress);
    }

    function encryptU32(uint32 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptU32(value, contractAddress, userAddress);
    }

    function encryptU64(uint64 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptU64(value, contractAddress, userAddress);
    }

    function encryptU128(uint128 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptU128(value, contractAddress, userAddress);
    }

    function encryptAddress(address value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptAddress(value, contractAddress, userAddress);
    }

    function encryptU256(uint256 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptU256(value, contractAddress, userAddress);
    }

    function encryptBytes64(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptBytes64(value, contractAddress, userAddress);
    }

    function encryptBytes128(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptBytes128(value, contractAddress, userAddress);
    }

    function encryptBytes256(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        (handle, inputProof) = _inputPc.encryptBytes256(value, contractAddress, userAddress);
    }

    function newEBool(bool value, address allowedAddress) internal returns (ebool result) {
        result = _inputPc.newEBool(value, allowedAddress);
    }

    function newEUint4(uint8 value, address allowedAddress) internal returns (euint4 result) {
        result = _inputPc.newEUint4(value, allowedAddress);
    }

    function newEUint8(uint8 value, address allowedAddress) internal returns (euint8 result) {
        result = _inputPc.newEUint8(value, allowedAddress);
    }

    function newEUint16(uint16 value, address allowedAddress) internal returns (euint16 result) {
        result = _inputPc.newEUint16(value, allowedAddress);
    }

    function newEUint32(uint32 value, address allowedAddress) internal returns (euint32 result) {
        result = _inputPc.newEUint32(value, allowedAddress);
    }

    function newEUint64(uint64 value, address allowedAddress) internal returns (euint64 result) {
        result = _inputPc.newEUint64(value, allowedAddress);
    }

    function newEUint128(uint128 value, address allowedAddress) internal returns (euint128 result) {
        result = _inputPc.newEUint128(value, allowedAddress);
    }

    function newEAddress(address value, address allowedAddress) internal returns (eaddress result) {
        result = _inputPc.newEAddress(value, allowedAddress);
    }

    function newEUint256(uint256 value, address allowedAddress) internal returns (euint256 result) {
        result = _inputPc.newEUint256(value, allowedAddress);
    }

    function newEBytes64(bytes memory value, address allowedAddress) internal returns (ebytes64 result) {
        result = _inputPc.newEBytes64(value, allowedAddress);
    }

    function newEBytes128(bytes memory value, address allowedAddress) internal returns (ebytes128 result) {
        result = _inputPc.newEBytes128(value, allowedAddress);
    }

    function newEBytes256(bytes memory value, address allowedAddress) internal returns (ebytes256 result) {
        result = _inputPc.newEBytes256(value, allowedAddress);
    }

    function generateKeyPair() internal returns (bytes memory publicKey, bytes memory privateKey) {
        (publicKey, privateKey) = _reencryptPc.generateKeyPair();
    }

    function createEIP712Digest(bytes memory publicKey, address contractAddress) internal returns (bytes32) {
        return _reencryptPc.createEIP712Digest(publicKey, contractAddress);
    }

    function sign(bytes32 digest, uint256 signer) internal returns (bytes memory signature) {
        signature = _reencryptPc.sign(digest, signer);
    }

    function reencryptBool(
        ebool value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (bool result) {
        result = _reencryptPc.reencryptBool(value, privateKey, publicKey, signature, contractAddress, userAddress);
    }

    function reencryptU4(
        euint4 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint8 result) {
        result = _reencryptPc.reencryptU4(value, privateKey, publicKey, signature, contractAddress, userAddress);
    }

    function reencryptU8(
        euint8 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint8 result) {
        result = _reencryptPc.reencryptU8(value, privateKey, publicKey, signature, contractAddress, userAddress);
    }

    function reencryptU16(
        euint16 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint16 result) {
        result = _reencryptPc.reencryptU16(value, privateKey, publicKey, signature, contractAddress, userAddress);
    }

    function reencryptU32(
        euint32 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint32 result) {
        result = _reencryptPc.reencryptU32(value, privateKey, publicKey, signature, contractAddress, userAddress);
    }

    function reencryptU64(
        euint64 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint64 result) {
        result = _reencryptPc.reencryptU64(value, privateKey, publicKey, signature, contractAddress, userAddress);
    }

    function reencryptU128(
        euint128 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint128 result) {
        result = _reencryptPc.reencryptU128(value, privateKey, publicKey, signature, contractAddress, userAddress);
    }

    function reencryptU256(
        euint256 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal returns (uint256 result) {
        result = _reencryptPc.reencryptU256(value, privateKey, publicKey, signature, contractAddress, userAddress);
    }
}
