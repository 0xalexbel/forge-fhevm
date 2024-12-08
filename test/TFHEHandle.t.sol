// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";

import {TFHEHandle} from "../src/libs/common/TFHEHandle.sol";

contract Foo {
    uint256 private _chainId;
    address private _aclAddress;

    constructor(uint256 chainId, address aclAddress) {
        _chainId = chainId;
        _aclAddress = aclAddress;
    }
}

contract TFHEHandleTest is Test {
    Foo foo;

    // function setUp() public {
    //     foo = new Foo(31337, 0x339EcE85B9E11a3A3AA557582784a15d7F82AAf2);
    // }

    // //forge test ./test/euint8.v2.t.sol --match-test test_AsEUint8 -vv
    // function test_precompute() public view {
    //     vm.assume(block.chainid == 31337);

    //     uint256 expectedHandle = 26596934688998226891527048613891156932770140149132685132958134307124587266560;
    //     address aclAddr = 0x339EcE85B9E11a3A3AA557582784a15d7F82AAf2;

    //     uint256 handle = TFHEHandle.precomputeTrivialEncrypt(128, TFHEHandle.euint8_t, aclAddr);
    //     vm.assertEq(handle, expectedHandle);
    // }

    // function test_is256Bits() public view {
    //     vm.assume(block.chainid == 31337);

    //     uint256 g = 0;
    //     uint256 handle = 26596934688998226891527048613891156932770140149132685132958134307124587266560;
    //     for (uint256 i = 0; i < 1000; ++i) {
    //         uint256 g1 = gasleft();

    //         TFHEHandle.checkIs256Bits(handle);

    //         uint256 g2 = gasleft();

    //         g += (g1 - g2);
    //     }

    //     console.log("gas = %s", g / 1000);
    // }

    // function copyBytes1() {
    //     bytes memory arr = new bytes(65);
    //     for (uint256 i = 0; i < 65; i++) {
    //         arr[i] = inputProof[99 + 32 * numHandles + i];
    //     }

    // }

    function test_typeOf() public view {
        // uint256(BytesLib.bytesToBytes32(self._data, 0 * 32 + 1));
        uint256 numHandles = 2;
        bytes memory arr1 = new bytes(99 + 32 * numHandles + 65 + 32);
        for (uint256 i = 0; i < arr1.length; ++i) {
            //uint256 a = i % type(uint8).max;
            //uint8 a = uint8(i % type(uint8).max);
            arr1[i] = bytes1(uint8(i % type(uint8).max));
        }

        bytes memory arr2 = new bytes(65);
        uint256 offset = 99 + 32 * numHandles;

        for (uint256 i = 0; i < offset; ++i) {
            arr1[i] = bytes1(0x00);
        }
        for (uint256 i = offset + 65; i < arr1.length; ++i) {
            arr1[i] = bytes1(0x00);
        }

        uint256 g = 0;
        for (uint256 i = 0; i < 10000; ++i) {
            uint256 g1 = gasleft();
            assembly ("memory-safe") {
                mcopy(add(arr2, add(0x20, 0)), add(arr1, add(0x20, offset)), 65)
            }
            uint256 g2 = gasleft();
            g += (g1 - g2);
        }

        console.log("g = %s", g / 10000);

        g = 0;
        for (uint256 i = 0; i < 10000; ++i) {
            uint256 g1 = gasleft();
            for (uint256 j = 0; j < 65; ++j) {
                arr2[j] = arr1[j + offset];
            }
            uint256 g2 = gasleft();
            g += (g1 - g2);
        }

        console.log("g = %s", g / 10000);

        // console.logBytes(arr1);
        // console.logBytes(arr2);

        // assembly ("memory-safe") {
        //     value := mload(add(buffer, add(0x20, offset)))
        // }

        // uint256 g = 0;
        // uint256 handle = 26596934688998226891527048613891156932770140149132685132958134307124587266560;
        // uint8 typeCt;
        // for (uint256 i = 0; i < 1000; ++i) {
        //     uint256 g1 = gasleft();

        //     typeCt = TFHEHandle.typeOf(handle);

        //     uint256 g2 = gasleft();

        //     g += (g1 - g2);
        // }

        // console.log("gas = %s", g / 1000);
        // vm.assertEq(typeCt, TFHEHandle.euint8_t);

        // //bytes32 bb = keccak256(abi.encode(uint256(keccak256("ffhevm.storage.FFHEVMDebuggerConfig")) - 1)) & ~bytes32(uint256(0xff));
        // //console.logBytes32(bb);
        // // 0xf2caf1b49a8f33e5a95fc55b0903daddd261d5a874ff154dc5d809a5f1c90449
        // bytes32 aa = keccak256(bytes("ffhevm.debugger.wallet"));
        // aa = 0xf2caf1b49a8f33e5a95fc55b0903daddd261d5a874ff154dc5d809a5f1c90449;
        // //0x5ac50c17c0e2ad3ef6d55c6b2d6ed7a68cd3b07af7d9a2ae8bd56295d64d319a
        // console.logBytes32(aa);
        // //41056308705603460901123179279511314825612252420026240603403308022489290715546
        // console.log(uint256(aa));
        // //0x5e85529F07A87868b853fda7eB518Ce1B6f58B92
        // console.logAddress(vm.addr(uint256(aa)));

        /*
        0xcb6E1F65B0d49Ba8aF68029ad271257a4E36f8b2
    0x0B572Ad50a12FA2C01733dA2E96968961c75Ca25
    0x92E129448e84188a8ba81c690bD464fe09C23005
    0xc12571f450aB1E45ecd1995b4ecA9360C7924391
    0x365e62c5993a21Ac8412e8470edc1caa59396C24
    0xd97818945Dc689325c36b7095F38587d4279F387
    0x82C6F1fe2D73472d05A650f92781eD202ffed213
    0x19186195b33E0C8AFd4E51F64B6D73D1328d8C99
    0x1fef0CC8ebDC2D3708eE973C1bfB47e2727E8CB2
    0x8398C8B035743DDD4C6035E2C0fd27ee1C25CD34
    0x81952f5e84Cde14eBc19C0072861B6078E7C8D29



        0x0B572Ad50a12FA2C01733dA2E96968961c75Ca25
    0x92E129448e84188a8ba81c690bD464fe09C23005
    0xc12571f450aB1E45ecd1995b4ecA9360C7924391
    0x365e62c5993a21Ac8412e8470edc1caa59396C24
    0xd97818945Dc689325c36b7095F38587d4279F387
    0x82C6F1fe2D73472d05A650f92781eD202ffed213
    0x19186195b33E0C8AFd4E51F64B6D73D1328d8C99
    0x1fef0CC8ebDC2D3708eE973C1bfB47e2727E8CB2
    0x8398C8B035743DDD4C6035E2C0fd27ee1C25CD34
    0x81952f5e84Cde14eBc19C0072861B6078E7C8D29
        */
        // for (uint256 i = 0; i < 10; ++i) {
        //     console.logAddress(vm.computeCreateAddress(0x5e85529F07A87868b853fda7eB518Ce1B6f58B92, i));
        // }
    }
}
