// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {FFhevm} from "../../../FFhevm.sol";

interface IFFhevmBase {
    function getConfig() external returns (FFhevm.Config memory config);
    function isCoprocessor() external returns (bool);
}
