// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import "ffhevm-config/addresses.sol" as ADDRESSES;
import {FHEVMConfigStruct} from "fhevm/lib/Impl.sol";
import {TFHE} from "fhevm/lib/TFHE.sol";

/**
 * @title   FHEVMConfig
 * @notice  This library returns all addresses for the ACL, TFHEExecutor, FHEPayment,
 *          and KMSVerifier contracts.
 */
library FHEVMConfig {
    /**
     * @notice This function returns a struct containing all contract addresses.
     * @dev    It returns an immutable struct.
     */
    function defaultConfig() internal pure returns (FHEVMConfigStruct memory) {
        return
            FHEVMConfigStruct({
                ACLAddress: ADDRESSES.ACL_ADDRESS,
                TFHEExecutorAddress: ADDRESSES.TFHE_EXECUTOR_ADDRESS,
                FHEPaymentAddress: ADDRESSES.FHE_PAYMENT_ADDRESS,
                KMSVerifierAddress: ADDRESSES.KMS_VERIFIER_ADDRESS
            });
    }
}

contract MockZamaFHEVMConfig {
    constructor() {
        TFHE.setFHEVM(FHEVMConfig.defaultConfig());
    }
}
