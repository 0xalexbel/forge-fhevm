// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";

import {TFHE, einput, ebool, euint64} from "../src/libs/fhevm-debug/lib/TFHE.sol";
import {InputProof} from "../src/libs/forge/input/InputProof.sol";

import {FhevmDebug} from "../src/FhevmDebug.sol";
import {FFhevm, EncryptedInput} from "../src/FFhevm.sol";

import {FHEVMConfig} from "./FHEVMConfig.sol";

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
        require(TFHE.isSenderAllowed(number), "Foo: setNumber sender not allowed");
        _number = number;
        TFHE.allowThis(_number);
    }

    function getNumber() public view returns (uint64) {
        return FhevmDebug.getClear(_number);
    }

    function getENumber() public returns (euint64) {
        TFHE.allow(_number, msg.sender);
        return _number;
    }
}

contract FFhevmDebugTest is Test {
    function setUp() public {
        FFhevm.setUp();
    }

    function test_getClear_from_within_a_contract() public {
        Foo foo = new Foo();
        (einput handle, bytes memory inputProof) = FFhevm.encryptU64(123, address(foo), address(this));

        FFhevm.Config memory config = FFhevm.getConfig();
        vm.assertEq(InputProof.numHandles(inputProof), 1);
        vm.assertEq(InputProof.numKMSSigners(inputProof), config.deployConfig.numKmsSigners);

        uint256[] memory handles = InputProof.extractHandles(inputProof);
        vm.assertEq(handles.length, 1);
        vm.assertEq(handles[0], uint256(einput.unwrap(handle)));

        foo.setNumber(handle, inputProof);

        euint64 enumber = foo.getENumber();
        uint64 number = FhevmDebug.decryptU64(enumber, address(foo), address(this));

        vm.assertEq(foo.getNumber(), 123);
        vm.assertEq(number, 123);
    }

    function test_wrong_userAddress() public {
        Foo foo = new Foo();
        (einput handle, bytes memory inputProof) = FFhevm.encryptU64(123, address(foo), msg.sender);
        //1112264
        vm.expectRevert();
        foo.setNumber(handle, inputProof);
    }
}
