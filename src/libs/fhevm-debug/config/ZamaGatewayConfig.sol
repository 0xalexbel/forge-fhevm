// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {Gateway} from "../gateway/lib/Gateway.sol";
import {GATEWAY_CONTRACT_ADDRESS} from "forge-fhevm-config/addresses.sol";

/**
 * @title   ZamaGatewayConfig.
 * @notice  This library returns the Gateway config for different networks
 *          with the address of the Gateway contract, which is
 *          deployed & maintained by Zama.
 */
library ZamaGatewayConfig {
    function getSepoliaConfig() internal pure returns (address) {
        return GATEWAY_CONTRACT_ADDRESS;
    }

    function getEthereumConfig() internal pure returns (address) {
        /// TODO
    }
}

/**
 * @title   SepoliaZamaGatewayConfig
 * @dev     This contract can be inherited by a contract wishing to use the Gateway service
 *          provided by Zama on the Sepolia network (chainId = 11155111).
 *          Other providers may offer other Gateways that are deployed at different addresses.
 *          If you wish to use them, you should rely on the instructions from these providers.
 */
contract SepoliaZamaGatewayConfig {
    constructor() {
        Gateway.setGateway(ZamaGatewayConfig.getSepoliaConfig());
    }
}

/**
 * @title   EthereumZamaGatewayConfig
 * @dev     This contract can be inherited by a contract wishing to use the Gateway service
 *          provided by Zama on the Ethereum (mainnet) network (chainId = 1).
 *          Other providers may offer other Gateways that are deployed at different addresses.
 *          If you wish to use them, you should rely on the instructions from these providers.
 */
contract EthereumZamaGatewayConfig {
    constructor() {
        Gateway.setGateway(ZamaGatewayConfig.getEthereumConfig());
    }
}
