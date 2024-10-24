// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {Common} from "../../lib/TFHE.sol";
import {BytesLib} from "../utils/BytesLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library MathLib {
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

    function add(uint256 a, uint256 b, uint8 typeCt)
        internal
        pure
        returns (ArithmeticFlags memory flags, uint256 result)
    {
        if (typeCt == Common.euint256_t) {
            unchecked {
                result = a + b;
                flags.overflow = (result < a);
            }
        } else {
            // Clamp
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            require(b <= mx);
            unchecked {
                result = (a + b);
                flags.overflow = (result > mx);
                result = result % (mx + 1);
            }
            require(result <= mx);
        }
    }

    // typeCt <= Common.euint256_t
    function sub(uint256 a, uint256 b, uint8 typeCt)
        internal
        pure
        returns (ArithmeticFlags memory flags, uint256 result)
    {
        flags.underflow = (a < b);
        unchecked {
            result = a - b;
        }

        // Clamp
        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            require(b <= mx);
            unchecked {
                result = result % (mx + 1);
            }
            require(result <= mx);
        }
    }

    // typeCt <= Common.euint256_t
    function mul(uint256 a, uint256 b, uint8 typeCt)
        internal
        pure
        returns (ArithmeticFlags memory flags, uint256 result)
    {
        (bool success256,) = Math.tryMul(a, b);

        unchecked {
            result = a * b;
        }

        flags.overflow = !success256;

        // Clamp
        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            require(b <= mx);
            flags.overflow = flags.overflow || result > mx;
            unchecked {
                result = result % (mx + 1);
            }
            require(result <= mx);
        }
    }

    // typeCt <= Common.euint256_t
    function div(uint256 a, uint256 b, uint8 typeCt)
        internal
        pure
        returns (ArithmeticFlags memory flags, uint256 result)
    {
        if (b == 0) {
            flags.divisionByZero = true;
            result = 0;
        } else {
            unchecked {
                result = a / b;
            }

            if (typeCt < Common.euint256_t) {
                uint256 mx = maxUint(typeCt);
                require(a <= mx);
                require(b <= mx);
                require(result <= mx);
            }
        }
    }

    // typeCt <= Common.euint256_t
    function rem(uint256 a, uint256 b, uint8 typeCt)
        internal
        pure
        returns (ArithmeticFlags memory flags, uint256 result)
    {
        if (b == 0) {
            flags.divisionByZero = true;
            result = 0;
        } else {
            unchecked {
                result = a % b;
            }

            if (typeCt < Common.euint256_t) {
                uint256 mx = maxUint(typeCt);
                require(a <= mx);
                require(b <= mx);
                require(result <= mx);
            }
        }
    }

    // typeCt <= Common.euint256_t
    function min(uint256 a, uint256 b, uint8 typeCt) internal pure returns (ArithmeticFlags memory, uint256) {
        uint256 result;
        ArithmeticFlags memory flags;

        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            require(b <= mx);
        }
        result = (a < b) ? a : b;

        return (flags, result);
    }

    // typeCt <= Common.euint256_t
    function max(uint256 a, uint256 b, uint8 typeCt) internal pure returns (ArithmeticFlags memory, uint256) {
        uint256 result;
        ArithmeticFlags memory flags;

        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            require(b <= mx);
        }
        result = (a > b) ? a : b;

        return (flags, result);
    }

    // ====== Bit unary ops ======

    // typeCt <= Common.euint256_t
    function not(uint256 a, uint8 typeCt) internal pure returns (uint256 result) {
        if (typeCt == Common.euint256_t) {
            unchecked {
                result = (a ^ type(uint256).max);
            }
        } else {
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            unchecked {
                result = (a ^ type(uint256).max) & mx;
            }
            require(result <= mx);
        }
    }

    // ====== Numeric unary ops ======

    // typeCt <= Common.euint256_t
    function neg(uint256 a, uint8 typeCt) internal pure returns (ArithmeticFlags memory, uint256) {
        uint256 result;
        ArithmeticFlags memory flags;

        if (typeCt == Common.euint256_t) {
            unchecked {
                result = (a ^ type(uint256).max) + 1;
            }
        } else {
            uint256 mx = maxUint(typeCt);
            require(a <= mx);
            unchecked {
                result = (((a ^ type(uint256).max) & mx) + 1) % (mx + 1);
            }
            require(result <= mx);
        }

        return (flags, result);
    }

    // toType <= Common.euint256_t
    function cast(uint256 a, uint8 toType) internal pure returns (ArithmeticFlags memory, uint256) {
        uint256 result;
        ArithmeticFlags memory flags;

        if (toType == Common.ebool_t) {
            result = uint256((a != 0) ? 1 : 0);
        } else if (toType == Common.euint4_t) {
            if (a > 0xF) {
                result = a % (0xF + 1);
            } else {
                result = a;
            }
        } else if (toType == Common.euint8_t) {
            result = uint256(uint8(a));
        } else if (toType == Common.euint16_t) {
            result = uint256(uint16(a));
        } else if (toType == Common.euint32_t) {
            result = uint256(uint32(a));
        } else if (toType == Common.euint64_t) {
            result = uint256(uint64(a));
        } else if (toType == Common.euint128_t) {
            result = uint256(uint128(a));
        } else if (toType == Common.euint256_t) {
            result = a;
        } else {
            revert("cast to unsupported type");
        }

        return (flags, result);
    }

    // ====== Cmp binary ops ======

    function gt(uint256 a, uint256 b, uint8 /*typeCt*/ ) internal pure returns (bool) {
        return a > b;
    }

    function ge(uint256 a, uint256 b, uint8 /*typeCt*/ ) internal pure returns (bool) {
        return a >= b;
    }

    function lt(uint256 a, uint256 b, uint8 /*typeCt*/ ) internal pure returns (bool) {
        return a < b;
    }

    function le(uint256 a, uint256 b, uint8 /*typeCt*/ ) internal pure returns (bool) {
        return a <= b;
    }

    function eq(uint256 a, uint256 b, uint8 /*typeCt*/ ) internal pure returns (bool) {
        return a == b;
    }

    function ne(uint256 a, uint256 b, uint8 /*typeCt*/ ) internal pure returns (bool) {
        return a != b;
    }

    function eqBytes(bytes memory a, bytes memory b, uint8 /*typeCt*/ ) internal pure returns (bool) {
        return a.length == b.length && keccak256(a) == keccak256(b);
    }

    function neBytes(bytes memory a, bytes memory b, uint8 /*typeCt*/ ) internal pure returns (bool) {
        return a.length != b.length || keccak256(a) != keccak256(b);
    }

    // ====== Bit binary ops ======

    function and(uint256 a, uint256 b, uint8 /*typeCt*/ ) internal pure returns (uint256) {
        return a & b;
    }

    function or(uint256 a, uint256 b, uint8 /*typeCt*/ ) internal pure returns (uint256) {
        return a | b;
    }

    function xor(uint256 a, uint256 b, uint8 typeCt) internal pure returns (uint256 result) {
        unchecked {
            result = a ^ b;
        }

        // Clamp
        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            require(a <= mx, "MathLib.xor lhs operand overflow");
            require(b <= mx, "MathLib.xor rhs operand overflow");
            unchecked {
                result = result % (mx + 1);
            }
            require(result <= mx, "MathLib.xor operator overflow");
        }
    }

    /// Note: b is interpreted as a uint8
    function shl(uint256 a, uint256 b, uint8 typeCt) internal pure returns (uint256 result) {
        // 0 <= b <= 255
        b = uint256(uint8(b));

        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            uint256 nb = numBits(typeCt);
            require(a <= mx, "MathLib.shl left operand overflow");
            unchecked {
                result = (a << (b % nb)) % (mx + 1);
            }
            require(result <= mx, "MathLib.shl operator overflow");
        } else {
            unchecked {
                result = (a << (b % 256));
            }
        }
    }

    /// Note: b is interpreted as a uint8
    function shr(uint256 a, uint256 b, uint8 typeCt) internal pure returns (uint256 result) {
        // 0 <= b <= 255
        b = uint256(uint8(b));

        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            uint256 nb = numBits(typeCt);
            require(a <= mx, "MathLib.shr left operand overflow");
            unchecked {
                result = (a >> (b % nb)) % (mx + 1);
            }
            require(result <= mx, "MathLib.shr operator overflow");
        } else {
            unchecked {
                result = (a >> (b % 256));
            }
        }
    }

    /// Note: b is interpreted as a uint8
    function rotl(uint256 a, uint256 b, uint8 typeCt) internal pure returns (uint256 result) {
        // 0 <= b <= 255
        b = uint256(uint8(b));

        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            uint256 nb = numBits(typeCt);
            require(a <= mx, "MathLib.rotl left operand overflow");
            unchecked {
                b = (b % nb);
                result = ((a << b) | (a >> (nb - b))) % (mx + 1);
            }
            require(result <= mx, "MathLib.rotl operator overflow");
        } else {
            unchecked {
                b = (b % 256);
                result = (a << b) | (a >> (256 - b));
            }
        }
    }

    /// Note: b is interpreted as a uint8
    function rotr(uint256 a, uint256 b, uint8 typeCt) internal pure returns (uint256 result) {
        // 0 <= b <= 255
        b = uint256(uint8(b));

        if (typeCt < Common.euint256_t) {
            uint256 mx = maxUint(typeCt);
            uint256 nb = numBits(typeCt);
            require(a <= mx, "MathLib.rotr left operand overflow");
            unchecked {
                b = (b % nb);
                result = ((a >> b) | (a << (nb - b))) % (mx + 1);
            }
            require(result <= mx, "MathLib.rotr operator overflow");
        } else {
            unchecked {
                b = (b % 256);
                result = (a >> b) | (a << (256 - b));
            }
        }
    }
}
