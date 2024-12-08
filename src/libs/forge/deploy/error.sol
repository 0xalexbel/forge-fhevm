// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library DeployError {
    function message(
        string memory contractName,
        address contractAddress,
        address expectedAddress,
        address deployerAddress,
        uint256 nonce
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                contractName,
                " contract address ",
                Strings.toHexString(contractAddress),
                " defined in 'ffhevm-config/addresses.sol' differs from its expected create address ",
                Strings.toHexString(expectedAddress),
                " computed using deployer: ",
                Strings.toHexString(deployerAddress),
                " and nonce: ",
                Strings.toString(nonce)
            )
        );
    }

    function message(string memory contractName, address contractAddress, address expectedAddress)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                contractName,
                " contract address ",
                Strings.toHexString(contractAddress),
                " defined in 'ffhevm-config/addresses.sol' differs from its expected create address ",
                Strings.toHexString(expectedAddress)
            )
        );
    }
}
