// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";
import {TFHE, einput, ebool, ebytes256} from "../lib/TFHE.sol";
import {TFHEvm} from "../src/TFHEvm.sol";
import {EncryptedInput} from "../src/encrypted-input/EncryptedInput.sol";
import {BytesLib} from "../src/utils/BytesLib.sol";

contract EncryptedInputTest is Test {
    function setUp() public {
        TFHEvm.setUp();
    }

    function test_AsBoolAnd() public {
        ebool b1 = TFHE.asEbool(true);

        address userAddress = msg.sender;
        address contractAddress = address(this);

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.addBool(true, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        (einput[] memory handles, bytes memory inputProof) = input.encrypt();

        ebool b2 = TFHE.asEbool(handles[0], inputProof);
        ebool b3 = TFHE.and(b1, b2);

        bool b2_ct = TFHEvm.getClear(b2);
        bool b3_ct = TFHEvm.getClear(b3);

        vm.assertEq(b2_ct, true);
        vm.assertEq(b3_ct, true);
    }

    function test_helper_AsBoolAnd() public {
        ebool b1 = TFHE.asEbool(true);

        address userAddress = msg.sender;
        address contractAddress = address(this);

        (einput inputHandle, bytes memory inputProof) = TFHEvm.encryptBool(
            true, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209, contractAddress, userAddress
        );

        ebool b2 = TFHE.asEbool(inputHandle, inputProof);
        ebool b3 = TFHE.and(b1, b2);

        TFHE.allow(b2, contractAddress);
        TFHE.allow(b2, userAddress);

        TFHE.allow(b3, contractAddress);
        TFHE.allow(b3, userAddress);

        bool b2_ct = TFHEvm.decryptBool(b2, contractAddress, userAddress);
        bool b3_ct = TFHEvm.decryptBool(b3, contractAddress, userAddress);

        vm.assertEq(b2_ct, true);
        vm.assertEq(b3_ct, true);
    }

    function test_helper_AsBytes() public {
        bytes memory b128 = abi.encodePacked(
            hex"0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376"
        );

        address userAddress = msg.sender;
        address contractAddress = address(this);

        (einput inputHandle, bytes memory inputProof) = TFHEvm.encryptBytes256(
            b128, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209, contractAddress, userAddress
        );

        ebytes256 b_enc = TFHE.asEbytes256(inputHandle, inputProof);

        TFHE.allow(b_enc, contractAddress);
        TFHE.allow(b_enc, userAddress);

        bytes memory b_ct = TFHEvm.decryptBytes256(b_enc, contractAddress, userAddress);

        vm.assertEq(b_ct, b128);
    }

    function test_helper_AsBytesEq() public {
        bytes memory b128 = abi.encodePacked(
            hex"0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376"
        );

        address userAddress = msg.sender;
        address contractAddress = address(this);

        (einput inputHandle1, bytes memory inputProof1) = TFHEvm.encryptBytes256(
            b128, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209, contractAddress, userAddress
        );

        (einput inputHandle2, bytes memory inputProof2) = TFHEvm.encryptBytes256(
            b128, 0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376, contractAddress, userAddress
        );

        ebytes256 b_enc1 = TFHE.asEbytes256(inputHandle1, inputProof1);
        ebytes256 b_enc2 = TFHE.asEbytes256(inputHandle2, inputProof2);

        ebool eq_enc = TFHE.eq(b_enc1, b_enc2);

        TFHE.allow(eq_enc, contractAddress);
        TFHE.allow(eq_enc, userAddress);

        bool eq_ct = TFHEvm.decryptBool(eq_enc, contractAddress, userAddress);

        vm.assertEq(eq_ct, true);
    }

    function test_AddBool() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.addBool(true, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 1);
    }

    function test_Add4() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.add4(15, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 15);
    }

    function test_Add8() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.add8(255, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 255);
    }

    function test_Add16() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.add16(65535, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 65535);
    }

    function test_Add32() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        //input = input.add32(2 ** 32 - 1, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        input.add32(2 ** 32 - 1, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 2 ** 32 - 1);
    }

    function test_Add64() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.add64(2 ** 64 - 1, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 2 ** 64 - 1);
    }

    function test_Add128() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.add128(2 ** 128 - 1, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 2 ** 128 - 1);
    }

    function test_Add256() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.add256(2 ** 256 - 1, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 2 ** 256 - 1);
    }

    function test_AddBytes64() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        bytes memory b64 = abi.encodePacked(
            hex"0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376"
        );

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.addBytes64(b64, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256[8] memory a = input._list._items[0].extract2048();

        vm.assertEq(a[0], uint256(0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376));
        vm.assertEq(a[1], uint256(0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376));
        vm.assertEq(a[2], uint256(0));
        vm.assertEq(a[3], uint256(0));
        vm.assertEq(a[4], uint256(0));
        vm.assertEq(a[5], uint256(0));
        vm.assertEq(a[6], uint256(0));
        vm.assertEq(a[7], uint256(0));
    }

    function test_AddBytes128() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        bytes memory b128 = abi.encodePacked(
            hex"0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376"
        );

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.addBytes128(b128, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256[8] memory a = input._list._items[0].extract2048();

        vm.assertEq(a[0], uint256(0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376));
        vm.assertEq(a[1], uint256(0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376));
        vm.assertEq(a[2], uint256(0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376));
        vm.assertEq(a[3], uint256(0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376));
        vm.assertEq(a[4], uint256(0));
        vm.assertEq(a[5], uint256(0));
        vm.assertEq(a[6], uint256(0));
        vm.assertEq(a[7], uint256(0));
    }

    function test_AddBytes256() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        bytes memory b128 = abi.encodePacked(
            hex"0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376"
        );

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.addBytes256(b128, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256[8] memory a = input._list._items[0].extract2048();

        vm.assertEq(a[0], uint256(0));
        vm.assertEq(a[1], uint256(0));
        vm.assertEq(a[2], uint256(0));
        vm.assertEq(a[3], uint256(0));
        vm.assertEq(a[4], uint256(0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376));
        vm.assertEq(a[5], uint256(0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376));
        vm.assertEq(a[6], uint256(0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376));
        vm.assertEq(a[7], uint256(0x0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376));
    }

    function test_Add64Add32_Coprocessor() public {
        if (!TFHEvm.isCoprocessor()) {
            return;
        }

        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = TFHEvm.createEncryptedInput(contractAddress, userAddress);
        input.add64(123456, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        input.add32(7890, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        (einput[] memory handles, bytes memory inputProof) = input.encrypt();

        vm.assertEq(handles.length, 2);
        vm.assertEq(einput.unwrap(handles[0]), 0x496eb5b6fa3270a6c5482f4854ea0d8d503e865e528d9d51ed245edd3f000500);
        vm.assertEq(einput.unwrap(handles[1]), 0x46ccfd5cedb24d2a0c6e65c4ec6bd143d0bcf69b197186b79e53452ac5010400);
        vm.assertEq(
            inputProof,
            abi.encodePacked(
                hex"0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376aae6496eb5b6fa3270a6c5482f4854ea0d8d503e865e528d9d51ed245edd3f00050046ccfd5cedb24d2a0c6e65c4ec6bd143d0bcf69b197186b79e53452ac501040066cdd9f23b35d78e59b1c51b80b0a3765e499ed9a0fd84b4f33efad25c33ed8c654ba42c65c9feee8e95f3cb1ec0e31b560692333bdad5e2c35407bc8111f0711b9e71f6d432c8d642e3b954da3d8235d1328d0eb49f11ff9dfcc9635237fa2c30570d92b896aad3068c6677245ca951b4016ea6ac28d061239648dfb722f311191c"
            )
        );
    }
}
