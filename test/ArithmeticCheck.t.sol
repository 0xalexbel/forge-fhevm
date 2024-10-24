// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";
import {TFHEvm, ArithmeticCheckingMode} from "../src/TFHEvm.sol";
import {EncryptedInput} from "../src/encrypted-input/EncryptedInput.sol";

import {TFHE, euint8, euint64, einput, ebool, ebytes256} from "../lib/TFHE.sol";

contract ArithmeticCheckTest is Test {
    function setUp() public {
        TFHEvm.setUp();
    }

    function testFail_startCheck_OperandsAndResult_Add_overflow() public {
        TFHEvm.startCheckArithmetic(ArithmeticCheckingMode.OperandsAndResult);
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        TFHE.add(ei1, ei2);
        TFHEvm.stopCheckArithmetic();
    }

    function testFail_check_OperandsAndResult_Add_overflow() public {
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        TFHEvm.checkArithmetic(ArithmeticCheckingMode.OperandsAndResult);
        TFHE.add(ei1, ei2);
    }

    function testFail_check_Operands_Add_overflow() public {
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        euint8 ei3 = TFHE.add(ei1, ei2);

        TFHEvm.checkArithmetic(ArithmeticCheckingMode.Operands);
        TFHE.add(ei1, ei3);
    }
}
