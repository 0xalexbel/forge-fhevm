// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {ICoreContract} from "./ICoreContract.sol";

interface IGatewayContract is ICoreContract {
    function requestDecryption(
        uint256[] calldata ctsHandles,
        bytes4 callbackSelector,
        uint256 msgValue,
        uint256 maxTimestamp,
        bool passSignaturesToCaller
    ) external returns (uint256 initialCounter);
    function getCounter() external returns (uint256);
    function fulfillRequest(uint256 requestID, bytes memory decryptedCts, bytes[] memory signatures) external payable;
    function getDecryptionRequest(uint256 requestID)
        external
        returns (uint256[] memory cts, uint256 msgValue, bool passSignaturesToCaller);
    function isRelayer(address account) external returns (bool);
    function addRelayer(address relayerAddress) external;
}
