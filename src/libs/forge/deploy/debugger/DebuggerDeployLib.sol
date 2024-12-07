// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {TFHEDebugger} from "../../../debugger/impl/TFHEDebugger.sol";
import {TFHEDebuggerDB} from "../../../debugger/impl/TFHEDebuggerDB.sol";

import {FFhevm} from "../../../../FFhevm.sol";

import {
    IForgeStdVmSafe as IVmSafe,
    IForgeStdVmUnsafe as IVmUnsafe,
    forgeStdVmSafeAdd,
    forgeStdVmUnsafeAdd
} from "../../interfaces/IForgeStdVm.sol";

import {DebuggerAddressesLib} from "./DebuggerAddressesLib.sol";

import {TFHEDebuggerVersion, TFHEDebuggerDBVersion, TFHEDebuggerDeployerDefaultPK} from "./constants.sol";

//import {console} from "forge-std/src/console.sol";

library DebuggerDeployLib {
    // solhint-disable const-name-snakecase
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);
    // solhint-disable const-name-snakecase
    IVmUnsafe private constant vmUnsafe = IVmUnsafe(forgeStdVmUnsafeAdd);

    /// @notice Deploy a new set of fhevm debugger contracts
    /// @dev Do not call this function inside a startBroadcast/stopBroadcast block
    function deployFhevmDebugger(FFhevm.Signer memory deployer, address randomGeneratorAddress)
        internal
        returns (FFhevm.DebuggerAddresses memory addresses)
    {
        bool useNonce = true;
        if (deployer.privateKey == 0) {
            useNonce = false;
            if (deployer.addr == address(0)) {
                deployer.addr = vm.rememberKey(TFHEDebuggerDeployerDefaultPK);
                deployer.privateKey = TFHEDebuggerDeployerDefaultPK;
            }
        }

        TFHEDebugger _tfheDebugger = _deployTFHEDebugger(deployer, randomGeneratorAddress, useNonce);
        TFHEDebuggerDB _tfheDebuggerDB = _deployTFHEDebuggerDB(deployer, address(_tfheDebugger), useNonce);

        vm.startBroadcast(deployer.addr);
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
    function _deployTFHEDebuggerWithNonce(address deployerAddr, address randomGeneratorAddress)
        private
        returns (TFHEDebugger)
    {
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
    function _deployTFHEDebuggerDBWithNonce(address deployerAddr, address _tfheDebuggerAddress)
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

    function _deployTFHEDebugger(FFhevm.Signer memory deployer, address randomGeneratorAddress, bool useNonce)
        private
        returns (TFHEDebugger)
    {
        return (deployer.privateKey != 0 && useNonce)
            ? _deployTFHEDebuggerWithNonce(deployer.addr, randomGeneratorAddress)
            : _deployTFHEDebuggerNoNonce(deployer.addr, randomGeneratorAddress);
    }

    function _deployTFHEDebuggerDB(FFhevm.Signer memory deployer, address _tfheDebuggerAddress, bool useNonce)
        private
        returns (TFHEDebuggerDB)
    {
        return (deployer.privateKey != 0 && useNonce)
            ? _deployTFHEDebuggerDBWithNonce(deployer.addr, _tfheDebuggerAddress)
            : _deployTFHEDebuggerDBNoNonce(deployer.addr, _tfheDebuggerAddress);
    }

    function _deployTFHEDebuggerNoNonce(address ownerAddr, address randomGeneratorAddress)
        private
        returns (TFHEDebugger)
    {
        address expectedAddr = DebuggerAddressesLib.expectedTFHEDebuggerAddress();
        _deployDebuggerContractAt("TFHEDebugger", "TFHEDebugger.sol", expectedAddr, TFHEDebuggerVersion);
        TFHEDebugger debugger = TFHEDebugger(expectedAddr);
        debugger.initialize(ownerAddr, randomGeneratorAddress);
        return debugger;
    }

    function _deployTFHEDebuggerDBNoNonce(address ownerAddr, address _tfheDebuggerAddress)
        private
        returns (TFHEDebuggerDB)
    {
        address expectedAddr = DebuggerAddressesLib.expectedTFHEDebuggerDBAddress();
        _deployDebuggerContractAt("TFHEDebuggerDB", "TFHEDebuggerDB.sol", expectedAddr, TFHEDebuggerDBVersion);
        TFHEDebuggerDB debuggerDB = TFHEDebuggerDB(expectedAddr);
        debuggerDB.initialize(ownerAddr, _tfheDebuggerAddress);
        return debuggerDB;
    }

    function _deployDebuggerContractAt(
        string memory contractName,
        string memory contractFilename,
        address expectedAddr,
        string memory expectedVersion
    ) private {
        if (_isVersion(expectedAddr, expectedVersion)) {
            return;
        }

        string memory path = string.concat("./out/", contractFilename, "/", contractName, ".json");
        bytes memory code = vm.getDeployedCode(path);

        vmUnsafe.etch(expectedAddr, code);
        vm.assertEq(expectedAddr.code, code, "Failed to deploy gateway contract");
    }
}
