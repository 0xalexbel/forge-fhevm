// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {TFHE} from "../lib/TFHE.sol";
import {FFhevmDebugConfigStruct} from "../../debugger/config/FFhevmDebugConfig.sol";

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
            ACLAddress: 0x9479B455904dCccCf8Bc4f7dF8e9A1105cBa2A8e,
            TFHEExecutorAddress: 0x199fB61DFdfE46f9F90C9773769c28D9623Bb90e,
            FHEPaymentAddress: 0x25FE5d92Ae6f89AF37D177cF818bF27EDFe37F7c,
            KMSVerifierAddress: 0x904Af2B61068f686838bD6257E385C2cE7a09195,
            TFHEDebuggerAddress: address(0),
            TFHEDebuggerDBAddress: address(0),
            forgeVmAddress: address(0)
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
