// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {console} from "forge-std/src/Console.sol";
import {Test} from "forge-std/src/Test.sol";
import {TFHEvm} from "../src/TFHEvm.sol";
import {ACL} from "fhevm/lib/ACL.sol";

contract TFHEvmTest is Test {
    function setUp() public {
        TFHEvm.setUp();
    }

    function test_ACL() public view {
        ACL acl = TFHEvm.acl();
        vm.assertEq(acl.owner(), TFHEvm.fhevmDeployer());
    }
}
