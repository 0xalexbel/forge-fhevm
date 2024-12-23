// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";

import {TFHE, euint4, euint8, euint64, einput, ebool, ebytes256} from "../src/libs/fhevm-debug/lib/TFHE.sol";

import {FhevmDebug} from "../src/FhevmDebug.sol";
import {FFhevm} from "../src/FFhevm.sol";

contract EUint8Test is Test {
    function setUp() public {
        FFhevm.setUp();
    }

    function test_AsEUint8() public {
        TFHE.asEuint8(128);
    }

    function testFail_AsEUint8_overflow() public {
        TFHE.asEuint8(65000);
    }

    // ===== Add =====

    function test_Add() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.add(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128 + 2);
    }

    function testFuzz_Add(uint8 v1, uint8 v2) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        euint8 ei3 = TFHE.add(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8(ei3, contractAddress, userAddress);

        uint8 v;
        unchecked {
            v = v1 + v2;
        }

        vm.assertEq(i3, v);
    }

    function testFail_revert_Add_no_user_permission() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.add(ei1, ei2);

        TFHE.allow(ei3, contractAddress);

        // serAddress does not have permission to decrypt handle
        // Note cannot use vm.expectRevert().
        // forge does not detect it
        // use testFail_xxx instead
        FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
    }

    function testFail_revert_Add_no_contract_permission() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.add(ei1, ei2);

        TFHE.allow(ei3, userAddress);

        // contractAddress does not have permission to decrypt handle
        // Note cannot use vm.expectRevert().
        // forge does not detect it
        // use testFail_xxx instead
        FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
    }

    function test_Add_overflow() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        euint8 ei3 = TFHE.add(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, uint8(uint16(128 + 129)));
    }

    function testFail_revert_Add_overflow() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        euint8 ei3 = TFHE.add(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        // Note cannot use vm.expectRevert().
        // forge does not detect it
        // use testFail_xxx instead
        FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
    }

    // ===== Sub =====

    function test_Sub() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.sub(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128 - 2);
    }

    function testFuzz_Sub(uint8 v1, uint8 v2) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        euint8 ei3 = TFHE.sub(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
        uint8 v;
        unchecked {
            v = v1 - v2;
        }
        vm.assertEq(i3, v);
    }

    function test_Sub_underflow() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.sub(ei2, ei1);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, uint8(int8(2 - 128)));
    }

    function testFail_revert_Sub_underflow() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.sub(ei2, ei1);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        // Note in strict mode, cannot use vm.expectRevert().
        // forge does not detect it
        // use testFail_xxx instead
        FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
    }

    function testFail_revert_Sub_no_user_permission() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.sub(ei1, ei2);

        TFHE.allow(ei3, contractAddress);

        // userAddress does not have permission to decrypt handle
        // Note cannot use vm.expectRevert().
        // forge does not detect it
        // use testFail_xxx instead
        FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
    }

    function testFail_revert_Sub_no_contract_permission() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.sub(ei1, ei2);

        TFHE.allow(ei3, userAddress);

        // contractAddress does not have permission to decrypt handle
        // Note cannot use vm.expectRevert().
        // forge does not detect it
        // use testFail_xxx instead
        FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
    }

    // ===== Mul =====

    function test_Mul_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(12);
        euint8 ei3 = TFHE.mul(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 8 * 12);
    }

    function test_Mul_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(12);
        euint8 ei2 = TFHE.asEuint8(14);
        euint8 ei3 = TFHE.mul(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 168);
    }

    function test_Mul_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(14);
        euint8 ei2 = TFHE.asEuint8(14);
        euint8 ei3 = TFHE.mul(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 196);
    }

    function testFuzz_Mul(uint8 v1, uint8 v2) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        euint8 ei3 = TFHE.mul(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(uint256(i3), (uint256(v1) * uint256(v2)) % (uint256(0xff) + 1));
    }

    // ===== Div =====

    function test_Div_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(87);
        euint8 ei2 = TFHE.div(ei1, 167);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 0);
    }

    function test_Div_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(31);
        euint8 ei2 = TFHE.div(ei1, 35);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 0);
    }

    function test_Div_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(35);
        euint8 ei2 = TFHE.div(ei1, 35);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 1);
    }

    function test_Div_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(35);
        euint8 ei2 = TFHE.div(ei1, 31);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 1);
    }

    function testFuzz_Div(uint8 v1, uint8 v2) public {
        vm.assume(v2 != 0);

        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.div(ei1, v2);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, v1 / v2);
    }

    // ===== Rem =====

    function test_Rem_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(85);
        euint8 ei2 = TFHE.rem(ei1, 232);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 85);
    }

    function test_Rem_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(38);
        euint8 ei2 = TFHE.rem(ei1, 42);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 38);
    }

    function test_Rem_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(42);
        euint8 ei2 = TFHE.rem(ei1, 42);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 0);
    }

    function test_Rem_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(42);
        euint8 ei2 = TFHE.rem(ei1, 38);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 4);
    }

    function testFuzz_Rem(uint8 v1, uint8 v2) public {
        vm.assume(v2 != 0);

        address userAddress = msg.sender;
        address contractAddress = address(this);

        uint8 q = v1 / v2;
        uint8 r = v1 - v2 * q;

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.rem(ei1, v2);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, r);
    }

    // ===== Not =====

    function test_Not() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(1);
        euint8 ei2 = TFHE.not(ei1);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, uint8(0xfe));
    }

    function testFuzz_Not(uint8 v) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v);
        euint8 ei2 = TFHE.not(ei1);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, ~(v));
    }

    // ===== Neg =====

    function test_Neg_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(1);
        euint8 ei2 = TFHE.neg(ei1);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 255);
    }

    function test_Neg_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(186);
        euint8 ei2 = TFHE.neg(ei1);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 70);
    }

    // ===== Eq =====

    function test_Eq_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(128);
        ebool eb = TFHE.eq(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, true);
    }

    function test_Eq_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(27);
        ebool eb = TFHE.eq(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, false);
    }

    // ===== Ne =====

    function test_Ne_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(128);
        ebool eb = TFHE.ne(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, false);
    }

    function test_Ne_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(27);
        ebool eb = TFHE.ne(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, true);
    }

    // ===== Gt =====

    function test_Gt_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(54);
        ebool eb = TFHE.gt(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, true);
    }

    function test_Gt_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(128);
        ebool eb = TFHE.gt(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, false);
    }

    function test_Gt_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(200);
        ebool eb = TFHE.gt(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, false);
    }

    function testFuzz_Gt(uint8 v1, uint8 v2) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        ebool eb = TFHE.gt(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, v1 > v2);
    }

    // ===== Lt =====

    function test_Lt_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(54);
        ebool eb = TFHE.lt(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, false);
    }

    function test_Lt_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(128);
        ebool eb = TFHE.lt(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, false);
    }

    function test_Lt_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(200);
        ebool eb = TFHE.lt(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, true);
    }

    function testFuzz_Lt(uint8 v1, uint8 v2) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        ebool eb = TFHE.lt(ei1, ei2);

        TFHE.allow(eb, contractAddress);
        TFHE.allow(eb, userAddress);

        bool b = FhevmDebug.decryptBoolStrict(eb, contractAddress, userAddress);
        vm.assertEq(b, v1 < v2);
    }

    // ===== Min =====

    function test_Min() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.min(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 2);
    }

    function testFuzz_Min(uint8 v1, uint8 v2) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        euint8 ei3 = TFHE.min(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);

        uint8 min = (v1 < v2) ? v1 : v2;
        vm.assertEq(i3, min);
    }

    // ===== Max =====

    function test_Max() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.max(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128);
    }

    function testFuzz_Max(uint8 v1, uint8 v2) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        euint8 ei3 = TFHE.max(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);

        uint8 mx = (v1 > v2) ? v1 : v2;
        vm.assertEq(i3, mx);
    }

    // ===== IsTrivial =====

    function test_IsTrivial() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.max(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        vm.assertEq(FhevmDebug.isTrivial(ei3), true);
    }

    // ===== Cast =====

    function test_Cast_u64_to_u8() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint64 ei1 = TFHE.asEuint64(128);
        euint8 ei2 = TFHE.asEuint8(ei1);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 128);
    }

    function test_Cast_u64_to_u8_clamp() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint64 ei1 = TFHE.asEuint64(9128);
        euint8 ei2 = TFHE.asEuint8(ei1);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);
        /// FhevmDebug.
        /// fhevmDebug.
        uint8 i2 = FhevmDebug.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, uint8(uint16(9128)));
    }

    function test_Cast_u8_to_u64() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint64 ei2 = TFHE.asEuint64(ei1);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint64 i2 = FhevmDebug.decryptU64Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 128);
    }

    function test_Cast_u8_to_u4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(0xa);
        euint4 ei2 = TFHE.asEuint4(ei1);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU4Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 0xa);
    }

    function testFuzz_Cast_u8_to_u4(uint8 value) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(value);
        euint4 ei2 = TFHE.asEuint4(ei1);

        TFHE.allow(ei2, contractAddress);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = FhevmDebug.decryptU4Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, value % (uint8(0xf) + 1));
    }

    // ===== Rotl =====

    /// rotl(52, 1) == 104
    function test_Rotl_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(52);
        euint8 ei2 = TFHE.asEuint8(1);
        euint8 ei3 = TFHE.rotl(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 104);
    }

    /// rotl(4, 8) == 4
    function test_Rotl_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(4);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.rotl(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 4);
    }

    /// rotl(8, 8) == 8
    function test_Rotl_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.rotl(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 8);
    }

    /// rotl(8, 4) == 128
    function test_Rotl_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.rotl(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128);
    }

    // ===== Rotr =====

    /// rotr(50, 4) == 35
    function test_Rotr_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(50);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.rotr(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 35);
    }

    /// rotr(4, 8) == 4
    function test_Rotr_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(4);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.rotr(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 4);
    }

    /// rotr(8, 8) == 8
    function test_Rotr_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.rotr(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 8);
    }

    /// rotr(8, 4) == 128
    function test_Rotr_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.rotr(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128);
    }

    // ===== Shl =====

    /// shl(201, 7) == 128
    function test_Shl_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(201);
        euint8 ei2 = TFHE.asEuint8(7);
        euint8 ei3 = TFHE.shl(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128);
    }

    /// shl(4, 8) == 4
    function test_Shl_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(4);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.shl(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 4);
    }

    /// shl(8, 8) == 8
    function test_Shl_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.shl(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 8);
    }

    /// shl(8, 4) == 128
    function test_Shl_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.shl(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128);
    }

    // ===== Shr =====

    /// shr(15, 4) == 0
    function test_Shr_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(15);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.shr(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 0);
    }

    /// shr(4, 8) == 4
    function test_Shr_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(4);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.shr(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 4);
    }

    /// shr(8, 8) == 8
    function test_Shr_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.shr(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 8);
    }

    /// shr(8, 4) == 0
    function test_Shr_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.shr(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 0);
    }

    // ===== And =====

    /// and(183, 70) == 6
    function test_And_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(183);
        euint8 ei2 = TFHE.asEuint8(70);
        euint8 ei3 = TFHE.and(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 6);
    }

    /// and(131, 135) == 131
    function test_And_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(131);
        euint8 ei2 = TFHE.asEuint8(135);
        euint8 ei3 = TFHE.and(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 131);
    }

    /// and(135, 135) == 135
    function test_And_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(135);
        euint8 ei2 = TFHE.asEuint8(135);
        euint8 ei3 = TFHE.and(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 135);
    }

    /// and(146, 70) == 2
    function test_And_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(146);
        euint8 ei2 = TFHE.asEuint8(70);
        euint8 ei3 = TFHE.and(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 2);
    }

    function testFuzz_And(uint8 v1, uint8 v2) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        euint8 ei3 = TFHE.and(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, uint8(v1 & v2));
    }

    // ===== Or =====

    /// or(189, 140) == 189
    function test_Or_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(189);
        euint8 ei2 = TFHE.asEuint8(140);
        euint8 ei3 = TFHE.or(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 189);
    }

    /// or(139, 140) == 143
    function test_Or_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(139);
        euint8 ei2 = TFHE.asEuint8(140);
        euint8 ei3 = TFHE.or(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 143);
    }

    function testFuzz_Or(uint8 v1, uint8 v2) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        euint8 ei3 = TFHE.or(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, uint8(v1 | v2));
    }

    // ===== Xor =====

    /// xor(146, 150) == 4
    function test_Xor_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(146);
        euint8 ei2 = TFHE.asEuint8(150);
        euint8 ei3 = TFHE.xor(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 4);
    }

    /// xor(62, 62) == 0
    function test_Xor_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(62);
        euint8 ei2 = TFHE.asEuint8(62);
        euint8 ei3 = TFHE.xor(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 0);
    }

    function testFuzz_Xor(uint8 v1, uint8 v2) public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        euint8 ei3 = TFHE.xor(ei1, ei2);

        TFHE.allow(ei3, contractAddress);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = FhevmDebug.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, uint8(v1 ^ v2));
    }
}
