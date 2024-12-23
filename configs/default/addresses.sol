// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

string constant CONFIG_NAME = "default";

// Fhevm Core contracts
uint256 constant CORE_DEPLOYER_PK = 0x0c66d8cde71d2faa29d0cb6e3a567d31279b6eace67b0a9d9ba869c119843a5e;
// Nonce = 1 (Impl nonce = 0) (included)
address constant ACL_ADDRESS = 0x339EcE85B9E11a3A3AA557582784a15d7F82AAf2;
// Nonce = 3 (Impl nonce = 2) (included)
address constant TFHE_EXECUTOR_ADDRESS = 0x596E6682c72946AF006B27C131793F2b62527A4b;
// Nonce = 5 (Impl nonce = 4) (included)
address constant KMS_VERIFIER_ADDRESS = 0x208De73316E44722e16f6dDFF40881A3e4F86104;
// Nonce = 7 (Impl nonce = 6) (included)
address constant INPUT_VERIFIER_ADDRESS = 0x69dE3158643e738a0724418b21a35FAA20CBb1c5;
// Nonce = 9 (Impl nonce = 8) (included)
address constant FHE_GASLIMIT_ADDRESS = 0x6d5A11aC509C707c00bc3A0a113ACcC26c532547;

// Fhevm Coprocessor
uint256 constant COPROCESSOR_PK = 0x7ec8ada6642fc4ccfb7729bc29c17cf8d21b61abd5642d1db992c0b8672ab901;
address constant COPROCESSOR_ADDRESS = 0xc9990FEfE0c27D31D0C2aa36196b085c0c4d456c;

// Fhevm Gateway contracts
uint256 constant GATEWAY_DEPLOYER_PK = 0x717fd99986df414889fd8b51069d4f90a50af72e542c58ee065f5883779099c6;
// Nonce = 1 (Impl nonce = 0) (included)
address constant GATEWAY_CONTRACT_ADDRESS = 0x096b4679d45fB675d4e2c1E4565009Cec99A12B1;

// FFhevm Debugger contracts
// Pk = keccak256(bytes("ffhevm.debugger.wallet"))
uint256 constant FFHEVM_DEBUGGER_DEPLOYER_PK = 0x5ac50c17c0e2ad3ef6d55c6b2d6ed7a68cd3b07af7d9a2ae8bd56295d64d319a;
// Nonce = 1 (Impl nonce = 0)
address constant FFHEVM_DEBUGGER_ADDRESS = 0x92E129448e84188a8ba81c690bD464fe09C23005;
// Nonce = 3 (Impl nonce = 2)
address constant FFHEVM_DEBUGGER_DB_ADDRESS = 0x365e62c5993a21Ac8412e8470edc1caa59396C24;
