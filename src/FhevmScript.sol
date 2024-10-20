// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script} from "forge-std/src/Script.sol";
import {FhevmRuntime} from "./vm/FhevmRuntime.sol";

abstract contract FhevmScript is Script, FhevmRuntime {
    function setUp() public virtual {
        FhevmRuntime.setUpRuntime();
    }
}
