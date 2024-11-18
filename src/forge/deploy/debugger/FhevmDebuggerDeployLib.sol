// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {TFHEDebugger} from "../../../debug/debugger/TFHEDebugger.sol";
import {IRandomGenerator} from "../../../common/interfaces/IRandomGenerator.sol";

import {FhevmDebuggerAddressesLib} from "./FhevmDebuggerAddressesLib.sol";

library FhevmDebuggerDeployLib {
    struct FhevmDebuggerDeployment {
        address TFHEDebuggerAddress;
    }

    /// Deploy a new set of fhevm contracts
    function deployFhevmDebugger(address deployerAddr, address randomGeneratorAddress)
        internal
        returns (FhevmDebuggerDeployment memory)
    {
        FhevmDebuggerDeployment memory res;

        TFHEDebugger _tfheDebuggerDB = deployTFHEDebugger(deployerAddr, randomGeneratorAddress);

        res.TFHEDebuggerAddress = address(_tfheDebuggerDB);

        return res;
    }

    /// Deploy a new TFHEDebugger contract using the specified deployer wallet
    function deployTFHEDebugger(address deployerAddr, address randomGeneratorAddress)
        private
        returns (TFHEDebugger)
    {
        address expectedAddr = FhevmDebuggerAddressesLib.expectedCreateTFHEDebuggerAddress(deployerAddr);

        TFHEDebugger _tfheDebuggerDB = new TFHEDebugger(deployerAddr, randomGeneratorAddress, true);
        require(address(_tfheDebuggerDB) == expectedAddr, "deployTFHEDebugger: unexpected contract deploy address");

        return _tfheDebuggerDB;
    }
}
