// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {FhevmRuntime} from "./vm/FhevmRuntime.sol";

abstract contract FhevmTest is Test, FhevmRuntime {
    function setUp() public virtual {
        FhevmRuntime.setUpRuntime();
    }
}
