// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {FFhevm, FFhevmDebugConfigStruct} from "../src/FFhevm.sol";

/**
 * @title   FHEVMConfig
 * @notice  This library returns all addresses for the ACL, TFHEExecutor, FHEGasLimit,
 *          and KMSVerifier contracts.
 */
library FHEVMConfig {
    /**
     * @notice This function returns a struct containing all contract addresses.
     * @dev    It returns an immutable struct.
     */
    function defaultConfig() internal pure returns (FFhevmDebugConfigStruct memory) {
        return FFhevm.defaultFHEVMConfig();
    }
}
