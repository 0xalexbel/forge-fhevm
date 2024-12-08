// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";

import {TFHE, euint8, euint64, einput, ebool, ebytes256} from "../../../src/libs/fhevm-debug/lib/TFHE.sol";
import {FhevmDebug} from "../../../src/FhevmDebug.sol";
import {Gateway} from "../../../src/libs/fhevm-debug/gateway/lib/Gateway.sol";

import {FFhevm, EncryptedInput} from "../../../src/FFhevm.sol";

import {Signers} from "../Signers.sol";
import {TestAsyncDecrypt} from "./TestAsyncDecrypt.sol";

contract Contract {
    uint256 internal _reserved;
    uint256 public data;

    constructor(uint256 _data) payable {
        data = _data;
    }
}

contract TestAsyncDecryptTest is Test {
    uint256 requestCount;
    Signers signers;
    TestAsyncDecrypt theContract;

    function setUp() public {
        FFhevm.setUp();

        signers = new Signers();
        signers.setUpWallets();

        vm.broadcast(signers.alice());
        theContract = new TestAsyncDecrypt();

        vm.deal(signers.relayerAddr(), 1000 ether);
        vm.deal(signers.aliceAddr(), 1000 ether);
        vm.deal(signers.bobAddr(), 1000 ether);
        vm.deal(signers.carolAddr(), 1000 ether);
    }

    function test_async_decrypt_bool() public {
        vm.startBroadcast(signers.carol());
        theContract.requestBool(0);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertTrue(theContract.yBool());
    }

    function test_async_decrypt_trustless() public {
        theContract.requestBoolTrustless();

        FFhevm.gatewayFulfillRequests();

        vm.assertTrue(theContract.yBool());
    }

    function test_async_decrypt_fail_max_timestamp_above_1_day() public {
        vm.startBroadcast(signers.carol());
        vm.expectRevert("maxTimestamp exceeded MAX_DELAY");
        theContract.requestBoolAboveDelay();
        vm.stopBroadcast();
    }

    function test_async_decrypt_uint4() public {
        vm.startBroadcast(signers.carol());
        theContract.requestUint4();
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yUint4(), 4);
    }

    function test_async_decrypt_uint8() public {
        vm.startBroadcast(signers.carol());
        theContract.requestUint8();
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yUint8(), 42);
    }

    function test_async_decrypt_uint16() public {
        vm.startBroadcast(signers.carol());
        theContract.requestUint16();
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yUint16(), 16);
    }

    function test_async_decrypt_uint32() public {
        vm.startBroadcast(signers.carol());
        theContract.requestUint32(5, 15);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        // 52 = 5+15+32
        vm.assertEq(theContract.yUint32(), 52);
    }

    function test_async_decrypt_uint64() public {
        vm.startBroadcast(signers.carol());
        theContract.requestUint64();
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yUint64(), 18446744073709551600);
    }

    function test_async_decrypt_uint128() public {
        vm.startBroadcast(signers.carol());
        theContract.requestUint128();
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yUint128(), 1267650600228229401496703205443);
    }

    function test_async_decrypt_uint128_non_trivial() public {
        EncryptedInput memory inputAlice = FFhevm.createEncryptedInput(address(theContract), signers.aliceAddr());
        inputAlice.add128(184467440737095500429401496);
        (einput[] memory handles, bytes memory inputProof) = inputAlice.encrypt();

        vm.startBroadcast(signers.alice());
        theContract.requestUint128NonTrivial(handles[0], inputProof);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yUint128(), 184467440737095500429401496);
    }

    function test_async_decrypt_uint256() public {
        vm.startBroadcast(signers.carol());
        theContract.requestUint256();
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yUint256(), 27606985387162255149739023449108101809804435888681546220650096895197251);
    }

    function test_async_decrypt_uint256_non_trivial() public {
        EncryptedInput memory inputAlice = FFhevm.createEncryptedInput(address(theContract), signers.aliceAddr());
        inputAlice.add256(6985387162255149739023449108101809804435888681546);
        (einput[] memory handles, bytes memory inputProof) = inputAlice.encrypt();

        vm.startBroadcast(signers.alice());
        theContract.requestUint256NonTrivial(handles[0], inputProof);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yUint256(), 6985387162255149739023449108101809804435888681546);
    }

    function test_async_decrypt_address() public {
        vm.startBroadcast(signers.carol());
        theContract.requestAddress();
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yAddress(), 0x8ba1f109551bD432803012645Ac136ddd64DBA72);
    }

    function test_async_decrypt_several_addresses() public {
        vm.startBroadcast(signers.carol());
        theContract.requestSeveralAddresses();
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yAddress(), 0x8ba1f109551bD432803012645Ac136ddd64DBA72);
        vm.assertEq(theContract.yAddress2(), 0xf48b8840387ba3809DAE990c930F3b4766A86ca3);
    }

    function test_async_decrypt_mixed() public {
        vm.startBroadcast(signers.carol());
        theContract.requestMixed(5, 15);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertTrue(theContract.yBool());
        vm.assertEq(theContract.yUint4(), 4);
        vm.assertEq(theContract.yUint8(), 42);
        vm.assertEq(theContract.yUint16(), 16);
        vm.assertEq(theContract.yAddress(), 0x8ba1f109551bD432803012645Ac136ddd64DBA72);
        vm.assertEq(theContract.yUint32(), 52);
        vm.assertEq(theContract.yUint64(), 18446744073709551600);
    }

    function test_async_decrypt_uint64_non_trivial() public {
        EncryptedInput memory inputAlice = FFhevm.createEncryptedInput(address(theContract), signers.aliceAddr());
        inputAlice.add64(18446744073709550042);
        (einput[] memory handles, bytes memory inputProof) = inputAlice.encrypt();

        vm.startBroadcast(signers.alice());
        theContract.requestUint64NonTrivial(handles[0], inputProof);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yUint64(), 18446744073709550042);
    }

    function test_async_decrypt_ebytes64_trivial() public {
        bytes memory aBytes64 = bytes.concat(bytes4(0x78685689));

        vm.startBroadcast(signers.carol());
        theContract.requestEbytes64Trivial(aBytes64);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yBytes64(), TFHE.padToBytes64(aBytes64));
    }

    function test_async_decrypt_ebytes64_non_trivial() public {
        bytes memory aBytes64 = TFHE.padToBytes64(abi.encodePacked(
            hex"1da9da96e0fd8fe4f9ae108c5d9149e0f24c097f9a7af0c362be6e44728601017b2f"
        ));
        vm.assertEq(aBytes64.length, 64);

        EncryptedInput memory inputAlice = FFhevm.createEncryptedInput(address(theContract), signers.aliceAddr());
        inputAlice.addBytes64(aBytes64);
        (einput[] memory handles, bytes memory inputProof) = inputAlice.encrypt();

        vm.startBroadcast(signers.alice());
        theContract.requestEbytes64NonTrivial(handles[0], inputProof);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yBytes64(), aBytes64);
    }

    function test_async_decrypt_ebytes128_trivial() public {
        bytes memory aBytes128 = TFHE.padToBytes128(abi.encodePacked(
            hex"8701d11594415047dfac2d9cb87e6631df5a735a2f364fba1511fa7b812dfad2972b809b80ff25ec19591a598081af357cba384cf5aa8e085678ff70bc55faee"
        ));
        vm.assertEq(aBytes128.length, 128);

        vm.startBroadcast(signers.carol());
        theContract.requestEbytes128Trivial(aBytes128);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yBytes128(), aBytes128);
    }

    function test_async_decrypt_ebytes128_non_trivial() public {
        bytes memory aBytes128 = TFHE.padToBytes128(abi.encodePacked(
            hex"8701d11594415047dfac2d9cb87e6631df5a735a2f364fba1511fa7b812dfad2972b809b80ff25ec19591a598081af357cba384cf5aa8e085678ff70bc55faee"
        ));
        vm.assertEq(aBytes128.length, 128);

        EncryptedInput memory inputAlice = FFhevm.createEncryptedInput(address(theContract), signers.aliceAddr());
        inputAlice.addBytes128(aBytes128);
        (einput[] memory handles, bytes memory inputProof) = inputAlice.encrypt();

        vm.startBroadcast(signers.alice());
        theContract.requestEbytes128NonTrivial(handles[0], inputProof);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yBytes128(), aBytes128);
    }

    function test_async_decrypt_ebytes256_trivial() public {
        bytes memory aBytes256 = TFHE.padToBytes256(abi.encodePacked(
            hex"78685689"
        ));
        vm.assertEq(aBytes256.length, 256);

        vm.startBroadcast(signers.carol());
        theContract.requestEbytes256Trivial(aBytes256);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yBytes256(), aBytes256);
    }

    function test_async_decrypt_ebytes256_non_trivial() public {
        bytes memory aBytes256 = TFHE.padToBytes256(bytes.concat(bytes32(uint256(18446744073709550022))));
        vm.assertEq(aBytes256.length, 256);

        EncryptedInput memory inputAlice = FFhevm.createEncryptedInput(address(theContract), signers.aliceAddr());
        inputAlice.addBytes256(aBytes256);
        (einput[] memory handles, bytes memory inputProof) = inputAlice.encrypt();

        vm.startBroadcast(signers.alice());
        theContract.requestEbytes256NonTrivial(handles[0], inputProof);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yBytes256(), aBytes256);
    }

    function test_async_decrypt_mixed_ebytes256() public {
        bytes memory aBytes256 = TFHE.padToBytes256(bytes.concat(bytes32(uint256(18446744073709550022))));
        vm.assertEq(aBytes256.length, 256);

        EncryptedInput memory inputAlice = FFhevm.createEncryptedInput(address(theContract), signers.aliceAddr());
        inputAlice.addBytes256(aBytes256);
        (einput[] memory handles, bytes memory inputProof) = inputAlice.encrypt();

        vm.startBroadcast(signers.alice());
        theContract.requestMixedBytes256(handles[0], inputProof);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yBytes256(), aBytes256);
        vm.assertEq(theContract.yBytes64(), TFHE.padToBytes64(bytes.concat(bytes3(0xaaff42))));
        vm.assertTrue(theContract.yBool());
        vm.assertEq(theContract.yAddress(), address(0x8ba1f109551bD432803012645Ac136ddd64DBA72));
    }

    function test_async_decrypt_ebytes256_non_trivial_trustless() public {
        bytes memory aBytes256 = TFHE.padToBytes256(bytes.concat(bytes32(uint256(18446744073709550022))));
        vm.assertEq(aBytes256.length, 256);

        EncryptedInput memory inputAlice = FFhevm.createEncryptedInput(address(theContract), signers.aliceAddr());
        inputAlice.addBytes256(aBytes256);
        (einput[] memory handles, bytes memory inputProof) = inputAlice.encrypt();

        vm.startBroadcast(signers.alice());
        theContract.requestEbytes256NonTrivialTrustless(handles[0], inputProof);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yBytes256(), aBytes256);
    }

    function test_async_decrypt_ebytes256_trustless() public {
        bytes memory aBytes256 = TFHE.padToBytes256(bytes.concat(bytes32(uint256(18446744073709550032))));
        vm.assertEq(aBytes256.length, 256);

        EncryptedInput memory inputAlice = FFhevm.createEncryptedInput(address(theContract), signers.aliceAddr());
        inputAlice.addBytes256(aBytes256);
        (einput[] memory handles, bytes memory inputProof) = inputAlice.encrypt();

        vm.startBroadcast(signers.alice());
        theContract.requestMixedBytes256Trustless(handles[0], inputProof);
        vm.stopBroadcast();

        FFhevm.gatewayFulfillRequests();

        vm.assertEq(theContract.yBytes256(), aBytes256);
        vm.assertTrue(theContract.yBool());
        vm.assertEq(theContract.yAddress(), address(0x8ba1f109551bD432803012645Ac136ddd64DBA72));
    }























    function test_async_decrypt_bool3() public {
        vm.startStateDiffRecording();
        Contract c = new Contract{value: 1 ether}(100);
        Vm.AccountAccess[] memory records = vm.stopAndReturnStateDiff();

        vm.assertEq(records.length, 1);
        vm.assertEq(records[0].account, address(c));
        vm.assertEq(records[0].accessor, address(this));
        vm.assertEq(records[0].initialized, true);
        vm.assertEq(records[0].oldBalance, 0);
        vm.assertEq(records[0].newBalance, 1 ether);
        vm.assertEq(records[0].deployedCode, address(c).code);
        vm.assertEq(records[0].value, 1 ether);
    }

    function test_async_decrypt_bool2() public {
        uint256 balanceBeforeR = signers.relayerAddr().balance;
        uint256 balanceBeforeU = signers.carolAddr().balance;

        //0x5FbDB2315678afecb367f032d93F642f64180aa3 = address(asyncDecrypt)

        console.log(signers.relayerAddr());
        console.log(signers.carolAddr());
        console.log(signers.aliceAddr());
        console.log(address(theContract));

        vm.startBroadcast(signers.carol());
        theContract.requestBool(0);
        vm.stopBroadcast();

        uint256 balanceAfterU = signers.carolAddr().balance;

        FFhevm.gatewayFulfillRequests();

        bool yb = theContract.yBool();

        vm.assertTrue(yb);

        uint256 balanceAfterR = signers.relayerAddr().balance;

        console.log("gas paid by relayer (fulfill tx) : %s", (balanceBeforeR - balanceAfterR));
        console.log("gas paid by user (request tx) : %s", (balanceBeforeU - balanceAfterU));
    }

    function test_async_decrypt_local() public {
        euint8 ei1 = TFHE.asEuint8(12);
        euint8 ei2 = TFHE.asEuint8(30);

        euint8 ei3 = TFHE.add(ei1, ei2);

        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(ei3);
        Gateway.requestDecryption(cts, this.callbackUint8WithSig.selector, 0, block.timestamp + 100, true);

        cts[0] = Gateway.toUint256(ei1);
        Gateway.requestDecryption(cts, this.callbackUintNoSig.selector, 0, block.timestamp + 100, false);

        FFhevm.gatewayFulfillRequests();
    }

    function callbackUintNoSig(uint256 requestID, uint8 decryptedInput) public pure {
        vm.assertEq(requestID, 1);
        vm.assertEq(decryptedInput, 12);
    }

    function callbackUint8WithSig(uint256 requestID, uint8 decryptedInput, bytes[] memory signatures) public pure {
        vm.assertEq(requestID, 0);
        vm.assertEq(decryptedInput, 42);
        vm.assertTrue(signatures.length > 0);
    }
}
