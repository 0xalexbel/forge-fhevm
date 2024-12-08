// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {FFhevmDebugConfigStruct} from "../../config/FFhevmDebugConfig.sol";

interface ITFHEExecutorDebugger {
    error InvalidFhevmConfigMissingAddress();
    error InvalidFhevmConfigInvalidDebuggerAddress(address debuggerAddress);
    error InvalidFhevmConfigInvalidDebuggerDBAddress(address debuggerDBAddress);
    error InvalidFhevmConfigAddressMismatch();
    error InvalidFhevmConfigInvalidCoreContract(address contractAddress);
    error VerifyCipherTextFailed(uint256 handle, address contractAddress, address userAddress);

    function verifyFFhevmDebuggerConfig(FFhevmDebugConfigStruct memory ffhevmDebuggerConfig) external;

    function fheAdd(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheSub(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheMul(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheDiv(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheRem(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheBitAnd(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheBitOr(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheBitXor(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheShl(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheShr(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheRotl(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheRotr(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheEq(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheEq(uint256 result, uint256 lhs, bytes calldata rhs, bytes1 scalarByte) external;
    function fheNe(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheNe(uint256 result, uint256 lhs, bytes calldata rhs, bytes1 scalarByte) external;
    function fheGe(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheGt(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheLe(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheLt(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheMin(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheMax(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheNeg(uint256 result, uint256 ct) external;
    function fheNot(uint256 result, uint256 ct) external;
    function verifyCiphertext(
        uint256 result,
        bytes32 inputHandle,
        address callerAddress,
        bytes calldata inputProof,
        bytes1 inputType
    ) external;
    function cast(uint256 result, uint256 ct, bytes1 toType) external;
    function trivialEncrypt(uint256 result, uint256 pt, bytes1 toType) external;
    function trivialEncrypt(uint256 result, bytes calldata pt, bytes1 toType) external;
    function fheIfThenElse(uint256 result, uint256 control, uint256 ifTrue, uint256 ifFalse) external;
    function fheRand(uint256 result, bytes1 randType) external;
    function fheRandBounded(uint256 result, uint256 upperBound, bytes1 randType) external;

    // Unchecked ops
    function fheAddUnchecked(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheSubUnchecked(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheMulUnchecked(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
    function fheDivUnchecked(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external;
}
