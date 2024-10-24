// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";

contract Signers {
    uint256 public alice;
    address public aliceAddr;

    uint256 public bob;
    address public bobAddr;

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function getMnemonic() public view returns (string memory mnemonic) {
        if (vm.envExists("MNEMONICS")) {
            mnemonic = vm.envString("MNEMONICS");
        } else {
            mnemonic = "test test test test test test test test test test test junk";
        }
    }

    function setUpWallets() public {
        string memory m = getMnemonic();

        Vm.Wallet memory w;
        uint256 alicePk = vm.deriveKey(m, 0);
        w = vm.createWallet(alicePk, "alice");
        alice = w.privateKey;
        aliceAddr = w.addr;

        uint256 bobPk = vm.deriveKey(m, 1);
        w = vm.createWallet(bobPk, "bob");
        bob = w.privateKey;
        bobAddr = w.addr;
    }
}
