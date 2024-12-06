// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";

import {TFHE, euint8} from "../src/libs/fhevm-debug/lib/TFHE.sol";
import {Gateway} from "../src/libs/fhevm-debug/gateway/lib/Gateway.sol";

import {FFhevm, EncryptedInput} from "../src/FFhevm.sol";

/*
        decryptedResult = 0x000000000000000000000000000000000000000000000000000000000000002a
        numSigners = 1
        privKeySigner[0] = 388b7680e4e1afa06efbfd45cdd1fe39f3c6af381df6555a19661f283b97de91 (=PRIVATE_KEY_KMS_SIGNER_0)
        kmsSignerAddress = 0x0971C80fF03B428fD2094dd5354600ab103201C5
        chainId = 31337
        kmsVerifierAddress = 0x208De73316E44722e16f6dDFF40881A3e4F86104
        aclAddress = 0x339EcE85B9E11a3A3AA557582784a15d7F82AAf2
        decryptResultsEIP712signatures[0] = 0xc519b582869824d3e3870400212195dc65f418224537d5b19075aae2adcadfcc45ce17b0db2ea5678c361a979143232e308328d19a475c739108da5bb2e9ef0b1b
*/

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
