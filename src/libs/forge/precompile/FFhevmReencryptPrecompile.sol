// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {IRandomGenerator} from "../../common/interfaces/IRandomGenerator.sol";
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
import {ReencryptLib} from "../reencrypt/ReencryptLib.sol";
import {IFFhevmReencrypt} from "../interfaces/IFFhevmReencrypt.sol";
import {FFhevmPrecompile} from "./FFhevmPrecompile.sol";

import {FhevmDebug} from "../../../FhevmDebug.sol";
import {FFhevm} from "../../../FFhevm.sol";

contract FFhevmReencryptPrecompile is FFhevmPrecompile, IFFhevmReencrypt, IRandomGenerator {
    uint256 private _randCounter;

    //keccak256("FFhevmReencryptPrecompile")
    bytes32 constant RANDSEED = 0x19381a0b494905fcd43aab651b6fd0f84b83179cbe2c80c3026da0c9835130ea;

    constructor(FFhevm.Config memory fhevmConfig) FFhevmPrecompile(fhevmConfig) {}

    function randomUint() external noGasMetering returns (uint256) {
        bytes32 pseudoRand = keccak256(bytes.concat(RANDSEED, bytes32(_randCounter)));
        _randCounter += 1;
        return uint256(pseudoRand);
    }

    function generateKeyPair() external noGasMetering returns (bytes memory publicKey, bytes memory privateKey) {
        address rndGenAddr = _config().IRandomGeneratorAddress;
        if (rndGenAddr == address(0)) {
            rndGenAddr = address(this);
        }
        return ReencryptLib.generateKeyPair(IRandomGenerator(rndGenAddr));
    }

    function createEIP712Digest(bytes memory publicKey, address contractAddress)
        external
        noGasMetering
        returns (bytes32)
    {
        return ReencryptLib.createEIP712Digest(publicKey, block.chainid, contractAddress);
    }

    function sign(bytes32 digest, uint256 signer) external noGasMetering returns (bytes memory signature) {
        return ReencryptLib.sign(digest, signer);
    }

    function reencryptBool(
        ebool value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (bool result) {
        uint256 handle = ebool.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptBool(value, contractAddress, userAddress);
    }

    function reencryptU4(
        euint4 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (uint8 result) {
        uint256 handle = euint4.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptU4(value, contractAddress, userAddress);
    }

    function reencryptU8(
        euint8 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (uint8 result) {
        uint256 handle = euint8.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptU8(value, contractAddress, userAddress);
    }

    function reencryptU16(
        euint16 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (uint16 result) {
        uint256 handle = euint16.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptU16(value, contractAddress, userAddress);
    }

    function reencryptU32(
        euint32 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (uint32 result) {
        uint256 handle = euint32.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptU32(value, contractAddress, userAddress);
    }

    function reencryptU64(
        euint64 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (uint64 result) {
        uint256 handle = euint64.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptU64(value, contractAddress, userAddress);
    }

    function reencryptU128(
        euint128 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (uint128 result) {
        uint256 handle = euint128.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptU128(value, contractAddress, userAddress);
    }

    function reencryptAddress(
        eaddress value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (address result) {
        uint256 handle = eaddress.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptAddress(value, contractAddress, userAddress);
    }

    function reencryptU256(
        euint256 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (uint256 result) {
        uint256 handle = euint256.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptU256(value, contractAddress, userAddress);
    }

    function reencryptBytes64(
        ebytes64 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (bytes memory result) {
        uint256 handle = ebytes64.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptBytes64(value, contractAddress, userAddress);
    }

    function reencryptBytes128(
        ebytes128 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (bytes memory result) {
        uint256 handle = ebytes128.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptBytes128(value, contractAddress, userAddress);
    }

    function reencryptBytes256(
        ebytes256 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external noGasMetering returns (bytes memory result) {
        uint256 handle = ebytes256.unwrap(value);
        vmSafe.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        result = FhevmDebug.decryptBytes256(value, contractAddress, userAddress);
    }
}
