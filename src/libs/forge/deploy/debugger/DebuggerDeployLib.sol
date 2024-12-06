// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {TFHEDebugger} from "../../../debugger/impl/TFHEDebugger.sol";
import {TFHEDebuggerDB} from "../../../debugger/impl/TFHEDebuggerDB.sol";

import {FFhevm} from "../../../../FFhevm.sol";

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "../../interfaces/IForgeStdVm.sol";

import {DebuggerAddressesLib} from "./DebuggerAddressesLib.sol";

import {TFHEDebuggerVersion, TFHEDebuggerDBVersion} from "./constants.sol";

//import {console} from "forge-std/src/console.sol";

library DebuggerDeployLib {
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    /// @notice Deploy a new set of fhevm debugger contracts
    /// @dev Do not call this function inside a startBroadcast/stopBroadcast block
    function deployFhevmDebugger(address deployerAddr, address randomGeneratorAddress)
        internal
        returns (FFhevm.DebuggerAddresses memory addresses)
    {
        TFHEDebugger _tfheDebugger = _deployTFHEDebugger(deployerAddr, randomGeneratorAddress);
        TFHEDebuggerDB _tfheDebuggerDB = _deployTFHEDebuggerDB(deployerAddr, address(_tfheDebugger));

        vm.startBroadcast(deployerAddr);
        {
            if (address(_tfheDebugger.db()) != address(_tfheDebuggerDB)) {
                _tfheDebugger.setDB(_tfheDebuggerDB);
            }
        }
        vm.stopBroadcast();

        addresses.TFHEDebuggerAddress = address(_tfheDebugger);
        addresses.TFHEDebuggerDBAddress = address(_tfheDebuggerDB);
    }

    function _isVersion(address contractAddress, string memory contractVersion) private view returns (bool) {
        (bool success, bytes memory returnData) = contractAddress.staticcall(abi.encodeWithSignature("getVersion()"));
        if (!success || returnData.length == 0) {
            return false;
        }
        string memory version = abi.decode(returnData, (string));
        return keccak256(abi.encode(version)) == keccak256(abi.encode(contractVersion));
    }

    /// Deploy a new TFHEDebugger contract using the specified deployer wallet
    function _deployTFHEDebugger(address deployerAddr, address randomGeneratorAddress) private returns (TFHEDebugger) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            DebuggerAddressesLib.expectedCreateTFHEDebuggerAddress(deployerAddr);

        if (_isVersion(expectedAddr, TFHEDebuggerVersion)) {
            return TFHEDebugger(expectedAddr);
        }

        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr),
            expectedImplNonce,
            "deploy TFHEDebugger contract implementation: unexpected nonce"
        );

        // Deploy TFHEDebugger implementation
        vm.broadcast(deployerAddr);
        TFHEDebugger impl = new TFHEDebugger();

        // Verify deployed contract address
        vm.assertEq(
            address(impl), expectedImplAddr, "deploy TFHEDebugger contract implementation: unexpected deploy address"
        );
        // Verify nonce
        vm.assertEq(vm.getNonce(deployerAddr), expectedNonce, "deploy TFHEDebugger contract proxy: unexpected nonce");

        // Deploy TFHEDebugger proxy
        vm.broadcast(deployerAddr);
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), abi.encodeWithSignature("initialize(address,address)", deployerAddr, randomGeneratorAddress)
        );

        // Verify deployed contract address
        vm.assertEq(address(proxy), expectedAddr, "deploy TFHEDebugger contract proxy: unexpected deploy address");
        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr), expectedNonce + 1, "deploy TFHEDebugger contract proxy: unexpected final nonce"
        );

        TFHEDebugger _tfheDebugger = TFHEDebugger(address(proxy));

        // Verify owner
        vm.assertEq(_tfheDebugger.owner(), deployerAddr, "deploy TFHEDebugger contract: unexpected owner");

        return _tfheDebugger;
    }

    /// https://medium.com/coinmonks/upgrading-smart-contracts-the-easy-way-a-tutorial-with-openzeppelin-a4ca35a56308
    /// Deploy a new TFHEDebuggerDB contract using the specified deployer wallet
    function _deployTFHEDebuggerDB(address deployerAddr, address _tfheDebuggerAddress)
        private
        returns (TFHEDebuggerDB)
    {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            DebuggerAddressesLib.expectedCreateTFHEDebuggerDBAddress(deployerAddr);

        if (_isVersion(expectedAddr, TFHEDebuggerDBVersion)) {
            return TFHEDebuggerDB(expectedAddr);
        }

        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr),
            expectedImplNonce,
            "deploy TFHEDebuggerDB contract implementation: unexpected nonce"
        );

        // Deploy TFHEDebuggerDB implementation
        vm.broadcast(deployerAddr);
        TFHEDebuggerDB impl = new TFHEDebuggerDB();

        // Verify deployed contract address
        vm.assertEq(
            address(impl), expectedImplAddr, "deploy TFHEDebuggerDB contract implementation: unexpected deploy address"
        );
        // Verify nonce
        vm.assertEq(vm.getNonce(deployerAddr), expectedNonce, "deploy TFHEDebuggerDB contract proxy: unexpected nonce");

        // Deploy TFHEDebuggerDB proxy
        vm.broadcast(deployerAddr);
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), abi.encodeWithSignature("initialize(address,address)", deployerAddr, _tfheDebuggerAddress)
        );

        // Verify deployed contract address
        vm.assertEq(address(proxy), expectedAddr, "deploy TFHEDebuggerDB contract proxy: unexpected deploy address");
        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr), expectedNonce + 1, "deploy TFHEDebuggerDB contract proxy: unexpected final nonce"
        );

        TFHEDebuggerDB _tfheDebuggerDB = TFHEDebuggerDB(address(proxy));

        // Verify owner
        vm.assertEq(_tfheDebuggerDB.owner(), deployerAddr, "deploy TFHEDebuggerDB contract: unexpected owner");

        return _tfheDebuggerDB;
    }
}
