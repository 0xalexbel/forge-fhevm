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
//node /Users/alex/src/github/downloads/fhevmjs-0.5.7/bin/fhevm.js encrypt -n https://devnet.zama.ai 0x5FbDB2315678afecb367f032d93F642f64180aa3 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 3324242:64    
//npx fhevm encrypt 0x5FbDB2315678afecb367f032d93F642f64180aa3 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 
    function test_should_mint_contract() public {
        vm.assertEq(erc20.owner(), signers.aliceAddr());

        vm.broadcast(signers.alice());
        erc20.mint(1000);

        euint64 balanceHandle = erc20.balanceOf(signers.aliceAddr());
        uint64 balance = TFHEvm.decryptU64(balanceHandle, address(erc20), signers.aliceAddr());
        vm.assertEq(balance, 1000);

        uint64 totalSupply = erc20.totalSupply();
        vm.assertEq(totalSupply, 1000);

        console.log("alice=%s", signers.aliceAddr());
        console.log("erc20=%s", address(erc20));
    }

    function test_should_mint_contract_v2() public {
        vm.assertEq(erc20.owner(), signers.aliceAddr());

        vm.broadcast(signers.alice());
        erc20.mint(1000);

        euint64 balanceHandle = erc20.balanceOf(signers.aliceAddr());
        uint64 balance = TFHEvm.decryptU64(balanceHandle, address(erc20), signers.aliceAddr());
        vm.assertEq(balance, 1000);

        uint64 totalSupply = erc20.totalSupply();
        vm.assertEq(totalSupply, 1000);
    }
    /*

    //   it('should mint the contract', async function () {
    //     const transaction = await this.erc20.mint(1000);
    //     await transaction.wait();

    //     // Reencrypt Alice's balance
    //     const balanceHandleAlice = await this.erc20.balanceOf(this.signers.alice);
    //     const { publicKey: publicKeyAlice, privateKey: privateKeyAlice } = this.instances.alice.generateKeypair();
    //     const eip712 = this.instances.alice.createEIP712(publicKeyAlice, this.contractAddress);
    //     const signatureAlice = await this.signers.alice.signTypedData(
    //       eip712.domain,
    //       { Reencrypt: eip712.types.Reencrypt },
    //       eip712.message,
    //     );
    //     const balanceAlice = await this.instances.alice.reencrypt(
    //       balanceHandleAlice,
    //       privateKeyAlice,
    //       publicKeyAlice,
    //       signatureAlice.replace('0x', ''),
    //       this.contractAddress,
    //       this.signers.alice.address,
    //     );
    //     expect(balanceAlice).to.equal(1000);

    //     const totalSupply = await this.erc20.totalSupply();
    //     expect(totalSupply).to.equal(1000);
    //   });

    */

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

    /*

    const userAllowed = await acl.persistAllowed(handle, userAddress);
    const contractAllowed = await acl.persistAllowed(handle, contractAddress);
    if (!isAllowed) {
      throw new Error('User is not authorized to reencrypt this handle!');
    }
    if (userAddress === contractAddress) {
      throw new Error(
        'userAddress should not be equal to contractAddress when requesting reencryption!',
      );
    }
    */

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

// import { expect } from 'chai';

// import { createInstances } from '../instance';
// import { getSigners, initSigners } from '../signers';
// import { deployEncryptedERC20Fixture } from './EncryptedERC20.fixture';

// describe('EncryptedERC20', function () {
//   before(async function () {
//     await initSigners(2);
//     this.signers = await getSigners();
//   });

//   beforeEach(async function () {
//     const contract = await deployEncryptedERC20Fixture();
//     this.contractAddress = await contract.getAddress();
//     this.erc20 = contract;
//     this.instances = await createInstances(this.signers);
//   });

//   it('should mint the contract', async function () {
//     const transaction = await this.erc20.mint(1000);
//     await transaction.wait();

//     // Reencrypt Alice's balance
//     const balanceHandleAlice = await this.erc20.balanceOf(this.signers.alice);
//     const { publicKey: publicKeyAlice, privateKey: privateKeyAlice } = this.instances.alice.generateKeypair();
//     const eip712 = this.instances.alice.createEIP712(publicKeyAlice, this.contractAddress);
//     const signatureAlice = await this.signers.alice.signTypedData(
//       eip712.domain,
//       { Reencrypt: eip712.types.Reencrypt },
//       eip712.message,
//     );
//     const balanceAlice = await this.instances.alice.reencrypt(
//       balanceHandleAlice,
//       privateKeyAlice,
//       publicKeyAlice,
//       signatureAlice.replace('0x', ''),
//       this.contractAddress,
//       this.signers.alice.address,
//     );
//     expect(balanceAlice).to.equal(1000);

//     const totalSupply = await this.erc20.totalSupply();
//     expect(totalSupply).to.equal(1000);
//   });

//   it('should transfer tokens between two users', async function () {
//     const transaction = await this.erc20.mint(10000);
//     const t1 = await transaction.wait();
//     expect(t1?.status).to.eq(1);

//     const input = this.instances.alice.createEncryptedInput(this.contractAddress, this.signers.alice.address);
//     input.add64(1337);
//     const encryptedTransferAmount = await input.encrypt();
//     const tx = await this.erc20['transfer(address,bytes32,bytes)'](
//       this.signers.bob.address,
//       encryptedTransferAmount.handles[0],
//       encryptedTransferAmount.inputProof,
//     );
//     const t2 = await tx.wait();
//     expect(t2?.status).to.eq(1);

//     // Reencrypt Alice's balance
//     const balanceHandleAlice = await this.erc20.balanceOf(this.signers.alice);
//     const { publicKey: publicKeyAlice, privateKey: privateKeyAlice } = this.instances.alice.generateKeypair();
//     const eip712 = this.instances.alice.createEIP712(publicKeyAlice, this.contractAddress);
//     const signatureAlice = await this.signers.alice.signTypedData(
//       eip712.domain,
//       { Reencrypt: eip712.types.Reencrypt },
//       eip712.message,
//     );
//     const balanceAlice = await this.instances.alice.reencrypt(
//       balanceHandleAlice,
//       privateKeyAlice,
//       publicKeyAlice,
//       signatureAlice.replace('0x', ''),
//       this.contractAddress,
//       this.signers.alice.address,
//     );

//     expect(balanceAlice).to.equal(10000 - 1337);

//     // Reencrypt Bob's balance
//     const balanceHandleBob = await this.erc20.balanceOf(this.signers.bob);

//     const { publicKey: publicKeyBob, privateKey: privateKeyBob } = this.instances.bob.generateKeypair();
//     const eip712Bob = this.instances.bob.createEIP712(publicKeyBob, this.contractAddress);
//     const signatureBob = await this.signers.bob.signTypedData(
//       eip712Bob.domain,
//       { Reencrypt: eip712Bob.types.Reencrypt },
//       eip712Bob.message,
//     );
//     const balanceBob = await this.instances.bob.reencrypt(
//       balanceHandleBob,
//       privateKeyBob,
//       publicKeyBob,
//       signatureBob.replace('0x', ''),
//       this.contractAddress,
//       this.signers.bob.address,
//     );

//     expect(balanceBob).to.equal(1337);

//     // on the other hand, Bob should be unable to read Alice's balance
//     try {
//       await this.instances.bob.reencrypt(
//         balanceHandleAlice,
//         privateKeyBob,
//         publicKeyBob,
//         signatureBob.replace('0x', ''),
//         this.contractAddress,
//         this.signers.bob.address,
//       );
//       expect.fail('Expected an error to be thrown - Bob should not be able to reencrypt Alice balance');
//     } catch (error) {
//       expect(error.message).to.equal('User is not authorized to reencrypt this handle!');
//     }

//     // and should be impossible to call reencrypt if contractAddress === userAddress
//     try {
//       const eip712b = this.instances.alice.createEIP712(publicKeyAlice, this.signers.alice.address);
//       const signatureAliceb = await this.signers.alice.signTypedData(
//         eip712b.domain,
//         { Reencrypt: eip712b.types.Reencrypt },
//         eip712b.message,
//       );
//       await this.instances.alice.reencrypt(
//         balanceHandleAlice,
//         privateKeyAlice,
//         publicKeyAlice,
//         signatureAliceb.replace('0x', ''),
//         this.signers.alice.address,
//         this.signers.alice.address,
//       );
//       expect.fail('Expected an error to be thrown - userAddress and contractAddress cannot be equal');
//     } catch (error) {
//       expect(error.message).to.equal(
//         'userAddress should not be equal to contractAddress when requesting reencryption!',
//       );
//     }
//   });

//   it('should not transfer tokens between two users', async function () {
//     const transaction = await this.erc20.mint(1000);
//     await transaction.wait();

//     const input = this.instances.alice.createEncryptedInput(this.contractAddress, this.signers.alice.address);
//     input.add64(1337);
//     const encryptedTransferAmount = await input.encrypt();
//     const tx = await this.erc20['transfer(address,bytes32,bytes)'](
//       this.signers.bob.address,
//       encryptedTransferAmount.handles[0],
//       encryptedTransferAmount.inputProof,
//     );
//     await tx.wait();

//     const balanceHandleAlice = await this.erc20.balanceOf(this.signers.alice);
//     const { publicKey: publicKeyAlice, privateKey: privateKeyAlice } = this.instances.alice.generateKeypair();
//     const eip712 = this.instances.alice.createEIP712(publicKeyAlice, this.contractAddress);
//     const signatureAlice = await this.signers.alice.signTypedData(
//       eip712.domain,
//       { Reencrypt: eip712.types.Reencrypt },
//       eip712.message,
//     );
//     const balanceAlice = await this.instances.alice.reencrypt(
//       balanceHandleAlice,
//       privateKeyAlice,
//       publicKeyAlice,
//       signatureAlice.replace('0x', ''),
//       this.contractAddress,
//       this.signers.alice.address,
//     );

//     expect(balanceAlice).to.equal(1000);

//     // Reencrypt Bob's balance
//     const balanceHandleBob = await this.erc20.balanceOf(this.signers.bob);

//     const { publicKey: publicKeyBob, privateKey: privateKeyBob } = this.instances.bob.generateKeypair();
//     const eip712Bob = this.instances.bob.createEIP712(publicKeyBob, this.contractAddress);
//     const signatureBob = await this.signers.bob.signTypedData(
//       eip712Bob.domain,
//       { Reencrypt: eip712Bob.types.Reencrypt },
//       eip712Bob.message,
//     );
//     const balanceBob = await this.instances.bob.reencrypt(
//       balanceHandleBob,
//       privateKeyBob,
//       publicKeyBob,
//       signatureBob.replace('0x', ''),
//       this.contractAddress,
//       this.signers.bob.address,
//     );

//     expect(balanceBob).to.equal(0);
//   });

//   it('should be able to transferFrom only if allowance is sufficient', async function () {
//     const transaction = await this.erc20.mint(10000);
//     await transaction.wait();

//     const inputAlice = this.instances.alice.createEncryptedInput(this.contractAddress, this.signers.alice.address);
//     inputAlice.add64(1337);
//     const encryptedAllowanceAmount = await inputAlice.encrypt();
//     const tx = await this.erc20['approve(address,bytes32,bytes)'](
//       this.signers.bob.address,
//       encryptedAllowanceAmount.handles[0],
//       encryptedAllowanceAmount.inputProof,
//     );
//     await tx.wait();

//     const bobErc20 = this.erc20.connect(this.signers.bob);
//     const inputBob1 = this.instances.bob.createEncryptedInput(this.contractAddress, this.signers.bob.address);
//     inputBob1.add64(1338); // above allowance so next tx should actually not send any token
//     const encryptedTransferAmount = await inputBob1.encrypt();
//     const tx2 = await bobErc20['transferFrom(address,address,bytes32,bytes)'](
//       this.signers.alice.address,
//       this.signers.bob.address,
//       encryptedTransferAmount.handles[0],
//       encryptedTransferAmount.inputProof,
//     );
//     await tx2.wait();

//     // Decrypt Alice's balance
//     const balanceHandleAlice = await this.erc20.balanceOf(this.signers.alice);
//     const { publicKey: publicKeyAlice, privateKey: privateKeyAlice } = this.instances.alice.generateKeypair();
//     const eip712 = this.instances.alice.createEIP712(publicKeyAlice, this.contractAddress);
//     const signatureAlice = await this.signers.alice.signTypedData(
//       eip712.domain,
//       { Reencrypt: eip712.types.Reencrypt },
//       eip712.message,
//     );
//     const balanceAlice = await this.instances.alice.reencrypt(
//       balanceHandleAlice,
//       privateKeyAlice,
//       publicKeyAlice,
//       signatureAlice.replace('0x', ''),
//       this.contractAddress,
//       this.signers.alice.address,
//     );
//     expect(balanceAlice).to.equal(10000); // check that transfer did not happen, as expected

//     // Decrypt Bob's balance
//     const balanceHandleBob = await this.erc20.balanceOf(this.signers.bob);
//     const { publicKey: publicKeyBob, privateKey: privateKeyBob } = this.instances.bob.generateKeypair();
//     const eip712Bob = this.instances.bob.createEIP712(publicKeyBob, this.contractAddress);
//     const signatureBob = await this.signers.bob.signTypedData(
//       eip712Bob.domain,
//       { Reencrypt: eip712Bob.types.Reencrypt },
//       eip712Bob.message,
//     );
//     const balanceBob = await this.instances.bob.reencrypt(
//       balanceHandleBob,
//       privateKeyBob,
//       publicKeyBob,
//       signatureBob.replace('0x', ''),
//       this.contractAddress,
//       this.signers.bob.address,
//     );
//     expect(balanceBob).to.equal(0); // check that transfer did not happen, as expected

//     const inputBob2 = this.instances.bob.createEncryptedInput(this.contractAddress, this.signers.bob.address);
//     inputBob2.add64(1337); // below allowance so next tx should send token
//     const encryptedTransferAmount2 = await inputBob2.encrypt();
//     const tx3 = await bobErc20['transferFrom(address,address,bytes32,bytes)'](
//       this.signers.alice.address,
//       this.signers.bob.address,
//       encryptedTransferAmount2.handles[0],
//       encryptedTransferAmount2.inputProof,
//     );
//     await tx3.wait();

//     // Decrypt Alice's balance
//     const balanceHandleAlice2 = await this.erc20.balanceOf(this.signers.alice);
//     const balanceAlice2 = await this.instances.alice.reencrypt(
//       balanceHandleAlice2,
//       privateKeyAlice,
//       publicKeyAlice,
//       signatureAlice.replace('0x', ''),
//       this.contractAddress,
//       this.signers.alice.address,
//     );
//     expect(balanceAlice2).to.equal(10000 - 1337); // check that transfer did happen this time

//     // Decrypt Bob's balance
//     const balanceHandleBob2 = await this.erc20.balanceOf(this.signers.bob);
//     const balanceBob2 = await this.instances.bob.reencrypt(
//       balanceHandleBob2,
//       privateKeyBob,
//       publicKeyBob,
//       signatureBob.replace('0x', ''),
//       this.contractAddress,
//       this.signers.bob.address,
//     );
//     expect(balanceBob2).to.equal(1337); // check that transfer did happen this time*/
//   });
// });
