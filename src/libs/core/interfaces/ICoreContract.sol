// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

interface ICoreContract {
    function getVersion() external pure returns (string memory);
    function initialize(address initialOwner) external;
}
