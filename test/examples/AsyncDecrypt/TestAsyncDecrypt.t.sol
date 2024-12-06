// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";

import {TFHE, euint8, euint64, einput, ebool, ebytes256} from "../../../src/libs/fhevm-debug/lib/TFHE.sol";
import {FhevmDebug} from "../../../src/FhevmDebug.sol";
import {Gateway} from "../../../src/libs/fhevm-debug/gateway/lib/Gateway.sol";

import {FFhevm} from "../../../src/FFhevm.sol";

import {Signers} from "../Signers.sol";
import {TestAsyncDecrypt} from "./TestAsyncDecrypt.sol";
import {TestAsyncDecryptDebug} from "./TestAsyncDecryptDebug.sol";

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
    TestAsyncDecrypt asyncDecrypt;

    function setUp() public {
        FFhevm.setUp();

        signers = new Signers();
        signers.setUpWallets();

        vm.broadcast(signers.alice());
        asyncDecrypt = new TestAsyncDecryptDebug();

        vm.deal(signers.relayerAddr(), 1000 ether);
        vm.deal(signers.aliceAddr(), 1000 ether);
        vm.deal(signers.bobAddr(), 1000 ether);
        vm.deal(signers.carolAddr(), 1000 ether);
    }

    function test_async_decrypt_bool3() public {
        vm.startStateDiffRecording();
        Contract c = new Contract{value: 1 ether}(100);
        Vm.AccountAccess[] memory records = vm.stopAndReturnStateDiff();

        vm.assertEq(records.length, 1);
        //vm.assertEq(records[0].kind, Vm.AccountAccessKind.Create);
        vm.assertEq(records[0].account, address(c));
        vm.assertEq(records[0].accessor, address(this));
        vm.assertEq(records[0].initialized, true);
        vm.assertEq(records[0].oldBalance, 0);
        vm.assertEq(records[0].newBalance, 1 ether);
        vm.assertEq(records[0].deployedCode, address(c).code);
        vm.assertEq(records[0].value, 1 ether);
        // vm.assertEq(records[0].data, abi.encodePacked(type(Contract).creationCode, (uint(100))));
        // vm.assertEq(records[0].reverted, false);

        // vm.assertEq(records[0].storageAccesses.length, 1);
        // vm.assertEq(records[0].storageAccesses[0].account, address(contract));
        // vm.assertEq(records[0].storageAccesses[0].slot, bytes32(uint256(1)));
        // vm.assertEq(records[0].storageAccesses[0].isWrite, true);
        // vm.assertEq(records[0].storageAccesses[0].previousValue, bytes32(uint(0)));
        // vm.assertEq(records[0].storageAccesses[0].newValue, bytes32(uint(100)));
        //         vm.assertEq(records[0].storageAccesses[0].reverted, false);
        // uint256 balanceBeforeR = signers.relayerAddr().balance;
        // console.log("balanceBeforeR=%s", balanceBeforeR);
    }

    function test_async_decrypt_bool2() public {
        uint256 balanceBeforeR = signers.relayerAddr().balance;
        uint256 balanceBeforeU = signers.carolAddr().balance;

        //0x5FbDB2315678afecb367f032d93F642f64180aa3 = address(asyncDecrypt)

        console.log(signers.relayerAddr());
        console.log(signers.carolAddr());
        console.log(signers.aliceAddr());
        console.log(address(asyncDecrypt));

        vm.startBroadcast(signers.carol());
        asyncDecrypt.requestBool(0);
        vm.stopBroadcast();

        uint256 balanceAfterU = signers.carolAddr().balance;

        FFhevm.gatewayFulfillRequests();

        bool yb = asyncDecrypt.yBool();

        vm.assertTrue(yb);

        uint256 balanceAfterR = signers.relayerAddr().balance;

        console.log("gas paid by relayer (fulfill tx) : %s", (balanceBeforeR - balanceAfterR));
        console.log("gas paid by user (request tx) : %s", (balanceBeforeU - balanceAfterU));
    }

    // const balanceBeforeR = await ethers.provider.getBalance(this.relayerAddress);
    // const balanceBeforeU = await ethers.provider.getBalance(this.signers.carol.address);
    // const tx2 = await this.contract.connect(this.signers.carol).requestBool({ gasLimit: 5_000_000 });
    // await tx2.wait();
    // const balanceAfterU = await ethers.provider.getBalance(this.signers.carol.address);
    // await awaitAllDecryptionResults();
    // const y = await this.contract.yBool();
    // expect(y).to.equal(true);
    // const balanceAfterR = await ethers.provider.getBalance(this.relayerAddress);
    // console.log('gas paid by relayer (fulfil tx) : ', balanceBeforeR - balanceAfterR);
    // console.log('gas paid by user (request tx) : ', balanceBeforeU - balanceAfterU);

    function test_async_decrypt4() public {
        euint8 ei1 = TFHE.asEuint8(12);
        euint8 ei2 = TFHE.asEuint8(30);

        euint8 ei3 = TFHE.add(ei1, ei2);

        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(ei3);
        Gateway.requestDecryption(cts, this.callbackUint8.selector, 0, block.timestamp + 100, true);

        cts[0] = Gateway.toUint256(ei1);
        Gateway.requestDecryption(cts, this.callbackUintNoSig.selector, 0, block.timestamp + 100, !true);

        FFhevm.gatewayFulfillRequests();
    }

    function callbackUintNoSig(uint256 requestID, uint8 decryptedInput) public pure {
        vm.assertEq(requestID, 1);
        vm.assertEq(decryptedInput, 12);
    }

    function callbackUint8(uint256 requestID, uint8 decryptedInput, bytes[] memory signatures) public pure {
        vm.assertEq(requestID, 0);
        vm.assertEq(decryptedInput, 30);
        vm.assertTrue(signatures.length > 0);
    }
}
