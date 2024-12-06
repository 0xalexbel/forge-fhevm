// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {GATEWAY_CONTRACT_ADDRESS} from "forge-fhevm-config/addresses.sol";

// ================== ⭐️ Env var names (.env files) ⭐️ =================== //

string constant GatewayContractAddressEnvName = "GATEWAY_CONTRACT_ADDRESS";

// =========================== ⭐️ Nonces ⭐️ ============================== //

uint64 constant GatewayContractImplNonce = 0;
uint64 constant GatewayContractNonce = 1;

// ====================== ⭐️ Required versions ⭐️ ======================== //

string constant GatewayContractVersion = "GatewayContract v0.1.0";
