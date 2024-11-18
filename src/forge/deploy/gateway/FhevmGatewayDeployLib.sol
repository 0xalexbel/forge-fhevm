// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {GatewayContract} from "../../../debug/fhevm/gateway/GatewayContract.sol";
import {FHEVMConfig} from "../../../debug/fhevm/lib/FHEVMConfig.sol";

import {FhevmGatewayAddressesLib} from "./FhevmGatewayAddressesLib.sol";

library FhevmGatewayDeployLib {
    struct FhevmGatewayDeployment {
        address GatewayContractAddress;
    }

    function deployFhevmGateway(address deployerAddr, address relayerAddr)
        internal
        returns (FhevmGatewayDeployment memory)
    {
        FhevmGatewayDeployment memory res;

        // Deploy order:
        // 1. GatewayContract
        // 2. addRelayer
        GatewayContract gc = deployGatewayContract(deployerAddr);
        gc.initialize(deployerAddr);
        gc.addRelayer(relayerAddr);

        res.GatewayContractAddress = address(gc);

        return res;
    }

    /// Deploy a new GatewayContract contract using the specified deployer wallet
    function deployGatewayContract(address deployerAddr) private returns (GatewayContract) {
        (address expectedImplAddr, address expectedAddr) =
            FhevmGatewayAddressesLib.expectedCreateGatewayContractAddress(deployerAddr);

        GatewayContract impl = new GatewayContract();
        require(address(impl) == expectedImplAddr, "deployGatewayContract: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployGatewayContract: unexpected proxy deploy address");

        GatewayContract _gc = GatewayContract(address(proxy));

        return _gc;
    }
}
