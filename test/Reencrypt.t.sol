// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";
import {BytesLib} from "../src/utils/BytesLib.sol";
import {TFHEvm} from "../src/TFHEvm.sol";
import {ReencryptLib} from "../src/reencrypt/Reencrypt.sol";

contract ReencryptTest is Test {
    function setUp() public {
        TFHEvm.setUp();
    }

    function test_sign() public pure {
        bytes memory publicKey =
            abi.encodePacked(hex"20000000000000008fcea1dc16897f40ea5142b829cb04b7527e48727a63e993e4561b6824104c2d");
        bytes memory privateKey =
            abi.encodePacked(hex"2000000000000000a5cb64ce9aea0f7dd66f04fdf61592c74ef6aa16b8f63c1d53da17211bd3ec0e");
        uint256 signerPk = 0x21521291d36b38112e2ae2b780ac39df94dd40bace399f479833f6a813e43b09;
        address signerAddr = 0x813787401A8CC716B6C7B834Ecd89D0fA34e0132;
        uint256 chainId = 31337;
        address verifyingContract = 0xcEc0e9723bF28D2A2C867108cC4C3A38a011d4D1;
        bytes memory signature = abi.encodePacked(
            hex"eb4e999aa1eb1013aadb9de7e9d9e427a7a8e0bbd1dbb70d5d5fb25c35ab0d595d46ee783a78c3ac433990b296aeb4063b8dbde210aacafc2be1320e7cb482551c"
        );
        bytes memory sig = ReencryptLib.reencryptSign(publicKey, chainId, verifyingContract, signerPk);
        vm.assertEq(sig, signature);

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, sig, chainId, verifyingContract, signerAddr);
    }

    function test_generateKeyPair() public {
        (bytes memory publicKey, bytes memory privateKey) = ReencryptLib.generateKeyPair();
        vm.assertEq(publicKey.length, 40);
        vm.assertEq(privateKey.length, 40);
        bytes8 b1 = BytesLib.bytesToBytes8(publicKey, 0);
        vm.assertEq(b1, bytes8(0x2000000000000000));
        bytes8 b2 = BytesLib.bytesToBytes8(privateKey, 0);
        vm.assertEq(b2, bytes8(0x2000000000000000));
    }
}
