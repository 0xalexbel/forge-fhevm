// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import {fhevm} from "../fhevm.sol";
import {fhevmEnvAdd} from "./FhevmEnvAddress.sol";
import {FhevmEnv} from "./FhevmEnv.sol";

import {FHEVMConfig} from "fhevm/lib/FHEVMConfig.sol";
import {TFHE} from "fhevm/lib/TFHE.sol";

abstract contract FhevmRuntime {
    FhevmEnv private constant fhevmEnv = FhevmEnv(fhevmEnvAdd);
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function setUpRuntime() public {
        // Note force solidity compiler to link "forge-fhevm/vm/FhevmEnv.sol"
        // No variable to avoid compiler warning
        // The current version of forge fails to run '_privDeployCodeTo(...)' directly
        // because 'vm.getCode(what)' reverts.
        new FhevmEnv();

        _privDeployCodeTo("src/vm/FhevmEnv.sol", "", 0, fhevmEnvAdd);
        vm.assertEq(fhevmEnv.IS_FHEVM_ENV(), true);

        fhevmEnv.initialize(false /* useDeterministicRandomGenerator */ );
        fhevmEnv.deploy();

        // Note Prior to calling any TFHE function, the TFHE library must be initialized
        // by calling "setFHEVM". During the deployment phase, check has been performed
        // to make sure the "FHEVMConfig.defaultConfig()" is consistant.
        // Note This call cannot be performed inside "fhevmEnv" since its purpose is to
        // store data into the contract that will use the TFHE lib.
        TFHE.setFHEVM(FHEVMConfig.defaultConfig());
    }

    /// From StdCheats.sol
    function _privDeployCodeTo(string memory what, bytes memory args, uint256 value, address where) private {
        bytes memory creationCode = vm.getCode(what);
        vm.etch(where, abi.encodePacked(creationCode, args));
        (bool success, bytes memory runtimeBytecode) = where.call{value: value}("");
        require(success, "StdCheats deployCodeTo(string,bytes,uint256,address): Failed to create runtime bytecode.");
        vm.etch(where, runtimeBytecode);
    }
}
