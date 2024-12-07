// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/Console.sol";

import {TFHEHandle} from "../src/libs/common/TFHEHandle.sol";
import {AddressLib} from "../src/libs/common/AddressLib.sol";
import {IACL} from "../src/libs/core/interfaces/IACL.sol";
import {ITFHEExecutor} from "../src/libs/core/interfaces/ITFHEExecutor.sol";
import {IInputVerifier} from "../src/libs/core/interfaces/IInputVerifier.sol";
import {IKMSVerifier} from "../src/libs/core/interfaces/IKMSVerifier.sol";

import "configs/sepolia/addresses.sol" as ADDRESSES;

contract GetDeployedCodeTest is Test {
    IACL public acl;
    IKMSVerifier public kmsVerifier;
    function setUp() public {
        acl = IACL(ADDRESSES.ACL_ADDRESS);
        kmsVerifier = IKMSVerifier(ADDRESSES.KMS_VERIFIER_ADDRESS);
    }
    function test_getDeployedCode() public view {
        // string memory version = acl.getVersion();
        // console.log("version=%s", version);
        bool ok = vm.envExists("FOUNDRY_ETH_RPC_URL");
        console.log("version=%s", ok);
        uint256 a = vm.activeFork();
        console.log("version=%s", a);
        console.log("version=%s", vm.getBlockNumber());

        address[] memory signers = kmsVerifier.getSigners();
        console.log("signers.length = %s", signers.length);
        for(uint256 i = 0; i < signers.length; ++i) {
            console.log("signers[%s] = %s", i, signers[i]);
        }

        console.log("signer 0 = %s", vm.addr(0x388b7680e4e1afa06efbfd45cdd1fe39f3c6af381df6555a19661f283b97de91));
        /*

    signers[0] = 0x71B1158E113a562CcDaE6a2d46Dd1a3a58f44F5b
    signers[1] = 0x11Cc32eeF6D93F0d9ae585A580fc0435c632bedB
    signers[2] = 0xdE8334f9B52FE21Bef939b6e1618F9E001D35187
    signers[3] = 0x390981c300b73935055C381d5C9a6a9f57884a34

        */
        //getSigners
        //https://sepolia.infura.io/v3/dd9e8f25088c4e49bc5a371bf43ea17d
    }
}
