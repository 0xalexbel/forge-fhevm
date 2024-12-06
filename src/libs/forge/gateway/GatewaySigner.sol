// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "../interfaces/IForgeStdVm.sol";
import {FFhevm} from "../../../FFhevm.sol";

//import {console} from "forge-std/src/console.sol";

struct GatewaySigner {
    FFhevm.Signer[] kmsSigners;
    uint256 chainId;
    address acl;
    address kmsVerifier;
}

library GatewaySignerLib {
    // solhint-disable const-name-snakecase
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 constant DECRYPTION_RESULT_TYPEHASH =
        keccak256("DecryptionResult(address aclAddress,uint256[] handlesList,bytes decryptedResult)");

    /*
        name = "KMSVerifier"
        version = "1"
    */
    function __buildKmsVerifierDomainSeparator(GatewaySigner memory self) private pure returns (bytes32) {
        bytes32 _hashedName = keccak256(bytes("KMSVerifier"));
        bytes32 _hashedVersion = keccak256(bytes("1"));
        return keccak256(abi.encode(EIP712DOMAIN_TYPEHASH, _hashedName, _hashedVersion, self.chainId, self.kmsVerifier));
    }

    function __hashDecryptionResult(
        GatewaySigner memory self,
        uint256[] memory handlesList,
        bytes memory decryptedResult
    ) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                DECRYPTION_RESULT_TYPEHASH,
                self.acl,
                keccak256(abi.encodePacked(handlesList)),
                keccak256(abi.encodePacked(decryptedResult))
            )
        );
    }

    function kmsSign(
        GatewaySigner memory self,
        uint256[] memory handlesList,
        bytes memory decryptedResult,
        uint256 kmsSignerIndex
    ) internal pure returns (bytes memory signature) {
        require(kmsSignerIndex < self.kmsSigners.length, "kmsSignerIndex out of bounds");
        bytes32 domainSep = __buildKmsVerifierDomainSeparator(self);
        bytes32 structHash = __hashDecryptionResult(self, handlesList, decryptedResult);
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(self.kmsSigners[kmsSignerIndex].privateKey, MessageHashUtils.toTypedDataHash(domainSep, structHash));
        signature = abi.encodePacked(r, s, v);
    }

    function kmsSign(GatewaySigner memory self, uint256[] memory handlesList, bytes memory decryptedResult)
        internal
        pure
        returns (bytes[] memory signatures)
    {
        signatures = new bytes[](self.kmsSigners.length);
        for (uint256 i = 0; i < self.kmsSigners.length; ++i) {
            signatures[i] = kmsSign(self, handlesList, decryptedResult, i);
        }
    }
}

using GatewaySignerLib for GatewaySigner global;
