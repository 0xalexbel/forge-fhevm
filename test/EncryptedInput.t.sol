// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";

import {TFHE, einput, ebool, ebytes256} from "../src/libs/fhevm-debug/lib/TFHE.sol";

import {FhevmDebug} from "../src/FhevmDebug.sol";
import {FFhevm, EncryptedInput} from "../src/FFhevm.sol";

contract EncryptedInputTest is Test {
    function setUp() public {
        FFhevm.setUp();
    }

    function test_AsBoolAnd() public {
        ebool b1 = TFHE.asEbool(true);

        address userAddress = msg.sender;
        address contractAddress = address(this);

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
        input.addBool(true, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        (einput[] memory handles, bytes memory inputProof) = input.encrypt();

        ebool b2 = TFHE.asEbool(handles[0], inputProof);
        ebool b3 = TFHE.and(b1, b2);

        bool b2Ct = FhevmDebug.getClear(b2);
        bool b3Ct = FhevmDebug.getClear(b3);

        vm.assertEq(b2Ct, true);
        vm.assertEq(b3Ct, true);
    }

    function test_helper_AsBoolAnd() public {
        ebool b1 = TFHE.asEbool(true);

        address userAddress = msg.sender;
        address contractAddress = address(this);

        (einput inputHandle, bytes memory inputProof) = FFhevm.encryptBool(true, contractAddress, userAddress);

        ebool b2 = TFHE.asEbool(inputHandle, inputProof);
        ebool b3 = TFHE.and(b1, b2);

        TFHE.allow(b2, contractAddress);
        TFHE.allow(b2, userAddress);

        TFHE.allow(b3, contractAddress);
        TFHE.allow(b3, userAddress);

        bool b2Ct = FhevmDebug.decryptBool(b2, contractAddress, userAddress);
        bool b3Ct = FhevmDebug.decryptBool(b3, contractAddress, userAddress);

        vm.assertEq(b2Ct, true);
        vm.assertEq(b3Ct, true);
    }

    function test_helper_AsBytes() public {
        bytes memory b128 = abi.encodePacked(
            hex"0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376"
        );

        address userAddress = msg.sender;
        address contractAddress = address(this);

        (einput inputHandle, bytes memory inputProof) = FFhevm.encryptBytes256(b128, contractAddress, userAddress);

        ebytes256 bEnc = TFHE.asEbytes256(inputHandle, inputProof);

        TFHE.allow(bEnc, contractAddress);
        TFHE.allow(bEnc, userAddress);

        bytes memory bCt = FhevmDebug.decryptBytes256(bEnc, contractAddress, userAddress);

        vm.assertEq(bCt, b128);
    }

    function test_helper_AsBytesEq() public {
        bytes memory b128 = abi.encodePacked(
            hex"0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c43760201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376"
        );

        address userAddress = msg.sender;
        address contractAddress = address(this);

        (einput inputHandle1, bytes memory inputProof1) = FFhevm.encryptBytes256(b128, contractAddress, userAddress);

        (einput inputHandle2, bytes memory inputProof2) = FFhevm.encryptBytes256(b128, contractAddress, userAddress);

        ebytes256 bEnc1 = TFHE.asEbytes256(inputHandle1, inputProof1);
        ebytes256 bEnc2 = TFHE.asEbytes256(inputHandle2, inputProof2);

        ebool eqEnc = TFHE.eq(bEnc1, bEnc2);

        TFHE.allow(eqEnc, contractAddress);
        TFHE.allow(eqEnc, userAddress);

        bool eqCt = FhevmDebug.decryptBool(eqEnc, contractAddress, userAddress);

        vm.assertEq(eqCt, true);
    }

    function test_AddBool() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
        input.addBool(true, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 1);
    }

    function test_Add4() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
        input.add4(15, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 15);
    }

    function test_Add8() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
        input.add8(255, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 255);
    }

    function test_Add16() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
        input.add16(65535, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 65535);
    }

    function test_Add32() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
        //input = input.add32(2 ** 32 - 1, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        input.add32(2 ** 32 - 1, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 2 ** 32 - 1);
    }

    function test_Add64() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
        input.add64(2 ** 64 - 1, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 2 ** 64 - 1);
    }

    function test_Add128() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
        input.add128(2 ** 128 - 1, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        uint256 a = input._list._items[0].extract256();
        vm.assertEq(a, 2 ** 128 - 1);
    }

    function test_Add256() public {
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
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

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
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

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
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

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);
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
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        EncryptedInput memory input = FFhevm.createEncryptedInput(contractAddress, userAddress);

        // The encoded result below has been computed using the following addresses:
        // 
        input._signer.chainId = 31337;
        input._signer.acl = 0x339EcE85B9E11a3A3AA557582784a15d7F82AAf2;
        input._signer.kmsVerifier = 0x208De73316E44722e16f6dDFF40881A3e4F86104;
        input._signer.inputVerifier = 0x69dE3158643e738a0724418b21a35FAA20CBb1c5;
        input._signer.coprocSigner.addr = 0xc9990FEfE0c27D31D0C2aa36196b085c0c4d456c;
        input._signer.coprocSigner.privateKey = 57345986822467263407452523075989323922629812897950173236713635509495877253377;
        input._signer.kmsSigners = new FFhevm.Signer[](1);
        input._signer.kmsSigners[0].addr = 0x0971C80fF03B428fD2094dd5354600ab103201C5;
        input._signer.kmsSigners[0].privateKey = 25575929143713252205522749670265078485541952339991649856291280552944085753489;
        
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
