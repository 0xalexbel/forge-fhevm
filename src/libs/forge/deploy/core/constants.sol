// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {
    ACL_ADDRESS,
    TFHE_EXECUTOR_ADDRESS,
    INPUT_VERIFIER_ADDRESS,
    KMS_VERIFIER_ADDRESS,
    FHE_GASLIMIT_ADDRESS,
    COPROCESSOR_ADDRESS
} from "forge-fhevm-config/addresses.sol";

// =========================== ⭐️ Nonces ⭐️ ============================== //

uint64 constant ACLImplNonce = 0;
uint64 constant ACLNonce = 1;
uint64 constant TFHEExecutorImplNonce = 2;
uint64 constant TFHEExecutorNonce = 3;
uint64 constant KMSVerifierImplNonce = 4;
uint64 constant KMSVerifierNonce = 5;
uint64 constant InputVerifierImplNonce = 6;
uint64 constant InputVerifierNonce = 7;
uint64 constant FHEGasLimitImplNonce = 8;
uint64 constant FHEGasLimitNonce = 9;

// ====================== ⭐️ Required versions ⭐️ ======================== //

string constant ACLVersion = "ACL v0.1.0";
string constant TFHEExecutorVersion = "TFHEExecutor v0.1.0";
string constant KMSVerifierVersion = "KMSVerifier v0.1.0";
string constant FHEGasLimitVersion = "FHEGasLimit v0.1.0";
string constant InputVerifierVersion = "InputVerifier v0.1.0";

// ===================== ⭐️ Default Deployer PK ⭐️ ======================= //

uint256 constant CoreDeployerDefaultPK = uint256(keccak256(bytes("ffhevm.core.wallet")));
