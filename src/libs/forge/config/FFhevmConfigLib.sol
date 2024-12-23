// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {FFhevm} from "../../../FFhevm.sol";

import {FFhevmDebugConfigStruct} from "../../debugger/config/FFhevmDebugConfig.sol";
import {Gateway} from "../../fhevm-debug/gateway/lib/Gateway.sol";
import {Impl} from "../../fhevm-debug/lib/Impl.sol";

import {CoreAddressesLib} from "../deploy/core/CoreAddressesLib.sol";
import {GatewayAddressesLib} from "../deploy/gateway/GatewayAddressesLib.sol";
import {DebuggerAddressesLib} from "../deploy/debugger/DebuggerAddressesLib.sol";
import {FFhevmDeployConfigLib} from "./FFhevmDeployConfigLib.sol";

library FFhevmConfigLib {
    function copyToStorage(FFhevm.Config memory src, FFhevm.Config storage dst) internal {
        FFhevmDeployConfigLib.copyToStorage(src.deployConfig, dst.deployConfig);

        // Random generator
        dst.IRandomGeneratorAddress = src.IRandomGeneratorAddress;

        // Fhevm Core
        dst.core.ACLAddress = src.core.ACLAddress;
        dst.core.TFHEExecutorAddress = src.core.TFHEExecutorAddress;
        dst.core.FHEGasLimitAddress = src.core.FHEGasLimitAddress;
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
        config.core =
            CoreAddressesLib.computeAddresses(config.deployConfig.fhevmDeployer.addr, config.deployConfig.isCoprocessor);
        // Gateway addresses
        config.gateway = GatewayAddressesLib.computeAddresses(config.deployConfig.fhevmDeployer.addr);
        // Debugger addresses
        config.debugger = DebuggerAddressesLib.computeAddresses(config.deployConfig.fhevmDeployer.addr);
    }

    function setFFhevmConfig(FFhevm.Config memory ffhevmConfig, address forgeVmAddress) internal {
        Impl.setFHEVM(
            FFhevmDebugConfigStruct({
                ACLAddress: ffhevmConfig.core.ACLAddress,
                TFHEExecutorAddress: ffhevmConfig.core.TFHEExecutorAddress,
                FHEGasLimitAddress: ffhevmConfig.core.FHEGasLimitAddress,
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
