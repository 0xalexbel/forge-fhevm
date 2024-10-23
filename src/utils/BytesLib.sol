// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

library BytesLib {
    function bytesToBytes1(bytes memory b, uint16 offset) internal pure returns (bytes1) {
        require(offset + 1 <= b.length, "out of bounds");
        return b[offset];
    }

    function bytesToBytes2(bytes memory b, uint16 offset) internal pure returns (bytes2) {
        require(offset + 2 <= b.length, "out of bounds");
        return _unsafeReadBytes2Offset(b, offset);
    }

    function bytesToBytes4(bytes memory b, uint16 offset) internal pure returns (bytes4) {
        require(offset + 4 <= b.length, "out of bounds");
        return _unsafeReadBytes4Offset(b, offset);
    }

    function bytesToBytes8(bytes memory b, uint16 offset) internal pure returns (bytes8) {
        require(offset + 8 <= b.length, "out of bounds");
        return _unsafeReadBytes8Offset(b, offset);
    }

    function bytesToBytes16(bytes memory b, uint16 offset) internal pure returns (bytes16) {
        require(offset + 16 <= b.length, "out of bounds");
        return _unsafeReadBytes16Offset(b, offset);
    }

    function bytesToBytes20(bytes memory b, uint16 offset) internal pure returns (bytes20) {
        require(offset + 20 <= b.length, "out of bounds");
        return _unsafeReadBytes20Offset(b, offset);
    }

    function bytesToBytes32(bytes memory b, uint16 offset) internal pure returns (bytes32) {
        require(offset + 32 <= b.length, "out of bounds");
        return _unsafeReadBytes32Offset(b, offset);
    }

    function _unsafeReadBytes2Offset(bytes memory buffer, uint256 offset) private pure returns (bytes2 value) {
        // This is not memory safe in the general case, but all calls to this private function are within bounds.
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    }

    function _unsafeReadBytes4Offset(bytes memory buffer, uint256 offset) private pure returns (bytes4 value) {
        // This is not memory safe in the general case, but all calls to this private function are within bounds.
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    }

    function _unsafeReadBytes8Offset(bytes memory buffer, uint256 offset) private pure returns (bytes8 value) {
        // This is not memory safe in the general case, but all calls to this private function are within bounds.
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    }

    function _unsafeReadBytes16Offset(bytes memory buffer, uint256 offset) private pure returns (bytes16 value) {
        // This is not memory safe in the general case, but all calls to this private function are within bounds.
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    }

    function _unsafeReadBytes20Offset(bytes memory buffer, uint256 offset) private pure returns (bytes20 value) {
        // This is not memory safe in the general case, but all calls to this private function are within bounds.
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    }

    function _unsafeReadBytes32Offset(bytes memory buffer, uint256 offset) private pure returns (bytes32 value) {
        // This is not memory safe in the general case, but all calls to this private function are within bounds.
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    }
}
