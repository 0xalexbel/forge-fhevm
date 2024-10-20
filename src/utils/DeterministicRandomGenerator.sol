// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IRandomGenerator} from "./IRandomGenerator.sol";

contract DeterministicRandomGenerator is IRandomGenerator {
    bytes32 _seed;
    bytes32 _pseudoRand;

    constructor(uint256 seed) {
        _seed = keccak256(bytes.concat(bytes32(seed)));
        _pseudoRand = _seed;
    }

    function randomUint() external returns (uint256) {
        _pseudoRand = keccak256(bytes.concat(_pseudoRand));
        return uint256(_pseudoRand);
    }
}
