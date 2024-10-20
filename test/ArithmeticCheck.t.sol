// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/Console.sol";
import {TFHE, euint8, euint64, einput, ebool, ebytes256} from "fhevm/lib/TFHE.sol";
import {FhevmTest} from "../src/FhevmTest.sol";
import {fhevm, ArithmeticCheckingMode} from "../src/fhevm.sol";
import {EncryptedInput} from "../src/encrypted-input/EncryptedInput.sol";

contract ArithmeticCheckTest is FhevmTest {
    function testFail_startCheck_OperandsAndResult_Add_overflow() public {
        fhevm.startCheckArithmetic(ArithmeticCheckingMode.OperandsAndResult);
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        TFHE.add(ei1, ei2);
        fhevm.stopCheckArithmetic();
    }

    function testFail_check_OperandsAndResult_Add_overflow() public {
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        fhevm.checkArithmetic(ArithmeticCheckingMode.OperandsAndResult);
        TFHE.add(ei1, ei2);
    }

    function testFail_check_Operands_Add_overflow() public {
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        euint8 ei3 = TFHE.add(ei1, ei2);

        fhevm.checkArithmetic(ArithmeticCheckingMode.Operands);
        TFHE.add(ei1, ei3);
    }
}
