#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$(pwd)

if [ -z "$1" ]
  then
    echo "usage: new-config.sh <output directory> <config-name>"
    exit 1
fi

if [ -z "$2" ]
  then
    echo "usage: new-config.sh <output directory> <config-name>"
    exit 1
fi

if [ ! -d "$1" ]
  then
    echo "Ouptut directory '${1}' does not exist."
    exit 1
fi

if [ ! -f "${ROOT_DIR}/foundry.toml" ]; then
    echo "Foundry config file '${ROOT_DIR}/foundry.toml' does not exist."
    exit 1
fi

if [ ! -f "${ROOT_DIR}/.env" ]; then
    echo ".env file '${ROOT_DIR}/.env' does not exist."
    exit 1
fi

DST_DIR=$(cd "${1}" && pwd) || { exit 1; }

if [ ! -z "$( ls -A ${DST_DIR} )" ]; then
   echo "Output directory should be empty"
   exit 1
fi

if [ -f "${DST_DIR}/addresses.sol" ]; then
    echo "Config file '${DST_DIR}/addresses.sol' already exists."
    exit 1
fi

cd "${ROOT_DIR}"

# To load the variables in the .env file
source .env

# ---------------------------------------------------------------------------- #
#
#  Compute Private Keys
#
# ---------------------------------------------------------------------------- #

#Default
CORE_DEPLOYER_PK="0x0c66d8cde71d2faa29d0cb6e3a567d31279b6eace67b0a9d9ba869c119843a5e"
GATEWAY_DEPLOYER_PK="0x717fd99986df414889fd8b51069d4f90a50af72e542c58ee065f5883779099c6"
COPROCESSOR_PK="0x7ec8ada6642fc4ccfb7729bc29c17cf8d21b61abd5642d1db992c0b8672ab901"
FFHEVM_DEBUGGER_DEPLOYER_PK="0x5ac50c17c0e2ad3ef6d55c6b2d6ed7a68cd3b07af7d9a2ae8bd56295d64d319a"

if [ ! -z "${PRIVATE_KEY_FHEVM_DEPLOYER}" ]; then
    CORE_DEPLOYER_PK="0x${PRIVATE_KEY_FHEVM_DEPLOYER}"
fi

if [ ! -z "${PRIVATE_KEY_GATEWAY_DEPLOYER}" ]; then
    GATEWAY_DEPLOYER_PK="0x${PRIVATE_KEY_GATEWAY_DEPLOYER}"
fi

if [ ! -z "${PRIVATE_KEY_COPROCESSOR_ACCOUNT}" ]; then
    COPROCESSOR_PK="0x${PRIVATE_KEY_COPROCESSOR_ACCOUNT}"
fi

if [ ! -z "${PRIVATE_KEY_FHEVM_DEBUGGER_DEPLOYER}" ]; then
    FFHEVM_DEBUGGER_DEPLOYER_PK="0x${PRIVATE_KEY_FHEVM_DEBUGGER_DEPLOYER}"
fi

# ---------------------------------------------------------------------------- #
#
#  Compute Addresses
#
# ---------------------------------------------------------------------------- #

CONFIG_NAME="${2}"

FHEVM_DEPLOYER_ADDR=$(cast wallet address --private-key "${CORE_DEPLOYER_PK}") 
GATEWAY_DEPLOYER_ADDR=$(cast wallet address --private-key "${GATEWAY_DEPLOYER_PK}") 
COPROCESSOR_ADDRESS=$(cast wallet address --private-key "${COPROCESSOR_PK}") 
FFHEVM_DEBUGGER_DEPLOYER_ADDR=$(cast wallet address --private-key "${FFHEVM_DEBUGGER_DEPLOYER_PK}") 

ACL_ADDRESS=$(cast compute-address "${FHEVM_DEPLOYER_ADDR}" --nonce 1)
ACL_ADDRESS=${ACL_ADDRESS:18:42}

TFHE_EXECUTOR_ADDRESS=$(cast compute-address "${FHEVM_DEPLOYER_ADDR}" --nonce 3)
TFHE_EXECUTOR_ADDRESS=${TFHE_EXECUTOR_ADDRESS:18:42}

KMS_VERIFIER_ADDRESS=$(cast compute-address "${FHEVM_DEPLOYER_ADDR}" --nonce 5)
KMS_VERIFIER_ADDRESS=${KMS_VERIFIER_ADDRESS:18:42}

INPUT_VERIFIER_ADDRESS=$(cast compute-address "${FHEVM_DEPLOYER_ADDR}" --nonce 7)
INPUT_VERIFIER_ADDRESS=${INPUT_VERIFIER_ADDRESS:18:42}

FHE_PAYMENT_ADDRESS=$(cast compute-address "${FHEVM_DEPLOYER_ADDR}" --nonce 9)
FHE_PAYMENT_ADDRESS=${FHE_PAYMENT_ADDRESS:18:42}

GATEWAY_CONTRACT_ADDRESS=$(cast compute-address "${GATEWAY_DEPLOYER_ADDR}" --nonce 1)
GATEWAY_CONTRACT_ADDRESS=${GATEWAY_CONTRACT_ADDRESS:18:42}

FFHEVM_DEBUGGER_ADDRESS=$(cast compute-address "${FFHEVM_DEBUGGER_DEPLOYER_ADDR}" --nonce 1)
FFHEVM_DEBUGGER_ADDRESS=${FFHEVM_DEBUGGER_ADDRESS:18:42}

FFHEVM_DEBUGGER_DB_ADDRESS=$(cast compute-address "${FFHEVM_DEBUGGER_DEPLOYER_ADDR}" --nonce 3)
FFHEVM_DEBUGGER_DB_ADDRESS=${FFHEVM_DEBUGGER_DB_ADDRESS:18:42}

# ---------------------------------------------------------------------------- #
#
#  Generate Solidity file: addresses.sol
#
# ---------------------------------------------------------------------------- #

DST="${DST_DIR}/addresses.sol"

echo "// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

string constant CONFIG_NAME = \"${CONFIG_NAME}\";

// Fhevm Core contracts
uint256 constant CORE_DEPLOYER_PK = ${CORE_DEPLOYER_PK};
// Nonce = 1 (Impl nonce = 0)
address constant ACL_ADDRESS = ${ACL_ADDRESS};
// Nonce = 3 (Impl nonce = 2)
address constant TFHE_EXECUTOR_ADDRESS = ${TFHE_EXECUTOR_ADDRESS};
// Nonce = 5 (Impl nonce = 4)
address constant KMS_VERIFIER_ADDRESS = ${KMS_VERIFIER_ADDRESS};
// Nonce = 7 (Impl nonce = 6)
address constant INPUT_VERIFIER_ADDRESS = ${INPUT_VERIFIER_ADDRESS};
// Nonce = 9 (Impl nonce = 8)
address constant FHE_PAYMENT_ADDRESS = ${FHE_PAYMENT_ADDRESS};

// Fhevm Coprocessor
uint256 constant COPROCESSOR_PK = ${COPROCESSOR_PK};
address constant COPROCESSOR_ADDRESS = ${COPROCESSOR_ADDRESS};

// Fhevm Gateway contracts
uint256 constant GATEWAY_DEPLOYER_PK = ${GATEWAY_DEPLOYER_PK};
// Nonce = 1 (Impl nonce = 0)
address constant GATEWAY_CONTRACT_ADDRESS = ${GATEWAY_CONTRACT_ADDRESS};

// FFhevm Debugger contracts
uint256 constant FFHEVM_DEBUGGER_DEPLOYER_PK = ${FFHEVM_DEBUGGER_DEPLOYER_PK};
// Nonce = 1 (Impl nonce = 0)
address constant FFHEVM_DEBUGGER_ADDRESS = ${FFHEVM_DEBUGGER_ADDRESS};
// Nonce = 3 (Impl nonce = 2)
address constant FFHEVM_DEBUGGER_DB_ADDRESS = ${FFHEVM_DEBUGGER_DB_ADDRESS};

" > "${DST}"

# ---------------------------------------------------------------------------- #
#
#  Display info message
#
# ---------------------------------------------------------------------------- #

REL_DST_DIR=""
if command -v perl 2>&1 >/dev/null
then
    REL_DST_DIR=$(perl -le 'use File::Spec; print File::Spec->abs2rel(@ARGV)' "${DST_DIR}" "${ROOT_DIR}")
fi

cat ${DST}

echo "Forge-Fhevm config file '${DST}' has been successfully generated."
echo "Add or modify the 'forge-fhevm-config/' remapping entry using the line below in your project's 'remappings.txt' file:"
echo ""
echo "forge-fhevm-config/=./${REL_DST_DIR}/"
echo ""

# INPUT=$(cat ./remappings.txt)
# echo "${INPUT}" | sed "/^forge-fhevm-config/ s/^forge-fhevm-config.*/ffhevm-config\/=.\/${REL_DST_DIR}\//" > ./remappings.txxt
