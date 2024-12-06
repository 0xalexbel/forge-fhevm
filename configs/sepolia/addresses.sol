// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

string constant CONFIG_NAME = "sepolia";

uint256 constant CORE_DEPLOYER_PK = 0;
address constant ACL_ADDRESS = 0xFee8407e2f5e3Ee68ad77cAE98c434e637f516e5;
address constant TFHE_EXECUTOR_ADDRESS = 0x687408aB54661ba0b4aeF3a44156c616c6955E07;
address constant FHE_PAYMENT_ADDRESS = 0xFb03BE574d14C256D56F09a198B586bdfc0A9de2;
address constant KMS_VERIFIER_ADDRESS = 0x9D6891A6240D6130c54ae243d8005063D05fE14b;
address constant INPUT_VERIFIER_ADDRESS = address(0);

// Fhevm Coprocessor
uint256 constant COPROCESSOR_PK = 0;
address constant COPROCESSOR_ADDRESS = address(0);

// Fhevm Gateway contracts
uint256 constant GATEWAY_DEPLOYER_PK = 0;
address constant GATEWAY_CONTRACT_ADDRESS = 0x33347831500F1e73f0ccCBb95c9f86B94d7b1123;

// FFhevm Debugger contracts
uint256 constant FFHEVM_DEBUGGER_DEPLOYER_PK = 0;
address constant FFHEVM_DEBUGGER_ADDRESS = address(0);
address constant FFHEVM_DEBUGGER_DB_ADDRESS = address(0);
