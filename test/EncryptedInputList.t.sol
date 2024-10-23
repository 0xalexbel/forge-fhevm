// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {console} from "forge-std/src/Console.sol";
import {Test} from "forge-std/src/Test.sol";
import {EncryptedInputList, EncryptedInputListLib} from "../src/encrypted-input/EncryptedInputList.sol";
import {EncryptedInputSigner} from "../src/encrypted-input/EncryptedInputSigner.sol";

contract EncryptedInputListTest is Test {
    function setUp() public {}

    function test_AddBool() public pure {
        EncryptedInputList memory input;
        input.addBool(true, 0xd5ca22bc4a5658e09cd06205fdaa89be9a4c5c9a921c3cb685ec48398d1b2012);

        assertEq(input.length(), 1);
        assertEq(
            input._items[0]._data,
            abi.encodePacked(hex"0001d5ca22bc4a5658e09cd06205fdaa89be9a4c5c9a921c3cb685ec48398d1b2012")
        );
    }

    function test_Add4() public pure {
        EncryptedInputList memory input;
        input.add4(2, 0xc581263b61d3bf95a490d7b7918244f7f084428ab4215b3b18378bbf3a6fec90);
        assertEq(input.length(), 1);
        assertEq(
            input._items[0]._data,
            abi.encodePacked(hex"0102c581263b61d3bf95a490d7b7918244f7f084428ab4215b3b18378bbf3a6fec90")
        );
    }

    function test_Add8() public pure {
        EncryptedInputList memory input;
        input.add8(255, 0x181886ee2e736f086e1c5c80603d20859209567d8bca5acb2ed43724dd44050d);
        assertEq(input.length(), 1);
        assertEq(
            input._items[0]._data,
            abi.encodePacked(hex"02ff181886ee2e736f086e1c5c80603d20859209567d8bca5acb2ed43724dd44050d")
        );
    }

    function test_Add16() public pure {
        EncryptedInputList memory input;
        input.add16(12345, 0x03f9f22a1f7c003212384c052ccddce85bda5ccd2673cc4b5cb4c61522106e64);
        assertEq(input.length(), 1);
        assertEq(
            input._items[0]._data,
            abi.encodePacked(hex"03303903f9f22a1f7c003212384c052ccddce85bda5ccd2673cc4b5cb4c61522106e64")
        );
    }

    function test_Add32() public pure {
        EncryptedInputList memory input;
        input.add32(123456, 0xc24709aa5cb9ce12f3be44d132b6120a3fa963b44f639685ee79948b52dba91b);
        assertEq(input.length(), 1);
        assertEq(
            input._items[0]._data,
            abi.encodePacked(hex"040001e240c24709aa5cb9ce12f3be44d132b6120a3fa963b44f639685ee79948b52dba91b")
        );
    }

    function test_Add64() public pure {
        EncryptedInputList memory input;
        input.add64(123456, 0x339a0a60345215d851fe889d74329f0e79ef3c4b6960d60a93c655373e41237b);
        assertEq(input.length(), 1);
        assertEq(
            input._items[0]._data,
            abi.encodePacked(hex"05000000000001e240339a0a60345215d851fe889d74329f0e79ef3c4b6960d60a93c655373e41237b")
        );
    }

    function test_Add128() public pure {
        EncryptedInputList memory input;
        input.add128(123456, 0xcbb5e7b47c99f912cb38d63a8cb4757ac82692bacd04035f5fe1f3ce10b30bf5);
        assertEq(input.length(), 1);
        assertEq(
            input._items[0]._data,
            abi.encodePacked(
                hex"060000000000000000000000000001e240cbb5e7b47c99f912cb38d63a8cb4757ac82692bacd04035f5fe1f3ce10b30bf5"
            )
        );
    }

    function test_Add256() public pure {
        EncryptedInputList memory input;
        input.add256(123456, 0x2d3721113627aec03b2f29716475e8abdc9637f70be1a5b3c478e735aa093429);
        assertEq(input.length(), 1);
        assertEq(
            input._items[0]._data,
            abi.encodePacked(
                hex"08000000000000000000000000000000000000000000000000000000000001e2402d3721113627aec03b2f29716475e8abdc9637f70be1a5b3c478e735aa093429"
            )
        );
    }

    function test_AddBytes64() public pure {
        EncryptedInputList memory input;
        input.addBytes64(
            bytes.concat(bytes4(uint32(123456))), 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209
        );
        assertEq(input.length(), 1);
        assertEq(
            input._items[0]._data,
            abi.encodePacked(
                hex"090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e24027ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209"
            )
        );
    }

    function test_Add64Handle() public pure {
        EncryptedInputList memory input;
        input.add64(123456, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        bytes32 hashedData = input.hashData();
        assertEq(input.length(), 1);
        bytes32 h = input._items[0].handle(hashedData);
        bytes32 expected = 0x60853e3a5639a842645bf747c8feb53ece18d803da80cb85046221b0c1000500;
        assertEq(h, expected);
    }

    function test_Add64Add32Handle() public pure {
        EncryptedInputList memory input;
        input.add64(123456, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        input.add32(7890, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        bytes32 hashedData = input.hashData();
        assertEq(input.length(), 2);
        bytes32 h0 = input._items[0].handle(hashedData);
        bytes32 h1 = input._items[1].handle(hashedData);
        bytes32 expected0 = 0x496eb5b6fa3270a6c5482f4854ea0d8d503e865e528d9d51ed245edd3f000500;
        bytes32 expected1 = 0x46ccfd5cedb24d2a0c6e65c4ec6bd143d0bcf69b197186b79e53452ac5010400;
        assertEq(h0, expected0);
        assertEq(h1, expected1);
    }

    function test_CoprocSign() public pure {
        bytes32 hashOfCiphertext = 0xc8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376aae6;
        uint256[] memory handlesList = new uint256[](2);
        handlesList[0] = 33214445272851953888971791435523282986228576720443603426622883507502061716736;
        handlesList[1] = 32024084849216631056286106877917562398524419963558258264588868824115426952192;

        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;

        EncryptedInputSigner memory signer;
        signer.acl = 0x339EcE85B9E11a3A3AA557582784a15d7F82AAf2;
        signer.inputVerifier = 0x69dE3158643e738a0724418b21a35FAA20CBb1c5;
        signer.kmsVerifier = 0x208De73316E44722e16f6dDFF40881A3e4F86104;
        signer.chainId = 31337;
        signer.coprocSigner = 0x7ec8ada6642fc4ccfb7729bc29c17cf8d21b61abd5642d1db992c0b8672ab901;
        signer.kmsSigners = new uint256[](1);
        signer.kmsSigners[0] = 0x388b7680e4e1afa06efbfd45cdd1fe39f3c6af381df6555a19661f283b97de91;

        bytes memory sig = signer.coprocSign(hashOfCiphertext, handlesList, userAddress, contractAddress);
        assertEq(
            sig,
            abi.encodePacked(
                hex"66cdd9f23b35d78e59b1c51b80b0a3765e499ed9a0fd84b4f33efad25c33ed8c654ba42c65c9feee8e95f3cb1ec0e31b560692333bdad5e2c35407bc8111f0711b"
            )
        );
    }

    function test_KmsSign() public pure {
        bytes32 hashOfCiphertext = 0xc8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376aae6;
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;

        EncryptedInputSigner memory signer;
        signer.acl = 0x339EcE85B9E11a3A3AA557582784a15d7F82AAf2;
        signer.chainId = 31337;
        signer.coprocSigner = 0x7ec8ada6642fc4ccfb7729bc29c17cf8d21b61abd5642d1db992c0b8672ab901;
        signer.kmsSigners = new uint256[](1);
        signer.kmsSigners[0] = 0x388b7680e4e1afa06efbfd45cdd1fe39f3c6af381df6555a19661f283b97de91;
        signer.inputVerifier = 0x69dE3158643e738a0724418b21a35FAA20CBb1c5;
        signer.kmsVerifier = 0x208De73316E44722e16f6dDFF40881A3e4F86104;

        bytes memory sig = signer.kmsSign(hashOfCiphertext, userAddress, contractAddress, 0);
        assertEq(
            sig,
            abi.encodePacked(
                hex"9e71f6d432c8d642e3b954da3d8235d1328d0eb49f11ff9dfcc9635237fa2c30570d92b896aad3068c6677245ca951b4016ea6ac28d061239648dfb722f311191c"
            )
        );
    }

    function test_CoprocEncrypt() public pure {
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;

        EncryptedInputSigner memory signer;
        signer.acl = 0x339EcE85B9E11a3A3AA557582784a15d7F82AAf2;
        signer.inputVerifier = 0x69dE3158643e738a0724418b21a35FAA20CBb1c5;
        signer.kmsVerifier = 0x208De73316E44722e16f6dDFF40881A3e4F86104;
        signer.chainId = 31337;
        signer.coprocSigner = 0x7ec8ada6642fc4ccfb7729bc29c17cf8d21b61abd5642d1db992c0b8672ab901;
        signer.kmsSigners = new uint256[](1);
        signer.kmsSigners[0] = 0x388b7680e4e1afa06efbfd45cdd1fe39f3c6af381df6555a19661f283b97de91;

        EncryptedInputList memory input;
        input.add64(123456, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        input.add32(7890, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);

        (uint256[] memory handles, bytes memory inputProof) =
            EncryptedInputListLib.encrypt(input, signer, contractAddress, userAddress);

        assertEq(handles.length, 2);
        assertEq(handles[0], 0x496eb5b6fa3270a6c5482f4854ea0d8d503e865e528d9d51ed245edd3f000500);
        assertEq(handles[1], 0x46ccfd5cedb24d2a0c6e65c4ec6bd143d0bcf69b197186b79e53452ac5010400);
        assertEq(
            inputProof,
            abi.encodePacked(
                hex"0201c8c28ce7a29ad73a0a0dbd2145443a29bbe1182e8bfeb07d2276d45c4376aae6496eb5b6fa3270a6c5482f4854ea0d8d503e865e528d9d51ed245edd3f00050046ccfd5cedb24d2a0c6e65c4ec6bd143d0bcf69b197186b79e53452ac501040066cdd9f23b35d78e59b1c51b80b0a3765e499ed9a0fd84b4f33efad25c33ed8c654ba42c65c9feee8e95f3cb1ec0e31b560692333bdad5e2c35407bc8111f0711b9e71f6d432c8d642e3b954da3d8235d1328d0eb49f11ff9dfcc9635237fa2c30570d92b896aad3068c6677245ca951b4016ea6ac28d061239648dfb722f311191c"
            )
        );
    }

    function test_NativeEncrypt() public pure {
        address userAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address contractAddress = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;
        EncryptedInputSigner memory signer;
        signer.acl = 0x339EcE85B9E11a3A3AA557582784a15d7F82AAf2;
        signer.inputVerifier = 0x69dE3158643e738a0724418b21a35FAA20CBb1c5;
        signer.kmsVerifier = 0x208De73316E44722e16f6dDFF40881A3e4F86104;
        signer.chainId = 31337;
        signer.kmsSigners = new uint256[](1);
        signer.kmsSigners[0] = 0x388b7680e4e1afa06efbfd45cdd1fe39f3c6af381df6555a19661f283b97de91;

        EncryptedInputList memory input;
        input.add64(123456, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);
        input.add32(7890, 0x27ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209);

        (uint256[] memory handles, bytes memory inputProof) = input.encrypt(signer, contractAddress, userAddress);

        assertEq(handles.length, 2);
        assertEq(handles[0], 0x496eb5b6fa3270a6c5482f4854ea0d8d503e865e528d9d51ed245edd3f000500);
        assertEq(handles[1], 0x46ccfd5cedb24d2a0c6e65c4ec6bd143d0bcf69b197186b79e53452ac5010400);
        assertEq(
            inputProof,
            abi.encodePacked(
                hex"0201496eb5b6fa3270a6c5482f4854ea0d8d503e865e528d9d51ed245edd3f00050046ccfd5cedb24d2a0c6e65c4ec6bd143d0bcf69b197186b79e53452ac50104009e71f6d432c8d642e3b954da3d8235d1328d0eb49f11ff9dfcc9635237fa2c30570d92b896aad3068c6677245ca951b4016ea6ac28d061239648dfb722f311191c05000000000001e24027ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae262090400001ed227ecd75f8b48b3c4b6091a31f04b120fa61e0611d6fca0373cac0c0d5ae26209"
            )
        );
    }

    // function log(EncryptedInputSigner memory signer) internal pure {
    //     console.log("chainId: %s", signer.chainId);
    //     console.log("ACL: %s", signer.acl);
    //     console.log("KMSVerifier: %s", signer.kmsVerifier);
    //     console.log("InputVerifier: %s", signer.inputVerifier);
    //     console.log("Coprocessor signer: %s", vm.toString(bytes32(signer.coprocSigner)));
    //     console.log("Num kms signers: %s", signer.kmsSigners.length);
    //     for (uint256 i = 0; i < signer.kmsSigners.length; ++i) {
    //         console.log("kms signer #%s: %s", i, vm.toString(bytes32(signer.kmsSigners[i])));
    //     }
    // }
}
