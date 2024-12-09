// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";

import {TFHE, euint8} from "../src/libs/fhevm-debug/lib/TFHE.sol";
import {Gateway} from "../src/libs/fhevm-debug/gateway/lib/Gateway.sol";

import {FFhevm, EncryptedInput} from "../src/FFhevm.sol";

contract AsyncDecryptTest is Test {
    uint256 requestCount;
    bool cb1;
    bool cb2;

    function setUp() public {
        FFhevm.setUp();
    }

    function test_async_decrypt() public {
        euint8 ei1 = TFHE.asEuint8(12);
        euint8 ei2 = TFHE.asEuint8(30);

        cb1 = false;
        cb1 = false;

        euint8 ei3 = TFHE.add(ei1, ei2);

        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(ei3);
        Gateway.requestDecryption(cts, this.callbackUint8.selector, 0, block.timestamp + 100, true);

        cts[0] = Gateway.toUint256(ei1);
        Gateway.requestDecryption(cts, this.callbackUintNoSig.selector, 0, block.timestamp + 100, !true);

        FFhevm.gatewayFulfillRequests();

        vm.assertTrue(cb1);
        vm.assertTrue(cb2);
    }

    function callbackUint8(uint256 requestID, uint8 decryptedInput, bytes[] memory signatures) public {
        vm.assertFalse(cb2);
        vm.assertEq(requestID, 0);
        vm.assertEq(decryptedInput, 42);
        vm.assertTrue(signatures.length > 0);
        cb2 = true;
    }

    function callbackUintNoSig(uint256 requestID, uint8 decryptedInput) public {
        vm.assertFalse(cb1);
        vm.assertEq(requestID, 1);
        vm.assertEq(decryptedInput, 12);
        cb1 = true;
    }
}
