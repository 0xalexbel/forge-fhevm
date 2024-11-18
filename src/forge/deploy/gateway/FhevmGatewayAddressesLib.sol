// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {GATEWAY_CONTRACT_PREDEPLOY_ADDRESS} from "../../../debug/fhevm/gateway/lib/GatewayContractAddress.sol";
import {AddressLib} from "../../utils/AddressLib.sol";

/// Note: forge does not handle libraries very well in a script setUp context.
/// Therefore, solidity code like this one is deployed as a contract instead of a library
library FhevmGatewayAddressesLib {
    uint8 private constant GatewayContractImplNonce = 0;
    uint8 private constant GatewayContractNonce = 1;

    /// Returns a tuple of two addresses:
    /// - the computed 'GatewayContract' contact implementation address
    /// - the 'GatewayContract' contract address
    /// Fails if the 'GatewayContract' contact address differs from the value of 'GATEWAY_CONTRACT_PREDEPLOY_ADDRESS' stored in
    /// the 'fhevm/gateway/lib/GatewayContractAddress.sol' solidity file.
    function expectedCreateGatewayContractAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, GatewayContractImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, GatewayContractNonce);

        require(
            GATEWAY_CONTRACT_PREDEPLOY_ADDRESS == expectedAddr,
            "GatewayContract contract address differs from its expected create address. Address solidity files must be regenerated."
        );
    }

    function computeCreateGatewayContractAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, GatewayContractNonce);
    }
}
