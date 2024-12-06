// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {TFHEHandle} from "../../common/TFHEHandle.sol";
import {FFhevmDebugConfigStruct} from "../../debugger/config/FFhevmDebugConfig.sol";
import {FHEVMConfigLocation} from "../lib/FHEVMConfigLocation.sol";

library TFHEzk {
    function __aclAddress() internal view returns (address) {
        FFhevmDebugConfigStruct storage $;
        assembly {
            $.slot := FHEVMConfigLocation
        }
        return $.ACLAddress;
    }

    // ====================================================================== //
    //
    //                  ⭐️ API: precompute handle ⭐️
    //
    // ====================================================================== //

    function add(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheAdd, lhs, rhs, false, __aclAddress());
    }

    function sub(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheSub, lhs, rhs, false, __aclAddress());
    }

    function mul(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheMul, lhs, rhs, false, __aclAddress());
    }

    function div(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheDiv, lhs, rhs, false, __aclAddress());
    }

    function rem(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheRem, lhs, rhs, false, __aclAddress());
    }

    function and(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheBitAnd, lhs, rhs, false, __aclAddress());
    }

    function or(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheBitOr, lhs, rhs, false, __aclAddress());
    }

    function xor(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheBitXor, lhs, rhs, false, __aclAddress());
    }

    function shl(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheShl, lhs, rhs, false, __aclAddress());
    }

    function shr(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheShr, lhs, rhs, false, __aclAddress());
    }

    function eq(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryBoolOp(TFHEHandle.Operators.fheEq, lhs, rhs, false, __aclAddress());
    }

    function ne(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryBoolOp(TFHEHandle.Operators.fheNe, lhs, rhs, false, __aclAddress());
    }

    function ge(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryBoolOp(TFHEHandle.Operators.fheGe, lhs, rhs, false, __aclAddress());
    }

    function gt(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryBoolOp(TFHEHandle.Operators.fheGt, lhs, rhs, false, __aclAddress());
    }

    function le(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryBoolOp(TFHEHandle.Operators.fheLe, lhs, rhs, false, __aclAddress());
    }

    function lt(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryBoolOp(TFHEHandle.Operators.fheLt, lhs, rhs, false, __aclAddress());
    }

    function addScalar(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheAdd, lhs, rhs, true, __aclAddress());
    }

    function subScalar(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheSub, lhs, rhs, true, __aclAddress());
    }

    function mulScalar(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheMul, lhs, rhs, true, __aclAddress());
    }

    function divScalar(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheDiv, lhs, rhs, true, __aclAddress());
    }

    function remScalar(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheRem, lhs, rhs, true, __aclAddress());
    }

    function shlScalar(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheShl, lhs, rhs, true, __aclAddress());
    }

    function shrScalar(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheShr, lhs, rhs, true, __aclAddress());
    }

    function rotlScalar(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheRotl, lhs, rhs, true, __aclAddress());
    }

    function rotrScalar(uint256 lhs, uint256 rhs) internal view returns (uint256) {
        return TFHEHandle.precomputeBinaryNumOp(TFHEHandle.Operators.fheRotr, lhs, rhs, true, __aclAddress());
    }
}
