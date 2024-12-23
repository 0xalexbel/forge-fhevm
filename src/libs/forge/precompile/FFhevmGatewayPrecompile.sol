// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {BytesLib} from "../../common/BytesLib.sol";
import {AddressLib} from "../../common/AddressLib.sol";
import {TFHEHandle} from "../../common/TFHEHandle.sol";

import {IFhevmDebuggerDB} from "../../debugger/interfaces/IFhevmDebuggerDB.sol";

import {IGatewayContract} from "../../core/interfaces/IGatewayContract.sol";

import {FFhevm} from "../../../FFhevm.sol";

import {GatewaySigner, GatewaySignerLib} from "../gateway/GatewaySigner.sol";
import {IFFhevmGateway} from "../interfaces/IFFhevmGateway.sol";
import {FFhevmPrecompile} from "./FFhevmPrecompile.sol";

import {console} from "forge-std/src/console.sol";

contract FFhevmGatewayPrecompile is FFhevmPrecompile, IFFhevmGateway {
    uint256 private _requestCount;

    constructor(FFhevm.Config memory fhevmConfig) FFhevmPrecompile(fhevmConfig) {
        IGatewayContract gc = IGatewayContract(fhevmConfig.gateway.GatewayContractAddress);
        if (AddressLib.isDeployed(address(gc))) {
            _requestCount = gc.getCounter();
        }
    }

    function fulfillRequests() external noGasMetering {
        FFhevm.Config memory config = _config();
        IGatewayContract gc = IGatewayContract(config.gateway.GatewayContractAddress);

        uint256 counter = gc.getCounter();
        if (counter == _requestCount) {
            return;
        }

        IFhevmDebuggerDB debuggerDB = IFhevmDebuggerDB(config.debugger.TFHEDebuggerDBAddress);

        GatewaySigner memory signer = GatewaySigner({
            kmsSigners: config.deployConfig.kmsSigners,
            chainId: block.chainid,
            acl: config.core.ACLAddress,
            kmsVerifier: config.core.KMSVerifierAddress
        });

        for (uint256 id = _requestCount; id < counter; ++id) {
            (uint256[] memory cts, uint256 msgValue, bool passSignaturesToCaller) = gc.getDecryptionRequest(id);

            bytes memory decryptedResult;
            bytes memory decryptedResultOffsets;
            uint256 offset = (cts.length + 1) * 32;

            for (uint8 j = 0; j < cts.length; ++j) {
                if (TFHEHandle.is256Bits(cts[j])) {
                    decryptedResult = bytes.concat(decryptedResult, debuggerDB.getNumAsBytes32(cts[j]));
                } else {
                    bytes memory ctsBytes = debuggerDB.getBytes(cts[j]);
                    uint256 ctsBytesLenAligned32 = 32 * ((ctsBytes.length + 31) / 32);
                    // 1 + cts.length + 1 = numArgs (requestID + number of other args + signatures)
                    decryptedResult = bytes.concat(decryptedResult, bytes32(offset));
                    decryptedResultOffsets = bytes.concat(
                        decryptedResultOffsets,
                        bytes32(ctsBytes.length),
                        ctsBytes,
                        new bytes(ctsBytesLenAligned32 - ctsBytes.length)
                    );
                    offset += ctsBytesLenAligned32 + 32;
                }
            }

            decryptedResult = bytes.concat(decryptedResult, decryptedResultOffsets);

            bytes[] memory signatures = signer.kmsSign(cts, decryptedResult);

            vmUnsafe.startPrank(config.deployConfig.gatewayRelayer.addr, config.deployConfig.gatewayRelayer.addr);
            {
                //gc.fulfillRequest(id, decryptedResult, signatures);
                (bool success,) = address(gc).call{value: msgValue}(
                    abi.encodeWithSignature("fulfillRequest(uint256,bytes,bytes[])", id, decryptedResult, signatures)
                );
                vmSafe.assertTrue(success, "FFhevmGateway: call fulfillRequest failed");
            }
            vmUnsafe.stopPrank();
        }

        _requestCount = counter;
    }
}
