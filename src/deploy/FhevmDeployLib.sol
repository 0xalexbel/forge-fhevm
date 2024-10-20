// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {ACL} from "fhevm/lib/ACL.sol";
import {FHEPayment} from "fhevm/lib/FHEPayment.sol";
import {KMSVerifier} from "fhevm/lib/KMSVerifier.sol";
import {InputVerifier as InputVerifierNative} from "fhevm/lib/InputVerifier.native.sol";
import {InputVerifier as InputVerifierCoprocessor} from "fhevm/lib/InputVerifier.coprocessor.sol";
import {GatewayContract} from "fhevm/gateway/GatewayContract.sol";

import {TFHEExecutor as TFHEExecutorWithPlugin} from "../executor/TFHEExecutor.plugin.sol";
import {FhevmAddressesLib} from "./FhevmAddressesLib.sol";

library FhevmDeployLib {
    struct FhevmDeployment {
        // FHEVMConfigStruct
        address ACLAddress;
        address TFHEExecutorAddress;
        address FHEPaymentAddress;
        address KMSVerifierAddress;
        // InputVerifiers
        address inputVerifierNative;
        address inputVerifierCoprocessor;
    }

    /// Deploy a new set of fhevm contracts
    function deployFhevmWithPlugin(
        address deployerAddr,
        bool isCoprocessor,
        address[] memory kmsSigners
    ) internal returns (FhevmDeployment memory) {
        FhevmDeployment memory res;

        // Deploy order:
        // 1. ACL
        // 2. TFHEExecutor
        // 3. KMSVerfier
        // 4. InputVerifier
        // 5. FHEPayment
        ACL acl = deployACL(deployerAddr);
        TFHEExecutorWithPlugin tfheExecutorWithPlugin = deployTFHEExecutorWithPlugin(deployerAddr);
        KMSVerifier kmsVerifier = deployKMSVerifier(deployerAddr);

        if (isCoprocessor) {
            res.inputVerifierCoprocessor = address(deployInputVerifierCoprocessor(deployerAddr));
        } else {
            res.inputVerifierNative = address(deployInputVerifierNative(deployerAddr));
        }

        FHEPayment fhePayment = deployFHEPayment(deployerAddr);

        res.ACLAddress = address(acl);
        res.TFHEExecutorAddress = address(tfheExecutorWithPlugin);
        res.KMSVerifierAddress = address(kmsVerifier);
        res.FHEPaymentAddress = address(fhePayment);

        acl.initialize(deployerAddr);
        tfheExecutorWithPlugin.initialize(deployerAddr);
        kmsVerifier.initialize(deployerAddr);

        // Add kms signers to the KMSVerifier
        for (uint256 i = 0; i < kmsSigners.length; ++i) {
            kmsVerifier.addSigner(kmsSigners[i]);
        }

        if (isCoprocessor) {
            InputVerifierCoprocessor iv = InputVerifierCoprocessor(res.inputVerifierCoprocessor);
            iv.initialize(deployerAddr);
        } else {
            InputVerifierNative iv = InputVerifierNative(res.inputVerifierNative);
            iv.initialize(deployerAddr);
        }

        fhePayment.initialize(deployerAddr);

        return res;
    }

    /// Deploy a new ACL contract using the specified deployer wallet
    function deployACL(address deployerAddr) internal returns (ACL) {
        (address expectedImplAddr, address expectedAddr) = FhevmAddressesLib.expectedCreateACLAddress(deployerAddr);

        ACL impl = new ACL();
        require(address(impl) == expectedImplAddr, "deployACL: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployACL: unexpected proxy deploy address");

        ACL _acl = ACL(address(proxy));

        return _acl;
    }

    /// Deploy a new TFHEExecutorWithPlugin contract using the specified deployer wallet
    function deployTFHEExecutorWithPlugin(address deployerAddr) internal returns (TFHEExecutorWithPlugin) {
        (address expectedImplAddr, address expectedAddr) = FhevmAddressesLib.expectedCreateTFHEExecutorAddress(
            deployerAddr
        );

        TFHEExecutorWithPlugin impl = new TFHEExecutorWithPlugin();
        require(address(impl) == expectedImplAddr, "deployTFHEExecutor: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployTFHEExecutor: unexpected proxy deploy address");

        TFHEExecutorWithPlugin _tfheExecutor = TFHEExecutorWithPlugin(address(proxy));

        return _tfheExecutor;
    }

    /// Deploy a new KMSVerifier contract using the specified deployer wallet
    function deployKMSVerifier(address deployerAddr) internal returns (KMSVerifier) {
        (address expectedImplAddr, address expectedAddr) = FhevmAddressesLib.expectedCreateKMSVerifierAddress(
            deployerAddr
        );

        KMSVerifier impl = new KMSVerifier();
        require(address(impl) == expectedImplAddr, "deployKMSVerifier: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployKMSVerifier: unexpected proxy deploy address");

        KMSVerifier _kmsVerifier = KMSVerifier(address(proxy));

        return _kmsVerifier;
    }

    /// Deploy a new FHEPayment contract using the specified deployer wallet
    function deployFHEPayment(address deployerAddr) internal returns (FHEPayment) {
        (address expectedImplAddr, address expectedAddr) = FhevmAddressesLib.expectedCreateFHEPaymentAddress(
            deployerAddr
        );

        FHEPayment impl = new FHEPayment();
        require(address(impl) == expectedImplAddr, "deployFHEPayment: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployFHEPayment: unexpected proxy deploy address");

        FHEPayment _fhePayment = FHEPayment(address(proxy));

        return _fhePayment;
    }

    /// Deploy a new InputVerifier native contract using the specified deployer wallet
    /// Native verifiers are defined in 'InputVerifier.native.sol'
    function deployInputVerifierNative(address deployerAddr) internal returns (address) {
        (address expectedImplAddr, address expectedAddr) = FhevmAddressesLib.expectedCreateInputVerifierAddress(
            deployerAddr
        );

        InputVerifierNative impl = new InputVerifierNative();
        require(
            address(impl) == expectedImplAddr,
            "deployInputVerifierNative: unexpected implementation deploy address"
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployInputVerifierNative: unexpected proxy deploy address");

        InputVerifierNative inputVerifier = InputVerifierNative(address(proxy));

        return address(inputVerifier);
    }

    /// Deploy a new InputVerifier coprocessor contract using the specified deployer wallet
    /// Coprocessor verifiers are defined in 'InputVerifier.coprocessor.sol'
    function deployInputVerifierCoprocessor(address deployerAddr) internal returns (address) {
        (address expectedImplAddr, address expectedAddr) = FhevmAddressesLib.expectedCreateInputVerifierAddress(
            deployerAddr
        );

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

    /// Deploy a new GatewayContract contract using the specified deployer wallet
    function deployGatewayContract(address deployerAddr) internal returns (GatewayContract) {
        (address expectedImplAddr, address expectedAddr) = FhevmAddressesLib.expectedCreateGatewayContractAddress(
            deployerAddr
        );

        GatewayContract impl = new GatewayContract();
        require(address(impl) == expectedImplAddr, "deployGatewayContract: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployGatewayContract: unexpected proxy deploy address");

        GatewayContract _gc = GatewayContract(address(proxy));

        return _gc;
    }
}
