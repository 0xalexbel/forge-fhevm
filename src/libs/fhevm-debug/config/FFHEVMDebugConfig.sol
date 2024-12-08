// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-fhevm-config/addresses.sol" as ADDRESSES;
import {FFhevmDebugConfigStruct} from "../../debugger/config/FFhevmDebugConfig.sol";
import {TFHE} from "../lib/TFHE.sol";
import {Gateway} from "../gateway/lib/Gateway.sol";

library FFHEVMDebugConfig {
    function defaultConfig() internal pure returns (FFhevmDebugConfigStruct memory) {
        return FFhevmDebugConfigStruct({
            ACLAddress: ADDRESSES.ACL_ADDRESS,
            TFHEExecutorAddress: ADDRESSES.TFHE_EXECUTOR_ADDRESS,
            FHEPaymentAddress: ADDRESSES.FHE_PAYMENT_ADDRESS,
            KMSVerifierAddress: ADDRESSES.KMS_VERIFIER_ADDRESS,
            // ffhevm addresses
            TFHEDebuggerAddress: ADDRESSES.FFHEVM_DEBUGGER_ADDRESS,
            TFHEDebuggerDBAddress: ADDRESSES.FFHEVM_DEBUGGER_DB_ADDRESS,
            forgeVmAddress: address(uint160(uint256(keccak256("hevm cheat code"))))
        });
    }
}

contract DefaultFFHEVMDebugConfig {
    constructor() {
        TFHE.setFHEVM(FFHEVMDebugConfig.defaultConfig());
        Gateway.setGateway(ADDRESSES.GATEWAY_CONTRACT_ADDRESS);
    }
}
