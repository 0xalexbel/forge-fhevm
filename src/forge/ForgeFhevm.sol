// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {TFHE} from "../debug/fhevm/lib/TFHE.sol";
import {FHEVMConfig} from "../debug/fhevm/lib/FHEVMConfig.sol";
import {IRandomGenerator} from "../common/interfaces/IRandomGenerator.sol";

import {ForgeFhevmConfig} from "./deploy/ForgeFhevmConfig.sol";
import {ForgeFhevmStorage, ForgeFhevmStorageLib} from "./deploy/ForgeFhevmStorage.sol";
import {FhevmCoreAddressesLib} from "./deploy/core/FhevmCoreAddressesLib.sol";
import {FhevmCoreDeployLib} from "./deploy/core/FhevmCoreDeployLib.sol";
import {FhevmGatewayAddressesLib} from "./deploy/gateway/FhevmGatewayAddressesLib.sol";
import {FhevmGatewayDeployLib} from "./deploy/gateway/FhevmGatewayDeployLib.sol";
import {FhevmDebuggerAddressesLib} from "./deploy/debugger/FhevmDebuggerAddressesLib.sol";
import {FhevmDebuggerDeployLib} from "./deploy/debugger/FhevmDebuggerDeployLib.sol";
import {DeterministicRandomGenerator} from "./utils/DeterministicRandomGenerator.sol";
import {
    IForgeStdVmSafe as IVmSafe,
    IForgeStdVmUnsafe as IVmUnsafe,
    forgeStdVmSafeAdd,
    forgeStdVmUnsafeAdd
} from "./interfaces/IForgeStdVm.sol";

//import {console} from "forge-std/src/console.sol";

library ForgeFhevm {
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);
    IVmUnsafe private constant vmUnsafe = IVmUnsafe(forgeStdVmUnsafeAdd);

    function __isForgeTest() private view returns (bool) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("IS_TEST()"));
        if (!success || returnData.length == 0) {
            return false;
        }
        return abi.decode(returnData, (bool));
    }

    function setUp() internal {
        require(__isForgeTest(), "FhevmDebugger must run in a forge Test contract");

        ForgeFhevmConfig memory deployConfig;
        deployConfig.initializeWithEnv();
        setUp(deployConfig);
    }

    function setUp(ForgeFhevmConfig memory deployConfig) internal {
        (IVmUnsafe.CallerMode callerMode, address msgSender, address txOrigin) = vmUnsafe.readCallers();

        if (uint8(callerMode) == 2) {
            vm.stopBroadcast();
        } else if (uint8(callerMode) == 4) {
            vmUnsafe.stopPrank();
        }

        _setUp(deployConfig);

        if (uint8(callerMode) == 2) {
            vm.startBroadcast(msgSender);
        } else if (uint8(callerMode) == 4) {
            vmUnsafe.startPrank(msgSender, txOrigin);
        }
    }

    function _setUp(ForgeFhevmConfig memory deployConfig) private {
        require(__isForgeTest(), "ForgeFhevm.setUp must be called from a forge Test contract.");

        ForgeFhevmStorage storage $ = ForgeFhevmStorageLib.get();
        require($.initialized == false, "FhevmDebugger already setUp");
        $.initialized = true;

        if (deployConfig.isCoprocessor) {
            FhevmCoreAddressesLib.checkCoprocessorAddress(deployConfig.coprocessorAccount.addr);
        }

        IRandomGenerator forgeFhevmRandomGenerator;

        // Deploy extra contracts using a different pk to avoid address conflicts.
        IVmSafe.Wallet memory wallet = vm.createWallet("forge-fhevm.IRandomGenerator.Wallet");
        vm.startBroadcast(wallet.privateKey);
        {
            if (deployConfig.useDeterministicRandomGenerator) {
                forgeFhevmRandomGenerator = IRandomGenerator(address(new DeterministicRandomGenerator(0)));
            } else {
                forgeFhevmRandomGenerator = IRandomGenerator(forgeStdVmSafeAdd);
            }
        }
        vm.stopBroadcast();

        // // Fhevm Debugger contracts
        // FhevmDebuggerDeployLib.FhevmDebuggerDeployment memory resDebugger;
        // vm.startBroadcast(deployConfig.fhevmDebuggerDeployer.privateKey);
        // {
        //     address debuggerRndGeneratorAddr;
        //     if (!deployConfig.useDeterministicRandomGenerator) {
        //         debuggerRndGeneratorAddr = forgeStdVmSafeAdd;
        //     }
        //     resDebugger = FhevmDebuggerDeployLib.deployFhevmDebugger(deployConfig.fhevmDebuggerDeployer.addr, debuggerRndGeneratorAddr);
        // }
        // vm.stopBroadcast();

        // Fhevm Core contracts
        FhevmCoreDeployLib.FhevmCoreDeployment memory resCore;
        vm.startBroadcast(deployConfig.fhevmDeployer.privateKey);
        {
            resCore = FhevmCoreDeployLib.deployFhevmCore(
                deployConfig.fhevmDeployer.addr, deployConfig.isCoprocessor, deployConfig.getKmsSignersAddr()
            );
        }
        vm.stopBroadcast();

        // Fhevm Gateway contracts
        FhevmGatewayDeployLib.FhevmGatewayDeployment memory resGateway;
        vm.startBroadcast(deployConfig.gatewayDeployer.privateKey);
        {
            resGateway = FhevmGatewayDeployLib.deployFhevmGateway(
                deployConfig.gatewayDeployer.addr, deployConfig.gatewayRelayer.addr
            );
        }
        vm.stopBroadcast();

        // Fhevm Debugger contracts
        FhevmDebuggerDeployLib.FhevmDebuggerDeployment memory resDebugger;
        vm.startBroadcast(deployConfig.fhevmDebuggerDeployer.privateKey);
        {
            address debuggerRndGeneratorAddr;
            if (!deployConfig.useDeterministicRandomGenerator) {
                debuggerRndGeneratorAddr = forgeStdVmSafeAdd;
            }
            resDebugger = FhevmDebuggerDeployLib.deployFhevmDebugger(deployConfig.fhevmDebuggerDeployer.addr, debuggerRndGeneratorAddr);
        }
        vm.stopBroadcast();

        $.deployConfig.storageCopyFrom(deployConfig);
        // Core
        $.fhevmConfig.ACLAddress = resCore.ACLAddress;
        $.fhevmConfig.FHEPaymentAddress = resCore.FHEPaymentAddress;
        $.fhevmConfig.KMSVerifierAddress = resCore.KMSVerifierAddress;
        $.fhevmConfig.TFHEExecutorAddress = resCore.TFHEExecutorAddress;
        $.InputVerifierCoprocessorAddress = resCore.InputVerifierCoprocessorAddress;
        $.InputVerifierNativeAddress = resCore.InputVerifierNativeAddress;
        $.InputVerifierAddress = resCore.InputVerifierAddress;
        // Gateway
        $.GatewayContractAddress = resGateway.GatewayContractAddress;
        // Debugger
        $.TFHEDebuggerAddress = resDebugger.TFHEDebuggerAddress;
        // Random generator
        $.IRandomGeneratorAddress = address(forgeFhevmRandomGenerator);

        TFHE.setFHEVM(FHEVMConfig.defaultConfig());
    }
}
