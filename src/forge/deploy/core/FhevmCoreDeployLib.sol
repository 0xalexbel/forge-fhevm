// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {ACL} from "fhevm-core-contracts/contracts/ACL.sol";
import {TFHEExecutor} from "fhevm-core-contracts/contracts/TFHEExecutor.sol";
import {FHEPayment} from "fhevm-core-contracts/contracts/FHEPayment.sol";
import {KMSVerifier} from "fhevm-core-contracts/contracts/KMSVerifier.sol";
import {InputVerifier as InputVerifierNative} from "fhevm-core-contracts/contracts/InputVerifier.native.sol";
import {InputVerifier as InputVerifierCoprocessor} from "fhevm-core-contracts/contracts/InputVerifier.coprocessor.sol";

import {FHEVMConfig} from "../../../debug/fhevm/lib/FHEVMConfig.sol";

import {FhevmCoreAddressesLib} from "./FhevmCoreAddressesLib.sol";

library FhevmCoreDeployLib {
    struct FhevmCoreDeployment {
        // FHEVMConfigStruct
        address ACLAddress;
        address TFHEExecutorAddress;
        address FHEPaymentAddress;
        address KMSVerifierAddress;
        // InputVerifiers
        address InputVerifierAddress;
        address InputVerifierNativeAddress;
        address InputVerifierCoprocessorAddress;
    }

    /// Deploy a new set of fhevm core contracts
    function deployFhevmCore(address deployerAddr, bool isCoprocessor, address[] memory kmsSigners)
        internal
        returns (FhevmCoreDeployment memory)
    {
        FhevmCoreDeployment memory res;

        // Verify coprocAddress
        // coprocessorAdd

        // Deploy order:
        // 1. ACL
        // 2. TFHEExecutor
        // 3. KMSVerfier
        // 4. InputVerifier
        // 5. FHEPayment
        ACL acl = deployACL(deployerAddr);
        TFHEExecutor tfheExecutor = deployTFHEExecutor(deployerAddr);
        KMSVerifier kmsVerifier = deployKMSVerifier(deployerAddr);

        if (isCoprocessor) {
            res.InputVerifierCoprocessorAddress = address(deployInputVerifierCoprocessor(deployerAddr));
            res.InputVerifierAddress = res.InputVerifierCoprocessorAddress;
        } else {
            res.InputVerifierNativeAddress = address(deployInputVerifierNative(deployerAddr));
            res.InputVerifierAddress = res.InputVerifierNativeAddress;
        }

        FHEPayment fhePayment = deployFHEPayment(deployerAddr);

        res.ACLAddress = address(acl);
        res.TFHEExecutorAddress = address(tfheExecutor);
        res.KMSVerifierAddress = address(kmsVerifier);
        res.FHEPaymentAddress = address(fhePayment);

        acl.initialize(deployerAddr);
        tfheExecutor.initialize(deployerAddr);
        kmsVerifier.initialize(deployerAddr);

        // Add kms signers to the KMSVerifier
        for (uint256 i = 0; i < kmsSigners.length; ++i) {
            kmsVerifier.addSigner(kmsSigners[i]);
        }

        if (isCoprocessor) {
            InputVerifierCoprocessor iv = InputVerifierCoprocessor(res.InputVerifierCoprocessorAddress);
            iv.initialize(deployerAddr);
        } else {
            InputVerifierNative iv = InputVerifierNative(res.InputVerifierNativeAddress);
            iv.initialize(deployerAddr);
        }

        fhePayment.initialize(deployerAddr);

        verifyDefaultFHEVMConfig(res);

        return res;
    }

    /// Verify that FHEVMConfig.defaultConfig() is consistent.
    function verifyDefaultFHEVMConfig(FhevmCoreDeployment memory deployment) private view {
        FHEVMConfig.FHEVMConfigStruct memory defaultCfg = FHEVMConfig.defaultConfig();
        require(defaultCfg.ACLAddress == deployment.ACLAddress, "ACL address is invalid. Deployment is inconsistent.");
        require(
            defaultCfg.TFHEExecutorAddress == deployment.TFHEExecutorAddress,
            "TFHEExecutor address is invalid. Deployment is inconsistent."
        );
        require(
            defaultCfg.KMSVerifierAddress == deployment.KMSVerifierAddress,
            "KMSVerifier address is invalid. Deployment is inconsistent."
        );
        require(
            defaultCfg.FHEPaymentAddress == deployment.FHEPaymentAddress,
            "FHEPayment address is invalid. Deployment is inconsistent."
        );
    }

    /// Deploy a new ACL contract using the specified deployer wallet
    function deployACL(address deployerAddr) private returns (ACL) {
        (address expectedImplAddr, address expectedAddr) = FhevmCoreAddressesLib.expectedCreateACLAddress(deployerAddr);

        ACL impl = new ACL();
        require(address(impl) == expectedImplAddr, "deployACL: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployACL: unexpected proxy deploy address");

        ACL _acl = ACL(address(proxy));

        return _acl;
    }

    /// Deploy a new TFHEExecutor contract using the specified deployer wallet
    function deployTFHEExecutor(address deployerAddr) private returns (TFHEExecutor) {
        (address expectedImplAddr, address expectedAddr) =
            FhevmCoreAddressesLib.expectedCreateTFHEExecutorAddress(deployerAddr);

        TFHEExecutor impl = new TFHEExecutor();
        require(address(impl) == expectedImplAddr, "deployTFHEExecutor: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployTFHEExecutor: unexpected proxy deploy address");

        TFHEExecutor _tfheExecutor = TFHEExecutor(address(proxy));

        return _tfheExecutor;
    }

    /// Deploy a new KMSVerifier contract using the specified deployer wallet
    function deployKMSVerifier(address deployerAddr) private returns (KMSVerifier) {
        (address expectedImplAddr, address expectedAddr) =
            FhevmCoreAddressesLib.expectedCreateKMSVerifierAddress(deployerAddr);

        KMSVerifier impl = new KMSVerifier();
        require(address(impl) == expectedImplAddr, "deployKMSVerifier: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployKMSVerifier: unexpected proxy deploy address");

        KMSVerifier _kmsVerifier = KMSVerifier(address(proxy));

        return _kmsVerifier;
    }

    /// Deploy a new FHEPayment contract using the specified deployer wallet
    function deployFHEPayment(address deployerAddr) private returns (FHEPayment) {
        (address expectedImplAddr, address expectedAddr) =
            FhevmCoreAddressesLib.expectedCreateFHEPaymentAddress(deployerAddr);

        FHEPayment impl = new FHEPayment();
        require(address(impl) == expectedImplAddr, "deployFHEPayment: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployFHEPayment: unexpected proxy deploy address");

        FHEPayment _fhePayment = FHEPayment(address(proxy));

        return _fhePayment;
    }

    /// Deploy a new InputVerifier native contract using the specified deployer wallet
    /// Native verifiers are defined in 'InputVerifier.native.sol'
    function deployInputVerifierNative(address deployerAddr) private returns (address) {
        (address expectedImplAddr, address expectedAddr) =
            FhevmCoreAddressesLib.expectedCreateInputVerifierAddress(deployerAddr);

        InputVerifierNative impl = new InputVerifierNative();
        require(
            address(impl) == expectedImplAddr, "deployInputVerifierNative: unexpected implementation deploy address"
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployInputVerifierNative: unexpected proxy deploy address");

        InputVerifierNative inputVerifier = InputVerifierNative(address(proxy));

        return address(inputVerifier);
    }

    /// Deploy a new InputVerifier coprocessor contract using the specified deployer wallet
    /// Coprocessor verifiers are defined in 'InputVerifier.coprocessor.sol'
    function deployInputVerifierCoprocessor(address deployerAddr) private returns (address) {
        (address expectedImplAddr, address expectedAddr) =
            FhevmCoreAddressesLib.expectedCreateInputVerifierAddress(deployerAddr);

        InputVerifierCoprocessor impl = new InputVerifierCoprocessor();
        require(
            address(impl) == expectedImplAddr,
            "deployInputVerifierCoprocessor: unexpected implementation deploy address"
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployInputVerifierCoprocessor: unexpected proxy deploy address");

        InputVerifierCoprocessor inputVerifier = InputVerifierCoprocessor(address(proxy));

        return address(inputVerifier);
    }
}
