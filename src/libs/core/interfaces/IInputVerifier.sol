// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {ITFHEExecutor} from "./ITFHEExecutor.sol";

interface IInputVerifier {
    function verifyCiphertext(
        ITFHEExecutor.ContextUserInputs memory context,
        bytes32 inputHandle,
        bytes memory inputProof
    ) external returns (uint256);

    function getKMSVerifierAddress() external returns (address);
}
