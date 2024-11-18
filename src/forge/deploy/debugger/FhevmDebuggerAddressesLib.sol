// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {tfheDebuggerAdd} from "../../../debug/addresses/TFHEDebuggerAddress.sol";

import {AddressLib} from "../../utils/AddressLib.sol";

/// Note: forge does not handle libraries very well in a script setUp context.
/// Therefore, solidity code like this one is deployed as a contract instead of a library
library FhevmDebuggerAddressesLib {
    uint8 private constant TFHEDebuggerNonce = 0;

    /// Returns a single address:
    /// - the 'TFHEDebugger' contract address
    /// Fails if the 'TFHEDebugger' contact address differs from the value of 'tfheExecutorDBAdd' stored in
    /// the 'fhevm/lib/TFHEDebuggerAddress.sol' solidity file.
    function expectedCreateTFHEDebuggerAddress(address deployerAddr) internal pure returns (address expectedAddr) {
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, TFHEDebuggerNonce);

        require(
            tfheDebuggerAdd == expectedAddr,
            "TFHEDebugger contract address differs from its expected create address. Address solidity files must be regenerated."
        );
    }

    function computeCreateTFHEDebuggerAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, TFHEDebuggerNonce);
    }
}
