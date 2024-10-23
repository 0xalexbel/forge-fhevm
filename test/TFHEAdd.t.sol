// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";
import {TFHE, euint8, euint64, einput, ebool, ebytes256} from "fhevm/lib/TFHE.sol";
import {TFHEvm} from "../src/TFHEvm.sol";
import {EncryptedInput} from "../src/encrypted-input/EncryptedInput.sol";

contract TFHEAddTest is Test {
    function setUp() public {
        TFHEvm.setUp();
    }

    function test_AsEUint8() public {
        TFHE.asEuint8(128);
    }

    function test_AsEUint8AndDecrypt() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        TFHE.allow(ei1, userAddress);

        console.logBytes32(bytes32(euint8.unwrap(ei1)));

        uint8 i1 = TFHEvm.decryptU8(ei1, contractAddress, userAddress);
        vm.assertEq(i1, 128);
    }

    // function test_revert_AsEUint8_overflow() public {
    //     vm.expectRevert("Value overflow");
    //     TFHE.asEuint8(65000);
    // }

    function test_Add_euint8_euint8() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(2);
        euint8 ei3 = TFHE.add(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 128 + 2);
    }

    function test_Add_euint8_euint8_overflow() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.asEuint8(128);
        euint8 ei3 = TFHE.add(ei1, ei2);
        TFHE.allow(ei3, userAddress);

        uint8 i3 = TFHEvm.decryptU8(ei3, contractAddress, userAddress);
        vm.assertEq(i3, 0);
    }

    function test_Add_euint8_uint8() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.add(ei1, 1);
        TFHE.allow(ei2, userAddress);

        uint8 i2 = TFHEvm.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 128 + 1);
    }

    function test_Add_euint8_uint8_overflow() public {
        address userAddress = msg.sender;
        address contractAddress = address(this);

        euint8 ei1 = TFHE.asEuint8(128);
        euint8 ei2 = TFHE.add(ei1, 128);
        TFHE.allow(ei2, userAddress);

        bool ok = TFHEvm.isArithmeticallyValid(ei2);
        vm.assertFalse(ok);

        uint8 i2 = TFHEvm.decryptU8(ei2, contractAddress, userAddress);
        vm.assertEq(i2, 0);
    }
}
