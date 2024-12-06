// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {EncryptedERC20} from "./EncryptedERC20.sol";
import {DefaultFFHEVMDebugConfig} from "../../../src/libs/fhevm-debug/config/FFHEVMDebugConfig.sol";

contract EncryptedERC20Debug is DefaultFFHEVMDebugConfig, EncryptedERC20 {
    constructor(string memory name_, string memory symbol_) EncryptedERC20(name_, symbol_) {
        //
    }
}
