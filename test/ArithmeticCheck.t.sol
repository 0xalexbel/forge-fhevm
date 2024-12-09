// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";

import {TFHE, euint8, euint64, einput, ebool, ebytes256} from "../src/libs/fhevm-debug/lib/TFHE.sol";
import {TFHEzk} from "../src/libs/fhevm-debug/utils/TFHEzk.sol";
import {TFHEHandle} from "../src/libs/common/TFHEHandle.sol";
import {MathLib} from "../src/libs/debugger/impl/lib/MathLib.sol";

import {FhevmDebug} from "../src/FhevmDebug.sol";
import {FFhevm, EncryptedInput} from "../src/FFhevm.sol";

contract ArithmeticCheckTest is Test {
    function setUp() public {
        FFhevm.setUp();
    }

    function test_startCheck_OperandsAndResult_Add_overflow() public {
        FhevmDebug.startArithmeticCheck(FhevmDebug.ArithmeticCheckMode.OperandsAndResult);
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);

        uint256 expectedErrorHandle = TFHEzk.add(euint8.unwrap(ei1), euint8.unwrap(ei2));
        vm.expectRevert(abi.encodeWithSelector(MathLib.ArithmeticOverflow.selector, expectedErrorHandle));
        // call TFHE.add(ei1, ei2)
        this._callTFHEAddInIsolatedContext(ei1, ei2);

        FhevmDebug.stopArithmeticCheck();
    }

    function testFuzz_startStopCheck_with_valid_ops_should_succeed(uint8 v1, uint8 v2) public {
        vm.assume(uint256(v1) + uint256(v2) <= type(uint8).max);
        FhevmDebug.startArithmeticCheck(FhevmDebug.ArithmeticCheckMode.OperandsAndResult);
        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        TFHE.add(ei1, ei2);
        FhevmDebug.stopArithmeticCheck();
    }

    function test_startStopCheck_do_not_revert() public {
        FhevmDebug.startArithmeticCheck(FhevmDebug.ArithmeticCheckMode.OperandsAndResult);
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        FhevmDebug.stopArithmeticCheck();

        // should not revert
        TFHE.add(ei1, ei2);
    }

    function testFuzz_startStopCheck_do_not_revert(uint8 v1, uint8 v2) public {
        vm.assume(uint256(v1) + uint256(v2) > type(uint8).max);
        FhevmDebug.startArithmeticCheck(FhevmDebug.ArithmeticCheckMode.OperandsAndResult);
        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);
        FhevmDebug.stopArithmeticCheck();

        // should not revert
        TFHE.add(ei1, ei2);
    }

    function test_check_OperandsAndResult_Add_overflow() public {
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);

        uint256 expectedErrorHandle = TFHEzk.add(euint8.unwrap(ei1), euint8.unwrap(ei2));

        FhevmDebug.checkArithmetic(FhevmDebug.ArithmeticCheckMode.OperandsAndResult);
        vm.expectRevert(abi.encodeWithSelector(MathLib.ArithmeticOverflow.selector, expectedErrorHandle));
        // call TFHE.add(ei1, ei2)
        this._callTFHEAddInIsolatedContext(ei1, ei2);
    }

    function testFuzz_check_OperandsAndResult_Add_overflow(uint8 v1, uint8 v2) public {
        vm.assume(uint256(v1) + uint256(v2) > type(uint8).max);

        euint8 ei1 = TFHE.asEuint8(v1);
        euint8 ei2 = TFHE.asEuint8(v2);

        uint256 expectedErrorHandle = TFHEzk.add(euint8.unwrap(ei1), euint8.unwrap(ei2));

        FhevmDebug.checkArithmetic(FhevmDebug.ArithmeticCheckMode.OperandsAndResult);
        vm.expectRevert(abi.encodeWithSelector(MathLib.ArithmeticOverflow.selector, expectedErrorHandle));
        // call TFHE.add(ei1, ei2)
        this._callTFHEAddInIsolatedContext(ei1, ei2);
    }

    function test_check_Operands_Add_overflow() public {
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);
        euint8 ei3 = TFHE.add(ei1, ei2);
        vm.assertFalse(FhevmDebug.isArithmeticallyValid(ei3));

        FhevmDebug.checkArithmetic(FhevmDebug.ArithmeticCheckMode.OperandsOnly);
        vm.expectRevert(abi.encodeWithSelector(MathLib.ArithmeticOverflow.selector, euint8.unwrap(ei3)));
        // call TFHE.add(ei1, ei3)
        this._callTFHEAddInIsolatedContext(ei1, ei3);
    }

    function test_add_overflow_ge_valid() public {
        // in TFHExecutor.trivialEncrypt : msg.sender = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
        // 128 + 129 is overflow
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);

        euint8 ei3 = TFHE.add(ei1, ei2);
        vm.assertFalse(FhevmDebug.isArithmeticallyValid(ei3));

        // <garbage> >= 0 is always true
        ebool validTrue = TFHE.ge(ei3, TFHE.asEuint8(0));
        vm.assertTrue(FhevmDebug.isArithmeticallyValid(validTrue));

        euint8 ei4 = TFHE.add(ei3, TFHE.asEuint8(0));
        vm.assertFalse(FhevmDebug.isArithmeticallyValid(ei4));

        FhevmDebug.checkArithmetic(FhevmDebug.ArithmeticCheckMode.ResultOnly);
        validTrue = TFHE.ge(ei4, TFHE.asEuint8(0));
    }

    function test_check_ResultOnly_Add_overflow_Ge() public {
        // 128 + 129 is overflow
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);

        euint8 ei3 = TFHE.add(ei1, ei2);
        vm.assertFalse(FhevmDebug.isArithmeticallyValid(ei3));

        euint8 one = TFHE.asEuint8(1);

        uint256 expectedErrorHandle = TFHEzk.ge(euint8.unwrap(ei3), euint8.unwrap(one));

        // Revert if next TFHE call result is not arithmetically valid
        FhevmDebug.checkArithmetic(FhevmDebug.ArithmeticCheckMode.ResultOnly);

        vm.expectRevert(abi.encodeWithSelector(MathLib.ArithmeticOverflow.selector, expectedErrorHandle));
        // call TFHE.ge(ei3, one)
        this._callTFHEGeInIsolatedContext(ei3, one);
    }

    function test_check_ResultOnly_Add_overflow() public {
        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(129);

        uint256 expectedErrorHandle = TFHEzk.add(euint8.unwrap(ei1), euint8.unwrap(ei2));

        // Revert if next TFHE call result is not arithmetically valid
        FhevmDebug.checkArithmetic(FhevmDebug.ArithmeticCheckMode.ResultOnly);

        vm.expectRevert(abi.encodeWithSelector(MathLib.ArithmeticOverflow.selector, expectedErrorHandle));
        // call TFHE.add(ei1, ei2)
        this._callTFHEAddInIsolatedContext(ei1, ei2);
    }

    function _callTFHEAddInIsolatedContext(euint8 a, euint8 b) public {
        TFHE.add(a, b);
    }

    function _callTFHEGeInIsolatedContext(euint8 a, euint8 b) public {
        TFHE.ge(a, b);
    }
}
