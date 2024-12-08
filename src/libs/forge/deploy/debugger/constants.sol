// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {FFHEVM_DEBUGGER_ADDRESS, FFHEVM_DEBUGGER_DB_ADDRESS} from "forge-fhevm-config/addresses.sol";

// ================== ⭐️ Env var names (.env files) ⭐️ =================== //

// string constant TFHEDebuggerAddressEnvName = "FFHEVM_DEBUGGER_ADDRESS";
// string constant TFHEDebuggerDBAddressEnvName = "FFHEVM_DEBUGGER_DB_ADDRESS";

// =========================== ⭐️ Nonces ⭐️ ============================== //

uint64 constant TFHEDebuggerImplNonce = 0;
uint64 constant TFHEDebuggerNonce = 1;
uint64 constant TFHEDebuggerDBImplNonce = 2;
uint64 constant TFHEDebuggerDBNonce = 3;

// ====================== ⭐️ Required versions ⭐️ ======================== //

string constant TFHEDebuggerVersion = "TFHEDebugger v0.1.0";
string constant TFHEDebuggerDBVersion = "TFHEDebuggerDB v0.1.0";

// ===================== ⭐️ Default Deployer PK ⭐️ ======================= //

uint256 constant TFHEDebuggerDeployerDefaultPK = uint256(keccak256(bytes("ffhevm.debugger.wallet")));
