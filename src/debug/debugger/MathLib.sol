// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Common} from "../fhevm/lib/TFHE.sol";

library MathLib {
    struct UintValue {
        uint256 value;
        ArithmeticFlags flags;
    }

    struct BoolValue {
        bool value;
        ArithmeticFlags flags;
    }

    struct BytesValue {
        bytes value;
        ArithmeticFlags flags;
    }

    struct ArithmeticFlags {
        bool divisionByZero;
        bool overflow;
        bool underflow;
    }

    function orArithmeticFlags(ArithmeticFlags memory l_flags, ArithmeticFlags memory r_flags)
        internal
        pure
        returns (ArithmeticFlags memory flags)
    {
        flags.overflow = l_flags.overflow || r_flags.overflow;
        flags.underflow = l_flags.underflow || r_flags.underflow;
        flags.divisionByZero = l_flags.divisionByZero || r_flags.divisionByZero;
    }

    function isValidArithmeticFlags(ArithmeticFlags memory flags) internal pure returns (bool) {
        return !flags.overflow && !flags.underflow && !flags.divisionByZero;
    }

    function maxUint(uint8 typeCt) internal pure returns (uint256) {
        uint256[9] memory MAX_UINT = [
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
        return MAX_UINT[typeCt];
    }

    function numBits(uint8 typeCt) internal pure returns (uint256) {
        if (typeCt == 0) return 1;
        if (typeCt == 7) return 160;
        if (typeCt == 8) return 256;
        unchecked {
            if (typeCt < 7) return 1 << (typeCt + 1);
            return 1 << typeCt;
        }
    }

    // ====== Numeric binary ops ======

    function add(UintValue memory _a, UintValue memory _b, uint8 typeCt, bool unChecked)
        internal
        pure
        returns (UintValue memory result)
    {
        uint256 a = _a.value;
        uint256 b = _b.value;
        uint256 value;
        bool overflow = false;
        if (typeCt == Common.euint256_t) {
            unchecked {
                value = a + b;
                overflow = (value < a);
            }
        } else {
            // Clamp
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            require(b <= mx);
            unchecked {
                value = (a + b);
                overflow = (value > mx);
                value = value % (mx + 1);
            }
            require(value <= mx);
        }
        result.value = value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
        if (!unChecked) {
            result.flags.overflow = result.flags.overflow || overflow;
        }
    }

    // typeCt <= Common.euint256_t
    function sub(UintValue memory _a, UintValue memory _b, uint8 typeCt, bool unChecked)
        internal
        pure
        returns (UintValue memory result)
    {
        uint256 a = _a.value;
        uint256 b = _b.value;
        uint256 value;
        bool underflow = (a < b);

        unchecked {
            value = a - b;
        }

        // Clamp
        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            require(b <= mx);
            unchecked {
                value = value % (mx + 1);
            }
            require(value <= mx);
        }
        result.value = value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
        if (!unChecked) {
            result.flags.underflow = result.flags.underflow || underflow;
        }
    }

    // typeCt <= Common.euint256_t
    function mul(UintValue memory _a, UintValue memory _b, uint8 typeCt, bool unChecked)
        internal
        pure
        returns (UintValue memory result)
    {
        uint256 a = _a.value;
        uint256 b = _b.value;
        uint256 value;

        (bool success256,) = Math.tryMul(a, b);

        unchecked {
            value = a * b;
        }

        bool overflow = !success256;

        // Clamp
        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            require(b <= mx);
            overflow = overflow || value > mx;
            unchecked {
                value = value % (mx + 1);
            }
            require(value <= mx);
        }
        result.value = value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
        if (!unChecked) {
            result.flags.overflow = result.flags.overflow || overflow;
        }
    }

    // typeCt <= Common.euint256_t
    function div(UintValue memory _a, UintValue memory _b, uint8 typeCt, bool unChecked)
        internal
        pure
        returns (UintValue memory result)
    {
        uint256 a = _a.value;
        uint256 b = _b.value;
        uint256 value;
        bool divisionByZero = false;
        if (b == 0) {
            divisionByZero = true;
            value = 0;
        } else {
            unchecked {
                value = a / b;
            }

            if (typeCt < Common.euint256_t) {
                uint256 mx = maxUint(typeCt);
                require(a <= mx);
                require(b <= mx);
                require(value <= mx);
            }
        }
        result.value = value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
        if (!unChecked) {
            result.flags.divisionByZero = result.flags.divisionByZero || divisionByZero;
        }
    }

    // typeCt <= Common.euint256_t
    function rem(UintValue memory _a, UintValue memory _b, uint8 typeCt, bool unChecked)
        internal
        pure
        returns (UintValue memory result)
    {
        // Not supported
        require(!unChecked);

        uint256 a = _a.value;
        uint256 b = _b.value;
        uint256 value;
        bool divisionByZero = false;
        if (b == 0) {
            divisionByZero = true;
            value = 0;
        } else {
            unchecked {
                value = a % b;
            }

            if (typeCt < Common.euint256_t) {
                uint256 mx = maxUint(typeCt);
                require(a <= mx);
                require(b <= mx);
                require(value <= mx);
            }
        }
        result.value = value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
        result.flags.divisionByZero = result.flags.divisionByZero || divisionByZero;
    }

    // typeCt <= Common.euint256_t
    function min(UintValue memory _a, UintValue memory _b, uint8 typeCt, bool unChecked)
        internal
        pure
        returns (UintValue memory result)
    {
        // Not supported
        require(!unChecked);

        uint256 mx = maxUint(typeCt);
        uint256 a = _a.value;
        uint256 b = _b.value;

        if (typeCt < Common.euint256_t) {
            require(a <= mx);
            require(b <= mx);
        }

        result.value = (a < b) ? a : b;

        bool aOk = isValidArithmeticFlags(_a.flags) && (a == 0);
        bool bOk = isValidArithmeticFlags(_b.flags) && (b == 0);
        if (!aOk && !bOk) {
            result.flags = orArithmeticFlags(_a.flags, _b.flags);
        } else {
            require(result.value == 0);
        }
    }

    // typeCt <= Common.euint256_t
    function max(UintValue memory _a, UintValue memory _b, uint8 typeCt, bool unChecked)
        internal
        pure
        returns (UintValue memory result)
    {
        // Not supported
        require(!unChecked);

        uint256 mx = maxUint(typeCt);
        uint256 a = _a.value;
        uint256 b = _b.value;

        if (typeCt < Common.euint256_t) {
            require(a <= mx);
            require(b <= mx);
        }

        result.value = (a > b) ? a : b;

        bool aOk = isValidArithmeticFlags(_a.flags) && (a == mx);
        bool bOk = isValidArithmeticFlags(_b.flags) && (b == mx);
        if (!aOk && !bOk) {
            result.flags = orArithmeticFlags(_a.flags, _b.flags);
        } else {
            require(result.value == mx);
        }
    }

    // ====== Bit unary ops ======

    // typeCt <= Common.euint256_t
    function not(UintValue memory _a, uint8 typeCt) internal pure returns (UintValue memory result) {
        uint256 a = _a.value;
        uint256 value;
        if (typeCt == Common.euint256_t) {
            unchecked {
                value = (a ^ type(uint256).max);
            }
        } else {
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            unchecked {
                value = (a ^ type(uint256).max) & mx;
            }
            require(value <= mx);
        }
        result.value = value;
        result.flags = _a.flags;
    }

    // ====== Numeric unary ops ======

    // typeCt <= Common.euint256_t
    function neg(UintValue memory _a, uint8 typeCt) internal pure returns (UintValue memory result) {
        uint256 a = _a.value;
        uint256 value;
        if (typeCt == Common.euint256_t) {
            unchecked {
                value = (a ^ type(uint256).max) + 1;
            }
        } else {
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            unchecked {
                value = (((a ^ type(uint256).max) & mx) + 1) % (mx + 1);
            }
            require(value <= mx);
        }

        result.value = value;
        result.flags = _a.flags;
    }

    // toType <= Common.euint256_t
    function cast(UintValue memory _a, uint8 toType) internal pure returns (UintValue memory result) {
        uint256 a = _a.value;
        uint256 value;
        if (toType == Common.ebool_t) {
            value = uint256((a != 0) ? 1 : 0);
        } else if (toType == Common.euint4_t) {
            if (a > 0xF) {
                value = a % (0xF + 1);
            } else {
                value = a;
            }
        } else if (toType == Common.euint8_t) {
            value = uint256(uint8(a));
        } else if (toType == Common.euint16_t) {
            value = uint256(uint16(a));
        } else if (toType == Common.euint32_t) {
            value = uint256(uint32(a));
        } else if (toType == Common.euint64_t) {
            value = uint256(uint64(a));
        } else if (toType == Common.euint128_t) {
            value = uint256(uint128(a));
        } else if (toType == Common.euint256_t) {
            value = a;
        } else {
            revert("cast to unsupported type");
        }

        result.value = value;
        result.flags = _a.flags;
    }

    // ====== Cmp binary ops ======

    function gt(UintValue memory _a, UintValue memory _b, uint8 typeCt)
        internal
        pure
        returns (BoolValue memory result)
    {
        result.value = _a.value > _b.value;

        bool aOk = isValidArithmeticFlags(_a.flags) && _a.value == 0;
        bool bOk = isValidArithmeticFlags(_b.flags) && _b.value == maxUint(typeCt);
        if (!aOk && !bOk) {
            result.flags = orArithmeticFlags(_a.flags, _b.flags);
        } else {
            require(result.value == false);
        }
    }

    function ge(UintValue memory _a, UintValue memory _b, uint8 typeCt)
        internal
        pure
        returns (BoolValue memory result)
    {
        result.value = _a.value >= _b.value;

        bool aOk = isValidArithmeticFlags(_a.flags) && _a.value == maxUint(typeCt);
        bool bOk = isValidArithmeticFlags(_b.flags) && _b.value == 0;
        if (!aOk && !bOk) {
            result.flags = orArithmeticFlags(_a.flags, _b.flags);
        } else {
            require(result.value == true);
        }
    }

    function lt(UintValue memory _a, UintValue memory _b, uint8 typeCt)
        internal
        pure
        returns (BoolValue memory result)
    {
        result.value = _a.value < _b.value;

        bool aOk = isValidArithmeticFlags(_a.flags) && _a.value == maxUint(typeCt);
        bool bOk = isValidArithmeticFlags(_b.flags) && _b.value == 0;
        if (!aOk && !bOk) {
            result.flags = orArithmeticFlags(_a.flags, _b.flags);
        } else {
            require(result.value == false);
        }
    }

    function le(UintValue memory _a, UintValue memory _b, uint8 typeCt)
        internal
        pure
        returns (BoolValue memory result)
    {
        result.value = _a.value <= _b.value;

        bool aOk = isValidArithmeticFlags(_a.flags) && _a.value == 0;
        bool bOk = isValidArithmeticFlags(_b.flags) && _b.value == maxUint(typeCt);
        if (!aOk && !bOk) {
            result.flags = orArithmeticFlags(_a.flags, _b.flags);
        } else {
            require(result.value == true);
        }
    }

    function eq(UintValue memory _a, UintValue memory _b, uint8 /*typeCt*/ )
        internal
        pure
        returns (BoolValue memory result)
    {
        result.value = _a.value == _b.value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
    }

    function ne(UintValue memory _a, UintValue memory _b, uint8 /*typeCt*/ )
        internal
        pure
        returns (BoolValue memory result)
    {
        result.value = _a.value != _b.value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
    }

    function eqBytes(BytesValue memory _a, BytesValue memory _b, uint8 /*typeCt*/ )
        internal
        pure
        returns (BoolValue memory result)
    {
        result.value = (_a.value.length == _b.value.length && keccak256(_a.value) == keccak256(_b.value));
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
    }

    function neBytes(BytesValue memory _a, BytesValue memory _b, uint8 /*typeCt*/ )
        internal
        pure
        returns (BoolValue memory result)
    {
        result.value = (_a.value.length != _b.value.length || keccak256(_a.value) != keccak256(_b.value));
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
    }

    // ====== Bit binary ops ======

    function and(UintValue memory _a, UintValue memory _b, uint8 /*typeCt*/ )
        internal
        pure
        returns (UintValue memory result)
    {
        result.value = _a.value & _b.value;

        bool aOk = isValidArithmeticFlags(_a.flags) && _a.value == 0;
        bool bOk = isValidArithmeticFlags(_b.flags) && _b.value == 0;
        if (!aOk && !bOk) {
            result.flags = orArithmeticFlags(_a.flags, _b.flags);
        } else {
            require(result.value == 0);
        }
    }

    function or(UintValue memory _a, UintValue memory _b, uint8 typeCt)
        internal
        pure
        returns (UintValue memory result)
    {
        result.value = _a.value | _b.value;

        uint256 mx = maxUint(typeCt);
        bool aOk = isValidArithmeticFlags(_a.flags) && _a.value == mx;
        bool bOk = isValidArithmeticFlags(_b.flags) && _b.value == mx;
        if (!aOk && !bOk) {
            result.flags = orArithmeticFlags(_a.flags, _b.flags);
        } else {
            require(result.value == mx);
        }
    }

    function xor(UintValue memory _a, UintValue memory _b, uint8 typeCt)
        internal
        pure
        returns (UintValue memory result)
    {
        uint256 value;
        uint256 a = _a.value;
        uint256 b = _b.value;

        unchecked {
            value = a ^ b;
        }

        // Clamp
        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            require(a <= mx, "MathLib.xor lhs operand overflow");
            require(b <= mx, "MathLib.xor rhs operand overflow");
            unchecked {
                value = value % (mx + 1);
            }
            require(value <= mx, "MathLib.xor operator overflow");
        }
        result.value = value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
    }

    /// Note: b is interpreted as a uint8
    function shl(UintValue memory _a, UintValue memory _b, uint8 typeCt)
        internal
        pure
        returns (UintValue memory result)
    {
        uint256 value;
        uint256 a = _a.value;
        // 0 <= b <= 255
        uint256 b = uint256(uint8(_b.value));

        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            uint256 nb = numBits(typeCt);
            require(a <= mx, "MathLib.shl left operand overflow");
            unchecked {
                value = (a << (b % nb)) % (mx + 1);
            }
            require(value <= mx, "MathLib.shl operator overflow");
        } else {
            unchecked {
                value = (a << (b % 256));
            }
        }
        result.value = value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
    }

    /// Note: b is interpreted as a uint8
    function shr(UintValue memory _a, UintValue memory _b, uint8 typeCt)
        internal
        pure
        returns (UintValue memory result)
    {
        uint256 value;
        uint256 a = _a.value;
        // 0 <= b <= 255
        uint256 b = uint256(uint8(_b.value));

        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            uint256 nb = numBits(typeCt);
            require(a <= mx, "MathLib.shr left operand overflow");
            unchecked {
                value = (a >> (b % nb)) % (mx + 1);
            }
            require(value <= mx, "MathLib.shr operator overflow");
        } else {
            unchecked {
                value = (a >> (b % 256));
            }
        }
        result.value = value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
    }

    /// Note: b is interpreted as a uint8
    function rotl(UintValue memory _a, UintValue memory _b, uint8 typeCt)
        internal
        pure
        returns (UintValue memory result)
    {
        uint256 value;
        uint256 a = _a.value;
        // 0 <= b <= 255
        uint256 b = uint256(uint8(_b.value));

        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            uint256 nb = numBits(typeCt);
            require(a <= mx, "MathLib.rotl left operand overflow");
            unchecked {
                b = (b % nb);
                value = ((a << b) | (a >> (nb - b))) % (mx + 1);
            }
            require(value <= mx, "MathLib.rotl operator overflow");
        } else {
            unchecked {
                b = (b % 256);
                value = (a << b) | (a >> (256 - b));
            }
        }
        result.value = value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
    }

    /// Note: b is interpreted as a uint8
    function rotr(UintValue memory _a, UintValue memory _b, uint8 typeCt)
        internal
        pure
        returns (UintValue memory result)
    {
        uint256 value;
        uint256 a = _a.value;
        // 0 <= b <= 255
        uint256 b = uint256(uint8(_b.value));

        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            uint256 nb = numBits(typeCt);
            require(a <= mx, "MathLib.rotr left operand overflow");
            unchecked {
                b = (b % nb);
                value = ((a >> b) | (a << (nb - b))) % (mx + 1);
            }
            require(value <= mx, "MathLib.rotr operator overflow");
        } else {
            unchecked {
                b = (b % 256);
                value = (a >> b) | (a << (256 - b));
            }
        }
        result.value = value;
        result.flags = orArithmeticFlags(_a.flags, _b.flags);
    }
}
