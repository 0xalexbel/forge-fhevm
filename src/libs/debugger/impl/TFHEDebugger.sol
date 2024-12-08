// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import {TFHEHandle} from "../../common/TFHEHandle.sol";
import {AddressLib} from "../../common/AddressLib.sol";
import {IRandomGenerator} from "../../common/interfaces/IRandomGenerator.sol";
import {ITFHEExecutor} from "../../core/interfaces/ITFHEExecutor.sol";
import {IInputVerifier} from "../../core/interfaces/IInputVerifier.sol";

import {ITFHEExecutorDebugger} from "./interfaces/ITFHEExecutorDebugger.sol";

// Public API
import {IFhevmDebugger} from "../interfaces/IFhevmDebugger.sol";
import {IFhevmDebuggerDB} from "../interfaces/IFhevmDebuggerDB.sol";
import {FFhevmDebugConfigStruct} from "../config/FFhevmDebugConfig.sol";

import {ITFHEDebuggerDB} from "./interfaces/ITFHEDebuggerDB.sol";
import {MathLib} from "./lib/MathLib.sol";

//import {console} from "forge-std/src/console.sol";

contract TFHEDebugger is UUPSUpgradeable, Ownable2StepUpgradeable, ITFHEExecutorDebugger, IFhevmDebugger {
    // ====================================================================== //
    //
    //           ⭐️ UUPSUpgradeable + Ownable2StepUpgradeable ⭐️
    //
    // ====================================================================== //

    /// @notice Name of the contract
    string private constant CONTRACT_NAME = "TFHEDebugger";

    /// @notice Version of the contract
    uint256 private constant MAJOR_VERSION = 0;
    uint256 private constant MINOR_VERSION = 1;
    uint256 private constant PATCH_VERSION = 0;

    bytes32 private constant RANDOM_SEED = keccak256("TFHEDebuggerDeterministicRandom");

    /// @notice transient storage. Data are potentially lost after upgrade.
    bytes32 constant TSLOT_ARITHMETIC_CHECK_COUNT = 0;
    bytes32 constant TSLOT_ARITHMETIC_CHECK_MODE = 0x0000000000000000000000000000000000000000000000000000000000000001;

    /// @custom:storage-location erc7201:fhevm.storage.TFHEDebugger
    struct TFHEDebuggerStorage {
        uint256 _randomCount;
        address _randomGeneratorAddress;
        ITFHEDebuggerDB _db;
    }

    // keccak256(abi.encode(uint256(keccak256("fhevm.storage.TFHEDebugger")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TFHEDebuggerStorageLocation =
        0x0f7b03a96d7d119524a66788a8bfc1e99eb1dd862bf3330342cc3c26298fde00;

    function _getTFHEDebuggerStorage() internal pure returns (TFHEDebuggerStorage storage $) {
        assembly {
            $.slot := TFHEDebuggerStorageLocation
        }
    }

    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyOwner {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract setting `initialOwner` as the initial owner
    function initialize(address initialOwner, address randomGeneratorAddress) external initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __TFHEDebugger_init(randomGeneratorAddress);
    }

    function __TFHEDebugger_init(address randomGeneratorAddress) internal onlyInitializing {
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();
        $._randomGeneratorAddress = randomGeneratorAddress;
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

    function verifyFFhevmDebuggerConfig(FFhevmDebugConfigStruct memory ffhevmDebuggerConfig) external {
        if (
            ffhevmDebuggerConfig.ACLAddress == address(0) || ffhevmDebuggerConfig.TFHEExecutorAddress == address(0)
                || ffhevmDebuggerConfig.FHEPaymentAddress == address(0)
                || ffhevmDebuggerConfig.KMSVerifierAddress == address(0)
        ) {
            revert InvalidFhevmConfigMissingAddress();
        }
        if (
            !AddressLib.isDeployed(ffhevmDebuggerConfig.ACLAddress)
                || !AddressLib.isDeployed(ffhevmDebuggerConfig.TFHEExecutorAddress)
                || !AddressLib.isDeployed(ffhevmDebuggerConfig.FHEPaymentAddress)
                || !AddressLib.isDeployed(ffhevmDebuggerConfig.KMSVerifierAddress)
        ) {
            revert("Wrong FHEVM config.");
        }

        if (ffhevmDebuggerConfig.forgeVmAddress != address(0)) {
            // Cheat code address, 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D.
            // address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
            require(
                ffhevmDebuggerConfig.forgeVmAddress == 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D,
                "Invalid Forge Vm address."
            );
            // If the debugger is running on a non-forge environment, reset the Vm address to zero
            if (!AddressLib.isDeployed(ffhevmDebuggerConfig.forgeVmAddress)) {
                ffhevmDebuggerConfig.forgeVmAddress = address(0);
            }
        }

        // Check debugger contracts consistency
        if (ffhevmDebuggerConfig.TFHEDebuggerAddress != address(this)) {
            revert InvalidFhevmConfigInvalidDebuggerAddress(ffhevmDebuggerConfig.TFHEDebuggerAddress);
        }
        if (ffhevmDebuggerConfig.TFHEDebuggerDBAddress != address(_db())) {
            revert InvalidFhevmConfigInvalidDebuggerDBAddress(ffhevmDebuggerConfig.TFHEDebuggerDBAddress);
        }

        // Check core contracts consistency
        try ITFHEExecutor(ffhevmDebuggerConfig.TFHEExecutorAddress).getACLAddress() returns (address aclAddr) {
            if (aclAddr != ffhevmDebuggerConfig.ACLAddress) {
                revert InvalidFhevmConfigAddressMismatch();
            }
        } catch {
            revert InvalidFhevmConfigInvalidCoreContract(ffhevmDebuggerConfig.TFHEExecutorAddress);
        }

        try ITFHEExecutor(ffhevmDebuggerConfig.TFHEExecutorAddress).getFHEPaymentAddress() returns (address paymentAddr)
        {
            if (paymentAddr != ffhevmDebuggerConfig.FHEPaymentAddress) {
                revert InvalidFhevmConfigAddressMismatch();
            }
        } catch {
            revert InvalidFhevmConfigInvalidCoreContract(ffhevmDebuggerConfig.TFHEExecutorAddress);
        }

        address _inputVerifierAddr;
        try ITFHEExecutor(ffhevmDebuggerConfig.TFHEExecutorAddress).getInputVerifierAddress() returns (
            address inputVerifierAddr
        ) {
            _inputVerifierAddr = inputVerifierAddr;
        } catch {
            revert InvalidFhevmConfigInvalidCoreContract(ffhevmDebuggerConfig.TFHEExecutorAddress);
        }

        try IInputVerifier(_inputVerifierAddr).getKMSVerifierAddress() returns (address kmsVerifierAddr) {
            if (kmsVerifierAddr != ffhevmDebuggerConfig.KMSVerifierAddress) {
                revert InvalidFhevmConfigAddressMismatch();
            }
        } catch {
            revert InvalidFhevmConfigInvalidCoreContract(_inputVerifierAddr);
        }
    }

    // ====================================================================== //
    //
    //             ⭐️ ArithmeticError Transient Functions ⭐️
    //
    // ====================================================================== //

    /// Has all subsequent TFHE calls perform arithmetic checks on the return values of every operator.
    function startArithmeticCheck() external {
        __startArithmeticCheck(type(uint256).max, ArithmeticCheckMode.ResultOnly);
    }

    /// Has all subsequent TFHE calls perform arithmetic checks on every operator, according to the given mode.
    /// @param mode if mode = OperandsOnly then check is only performed on operator operands,
    /// if mode = ResultsOnly then check is only performed on operator result, if mode = OperandsAndResult then check is performed on
    /// both operands and result.
    function startArithmeticCheck(ArithmeticCheckMode mode) external {
        __startArithmeticCheck(type(uint256).max, mode);
    }

    /// Stops arithmetic checks on TFHE calls.
    function stopArithmeticCheck() external {
        assembly {
            tstore(TSLOT_ARITHMETIC_CHECK_COUNT, 0)
        }
    }

    /// Has the next TFHE call only perform arithmetic check on the return value.
    function checkArithmetic() external {
        __startArithmeticCheck(1, ArithmeticCheckMode.ResultOnly);
    }

    /// Has the next TFHE call only perform arithmetic check according to the given mode.
    function checkArithmetic(ArithmeticCheckMode mode) external {
        __startArithmeticCheck(1, mode);
    }

    function __startArithmeticCheck(uint256 count, ArithmeticCheckMode mode) private {
        uint256 _count;
        assembly {
            _count := tload(TSLOT_ARITHMETIC_CHECK_COUNT)
        }
        require(_count == 0, "Arithmetic error checking already setup");
        assembly {
            tstore(TSLOT_ARITHMETIC_CHECK_COUNT, count)
            tstore(TSLOT_ARITHMETIC_CHECK_MODE, mode)
        }
    }

    function __shouldRevertIfOperandArithmeticError() private view returns (bool) {
        uint256 count;
        ArithmeticCheckMode mode;
        assembly {
            count := tload(TSLOT_ARITHMETIC_CHECK_COUNT)
            mode := tload(TSLOT_ARITHMETIC_CHECK_MODE)
        }
        // count > 0 means the arithmetic checking is on
        return (count > 0 && mode != ArithmeticCheckMode.ResultOnly);
    }

    function __shouldRevertIfArithmeticError() private view returns (bool) {
        uint256 count;
        assembly {
            count := tload(TSLOT_ARITHMETIC_CHECK_COUNT)
        }
        // count > 0 means the arithmetic checking is on
        return (count > 0);
    }

    /// Using a modifier is not possible because the arguments are computed in the function body.
    function __exit_checkArithmetic(uint256 result, MathLib.ArithmeticFlags memory flags) private {
        // get the arithmetic check count stored as a transient value
        uint256 count;
        assembly {
            count := tload(TSLOT_ARITHMETIC_CHECK_COUNT)
        }

        if (count > 0) {
            // get the arithmetic check mode stored as a transient value
            ArithmeticCheckMode mode;
            assembly {
                mode := tload(TSLOT_ARITHMETIC_CHECK_MODE)
            }

            // do we have to check the result ?
            if (mode != ArithmeticCheckMode.OperandsOnly) {
                MathLib.checkHandleArithmetic(result, flags);
            }

            count--;

            // set transient value: throwIfArithmeticErrorCount
            assembly {
                tstore(TSLOT_ARITHMETIC_CHECK_COUNT, count)
            }
        }
    }

    // ====================================================================== //
    //
    //                       ⭐️ API Functions ⭐️
    //
    // ====================================================================== //

    function db() external view returns (IFhevmDebuggerDB) {
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();
        return $._db;
    }

    function setDB(ITFHEDebuggerDB newDB) external onlyOwner {
        require(newDB.debugger() == address(this));
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();
        $._db = newDB;
    }

    function _db() private view returns (ITFHEDebuggerDB) {
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();
        return $._db;
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
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();

        TFHEHandle.checkSameNumeric(lhs, resultHandle);

        ITFHEDebuggerDB.RecordMeta memory meta;
        MathLib.UintValue memory lClearNum;
        MathLib.UintValue memory rClearNum;

        // stack too deep workaround
        {
            bool revertIfArithmeticError = __shouldRevertIfOperandArithmeticError();
            if (rhsIsScalar) {
                (meta, lClearNum) = $._db.binaryOpNumCtNumPt(resultHandle, lhs, revertIfArithmeticError);
                rClearNum.value = rhs;
            } else {
                (meta, lClearNum, rClearNum) = $._db.binaryOpNumCtNumCt(resultHandle, lhs, rhs, revertIfArithmeticError);
            }
        }

        // stack too deep workaround
        {
            MathLib.UintValue memory result = numericBinaryOpFunc(lClearNum, rClearNum, meta.valueType - 1, unChecked);

            meta.arithmeticFlags = result.flags;

            $._db.insertUintUnsafe(resultHandle, result.value, meta);
        }

        // Same as a modifier behaviour.
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

    // ===== Extra Unchecked ops =====

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
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();

        uint8 ctType = TFHEHandle.typeOf(ct);
        TFHEHandle.checkTypeIsNumeric(ctType, ct);

        if (resultTypeEqCtType) {
            TFHEHandle.checkTypeEq(resultHandle, ctType);
        }

        (ITFHEDebuggerDB.RecordMeta memory meta, MathLib.UintValue memory clearNum) =
            $._db.unaryOpNumCt(resultHandle, ct, __shouldRevertIfOperandArithmeticError());

        MathLib.UintValue memory result = numericUnaryOpFunc(clearNum, meta.valueType - 1);

        meta.arithmeticFlags = result.flags;

        $._db.insertUintUnsafe(resultHandle, result.value, meta);

        // Same as a modifier behaviour.
        // Must be the very last function call
        __exit_checkArithmetic(resultHandle, meta.arithmeticFlags);
    }

    function fheNeg(uint256 result, uint256 ct) external {
        // typeOf(result) == typeOf(ct)
        _fheNumericUnaryOp(MathLib.neg, result, ct, true /* resultTypeEqCtType */ );
    }

    function cast(uint256 result, uint256 ct, bytes1 toType) external {
        TFHEHandle.checkTypeEq(result, uint8(toType));

        if (result == ct) {
            _db().checkHandleExist(ct, uint8(toType));
            return;
        }

        if (uint8(toType) == TFHEHandle.ebool_t) {
            revert("Cast to bool not supported");
        }

        TFHEHandle.checkTypeNe(result, TFHEHandle.typeOf(ct));

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
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();

        uint8 lhsType = TFHEHandle.typeOf(lhs);
        TFHEHandle.checkIs256Bits(lhs, lhsType);
        TFHEHandle.checkTypeEq(resultHandle, lhsType);

        ITFHEDebuggerDB.RecordMeta memory meta;
        MathLib.UintValue memory lClearNum;
        MathLib.UintValue memory rClearNum;
        bool revertIfArithmeticError = __shouldRevertIfOperandArithmeticError();

        if (rhsIsScalar) {
            (meta, lClearNum) = $._db.binaryOpNumCtNumPt(resultHandle, lhs, revertIfArithmeticError);
            rClearNum.value = rhs;
        } else {
            (meta, lClearNum, rClearNum) = $._db.binaryOpNumCtNumCt(resultHandle, lhs, rhs, revertIfArithmeticError);
        }

        MathLib.UintValue memory result = bitBinaryOpFunc(lClearNum, rClearNum, meta.valueType - 1);

        meta.arithmeticFlags = result.flags;

        $._db.insertUintUnsafe(resultHandle, result.value, meta);

        // Same as a modifier behaviour.
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
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();

        uint8 typeCt = TFHEHandle.typeOf(ct);
        TFHEHandle.checkIs256Bits(ct, typeCt);
        TFHEHandle.checkTypeEq(resultHandle, typeCt);

        (ITFHEDebuggerDB.RecordMeta memory meta, MathLib.UintValue memory clearNum) =
            $._db.unaryOpNumCt(resultHandle, ct, __shouldRevertIfOperandArithmeticError());

        MathLib.UintValue memory result = bitUnaryOpFunc(clearNum, meta.valueType - 1);

        meta.arithmeticFlags = result.flags;

        $._db.insertUintUnsafe(resultHandle, result.value, meta);

        // Same as a modifier behaviour.
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
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();

        ITFHEDebuggerDB.RecordMeta memory meta;
        MathLib.UintValue memory lClearNum;
        MathLib.UintValue memory rClearNum;
        bool revertIfArithmeticError = __shouldRevertIfOperandArithmeticError();

        if (rhsIsScalar) {
            (meta, lClearNum) = $._db.binaryOpNumCtNumPt(resultHandle, lhs, revertIfArithmeticError);
            rClearNum.value = rhs;
        } else {
            (meta, lClearNum, rClearNum) = $._db.binaryOpNumCtNumCt(resultHandle, lhs, rhs, revertIfArithmeticError);
        }

        // MathLib.eq, ne, ge, gt, le, lt
        MathLib.BoolValue memory cmp = numericCmpBinaryOpFunc(lClearNum, rClearNum, TFHEHandle.typeOf(lhs));

        meta.arithmeticFlags = cmp.flags;

        $._db.insertBoolUnsafe(resultHandle, cmp.value, meta);

        // Same as a modifier behaviour.
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
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();

        (
            ITFHEDebuggerDB.RecordMeta memory meta,
            MathLib.BytesValue memory lClearBytes,
            MathLib.BytesValue memory rClearBytes
        ) = $._db.binaryOpBytesCtBytesCt(resultHandle, lhs, rhs, __shouldRevertIfOperandArithmeticError());

        // MathLib.eq, ne
        MathLib.BoolValue memory cmp = bytesCmpBinaryOpFunc(lClearBytes, rClearBytes, TFHEHandle.typeOf(lhs));

        meta.arithmeticFlags = cmp.flags;

        $._db.insertBoolUnsafe(resultHandle, cmp.value, meta);

        // Same as a modifier behaviour.
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
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();

        (ITFHEDebuggerDB.RecordMeta memory meta, MathLib.BytesValue memory lClearBytes) =
            $._db.binaryOpBytesCtBytesPt(resultHandle, lhs, __shouldRevertIfOperandArithmeticError());

        MathLib.BytesValue memory rClearBytes;
        rClearBytes.value = clearRhs;

        // MathLib.eq, ne
        MathLib.BoolValue memory cmp = bytesCmpBinaryOpFunc(lClearBytes, rClearBytes, TFHEHandle.typeOf(lhs));

        meta.arithmeticFlags = cmp.flags;

        $._db.insertBoolUnsafe(resultHandle, cmp.value, meta);

        // Same as a modifier behaviour.
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
        TFHEHandle.checkTypeEq(resultHandle, TFHEHandle.ebool_t);

        uint8 lhsType = TFHEHandle.typeOf(lhs);
        if (lhsType >= TFHEHandle.ebytes64_t) {
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
        TFHEHandle.checkTypeEq(resultHandle, TFHEHandle.ebool_t);

        uint8 lhsType = TFHEHandle.typeOf(lhs);
        if (lhsType >= TFHEHandle.ebytes64_t) {
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
        TFHEHandle.checkTypeEq(resultHandle, TFHEHandle.ebool_t);

        uint8 lhsType = TFHEHandle.typeOf(lhs);
        if (lhsType >= TFHEHandle.ebytes64_t) {
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

    function fheEq(uint256 result, uint256 lhs, bytes calldata rhs, bytes1 scalarByte) external {
        _fheBytesCmpBinaryOp(MathLib.eqBytes, result, lhs, rhs, (scalarByte != 0x0));
    }

    function fheNe(uint256 result, uint256 lhs, uint256 rhs, bytes1 scalarByte) external {
        _fheCmpBinaryOp(MathLib.ne, MathLib.neBytes, result, lhs, rhs, (scalarByte != 0x0));
    }

    function fheNe(uint256 result, uint256 lhs, bytes calldata rhs, bytes1 scalarByte) external {
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
        bytes calldata, /*inputProof*/
        bytes1 inputType
    ) external view {
        if (result == 0) {
            // Previous verify failed
            revert VerifyCipherTextFailed(uint256(inputHandle), msg.sender, callerAddress);
        } else {
            _db().checkHandleExist(result, uint8(inputType));
        }
    }

    function trivialEncrypt(uint256 result, uint256 pt, bytes1 toType) external {
        _db().checkAndInsert256Bits(result, pt, uint8(toType), true /* trivial */ );
    }

    function trivialEncrypt(uint256 result, bytes calldata pt, bytes1 toType) external {
        _db().checkAndInsertBytes(result, pt, uint8(toType), true /* trivial */ );
    }

    function fheIfThenElse(uint256 result, uint256 control, uint256 ifTrue, uint256 ifFalse) external {
        ITFHEDebuggerDB.RecordMeta memory meta =
            _db().insertIfCtThenCtElseCt(result, control, ifTrue, ifFalse, __shouldRevertIfArithmeticError());

        // Same as a modifier behaviour.
        // Must be the very last function call
        __exit_checkArithmetic(result, meta.arithmeticFlags);
    }

    // ===== Random =====

    function fheRand(uint256 result, bytes1 randType) external {
        _fheRand(result, type(uint256).max, randType);
    }

    function fheRandBounded(uint256 result, uint256 upperBound, bytes1 randType) external {
        _fheRand(result, upperBound, randType);
    }

    function __randomUint() private returns (uint256 result) {
        TFHEDebuggerStorage storage $ = _getTFHEDebuggerStorage();
        if ($._randomGeneratorAddress == address(0)) {
            // Deterministic
            result = uint256(keccak256(bytes.concat(RANDOM_SEED, bytes32($._randomCount))));
        } else {
            // using vm.randomUint()
            result = IRandomGenerator($._randomGeneratorAddress).randomUint();
        }
        $._randomCount++;
    }

    function _fheRand(uint256 result, uint256 upperBound, bytes1 randType) private {
        uint8 typeCt = uint8(randType);

        TFHEHandle.checkIs256Bits(result, typeCt);

        MathLib.UintValue memory clearRnd;
        clearRnd.value = __randomUint();

        MathLib.UintValue memory random = MathLib.cast(clearRnd, typeCt);

        if (random.value > upperBound) {
            random.value = upperBound;
        }

        if (_db().exist(result)) {
            revert ITFHEDebuggerDB.HandleAlreadyExist(result);
        }

        _db().checkAndInsert256Bits(result, random.value, typeCt, false /* trivial */ );
    }
}
