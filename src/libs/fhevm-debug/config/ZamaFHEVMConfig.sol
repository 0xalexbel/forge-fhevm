// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {TFHE} from "../lib/TFHE.sol";
import {FFhevmDebugConfigStruct} from "../../debugger/config/FFhevmDebugConfig.sol";
import {
    ACL_ADDRESS,
    TFHE_EXECUTOR_ADDRESS,
    FHE_PAYMENT_ADDRESS,
    KMS_VERIFIER_ADDRESS,
    FFHEVM_DEBUGGER_ADDRESS,
    FFHEVM_DEBUGGER_DB_ADDRESS
} from "forge-fhevm-config/addresses.sol";

/**
 * @title   ZamaFHEVMConfig.
 * @notice  This library returns the TFHE config for different networks
 *          with the contract addresses for
 *          (1) ACL, (2) TFHEExecutor, (3) FHEPayment, (4) KMSVerifier,
 *          which are deployed & maintained by Zama.
 */
library ZamaFHEVMConfig {
    function getSepoliaConfig() internal pure returns (FFhevmDebugConfigStruct memory) {
        return FFhevmDebugConfigStruct({
            ACLAddress: ACL_ADDRESS,
            TFHEExecutorAddress: TFHE_EXECUTOR_ADDRESS,
            FHEPaymentAddress: FHE_PAYMENT_ADDRESS,
            KMSVerifierAddress: KMS_VERIFIER_ADDRESS,
            TFHEDebuggerAddress: FFHEVM_DEBUGGER_ADDRESS,
            TFHEDebuggerDBAddress: FFHEVM_DEBUGGER_DB_ADDRESS,
            forgeVmAddress: address(uint160(uint256(keccak256("hevm cheat code"))))
        });
    }

    function getEthereumConfig() internal pure returns (FFhevmDebugConfigStruct memory) {
        /// TODO
    }
}

/**
 * @title   SepoliaZamaFHEVMConfig.
 * @dev     This contract can be inherited by a contract wishing to use the FHEVM contracts provided by Zama
 *          on the Sepolia network (chainId = 11155111).
 *          Other providers may offer similar contracts deployed at different addresses.
 *          If you wish to use them, you should rely on the instructions from these providers.
 */
contract SepoliaZamaFHEVMConfig {
    constructor() {
        TFHE.setFHEVM(ZamaFHEVMConfig.getSepoliaConfig());
    }
}

/**
 * @title   EthereumZamaFHEVMConfig.
 * @dev     This contract can be inherited by a contract wishing to use the FHEVM contracts provided by Zama
 *          on the Ethereum (mainnet) network (chainId = 1).
 *          Other providers may offer similar contracts deployed at different addresses.
 *          If you wish to use them, you should rely on the instructions from these providers.
 */
contract EthereumZamaFHEVMConfig {
    constructor() {
        TFHE.setFHEVM(ZamaFHEVMConfig.getEthereumConfig());
    }
}
