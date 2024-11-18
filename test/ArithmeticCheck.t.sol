// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";

import {TFHE, euint8, euint64, einput, ebool, ebytes256} from "../src/debug/fhevm/lib/TFHE.sol";
import {FhevmDebugger, ArithmeticCheckingMode} from "../src/debug/FhevmDebugger.sol";

import {EncryptedInput} from "../src/forge/EncryptedInput.sol";
import {ForgeFhevm} from "../src/forge/ForgeFhevm.sol";

contract ArithmeticCheckTest is Test {
    function setUp() public {
        ForgeFhevm.setUp();
    }

    function testFail_startCheck_OperandsAndResult_Add_overflow() public {
        FhevmDebugger.startCheckArithmetic(ArithmeticCheckingMode.OperandsAndResult);
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        TFHE.add(ei1, ei2);
        FhevmDebugger.stopCheckArithmetic();
    }

    function testFail_check_OperandsAndResult_Add_overflow() public {
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        FhevmDebugger.checkArithmetic(ArithmeticCheckingMode.OperandsAndResult);
        TFHE.add(ei1, ei2);
    }

    function testFail_check_Operands_Add_overflow() public {
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        euint8 ei3 = TFHE.add(ei1, ei2);

        FhevmDebugger.checkArithmetic(ArithmeticCheckingMode.OperandsOnly);
        TFHE.add(ei1, ei3);
    }

    function test_add_overflow_ge_valid() public {
        // 128 + 129 is overflow
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);

        euint8 ei3 = TFHE.add(ei1, ei2);
        vm.assertFalse(FhevmDebugger.isArithmeticallyValid(ei3));

        // <garbage> >= 0 is always true
        ebool validTrue = TFHE.ge(ei3, TFHE.asEuint8(0));
        vm.assertTrue(FhevmDebugger.isArithmeticallyValid(validTrue));

        euint8 ei4 = TFHE.add(ei3, TFHE.asEuint8(0));
        vm.assertFalse(FhevmDebugger.isArithmeticallyValid(ei4));

        FhevmDebugger.checkArithmetic(ArithmeticCheckingMode.ResultOnly);
        validTrue = TFHE.ge(ei4, TFHE.asEuint8(0));
    }

    function testFail_check_ResultOnly_Add_overflow_Ge() public {
        // 128 + 129 is overflow
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);

        euint8 ei3 = TFHE.add(ei1, ei2);
        vm.assertFalse(FhevmDebugger.isArithmeticallyValid(ei3));

        FhevmDebugger.checkArithmetic(ArithmeticCheckingMode.ResultOnly);
        TFHE.ge(ei3, TFHE.asEuint8(1));
    }

    function testFail_check_ResultOnly_Add_overflow() public {
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);

        FhevmDebugger.checkArithmetic(ArithmeticCheckingMode.ResultOnly);
        TFHE.add(ei1, ei2);
    }
}
