// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {console} from "forge-std/src/Console.sol";
import {Test} from "forge-std/src/Test.sol";
import {Common} from "fhevm/lib/TFHE.sol";
import {DBLib} from "../src/db/DB.sol";
import {BytesLib} from "../src/utils/BytesLib.sol";

contract DBTest is Test {
    DBLib.Set db;

    using DBLib for DBLib.Set;

    function setUp() public {}

    function test_Add() public pure {
        
    }
}
