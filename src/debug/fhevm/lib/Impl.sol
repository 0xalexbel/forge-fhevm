// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import "../../../common/GasMetering.sol";
import "../../debugger/interfaces/ITFHEDebugger.sol";

import "./TFHE.sol";
import "./FHEVMConfig.sol";

import {console} from "forge-std/src/console.sol";

interface ITFHEExecutor {
    function fheAdd(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheSub(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheMul(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheDiv(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheRem(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheBitAnd(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheBitOr(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheBitXor(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheShl(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheShr(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheRotl(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheRotr(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheEq(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheNe(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheGe(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheGt(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheLe(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheLt(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheMin(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheMax(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheNeg(uint256 ct) external returns (uint256 result);
    function fheNot(uint256 ct) external returns (uint256 result);
    function verifyCiphertext(bytes32 inputHandle, address callerAddress, bytes memory inputProof, bytes1 inputType)
        external
        returns (uint256 result);
    function cast(uint256 ct, bytes1 toType) external returns (uint256 result);
    function trivialEncrypt(uint256 ct, bytes1 toType) external returns (uint256 result);
    function trivialEncrypt(bytes memory ct, bytes1 toType) external returns (uint256 result);
    function fheEq(uint256 lhs, bytes memory rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheNe(uint256 lhs, bytes memory rhs, bytes1 scalarByte) external returns (uint256 result);
    function fheIfThenElse(uint256 control, uint256 ifTrue, uint256 ifFalse) external returns (uint256 result);
    function fheRand(bytes1 randType) external returns (uint256 result);
    function fheRandBounded(uint256 upperBound, bytes1 randType) external returns (uint256 result);
}

interface IACL {
    function allowTransient(uint256 ciphertext, address account) external;
    function allow(uint256 handle, address account) external;
    function cleanTransientStorage() external;
    function isAllowed(uint256 handle, address account) external view returns (bool);
    function allowForDecryption(uint256[] memory handlesList) external;
}

library Impl {
    // keccak256(abi.encode(uint256(keccak256("fhevm.storage.FHEVMConfig")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant FHEVMConfigLocation = 0xed8d60e34876f751cc8b014c560745351147d9de11b9347c854e881b128ea600;

    function getFHEVMConfig() internal view returns (FHEVMConfig.FHEVMConfigStruct storage $) {
        assembly {
            $.slot := FHEVMConfigLocation
        }
        /// This is crucial to help debugging any contract setup
        /// The problem is even trickier when contract A creates contract B which creates contract C
        /// with C using TFHE. It can be painfull to find out why nothing is running...
        require(
            $.TFHEExecutorAddress != address(0),
            "Null TFHEExecutor address. A contract calls a function from the TFHE library without having initialized it beforehand. Call 'TFHE.setFHEVM(FHEVMConfig.defaultConfig())' first!"
        );
        require(
            $.ACLAddress != address(0),
            "Null ACLAddress address. A contract calls a function from the TFHE library without having initialized it beforehand. Call 'TFHE.setFHEVM(FHEVMConfig.defaultConfig())' first!"
        );
        require(
            $.FHEPaymentAddress != address(0),
            "Null FHEPaymentAddress address. A contract calls a function from the TFHE library without having initialized it beforehand. Call 'TFHE.setFHEVM(FHEVMConfig.defaultConfig())' first!"
        );
        require(
            $.KMSVerifierAddress != address(0),
            "Null KMSVerifierAddress address. A contract calls a function from the TFHE library without having initialized it beforehand. Call 'TFHE.setFHEVM(FHEVMConfig.defaultConfig())' first!"
        );
        require(
            $.TFHEDebuggerAddress != address(0),
            "Null TFHEDebuggerAddress address. A contract calls a function from the TFHE library without having initialized it beforehand. Call 'TFHE.setFHEVM(FHEVMConfig.defaultConfig())' first!"
        );
    }

    function setFHEVM(FHEVMConfig.FHEVMConfigStruct memory fhevmConfig) internal {
        FHEVMConfig.FHEVMConfigStruct storage $;
        assembly {
            $.slot := FHEVMConfigLocation
        }
        $.ACLAddress = fhevmConfig.ACLAddress;
        $.TFHEExecutorAddress = fhevmConfig.TFHEExecutorAddress;
        $.FHEPaymentAddress = fhevmConfig.FHEPaymentAddress;
        $.KMSVerifierAddress = fhevmConfig.KMSVerifierAddress;
        //forge-fhevm Debugger
        $.TFHEDebuggerAddress = fhevmConfig.TFHEDebuggerAddress;
        $.forgeVmAddress = fhevmConfig.forgeVmAddress;
    }
    /// End forge-fhevm patch

    function add(uint256 lhs, uint256 rhs, bool scalar) internal returns (uint256 result) {
        bytes1 scalarByte;
        if (scalar) {
            scalarByte = 0x01;
        } else {
            scalarByte = 0x00;
        }
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheAdd(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///
        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheAdd(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheSub(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///
        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheSub(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheMul(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///
        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheMul(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function div(uint256 lhs, uint256 rhs) internal returns (uint256 result) {
        bytes1 scalarByte = 0x01;
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheDiv(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///
        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheDiv(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function rem(uint256 lhs, uint256 rhs) internal returns (uint256 result) {
        bytes1 scalarByte = 0x01;
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheRem(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///
        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheRem(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheBitAnd(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///
        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheBitAnd(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheBitOr(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheBitOr(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheBitXor(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheBitXor(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheShl(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheShl(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheShr(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheShr(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheRotl(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheRotl(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheRotr(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheRotr(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheEq(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheEq(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheNe(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheNe(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheGe(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheGe(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheGt(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheGt(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheLe(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheLe(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheLt(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheLt(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheMin(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheMin(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheMax(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheMax(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function neg(uint256 ct) internal returns (uint256 result) {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheNeg(ct);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheNeg(result, ct);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function not(uint256 ct) internal returns (uint256 result) {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheNot(ct);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheNot(result, ct);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    // If 'control's value is 'true', the result has the same value as 'ifTrue'.
    // If 'control's value is 'false', the result has the same value as 'ifFalse'.
    function select(uint256 control, uint256 ifTrue, uint256 ifFalse) internal returns (uint256 result) {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheIfThenElse(control, ifTrue, ifFalse);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheIfThenElse(result, control, ifTrue, ifFalse);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function verify(bytes32 inputHandle, bytes memory inputProof, uint8 toType) internal returns (uint256 result) {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        try ITFHEExecutor($.TFHEExecutorAddress).verifyCiphertext(inputHandle, msg.sender, inputProof, bytes1(toType))
        returns (uint256 res) {
            result = res;
            ///
            /// Begin forge-fhevm patch
            ///

            GasMetering.pause($.forgeVmAddress);
            ITFHEDebugger($.TFHEDebuggerAddress).verifyCiphertext(
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
            ITFHEDebugger($.TFHEDebuggerAddress).verifyCiphertext(
                0, inputHandle, msg.sender, inputProof, bytes1(toType)
            );
            GasMetering.resume($.forgeVmAddress);
            /// End forge-fhevm patch
            revert(reason);
        }
    }

    function cast(uint256 ciphertext, uint8 toType) internal returns (uint256 result) {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).cast(ciphertext, bytes1(toType));
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).cast(result, ciphertext, bytes1(toType));
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function trivialEncrypt(uint256 value, uint8 toType) internal returns (uint256 result) {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).trivialEncrypt(value, bytes1(toType));
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).trivialEncrypt(result, value, bytes1(toType));
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function trivialEncrypt(bytes memory value, uint8 toType) internal returns (uint256 result) {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).trivialEncrypt(value, bytes1(toType));
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).trivialEncrypt(result, value, bytes1(toType));
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheEq(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheEq(result, lhs, rhs, scalarByte);
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
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheNe(lhs, rhs, scalarByte);
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheNe(result, lhs, rhs, scalarByte);
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function rand(uint8 randType) internal returns (uint256 result) {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheRand(bytes1(randType));
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheRand(result, bytes1(randType));
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function randBounded(uint256 upperBound, uint8 randType) internal returns (uint256 result) {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        result = ITFHEExecutor($.TFHEExecutorAddress).fheRandBounded(upperBound, bytes1(randType));
        ///
        /// Begin forge-fhevm patch
        ///

        GasMetering.pause($.forgeVmAddress);
        ITFHEDebugger($.TFHEDebuggerAddress).fheRandBounded(result, upperBound, bytes1(randType));
        GasMetering.resume($.forgeVmAddress);
        /// End forge-fhevm patch
    }

    function allowTransient(uint256 handle, address account) internal {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        IACL($.ACLAddress).allowTransient(handle, account);
    }

    function allow(uint256 handle, address account) internal {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        IACL($.ACLAddress).allow(handle, account);
    }

    function cleanTransientStorage() internal {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        IACL($.ACLAddress).cleanTransientStorage();
    }

    function isAllowed(uint256 handle, address account) internal view returns (bool) {
        FHEVMConfig.FHEVMConfigStruct storage $ = getFHEVMConfig();
        return IACL($.ACLAddress).isAllowed(handle, account);
    }
}
