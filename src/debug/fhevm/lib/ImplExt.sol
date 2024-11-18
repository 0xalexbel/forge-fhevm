// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {GasMetering} from "../../../common/GasMetering.sol";
import {ITFHEDebugger} from "../../debugger/interfaces/ITFHEDebugger.sol";
import {Impl, ITFHEExecutor} from "./Impl.sol";
import {FHEVMConfig} from "../../fhevm/lib/FHEVMConfig.sol";

library ImplExt {
    function addUnchecked(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FHEVMConfig.FHEVMConfigStruct storage $ = Impl.getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheAdd(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///
        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheAddUnchecked(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = Impl.getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheSub(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///
        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheSubUnchecked(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = Impl.getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheMul(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///
        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheMulUnchecked(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function divUnchecked(uint256 lhs, uint256 rhs) internal returns (uint256 result) {
        bytes1 scalarByte = 0x01;
        FHEVMConfig.FHEVMConfigStruct storage $ = Impl.getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheDiv(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///
        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheDivUnchecked(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }
}
