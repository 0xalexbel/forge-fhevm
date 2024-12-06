// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {ITFHEExecutorDebugger} from "../../debugger/impl/interfaces/ITFHEExecutorDebugger.sol";
import {ITFHEExecutor} from "../../core/interfaces/ITFHEExecutor.sol";
import {FFhevmDebugConfigStruct} from "../../debugger/config/FFhevmDebugConfig.sol";

import {GasMetering} from "./GasMetering.sol";
import {Impl} from "./Impl.sol";

library ImplExt {
    function addUnchecked(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = Impl.getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheAdd(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheAddUnchecked(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function subUnchecked(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = Impl.getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheSub(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheSubUnchecked(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function mulUnchecked(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = Impl.getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheMul(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheMulUnchecked(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function divUnchecked(uint256 lhs, uint256 rhs) internal returns (uint256 result) {
        bytes1 scalarByte = 0x01;
        FFhevmDebugConfigStruct storage $ = Impl.getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheDiv(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheDivUnchecked(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }
}
