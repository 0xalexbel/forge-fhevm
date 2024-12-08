// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {IFhevmDebuggerDB} from "./IFhevmDebuggerDB.sol";

interface IFhevmDebugger {
    enum ArithmeticCheckMode {
        OperandsOnly,
        OperandsAndResult,
        ResultOnly
    }

    function db() external view returns (IFhevmDebuggerDB);
    function startArithmeticCheck() external;
    function startArithmeticCheck(ArithmeticCheckMode mode) external;
    function stopArithmeticCheck() external;
    function checkArithmetic() external;
    function checkArithmetic(ArithmeticCheckMode mode) external;
}
