// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {TestAsyncDecrypt} from "./TestAsyncDecrypt.sol";
import {DefaultFFHEVMDebugConfig} from "../../../src/libs/fhevm-debug/config/FFHEVMDebugConfig.sol";

contract TestAsyncDecryptDebug is DefaultFFHEVMDebugConfig, TestAsyncDecrypt {}
