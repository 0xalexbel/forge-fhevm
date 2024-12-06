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

import {EncryptedInput} from "../../../FFhevm.sol";

import {IFFhevmBase} from "./IFFhevmBase.sol";

interface IFFhevmInput is IFFhevmBase {
    function createEncryptedInput(address contractAddress, address userAddress)
        external
        returns (EncryptedInput memory input);

    function encryptBool(bool value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptU4(uint8 value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptU8(uint8 value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptU16(uint16 value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptU32(uint32 value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptU64(uint64 value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptU128(uint128 value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptU256(uint256 value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptBytes64(bytes calldata value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptBytes128(bytes calldata value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptBytes256(bytes calldata value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function encryptAddress(address value, address contractAddress, address userAddress)
        external
        returns (einput handle, bytes memory inputProof);

    function newEBool(bool value, address allowedAddress) external returns (ebool result);
    function newEUint4(uint8 value, address allowedAddress) external returns (euint4 result);
    function newEUint8(uint8 value, address allowedAddress) external returns (euint8 result);
    function newEUint16(uint16 value, address allowedAddress) external returns (euint16 result);
    function newEUint32(uint32 value, address allowedAddress) external returns (euint32 result);
    function newEUint64(uint64 value, address allowedAddress) external returns (euint64 result);
    function newEUint128(uint128 value, address allowedAddress) external returns (euint128 result);
    function newEUint256(uint256 value, address allowedAddress) external returns (euint256 result);
    function newEAddress(address value, address allowedAddress) external returns (eaddress result);
    function newEBytes64(bytes calldata value, address allowedAddress) external returns (ebytes64 result);
    function newEBytes128(bytes calldata value, address allowedAddress) external returns (ebytes128 result);
    function newEBytes256(bytes calldata value, address allowedAddress) external returns (ebytes256 result);
}
