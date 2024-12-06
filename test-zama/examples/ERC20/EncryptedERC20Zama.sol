// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {EncryptedERC20} from "./EncryptedERC20.sol";
import {MockZamaFHEVMConfig} from "./FHEVMConfig.sol";

contract EncryptedERC20Zama is MockZamaFHEVMConfig, EncryptedERC20 {
    constructor(string memory name_, string memory symbol_) EncryptedERC20(name_, symbol_) {
        //
    }
}
