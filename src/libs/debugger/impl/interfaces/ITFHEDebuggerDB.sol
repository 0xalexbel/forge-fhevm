// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {MathLib} from "../lib/MathLib.sol";
import {IFhevmDebuggerDB} from "../../interfaces/IFhevmDebuggerDB.sol";

interface ITFHEDebuggerDB is IFhevmDebuggerDB {
    error HandleAlreadyExist(uint256 handle);
    error HandleDoesNotExist(uint256 handle);
    error ClearNumericOverflow(uint256 clearValue, uint8 typePt);
    error ClearBytesOverflow(uint8 typePt);
    error InternalError();

    struct Set {
        uint256 count;
        mapping(uint256 handle => Record) records;
    }

    struct Record {
        RecordMeta meta;
        bytes value;
    }

    struct RecordMeta {
        // equals to Common.<type> + 1
        uint8 valueType;
        MathLib.ArithmeticFlags arithmeticFlags;
        bool trivial;
    }

    function insertEncryptedInput(uint256 handle, uint256 valuePt, uint8 typePt) external;
    function insertEncryptedInput(uint256 handle, bytes calldata valuePt, uint8 typePt) external;

    function insertBoolUnsafe(uint256 handle, bool value, ITFHEDebuggerDB.RecordMeta calldata meta) external;
    function insertUintUnsafe(uint256 handle, uint256 value, ITFHEDebuggerDB.RecordMeta calldata meta) external;
    function checkAndInsert256Bits(uint256 handle, uint256 valuePt, uint8 typePt, bool trivial) external;
    function checkAndInsertBytes(uint256 handle, bytes calldata valuePt, uint8 typePt, bool trivial) external;
    function insertIfCtThenCtElseCt(
        uint256 resultHandle,
        uint256 control,
        uint256 ifTrue,
        uint256 ifFalse,
        bool revertIfArithmeticError
    ) external returns (RecordMeta memory meta);

    /// ===== compute DB (readonly) =====

    function binaryOpNumCtNumCt(uint256 resultHandle, uint256 lct, uint256 rct, bool revertIfArithmeticError)
        external
        view
        returns (RecordMeta memory meta, MathLib.UintValue memory lClear, MathLib.UintValue memory rClear);

    function binaryOpNumCtNumPt(uint256 resultHandle, uint256 lct, bool revertIfArithmeticError)
        external
        view
        returns (RecordMeta memory meta, MathLib.UintValue memory lClear);

    function binaryOpBytesCtBytesCt(uint256 resultHandle, uint256 lct, uint256 rct, bool revertIfArithmeticError)
        external
        view
        returns (RecordMeta memory meta, MathLib.BytesValue memory lClear, MathLib.BytesValue memory rClear);

    function binaryOpBytesCtBytesPt(uint256 resultHandle, uint256 lct, bool revertIfArithmeticError)
        external
        view
        returns (RecordMeta memory meta, MathLib.BytesValue memory lClear);

    function unaryOpNumCt(uint256 resultHandle, uint256 ct, bool revertIfArithmeticError)
        external
        view
        returns (RecordMeta memory meta, MathLib.UintValue memory clear);
}
