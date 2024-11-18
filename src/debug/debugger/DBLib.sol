// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {Common} from "../fhevm/lib/TFHE.sol";
import {MathLib} from "./MathLib.sol";

library DBLib {
    struct Set {
        uint256 count;
        mapping(uint256 handle => Record) records;
    }

    struct Record {
        bytes value;
        RecordMeta meta;
    }

    struct RecordMeta {
        // equals to Common.<type> + 1
        uint8 valueType;
        MathLib.ArithmeticFlags arithmeticFlags;
        bool trivial;
    }

    error Not64BytesHandle(uint256 handle);
    error Not128BytesHandle(uint256 handle);
    error Not256BytesHandle(uint256 handle);
    error Not256BitsValue(uint256 handle);
    error Not256BitsHandle(uint256 handle, uint8 typeCt);
    error NotNumericValue(uint256 handle);
    error WrongHandleType(uint256 handle, uint8 typeCt);
    error NotBytesValue(uint256 handle);
    error NullHandle();
    error HandleDoesNotExist(uint256 handle);
    error HandleAlreadyExists(uint256 handle);
    error ArithmeticOverflow(uint256 handle);
    error ArithmeticUnderflow(uint256 handle);
    error ArithmeticDivisionByZero(uint256 handle);
    error ClearNumericOverflow(uint256 clearValue, uint8 typePt);
    error ClearBytesOverflow(uint8 typePt);
    error InternalError();
    error VerifyCipherTextFailed(uint256 handle, address contractAddress, address userAddress);

    function __checkNullHandle(uint256 handle) private pure {
        if (handle == 0) {
            revert NullHandle();
        }
    }

    function __bytesToBytes32(bytes memory buffer, uint16 offset) private pure returns (bytes32 value) {
        require(offset + 32 <= buffer.length, "out of bounds");
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    }

    function __checkValueTypeEq(uint256 handle, uint8 valueType, uint8 typeCt) private pure {
        if (valueType == 0) {
            revert HandleDoesNotExist(handle);
        }
        if (valueType != typeCt + 1) {
            revert InternalError();
        }
        if (typeOf(handle) != typeCt) {
            revert WrongHandleType(handle, typeCt);
        }
    }

    function typeOf(uint256 handle) internal pure returns (uint8) {
        uint8 typeCt = uint8(handle >> 8);
        return typeCt;
    }

    function checkIs256Bits(uint256 handle, uint8 typeCt) internal pure {
        if (!(typeCt >= Common.ebool_t && typeCt <= Common.euint256_t)) {
            revert Not256BitsHandle(handle, typeCt);
        }
    }

    function checkIsBytes(uint256 handle, uint8 typeCt) internal pure {
        if (!(typeCt >= Common.ebytes64_t && typeCt <= Common.ebytes256_t)) {
            revert NotBytesValue(handle);
        }
    }

    function checkIsNumeric(uint256 handle, uint8 typeCt) internal pure {
        if (!(typeCt >= Common.euint4_t && typeCt <= Common.euint256_t)) {
            revert NotNumericValue(handle);
        }
    }

    function checkTypeEq(uint256 handle, uint8 typeCt) internal pure {
        if (typeOf(handle) != typeCt) {
            revert WrongHandleType(handle, typeCt);
        }
    }

    function checkTypeNe(uint256 handle, uint8 typeCt) internal pure {
        if (typeOf(handle) == typeCt) {
            revert WrongHandleType(handle, typeCt);
        }
    }

    function checkHandle(Set storage self, uint256 handle) internal view {
        __checkNullHandle(handle);

        uint8 typeCt = typeOf(handle);

        Record memory r = self.records[handle];

        if (r.meta.valueType == 0) {
            revert HandleDoesNotExist(handle);
        }
        if (r.meta.valueType != typeCt + 1) {
            revert InternalError();
        }

        checkHandleArithmetic(handle, r.meta.arithmeticFlags);
    }

    function checkHandleExist(Set storage self, uint256 handle, uint8 typeCt) internal view {
        Record memory r = self.records[handle];
        if (r.meta.valueType == 0) {
            revert HandleDoesNotExist(handle);
        }
        if (r.meta.valueType != typeCt + 1) {
            revert InternalError();
        }
    }

    function checkHandleArithmetic(uint256 handle, MathLib.ArithmeticFlags memory flags) internal pure {
        if (flags.overflow) {
            revert ArithmeticOverflow(handle);
        }
        if (flags.underflow) {
            revert ArithmeticUnderflow(handle);
        }
        if (flags.divisionByZero) {
            revert ArithmeticDivisionByZero(handle);
        }
    }

    function checkClearNumericOverflow(uint256 clearNum, uint8 typePt) internal pure {
        if (clearNum > MathLib.maxUint(typePt)) {
            revert ClearNumericOverflow(clearNum, typePt);
        }
    }

    function checkClearBytesOverflow(bytes memory clearBytes, uint8 typePt) internal pure {
        if (typePt == Common.ebytes64_t) {
            if (clearBytes.length >= 64) {
                revert ClearBytesOverflow(typePt);
            }
        } else if (typePt == Common.ebytes128_t) {
            if (clearBytes.length >= 128) {
                revert ClearBytesOverflow(typePt);
            }
        } else if (typePt == Common.ebytes256_t) {
            if (clearBytes.length >= 256) {
                revert ClearBytesOverflow(typePt);
            }
        }
    }

    function checkAndInsert256Bits(Set storage self, uint256 handle, uint256 valuePt, uint8 typePt, bool trivial)
        internal
    {
        checkTypeEq(handle, typePt);
        checkIs256Bits(handle, typePt);
        checkClearNumericOverflow(valuePt, typePt);

        bytes memory value = bytes.concat(bytes32(valuePt));

        Record memory existingRecord = self.records[handle];
        if (existingRecord.meta.valueType != 0) {
            if (keccak256(existingRecord.value) != keccak256(value)) {
                revert InternalError();
            }
            if (existingRecord.meta.valueType != typePt + 1) {
                revert InternalError();
            }
            if (existingRecord.meta.trivial != trivial) {
                revert InternalError();
            }
        }

        Record memory r;
        r.meta.valueType = typePt + 1;
        r.meta.trivial = trivial;
        r.value = value;
        self.records[handle] = r;
    }

    function checkAndInsertBytes(Set storage self, uint256 handle, bytes memory valuePt, uint8 typePt, bool trivial)
        internal
    {
        checkTypeEq(handle, typePt);
        checkIsBytes(handle, typePt);
        checkClearBytesOverflow(valuePt, typePt);

        Record memory existingRecord = self.records[handle];
        if (existingRecord.meta.valueType != 0) {
            if (keccak256(existingRecord.value) != keccak256(valuePt)) {
                revert InternalError();
            }
            if (existingRecord.meta.valueType != typePt + 1) {
                revert InternalError();
            }
            if (existingRecord.meta.trivial != trivial) {
                revert InternalError();
            }
        }

        Record memory r;
        r.meta.valueType = typePt + 1;
        r.meta.trivial = trivial;
        r.value = valuePt;
        self.records[handle] = r;
    }

    function insertUnsafe(Set storage self, uint256 handle, Record memory record) internal {
        self.records[handle] = record;
    }

    function exist(Set storage self, uint256 handle) internal view returns (bool) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        return (r.meta.valueType != 0);
    }

    function isTrivial(Set storage self, uint256 handle) internal view returns (bool) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        if (r.meta.valueType == 0) {
            revert HandleDoesNotExist(handle);
        }
        return r.meta.trivial;
    }

    function isArithmeticallyValid(Set storage self, uint256 handle) internal view returns (bool) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        if (r.meta.valueType == 0) {
            revert HandleDoesNotExist(handle);
        }
        MathLib.ArithmeticFlags memory flags = r.meta.arithmeticFlags;
        return !flags.divisionByZero && !flags.overflow && !flags.underflow;
    }

    function getBool(Set storage self, uint256 handle) internal view returns (bool) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.ebool_t);
        return uint8(uint256(__bytesToBytes32(r.value, 0))) != 0;
    }

    function getU4(Set storage self, uint256 handle) internal view returns (uint8) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.euint4_t);
        return uint8(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getU8(Set storage self, uint256 handle) internal view returns (uint8) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.euint8_t);
        return uint8(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getU16(Set storage self, uint256 handle) internal view returns (uint16) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.euint16_t);
        return uint16(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getU32(Set storage self, uint256 handle) internal view returns (uint32) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.euint32_t);
        return uint32(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getU64(Set storage self, uint256 handle) internal view returns (uint64) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.euint64_t);
        return uint64(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getU128(Set storage self, uint256 handle) internal view returns (uint128) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.euint128_t);
        return uint128(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getAddress(Set storage self, uint256 handle) internal view returns (address) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.euint160_t);
        return address(uint160(uint256(__bytesToBytes32(r.value, 0))));
    }

    function getU256(Set storage self, uint256 handle) internal view returns (uint256) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.euint256_t);
        return uint256(__bytesToBytes32(r.value, 0));
    }

    function getBytes64(Set storage self, uint256 handle) internal view returns (bytes memory) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.ebytes64_t);
        if (r.value.length >= 64) {
            revert Not64BytesHandle(handle);
        }
        return r.value;
    }

    function getBytes128(Set storage self, uint256 handle) internal view returns (bytes memory) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.ebytes128_t);
        if (r.value.length >= 128) {
            revert Not128BytesHandle(handle);
        }
        return r.value;
    }

    function getBytes256(Set storage self, uint256 handle) internal view returns (bytes memory) {
        __checkNullHandle(handle);
        Record memory r = self.records[handle];
        __checkValueTypeEq(handle, r.meta.valueType, Common.ebytes256_t);
        if (r.value.length >= 256) {
            revert Not256BytesHandle(handle);
        }
        return r.value;
    }

    /**
     * Note: Requirements
     *
     *    - !! Boolean is also supported !!
     *    - typeOf(lct) == typeOf(rct)
     *    - Common.ebool_t <= typeOf(lct) <= Common.euint256_t
     *
     * Examples:
     *    TFHE.add(euint64, euint64)
     *    TFHE.eq(euint64, euint64)
     *    TFHE.eq(ebool, ebool)
     *    TFHE.and(ebool, ebool)
     *    etc.
     */
    function binaryOpNumCtNumCt(
        Set storage self,
        uint256 resultHandle,
        uint256 lct,
        uint256 rct,
        bool revertIfArithmeticError
    )
        internal
        view
        returns (RecordMeta memory meta, MathLib.UintValue memory lClear, MathLib.UintValue memory rClear)
    {
        uint8 typeCt = typeOf(lct);

        checkIs256Bits(lct, typeCt);
        checkTypeEq(rct, typeCt);

        Record memory l_record = self.records[lct];
        RecordMeta memory l = l_record.meta;
        if (l.valueType == 0) {
            revert HandleDoesNotExist(lct);
        }

        Record memory r_record = self.records[rct];
        RecordMeta memory r = r_record.meta;
        if (r.valueType == 0) {
            revert HandleDoesNotExist(rct);
        }

        if (revertIfArithmeticError) {
            checkHandleArithmetic(lct, l.arithmeticFlags);
            checkHandleArithmetic(rct, r.arithmeticFlags);
        }

        meta.valueType = typeOf(resultHandle) + 1;
        meta.trivial = l.trivial && r.trivial;

        lClear.value = uint256(__bytesToBytes32(l_record.value, 0));
        rClear.value = uint256(__bytesToBytes32(r_record.value, 0));

        lClear.flags = l_record.meta.arithmeticFlags;
        rClear.flags = r_record.meta.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - !! Boolean is also supported !!
     *    - Common.ebool_t <= typeOf(lct) <= Common.euint256_t
     *
     * Examples:
     *    TFHE.add(euint64, 1234)
     *    TFHE.eq(euint64, 1234)
     *    TFHE.eq(ebool, true)
     *    TFHE.and(ebool, true)
     *    etc.
     */
    function binaryOpNumCtNumPt(Set storage self, uint256 resultHandle, uint256 lct, bool revertIfArithmeticError)
        internal
        view
        returns (RecordMeta memory meta, MathLib.UintValue memory lClear)
    {
        uint8 typeCt = typeOf(lct);

        checkIs256Bits(lct, typeCt);

        Record memory l_record = self.records[lct];
        RecordMeta memory l = l_record.meta;
        if (l.valueType == 0) {
            revert HandleDoesNotExist(lct);
        }

        if (revertIfArithmeticError) {
            checkHandleArithmetic(lct, l.arithmeticFlags);
        }

        meta.valueType = typeOf(resultHandle) + 1;
        meta.trivial = l.trivial;

        lClear.value = uint256(__bytesToBytes32(l_record.value, 0));
        lClear.flags = l.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - typeOf(lct) == typeOf(rct)
     *    - Common.ebytes64_t <= typeOf(lct, rct) <= Common.ebytes256_t
     *
     * Examples:
     *    TFHE.eq(ebytes64, ebytes64)
     *    TFHE.and(ebytes64, ebytes64)
     *    etc.
     */
    function binaryOpBytesCtBytesCt(
        Set storage self,
        uint256 resultHandle,
        uint256 lct,
        uint256 rct,
        bool revertIfArithmeticError
    )
        internal
        view
        returns (RecordMeta memory meta, MathLib.BytesValue memory lClear, MathLib.BytesValue memory rClear)
    {
        uint8 typeCt = typeOf(lct);

        checkIsBytes(lct, typeCt);
        checkTypeEq(rct, typeCt);

        Record memory l_record = self.records[lct];
        RecordMeta memory l = l_record.meta;
        if (l.valueType == 0) {
            revert HandleDoesNotExist(lct);
        }

        Record memory r_record = self.records[rct];
        RecordMeta memory r = r_record.meta;
        if (r.valueType == 0) {
            revert HandleDoesNotExist(rct);
        }

        if (revertIfArithmeticError) {
            checkHandleArithmetic(lct, l.arithmeticFlags);
            checkHandleArithmetic(rct, r.arithmeticFlags);
        }

        meta.valueType = typeOf(resultHandle) + 1;
        meta.trivial = l.trivial && r.trivial;

        lClear.value = l_record.value;
        rClear.value = r_record.value;

        lClear.flags = l_record.meta.arithmeticFlags;
        rClear.flags = r_record.meta.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - Common.ebytes64_t <= typeOf(lct) <= Common.ebytes256_t
     *
     * Examples:
     *    TFHE.ne(ebytes64, bytes.concat(...))
     *    TFHE.and(ebytes64, bytes.concat(...))
     *    etc.
     */
    function binaryOpBytesCtBytesPt(Set storage self, uint256 resultHandle, uint256 lct, bool revertIfArithmeticError)
        internal
        view
        returns (RecordMeta memory meta, MathLib.BytesValue memory lClear)
    {
        uint8 typeCt = typeOf(lct);

        checkIsBytes(lct, typeCt);

        Record memory l_record = self.records[lct];
        RecordMeta memory l = l_record.meta;
        if (l.valueType == 0) {
            revert HandleDoesNotExist(lct);
        }

        if (revertIfArithmeticError) {
            checkHandleArithmetic(lct, l.arithmeticFlags);
        }

        meta.valueType = typeOf(resultHandle) + 1;
        meta.trivial = l.trivial;

        lClear.value = l_record.value;
        lClear.flags = l.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - !! Boolean is also supported !!
     *    - Common.ebool_t <= typeOf(lct) <= Common.euint256_t
     *
     * Examples:
     *    TFHE.neg(euint64)
     *    TFHE.neg(ebool) (doesnt mean anything)
     *    etc.
     */
    function unaryOpNumCt(Set storage self, uint256 resultHandle, uint256 ct, bool revertIfArithmeticError)
        internal
        view
        returns (RecordMeta memory meta, MathLib.UintValue memory clear)
    {
        uint8 typeCt = typeOf(ct);

        checkIs256Bits(ct, typeCt);

        Record memory ct_record = self.records[ct];
        RecordMeta memory ct_meta = ct_record.meta;
        if (ct_meta.valueType == 0) {
            revert HandleDoesNotExist(ct);
        }

        if (revertIfArithmeticError) {
            checkHandleArithmetic(ct, ct_meta.arithmeticFlags);
        }

        meta.valueType = typeOf(resultHandle) + 1;
        meta.trivial = ct_meta.trivial;

        clear.value = uint256(__bytesToBytes32(ct_record.value, 0));
        clear.flags = ct_meta.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - !! Boolean is also supported !!
     *    - Common.ebool_t <= typeOf(lct) <= Common.euint256_t
     *
     * Examples:
     *    TFHE.not(euint64)
     *    TFHE.not(ebool)
     *    etc.
     */
    function unaryOpBytesCt(Set storage self, uint256 resultHandle, uint256 ct, bool revertIfArithmeticError)
        internal
        view
        returns (RecordMeta memory meta, MathLib.BytesValue memory clear)
    {
        uint8 typeCt = typeOf(ct);

        checkIs256Bits(ct, typeCt);

        Record memory ct_record = self.records[ct];
        RecordMeta memory ct_meta = ct_record.meta;
        if (ct_meta.valueType == 0) {
            revert HandleDoesNotExist(ct);
        }

        if (revertIfArithmeticError) {
            checkHandleArithmetic(ct, ct_meta.arithmeticFlags);
        }

        meta.valueType = typeOf(resultHandle) + 1;
        meta.trivial = ct_meta.trivial;

        clear.value = ct_record.value;
        clear.flags = ct_meta.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - typeOf(control) == Common.ebool_t
     *    - typeOf(ifTrue) == typeOf(ifFalse)
     *    - Common.ebool_t <= typeOf(ifTrue, ifFalse) <= Common.ebytes256_t
     *
     * Examples:
     *    TFHE.select(ebool, ebytes64, ebytes64)
     *    TFHE.select(ebool, euint8, euint8)
     *    etc.
     */
    function ifCtThenCtElseCt(
        Set storage self,
        uint256 resultHandle,
        uint256 control,
        uint256 ifTrue,
        uint256 ifFalse,
        bool revertIfArithmeticError
    ) internal returns (RecordMeta memory meta) {
        uint8 typeCt = typeOf(ifTrue);

        checkTypeEq(ifFalse, typeCt);
        checkTypeEq(control, Common.ebool_t);

        Record memory ifTrue_record = self.records[ifTrue];
        RecordMeta memory ifTrue_meta = ifTrue_record.meta;
        if (ifTrue_meta.valueType == 0) {
            revert HandleDoesNotExist(ifTrue);
        }

        Record memory ifFalse_record = self.records[ifFalse];
        RecordMeta memory ifFalse_meta = ifFalse_record.meta;
        if (ifFalse_meta.valueType == 0) {
            revert HandleDoesNotExist(ifFalse);
        }

        Record memory control_record = self.records[control];
        RecordMeta memory control_meta = control_record.meta;
        if (control_meta.valueType == 0) {
            revert HandleDoesNotExist(control);
        }

        bool clearControl = uint8(uint256(__bytesToBytes32(control_record.value, 0))) != 0;

        if (revertIfArithmeticError) {
            checkHandleArithmetic(control, control_meta.arithmeticFlags);

            //
            // TFHE: Only check the final result
            //
            if (clearControl) {
                checkHandleArithmetic(ifTrue, ifTrue_meta.arithmeticFlags);
            } else {
                checkHandleArithmetic(ifFalse, ifFalse_meta.arithmeticFlags);
            }
        }

        if (clearControl) {
            insertUnsafe(self, resultHandle, ifTrue_record);
            meta = ifTrue_record.meta;
        } else {
            insertUnsafe(self, resultHandle, ifFalse_record);
            meta = ifFalse_record.meta;
        }
    }
}
