// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {ICoreContract} from "./ICoreContract.sol";

interface IKMSVerifier is ICoreContract {
    function isSigner(address account) external returns (bool);
    function addSigner(address signer) external;
    function getSigners() external view returns (address[] memory);
    function verifyDecryptionEIP712KMSSignatures(
        address aclAddress,
        uint256[] memory handlesList,
        bytes memory decryptedResult,
        bytes[] memory signatures
    ) external returns (bool);
}
