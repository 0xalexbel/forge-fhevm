// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Common} from "fhevm/lib/TFHE.sol";
import {ITFHEExecutorPlugin} from "./ITFHEExecutorPlugin.sol";

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

contract TFHEExecutorDB is Ownable, ITFHEExecutorPlugin {
    enum ArithmeticCheckingMode {
        OperandsOnly,
        OperandsAndResult
    }

    error HandleDoesNotExist(uint256 handle);
    error ArithmeticOverflow(uint256 handle);
    error ArithmeticUnderflow(uint256 handle);
    error ArithmeticDivisionByZero(uint256 handle);

    uint256[9] private MAX_UINT = [
        1, // 2**1 - 1 (0, ebool_t)
        0xF, // 2**4 - 1 (1, euint4_t)
        0xFF, // 2**8 - 1 (2, euint8_t)
        0xFFFF, // 2**16 - 1 (3, euint16_t)
        0xFFFFFFFF, // 2**32 - 1 (4, euint32_t)
        0xFFFFFFFFFFFFFFFF, // 2**64 - 1 (5, euint64_t)
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, // 2**128 - 1 (6, euint128_t))
        0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, // 2**160 - 1 (7, euint160_t))
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF // 2**256 - 1 (8, euint256_t))
    ];

    struct Entry256 {
        // equals to Common.<type> + 1
        uint8 valueType;
        uint256 value;
        bool divisionByZero;
        bool overflow;
        bool underflow;
        bool trivial;
    }

    struct Entry2048 {
        // equals to Common.<type> + 1
        uint8 valueType;
        bytes value;
    }

    // Note: IS_FORGE_TFHE_EXECUTOR_DB() must return true.
    bool public IS_FORGE_TFHE_EXECUTOR_DB = true;

    mapping(uint256 => Entry256) public db_256;
    mapping(uint256 => Entry2048) public db_2048;

    uint256 public db256Count;
    uint256 public db2048Count;

    uint256 private _throwIfArithmeticError;
    ArithmeticCheckingMode private _arithmeticCheckingMode;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function exists256(uint256 handle) internal view returns (bool) {
        return db_256[handle].valueType > 0;
    }
    function exists2048(uint256 handle) internal view returns (bool) {
        return db_2048[handle].valueType > 0;
    }

    function get256(uint256 handle) public view returns (Entry256 memory) {
        return db_256[handle];
    }
    function get2048(uint256 handle) public view returns (Entry2048 memory) {
        return db_2048[handle];
    }
    function get256AsBytes(uint256 handle) public view returns (bytes memory clearBytes) {
        Entry256 memory e = db_256[handle];

        require(e.valueType != 0, "Handle does not exist");

        uint8 typeCt = e.valueType - 1;
        if (typeCt <= Common.euint8_t) {
            clearBytes = bytes.concat(bytes1(uint8(e.value)));
        } else if (typeCt == Common.euint16_t) {
            clearBytes = bytes.concat(bytes2(uint16(e.value)));
        } else if (typeCt == Common.euint32_t) {
            clearBytes = bytes.concat(bytes4(uint32(e.value)));
        } else if (typeCt == Common.euint64_t) {
            clearBytes = bytes.concat(bytes8(uint64(e.value)));
        } else if (typeCt == Common.euint128_t) {
            clearBytes = bytes.concat(bytes16(uint128(e.value)));
        } else if (typeCt == Common.euint256_t) {
            clearBytes = bytes.concat(bytes32(uint256(e.value)));
        } else {
            revert("Value type is not 256-bits compatible");
        }
    }

    function get2048AsBytes(uint256 handle) public view returns (bytes memory clearBytes) {
        Entry2048 memory e = db_2048[handle];

        require(e.valueType != 0, "Handle does not exist");

        clearBytes = e.value;
    }

    function startCheckArithmetic() public {
        require(_throwIfArithmeticError == 0, "Arithmetic error checking already setup");
        _throwIfArithmeticError = type(uint256).max;
        _arithmeticCheckingMode = ArithmeticCheckingMode.OperandsOnly;
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
        _arithmeticCheckingMode = ArithmeticCheckingMode.OperandsOnly;
    }

    function checkArithmetic(uint8 mode) public {
        require(_throwIfArithmeticError == 0, "Arithmetic error checking already setup");
        _throwIfArithmeticError = 1;
        _arithmeticCheckingMode = ArithmeticCheckingMode(mode);
    }

    /**
     * @dev Throws if handle is not stored in the db 256.
     */
    modifier onlyExists256(uint256 handle) {
        if (db_256[handle].valueType == 0) {
            revert HandleDoesNotExist(handle);
        }
        _;
    }

    /**
     * @dev Throws if handle is not a scalar and is not stored in the db 256.
     */
    modifier onlyExistsOrScalar256(uint256 handle, bytes1 scalarByte) {
        if (!(scalarByte == 0x01 || db_256[handle].valueType > 0)) {
            revert HandleDoesNotExist(handle);
        }
        _;
    }

    function typeOf(uint256 handle) public pure returns (uint8) {
        uint8 typeCt = uint8(handle >> 8);
        return typeCt;
    }

    function _newEntry256(uint256 lhs, uint256 rhs) internal view returns (Entry256 memory) {
        Entry256 memory l = db_256[lhs];
        Entry256 memory r = db_256[rhs];
        Entry256 memory e;
        e.overflow = l.overflow || r.overflow;
        e.underflow = l.underflow || r.underflow;
        e.divisionByZero = l.divisionByZero || r.divisionByZero;
        e.trivial = l.trivial && r.trivial;
        return e;
    }

    function _newEntry256(uint256 ct) internal view returns (Entry256 memory) {
        Entry256 memory ctEntry = db_256[ct];

        Entry256 memory e;
        e.overflow = ctEntry.overflow;
        e.underflow = ctEntry.underflow;
        e.divisionByZero = ctEntry.divisionByZero;
        e.trivial = ctEntry.trivial;

        return e;
    }

    function _newEntry2048(uint256 /*lhs*/, uint256 /*rhs*/) internal pure returns (Entry2048 memory) {
        Entry2048 memory e;
        return e;
    }

    function revertIfArithmeticError(uint256 handle) internal view {
        Entry256 memory e = db_256[handle];
        if (e.overflow) {
            revert ArithmeticOverflow(handle);
        }
        if (e.underflow) {
            revert ArithmeticUnderflow(handle);
        }
        if (e.divisionByZero) {
            revert ArithmeticDivisionByZero(handle);
        }
    }

    function verifyHandle256(uint256 handle, bytes1 scalarByte, bool operand) internal view returns (uint256 clearCt) {
        Entry256 memory entry = db_256[handle];
        if (scalarByte == 0x0) {
            if (entry.valueType == 0) {
                revert HandleDoesNotExist(handle);
            }
            if (operand || (!operand && _arithmeticCheckingMode == ArithmeticCheckingMode.OperandsAndResult)) {
                if (_throwIfArithmeticError > 0) {
                    revertIfArithmeticError(handle);
                }
            }
            clearCt = entry.value;
        } else {
            clearCt = handle;
        }
    }

    function verifyHandle2048(uint256 handle) internal view returns (bytes memory clearCt) {
        Entry2048 memory entry = db_2048[handle];
        if (entry.valueType == 0) {
            revert HandleDoesNotExist(handle);
        }
        clearCt = entry.value;
    }

    function binaryOpVerify256(
        uint256 lhs,
        uint256 rhs,
        bytes1 scalarByte
    ) internal view returns (uint256 clearLhs, uint256 clearRhs) {
        clearLhs = verifyHandle256(lhs, 0x0, true);
        clearRhs = verifyHandle256(rhs, scalarByte, true);
    }

    function ternaryOpVerify256(
        uint256 one,
        uint256 two,
        uint256 three
    ) internal view returns (uint256 clearOne, uint256 clearTwo, uint256 clearThree) {
        clearOne = verifyHandle256(one, 0x0, true);
        clearTwo = verifyHandle256(two, 0x0, true);
        clearThree = verifyHandle256(three, 0x0, true);
    }

    function binaryOpVerify2048(
        uint256 lhs,
        uint256 rhs
    ) internal view returns (bytes memory clearLhs, bytes memory clearRhs) {
        clearLhs = verifyHandle2048(lhs);
        clearRhs = verifyHandle2048(rhs);
    }

    function ternaryOpVerify2048(
        uint256 one,
        uint256 two,
        uint256 three
    ) internal view returns (uint256 clearOne, bytes memory clearTwo, bytes memory clearThree) {
        // 256 (bool type)
        clearOne = verifyHandle256(one, 0x0, true);
        // 2048
        clearTwo = verifyHandle2048(two);
        // 2048
        clearThree = verifyHandle2048(three);
    }

    function insertDB256(uint256 handle, uint256 valueCt, uint8 typeCt) external {
        require(typeCt >= Common.ebool_t && typeCt <= Common.euint256_t, "Invalid 256 type");
        require(db_256[handle].valueType == 0, "Handle already exists");

        db256Count++;

        Entry256 memory e;
        e.valueType = typeCt + 1;
        e.value = valueCt;

        db_256[handle] = e;
    }

    function insertDB2048(uint256 handle, bytes memory valueCt, uint8 typeCt) external {
        require(typeCt >= Common.ebytes64_t && typeCt <= Common.ebytes256_t, "Invalid 2048 type");
        require(db_2048[handle].valueType == 0, "Handle already exists");

        db2048Count++;

        Entry2048 memory e;
        e.valueType = typeCt + 1;
        e.value = valueCt;

        db_2048[handle] = e;
    }

    function exit_insertDB256(uint256 handle, Entry256 memory e) internal {
        // Does not already exist
        if (db_256[handle].valueType == 0) {
            db256Count++;
        }
        db_256[handle] = e;

        if (_throwIfArithmeticError > 0) {
            if (_arithmeticCheckingMode == ArithmeticCheckingMode.OperandsAndResult) {
                revertIfArithmeticError(handle);
            }
            _throwIfArithmeticError--;
        }
    }

    function exit_insertDB2048(uint256 handle, Entry2048 memory e) internal {
        // Does not already exist
        if (db_2048[handle].valueType == 0) {
            db2048Count++;
        }
        db_2048[handle] = e;

        if (_throwIfArithmeticError > 0) {
            // No artithmetic error with bytes
            _throwIfArithmeticError--;
        }
    }

    function fheAdd(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

        Entry256 memory e = _newEntry256(lhs, rhs);
        e.valueType = lhsType + 1;
        (bool succeeded, uint256 result) = Math.tryAdd(clearLhs, clearRhs);
        e.value = result % (MAX_UINT[lhsType] + 1);
        e.overflow = (succeeded ? (result > MAX_UINT[lhsType]) : true) || e.overflow;

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheSub(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

        Entry256 memory e = _newEntry256(lhs, rhs);
        e.valueType = lhsType + 1;
        e.underflow = (clearRhs > clearLhs) || e.underflow;
        unchecked {
            e.value = (clearLhs - clearRhs) % (MAX_UINT[lhsType] + 1);
        }

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheMul(uint256 resultHandle, uint256 lhs, uint256 /* rhs */, bytes1 /* scalarByte */) external pure {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        revert("fheMul not yet implemented");
    }

    function fheDiv(uint256 resultHandle, uint256 lhs, uint256 /* rhs */, bytes1 /* scalarByte */) external pure {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        revert("fheDiv not yet implemented");
    }

    function fheRem(uint256 resultHandle, uint256 lhs, uint256 /* rhs */, bytes1 /* scalarByte */) external pure {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        revert("fheRem not yet implemented");
    }

    function fheBitAnd(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.ebool_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

        Entry256 memory e = _newEntry256(lhs, rhs);
        e.valueType = lhsType + 1;
        e.value = (clearLhs & clearRhs);

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheBitOr(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.ebool_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

        Entry256 memory e = _newEntry256(lhs, rhs);
        e.valueType = lhsType + 1;
        e.value = (clearLhs | clearRhs);

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheBitXor(uint256 resultHandle, uint256 lhs, uint256 /* rhs */, bytes1 /* scalarByte */) external pure {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.ebool_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        revert("fheBitXor not yet implemented");
    }

    function fheShl(uint256 resultHandle, uint256 lhs, uint256 /* rhs */, bytes1 /* scalarByte */) external pure {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        revert("fheShl not yet implemented");
    }

    function fheShr(uint256 resultHandle, uint256 lhs, uint256 /* rhs */, bytes1 /* scalarByte */) external pure {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        revert("fheShr not yet implemented");
    }

    function fheRotl(uint256 resultHandle, uint256 lhs, uint256 /* rhs */, bytes1 /* scalarByte */) external pure {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        revert("fheRotl not yet implemented");
    }

    function fheRotr(uint256 resultHandle, uint256 lhs, uint256 /* rhs */, bytes1 /* scalarByte */) external pure {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        revert("fheRotl not yet implemented");
    }

    function fheEq(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.ebytes256_t);
        require(typeOf(resultHandle) == Common.ebool_t);

        if (lhsType <= Common.euint256_t) {
            (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

            Entry256 memory e = _newEntry256(lhs, rhs);
            e.valueType = Common.ebool_t + 1;
            e.value = (clearLhs == clearRhs) ? 1 : 0;

            // Must be the very last function call
            exit_insertDB256(resultHandle, e);
        } else {
            require(scalarByte == 0x0, "rhs scalar not supported with ebytes types");

            (bytes memory clearLhs, bytes memory clearRhs) = binaryOpVerify2048(lhs, rhs);

            bool areEqual = clearLhs.length == clearRhs.length && keccak256(clearLhs) == keccak256(clearRhs);

            Entry256 memory e = _newEntry256(lhs, rhs);
            e.valueType = Common.ebool_t + 1;
            e.value = (areEqual) ? 1 : 0;

            // Must be the very last function call
            exit_insertDB256(resultHandle, e);
        }
    }

    function fheNe(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.ebytes256_t);
        require(typeOf(resultHandle) == Common.ebool_t);

        if (lhsType <= Common.euint256_t) {
            (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

            Entry256 memory e = _newEntry256(lhs, rhs);
            e.valueType = lhsType + 1;
            e.value = (clearLhs != clearRhs) ? 1 : 0;

            // Must be the very last function call
            exit_insertDB256(resultHandle, e);
        } else {
            require(scalarByte == 0x0, "rhs scalar not supported with ebytes types");

            (bytes memory clearLhs, bytes memory clearRhs) = binaryOpVerify2048(lhs, rhs);

            bool areEqual = clearLhs.length == clearRhs.length && keccak256(clearLhs) == keccak256(clearRhs);

            Entry256 memory e = _newEntry256(lhs, rhs);
            e.valueType = Common.ebool_t + 1;
            e.value = (!areEqual) ? 1 : 0;

            // Must be the very last function call
            exit_insertDB256(resultHandle, e);
        }
    }

    function fheGe(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(typeOf(resultHandle) == Common.ebool_t);

        (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

        Entry256 memory e = _newEntry256(lhs, rhs);
        e.valueType = lhsType + 1;
        e.value = (clearLhs >= clearRhs) ? 1 : 0;

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheGt(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(typeOf(resultHandle) == Common.ebool_t);

        (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

        Entry256 memory e = _newEntry256(lhs, rhs);
        e.valueType = lhsType + 1;
        e.value = (clearLhs > clearRhs) ? 1 : 0;

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheLe(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(typeOf(resultHandle) == Common.ebool_t);

        (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

        Entry256 memory e = _newEntry256(lhs, rhs);
        e.valueType = lhsType + 1;
        e.value = (clearLhs <= clearRhs) ? 1 : 0;

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheLt(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(typeOf(resultHandle) == Common.ebool_t);

        (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

        Entry256 memory e = _newEntry256(lhs, rhs);
        e.valueType = lhsType + 1;
        e.value = (clearLhs < clearRhs) ? 1 : 0;

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheMin(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

        Entry256 memory e = _newEntry256(lhs, rhs);
        e.valueType = lhsType + 1;
        e.value = (clearLhs < clearRhs) ? clearLhs : clearRhs;

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheMax(uint256 resultHandle, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        uint8 lhsType = typeOf(lhs);

        require(lhsType >= Common.euint4_t && lhsType <= Common.euint256_t);
        require(lhsType == typeOf(resultHandle));

        (uint256 clearLhs, uint256 clearRhs) = binaryOpVerify256(lhs, rhs, scalarByte);

        Entry256 memory e = _newEntry256(lhs, rhs);
        e.valueType = lhsType + 1;
        e.value = (clearLhs > clearRhs) ? clearLhs : clearRhs;

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheNeg(uint256 resultHandle, uint256 ct) external {
        uint8 ctType = typeOf(ct);
        uint256 clearCt = verifyHandle256(ct, 0x0, true);

        require(ctType >= Common.euint4_t && ctType <= Common.euint256_t);

        Entry256 memory e = _newEntry256(ct);
        e.valueType = ctType + 1;

        uint256 not = (clearCt ^ type(uint256).max) & MAX_UINT[ctType];
        if (ctType == Common.euint256_t) {
            e.value = not + 1;
        } else {
            e.value = (not + 1) % (MAX_UINT[ctType] + 1);
        }

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheNot(uint256 resultHandle, uint256 ct) external {
        uint8 ctType = typeOf(ct);
        uint256 clearCt = verifyHandle256(ct, 0x0, true);

        require(ctType >= Common.ebool_t && ctType <= Common.euint256_t);

        Entry256 memory e = _newEntry256(ct);
        e.valueType = ctType + 1;
        e.value = (clearCt ^ type(uint256).max) & MAX_UINT[ctType];

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function verifyCiphertext(
        uint256 resultHandle,
        bytes32 /*inputHandle*/,
        address /*callerAddress*/,
        bytes memory /*inputProof*/,
        bytes1 inputType
    ) external view {
        uint8 ctType = uint8(inputType);
        if (ctType <= Common.euint256_t) {
            require(exists256(resultHandle), "verifyCiphertext: 256-bits result handle is not stored in the db");
            require(
                !exists2048(resultHandle),
                "verifyCiphertext: 256-bits result handle is already stored in as a 2048-bits handle."
            );
        } else {
            require(exists2048(resultHandle), "verifyCiphertext: 2048-bits result handle is not stored in the db");
            require(
                !exists256(resultHandle),
                "verifyCiphertext: 2048-bits result handle is already stored in as a 256-bits handle."
            );
        }
    }

    function cast(uint256 resultHandle, uint256 ct, bytes1 toType) external {
        uint8 toT = uint8(toType);

        require(toT >= Common.ebool_t && toT <= Common.euint256_t, "Unsupported type");

        uint8 ctType = typeOf(ct);
        uint256 clearCt = verifyHandle256(ct, 0x0, true);

        require(ctType >= Common.ebool_t && ctType <= Common.euint256_t);

        Entry256 memory e = _newEntry256(ct);
        e.valueType = toT + 1;
        if (toT == Common.ebool_t) {
            e.value = uint256((clearCt != 0) ? 1 : 0);
        } else if (toT == Common.euint4_t) {
            revert("cast to euint4 not yet supported");
        } else if (toT == Common.euint8_t) {
            e.value = uint256(uint8(clearCt));
        } else if (toT == Common.euint16_t) {
            e.value = uint256(uint16(clearCt));
        } else if (toT == Common.euint32_t) {
            e.value = uint256(uint32(clearCt));
        } else if (toT == Common.euint64_t) {
            e.value = uint256(uint64(clearCt));
        } else if (toT == Common.euint128_t) {
            e.value = uint256(uint128(clearCt));
        } else if (toT == Common.euint256_t) {
            e.value = clearCt;
        } else {
            revert("cast to unknown type");
        }

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function trivialEncrypt(uint256 resultHandle, uint256 plaintext, bytes1 toType) external {
        uint8 toT = uint8(toType);

        require(toT >= Common.ebool_t && toT <= Common.euint256_t, "Unsupported type");
        require(plaintext <= MAX_UINT[toT], "Value overflow");

        Entry256 memory e;
        e.valueType = toT + 1;
        e.value = plaintext;
        e.trivial = true;

        // Must be the very last function call
        exit_insertDB256(resultHandle, e);
    }

    function fheIfThenElse(uint256 resultHandle, uint256 control, uint256 ifTrue, uint256 ifFalse) external {
        // typeOf(resultHandle) == typeOf(ifTrue) == typeOf(ifFalse)
        uint8 ifTrueType = typeOf(ifTrue);

        if (ifTrueType <= Common.euint256_t) {
            (uint256 clearControl, , ) = ternaryOpVerify256(control, ifTrue, ifFalse);

            Entry256 memory e;
            Entry256 memory c = (clearControl == 0) ? db_256[ifFalse] : db_256[ifTrue];

            e.valueType = c.valueType;
            e.value = c.value;
            e.trivial = c.trivial;
            e.overflow = c.overflow;
            e.underflow = c.underflow;
            e.divisionByZero = c.divisionByZero;

            // Must be the very last function call
            exit_insertDB256(resultHandle, e);
        } else {
            (uint256 clearControl, , ) = ternaryOpVerify2048(control, ifTrue, ifFalse);

            Entry2048 memory e;
            Entry2048 memory c = (clearControl == 0) ? db_2048[ifFalse] : db_2048[ifTrue];

            e.valueType = c.valueType;
            e.value = c.value;

            // Must be the very last function call
            exit_insertDB2048(resultHandle, e);
        }
    }

    function fheRand(uint256 /* resultHandle */, bytes1 /* randType */) external pure {
        revert("fheRand not yet implemented");
    }

    function fheRandBounded(uint256 /* resultHandle */, uint256 /* upperBound */, bytes1 /* randType */) external pure {
        revert("fheRandBounded not yet implemented");
    }
}
