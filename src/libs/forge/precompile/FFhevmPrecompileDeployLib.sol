// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {
    FFHEVM_PRECOMPILE_PK,
    FFHEVM_PRECOMPILE_ADDRESS,
    FFHEVM_INPUT_PRECOMPILE_NONCE,
    FFHEVM_INPUT_PRECOMPILE_ADDRESS,
    FFHEVM_GATEWAY_PRECOMPILE_NONCE,
    FFHEVM_GATEWAY_PRECOMPILE_ADDRESS,
    FFHEVM_REENCRYPT_PRECOMPILE_NONCE,
    FFHEVM_REENCRYPT_PRECOMPILE_ADDRESS
} from "./FFhevmPrecompileAddresses.sol";

import {
    IForgeStdVmSafe as IVmSafe,
    IForgeStdVmUnsafe as IVmUnsafe,
    forgeStdVmSafeAdd,
    forgeStdVmUnsafeAdd
} from "../interfaces/IForgeStdVm.sol";
import {FFhevm} from "../../../FFhevm.sol";

import {FFhevmInputPrecompile} from "./FFhevmInputPrecompile.sol";
import {FFhevmGatewayPrecompile} from "./FFhevmGatewayPrecompile.sol";
import {FFhevmReencryptPrecompile} from "./FFhevmReencryptPrecompile.sol";

library FFhevmPrecompileDeployLib {
    // solhint-disable const-name-snakecase
    IVmSafe internal constant vmSafe = IVmSafe(forgeStdVmSafeAdd);
    // solhint-disable const-name-snakecase
    IVmUnsafe internal constant vmUnsafe = IVmUnsafe(forgeStdVmUnsafeAdd);

    function deployFFhevmPrecompile(FFhevm.Config memory config) internal {
        vmSafe.startBroadcast(FFHEVM_PRECOMPILE_PK);
        {
            uint256 nonce = vmSafe.getNonce(FFHEVM_PRECOMPILE_ADDRESS);
            if (nonce == 0) {
                vmSafe.assertEq(
                    FFHEVM_INPUT_PRECOMPILE_NONCE, 0, "FFhevmSetUp Error: Invalid FFhevmInputPrecompile contract nonce"
                );
                FFhevmInputPrecompile pc0 = new FFhevmInputPrecompile(config);
                vmSafe.assertEq(
                    address(pc0),
                    FFHEVM_INPUT_PRECOMPILE_ADDRESS,
                    "FFhevmSetUp Error: Invalid FFhevmInputPrecompile contract address"
                );
                nonce = vmSafe.getNonce(FFHEVM_PRECOMPILE_ADDRESS);
            }

            if (nonce <= 1) {
                vmSafe.assertEq(nonce, 1, "FFhevmSetUp Error: Unexpected nonce");
                vmSafe.assertEq(
                    FFHEVM_GATEWAY_PRECOMPILE_NONCE,
                    1,
                    "FFhevmSetUp Error: Invalid FFhevmGatewayPrecompile contract nonce"
                );
                FFhevmGatewayPrecompile pc1 = new FFhevmGatewayPrecompile(config);
                vmSafe.assertEq(
                    address(pc1),
                    FFHEVM_GATEWAY_PRECOMPILE_ADDRESS,
                    "FFhevmSetUp Error: Invalid FFhevmGatewayPrecompile contract address"
                );
                nonce = vmSafe.getNonce(FFHEVM_PRECOMPILE_ADDRESS);
            }

            if (nonce <= 2) {
                vmSafe.assertEq(nonce, 2, "FFhevmSetUp Error: Unexpected nonce");
                vmSafe.assertEq(
                    FFHEVM_REENCRYPT_PRECOMPILE_NONCE,
                    2,
                    "FFhevmSetUp Error: Invalid FFhevmReencryptPrecompile contract nonce"
                );
                FFhevmReencryptPrecompile pc3 = new FFhevmReencryptPrecompile(config);
                vmSafe.assertEq(
                    address(pc3),
                    FFHEVM_REENCRYPT_PRECOMPILE_ADDRESS,
                    "FFhevmSetUp Error: Invalid FFhevmReencryptPrecompile contract address"
                );
            }
        }
        vmSafe.stopBroadcast();

        // vmUnsafe.allowCheatcodes(FFHEVM_INPUT_PRECOMPILE_ADDRESS);
        // vmUnsafe.allowCheatcodes(FFHEVM_GATEWAY_PRECOMPILE_ADDRESS);
        // vmUnsafe.allowCheatcodes(FFHEVM_REENCRYPT_PRECOMPILE_ADDRESS);
    }
}
