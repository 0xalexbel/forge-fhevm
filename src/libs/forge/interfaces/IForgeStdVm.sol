// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

address constant forgeStdVmSafeAdd = address(uint160(uint256(keccak256("hevm cheat code"))));
address constant forgeStdVmUnsafeAdd = address(uint160(uint256(keccak256("hevm cheat code"))));

interface IForgeStdVmSafe {
    struct Wallet {
        address addr;
        uint256 publicKeyX;
        uint256 publicKeyY;
        uint256 privateKey;
    }

    function getNonce(address account) external returns (uint64);
    function envExists(string calldata name) external view returns (bool result);
    function envString(string calldata name) external view returns (string memory value);
    function indexOf(string calldata input, string calldata key) external pure returns (uint256);
    function parseUint(string calldata stringifiedValue) external pure returns (uint256 parsedValue);
    function parseBool(string calldata stringifiedValue) external pure returns (bool parsedValue);
    function parseAddress(string calldata stringifiedValue) external pure returns (address parsedValue);
    function randomUint() external returns (uint256);
    function rememberKey(uint256 privateKey) external returns (address);
    function createWallet(string calldata walletLabel) external returns (Wallet memory wallet);
    function createWallet(uint256 privateKey) external returns (Wallet memory wallet);
    function sign(uint256 privateKey, bytes32 digest) external pure returns (uint8 v, bytes32 r, bytes32 s);
    function broadcast(address signer) external;
    function broadcast(uint256 privateKey) external;
    function startBroadcast(uint256 privateKey) external;
    function startBroadcast(address signer) external;
    function stopBroadcast() external;
    function toString(uint256 value) external pure returns (string memory stringifiedValue);
    function toString(address value) external pure returns (string memory stringifiedValue);
    function toString(bytes32 value) external pure returns (string memory stringifiedValue);
    function addr(uint256 privateKey) external pure returns (address keyAddr);
    function writeFile(string calldata path, string calldata data) external;
    function computeCreateAddress(address deployer, uint256 nonce) external pure returns (address);
    function rpc(string calldata method, string calldata params) external returns (bytes memory data);
    function getDeployedCode(string calldata artifactPath) external view returns (bytes memory runtimeBytecode);

    // ======== Testing ========

    function assertTrue(bool condition, string calldata error) external pure;
    function assertFalse(bool condition, string calldata error) external pure;
    function assertNotEq(uint256 left, uint256 right, string calldata error) external pure;
    function assertEq(address left, address right, string calldata error) external pure;
    function assertEq(uint256 left, uint256 right, string calldata error) external pure;
    function assertEq(bytes calldata left, bytes calldata right, string calldata error) external pure;

    // ======== Gas metering ========

    function pauseGasMetering() external;
    function resumeGasMetering() external;
}

interface IForgeStdVmUnsafe is IForgeStdVmSafe {
    enum CallerMode {
        None,
        Broadcast,
        RecurrentBroadcast,
        Prank,
        RecurrentPrank
    }

    function readCallers() external returns (CallerMode callerMode, address msgSender, address txOrigin);
    function startPrank(address msgSender, address txOrigin) external;
    function stopPrank() external;
    //function allowCheatcodes(address account) external;
    function etch(address target, bytes calldata newRuntimeBytecode) external;
}
