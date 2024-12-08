// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {
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

import {IFFhevmBase} from "./IFFhevmBase.sol";

interface IFFhevmReencrypt is IFFhevmBase {
    function generateKeyPair() external returns (bytes memory publicKey, bytes memory privateKey);
    function createEIP712Digest(bytes memory publicKey, address contractAddress) external returns (bytes32);
    function sign(bytes32 digest, uint256 signer) external returns (bytes memory signature);

    function reencryptBool(
        ebool value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (bool result);

    function reencryptU4(
        euint4 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (uint8 result);

    function reencryptU8(
        euint8 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (uint8 result);

    function reencryptU16(
        euint16 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (uint16 result);

    function reencryptU32(
        euint32 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (uint32 result);

    function reencryptU64(
        euint64 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (uint64 result);

    function reencryptU128(
        euint128 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (uint128 result);

    function reencryptAddress(
        eaddress value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (address result);

    function reencryptU256(
        euint256 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (uint256 result);

    function reencryptBytes64(
        ebytes64 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (bytes memory result);

    function reencryptBytes128(
        ebytes128 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (bytes memory result);

    function reencryptBytes256(
        ebytes256 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) external returns (bytes memory result);
}
