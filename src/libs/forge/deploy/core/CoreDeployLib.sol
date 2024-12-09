// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/src/console.sol";

import {FFhevm} from "../../../../FFhevm.sol";
import {AddressLib} from "../../../common/AddressLib.sol";

import {ICoreContract} from "../../../core/interfaces/ICoreContract.sol";
import {IACL} from "../../../core/interfaces/IACL.sol";
import {ITFHEExecutor} from "../../../core/interfaces/ITFHEExecutor.sol";
import {IFHEPayment} from "../../../core/interfaces/IFHEPayment.sol";
import {IKMSVerifier} from "../../../core/interfaces/IKMSVerifier.sol";
import {IInputVerifier} from "../../../core/interfaces/IInputVerifier.sol";

import {ACL} from "../../../core/contracts/ACL.sol";
import {TFHEExecutor} from "../../../core/contracts/TFHEExecutor.sol";
import {FHEPayment} from "../../../core/contracts/FHEPayment.sol";
import {KMSVerifier} from "../../../core/contracts/KMSVerifier.sol";
import {InputVerifier as InputVerifierNative} from "../../../core/contracts/InputVerifier.native.sol";
import {InputVerifier as InputVerifierCoprocessor} from "../../../core/contracts/InputVerifier.coprocessor.sol";

import {
    IForgeStdVmSafe as IVmSafe,
    IForgeStdVmUnsafe as IVmUnsafe,
    forgeStdVmSafeAdd,
    forgeStdVmUnsafeAdd
} from "../../interfaces/IForgeStdVm.sol";

import {
    ACLVersion,
    TFHEExecutorVersion,
    KMSVerifierVersion,
    FHEPaymentVersion,
    InputVerifierVersion,
    CoreDeployerDefaultPK
} from "./constants.sol";

import {CoreAddressesLib} from "./CoreAddressesLib.sol";

library CoreDeployLib {
    // solhint-disable const-name-snakecase
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);
    // solhint-disable const-name-snakecase
    IVmUnsafe private constant vmUnsafe = IVmUnsafe(forgeStdVmUnsafeAdd);

    function _getArtifactPath(string memory contractName, string memory contractFilename)
        private
        pure
        returns (string memory)
    {
        return string.concat(
            "./node_modules/fhevm-core-contracts/artifacts/contracts/", contractFilename, "/", contractName, ".json"
        );
    }

    /// @notice Deploy a new set of fhevm core contracts
    /// @dev Do not call this function inside a startBroadcast/stopBroadcast block
    function deployFhevmCore(
        FFhevm.Signer memory deployer,
        address coprocessorAccountAddr,
        address[] memory kmsSignersAddr
    ) internal returns (FFhevm.CoreAddresses memory addresses) {
        bool useNonce = true;
        if (deployer.privateKey == 0) {
            useNonce = false;
            if (deployer.addr == address(0)) {
                IVmSafe.Wallet memory wallet = vm.createWallet(CoreDeployerDefaultPK);
                deployer.addr = wallet.addr;
                deployer.privateKey = wallet.privateKey;
            }
        }

        // Verify coprocAddress
        // coprocessorAdd

        // Deploy order:
        // 1. ACL
        // 2. TFHEExecutor
        // 3. KMSVerfier
        // 4. InputVerifier
        // 5. FHEPayment
        IACL acl = _deployACL(deployer, useNonce);
        ITFHEExecutor tfheExecutor = _deployTFHEExecutor(deployer, useNonce);
        IKMSVerifier kmsVerifier = _deployKMSVerifier(deployer, useNonce);

        if (coprocessorAccountAddr != address(0)) {
            CoreAddressesLib.checkCoprocessorAddress(coprocessorAccountAddr);

            addresses.InputVerifierCoprocessorAddress = _deployInputVerifierCoprocessor(deployer, useNonce);
            addresses.InputVerifierAddress = addresses.InputVerifierCoprocessorAddress;
        } else {
            addresses.InputVerifierNativeAddress = _deployInputVerifierNative(deployer, useNonce);
            addresses.InputVerifierAddress = addresses.InputVerifierNativeAddress;
        }

        IFHEPayment fhePayment = _deployFHEPayment(deployer, useNonce);

        addresses.ACLAddress = address(acl);
        addresses.TFHEExecutorAddress = address(tfheExecutor);
        addresses.KMSVerifierAddress = address(kmsVerifier);
        addresses.FHEPaymentAddress = address(fhePayment);

        // Add kms signers to the KMSVerifier
        for (uint256 i = 0; i < kmsSignersAddr.length; ++i) {
            if (!kmsVerifier.isSigner(kmsSignersAddr[i])) {
                vm.startBroadcast(deployer.addr);
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
    function _deployACLWithNonce(address deployerAddr) private returns (IACL) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            CoreAddressesLib.expectedCreateACLAddress(deployerAddr);

        if (_isVersion(expectedAddr, ACLVersion)) {
            return IACL(expectedAddr);
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

        IACL _acl = IACL(address(proxy));

        // Verify owner
        vm.assertEq(AddressLib.getOwner(address(_acl)), deployerAddr, "deploy ACL contract: unexpected owner");

        return _acl;
    }

    function _deployTFHEExecutorWithNonce(address deployerAddr) private returns (ITFHEExecutor) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            CoreAddressesLib.expectedCreateTFHEExecutorAddress(deployerAddr);

        if (_isVersion(expectedAddr, TFHEExecutorVersion)) {
            return ITFHEExecutor(expectedAddr);
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

        ITFHEExecutor _tfheExecutor = ITFHEExecutor(address(proxy));

        return _tfheExecutor;
    }

    function _deployKMSVerifierWithNonce(address deployerAddr) private returns (IKMSVerifier) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            CoreAddressesLib.expectedCreateKMSVerifierAddress(deployerAddr);

        if (_isVersion(expectedAddr, KMSVerifierVersion)) {
            return IKMSVerifier(expectedAddr);
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

        IKMSVerifier _kmsVerifier = IKMSVerifier(address(proxy));

        return _kmsVerifier;
    }

    function _deployFHEPaymentWithNonce(address deployerAddr) private returns (IFHEPayment) {
        (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce) =
            CoreAddressesLib.expectedCreateFHEPaymentAddress(deployerAddr);

        if (_isVersion(expectedAddr, FHEPaymentVersion)) {
            return IFHEPayment(expectedAddr);
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

        IFHEPayment _fhePayment = IFHEPayment(address(proxy));

        return _fhePayment;
    }

    function _deployInputVerifierNativeWithNonce(address deployerAddr) private returns (address) {
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

    function _deployInputVerifierCoprocessorWithNonce(address deployerAddr) private returns (address) {
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

    function _deployACL(FFhevm.Signer memory deployer, bool useNonce) private returns (IACL) {
        return (deployer.privateKey != 0 && useNonce)
            ? _deployACLWithNonce(deployer.addr)
            : _deployACLNoNonce(deployer.addr);
    }

    function _deployTFHEExecutor(FFhevm.Signer memory deployer, bool useNonce) private returns (ITFHEExecutor) {
        return (deployer.privateKey != 0 && useNonce)
            ? _deployTFHEExecutorWithNonce(deployer.addr)
            : _deployTFHEExecutorNoNonce(deployer.addr);
    }

    function _deployKMSVerifier(FFhevm.Signer memory deployer, bool useNonce) private returns (IKMSVerifier) {
        return (deployer.privateKey != 0 && useNonce)
            ? _deployKMSVerifierWithNonce(deployer.addr)
            : _deployKMSVerifierNoNonce(deployer.addr);
    }

    function _deployFHEPayment(FFhevm.Signer memory deployer, bool useNonce) private returns (IFHEPayment) {
        return (deployer.privateKey != 0 && useNonce)
            ? _deployFHEPaymentWithNonce(deployer.addr)
            : _deployFHEPaymentNoNonce(deployer.addr);
    }

    function _deployInputVerifierNative(FFhevm.Signer memory deployer, bool useNonce) private returns (address) {
        return (deployer.privateKey != 0 && useNonce)
            ? _deployInputVerifierNativeWithNonce(deployer.addr)
            : _deployInputVerifierNativeNoNonce(deployer.addr);
    }

    function _deployInputVerifierCoprocessor(FFhevm.Signer memory deployer, bool useNonce) private returns (address) {
        return (deployer.privateKey != 0 && useNonce)
            ? _deployInputVerifierCoprocessorWithNonce(deployer.addr)
            : _deployInputVerifierCoprocessorNoNonce(deployer.addr);
    }

    function _deployACLNoNonce(address ownerAddr) private returns (IACL) {
        address expectedAddr = CoreAddressesLib.expectedACLAddress();
        _deployCoreContractAt("ACL", "ACL.sol", expectedAddr, ownerAddr, ACLVersion);
        return IACL(expectedAddr);
    }

    function _deployTFHEExecutorNoNonce(address ownerAddr) private returns (ITFHEExecutor) {
        address expectedAddr = CoreAddressesLib.expectedTFHEExecutorAddress();
        _deployCoreContractAt("TFHEExecutor", "TFHEExecutor.sol", expectedAddr, ownerAddr, TFHEExecutorVersion);
        return ITFHEExecutor(expectedAddr);
    }

    function _deployFHEPaymentNoNonce(address ownerAddr) private returns (IFHEPayment) {
        address expectedAddr = CoreAddressesLib.expectedFHEPaymentAddress();
        _deployCoreContractAt("FHEPayment", "FHEPayment.sol", expectedAddr, ownerAddr, FHEPaymentVersion);
        return IFHEPayment(expectedAddr);
    }

    function _deployKMSVerifierNoNonce(address ownerAddr) private returns (IKMSVerifier) {
        address expectedAddr = CoreAddressesLib.expectedKMSVerifierAddress();
        _deployCoreContractAt("KMSVerifier", "KMSVerifier.sol", expectedAddr, ownerAddr, KMSVerifierVersion);
        return IKMSVerifier(expectedAddr);
    }

    function _deployInputVerifierCoprocessorNoNonce(address ownerAddr) private returns (address) {
        address expectedAddr = CoreAddressesLib.expectedInputVerifierAddress();
        _deployCoreContractAt(
            "InputVerifier", "InputVerifier.coprocessor.sol", expectedAddr, ownerAddr, InputVerifierVersion
        );
        return expectedAddr;
    }

    function _deployInputVerifierNativeNoNonce(address ownerAddr) private returns (address) {
        address expectedAddr = CoreAddressesLib.expectedInputVerifierAddress();
        _deployCoreContractAt(
            "InputVerifier", "InputVerifier.native.sol", expectedAddr, ownerAddr, InputVerifierVersion
        );
        return expectedAddr;
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

        string memory path = _getArtifactPath(contractName, contractFilename);
        bytes memory code = vm.getDeployedCode(path);

        vmUnsafe.etch(expectedAddr, code);
        vm.assertEq(expectedAddr.code, code, "Failed to deploy core contract");

        ICoreContract coreContract = ICoreContract(expectedAddr);
        coreContract.initialize(ownerAddr);
    }
}
