// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {FFhevm} from "../../../FFhevm.sol";

import {FFhevmDebugConfigStruct} from "../../debugger/config/FFhevmDebugConfig.sol";
import {Gateway} from "../../fhevm-debug/gateway/lib/Gateway.sol";
import {Impl} from "../../fhevm-debug/lib/Impl.sol";

import {
    ACLAddressEnvName,
    TFHEExecutorAddressEnvName,
    InputVerifierAddressEnvName,
    KMSVerifierAddressEnvName,
    FHEPaymentAddressEnvName
} from "../deploy/core/constants.sol";
import {GatewayContractAddressEnvName} from "../deploy/gateway/constants.sol";
import {TFHEDebuggerAddressEnvName, TFHEDebuggerDBAddressEnvName} from "../deploy/debugger/constants.sol";
import {CoreAddressesLib} from "../deploy/core/CoreAddressesLib.sol";
import {GatewayAddressesLib} from "../deploy/gateway/GatewayAddressesLib.sol";
import {DebuggerAddressesLib} from "../deploy/debugger/DebuggerAddressesLib.sol";
import {EnvLib} from "../utils/EnvLib.sol";
import {FFhevmDeployConfigLib} from "./FFhevmDeployConfigLib.sol";

library FFhevmConfigLib {
    function copyToStorage(FFhevm.Config memory src, FFhevm.Config storage dst) internal {
        FFhevmDeployConfigLib.copyToStorage(src.deployConfig, dst.deployConfig);

        // Random generator
        dst.IRandomGeneratorAddress = src.IRandomGeneratorAddress;

        // Fhevm Core
        dst.core.ACLAddress = src.core.ACLAddress;
        dst.core.TFHEExecutorAddress = src.core.TFHEExecutorAddress;
        dst.core.FHEPaymentAddress = src.core.FHEPaymentAddress;
        dst.core.KMSVerifierAddress = src.core.KMSVerifierAddress;

        // InputVerifiers
        dst.core.InputVerifierNativeAddress = src.core.InputVerifierNativeAddress;
        dst.core.InputVerifierCoprocessorAddress = src.core.InputVerifierCoprocessorAddress;
        dst.core.InputVerifierAddress = src.core.InputVerifierAddress;

        // Gateway
        dst.gateway.GatewayContractAddress = src.gateway.GatewayContractAddress;

        // Debugger
        dst.debugger.TFHEDebuggerAddress = src.debugger.TFHEDebuggerAddress;
        dst.debugger.TFHEDebuggerDBAddress = src.debugger.TFHEDebuggerDBAddress;
    }

    function initializeWithEnv() internal returns (FFhevm.Config memory config) {
        config.deployConfig = FFhevmDeployConfigLib.initializeWithEnv();

        // Core addresses
        FFhevm.CoreAddresses memory coreAddresses =
            CoreAddressesLib.computeAddresses(config.deployConfig.fhevmDeployer.addr, config.deployConfig.isCoprocessor);

        config.core.ACLAddress = EnvLib.envAddressOr(ACLAddressEnvName, coreAddresses.ACLAddress);
        config.core.TFHEExecutorAddress =
            EnvLib.envAddressOr(TFHEExecutorAddressEnvName, coreAddresses.TFHEExecutorAddress);
        config.core.FHEPaymentAddress = EnvLib.envAddressOr(FHEPaymentAddressEnvName, coreAddresses.FHEPaymentAddress);
        config.core.KMSVerifierAddress =
            EnvLib.envAddressOr(KMSVerifierAddressEnvName, coreAddresses.KMSVerifierAddress);
        config.core.InputVerifierAddress =
            EnvLib.envAddressOr(InputVerifierAddressEnvName, coreAddresses.InputVerifierAddress);

        // Gateway addresses
        FFhevm.GatewayAddresses memory gatewayAddresses =
            GatewayAddressesLib.computeAddresses(config.deployConfig.fhevmDeployer.addr);

        config.gateway.GatewayContractAddress =
            EnvLib.envAddressOr(GatewayContractAddressEnvName, gatewayAddresses.GatewayContractAddress);

        // Debugger addresses
        FFhevm.DebuggerAddresses memory debuggerAddresses =
            DebuggerAddressesLib.computeAddresses(config.deployConfig.fhevmDeployer.addr);

        config.debugger.TFHEDebuggerAddress =
            EnvLib.envAddressOr(TFHEDebuggerAddressEnvName, debuggerAddresses.TFHEDebuggerAddress);
        config.debugger.TFHEDebuggerDBAddress =
            EnvLib.envAddressOr(TFHEDebuggerDBAddressEnvName, debuggerAddresses.TFHEDebuggerDBAddress);
    }

    function setFFhevmConfig(FFhevm.Config memory ffhevmConfig, address forgeVmAddress) internal {
        Impl.setFHEVM(
            FFhevmDebugConfigStruct({
                ACLAddress: ffhevmConfig.core.ACLAddress,
                TFHEExecutorAddress: ffhevmConfig.core.TFHEExecutorAddress,
                FHEPaymentAddress: ffhevmConfig.core.FHEPaymentAddress,
                KMSVerifierAddress: ffhevmConfig.core.KMSVerifierAddress,
                // FFhevm addresses
                TFHEDebuggerAddress: ffhevmConfig.debugger.TFHEDebuggerAddress,
                TFHEDebuggerDBAddress: ffhevmConfig.debugger.TFHEDebuggerDBAddress,
                forgeVmAddress: forgeVmAddress
            })
        );

        Gateway.setGateway(ffhevmConfig.gateway.GatewayContractAddress);
    }
}
