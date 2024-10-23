// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";
import {TFHE, euint4, euint8, euint64, einput, ebool, ebytes256} from "fhevm/lib/TFHE.sol";
import {TFHEvm} from "../src/TFHEvm.sol";
import {EncryptedInput} from "../src/encrypted-input/EncryptedInput.sol";

contract EUint8Test is Test {
    function setUp() public {
        TFHEvm.setUp();
    }

    function test_AsEUint8() public {
        TFHE.asEuint8(128);
    }

    function testFail_AsEUint8_overflow() public {
        TFHE.asEuint8(65000);
    }

    function test_Add() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.add(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128 + 2);
    }

    function test_revert_Add_no_user_permission() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.add(ei1, ei2);

        vm.expectRevert("user does not have permission to decrypt handle");
        TFHEvm.decryptU8(ei3, contractAddress, userAddress);
    }

    function test_Add_overflow() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        euint8 ei3 = TFHE.add(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, uint8(uint16(128 + 129)));
    }

    function testFail_revert_Add_overflow() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        euint8 ei3 = TFHE.add(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        // Note in strict mode, cannot use vm.expectRevert().
        // forge does not detect it
        // use testFail_xxx instead
        TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
    }

    function test_Not() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(1);
        euint8 ei2 = TFHE.not(ei1);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = TFHEvm.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, uint8(0xfe));
    }

    function test_Neg_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(1);
        euint8 ei2 = TFHE.neg(ei1);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = TFHEvm.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 255);
    }

    function test_Neg_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(186);
        euint8 ei2 = TFHE.neg(ei1);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = TFHEvm.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 70);
    }

    function test_Sub() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.sub(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128 - 2);
    }

    function test_Sub_underflow() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.sub(ei2, ei1);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, uint8(int8(2 - 128)));
    }

    function testFail_revert_Sub_underflow() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.sub(ei2, ei1);
        TFHE.allow(ei3, userAddress);

        // Note in strict mode, cannot use vm.expectRevert().
        // forge does not detect it
        // use testFail_xxx instead
        TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
    }

    function test_revert_Sub_no_user_permission() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.sub(ei1, ei2);

        vm.expectRevert("user does not have permission to decrypt handle");
        TFHEvm.decryptU8(ei3, contractAddress, userAddress);
    }

    function test_Min() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.min(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 2);
    }

    function test_Max() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.max(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128);
    }

    function test_IsTrivial() public {
        address userAddress = msg.sender;

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.max(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        vm.assertEq(TFHEvm.isTrivial(ei3), true);
    }

    function test_Cast_u64_to_u8() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint64 ei1 = TFHE.asEuint64(128);
        euint8 ei2 = TFHE.asEuint8(ei1);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = TFHEvm.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 128);
    }

    function test_Cast_u64_to_u8_clamp() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint64 ei1 = TFHE.asEuint64(9128);
        euint8 ei2 = TFHE.asEuint8(ei1);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = TFHEvm.decryptU8Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, uint8(uint16(9128)));
    }

    function test_Cast_u8_to_u64() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint64 ei2 = TFHE.asEuint64(ei1);
        TFHE.allow(ei2, userAddress);

        uint64 i2 = TFHEvm.decryptU64Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 128);
    }

    function test_Cast_u8_to_u4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(0xa);
        euint4 ei2 = TFHE.asEuint4(ei1);
        TFHE.allow(ei2, userAddress);

        uint64 i2 = TFHEvm.decryptU4Strict(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 0xa);
    }

    /// rotl(52, 1) == 104
    function test_Rotl_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(52);
        euint8 ei2 = TFHE.asEuint8(1);
        euint8 ei3 = TFHE.rotl(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 104);
    }

    /// rotl(4, 8) == 4
    function test_Rotl_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(4);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.rotl(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 4);
    }

    /// rotl(8, 8) == 8
    function test_Rotl_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.rotl(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 8);
    }

    /// rotl(8, 4) == 128
    function test_Rotl_u8_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.rotl(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128);
    }

    /// rotr(50, 4) == 35
    function test_Rotr_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(50);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.rotr(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 35);
    }

    /// rotr(4, 8) == 4
    function test_Rotr_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(4);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.rotr(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 4);
    }

    /// rotr(8, 8) == 8
    function test_Rotr_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.rotr(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 8);
    }

    /// rotr(8, 4) == 128
    function test_Rotr_u8_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.rotr(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128);
    }

    /// shl(201, 7) == 128
    function test_Shl_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(201);
        euint8 ei2 = TFHE.asEuint8(7);
        euint8 ei3 = TFHE.shl(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128);
    }

    /// shl(4, 8) == 4
    function test_Shl_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(4);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.shl(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 4);
    }

    /// shl(8, 8) == 8
    function test_Shl_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.shl(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 8);
    }

    /// shl(8, 4) == 128
    function test_Shl_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.shl(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128);
    }

    /// shr(15, 4) == 0
    function test_Shr_1() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(15);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.shr(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 0);
    }

    /// shr(4, 8) == 4
    function test_Shr_2() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(4);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.shr(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 4);
    }

    /// shr(8, 8) == 8
    function test_Shr_3() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(8);
        euint8 ei3 = TFHE.shr(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 8);
    }

    /// shr(8, 4) == 0
    function test_Shr_4() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(8);
        euint8 ei2 = TFHE.asEuint8(4);
        euint8 ei3 = TFHE.shr(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8Strict(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 0);
    }
}

