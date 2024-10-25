// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {console} from "forge-std/src/console.sol";
import {Test} from "forge-std/src/Test.sol";
import {TFHEvm, ArithmeticCheckingMode} from "../../src/TFHEvm.sol";
import {EncryptedInput} from "../../src/encrypted-input/EncryptedInput.sol";

import {TFHE, euint64, einput, Common} from "../../lib/TFHE.sol";

import {Signers} from "./Signers.sol";
import {EncryptedERC20} from "./EncryptedERC20.sol";

contract EncryptedERC20Test is Test {
    EncryptedERC20 erc20;
    Signers signers;

    function setUp() public {
        TFHEvm.setUp();

        signers = new Signers();
        signers.setUpWallets();

        vm.broadcast(signers.alice());
        erc20 = new EncryptedERC20("Naraggara", "NARA");
    }

    function test_should_mint_contract() public {
        vm.assertEq(erc20.owner(), signers.aliceAddr());

        vm.broadcast(signers.alice());
        erc20.mint(1000);

        euint64 balanceHandle = erc20.balanceOf(signers.aliceAddr());
        uint64 balance = TFHEvm.decryptU64(balanceHandle, address(erc20), signers.aliceAddr());
        vm.assertEq(balance, 1000);

        uint64 totalSupply = erc20.totalSupply();
        vm.assertEq(totalSupply, 1000);
    }

    function test_should_transfer_tokens_between_two_users() public {
        address aliceAddr = signers.aliceAddr();
        address bobAddr = signers.bobAddr();

        vm.assertEq(erc20.owner(), aliceAddr);

        vm.broadcast(signers.alice());
        erc20.mint(10000);

        euint64 balanceHandleAlice = erc20.balanceOf(aliceAddr);
        TFHEvm.assertArithmeticallyValid(balanceHandleAlice);

        (einput inputHandle, bytes memory inputProof) = TFHEvm.encryptU64(1337, address(erc20), aliceAddr);

        vm.broadcast(signers.alice());
        erc20.transfer(bobAddr, inputHandle, inputProof);

        // Decrypt Alice's balance
        balanceHandleAlice = erc20.balanceOf(aliceAddr);
        TFHEvm.assertArithmeticallyValid(balanceHandleAlice);

        uint64 balanceAlice = TFHEvm.decryptU64(balanceHandleAlice, address(erc20), aliceAddr);
        vm.assertEq(balanceAlice, 10000 - 1337);

        // Decrypt Bob's balance
        euint64 balanceHandleBob = erc20.balanceOf(bobAddr);
        uint64 balanceBob = TFHEvm.decryptU64(balanceHandleBob, address(erc20), bobAddr);
        vm.assertEq(balanceBob, 1337);
    }

    function test_should_not_transfer_tokens_between_two_users() public {
        address aliceAddr = signers.aliceAddr();
        address bobAddr = signers.bobAddr();

        vm.assertEq(erc20.owner(), aliceAddr);

        vm.broadcast(signers.alice());
        erc20.mint(1000);

        (einput inputHandle, bytes memory inputProof) = TFHEvm.encryptU64(1337, address(erc20), aliceAddr);

        vm.broadcast(signers.alice());
        erc20.transfer(bobAddr, inputHandle, inputProof);

        // Decrypt Alice's balance
        euint64 balanceHandleAlice = erc20.balanceOf(aliceAddr);
        uint64 balanceAlice = TFHEvm.decryptU64(balanceHandleAlice, address(erc20), aliceAddr);
        vm.assertEq(balanceAlice, 1000);

        // Decrypt Bob's balance
        euint64 balanceHandleBob = erc20.balanceOf(bobAddr);
        uint64 balanceBob = TFHEvm.decryptU64(balanceHandleBob, address(erc20), bobAddr);
        vm.assertEq(balanceBob, 0);
    }

    function reencryptU64(euint64 handle, address contractAddress, uint256 userPk, address userAddress)
        private
        returns (uint64 clearValue)
    {
        (bytes memory publicKey, bytes memory privateKey) = TFHEvm.generateKeyPair();
        bytes32 eip712 = TFHEvm.createEIP712Digest(publicKey, contractAddress);
        bytes memory signature = TFHEvm.sign(eip712, userPk);
        clearValue = TFHEvm.reencryptU64(handle, privateKey, publicKey, signature, contractAddress, userAddress);
    }

    function test_should_be_able_to_transferFrom_only_if_allowance_is_sufficient() public {
        address aliceAddr = signers.aliceAddr();
        address bobAddr = signers.bobAddr();

        vm.assertEq(erc20.owner(), aliceAddr);

        vm.broadcast(signers.alice());
        erc20.mint(10000);

        bytes memory proof;
        einput encAmount;

        // Alice approves Bob, amount: 1337
        (encAmount, proof) = TFHEvm.encryptU64(1337, address(erc20), aliceAddr);

        vm.broadcast(signers.alice());
        erc20.approve(bobAddr, encAmount, proof);

        // Bob transfers from Alice, amount: 1338
        (encAmount, proof) = TFHEvm.encryptU64(1338, address(erc20), bobAddr);

        vm.broadcast(signers.bob());
        erc20.transferFrom(aliceAddr, bobAddr, encAmount, proof);

        // Decrypt Alice's balance
        euint64 balanceHandleAlice = erc20.balanceOf(aliceAddr);
        uint64 balanceAlice = TFHEvm.decryptU64(balanceHandleAlice, address(erc20), aliceAddr);
        // check that transfer did not happen, as expected
        vm.assertEq(balanceAlice, 10000);

        // Decrypt Bob's balance
        euint64 balanceHandleBob = erc20.balanceOf(bobAddr);
        uint64 balanceBob = TFHEvm.decryptU64(balanceHandleBob, address(erc20), bobAddr);
        // check that transfer did not happen, as expected
        vm.assertEq(balanceBob, 0);

        // Bob transfers from Alice, amount: 1337
        (encAmount, proof) = TFHEvm.encryptU64(1337, address(erc20), bobAddr);

        vm.broadcast(signers.bob());
        erc20.transferFrom(aliceAddr, bobAddr, encAmount, proof);

        // Decrypt Alice's balance
        balanceHandleAlice = erc20.balanceOf(aliceAddr);
        balanceAlice = TFHEvm.decryptU64(balanceHandleAlice, address(erc20), aliceAddr);
        // check that transfer did actually happen, as expected
        vm.assertEq(balanceAlice, 10000 - 1337);

        // Decrypt Bob's balance
        balanceHandleBob = erc20.balanceOf(bobAddr);
        balanceBob = TFHEvm.decryptU64(balanceHandleBob, address(erc20), bobAddr);
        // check that transfer did actually happen, as expected
        vm.assertEq(balanceBob, 1337);

        balanceBob = reencryptU64(balanceHandleBob, address(erc20), signers.bob(), bobAddr);
        vm.assertEq(balanceBob, 1337);
    }
}
