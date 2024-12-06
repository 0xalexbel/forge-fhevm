// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {AddressLib} from "../../../common/AddressLib.sol";

import {FFhevm} from "../../../../FFhevm.sol";

import {EnvLib} from "../../utils/EnvLib.sol";
import {DeployError} from "../error.sol";

import "./constants.sol" as CONST;

library GatewayAddressesLib {
    function checkGatewayContractAddress(address addr) internal pure {
        require(
            CONST.GATEWAY_CONTRACT_ADDRESS == addr,
            DeployError.message("GatewayContract", CONST.GATEWAY_CONTRACT_ADDRESS, addr)
        );
    }

    function expectedCreateGatewayContractAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce)
    {
        expectedImplNonce = CONST.GatewayContractImplNonce;
        expectedNonce = CONST.GatewayContractNonce;
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, expectedImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, expectedNonce);

        require(
            CONST.GATEWAY_CONTRACT_ADDRESS == expectedAddr,
            DeployError.message(
                "GatewayContract", CONST.GATEWAY_CONTRACT_ADDRESS, expectedAddr, deployerAddr, expectedNonce
            )
        );
    }

    function computeCreateGatewayContractAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, CONST.GatewayContractNonce);
    }

    function computeAddresses(address deployerAddr)
        internal
        pure
        returns (FFhevm.GatewayAddresses memory gatewayAddresses)
    {
        gatewayAddresses.GatewayContractAddress = computeCreateGatewayContractAddress(deployerAddr);
    }

    function readEnvAddresses() internal view returns (FFhevm.GatewayAddresses memory) {
        FFhevm.GatewayAddresses memory gatewayAddresses;

        gatewayAddresses.GatewayContractAddress = EnvLib.envAddressOr(CONST.GatewayContractAddressEnvName, address(0));

        if (gatewayAddresses.GatewayContractAddress == address(0)) {
            return gatewayAddresses;
        }

        if (gatewayAddresses.GatewayContractAddress == address(0)) {
            revert("Missing GatewayContract contract address env value");
        } else {
            checkGatewayContractAddress(gatewayAddresses.GatewayContractAddress);
        }

        return gatewayAddresses;
    }
}
