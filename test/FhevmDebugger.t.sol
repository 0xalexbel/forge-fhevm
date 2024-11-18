// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";

import {TFHE, einput, ebool, euint64} from "../src/debug/fhevm/lib/TFHE.sol";
import {FHEVMConfig} from "../src/debug/fhevm/lib/FHEVMConfig.sol";
import {FhevmDebugger} from "../src/debug/FhevmDebugger.sol";

import {BytesLib} from "../src/forge/utils/BytesLib.sol";
import {EncryptedInput} from "../src/forge/EncryptedInput.sol";
import {ForgeFhevm} from "../src/forge/ForgeFhevm.sol";
import {FhevmInput} from "../src/forge/FhevmInput.sol";

contract Foo {
    struct FooStruct {
        address a;
        address b;
        address c;
    }

    euint64 private _number;

    constructor() {
        TFHE.setFHEVM(FHEVMConfig.defaultConfig());
    }

    function setNumber(einput encryptedAmount, bytes calldata inputProof) external {
        setNumber(TFHE.asEuint64(encryptedAmount, inputProof));
    }

    function setNumber(euint64 number) public {
        require(TFHE.isSenderAllowed(number));
        _number = number;
        TFHE.allowThis(_number);
    }

    function getNumber() public view returns (uint64) {
        return FhevmDebugger.getClear(_number);
    }

    function getENumber() public returns (euint64) {
        TFHE.allow(_number, msg.sender);
        return _number;
    }
}

contract FhevmDebuggerTest is Test {
    function setUp() public {
        ForgeFhevm.setUp();
    }

    function test_getClear_from_within_a_contract() public {
        Foo foo = new Foo();
        (einput handle, bytes memory inputProof) = FhevmInput.encryptU64(123, address(foo), address(this));

        foo.setNumber(handle, inputProof);

        euint64 enumber = foo.getENumber();
        uint64 number = FhevmDebugger.decryptU64(enumber, address(foo), address(this));

        vm.assertEq(foo.getNumber(), 123);
        vm.assertEq(number, 123);
    }

    function test_wrong_userAddress() public {
        Foo foo = new Foo();
        (einput handle, bytes memory inputProof) = FhevmInput.encryptU64(123, address(foo), msg.sender);
        //1112264
        vm.expectRevert();
        foo.setNumber(handle, inputProof);
    }
}
