// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {IFFhevmBase} from "./IFFhevmBase.sol";

interface IFFhevmGateway is IFFhevmBase {
    function fulfillRequests() external;
}
