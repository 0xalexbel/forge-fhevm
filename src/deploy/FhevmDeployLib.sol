// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {ACL} from "fhevm/lib/ACL.sol";
import {TFHEExecutor} from "fhevm/lib/TFHEExecutor.sol";
import {FHEPayment} from "fhevm/lib/FHEPayment.sol";
import {KMSVerifier} from "fhevm/lib/KMSVerifier.sol";
import {InputVerifier as InputVerifierNative} from "fhevm/lib/InputVerifier.native.sol";
import {InputVerifier as InputVerifierCoprocessor} from "fhevm/lib/InputVerifier.coprocessor.sol";
import {GatewayContract} from "fhevm/gateway/GatewayContract.sol";
import {FHEVMConfig} from "fhevm/lib/FHEVMConfig.sol";

import {TFHEExecutor as TFHEExecutorWithPlugin} from "../executor/TFHEExecutor.plugin.sol";
import {TFHEExecutorDB} from "../executor/TFHEExecutorDB.sol";
import {FhevmAddressesLib} from "./FhevmAddressesLib.sol";

library FhevmDeployLib {
    struct FhevmDeployment {
        // FHEVMConfigStruct
        address ACLAddress;
        address TFHEExecutorAddress;
        address FHEPaymentAddress;
        address KMSVerifierAddress;
        // InputVerifiers
        address InputVerifierAddress;
        address InputVerifierNativeAddress;
        address InputVerifierCoprocessorAddress;
        // Extra
        address TFHEExecutorDBAddress;
    }

    function deployGateway(address deployerAddr, address relayerAddr)
        internal
        returns (address gatewayContractAddress)
    {
        // Deploy order:
        // 1. GatewayContract
        // 2. addRelayer
        GatewayContract gc = deployGatewayContract(deployerAddr);
        gc.initialize(deployerAddr);
        gc.addRelayer(relayerAddr);

        gatewayContractAddress = address(gc);
    }

    /// Deploy a new set of fhevm contracts
    function deployFhevmNoPlugin(address deployerAddr, bool isCoprocessor, address[] memory kmsSigners)
        internal
        returns (FhevmDeployment memory)
    {
        FhevmDeployment memory res;

        // Verify coprocAddress
        // coprocessorAdd

        // Deploy order:
        // 1. ACL
        // 2. TFHEExecutor
        // 3. KMSVerfier
        // 4. InputVerifier
        // 5. FHEPayment
        // Extra:
        // 6. TFHEExecutorDB
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

        // Extra
        TFHEExecutorDB tfheExecutorDB = deployTFHEExecutorDB(deployerAddr);

        res.ACLAddress = address(acl);
        res.TFHEExecutorAddress = address(tfheExecutor);
        res.KMSVerifierAddress = address(kmsVerifier);
        res.FHEPaymentAddress = address(fhePayment);
        res.TFHEExecutorDBAddress = address(tfheExecutorDB);

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

    /// Deploy a new set of fhevm contracts
    function deployFhevmWithPlugin(address deployerAddr, bool isCoprocessor, address[] memory kmsSigners)
        internal
        returns (FhevmDeployment memory)
    {
        FhevmDeployment memory res;

        // Verify coprocAddress
        // coprocessorAdd

        // Deploy order:
        // 1. ACL
        // 2. TFHEExecutor
        // 3. KMSVerfier
        // 4. InputVerifier
        // 5. FHEPayment
        // Extra:
        // 6. TFHEExecutorDB
        ACL acl = deployACL(deployerAddr);
        TFHEExecutorWithPlugin tfheExecutorWithPlugin = deployTFHEExecutorWithPlugin(deployerAddr);
        KMSVerifier kmsVerifier = deployKMSVerifier(deployerAddr);

        if (isCoprocessor) {
            res.InputVerifierCoprocessorAddress = address(deployInputVerifierCoprocessor(deployerAddr));
            res.InputVerifierAddress = res.InputVerifierCoprocessorAddress;
        } else {
            res.InputVerifierNativeAddress = address(deployInputVerifierNative(deployerAddr));
            res.InputVerifierAddress = res.InputVerifierNativeAddress;
        }

        FHEPayment fhePayment = deployFHEPayment(deployerAddr);

        // Extra
        TFHEExecutorDB tfheExecutorDB = deployTFHEExecutorDB(deployerAddr);

        res.ACLAddress = address(acl);
        res.TFHEExecutorAddress = address(tfheExecutorWithPlugin);
        res.KMSVerifierAddress = address(kmsVerifier);
        res.FHEPaymentAddress = address(fhePayment);
        res.TFHEExecutorDBAddress = address(tfheExecutorDB);

        acl.initialize(deployerAddr);
        tfheExecutorWithPlugin.initialize(deployerAddr);
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

        tfheExecutorWithPlugin.setPlugin(tfheExecutorDB);

        verifyDefaultFHEVMConfig(res);

        return res;
    }

    /// Verify that FHEVMConfig.defaultConfig() is consistent.
    function verifyDefaultFHEVMConfig(FhevmDeployment memory deployment) private pure {
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
        (address expectedImplAddr, address expectedAddr) = FhevmAddressesLib.expectedCreateACLAddress(deployerAddr);

        ACL impl = new ACL();
        require(address(impl) == expectedImplAddr, "deployACL: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployACL: unexpected proxy deploy address");

        ACL _acl = ACL(address(proxy));

        return _acl;
    }

    /// Deploy a new TFHEExecutorWithPlugin contract using the specified deployer wallet
    function deployTFHEExecutorWithPlugin(address deployerAddr) private returns (TFHEExecutorWithPlugin) {
        (address expectedImplAddr, address expectedAddr) =
            FhevmAddressesLib.expectedCreateTFHEExecutorAddress(deployerAddr);

        TFHEExecutorWithPlugin impl = new TFHEExecutorWithPlugin();
        require(address(impl) == expectedImplAddr, "deployTFHEExecutor: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployTFHEExecutor: unexpected proxy deploy address");

        TFHEExecutorWithPlugin _tfheExecutor = TFHEExecutorWithPlugin(address(proxy));

        return _tfheExecutor;
    }

    /// Deploy a new TFHEExecutor contract using the specified deployer wallet
    function deployTFHEExecutor(address deployerAddr) private returns (TFHEExecutor) {
        (address expectedImplAddr, address expectedAddr) =
            FhevmAddressesLib.expectedCreateTFHEExecutorAddress(deployerAddr);

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
            FhevmAddressesLib.expectedCreateKMSVerifierAddress(deployerAddr);

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
            FhevmAddressesLib.expectedCreateFHEPaymentAddress(deployerAddr);

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
            FhevmAddressesLib.expectedCreateInputVerifierAddress(deployerAddr);

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
            FhevmAddressesLib.expectedCreateInputVerifierAddress(deployerAddr);

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
    function deployGatewayContract(address deployerAddr) private returns (GatewayContract) {
        (address expectedImplAddr, address expectedAddr) =
            FhevmAddressesLib.expectedCreateGatewayContractAddress(deployerAddr);

        GatewayContract impl = new GatewayContract();
        require(address(impl) == expectedImplAddr, "deployGatewayContract: unexpected implementation deploy address");

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        require(address(proxy) == expectedAddr, "deployGatewayContract: unexpected proxy deploy address");

        GatewayContract _gc = GatewayContract(address(proxy));

        return _gc;
    }

    /// Deploy a new TFHEExecutorDB contract using the specified deployer wallet
    function deployTFHEExecutorDB(address deployerAddr) private returns (TFHEExecutorDB) {
        address expectedAddr = FhevmAddressesLib.expectedCreateTFHEExecutorDBAddress(deployerAddr);

        TFHEExecutorDB _tfheExecutorDB = new TFHEExecutorDB(deployerAddr);
        require(address(_tfheExecutorDB) == expectedAddr, "deployTFHEExecutorDB: unexpected contract deploy address");

        return _tfheExecutorDB;
    }
}
