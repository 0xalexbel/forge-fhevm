// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {FFhevm} from "../../../../FFhevm.sol";
import {AddressLib} from "../../../common/AddressLib.sol";

import {GatewayContract} from "../../../core/gateway/GatewayContract.sol";
import {IGatewayContract} from "../../../core/interfaces/IGatewayContract.sol";
import {ICoreContract} from "../../../core/interfaces/ICoreContract.sol";

import {
    IForgeStdVmSafe as IVmSafe,
    IForgeStdVmUnsafe as IVmUnsafe,
    forgeStdVmSafeAdd,
    forgeStdVmUnsafeAdd
} from "../../interfaces/IForgeStdVm.sol";

import {GatewayAddressesLib} from "./GatewayAddressesLib.sol";
import {GatewayContractVersion, GatewayDeployerDefaultPK} from "./constants.sol";

library GatewayDeployLib {
    // solhint-disable const-name-snakecase
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);
    // solhint-disable const-name-snakecase
    IVmUnsafe private constant vmUnsafe = IVmUnsafe(forgeStdVmUnsafeAdd);

    /// @notice Deploy a new set of fhevm gateway contracts
    /// @dev Do not call this function inside a startBroadcast/stopBroadcast block
    function deployFhevmGateway(FFhevm.Signer memory deployer, address relayerAddr)
        internal
        returns (FFhevm.GatewayAddresses memory addresses)
    {
        bool useNonce = true;
        if (deployer.privateKey == 0) {
            useNonce = false;
            if (deployer.addr == address(0)) {
                deployer.addr = vm.rememberKey(GatewayDeployerDefaultPK);
                deployer.privateKey = GatewayDeployerDefaultPK;
            }
        }

        // Deploy order:
        // 1. GatewayContract
        // 2. addRelayer
        IGatewayContract gc = _deployGatewayContract(deployer, useNonce);

        if (!gc.isRelayer(relayerAddr)) {
            vm.startBroadcast(deployer.addr);
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

    function _deployGatewayContractWithNonce(address deployerAddr) private returns (IGatewayContract) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            GatewayAddressesLib.expectedCreateGatewayContractAddress(deployerAddr);

        if (_isVersion(expectedAddr, GatewayContractVersion)) {
            return IGatewayContract(expectedAddr);
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

        IGatewayContract _gc = IGatewayContract(address(proxy));

        // Verify owner
        vm.assertEq(
            AddressLib.getOwner(address(_gc)), deployerAddr, "deploy GatewayContract contract: unexpected owner"
        );

        return _gc;
    }

    function _deployGatewayContract(FFhevm.Signer memory deployer, bool useNonce) private returns (IGatewayContract) {
        return (deployer.privateKey != 0 && useNonce)
            ? _deployGatewayContractWithNonce(deployer.addr)
            : _deployGatewayContractNoNonce(deployer.addr);
    }

    function _deployGatewayContractNoNonce(address ownerAddr) private returns (IGatewayContract) {
        address expectedAddr = GatewayAddressesLib.expectedGatewayContractAddress();
        _deployCoreContractAt("GatewayContract", "GatewayContract.sol", expectedAddr, ownerAddr, GatewayContractVersion);
        return IGatewayContract(expectedAddr);
    }

    function _deployCoreContractAt(
        string memory contractName,
        string memory contractFilename,
        address expectedAddr,
        address ownerAddr,
        string memory expectedVersion
    ) private {
        if (_isVersion(expectedAddr, expectedVersion)) {
            return;
        }

        ///
        /// !! WARNING !! use the modified version of GatewayContract.sol located in forge artifacts.
        /// !! DO NOT DEPLOY !! fhevm-core-contracts/gateway/GatewayContract.sol
        ///
        string memory path = string.concat("./out/", contractFilename, "/", contractName, ".json");
        bytes memory code = vm.getDeployedCode(path);

        vmUnsafe.etch(expectedAddr, code);
        vm.assertEq(expectedAddr.code, code, "Failed to deploy gateway contract");

        ICoreContract coreContract = ICoreContract(expectedAddr);
        coreContract.initialize(ownerAddr);
    }
}
