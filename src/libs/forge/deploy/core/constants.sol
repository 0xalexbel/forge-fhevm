// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {
    ACL_ADDRESS,
    TFHE_EXECUTOR_ADDRESS,
    INPUT_VERIFIER_ADDRESS,
    KMS_VERIFIER_ADDRESS,
    FHE_PAYMENT_ADDRESS,
    COPROCESSOR_ADDRESS
} from "forge-fhevm-config/addresses.sol";

// ================== ⭐️ Env var names (.env files) ⭐️ =================== //

string constant ACLAddressEnvName = "ACL_ADDRESS";
string constant TFHEExecutorAddressEnvName = "TFHE_EXECUTOR_ADDRESS";
string constant InputVerifierAddressEnvName = "INPUT_VERIFIER_ADDRESS";
string constant KMSVerifierAddressEnvName = "KMS_VERIFIER_ADDRESS";
string constant FHEPaymentAddressEnvName = "FHE_PAYMENT_ADDRESS";
string constant CoprocessorEnvName = "COPROCESSOR_ADDRESS";

// =========================== ⭐️ Nonces ⭐️ ============================== //

uint64 constant ACLImplNonce = 0;
uint64 constant ACLNonce = 1;
uint64 constant TFHEExecutorImplNonce = 2;
uint64 constant TFHEExecutorNonce = 3;
uint64 constant KMSVerifierImplNonce = 4;
uint64 constant KMSVerifierNonce = 5;
uint64 constant InputVerifierImplNonce = 6;
uint64 constant InputVerifierNonce = 7;
uint64 constant FHEPaymentImplNonce = 8;
uint64 constant FHEPaymentNonce = 9;

// ====================== ⭐️ Required versions ⭐️ ======================== //

string constant ACLVersion = "ACL v0.1.0";
string constant TFHEExecutorVersion = "TFHEExecutor v0.1.0";
string constant KMSVerifierVersion = "KMSVerifier v0.1.0";
string constant FHEPaymentVersion = "FHEPayment v0.1.0";
string constant InputVerifierVersion = "InputVerifier v0.1.0";
