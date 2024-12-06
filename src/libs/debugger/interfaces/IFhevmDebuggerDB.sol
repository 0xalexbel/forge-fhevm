// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

interface IFhevmDebuggerDB {
    function debugger() external view returns (address);

    /// Performs extensive handle checking
    function checkHandle(uint256 handle) external view;

    /// Only checks if handle exists
    function checkHandleExist(uint256 handle, uint8 typeCt) external view;

    function exist(uint256 handle) external view returns (bool);
    function isTrivial(uint256 handle) external view returns (bool);
    function isArithmeticallyValid(uint256 handle) external view returns (bool);

    /// ===== getters DB (readlony) =====

    function getNumAsBytes32(uint256 handle) external view returns (bytes32);
    function getBool(uint256 handle) external view returns (bool);
    function getU4(uint256 handle) external view returns (uint8);
    function getU8(uint256 handle) external view returns (uint8);
    function getU16(uint256 handle) external view returns (uint16);
    function getU32(uint256 handle) external view returns (uint32);
    function getU64(uint256 handle) external view returns (uint64);
    function getU128(uint256 handle) external view returns (uint128);
    function getAddress(uint256 handle) external view returns (address);
    function getU256(uint256 handle) external view returns (uint256);
    function getBytes64(uint256 handle) external view returns (bytes memory);
    function getBytes128(uint256 handle) external view returns (bytes memory);
    function getBytes256(uint256 handle) external view returns (bytes memory);
    function getBytes(uint256 handle) external view returns (bytes memory);
}
