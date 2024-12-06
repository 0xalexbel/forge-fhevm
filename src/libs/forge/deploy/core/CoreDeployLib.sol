// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/src/Console.sol";

import {FFhevm} from "../../../../FFhevm.sol";

import {ACL} from "../../../core/contracts/ACL.sol";
import {TFHEExecutor} from "../../../core/contracts/TFHEExecutor.sol";
import {FHEPayment} from "../../../core/contracts/FHEPayment.sol";
import {KMSVerifier} from "../../../core/contracts/KMSVerifier.sol";
import {InputVerifier as InputVerifierNative} from "../../../core/contracts/InputVerifier.native.sol";
import {InputVerifier as InputVerifierCoprocessor} from "../../../core/contracts/InputVerifier.coprocessor.sol";

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "../../interfaces/IForgeStdVm.sol";

import {
    ACLVersion,
    TFHEExecutorVersion,
    KMSVerifierVersion,
    FHEPaymentVersion,
    InputVerifierVersion
} from "./constants.sol";

import {CoreAddressesLib} from "./CoreAddressesLib.sol";

library CoreDeployLib {
    // solhint-disable const-name-snakecase
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    /// @notice Deploy a new set of fhevm core contracts
    /// @dev Do not call this function inside a startBroadcast/stopBroadcast block
    function deployFhevmCore(address deployerAddr, address coprocessorAccountAddr, address[] memory kmsSignersAddr)
        internal
        returns (FFhevm.CoreAddresses memory addresses)
    {
        // Verify coprocAddress
        // coprocessorAdd

        // Deploy order:
        // 1. ACL
        // 2. TFHEExecutor
        // 3. KMSVerfier
        // 4. InputVerifier
        // 5. FHEPayment
        ACL acl = _deployACL(deployerAddr);
        TFHEExecutor tfheExecutor = _deployTFHEExecutor(deployerAddr);
        KMSVerifier kmsVerifier = _deployKMSVerifier(deployerAddr);

        if (coprocessorAccountAddr != address(0)) {
            CoreAddressesLib.checkCoprocessorAddress(coprocessorAccountAddr);

            addresses.InputVerifierCoprocessorAddress = address(_deployInputVerifierCoprocessor(deployerAddr));
            addresses.InputVerifierAddress = addresses.InputVerifierCoprocessorAddress;
        } else {
            addresses.InputVerifierNativeAddress = address(_deployInputVerifierNative(deployerAddr));
            addresses.InputVerifierAddress = addresses.InputVerifierNativeAddress;
        }

        FHEPayment fhePayment = _deployFHEPayment(deployerAddr);

        addresses.ACLAddress = address(acl);
        addresses.TFHEExecutorAddress = address(tfheExecutor);
        addresses.KMSVerifierAddress = address(kmsVerifier);
        addresses.FHEPaymentAddress = address(fhePayment);

        // Add kms signers to the KMSVerifier
        for (uint256 i = 0; i < kmsSignersAddr.length; ++i) {
            if (!kmsVerifier.isSigner(kmsSignersAddr[i])) {
                vm.startBroadcast(deployerAddr);
                {
                    kmsVerifier.addSigner(kmsSignersAddr[i]);
                }
                vm.stopBroadcast();
            }
        }
    }

    // function _rpcEthGetCode(address contractAddress) private returns(bytes memory) {
    //     string memory arg = string.concat("[\"", vm.toString(contractAddress), "\", \"latest\"]");
    //     return vm.rpc("eth_getCode", arg);
    // }

    function _isVersion(address contractAddress, string memory contractVersion) private view returns (bool) {
        (bool success, bytes memory returnData) = contractAddress.staticcall(abi.encodeWithSignature("getVersion()"));
        if (!success || returnData.length == 0) {
            return false;
        }
        string memory version = abi.decode(returnData, (string));
        return keccak256(abi.encode(version)) == keccak256(abi.encode(contractVersion));
    }

    /// Deploy a new ACL contract using the specified deployer wallet
    function _deployACL(address deployerAddr) private returns (ACL) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            CoreAddressesLib.expectedCreateACLAddress(deployerAddr);

        if (_isVersion(expectedAddr, ACLVersion)) {
            return ACL(expectedAddr);
        }

        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr), expectedImplNonce, "deploy ACL contract implementation: unexpected nonce"
        );

        // Deploy ACL implementation
        vm.broadcast(deployerAddr);
        ACL impl = new ACL();

        // Verify deployed contract address
        vm.assertEq(address(impl), expectedImplAddr, "deploy ACL contract implementation: unexpected deploy address");
        // Verify nonce
        vm.assertEq(vm.getNonce(deployerAddr), expectedNonce, "deploy ACL contract proxy: unexpected nonce");

        // Deploy ACL proxy
        vm.broadcast(deployerAddr);
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(address)", deployerAddr));

        // Verify deployed contract address
        vm.assertEq(address(proxy), expectedAddr, "deploy ACL contract proxy: unexpected deploy address");
        // Verify nonce
        vm.assertEq(vm.getNonce(deployerAddr), expectedNonce + 1, "deploy ACL contract proxy: unexpected final nonce");

        ACL _acl = ACL(address(proxy));

        // Verify owner
        vm.assertEq(_acl.owner(), deployerAddr, "deploy ACL contract: unexpected owner");

        return _acl;
    }

    /// Deploy a new TFHEExecutor contract using the specified deployer wallet
    function _deployTFHEExecutor(address deployerAddr) private returns (TFHEExecutor) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            CoreAddressesLib.expectedCreateTFHEExecutorAddress(deployerAddr);

        if (_isVersion(expectedAddr, TFHEExecutorVersion)) {
            return TFHEExecutor(expectedAddr);
        }

        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr),
            expectedImplNonce,
            "deploy TFHEExecutor contract implementation: unexpected nonce"
        );

        // Deploy TFHEExecutor implementation
        vm.broadcast(deployerAddr);
        TFHEExecutor impl = new TFHEExecutor();

        // Verify deployed contract address
        vm.assertEq(
            address(impl), expectedImplAddr, "deploy TFHEExecutor contract implementation: unexpected deploy address"
        );
        // Verify nonce
        vm.assertEq(vm.getNonce(deployerAddr), expectedNonce, "deploy TFHEExecutor contract proxy: unexpected nonce");

        // Deploy TFHEExecutor proxy
        vm.broadcast(deployerAddr);
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(address)", deployerAddr));

        // Verify deployed contract address
        vm.assertEq(address(proxy), expectedAddr, "deploy TFHEExecutor contract proxy: unexpected deploy address");
        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr), expectedNonce + 1, "deploy TFHEExecutor contract proxy: unexpected final nonce"
        );

        TFHEExecutor _tfheExecutor = TFHEExecutor(address(proxy));

        return _tfheExecutor;
    }

    /// Deploy a new KMSVerifier contract using the specified deployer wallet
    function _deployKMSVerifier(address deployerAddr) private returns (KMSVerifier) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            CoreAddressesLib.expectedCreateKMSVerifierAddress(deployerAddr);

        if (_isVersion(expectedAddr, KMSVerifierVersion)) {
            return KMSVerifier(expectedAddr);
        }

        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr), expectedImplNonce, "deploy KMSVerifier contract implementation: unexpected nonce"
        );

        // Deploy KMSVerifier implementation
        vm.broadcast(deployerAddr);
        KMSVerifier impl = new KMSVerifier();

        // Verify deployed contract address
        vm.assertEq(
            address(impl), expectedImplAddr, "deploy KMSVerifier contract implementation: unexpected deploy address"
        );
        // Verify nonce
        vm.assertEq(vm.getNonce(deployerAddr), expectedNonce, "deploy KMSVerifier contract proxy: unexpected nonce");

        // Deploy KMSVerifier proxy
        vm.broadcast(deployerAddr);
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(address)", deployerAddr));

        // Verify deployed contract address
        vm.assertEq(address(proxy), expectedAddr, "deploy KMSVerifier contract proxy: unexpected deploy address");
        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr), expectedNonce + 1, "deploy KMSVerifier contract proxy: unexpected final nonce"
        );

        KMSVerifier _kmsVerifier = KMSVerifier(address(proxy));

        return _kmsVerifier;
    }

    /// Deploy a new FHEPayment contract using the specified deployer wallet
    function _deployFHEPayment(address deployerAddr) private returns (FHEPayment) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            CoreAddressesLib.expectedCreateFHEPaymentAddress(deployerAddr);

        if (_isVersion(expectedAddr, FHEPaymentVersion)) {
            return FHEPayment(expectedAddr);
        }

        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr), expectedImplNonce, "deploy FHEPayment contract implementation: unexpected nonce"
        );

        // Deploy FHEPayment implementation
        vm.broadcast(deployerAddr);
        FHEPayment impl = new FHEPayment();

        // Verify deployed contract address
        vm.assertEq(
            address(impl), expectedImplAddr, "deploy FHEPayment contract implementation: unexpected deploy address"
        );
        // Verify nonce
        vm.assertEq(vm.getNonce(deployerAddr), expectedNonce, "deploy FHEPayment contract proxy: unexpected nonce");

        // Deploy FHEPayment proxy
        vm.broadcast(deployerAddr);
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(address)", deployerAddr));

        // Verify deployed contract address
        vm.assertEq(address(proxy), expectedAddr, "deploy FHEPayment contract proxy: unexpected deploy address");
        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr), expectedNonce + 1, "deploy FHEPayment contract proxy: unexpected final nonce"
        );

        FHEPayment _fhePayment = FHEPayment(address(proxy));

        return _fhePayment;
    }

    /// Deploy a new InputVerifier native contract using the specified deployer wallet
    /// Native verifiers are defined in 'InputVerifier.native.sol'
    function _deployInputVerifierNative(address deployerAddr) private returns (address) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            CoreAddressesLib.expectedCreateInputVerifierAddress(deployerAddr);

        if (_isVersion(expectedAddr, InputVerifierVersion)) {
            return expectedAddr;
        }

        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr),
            expectedImplNonce,
            "deploy InputVerifier.native contract implementation: unexpected nonce"
        );

        // Deploy InputVerifierNative implementation
        vm.broadcast(deployerAddr);
        InputVerifierNative impl = new InputVerifierNative();

        // Verify deployed contract address
        vm.assertEq(
            address(impl),
            expectedImplAddr,
            "deploy InputVerifierNative contract implementation: unexpected deploy address"
        );
        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr), expectedNonce, "deploy InputVerifierNative contract proxy: unexpected nonce"
        );

        // Deploy InputVerifierNative proxy
        vm.broadcast(deployerAddr);
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(address)", deployerAddr));

        // Verify deployed contract address
        vm.assertEq(
            address(proxy), expectedAddr, "deploy InputVerifierNative contract proxy: unexpected deploy address"
        );
        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr),
            expectedNonce + 1,
            "deploy InputVerifierNative contract proxy: unexpected final nonce"
        );

        InputVerifierNative inputVerifier = InputVerifierNative(address(proxy));

        return address(inputVerifier);
    }

    /// Deploy a new InputVerifier coprocessor contract using the specified deployer wallet
    /// Coprocessor verifiers are defined in 'InputVerifier.coprocessor.sol'
    function _deployInputVerifierCoprocessor(address deployerAddr) private returns (address) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            CoreAddressesLib.expectedCreateInputVerifierAddress(deployerAddr);

        if (_isVersion(expectedAddr, InputVerifierVersion)) {
            return expectedAddr;
        }

        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr),
            expectedImplNonce,
            "deploy InputVerifier.coprocessor contract implementation: unexpected nonce"
        );

        // Deploy InputVerifierCoprocessor implementation
        vm.broadcast(deployerAddr);
        InputVerifierCoprocessor impl = new InputVerifierCoprocessor();

        // Verify deployed contract address
        vm.assertEq(
            address(impl),
            expectedImplAddr,
            "deploy InputVerifierCoprocessor contract implementation: unexpected deploy address"
        );
        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr), expectedNonce, "deploy InputVerifierCoprocessor contract proxy: unexpected nonce"
        );

        // Deploy InputVerifierCoprocessor proxy
        vm.broadcast(deployerAddr);
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(address)", deployerAddr));

        // Verify deployed contract address
        vm.assertEq(
            address(proxy), expectedAddr, "deploy InputVerifierCoprocessor contract proxy: unexpected deploy address"
        );
        // Verify nonce
        vm.assertEq(
            vm.getNonce(deployerAddr),
            expectedNonce + 1,
            "deploy InputVerifierCoprocessor contract proxy: unexpected final nonce"
        );

        InputVerifierCoprocessor inputVerifier = InputVerifierCoprocessor(address(proxy));

        return address(inputVerifier);
    }
}
