// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

// keccak256(abi.encode(uint256(keccak256("fhevm.storage.FHEVMConfig")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant FHEVMConfigLocation = 0xed8d60e34876f751cc8b014c560745351147d9de11b9347c854e881b128ea600;
