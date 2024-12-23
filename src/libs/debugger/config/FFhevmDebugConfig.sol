// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

/**
 * @title   FFhevmDebugConfigStruct
 * @notice  This struct is a debug version of its counterpart 'FHEVMConfigStruct'.
 */
struct FFhevmDebugConfigStruct {
    address ACLAddress;
    address TFHEExecutorAddress;
    address FHEGasLimitAddress;
    address KMSVerifierAddress;
    // FFhevm addresses
    address TFHEDebuggerAddress;
    address TFHEDebuggerDBAddress;
    address forgeVmAddress;
}
