// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

string constant MNEMONIC =
    "adapt mosquito move limb mobile illegal tree voyage juice mosquito burger raise father hope layer";
uint256 constant PRIVATE_KEY_FHEVM_DEPLOYER = 0x0c66d8cde71d2faa29d0cb6e3a567d31279b6eace67b0a9d9ba869c119843a5e;
uint256 constant PRIVATE_KEY_GATEWAY_DEPLOYER = 0x717fd99986df414889fd8b51069d4f90a50af72e542c58ee065f5883779099c6;
uint256 constant PRIVATE_KEY_GATEWAY_RELAYER = 0x7ec931411ad75a7c201469a385d6f18a325d4923f9f213bd882bbea87e160b67;

uint8 constant NUM_KMS_SIGNERS = 1;

uint256 constant PRIVATE_KEY_KMS_SIGNER_0 = 0x388b7680e4e1afa06efbfd45cdd1fe39f3c6af381df6555a19661f283b97de91;
uint256 constant PRIVATE_KEY_KMS_SIGNER_1 = 0xbbaed91514fa4b7c86aa4f73becbabcf4bce0ae130240f0d6ac3f87e06812440;
uint256 constant PRIVATE_KEY_KMS_SIGNER_2 = 0x1bfa3e2233b0103ad67954a728b246c528916791f7fab4894ff361e3937b47e1;
uint256 constant PRIVATE_KEY_KMS_SIGNER_3 = 0x7a604eed8cf4a43277d192aa0c7894d368577a4021e52bf45420f256e34c7dd7;

uint8 constant PRIVATE_KEY_KMS_SIGNERS_LEN = 4;
bytes constant PRIVATE_KEY_KMS_SIGNERS = abi.encode(
    bytes32(uint256(32)),
    bytes32(uint256(PRIVATE_KEY_KMS_SIGNERS_LEN)),
    PRIVATE_KEY_KMS_SIGNER_0,
    PRIVATE_KEY_KMS_SIGNER_1,
    PRIVATE_KEY_KMS_SIGNER_2,
    PRIVATE_KEY_KMS_SIGNER_3
);

uint256 constant PRIVATE_KEY_COPROCESSOR_ACCOUNT = 0x7ec8ada6642fc4ccfb7729bc29c17cf8d21b61abd5642d1db992c0b8672ab901;

bool constant IS_COPROCESSOR = true;
