// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {AddressLib} from "../../common/AddressLib.sol";
import {IACL} from "../../core/interfaces/IACL.sol";
import {ITFHEExecutor} from "../../core/interfaces/ITFHEExecutor.sol";
import {ITFHEExecutorDebugger} from "../../debugger/impl/interfaces/ITFHEExecutorDebugger.sol";
import {FFhevmDebugConfigStruct} from "../../debugger/config/FFhevmDebugConfig.sol";

import {GasMetering} from "./GasMetering.sol";

import {TFHE} from "./TFHE.sol";
import {FHEVMConfigLocation} from "./FHEVMConfigLocation.sol";

//import {console} from "forge-std/src/console.sol";

library Impl {
    function getFHEVMConfig() internal view returns (FFhevmDebugConfigStruct storage $) {
        assembly {
            $.slot := FHEVMConfigLocation
        }
        /// This is crucial to help debugging any contract setup
        /// The problem is even trickier when contract A creates contract B which creates contract C
        /// with C using TFHE. It can be painfull to find out why nothing is running...
        require(
            $.TFHEExecutorAddress != address(0) || $.ACLAddress != address(0) || $.FHEGasLimitAddress != address(0)
                || $.KMSVerifierAddress != address(0),
            "A contract calls a function from the TFHE library without having initialized it beforehand. Call 'TFHE.setFHEVM(<your debug config>)' first!"
        );
        require($.TFHEDebuggerAddress != address(0), "Missing TFHEDebuggerAddress address.");
        require($.TFHEDebuggerDBAddress != address(0), "Missing TFHEDebuggerDBAddress address.");
    }

    function setFHEVM(FFhevmDebugConfigStruct memory fhevmConfig) internal {
        require(
            fhevmConfig.TFHEDebuggerAddress != address(0),
            "FFhevm error: the selected FHEVM config is not a debug config."
        );
        if (!AddressLib.isDeployed(fhevmConfig.TFHEDebuggerAddress)) {
            revert("FFhevm error: The FFhevm debugger is not installed. Please call FFhevm.setUp() first!");
        }
        ITFHEExecutorDebugger(fhevmConfig.TFHEDebuggerAddress).verifyFFhevmDebuggerConfig(fhevmConfig);

        FFhevmDebugConfigStruct storage $;
        assembly {
            $.slot := FHEVMConfigLocation
        }
        $.ACLAddress = fhevmConfig.ACLAddress;
        $.TFHEExecutorAddress = fhevmConfig.TFHEExecutorAddress;
        $.FHEGasLimitAddress = fhevmConfig.FHEGasLimitAddress;
        $.KMSVerifierAddress = fhevmConfig.KMSVerifierAddress;
        // Extra
        $.TFHEDebuggerAddress = fhevmConfig.TFHEDebuggerAddress;
        $.TFHEDebuggerDBAddress = fhevmConfig.TFHEDebuggerDBAddress;
        $.forgeVmAddress = fhevmConfig.forgeVmAddress;
    }

    function add(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheAdd(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheAdd(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function sub(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheSub(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheSub(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function mul(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheMul(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheMul(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function div(uint256 lhs, uint256 rhs) internal returns (uint256 result) {
        bytes1 scalarByte = 0x01;
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheDiv(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheDiv(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function rem(uint256 lhs, uint256 rhs) internal returns (uint256 result) {
        bytes1 scalarByte = 0x01;
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheRem(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheRem(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function and(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheBitAnd(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheBitAnd(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function or(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheBitOr(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheBitOr(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function xor(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheBitXor(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheBitXor(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function shl(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheShl(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheShl(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function shr(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheShr(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheShr(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function rotl(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheRotl(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheRotl(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function rotr(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheRotr(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheRotr(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function eq(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheEq(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheEq(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function ne(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheNe(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheNe(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function ge(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheGe(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheGe(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function gt(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheGt(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheGt(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function le(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheLe(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheLe(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function lt(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheLt(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheLt(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function min(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheMin(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheMin(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function max(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheMax(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheMax(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function neg(uint256 ct) internal returns (uint256 result) {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheNeg(ct);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheNeg(result, ct);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function not(uint256 ct) internal returns (uint256 result) {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheNot(ct);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheNot(result, ct);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    // If 'control's value is 'true', the result has the same value as 'ifTrue'.
    // If 'control's value is 'false', the result has the same value as 'ifFalse'.
    function select(uint256 control, uint256 ifTrue, uint256 ifFalse) internal returns (uint256 result) {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheIfThenElse(control, ifTrue, ifFalse);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheIfThenElse(result, control, ifTrue, ifFalse);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function verify(bytes32 inputHandle, bytes memory inputProof, uint8 toType) internal returns (uint256 result) {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        try ITFHEExecutor($.TFHEExecutorAddress).verifyCiphertext(inputHandle, msg.sender, inputProof, bytes1(toType))
        returns (uint256 res) {
            result = res;
            ///
            /// Begin forge-fhevm patch
            ///
            GasMetering.pause($.forgeVmAddress);
            ITFHEExecutorDebugger($.TFHEDebuggerAddress).verifyCiphertext(
                result, inputHandle, msg.sender, inputProof, bytes1(toType)
            );
            GasMetering.resume($.forgeVmAddress);
            /// End forge-fhevm patch
            IACL($.ACLAddress).allowTransient(result, msg.sender);
        } catch Error(string memory reason) {
            ///
            /// Begin forge-fhevm patch
            ///

            GasMetering.pause($.forgeVmAddress);
            ITFHEExecutorDebugger($.TFHEDebuggerAddress).verifyCiphertext(
                0, inputHandle, msg.sender, inputProof, bytes1(toType)
            );
            GasMetering.resume($.forgeVmAddress);
            /// End forge-fhevm patch
            revert(reason);
        }
    }

    function cast(uint256 ciphertext, uint8 toType) internal returns (uint256 result) {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).cast(ciphertext, bytes1(toType));
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).cast(result, ciphertext, bytes1(toType));
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function trivialEncrypt(uint256 value, uint8 toType) internal returns (uint256 result) {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).trivialEncrypt(value, bytes1(toType));
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).trivialEncrypt(result, value, bytes1(toType));
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function trivialEncrypt(bytes memory value, uint8 toType) internal returns (uint256 result) {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).trivialEncrypt(value, bytes1(toType));
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).trivialEncrypt(result, value, bytes1(toType));
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function eq(uint256 lhs, bytes memory rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheEq(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheEq(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function ne(uint256 lhs, bytes memory rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheNe(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheNe(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function rand(uint8 randType) internal returns (uint256 result) {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheRand(bytes1(randType));
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheRand(result, bytes1(randType));
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function randBounded(uint256 upperBound, uint8 randType) internal returns (uint256 result) {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheRandBounded(upperBound, bytes1(randType));
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEExecutorDebugger($.TFHEDebuggerAddress).fheRandBounded(result, upperBound, bytes1(randType));
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function allowTransient(uint256 handle, address account) internal {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        IACL($.ACLAddress).allowTransient(handle, account);
    }

    function allow(uint256 handle, address account) internal {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        IACL($.ACLAddress).allow(handle, account);
    }

    function cleanTransientStorage() internal {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        IACL($.ACLAddress).cleanTransientStorage();
    }

    function isAllowed(uint256 handle, address account) internal view returns (bool) {
        FFhevmDebugConfigStruct storage $ = getFHEVMConfig();
        return IACL($.ACLAddress).isAllowed(handle, account);
    }
}
