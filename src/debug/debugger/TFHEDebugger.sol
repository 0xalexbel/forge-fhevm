// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Common} from "../fhevm/lib/TFHE.sol";

import {IRandomGenerator} from "../../common/interfaces/IRandomGenerator.sol";
import {ITFHEDebugger} from "./interfaces/ITFHEDebugger.sol";
import {MathLib} from "./MathLib.sol";
import {DBLib} from "./DBLib.sol";

//import {console} from "forge-std/src/console.sol";

/*
    uint8 internal constant ebool_t = 0;
    uint8 internal constant euint4_t = 1;
    uint8 internal constant euint8_t = 2;
    uint8 internal constant euint16_t = 3;
    uint8 internal constant euint32_t = 4;
    uint8 internal constant euint64_t = 5;
    uint8 internal constant euint128_t = 6;
    uint8 internal constant euint160_t = 7;
    uint8 internal constant euint256_t = 8;
    uint8 internal constant ebytes64_t = 9;
    uint8 internal constant ebytes128_t = 10;
    uint8 internal constant ebytes256_t = 11;
*/

enum ArithmeticCheckingMode {
    OperandsOnly,
    OperandsAndResult,
    ResultOnly
}

contract TFHEDebugger is Ownable, ITFHEDebugger {
    // Note: IS_TFHE_DEBUGGER() must return true.
    bool public IS_TFHE_DEBUGGER = true;

    bytes32 private constant _randomSeed = keccak256("TFHEDebuggerDeterministicRandom");
    uint256 _randomCount;

    uint256 private _throwIfArithmeticError;
    ArithmeticCheckingMode private _arithmeticCheckingMode;

    address private _randomGeneratorAddress;
    bool private _useForge;

    DBLib.Set private _db;

    using DBLib for DBLib.Set;

    constructor(address initialOwner, address randomGeneratorAddress, bool useForge) Ownable(initialOwner) {
        _randomGeneratorAddress = randomGeneratorAddress;
        _useForge = useForge;
    }

    function __randomUint() private returns (uint256 result) {
        if (_randomGeneratorAddress == address(0)) {
            // Deterministic
            result = uint256(keccak256(bytes.concat(_randomSeed, bytes32(_randomCount))));
        } else {
            // using vm.randomUint()
            result = IRandomGenerator(_randomGeneratorAddress).randomUint();
        }
        _randomCount++;
    }

    function getVersion() external pure returns (string memory) {
        return "TFHEDebugger 0.1.0";
    }

    function useForgeVm() external view returns (bool) {
        return _useForge;
    }

    function checkHandle(uint256 handle) external view {
        _db.checkHandle(handle);
    }

    function isTrivial(uint256 handle) external view returns (bool) {
        return _db.isTrivial(handle);
    }

    function isArithmeticallyValid(uint256 handle) external view returns (bool) {
        return _db.isArithmeticallyValid(handle);
    }

    function getBool(uint256 handle) external view returns (bool) {
        return _db.getBool(handle);
    }

    function getU4(uint256 handle) external view returns (uint8) {
        return _db.getU4(handle);
    }

    function getU8(uint256 handle) external view returns (uint8) {
        return _db.getU8(handle);
    }

    function getU16(uint256 handle) external view returns (uint16) {
        return _db.getU16(handle);
    }

    function getU32(uint256 handle) external view returns (uint32) {
        return _db.getU32(handle);
    }

    function getU64(uint256 handle) external view returns (uint64) {
        return _db.getU64(handle);
    }

    function getU128(uint256 handle) external view returns (uint128) {
        return _db.getU128(handle);
    }

    function getAddress(uint256 handle) external view returns (address) {
        return _db.getAddress(handle);
    }

    function getU256(uint256 handle) external view returns (uint256) {
        return _db.getU256(handle);
    }

    function getBytes64(uint256 handle) external view returns (bytes memory) {
        return _db.getBytes64(handle);
    }

    function getBytes128(uint256 handle) external view returns (bytes memory) {
        return _db.getBytes128(handle);
    }

    function getBytes256(uint256 handle) external view returns (bytes memory) {
        return _db.getBytes256(handle);
    }

    function startCheckArithmetic() public {
        require(_throwIfArithmeticError == 0, "Arithmetic error checking already setup");
        _throwIfArithmeticError = type(uint256).max;
        _arithmeticCheckingMode = ArithmeticCheckingMode.ResultOnly;
    }

    function startCheckArithmetic(uint8 mode) public {
        require(_throwIfArithmeticError == 0, "Arithmetic error checking already setup");
        _throwIfArithmeticError = type(uint256).max;
        _arithmeticCheckingMode = ArithmeticCheckingMode(mode);
    }

    function stopCheckArithmetic() public {
        _throwIfArithmeticError = 0;
    }

    function checkArithmetic() public {
        require(_throwIfArithmeticError == 0, "Arithmetic error checking already setup");
        _throwIfArithmeticError = 1;
        _arithmeticCheckingMode = ArithmeticCheckingMode.ResultOnly;
    }

    function checkArithmetic(uint8 mode) public {
        require(_throwIfArithmeticError == 0, "Arithmetic error checking already setup");
        _throwIfArithmeticError = 1;
        _arithmeticCheckingMode = ArithmeticCheckingMode(mode);
    }

    function __exit_checkArithmetic(uint256 result, MathLib.ArithmeticFlags memory flags) private {
        if (_throwIfArithmeticError > 0) {
            if (
                _arithmeticCheckingMode == ArithmeticCheckingMode.OperandsAndResult
                    || _arithmeticCheckingMode == ArithmeticCheckingMode.ResultOnly
            ) {
                DBLib.checkHandleArithmetic(result, flags);
            }
            _throwIfArithmeticError--;
        }
    }

    // ===== Numeric binary op =====

    /**
     * Note: 2 cases
     *
     * 1. TFHE.add(euint64, euint64)
     *
     *    - typeOf(lhs) == typeOf(rhs) == typeOf(resultHandle)
     *    - Common.euint4_t <= type <= Common.euint256_t
     *
     * 2. TFHE.add(euint64, 12345)
     *
     *    - typeOf(lhs) == typeOf(resultHandle)
     *    - Common.euint4_t <= type <= Common.euint256_t
     *
     */
    function _fheNumericBinaryOp(
        function(MathLib.UintValue memory,MathLib.UintValue memory,uint8,bool) internal pure returns(MathLib.UintValue memory)
            numericBinaryOpFunc,
        uint256 resultHandle,
        uint256 lhs,
        uint256 rhs,
        bool rhsIsScalar,
        bool unChecked
    ) private {
        uint8 lhsType = DBLib.typeOf(lhs);
        DBLib.checkIsNumeric(lhs, lhsType);
        DBLib.checkTypeEq(resultHandle, lhsType);

        DBLib.RecordMeta memory meta;
        MathLib.UintValue memory lClearNum;
        MathLib.UintValue memory rClearNum;

        // stack too deep workaround
        {
            bool revertIfArithmeticError =
                (_throwIfArithmeticError > 0 && (_arithmeticCheckingMode != ArithmeticCheckingMode.ResultOnly));
            if (rhsIsScalar) {
                (meta, lClearNum) = _db.binaryOpNumCtNumPt(resultHandle, lhs, revertIfArithmeticError);
                rClearNum.value = rhs;
            } else {
                (meta, lClearNum, rClearNum) = _db.binaryOpNumCtNumCt(resultHandle, lhs, rhs, revertIfArithmeticError);
            }
        }

        MathLib.UintValue memory result = numericBinaryOpFunc(lClearNum, rClearNum, meta.valueType - 1, unChecked);

        DBLib.Record memory r;
        r.meta = meta;
        r.meta.arithmeticFlags = result.flags;
        r.value = bytes.concat(bytes32(result.value));

        _db.insertUnsafe(resultHandle, r);

        // Must be the very last function call
        __exit_checkArithmetic(resultHandle, meta.arithmeticFlags);
    }

    function fheAdd(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.add, result, lhs, rhs, (scalarByte != 0), false);
    }

    function fheSub(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.sub, result, lhs, rhs, (scalarByte != 0), false);
    }

    function fheMul(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.mul, result, lhs, rhs, (scalarByte != 0), false);
    }

    function fheDiv(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.div, result, lhs, rhs, (scalarByte != 0), false);
    }

    function fheRem(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.rem, result, lhs, rhs, (scalarByte != 0), false);
    }

    function fheMin(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.min, result, lhs, rhs, (scalarByte != 0), false);
    }

    function fheMax(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.max, result, lhs, rhs, (scalarByte != 0), false);
    }

    // ===== ITFHEExecutorExtPlugin =====

    function fheAddUnchecked(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.add, result, lhs, rhs, (scalarByte != 0), true);
    }

    function fheSubUnchecked(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.sub, result, lhs, rhs, (scalarByte != 0), true);
    }

    function fheMulUnchecked(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.mul, result, lhs, rhs, (scalarByte != 0), true);
    }

    function fheDivUnchecked(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericBinaryOp(MathLib.div, result, lhs, rhs, (scalarByte != 0), true);
    }

    // ===== Numeric unary op =====

    /**
     * Note: 1 case
     *
     * 1. euint64 TFHE.neg(euint64)
     *
     *    - typeOf(lhs) == typeOf(resultHandle)
     *    - Common.euint4_t <= type <= Common.euint256_t
     *
     */
    function _fheNumericUnaryOp(
        function(MathLib.UintValue memory,uint8) internal pure returns(MathLib.UintValue memory) numericUnaryOpFunc,
        uint256 resultHandle,
        uint256 ct,
        bool resultTypeEqCtType
    ) private {
        uint8 ctType = DBLib.typeOf(ct);
        DBLib.checkIsNumeric(ct, ctType);

        if (resultTypeEqCtType) {
            DBLib.checkTypeEq(resultHandle, ctType);
        }

        DBLib.RecordMeta memory meta;
        MathLib.UintValue memory clearNum;
        bool revertIfArithmeticError =
            (_throwIfArithmeticError > 0 && (_arithmeticCheckingMode != ArithmeticCheckingMode.ResultOnly));

        (meta, clearNum) = _db.unaryOpNumCt(resultHandle, ct, revertIfArithmeticError);

        MathLib.UintValue memory result = numericUnaryOpFunc(clearNum, meta.valueType - 1);

        DBLib.Record memory r;
        r.meta = meta;
        r.meta.arithmeticFlags = result.flags;
        r.value = bytes.concat(bytes32(result.value));

        _db.insertUnsafe(resultHandle, r);

        // Must be the very last function call
        __exit_checkArithmetic(resultHandle, meta.arithmeticFlags);
    }

    function fheNeg(uint256 result, uint256 ct) external {
        // typeOf(result) == typeOf(ct)
        _fheNumericUnaryOp(MathLib.neg, result, ct, true /* resultTypeEqCtType */ );
    }

    function cast(uint256 result, uint256 ct, bytes1 toType) external {
        DBLib.checkTypeEq(result, uint8(toType));

        if (result == ct) {
            _db.checkHandleExist(ct, uint8(toType));

            return;
        }

        if (uint8(toType) == Common.ebool_t) {
            revert("Cast to bool not supported");
        }

        DBLib.checkTypeNe(result, DBLib.typeOf(ct));

        // typeOf(result) != typeOf(ct)
        _fheNumericUnaryOp(MathLib.cast, result, ct, false /* resultTypeEqCtType */ );
    }

    // ===== Bit binary op =====

    /**
     * Note: 2 cases
     *
     * 1. euint64 = TFHE.xor(euint64, euint64)
     *
     *    - typeOf(lhs) == typeOf(rhs) == typeOf(resultHandle)
     *    - Common.ebool_t <= typeOf(lhs, rhs, resultHandle) <= Common.euint256_t
     *
     * 2. euint64 = TFHE.xor(euint64, 12345)
     *
     *    - typeOf(lhs) == typeOf(resultHandle)
     *    - Common.ebool_t <= typeOf(lhs, resultHandle) <= Common.euint256_t
     *
     */
    function _fheBitBinaryOp(
        function(MathLib.UintValue memory,MathLib.UintValue memory,uint8) internal pure returns(MathLib.UintValue memory)
            bitBinaryOpFunc,
        uint256 resultHandle,
        uint256 lhs,
        uint256 rhs,
        bool rhsIsScalar
    ) private {
        uint8 lhsType = DBLib.typeOf(lhs);
        DBLib.checkIs256Bits(lhs, lhsType);
        DBLib.checkTypeEq(resultHandle, lhsType);

        DBLib.RecordMeta memory meta;
        MathLib.UintValue memory lClearNum;
        MathLib.UintValue memory rClearNum;
        bool revertIfArithmeticError =
            (_throwIfArithmeticError > 0 && (_arithmeticCheckingMode != ArithmeticCheckingMode.ResultOnly));

        if (rhsIsScalar) {
            (meta, lClearNum) = _db.binaryOpNumCtNumPt(resultHandle, lhs, revertIfArithmeticError);
            rClearNum.value = rhs;
        } else {
            (meta, lClearNum, rClearNum) = _db.binaryOpNumCtNumCt(resultHandle, lhs, rhs, revertIfArithmeticError);
        }

        MathLib.UintValue memory result = bitBinaryOpFunc(lClearNum, rClearNum, meta.valueType - 1);

        DBLib.Record memory r;
        r.meta = meta;
        r.meta.arithmeticFlags = result.flags;
        r.value = bytes.concat(bytes32(result.value));

        _db.insertUnsafe(resultHandle, r);

        // Must be the very last function call
        __exit_checkArithmetic(resultHandle, meta.arithmeticFlags);
    }

    function fheBitAnd(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheBitBinaryOp(MathLib.and, result, lhs, rhs, (scalarByte != 0));
    }

    function fheBitOr(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheBitBinaryOp(MathLib.or, result, lhs, rhs, (scalarByte != 0));
    }

    function fheBitXor(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheBitBinaryOp(MathLib.xor, result, lhs, rhs, (scalarByte != 0));
    }

    function fheShl(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheBitBinaryOp(MathLib.shl, result, lhs, rhs, (scalarByte != 0));
    }

    function fheShr(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheBitBinaryOp(MathLib.shr, result, lhs, rhs, (scalarByte != 0));
    }

    function fheRotl(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheBitBinaryOp(MathLib.rotl, result, lhs, rhs, (scalarByte != 0));
    }

    function fheRotr(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheBitBinaryOp(MathLib.rotr, result, lhs, rhs, (scalarByte != 0));
    }

    // ===== Bit unary op =====

    /**
     * Note: 1 case
     *
     * 1. euint64 TFHE.not(euint64)
     *
     *    - typeOf(lhs)== typeOf(resultHandle)
     *    - Common.ebool_t <= type <= Common.euint256_t
     *
     */
    function _fheBitUnaryOp(
        function(MathLib.UintValue memory,uint8) internal pure returns(MathLib.UintValue memory) bitUnaryOpFunc,
        uint256 resultHandle,
        uint256 ct
    ) private {
        uint8 typeCt = DBLib.typeOf(ct);
        DBLib.checkIs256Bits(ct, typeCt);
        DBLib.checkTypeEq(resultHandle, typeCt);

        DBLib.RecordMeta memory meta;
        MathLib.UintValue memory clearNum;
        bool revertIfArithmeticError =
            (_throwIfArithmeticError > 0 && (_arithmeticCheckingMode != ArithmeticCheckingMode.ResultOnly));

        (meta, clearNum) = _db.unaryOpNumCt(resultHandle, ct, revertIfArithmeticError);

        MathLib.UintValue memory result = bitUnaryOpFunc(clearNum, meta.valueType - 1);

        DBLib.Record memory r;
        r.meta = meta;
        r.meta.arithmeticFlags = result.flags;
        r.value = bytes.concat(bytes32(result.value));

        _db.insertUnsafe(resultHandle, r);

        // Must be the very last function call
        __exit_checkArithmetic(resultHandle, meta.arithmeticFlags);
    }

    function fheNot(uint256 result, uint256 ct) external {
        _fheBitUnaryOp(MathLib.not, result, ct);
    }

    // ===== Cmp binary op =====

    /**
     * Note 2 cases
     *
     * 1. ebool = TFHE.eq(euint64, euint64)
     *
     *    - !! Boolean is also supported !!
     *    - typeOf(lhs) == typeOf(rhs)
     *    - typeOf(resultHandle) = Common.ebool_t
     *    - Common.ebool_t <= typeOf(lhs,rhs) <= Common.euint256_t
     *
     * 2. ebool = TFHE.eq(euint64, 12345)
     *
     *    - !! Boolean is also supported !!
     *    - typeOf(resultHandle) = Common.ebool_t
     *    - Common.ebool_t <= typeOf(lhs) <= Common.euint256_t
     *
     */
    function _fheCmpBinaryOp_NumCt_NumCtOrPt(
        function(MathLib.UintValue memory,MathLib.UintValue memory,uint8) internal pure returns(MathLib.BoolValue memory)
            numericCmpBinaryOpFunc,
        uint256 resultHandle,
        uint256 lhs,
        uint256 rhs,
        bool rhsIsScalar
    ) private {
        DBLib.RecordMeta memory meta;
        MathLib.UintValue memory lClearNum;
        MathLib.UintValue memory rClearNum;
        bool revertIfArithmeticError =
            (_throwIfArithmeticError > 0 && (_arithmeticCheckingMode != ArithmeticCheckingMode.ResultOnly));

        if (rhsIsScalar) {
            (meta, lClearNum) = _db.binaryOpNumCtNumPt(resultHandle, lhs, revertIfArithmeticError);
            rClearNum.value = rhs;
        } else {
            (meta, lClearNum, rClearNum) = _db.binaryOpNumCtNumCt(resultHandle, lhs, rhs, revertIfArithmeticError);
        }

        // MathLib.eq, ne, ge, gt, le, lt
        MathLib.BoolValue memory cmp = numericCmpBinaryOpFunc(lClearNum, rClearNum, DBLib.typeOf(lhs));

        DBLib.Record memory r;
        r.meta = meta;
        r.meta.arithmeticFlags = cmp.flags;
        r.value = (cmp.value) ? bytes.concat(bytes32(uint256(1))) : bytes.concat(bytes32(uint256(0)));

        _db.insertUnsafe(resultHandle, r);

        // Must be the very last function call
        __exit_checkArithmetic(resultHandle, meta.arithmeticFlags);
    }

    /**
     * Note: 1 case
     *
     *    ebool = TFHE.eq(ebytes128, ebytes128)
     *
     *    - typeOf(lhs) == typeOf(rhs)
     *    - typeOf(resultHandle) = Common.ebool_t
     *    - Common.ebytes64_t <= typeOf(lhs,rhs) <= Common.ebytes256_t
     *
     */
    function _fheCmpBinaryOp_BytesCt_BytesCt(
        function(MathLib.BytesValue memory,MathLib.BytesValue memory,uint8) internal pure returns(MathLib.BoolValue memory)
            bytesCmpBinaryOpFunc,
        uint256 resultHandle,
        uint256 lhs,
        uint256 rhs
    ) private {
        DBLib.RecordMeta memory meta;
        MathLib.BytesValue memory lClearBytes;
        MathLib.BytesValue memory rClearBytes;
        bool revertIfArithmeticError =
            (_throwIfArithmeticError > 0 && (_arithmeticCheckingMode != ArithmeticCheckingMode.ResultOnly));

        (meta, lClearBytes, rClearBytes) = _db.binaryOpBytesCtBytesCt(resultHandle, lhs, rhs, revertIfArithmeticError);

        // MathLib.eq, ne
        (MathLib.BoolValue memory cmp) = bytesCmpBinaryOpFunc(lClearBytes, rClearBytes, DBLib.typeOf(lhs));

        DBLib.Record memory r;
        r.meta = meta;
        r.meta.arithmeticFlags = cmp.flags;
        r.value = (cmp.value) ? bytes.concat(bytes32(uint256(1))) : bytes.concat(bytes32(uint256(0)));

        _db.insertUnsafe(resultHandle, r);

        // Must be the very last function call
        __exit_checkArithmetic(resultHandle, meta.arithmeticFlags);
    }

    /**
     * Note: 1 case
     *
     *    ebool = TFHE.eq(ebytes128, bytes.concat(...))
     *
     *    - typeOf(resultHandle) = Common.ebool_t
     *    - Common.ebytes64_t <= typeOf(lhs) <= Common.ebytes256_t
     *
     */
    function _fheCmpBinaryOp_BytesCt_BytesPt(
        function(MathLib.BytesValue memory,MathLib.BytesValue memory,uint8) internal pure returns(MathLib.BoolValue memory)
            bytesCmpBinaryOpFunc,
        uint256 resultHandle,
        uint256 lhs,
        bytes memory clearRhs
    ) private {
        bool revertIfArithmeticError =
            (_throwIfArithmeticError > 0 && (_arithmeticCheckingMode != ArithmeticCheckingMode.ResultOnly));

        (DBLib.RecordMeta memory meta, MathLib.BytesValue memory lClearBytes) =
            _db.binaryOpBytesCtBytesPt(resultHandle, lhs, revertIfArithmeticError);

        MathLib.BytesValue memory rClearBytes;
        rClearBytes.value = clearRhs;

        // MathLib.eq, ne
        (MathLib.BoolValue memory cmp) = bytesCmpBinaryOpFunc(lClearBytes, rClearBytes, DBLib.typeOf(lhs));

        DBLib.Record memory r;
        r.meta = meta;
        r.meta.arithmeticFlags = cmp.flags;
        r.value = (cmp.value) ? bytes.concat(bytes32(uint256(1))) : bytes.concat(bytes32(uint256(0)));

        _db.insertUnsafe(resultHandle, r);

        // Must be the very last function call
        __exit_checkArithmetic(resultHandle, meta.arithmeticFlags);
    }

    /**
     * Note: 3 cases
     *
     * 1. ebool = TFHE.eq(euint64, euint64)
     *
     *    - !! Boolean is also supported !!
     *    - typeOf(lhs) == typeOf(rhs)
     *    - typeOf(resultHandle) = Common.ebool_t
     *    - Common.ebool_t <= typeOf(lhs,rhs) <= Common.euint256_t
     *    - rhsIsScalar = false
     *
     * 2. ebool = TFHE.eq(euint64, 12345)
     *
     *    - !! Boolean is also supported !!
     *    - typeOf(resultHandle) = Common.ebool_t
     *    - Common.ebool_t <= typeOf(lhs) <= Common.euint256_t
     *    - rhsIsScalar = true
     *
     * 3. ebool = TFHE.eq(ebytes128, ebytes128)
     *
     *    - typeOf(resultHandle) = Common.ebool_t
     *    - Common.ebytes64_t <= typeOf(lhs) <= Common.ebytes256_t
     *    - rhsIsScalar = false
     *
     */
    function _fheCmpBinaryOp(
        function(MathLib.UintValue memory,MathLib.UintValue memory,uint8) internal pure returns(MathLib.BoolValue memory)
            numericCmpBinaryOpFunc,
        function(MathLib.BytesValue memory,MathLib.BytesValue memory,uint8) internal pure returns(MathLib.BoolValue memory)
            bytesCmpBinaryOpFunc,
        uint256 resultHandle,
        uint256 lhs,
        uint256 rhs,
        bool rhsIsScalar
    ) private {
        DBLib.checkTypeEq(resultHandle, Common.ebool_t);

        uint8 lhsType = DBLib.typeOf(lhs);
        if (lhsType >= Common.ebytes64_t) {
            require(!rhsIsScalar);
            _fheCmpBinaryOp_BytesCt_BytesCt(bytesCmpBinaryOpFunc, resultHandle, lhs, rhs);
        } else {
            _fheCmpBinaryOp_NumCt_NumCtOrPt(numericCmpBinaryOpFunc, resultHandle, lhs, rhs, rhsIsScalar);
        }
    }

    /**
     * Note: 2 cases
     *
     * 1. ebool = TFHE.eq(euint64, euint64)
     *
     *    - !! Boolean is also supported !!
     *    - typeOf(lhs) == typeOf(rhs)
     *    - typeOf(resultHandle) = Common.ebool_t
     *    - Common.ebool_t <= typeOf(lhs,rhs) <= Common.euint256_t
     *    - rhsIsScalar = false
     *
     * 2. ebool = TFHE.eq(euint64, 12345)
     *
     *    - !! Boolean is also supported !!
     *    - typeOf(resultHandle) = Common.ebool_t
     *    - Common.ebool_t <= typeOf(lhs) <= Common.euint256_t
     *    - rhsIsScalar = true
     *
     */
    function _fheNumericCmpBinaryOp(
        function(MathLib.UintValue memory,MathLib.UintValue memory,uint8) internal pure returns(MathLib.BoolValue memory)
            numericCmpBinaryOpFunc,
        uint256 resultHandle,
        uint256 lhs,
        uint256 rhs,
        bool rhsIsScalar
    ) private {
        DBLib.checkTypeEq(resultHandle, Common.ebool_t);

        uint8 lhsType = DBLib.typeOf(lhs);
        if (lhsType >= Common.ebytes64_t) {
            revert("Operation not yet supported");
        } else {
            _fheCmpBinaryOp_NumCt_NumCtOrPt(numericCmpBinaryOpFunc, resultHandle, lhs, rhs, rhsIsScalar);
        }
    }

    /**
     * Note: 1 case
     *
     *    ebool = TFHE.eq(ebytes128, bytes.concat(...))
     *
     *    - typeOf(resultHandle) = Common.ebool_t
     *    - Common.ebytes64_t <= typeOf(lhs) <= Common.ebytes256_t
     *    - rhsIsScalar == true
     *
     */
    function _fheBytesCmpBinaryOp(
        function(MathLib.BytesValue memory,MathLib.BytesValue memory,uint8) internal pure returns(MathLib.BoolValue memory)
            bytesCmpBinaryOpFunc,
        uint256 resultHandle,
        uint256 lhs,
        bytes memory rhs,
        bool rhsIsScalar
    ) private {
        // scalar is always true
        require(rhsIsScalar, "Operation only supported in scalar mode");
        DBLib.checkTypeEq(resultHandle, Common.ebool_t);

        uint8 lhsType = DBLib.typeOf(lhs);
        if (lhsType >= Common.ebytes64_t) {
            // TFHE.eq(ebytes128, bytes.concact(bytes2(0x1234)))
            _fheCmpBinaryOp_BytesCt_BytesPt(bytesCmpBinaryOpFunc, resultHandle, lhs, rhs);
        } else {
            // TFHE.eq(euint64, bytes.concact(bytes2(0x1234)))
            revert("Operation not yet supported");
        }
    }

    function fheEq(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheCmpBinaryOp(MathLib.eq, MathLib.eqBytes, result, lhs, rhs, (scalarByte != 0x0));
    }

    function fheEq(uint256 result, uint256 lhs, bytes memory rhs, bytes1 scalarByte) external {
        _fheBytesCmpBinaryOp(MathLib.eqBytes, result, lhs, rhs, (scalarByte != 0x0));
    }

    function fheNe(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheCmpBinaryOp(MathLib.ne, MathLib.neBytes, result, lhs, rhs, (scalarByte != 0x0));
    }

    function fheNe(uint256 result, uint256 lhs, bytes memory rhs, bytes1 scalarByte) external {
        _fheBytesCmpBinaryOp(MathLib.neBytes, result, lhs, rhs, (scalarByte != 0x0));
    }

    function fheGe(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericCmpBinaryOp(MathLib.ge, result, lhs, rhs, (scalarByte != 0x0));
    }

    function fheGt(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericCmpBinaryOp(MathLib.gt, result, lhs, rhs, (scalarByte != 0x0));
    }

    function fheLe(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericCmpBinaryOp(MathLib.le, result, lhs, rhs, (scalarByte != 0x0));
    }

    function fheLt(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheNumericCmpBinaryOp(MathLib.lt, result, lhs, rhs, (scalarByte != 0x0));
    }

    function verifyCiphertext(
        uint256 result,
        bytes32 inputHandle,
        address callerAddress,
        bytes memory, /*inputProof*/
        bytes1 inputType
    ) external view {
        if (result == 0) {
            // Previous verify failed
            // Print out the debug infos.
            // console.log("");
            // console.log("========================= VERIFY FAILED ===========================");
            // console.log("Verify ciphertext failed using the following values:");
            // console.log("  - contractAddress = %s", msg.sender);
            // console.log("  - userAddress     = %s", callerAddress);
            // console.log("  - inputHandle     = %s", uint256(inputHandle));
            // console.log("Note: you should check 'userAddress' and 'contractAddress'");
            // console.log("===================================================================");
            // console.log("");
            revert DBLib.VerifyCipherTextFailed(uint256(inputHandle), msg.sender, callerAddress);
        } else {
            _db.checkHandleExist(result, uint8(inputType));
        }
    }

    function trivialEncrypt(uint256 result, uint256 pt, bytes1 toType) external {
        _db.checkAndInsert256Bits(result, pt, uint8(toType), true /* trivial */ );
    }

    function trivialEncrypt(uint256 result, bytes memory pt, bytes1 toType) external {
        _db.checkAndInsertBytes(result, pt, uint8(toType), true /* trivial */ );
    }

    function fheIfThenElse(uint256 result, uint256 control, uint256 ifTrue, uint256 ifFalse) external {
        DBLib.RecordMeta memory meta =
            _db.ifCtThenCtElseCt(result, control, ifTrue, ifFalse, (_throwIfArithmeticError > 0));

        // Must be the very last function call
        __exit_checkArithmetic(result, meta.arithmeticFlags);
    }

    function fheRand(uint256 result, bytes1 randType) external {
        uint8 typeCt = uint8(randType);

        DBLib.checkTypeEq(result, typeCt);
        DBLib.checkIs256Bits(result, typeCt);

        MathLib.UintValue memory clearRnd;
        clearRnd.value = __randomUint();

        MathLib.UintValue memory random = MathLib.cast(clearRnd, typeCt);

        _db.checkAndInsert256Bits(result, random.value, typeCt, false /* trivial */ );
    }

    function fheRandBounded(uint256 result, uint256 upperBound, bytes1 randType) external {
        uint8 typeCt = uint8(randType);

        DBLib.checkTypeEq(result, typeCt);
        DBLib.checkIs256Bits(result, typeCt);

        MathLib.UintValue memory clearRnd;
        clearRnd.value = __randomUint();

        MathLib.UintValue memory random = MathLib.cast(clearRnd, typeCt);

        if (random.value > upperBound) {
            random.value = upperBound;
        }

        _db.checkAndInsert256Bits(result, random.value, typeCt, false /* trivial */ );
    }

    function insertEncrypted256Bits(uint256 handle, uint256 valuePt, uint8 typePt) external {
        _db.checkAndInsert256Bits(handle, valuePt, typePt, false /* trivial */ );
    }

    function insertEncryptedBytes(uint256 handle, bytes memory valuePt, uint8 typePt) external {
        _db.checkAndInsertBytes(handle, valuePt, typePt, false /* trivial */ );
    }
}
