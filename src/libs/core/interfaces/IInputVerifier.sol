// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {ITFHEExecutor} from "./ITFHEExecutor.sol";
import {ICoreContract} from "./ICoreContract.sol";

interface IInputVerifier is ICoreContract {
    function verifyCiphertext(
        ITFHEExecutor.ContextUserInputs memory context,
        bytes32 inputHandle,
        bytes memory inputProof
    ) external returns (uint256);

    function getKMSVerifierAddress() external returns (address);
    function cleanTransientStorage() external;
}
