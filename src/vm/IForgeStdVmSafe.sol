// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

address constant forgeStdVmSafeAdd = address(uint160(uint256(keccak256("hevm cheat code"))));

interface IForgeStdVmSafe {
    struct Wallet {
        address addr;
        uint256 publicKeyX;
        uint256 publicKeyY;
        uint256 privateKey;
    }

    function envExists(string calldata name) external view returns (bool result);
    function envString(string calldata name) external view returns (string memory value);
    function indexOf(string calldata input, string calldata key) external pure returns (uint256);
    function parseUint(string calldata stringifiedValue) external pure returns (uint256 parsedValue);
    function parseBool(string calldata stringifiedValue) external pure returns (bool parsedValue);
    function randomUint() external returns (uint256);
    function createWallet(string calldata walletLabel) external returns (Wallet memory wallet);
    function createWallet(uint256 privateKey) external returns (Wallet memory wallet);
    function sign(uint256 privateKey, bytes32 digest) external pure returns (uint8 v, bytes32 r, bytes32 s);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
    function toString(uint256 value) external pure returns (string memory stringifiedValue);
    function toString(address value) external pure returns (string memory stringifiedValue);
    function toString(bytes32 value) external pure returns (string memory stringifiedValue);
    function addr(uint256 privateKey) external pure returns (address keyAddr);
    function writeFile(string calldata path, string calldata data) external;
    function computeCreateAddress(address deployer, uint256 nonce) external pure returns (address);

    // ======== Testing ========

    function assertTrue(bool condition, string calldata error) external pure;
    function assertFalse(bool condition, string calldata error) external pure;
    function assertNotEq(uint256 left, uint256 right, string calldata error) external pure;
    function assertEq(address left, address right, string calldata error) external pure;
}
