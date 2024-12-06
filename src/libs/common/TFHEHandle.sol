// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

library TFHEHandle {
    // ====================================================================== //
    //
    //     ❌ 🧨 !!! MUST be equal to TFHEExecutor.HANDLE_VERSION !!! 🧨 ❌
    //
    // ====================================================================== //

    uint8 internal constant HANDLE_VERSION = 0;

    // ====================================================================== //
    //
    //           ❌ 🧨 !!! MUST be equal to TFHE.Common !!! 🧨 ❌
    //
    // ====================================================================== //

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

    // ====================================================================== //
    //
    //     ❌ 🧨 !!! MUST be equal to TFHEExecutor.Operators !!! 🧨 ❌
    //
    // ====================================================================== //

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

    error NullHandle();
    error Not256BitsHandle(uint256 handle, uint8 typeCt);
    error NotBytesHandle(uint256 handle, uint8 typeCt);
    error NotNumericHandle(uint256 handle, uint8 typeCt);
    error NotEqualToType(uint256 handle, uint8 typeCt);
    error EqualToType(uint256 handle, uint8 typeCt);

    // gas cost : 38
    function typeOf(uint256 handle) internal pure returns (uint8) {
        uint8 typeCt = uint8(handle >> 8);
        return typeCt;
    }

    function isType256Bits(uint8 typeCt) internal pure returns (bool) {
        return (!(typeCt >= ebytes64_t && typeCt <= ebytes256_t));
    }

    function isTypeBytes(uint8 typeCt) internal pure returns (bool) {
        return (typeCt >= ebytes64_t && typeCt <= ebytes256_t);
    }

    function is256Bits(uint256 handle) internal pure returns (bool) {
        uint8 typeCt = typeOf(handle);
        return (!(typeCt >= ebytes64_t && typeCt <= ebytes256_t));
    }

    function isBytes(uint256 handle) internal pure returns (bool) {
        uint8 typeCt = typeOf(handle);
        return (typeCt >= ebytes64_t && typeCt <= ebytes256_t);
    }

    function isNumeric(uint256 handle) internal pure returns (bool) {
        uint8 typeCt = typeOf(handle);
        return (!(typeCt >= euint4_t && typeCt <= euint256_t));
    }

    function isBool(uint256 handle) internal pure returns (bool) {
        return typeOf(handle) == ebool_t;
    }

    function checkNotNull(uint256 handle) internal pure {
        if (handle == 0) {
            revert NullHandle();
        }
    }

    /**
     * @dev Throws if 'typeCt' is not a 256-bits type. From bool to uint256
     * @dev gas cost: 75
     */
    function checkTypeIs256Bits(uint8 typeCt, uint256 handleIfError) internal pure {
        if (!(typeCt >= ebool_t && typeCt <= euint256_t)) {
            revert Not256BitsHandle(handleIfError, typeCt);
        }
    }

    /**
     * @dev Throws if 'handle' type is not 256-bits. From bool to uint256
     * @dev gas cost: 103
     */
    function checkIs256Bits(uint256 handle) internal pure {
        uint8 typeCt = typeOf(handle);
        if (!(typeCt >= ebool_t && typeCt <= euint256_t)) {
            revert Not256BitsHandle(handle, typeCt);
        }
    }

    /**
     * @dev Throws if 'handle' type is of specifed 256-bits type
     */
    function checkIs256Bits(uint256 handle, uint8 expected256BitsType) internal pure {
        uint8 typeCt = typeOf(handle);
        if (!(typeCt >= ebool_t && typeCt <= euint256_t)) {
            revert Not256BitsHandle(handle, typeCt);
        }
        if (typeCt != expected256BitsType) {
            revert NotEqualToType(handle, expected256BitsType);
        }
    }

    /**
     * @dev Throws if 'typeCt' is not a uint. From uint4 to uint256
     */
    function checkTypeIsNumeric(uint8 typeCt, uint256 handleIfError) internal pure {
        if (!(typeCt >= euint4_t && typeCt <= euint256_t)) {
            revert NotNumericHandle(handleIfError, typeCt);
        }
    }

    /**
     * @dev Throws if 'handle' type is not uint. From uint4 to uint256
     */
    function checkIsNumeric(uint256 handle) internal pure {
        uint8 typeCt = typeOf(handle);
        if (!(typeCt >= euint4_t && typeCt <= euint256_t)) {
            revert NotNumericHandle(handle, typeCt);
        }
    }

    /**
     * @dev Throws if 'typeCt' is not a bytes type. From bytes64 to bytes256
     */
    function checkTypeIsBytes(uint8 typeCt, uint256 handleIfError) internal pure {
        if (!(typeCt >= ebytes64_t && typeCt <= ebytes256_t)) {
            revert NotBytesHandle(handleIfError, typeCt);
        }
    }

    /**
     * @dev Throws if 'handle' type is not bytes. From bytes64 to bytes256
     */
    function checkIsBytes(uint256 handle) internal pure {
        uint8 typeCt = typeOf(handle);
        if (!(typeCt >= ebytes64_t && typeCt <= ebytes256_t)) {
            revert NotBytesHandle(handle, typeCt);
        }
    }

    /**
     * @dev Throws if 'handle' type is of specifed bytes type
     */
    function checkIsBytes(uint256 handle, uint8 expectedBytesType) internal pure {
        uint8 typeCt = typeOf(handle);
        if (!(typeCt >= ebytes64_t && typeCt <= ebytes256_t)) {
            revert NotBytesHandle(handle, typeCt);
        }
        if (typeCt != expectedBytesType) {
            revert NotEqualToType(handle, expectedBytesType);
        }
    }

    /**
     * @dev Throws if 'handle1' type is not bytes or typeOf(handle1) != typeOf(handle2)
     */
    function checkSameBytes(uint256 handle1, uint256 handle2) internal pure {
        uint8 typeCt1 = typeOf(handle1);
        if (!(typeCt1 >= ebytes64_t && typeCt1 <= ebytes256_t)) {
            revert NotBytesHandle(handle1, typeCt1);
        }
        if (typeOf(handle2) != typeCt1) {
            revert NotEqualToType(handle2, typeCt1);
        }
    }

    /**
     * @dev Throws if 'handle1' type is not 256-bits or typeOf(handle1) != typeOf(handle2)
     */
    function checkSame256Bits(uint256 handle1, uint256 handle2) internal pure {
        uint8 typeCt1 = typeOf(handle1);
        if (typeCt1 >= ebytes64_t && typeCt1 <= ebytes256_t) {
            revert Not256BitsHandle(handle1, typeCt1);
        }
        if (typeOf(handle2) != typeCt1) {
            revert NotEqualToType(handle2, typeCt1);
        }
    }

    /**
     * @dev Throws if 'handle1' type is not uint or typeOf(handle1) != typeOf(handle2)
     */
    function checkSameNumeric(uint256 handle1, uint256 handle2) internal pure {
        uint8 typeCt1 = typeOf(handle1);
        if (!(typeCt1 >= euint4_t && typeCt1 <= euint256_t)) {
            revert NotNumericHandle(handle1, typeCt1);
        }
        if (typeOf(handle2) != typeCt1) {
            revert NotEqualToType(handle2, typeCt1);
        }
    }

    function getPackedBytesLen(uint256 handle) internal pure returns (uint256) {
        uint8 typeCt = typeOf(handle);
        if (typeCt == ebytes64_t) {
            return 64; //512
        }
        if (typeCt == ebytes128_t) {
            return 128; //1024
        }
        if (typeCt == ebytes256_t) {
            return 256; //2048
        }
        return 32; //256
    }

    function getTypePackedBytesLen(uint8 typeCt) internal pure returns (uint256) {
        if (typeCt == ebytes64_t) {
            return 64; //512
        }
        if (typeCt == ebytes128_t) {
            return 128; //1024
        }
        if (typeCt == ebytes256_t) {
            return 256; //2048
        }
        return 32; //256
    }

    function checkTypeEq(uint256 handle, uint8 typeCt) internal pure {
        if (typeOf(handle) != typeCt) {
            revert NotEqualToType(handle, typeCt);
        }
    }

    function checkTypeNe(uint256 handle, uint8 typeCt) internal pure {
        if (typeOf(handle) == typeCt) {
            revert EqualToType(handle, typeCt);
        }
    }

    function _appendType(uint256 prehandle, uint8 handleType) private pure returns (uint256 result) {
        result = prehandle & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000;
        result = result | (uint256(handleType) << 8); // append type
        result = result | HANDLE_VERSION;
    }

    function precomputeBinaryNumOp(Operators op, uint256 lhs, uint256 rhs, bool isScalar, address aclAddress)
        internal
        view
        returns (uint256 result)
    {
        require(lhs != 0);
        require(rhs != 0 || isScalar);
        result = uint256(
            keccak256(
                abi.encodePacked(op, lhs, rhs, (isScalar) ? bytes1(0x01) : bytes1(0x00), aclAddress, block.chainid)
            )
        );
        result = _appendType(result, typeOf(lhs));
    }

    function precomputeBinaryBoolOp(Operators op, uint256 lhs, uint256 rhs, bool isScalar, address aclAddress)
        internal
        view
        returns (uint256 result)
    {
        require(lhs != 0);
        require(rhs != 0 || isScalar);
        result = uint256(
            keccak256(
                abi.encodePacked(op, lhs, rhs, (isScalar) ? bytes1(0x01) : bytes1(0x00), aclAddress, block.chainid)
            )
        );
        result = _appendType(result, ebool_t);
    }

    function precomputeUnaryOp(Operators op, uint256 ct, address aclAddress) internal view returns (uint256 result) {
        require(ct != 0);
        result = uint256(keccak256(abi.encodePacked(op, ct, aclAddress, block.chainid)));
        result = _appendType(result, typeOf(ct));
    }

    function precomputeHandleCast(uint256 ct, uint8 toType, address aclAddress)
        internal
        view
        returns (uint256 result)
    {
        require(ct != 0);
        result = uint256(keccak256(abi.encodePacked(Operators.cast, ct, bytes1(toType), aclAddress, block.chainid)));
        result = _appendType(result, toType);
    }

    // Some gas stats:
    // ===============
    // empty = 880 (925 if chainId is passed as argument)
    // require = 940 (cost = 60)
    // encodePacked = 300
    // appendType = 150
    // full = 1378
    // indirection = 1432
    function precomputeTrivialEncrypt(uint256 pt, uint8 toType, address aclAddress)
        internal
        view
        returns (uint256 result)
    {
        require(pt != 0);
        result = uint256(
            keccak256(abi.encodePacked(Operators.trivialEncrypt, pt, bytes1(toType), aclAddress, block.chainid))
        );
        result = _appendType(result, toType);
    }

    function precomputeTrivialEncrypt(bytes memory pt, uint8 toType, address aclAddress)
        internal
        view
        returns (uint256 result)
    {
        result = uint256(
            keccak256(abi.encodePacked(Operators.trivialEncrypt, pt, bytes1(toType), aclAddress, block.chainid))
        );
        result = _appendType(result, toType);
    }

    function precomputeIfThenElse(uint256 control, uint256 ifTrue, uint256 ifFalse, address aclAddress)
        internal
        view
        returns (uint256 result)
    {
        result = uint256(
            keccak256(abi.encodePacked(Operators.fheIfThenElse, control, ifTrue, ifFalse, aclAddress, block.chainid))
        );
        result = _appendType(result, typeOf(ifTrue));
    }
}
