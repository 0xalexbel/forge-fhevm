// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {TFHE} from "../fhevm-debug/lib/TFHE.sol";
import {Gateway} from "../fhevm-debug/gateway/lib/Gateway.sol";

import {FFhevmConfigLib} from "./config/FFhevmConfigLib.sol";
import {FFhevmDeployConfigLib} from "./config/FFhevmDeployConfigLib.sol";

import {
    IForgeStdVmSafe as IVmSafe,
    IForgeStdVmUnsafe as IVmUnsafe,
    forgeStdVmSafeAdd,
    forgeStdVmUnsafeAdd
} from "./interfaces/IForgeStdVm.sol";
import {FFhevm} from "../../FFhevm.sol";

import {CoreAddressesLib} from "./deploy/core/CoreAddressesLib.sol";
import {CoreDeployLib} from "./deploy/core/CoreDeployLib.sol";
import {GatewayAddressesLib} from "./deploy/gateway/GatewayAddressesLib.sol";
import {GatewayDeployLib} from "./deploy/gateway/GatewayDeployLib.sol";
import {DebuggerAddressesLib} from "./deploy/debugger/DebuggerAddressesLib.sol";
import {DebuggerDeployLib} from "./deploy/debugger/DebuggerDeployLib.sol";
import {FFhevmPrecompileDeployLib} from "./precompile/FFhevmPrecompileDeployLib.sol";

library FFhevmSetUp {
    // solhint-disable const-name-snakecase
    IVmSafe internal constant vmSafe = IVmSafe(forgeStdVmSafeAdd);

    function setUpFullSuite() internal {
        FFhevm.DeployConfig memory deployConfig = FFhevmDeployConfigLib.initializeWithEnv();
        setUpFullSuite(deployConfig);
    }

    function setUpFullSuite(FFhevm.DeployConfig memory deployConfig) internal {
        FFhevm.CoreAddresses memory coreAddresses = setUpCore(deployConfig);
        FFhevm.GatewayAddresses memory gatewayAddresses = setUpGateway(deployConfig);
        FFhevm.DebuggerAddresses memory debuggerAddresses = setUpDebugger(deployConfig);

        FFhevm.Config memory ffhevmConfig;
        ffhevmConfig.deployConfig = deployConfig;
        ffhevmConfig.core = coreAddresses;
        ffhevmConfig.gateway = gatewayAddresses;
        ffhevmConfig.debugger = debuggerAddresses;

        if (!deployConfig.useDeterministicRandomGenerator) {
            // use forge Vm as random generator
            ffhevmConfig.IRandomGeneratorAddress = forgeStdVmSafeAdd;
        }

        setUpPrecompile(ffhevmConfig);

        //Setup FHEVMConfig + Gateway + Debugger
        FFhevmConfigLib.setFFhevmConfig(ffhevmConfig, forgeStdVmSafeAdd);
    }

    function setUpCore(FFhevm.DeployConfig memory deployConfig)
        internal
        returns (FFhevm.CoreAddresses memory coreAddresses)
    {
        coreAddresses = CoreAddressesLib.readEnvAddresses();

        // Shall we deploy the core suite ?
        if (coreAddresses.ACLAddress == address(0)) {
            // Fhevm Core contracts
            address coprocessorAccountAddr =
                (deployConfig.isCoprocessor) ? deployConfig.coprocessorAccount.addr : address(0);

            coreAddresses = CoreDeployLib.deployFhevmCore(
                deployConfig.fhevmDeployer.addr,
                coprocessorAccountAddr,
                FFhevmDeployConfigLib.getKmsSignersAddr(deployConfig)
            );
        }
    }

    function setUpGateway(FFhevm.DeployConfig memory deployConfig)
        internal
        returns (FFhevm.GatewayAddresses memory gatewayAddresses)
    {
        gatewayAddresses = GatewayAddressesLib.readEnvAddresses();

        // Shall we deploy the gateway suite ?
        if (gatewayAddresses.GatewayContractAddress == address(0)) {
            gatewayAddresses =
                GatewayDeployLib.deployFhevmGateway(deployConfig.gatewayDeployer.addr, deployConfig.gatewayRelayer.addr);
        }
    }

    function setUpDebugger(FFhevm.DeployConfig memory deployConfig)
        internal
        returns (FFhevm.DebuggerAddresses memory debuggerAddresses)
    {
        debuggerAddresses = DebuggerAddressesLib.readEnvAddresses();

        // Shall we deploy the debugger suite ?
        if (debuggerAddresses.TFHEDebuggerAddress == address(0)) {
            debuggerAddresses = DebuggerDeployLib.deployFhevmDebugger(
                deployConfig.ffhevmDebuggerDeployer.addr,
                (deployConfig.useDeterministicRandomGenerator) ? address(0) : forgeStdVmSafeAdd
            );
        }
    }

    function setUpPrecompile(FFhevm.Config memory ffhevmConfig) internal {
        FFhevmPrecompileDeployLib.deployFFhevmPrecompile(ffhevmConfig);
    }
}
