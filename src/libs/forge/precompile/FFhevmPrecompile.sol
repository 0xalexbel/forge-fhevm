// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {AddressLib} from "../../common/AddressLib.sol";

import {TFHE} from "../../fhevm-debug/lib/TFHE.sol";

import {ITFHEExecutorDebugger} from "../../debugger/impl/interfaces/ITFHEExecutorDebugger.sol";

import {FFhevm} from "../../../FFhevm.sol";

import {
    IForgeStdVmSafe as IVmSafe,
    IForgeStdVmUnsafe as IVmUnsafe,
    forgeStdVmSafeAdd,
    forgeStdVmUnsafeAdd
} from "../interfaces/IForgeStdVm.sol";
import {IFFhevmBase} from "../interfaces/IFFhevmBase.sol";
import {FFhevmConfigLib} from "../config/FFhevmConfigLib.sol";

abstract contract FFhevmPrecompile is IFFhevmBase {
    FFhevm.Config private _fhevmConfig;

    // solhint-disable const-name-snakecase
    IVmSafe internal constant vmSafe = IVmSafe(forgeStdVmSafeAdd);
    IVmUnsafe internal constant vmUnsafe = IVmUnsafe(forgeStdVmUnsafeAdd);

    bool private gasMeteringOff;

    modifier noGasMetering() {
        vmSafe.pauseGasMetering();
        // To prevent turning gas monitoring back on with nested functions that use this modifier,
        // we check if gasMetering started in the off position. If it did, we don't want to turn
        // it back on until we exit the top level function that used the modifier
        //
        // i.e. funcA() noGasMetering { funcB() }, where funcB has noGasMetering as well.
        // funcA will have `gasStartedOff` as false, funcB will have it as true,
        // so we only turn metering back on at the end of the funcA
        bool gasStartedOff = gasMeteringOff;
        gasMeteringOff = true;

        _;

        // if gas metering was on when this modifier was called, turn it back on at the end
        if (!gasStartedOff) {
            gasMeteringOff = false;
            vmSafe.resumeGasMetering();
        }
    }

    modifier debuggerDeployed() {
        if (_fhevmConfig.debugger.TFHEDebuggerAddress == address(0)) {
            revert("forge-fhevm: debugger address is null");
        }
        if (!AddressLib.isDeployed(_fhevmConfig.debugger.TFHEDebuggerAddress)) {
            revert("forge-fhevm debugger is not deployed");
        }
        _;
    }

    constructor(FFhevm.Config memory ffhevmConfig) {
        FFhevmConfigLib.copyToStorage(ffhevmConfig, _fhevmConfig);
        // Call setFHEVM + Gateway.setGateway + setup debugger config
        // so every Precompile contract can call TFHE, Gateway and FhevmDebug
        // libraries
        FFhevmConfigLib.setFFhevmConfig(ffhevmConfig, forgeStdVmSafeAdd);
    }

    function _config() internal view returns (FFhevm.Config storage) {
        return _fhevmConfig;
    }

    function isCoprocessor() external view returns (bool) {
        return _fhevmConfig.deployConfig.isCoprocessor;
    }

    function getConfig() external noGasMetering returns (FFhevm.Config memory) {
        return _fhevmConfig;
    }
}
