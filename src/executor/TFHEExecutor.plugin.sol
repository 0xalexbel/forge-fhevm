// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import "fhevm/lib/ACL.sol";
import "fhevm/lib/FHEPayment.sol";
import "fhevm/lib/ACLAddress.sol";
import "fhevm/lib/FHEPaymentAddress.sol";
import "fhevm/lib/InputVerifierAddress.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import "./ITFHEExecutorPlugin.sol";
import "./TFHEExecutorPluginStorage.sol";

interface IInputVerifier {
    function verifyCiphertext(
        TFHEExecutor.ContextUserInputs memory context,
        bytes32 inputHandle,
        bytes memory inputProof
    ) external returns (uint256);
}

contract TFHEExecutor is TFHEExecutorPluginStorage, UUPSUpgradeable, Ownable2StepUpgradeable {
    /// @notice Handle version
    uint8 public constant HANDLE_VERSION = 0;

    /// @notice Name of the contract
    string private constant CONTRACT_NAME = "TFHEExecutor";

    /// @notice Version of the contract
    uint256 private constant MAJOR_VERSION = 0;
    uint256 private constant MINOR_VERSION = 1;
    uint256 private constant PATCH_VERSION = 0;

    ACL private constant acl = ACL(aclAdd);
    FHEPayment private constant fhePayment = FHEPayment(fhePaymentAdd);
    IInputVerifier private constant inputVerifier = IInputVerifier(inputVerifierAdd);

    /// @custom:storage-location erc7201:fhevm.storage.TFHEExecutor
    struct TFHEExecutorStorage {
        uint256 counterRand;
    }
    /// @notice counter used for computing handles of randomness operators

    struct ContextUserInputs {
        address aclAddress;
        address userAddress;
        address contractAddress;
    }

    // keccak256(abi.encode(uint256(keccak256("fhevm.storage.TFHEExecutor")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TFHEExecutorStorageLocation =
        0xa436a06f0efce5ea38c956a21e24202a59b3b746d48a23fb52b4a5bc33fe3e00;

    function _getTFHEExecutorStorage() internal pure returns (TFHEExecutorStorage storage $) {
        assembly {
            $.slot := TFHEExecutorStorageLocation
        }
    }

    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyOwner {}

    /// @notice Getter function for the ACL contract address
    function getACLAddress() public view virtual returns (address) {
        return address(acl);
    }

    /// @notice Getter function for the FHEPayment contract address
    function getFHEPaymentAddress() public view virtual returns (address) {
        return address(fhePayment);
    }

    /// @notice Getter function for the InputVerifier contract address
    function getInputVerifierAddress() public view virtual returns (address) {
        return address(inputVerifier);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract setting `initialOwner` as the initial owner
    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
    }

    enum Operators {
        fheAdd,
        fheSub,
        fheMul,
        fheDiv,
        fheRem,
        fheBitAnd,
        fheBitOr,
        fheBitXor,
        fheShl,
        fheShr,
        fheRotl,
        fheRotr,
        fheEq,
        fheNe,
        fheGe,
        fheGt,
        fheLe,
        fheLt,
        fheMin,
        fheMax,
        fheNeg,
        fheNot,
        verifyCiphertext,
        cast,
        trivialEncrypt,
        fheIfThenElse,
        fheRand,
        fheRandBounded
    }

    function isPowerOfTwo(uint256 x) internal pure virtual returns (bool) {
        return (x > 0) && ((x & (x - 1)) == 0);
    }

    /// @dev handle format for user inputs is: keccak256(keccak256(CiphertextFHEList)||index_handle)[0:29] || index_handle || handle_type || handle_version
    /// @dev other handles format (fhe ops results) is: keccak256(keccak256(rawCiphertextFHEList)||index_handle)[0:30] || handle_type || handle_version
    /// @dev the CiphertextFHEList actually contains: 1 byte (= N) for size of handles_list, N bytes for the handles_types : 1 per handle, then the original fhe160list raw ciphertext
    function typeOf(uint256 handle) internal pure virtual returns (uint8) {
        uint8 typeCt = uint8(handle >> 8);
        return typeCt;
    }

    function appendType(uint256 prehandle, uint8 handleType) internal pure virtual returns (uint256 result) {
        result = prehandle & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000;
        result = result | (uint256(handleType) << 8); // append type
        result = result | HANDLE_VERSION;
    }

    function requireType(uint256 handle, uint256 supportedTypes) internal pure virtual {
        uint8 typeCt = typeOf(handle);
        require((1 << typeCt) & supportedTypes > 0, "Unsupported type");
    }

    function unaryOp(Operators op, uint256 ct) internal virtual returns (uint256 result) {
        require(acl.isAllowed(ct, msg.sender), "Sender doesn't own ct on op");
        result = uint256(keccak256(abi.encodePacked(op, ct, acl, block.chainid)));
        uint8 typeCt = typeOf(ct);
        result = appendType(result, typeCt);
        acl.allowTransient(result, msg.sender);
    }

    function binaryOp(Operators op, uint256 lhs, uint256 rhs, bytes1 scalar, uint8 resultType)
        internal
        virtual
        returns (uint256 result)
    {
        require(acl.isAllowed(lhs, msg.sender), "Sender doesn't own lhs on op");
        if (scalar == 0x00) {
            require(acl.isAllowed(rhs, msg.sender), "Sender doesn't own rhs on op");
            uint8 typeRhs = typeOf(rhs);
            uint8 typeLhs = typeOf(lhs);
            require(typeLhs == typeRhs, "Incompatible types for lhs and rhs");
        }
        result = uint256(keccak256(abi.encodePacked(op, lhs, rhs, scalar, acl, block.chainid)));
        result = appendType(result, resultType);
        acl.allowTransient(result, msg.sender);
    }

    function ternaryOp(Operators op, uint256 lhs, uint256 middle, uint256 rhs)
        internal
        virtual
        returns (uint256 result)
    {
        require(acl.isAllowed(lhs, msg.sender), "Sender doesn't own lhs on op");
        require(acl.isAllowed(middle, msg.sender), "Sender doesn't own middle on op");
        require(acl.isAllowed(rhs, msg.sender), "Sender doesn't own rhs on op");
        uint8 typeLhs = typeOf(lhs);
        uint8 typeMiddle = typeOf(middle);
        uint8 typeRhs = typeOf(rhs);
        require(typeLhs == 0, "Unsupported type for lhs"); // lhs must be ebool
        require(typeMiddle == typeRhs, "Incompatible types for middle and rhs");
        result = uint256(keccak256(abi.encodePacked(op, lhs, middle, rhs, acl, block.chainid)));
        result = appendType(result, typeMiddle);
        acl.allowTransient(result, msg.sender);
    }

    function fheAdd(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheAdd(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheAdd, lhs, rhs, scalar, lhsType);
        plugin().fheAdd(result, lhs, rhs, scalarByte);
    }

    function fheSub(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheSub(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheSub, lhs, rhs, scalar, lhsType);
        plugin().fheSub(result, lhs, rhs, scalarByte);
    }

    function fheMul(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheMul(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheMul, lhs, rhs, scalar, lhsType);
        plugin().fheMul(result, lhs, rhs, scalarByte);
    }

    function fheDiv(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        require(scalarByte & 0x01 == 0x01, "Only fheDiv by a scalar is supported");
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheDiv(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheDiv, lhs, rhs, scalar, lhsType);
        plugin().fheDiv(result, lhs, rhs, scalarByte);
    }

    function fheRem(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        require(scalarByte & 0x01 == 0x01, "Only fheRem by a scalar is supported");
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheRem(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheRem, lhs, rhs, scalar, lhsType);
        plugin().fheRem(result, lhs, rhs, scalarByte);
    }

    function fheBitAnd(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        require(scalarByte & 0x01 == 0x00, "Only fheBitAnd by a ciphertext is supported");
        uint256 supportedTypes = (1 << 0) + (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheBitAnd(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheBitAnd, lhs, rhs, scalar, lhsType);
        plugin().fheBitAnd(result, lhs, rhs, scalarByte);
    }

    function fheBitOr(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        require(scalarByte & 0x01 == 0x00, "Only fheBitOr by a ciphertext is supported");
        uint256 supportedTypes = (1 << 0) + (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheBitOr(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheBitOr, lhs, rhs, scalar, lhsType);
        plugin().fheBitOr(result, lhs, rhs, scalarByte);
    }

    function fheBitXor(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        require(scalarByte & 0x01 == 0x00, "Only fheBitXor by a ciphertext is supported");
        uint256 supportedTypes = (1 << 0) + (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheBitXor(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheBitXor, lhs, rhs, scalar, lhsType);
        plugin().fheBitXor(result, lhs, rhs, scalarByte);
    }

    function fheShl(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheShl(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheShl, lhs, rhs, scalar, lhsType);
        plugin().fheShl(result, lhs, rhs, scalarByte);
    }

    function fheShr(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheShr(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheShr, lhs, rhs, scalar, lhsType);
        plugin().fheShr(result, lhs, rhs, scalarByte);
    }

    function fheRotl(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheRotl(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheRotl, lhs, rhs, scalar, lhsType);
        plugin().fheRotl(result, lhs, rhs, scalarByte);
    }

    function fheRotr(uint256 lhs, uint256 rhs, bytes1 scalarByte) external returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheRotr(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheRotr, lhs, rhs, scalar, lhsType);
        plugin().fheRotr(result, lhs, rhs, scalarByte);
    }

    function fheEq(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5) + (1 << 7) + (1 << 11);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheEq(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheEq, lhs, rhs, scalar, 0);
        plugin().fheEq(result, lhs, rhs, scalarByte);
    }

    function fheNe(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5) + (1 << 7) + (1 << 11);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheNe(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheNe, lhs, rhs, scalar, 0);
        plugin().fheNe(result, lhs, rhs, scalarByte);
    }

    function fheGe(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheGe(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheGe, lhs, rhs, scalar, 0);
        plugin().fheGe(result, lhs, rhs, scalarByte);
    }

    function fheGt(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheGt(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheGt, lhs, rhs, scalar, 0);
        plugin().fheGt(result, lhs, rhs, scalarByte);
    }

    function fheLe(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheLe(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheLe, lhs, rhs, scalar, 0);
        plugin().fheLe(result, lhs, rhs, scalarByte);
    }

    function fheLt(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheLt(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheLt, lhs, rhs, scalar, 0);
        plugin().fheLt(result, lhs, rhs, scalarByte);
    }

    function fheMin(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheMin(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheMin, lhs, rhs, scalar, lhsType);
        plugin().fheMin(result, lhs, rhs, scalarByte);
    }

    function fheMax(uint256 lhs, uint256 rhs, bytes1 scalarByte) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(lhs, supportedTypes);
        uint8 lhsType = typeOf(lhs);
        bytes1 scalar = scalarByte & 0x01;
        fhePayment.payForFheMax(msg.sender, lhsType, scalar);
        result = binaryOp(Operators.fheMax, lhs, rhs, scalar, lhsType);
        plugin().fheMax(result, lhs, rhs, scalarByte);
    }

    function fheNeg(uint256 ct) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(ct, supportedTypes);
        uint8 typeCt = typeOf(ct);
        fhePayment.payForFheNeg(msg.sender, typeCt);
        result = unaryOp(Operators.fheNeg, ct);
        plugin().fheNeg(result, ct);
    }

    function fheNot(uint256 ct) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 0) + (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(ct, supportedTypes);
        uint8 typeCt = typeOf(ct);
        fhePayment.payForFheNot(msg.sender, typeCt);
        result = unaryOp(Operators.fheNot, ct);
        plugin().fheNot(result, ct);
    }

    function verifyCiphertext(bytes32 inputHandle, address userAddress, bytes memory inputProof, bytes1 inputType)
        external
        virtual
        returns (uint256 result)
    {
        ContextUserInputs memory contextUserInputs =
            ContextUserInputs({aclAddress: address(acl), userAddress: userAddress, contractAddress: msg.sender});
        uint8 typeCt = typeOf(uint256(inputHandle));
        require(uint8(inputType) == typeCt, "Wrong type");
        result = inputVerifier.verifyCiphertext(contextUserInputs, inputHandle, inputProof);
        acl.allowTransient(result, msg.sender);
        plugin().verifyCiphertext(result, inputHandle, userAddress, inputProof, inputType);
    }

    function cast(uint256 ct, bytes1 toType) external virtual returns (uint256 result) {
        require(acl.isAllowed(ct, msg.sender), "Sender doesn't own ct on cast");
        uint256 supportedTypesInput = (1 << 0) + (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        requireType(ct, supportedTypesInput);
        uint256 supportedTypesOutput = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5); // @note: unsupported casting to ebool (use fheNe instead)
        require((1 << uint8(toType)) & supportedTypesOutput > 0, "Unsupported output type");
        uint8 typeCt = typeOf(ct);
        require(bytes1(typeCt) != toType, "Cannot cast to same type");
        fhePayment.payForCast(msg.sender, typeCt);
        result = uint256(keccak256(abi.encodePacked(Operators.cast, ct, toType, acl, block.chainid)));
        result = appendType(result, uint8(toType));
        acl.allowTransient(result, msg.sender);
        plugin().cast(result, ct, toType);
    }

    function trivialEncrypt(uint256 pt, bytes1 toType) external virtual returns (uint256 result) {
        uint256 supportedTypes = (1 << 0) + (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5) + (1 << 7);
        uint8 toT = uint8(toType);
        require((1 << toT) & supportedTypes > 0, "Unsupported type");
        fhePayment.payForTrivialEncrypt(msg.sender, toT);
        result = uint256(keccak256(abi.encodePacked(Operators.trivialEncrypt, pt, toType, acl, block.chainid)));
        result = appendType(result, toT);
        acl.allowTransient(result, msg.sender);
        plugin().trivialEncrypt(result, pt, toType);
    }

    function fheIfThenElse(uint256 control, uint256 ifTrue, uint256 ifFalse)
        external
        virtual
        returns (uint256 result)
    {
        uint256 supportedTypes = (1 << 1) + (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5) + (1 << 7);
        requireType(ifTrue, supportedTypes);
        uint8 typeCt = typeOf(ifTrue);
        fhePayment.payForIfThenElse(msg.sender, typeCt);
        result = ternaryOp(Operators.fheIfThenElse, control, ifTrue, ifFalse);
        plugin().fheIfThenElse(result, control, ifTrue, ifFalse);
    }

    function fheRand(bytes1 randType) external virtual returns (uint256 result) {
        TFHEExecutorStorage storage $ = _getTFHEExecutorStorage();
        uint256 supportedTypes = (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        uint8 randT = uint8(randType);
        require((1 << randT) & supportedTypes > 0, "Unsupported erandom type");
        fhePayment.payForFheRand(msg.sender, randT);
        bytes16 seed = bytes16(
            keccak256(abi.encodePacked($.counterRand, acl, block.chainid, blockhash(block.number - 1), block.timestamp))
        );
        result = uint256(keccak256(abi.encodePacked(Operators.fheRand, randType, seed)));
        result = appendType(result, randT);
        acl.allowTransient(result, msg.sender);
        $.counterRand++;
        plugin().fheRand(result, randType);
    }

    function fheRandBounded(uint256 upperBound, bytes1 randType) external virtual returns (uint256 result) {
        TFHEExecutorStorage storage $ = _getTFHEExecutorStorage();
        uint256 supportedTypes = (1 << 2) + (1 << 3) + (1 << 4) + (1 << 5);
        uint8 randT = uint8(randType);
        require((1 << randT) & supportedTypes > 0, "Unsupported erandom type");
        require(isPowerOfTwo(upperBound), "UpperBound must be a power of 2");
        fhePayment.payForFheRandBounded(msg.sender, randT);
        bytes16 seed = bytes16(
            keccak256(abi.encodePacked($.counterRand, acl, block.chainid, blockhash(block.number - 1), block.timestamp))
        );
        result = uint256(keccak256(abi.encodePacked(Operators.fheRandBounded, upperBound, randType, seed)));
        result = appendType(result, randT);
        acl.allowTransient(result, msg.sender);
        $.counterRand++;
        plugin().fheRandBounded(result, upperBound, randType);
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
}
