// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {FFhevm} from "../../../../FFhevm.sol";

import {GatewayContract} from "../../../core/gateway/GatewayContract.sol";

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "../../interfaces/IForgeStdVm.sol";

import {GatewayAddressesLib} from "./GatewayAddressesLib.sol";
import {GatewayContractVersion} from "./constants.sol";

library GatewayDeployLib {
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    /// @notice Deploy a new set of fhevm gateway contracts
    /// @dev Do not call this function inside a startBroadcast/stopBroadcast block
    function deployFhevmGateway(address deployerAddr, address relayerAddr)
        internal
        returns (FFhevm.GatewayAddresses memory addresses)
    {
        // Deploy order:
        // 1. GatewayContract
        // 2. addRelayer
        GatewayContract gc = _deployGatewayContract(deployerAddr);

        if (!gc.isRelayer(relayerAddr)) {
            vm.startBroadcast(deployerAddr);
            {
                gc.addRelayer(relayerAddr);
            }
            vm.stopBroadcast();
        }

        addresses.GatewayContractAddress = address(gc);
    }

    function _isVersion(address contractAddress, string memory contractVersion) private view returns (bool) {
        (bool success, bytes memory returnData) = contractAddress.staticcall(abi.encodeWithSignature("getVersion()"));
        if (!success || returnData.length == 0) {
            return false;
        }
        string memory version = abi.decode(returnData, (string));
        return keccak256(abi.encode(version)) == keccak256(abi.encode(contractVersion));
    }

    /// Deploy a new GatewayContract contract using the specified deployer wallet
    function _deployGatewayContract(address deployerAddr) private returns (GatewayContract) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            GatewayAddressesLib.expectedCreateGatewayContractAddress(deployerAddr);

        if (_isVersion(expectedAddr, GatewayContractVersion)) {
            return GatewayContract(expectedAddr);
        }

        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr),
            expectedImplNonce,
            "deploy GatewayContract contract implementation: unexpected nonce"
        );

        // Deploy GatewayContract implementation
        vm.broadcast(deployerAddr);
        GatewayContract impl = new GatewayContract();

        // Verify deployed contract address
        vm.assertEq(
            address(impl), expectedImplAddr, "deploy GatewayContract contract implementation: unexpected deploy address"
        );
        // Verify nonce
        vm.assertEq(vm.getNonce(deployerAddr), expectedNonce, "deploy GatewayContract contract proxy: unexpected nonce");

        // Deploy GatewayContract proxy
        vm.broadcast(deployerAddr);
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(address)", deployerAddr));

        // Verify deployed contract address
        vm.assertEq(address(proxy), expectedAddr, "deploy GatewayContract contract proxy: unexpected deploy address");
        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr),
            expectedNonce + 1,
            "deploy GatewayContract contract proxy: unexpected final nonce"
        );

        GatewayContract _gc = GatewayContract(address(proxy));

        // Verify owner
        vm.assertEq(_gc.owner(), deployerAddr, "deploy GatewayContract contract: unexpected owner");

        return _gc;
    }
}
