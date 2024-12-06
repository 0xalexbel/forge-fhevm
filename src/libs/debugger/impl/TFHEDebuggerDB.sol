// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import {TFHEHandle} from "../../common/TFHEHandle.sol";

// Public API
import {IFhevmDebuggerDB} from "../interfaces/IFhevmDebuggerDB.sol";

import {MathLib} from "./lib/MathLib.sol";
import {ITFHEDebuggerDB} from "./interfaces/ITFHEDebuggerDB.sol";

//import {console} from "forge-std/src/console.sol";

contract TFHEDebuggerDB is UUPSUpgradeable, Ownable2StepUpgradeable, ITFHEDebuggerDB {
    // ====================================================================== //
    //
    //           ⭐️ UUPSUpgradeable + Ownable2StepUpgradeable ⭐️
    //
    // ====================================================================== //

    /// @notice Name of the contract
    string private constant CONTRACT_NAME = "TFHEDebuggerDB";

    /// @notice Version of the contract
    uint256 private constant MAJOR_VERSION = 0;
    uint256 private constant MINOR_VERSION = 1;
    uint256 private constant PATCH_VERSION = 0;

    /// @custom:storage-location erc7201:fhevm.storage.TFHEDebuggerDB
    struct TFHEDebuggerDBStorage {
        address debuggerAddress;
        ITFHEDebuggerDB.Set db;
    }

    // keccak256(abi.encode(uint256(keccak256("fhevm.storage.TFHEDebuggerDB")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TFHEDebuggerDBStorageLocation =
        0x40ba33133da4f37dd72a95eb1a3e940a14bd415da18fec426e905bb2c82bcd00;

    function _getTFHEDebuggerDBStorage() internal pure returns (TFHEDebuggerDBStorage storage $) {
        assembly {
            $.slot := TFHEDebuggerDBStorageLocation
        }
    }

    function _getRecordStorage(uint256 handle) internal view returns (ITFHEDebuggerDB.Record storage) {
        TFHEDebuggerDBStorage storage $;
        assembly {
            $.slot := TFHEDebuggerDBStorageLocation
        }
        return $.db.records[handle];
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error DebuggerDBUnauthorizedAccount(address account);

    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyOwner {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract setting `initialOwner` as the initial owner
    function initialize(address initialOwner, address initialDebugger) external initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __TFHEDebuggerDB_init(initialDebugger);
    }

    /// @dev Initializes the DebuggerDB setting the address provided by the deployer as the initial debugger.
    function __TFHEDebuggerDB_init(address initialDebugger) internal onlyInitializing {
        TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        $.debuggerAddress = initialDebugger;
    }

    /// @notice Getter for the name and version of the contract
    /// @return string representing the name and the version of the contract
    function getVersion() external pure virtual returns (string memory) {
        return string(
            abi.encodePacked(
                CONTRACT_NAME,
                " v",
                Strings.toString(MAJOR_VERSION),
                ".",
                Strings.toString(MINOR_VERSION),
                ".",
                Strings.toString(PATCH_VERSION)
            )
        );
    }

    function debugger() public view returns (address) {
        TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        return $.debuggerAddress;
    }

    /**
     * @dev Throws if the sender is not the debugger.
     */
    function _checkDebugger() private view {
        if (debugger() != _msgSender()) {
            revert DebuggerDBUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Throws if called by any account other than the debugger.
     */
    modifier onlyDebugger() {
        _checkDebugger();
        _;
    }

    // ====================================================================== //
    //
    //                     ⭐️ Contract functions ⭐️
    //
    // ====================================================================== //

    function __bytesToBytes32(bytes memory buffer, uint16 offset) private pure returns (bytes32 value) {
        require(offset + 32 <= buffer.length, "out of bounds");
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    }

    function __checkValueTypeEq(uint256 handle, uint8 valueType, uint8 typeCt) private pure {
        if (valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(handle);
        }
        if (valueType != typeCt + 1) {
            revert ITFHEDebuggerDB.InternalError();
        }
        TFHEHandle.checkTypeEq(handle, typeCt);
    }

    function checkHandle(uint256 handle) external view {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record storage r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);

        uint8 typeMeta = r.meta.valueType;

        if (typeMeta == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(handle);
        }

        uint8 typeCt = TFHEHandle.typeOf(handle);

        if (typeMeta != typeCt + 1) {
            revert ITFHEDebuggerDB.InternalError();
        }

        MathLib.checkHandleArithmetic(handle, r.meta.arithmeticFlags);
    }

    function checkHandleExist(uint256 handle, uint8 typeCt) external view {
        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record storage r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);

        uint8 typeMeta = r.meta.valueType;

        if (typeMeta == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(handle);
        }

        if (typeMeta != typeCt + 1) {
            revert ITFHEDebuggerDB.InternalError();
        }
    }

    function __checkClearNumericOverflow(uint256 clearNum, uint8 typePt) private pure {
        if (clearNum > MathLib.maxUint(typePt)) {
            revert ITFHEDebuggerDB.ClearNumericOverflow(clearNum, typePt);
        }
    }

    function __checkClearBytesOverflow(bytes memory clearBytes, uint8 typePt) private pure {
        uint256 maxLen = TFHEHandle.getTypePackedBytesLen(typePt);
        if (clearBytes.length >= maxLen) {
            revert ITFHEDebuggerDB.ClearBytesOverflow(typePt);
        }
        // if (typePt == TFHEHandle.ebytes64_t) {
        //     if (clearBytes.length >= 64) {
        //         revert ITFHEDebuggerDB.ClearBytesOverflow(typePt);
        //     }
        // } else if (typePt == TFHEHandle.ebytes128_t) {
        //     if (clearBytes.length >= 128) {
        //         revert ITFHEDebuggerDB.ClearBytesOverflow(typePt);
        //     }
        // } else if (typePt == TFHEHandle.ebytes256_t) {
        //     if (clearBytes.length >= 256) {
        //         revert ITFHEDebuggerDB.ClearBytesOverflow(typePt);
        //     }
        // }
    }

    function insertEncryptedInput(uint256 handle, uint256 valuePt, uint8 typePt) external {
        __checkAndInsert256Bits(handle, valuePt, typePt, false /* trivial */ );
    }

    function insertEncryptedInput(uint256 handle, bytes calldata valuePt, uint8 typePt) external {
        __checkAndInsertBytes(handle, valuePt, typePt, false /* trivial */ );
    }

    // from trivialEncrypt or Random
    function checkAndInsert256Bits(uint256 handle, uint256 valuePt, uint8 typePt, bool trivial) external onlyDebugger {
        __checkAndInsert256Bits(handle, valuePt, typePt, trivial);
    }

    // Only called from trivialEncrypt
    function checkAndInsertBytes(uint256 handle, bytes calldata valuePt, uint8 typePt, bool trivial)
        external
        onlyDebugger
    {
        __checkAndInsertBytes(handle, valuePt, typePt, trivial);
    }

    function __checkAndInsert256Bits(uint256 handle, uint256 valuePt, uint8 typePt, bool trivial) private {
        TFHEHandle.checkIs256Bits(handle, typePt);
        __checkClearNumericOverflow(valuePt, typePt);

        bytes memory value = bytes.concat(bytes32(valuePt));

        //ITFHEDebuggerDB.Record memory existingRecord = $.db.records[handle];
        ITFHEDebuggerDB.Record storage existingRecord = _getRecordStorage(handle);
        if (existingRecord.meta.valueType != 0) {
            if (existingRecord.meta.trivial != trivial) {
                revert ITFHEDebuggerDB.InternalError();
            }
            if (existingRecord.meta.valueType != typePt + 1) {
                revert ITFHEDebuggerDB.InternalError();
            }
            if (keccak256(existingRecord.value) != keccak256(value)) {
                revert ITFHEDebuggerDB.InternalError();
            }
        }

        // No arithmetic error to forward since the call comes from trivialEncrypt or Random
        ITFHEDebuggerDB.Record memory r;
        r.meta.valueType = typePt + 1;
        r.meta.trivial = trivial;
        r.value = value;

        __insertUnsafe(handle, r);
    }

    function __checkAndInsertBytes(uint256 handle, bytes calldata valuePt, uint8 typePt, bool trivial) private {
        //TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        TFHEHandle.checkIsBytes(handle, typePt);
        __checkClearBytesOverflow(valuePt, typePt);

        //ITFHEDebuggerDB.Record memory existingRecord = $.db.records[handle];
        ITFHEDebuggerDB.Record storage existingRecord = _getRecordStorage(handle);
        if (existingRecord.meta.valueType != 0) {
            if (existingRecord.meta.trivial != trivial) {
                revert ITFHEDebuggerDB.InternalError();
            }
            if (existingRecord.meta.valueType != typePt + 1) {
                revert ITFHEDebuggerDB.InternalError();
            }
            if (keccak256(existingRecord.value) != keccak256(valuePt)) {
                revert ITFHEDebuggerDB.InternalError();
            }
        }

        // No arithmetic error to forward since the call comes from trivialEncrypt or Random
        ITFHEDebuggerDB.Record memory r;
        r.meta.valueType = typePt + 1;
        r.meta.trivial = trivial;
        r.value = valuePt;

        __insertUnsafe(handle, r);
    }

    function insertBoolUnsafe(uint256 handle, bool value, ITFHEDebuggerDB.RecordMeta calldata meta)
        external
        onlyDebugger
    {
        __insertUnsafe(
            handle,
            Record({meta: meta, value: (value) ? bytes.concat(bytes32(uint256(1))) : bytes.concat(bytes32(uint256(0)))})
        );
    }

    function insertUintUnsafe(uint256 handle, uint256 value, ITFHEDebuggerDB.RecordMeta calldata meta)
        external
        onlyDebugger
    {
        __insertUnsafe(handle, Record({meta: meta, value: bytes.concat(bytes32(value))}));
    }

    function __insertUnsafe(uint256 handle, ITFHEDebuggerDB.Record memory record) private {
        TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        $.db.records[handle] = record;
    }

    function exist(uint256 handle) external view returns (bool) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        return (r.meta.valueType != 0);
    }

    function isTrivial(uint256 handle) external view returns (bool) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        if (r.meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(handle);
        }
        return r.meta.trivial;
    }

    function isArithmeticallyValid(uint256 handle) external view returns (bool) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        if (r.meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(handle);
        }
        MathLib.ArithmeticFlags memory flags = r.meta.arithmeticFlags;
        return !flags.divisionByZero && !flags.overflow && !flags.underflow;
    }

    function getNumAsBytes32(uint256 handle) external view returns (bytes32) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);

        if (r.meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(handle);
        }
        TFHEHandle.checkIs256Bits(handle, TFHEHandle.typeOf(handle));
        TFHEHandle.checkTypeEq(handle, r.meta.valueType - 1);

        return __bytesToBytes32(r.value, 0);
    }

    function getBool(uint256 handle) external view returns (bool) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.ebool_t);
        return uint8(uint256(__bytesToBytes32(r.value, 0))) != 0;
    }

    function getU4(uint256 handle) external view returns (uint8) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.euint4_t);
        return uint8(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getU8(uint256 handle) external view returns (uint8) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.euint8_t);
        return uint8(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getU16(uint256 handle) external view returns (uint16) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.euint16_t);
        return uint16(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getU32(uint256 handle) external view returns (uint32) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.euint32_t);
        return uint32(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getU64(uint256 handle) external view returns (uint64) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.euint64_t);
        return uint64(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getU128(uint256 handle) external view returns (uint128) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.euint128_t);
        return uint128(uint256(__bytesToBytes32(r.value, 0)));
    }

    function getAddress(uint256 handle) external view returns (address) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.euint160_t);
        return address(uint160(uint256(__bytesToBytes32(r.value, 0))));
    }

    function getU256(uint256 handle) external view returns (uint256) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.euint256_t);
        return uint256(__bytesToBytes32(r.value, 0));
    }

    function getBytes64(uint256 handle) external view returns (bytes memory) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.ebytes64_t);
        if (r.value.length >= 64) {
            // should never happen
            revert ITFHEDebuggerDB.InternalError();
        }
        return r.value;
    }

    function getBytes128(uint256 handle) external view returns (bytes memory) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.ebytes128_t);
        if (r.value.length >= 128) {
            // should never happen
            revert ITFHEDebuggerDB.InternalError();
        }
        return r.value;
    }

    function getBytes256(uint256 handle) external view returns (bytes memory) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        __checkValueTypeEq(handle, r.meta.valueType, TFHEHandle.ebytes256_t);
        if (r.value.length >= 256) {
            // should never happen
            revert ITFHEDebuggerDB.InternalError();
        }
        return r.value;
    }

    function getBytes(uint256 handle) external view returns (bytes memory) {
        TFHEHandle.checkNotNull(handle);

        // TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        // ITFHEDebuggerDB.Record memory r = $.db.records[handle];
        ITFHEDebuggerDB.Record storage r = _getRecordStorage(handle);
        if (r.meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(handle);
        }
        TFHEHandle.checkIsBytes(handle, r.meta.valueType - 1);

        return r.value;
    }

    /**
     * Note: Requirements
     *
     *    - !! Boolean is also supported !!
     *    - typeOf(lct) == typeOf(rct)
     *    - TFHEHandle.ebool_t <= typeOf(lct) <= TFHEHandle.euint256_t
     *
     * Examples:
     *    TFHE.add(euint64, euint64)
     *    TFHE.eq(euint64, euint64)
     *    TFHE.eq(ebool, ebool)
     *    TFHE.and(ebool, ebool)
     *    etc.
     */
    function binaryOpNumCtNumCt(uint256 resultHandle, uint256 lct, uint256 rct, bool revertIfArithmeticError)
        external
        view
        returns (
            ITFHEDebuggerDB.RecordMeta memory meta,
            MathLib.UintValue memory lClear,
            MathLib.UintValue memory rClear
        )
    {
        TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();

        TFHEHandle.checkSame256Bits(lct, rct);

        ITFHEDebuggerDB.Record memory l_record = $.db.records[lct];
        ITFHEDebuggerDB.RecordMeta memory l_meta = l_record.meta;
        if (l_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(lct);
        }

        ITFHEDebuggerDB.Record memory r_record = $.db.records[rct];
        ITFHEDebuggerDB.RecordMeta memory r_meta = r_record.meta;
        if (r_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(rct);
        }

        if (revertIfArithmeticError) {
            MathLib.checkHandleArithmetic(lct, l_meta.arithmeticFlags);
            MathLib.checkHandleArithmetic(rct, r_meta.arithmeticFlags);
        }

        meta.valueType = TFHEHandle.typeOf(resultHandle) + 1;
        meta.trivial = l_meta.trivial && r_meta.trivial;

        lClear.value = uint256(__bytesToBytes32(l_record.value, 0));
        rClear.value = uint256(__bytesToBytes32(r_record.value, 0));

        lClear.flags = l_record.meta.arithmeticFlags;
        rClear.flags = r_record.meta.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - !! Boolean is also supported !!
     *    - TFHEHandle.ebool_t <= typeOf(lct) <= TFHEHandle.euint256_t
     *
     * Examples:
     *    TFHE.add(euint64, 1234)
     *    TFHE.eq(euint64, 1234)
     *    TFHE.eq(ebool, true)
     *    TFHE.and(ebool, true)
     *    etc.
     */
    function binaryOpNumCtNumPt(uint256 resultHandle, uint256 lct, bool revertIfArithmeticError)
        external
        view
        returns (ITFHEDebuggerDB.RecordMeta memory meta, MathLib.UintValue memory lClear)
    {
        TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();

        TFHEHandle.checkIs256Bits(lct);

        ITFHEDebuggerDB.Record memory l_record = $.db.records[lct];
        ITFHEDebuggerDB.RecordMeta memory l_meta = l_record.meta;
        if (l_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(lct);
        }

        if (revertIfArithmeticError) {
            MathLib.checkHandleArithmetic(lct, l_meta.arithmeticFlags);
        }

        meta.valueType = TFHEHandle.typeOf(resultHandle) + 1;
        meta.trivial = l_meta.trivial;

        lClear.value = uint256(__bytesToBytes32(l_record.value, 0));
        lClear.flags = l_meta.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - typeOf(lct) == typeOf(rct)
     *    - TFHEHandle.ebytes64_t <= typeOf(lct, rct) <= TFHEHandle.ebytes256_t
     *
     * Examples:
     *    TFHE.eq(ebytes64, ebytes64)
     *    TFHE.and(ebytes64, ebytes64)
     *    etc.
     */
    function binaryOpBytesCtBytesCt(uint256 resultHandle, uint256 lct, uint256 rct, bool revertIfArithmeticError)
        external
        view
        returns (
            ITFHEDebuggerDB.RecordMeta memory meta,
            MathLib.BytesValue memory lClear,
            MathLib.BytesValue memory rClear
        )
    {
        TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();

        TFHEHandle.checkSameBytes(lct, rct);

        ITFHEDebuggerDB.Record memory l_record = $.db.records[lct];
        ITFHEDebuggerDB.RecordMeta memory l_meta = l_record.meta;
        if (l_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(lct);
        }

        ITFHEDebuggerDB.Record memory r_record = $.db.records[rct];
        ITFHEDebuggerDB.RecordMeta memory r_meta = r_record.meta;
        if (r_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(rct);
        }

        if (revertIfArithmeticError) {
            MathLib.checkHandleArithmetic(lct, l_meta.arithmeticFlags);
            MathLib.checkHandleArithmetic(rct, r_meta.arithmeticFlags);
        }

        meta.valueType = TFHEHandle.typeOf(resultHandle) + 1;
        meta.trivial = l_meta.trivial && r_meta.trivial;

        lClear.value = l_record.value;
        rClear.value = r_record.value;

        lClear.flags = l_record.meta.arithmeticFlags;
        rClear.flags = r_record.meta.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - TFHEHandle.ebytes64_t <= typeOf(lct) <= TFHEHandle.ebytes256_t
     *
     * Examples:
     *    TFHE.ne(ebytes64, bytes.concat(...))
     *    TFHE.and(ebytes64, bytes.concat(...))
     *    etc.
     */
    function binaryOpBytesCtBytesPt(uint256 resultHandle, uint256 lct, bool revertIfArithmeticError)
        external
        view
        returns (ITFHEDebuggerDB.RecordMeta memory meta, MathLib.BytesValue memory lClear)
    {
        TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();

        TFHEHandle.checkIsBytes(lct);

        ITFHEDebuggerDB.Record memory l_record = $.db.records[lct];
        ITFHEDebuggerDB.RecordMeta memory l_meta = l_record.meta;
        if (l_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(lct);
        }

        if (revertIfArithmeticError) {
            MathLib.checkHandleArithmetic(lct, l_meta.arithmeticFlags);
        }

        meta.valueType = TFHEHandle.typeOf(resultHandle) + 1;
        meta.trivial = l_meta.trivial;

        lClear.value = l_record.value;
        lClear.flags = l_meta.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - !! Boolean is also supported !!
     *    - TFHEHandle.ebool_t <= typeOf(lct) <= TFHEHandle.euint256_t
     *
     * Examples:
     *    TFHE.neg(euint64)
     *    TFHE.neg(ebool) (doesnt mean anything)
     *    etc.
     */
    function unaryOpNumCt(uint256 resultHandle, uint256 ct, bool revertIfArithmeticError)
        external
        view
        returns (ITFHEDebuggerDB.RecordMeta memory meta, MathLib.UintValue memory clear)
    {
        TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();

        TFHEHandle.checkIs256Bits(ct);

        ITFHEDebuggerDB.Record memory ct_record = $.db.records[ct];
        ITFHEDebuggerDB.RecordMeta memory ct_meta = ct_record.meta;
        if (ct_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(ct);
        }

        if (revertIfArithmeticError) {
            MathLib.checkHandleArithmetic(ct, ct_meta.arithmeticFlags);
        }

        meta.valueType = TFHEHandle.typeOf(resultHandle) + 1;
        meta.trivial = ct_meta.trivial;

        clear.value = uint256(__bytesToBytes32(ct_record.value, 0));
        clear.flags = ct_meta.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - !! Boolean is also supported !!
     *    - TFHEHandle.ebool_t <= typeOf(lct) <= TFHEHandle.euint256_t
     *
     * Examples:
     *    TFHE.not(euint64)
     *    TFHE.not(ebool)
     *    etc.
     */
    function unaryOpBytesCt(uint256 resultHandle, uint256 ct, bool revertIfArithmeticError)
        external
        view
        returns (ITFHEDebuggerDB.RecordMeta memory meta, MathLib.BytesValue memory clear)
    {
        TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();

        TFHEHandle.checkIs256Bits(ct);

        ITFHEDebuggerDB.Record memory ct_record = $.db.records[ct];
        ITFHEDebuggerDB.RecordMeta memory ct_meta = ct_record.meta;
        if (ct_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(ct);
        }

        if (revertIfArithmeticError) {
            MathLib.checkHandleArithmetic(ct, ct_meta.arithmeticFlags);
        }

        meta.valueType = TFHEHandle.typeOf(resultHandle) + 1;
        meta.trivial = ct_meta.trivial;

        clear.value = ct_record.value;
        clear.flags = ct_meta.arithmeticFlags;
    }

    /**
     * Note: Requirements
     *
     *    - typeOf(control) == TFHEHandle.ebool_t
     *    - typeOf(ifTrue) == typeOf(ifFalse)
     *    - TFHEHandle.ebool_t <= typeOf(ifTrue, ifFalse) <= TFHEHandle.ebytes256_t
     *
     * Examples:
     *    TFHE.select(ebool, ebytes64, ebytes64)
     *    TFHE.select(ebool, euint8, euint8)
     *    etc.
     */
    function insertIfCtThenCtElseCt(
        uint256 resultHandle,
        uint256 control,
        uint256 ifTrue,
        uint256 ifFalse,
        bool revertIfArithmeticError
    ) external returns (ITFHEDebuggerDB.RecordMeta memory meta) {
        TFHEDebuggerDBStorage storage $ = _getTFHEDebuggerDBStorage();
        uint8 typeCt = TFHEHandle.typeOf(ifTrue);

        TFHEHandle.checkTypeEq(ifFalse, typeCt);
        TFHEHandle.checkTypeEq(control, TFHEHandle.ebool_t);

        ITFHEDebuggerDB.Record memory ifTrue_record = $.db.records[ifTrue];
        ITFHEDebuggerDB.RecordMeta memory ifTrue_meta = ifTrue_record.meta;
        if (ifTrue_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(ifTrue);
        }

        ITFHEDebuggerDB.Record memory ifFalse_record = $.db.records[ifFalse];
        ITFHEDebuggerDB.RecordMeta memory ifFalse_meta = ifFalse_record.meta;
        if (ifFalse_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(ifFalse);
        }

        ITFHEDebuggerDB.Record memory control_record = $.db.records[control];
        ITFHEDebuggerDB.RecordMeta memory control_meta = control_record.meta;
        if (control_meta.valueType == 0) {
            revert ITFHEDebuggerDB.HandleDoesNotExist(control);
        }

        bool clearControl = uint8(uint256(__bytesToBytes32(control_record.value, 0))) != 0;

        if (revertIfArithmeticError) {
            MathLib.checkHandleArithmetic(control, control_meta.arithmeticFlags);

            //
            // TFHE: Only check the final result
            //
            if (clearControl) {
                MathLib.checkHandleArithmetic(ifTrue, ifTrue_meta.arithmeticFlags);
            } else {
                MathLib.checkHandleArithmetic(ifFalse, ifFalse_meta.arithmeticFlags);
            }
        }

        if (clearControl) {
            __insertUnsafe(resultHandle, ifTrue_record);
            meta = ifTrue_record.meta;
        } else {
            __insertUnsafe(resultHandle, ifFalse_record);
            meta = ifFalse_record.meta;
        }
    }
}
