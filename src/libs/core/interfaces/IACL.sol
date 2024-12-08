// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {ICoreContract} from "./ICoreContract.sol";

interface IACL is ICoreContract {
    function allowTransient(uint256 ciphertext, address account) external;
    function allow(uint256 handle, address account) external;
    function cleanTransientStorage() external;
    function isAllowed(uint256 handle, address account) external view returns (bool);
    function persistAllowed(uint256 handle, address account) external view returns (bool);
    function allowForDecryption(uint256[] memory handlesList) external;
}
