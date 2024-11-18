// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import "fhevm-core-contracts/addresses/ACLAddress.sol";
import "fhevm-core-contracts/addresses/FHEPaymentAddress.sol";
import "fhevm-core-contracts/addresses/KMSVerifierAddress.sol";
import "fhevm-core-contracts/addresses/TFHEExecutorAddress.sol";

//forge-fhevm Debugger
import "../../addresses/TFHEDebuggerAddress.sol";

library FHEVMConfig {
    struct FHEVMConfigStruct {
        address ACLAddress;
        address TFHEExecutorAddress;
        address FHEPaymentAddress;
        address KMSVerifierAddress;
        //forge-fhevm Debugger
        address TFHEDebuggerAddress;
        address forgeVmAddress;
    }

    // - Returns false if debugger is not yet deployed
    function __useForgeVm() private view returns (bool) {
        (bool success, bytes memory returnData) = tfheDebuggerAdd.staticcall(abi.encodeWithSignature("useForgeVm()"));
        if (!success || returnData.length == 0) {
            return false;
        }
        return abi.decode(returnData, (bool));
    }

    /// @dev Function to return an immutable struct
    function defaultConfig() internal view returns (FHEVMConfigStruct memory) {
        address forgeVmAddress = address(0);
        if (__useForgeVm()) {
            forgeVmAddress = address(uint160(uint256(keccak256("hevm cheat code"))));
        }

        return FHEVMConfigStruct({
            ACLAddress: aclAdd,
            TFHEExecutorAddress: tfheExecutorAdd,
            FHEPaymentAddress: fhePaymentAdd,
            KMSVerifierAddress: kmsVerifierAdd,
            //forge-fhevm Debugger
            TFHEDebuggerAddress: tfheDebuggerAdd,
            forgeVmAddress: forgeVmAddress
        });
    }
}
