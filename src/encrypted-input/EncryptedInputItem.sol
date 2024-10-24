// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Common} from "../../lib/TFHE.sol";
import {BytesLib} from "../utils/BytesLib.sol";

struct EncryptedInputItem {
    uint8 _type;
    uint16 _numBits;
    uint8 _index;
    bytes _data;
    uint256 _numericalValue;
    bytes _bytesValue;
}

library EncryptedInputItemLib {
    function handle(EncryptedInputItem memory self, bytes32 hashedData) public pure returns (bytes32) {
        bytes32 finalHash = keccak256(bytes.concat(hashedData, bytes1(self._index)));
        return (finalHash & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000)
            | (bytes32(uint256(self._index)) << 16) | (bytes32(uint256(self._type)) << 8);
    }

    function is256(EncryptedInputItem memory self) public pure returns (bool) {
        return (self._type <= Common.euint256_t);
    }

    function is2048(EncryptedInputItem memory self) public pure returns (bool) {
        return !is256(self);
    }

    function extract256(EncryptedInputItem memory self) public pure returns (uint256) {
        require(is256(self), "Element is not a 256 bits element");
        if (self._numBits <= 8) {
            return uint256(uint8(bytes1(self._data[1])));
        }
        if (self._numBits == 16) {
            return uint256(uint16(bytes2(self._data[1] & 0xFF) | (bytes2(self._data[2] & 0xFF) >> 8)));
        }
        if (self._numBits == 32) {
            return uint256(
                uint32(
                    bytes4(self._data[1] & 0xFF) | (bytes4(self._data[2] & 0xFF) >> 8)
                        | (bytes4(self._data[3] & 0xFF) >> 16) | (bytes4(self._data[4] & 0xFF) >> 24)
                )
            );
        }
        if (self._numBits == 64) {
            return uint256(
                uint64(
                    bytes8(self._data[1] & 0xFF) | (bytes8(self._data[2] & 0xFF) >> 8)
                        | (bytes8(self._data[3] & 0xFF) >> 16) | (bytes8(self._data[4] & 0xFF) >> 24)
                        | (bytes8(self._data[5] & 0xFF) >> 32) | (bytes8(self._data[6] & 0xFF) >> 40)
                        | (bytes8(self._data[7] & 0xFF) >> 48) | (bytes8(self._data[8] & 0xFF) >> 56)
                )
            );
        }
        if (self._numBits == 128) {
            return uint256(uint128(BytesLib.bytesToBytes16(self._data, 1)));
        }
        if (self._numBits == 256) {
            return uint256(BytesLib.bytesToBytes32(self._data, 1));
        }
        revert("Unknown element type");
    }

    function extract2048(EncryptedInputItem memory self) public pure returns (uint256[8] memory b2048) {
        require(is2048(self), "Element is not a 2048 bits element");
        require(
            self._numBits == 512 || self._numBits == 1024 || self._numBits == 2048,
            "Element num bits must be 512 or 1024 or 2048"
        );

        if (self._numBits >= 512) {
            b2048[0] = uint256(BytesLib.bytesToBytes32(self._data, 0 * 32 + 1));
            b2048[1] = uint256(BytesLib.bytesToBytes32(self._data, 1 * 32 + 1));
        }
        if (self._numBits >= 1024) {
            b2048[2] = uint256(BytesLib.bytesToBytes32(self._data, 2 * 32 + 1));
            b2048[3] = uint256(BytesLib.bytesToBytes32(self._data, 3 * 32 + 1));
        }
        if (self._numBits == 2048) {
            b2048[4] = uint256(BytesLib.bytesToBytes32(self._data, 4 * 32 + 1));
            b2048[5] = uint256(BytesLib.bytesToBytes32(self._data, 5 * 32 + 1));
            b2048[6] = uint256(BytesLib.bytesToBytes32(self._data, 6 * 32 + 1));
            b2048[7] = uint256(BytesLib.bytesToBytes32(self._data, 7 * 32 + 1));
        }
    }
}

using EncryptedInputItemLib for EncryptedInputItem global;
