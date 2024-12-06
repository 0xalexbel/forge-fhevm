// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {console} from "forge-std/src/console.sol";
import {Test} from "forge-std/src/Test.sol";

import {TFHE, euint64, einput, Common} from "fhevm/lib/TFHE.sol";
import {FFhevm} from "ffhevm-forge/FFhevm.sol";

import {Signers} from "../Signers.sol";
import {EncryptedERC20Zama} from "./EncryptedERC20Zama.sol";

contract EncryptedERC20Test is Test {
    EncryptedERC20Zama erc20;
    Signers signers;

    function setUp() public {
        FFhevm.setUp();

        signers = new Signers();
        signers.setUpWallets();

        vm.broadcast(signers.alice());
        erc20 = new EncryptedERC20Zama("Naraggara", "NARA");
    }

    function test_owner() public view {
        vm.assertEq(erc20.owner(), signers.aliceAddr());
    }
}
