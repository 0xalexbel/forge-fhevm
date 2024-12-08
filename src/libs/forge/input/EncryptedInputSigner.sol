// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "../interfaces/IForgeStdVm.sol";
import {FFhevm} from "../../../FFhevm.sol";

//import {console} from "forge-std/src/console.sol";

struct EncryptedInputSigner {
    FFhevm.Signer[] kmsSigners;
    FFhevm.Signer coprocSigner;
    uint256 chainId;
    address acl;
    address inputVerifier;
    address kmsVerifier;
}

library EncryptedInputSignerLib {
    // solhint-disable const-name-snakecase
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 constant COPROC_TYPEHASH = keccak256(
        "CiphertextVerificationForCopro(address aclAddress,bytes32 hashOfCiphertext,uint256[] handlesList,address userAddress,address contractAddress)"
    );

    bytes32 constant KMS_TYPEHASH = keccak256(
        "CiphertextVerificationForKMS(address aclAddress,bytes32 hashOfCiphertext,address userAddress,address contractAddress)"
    );

    /*
        name = "InputVerifier"
        version = "1"
    */
    function __buildInputVerifierDomainSeparator(EncryptedInputSigner memory self) private pure returns (bytes32) {
        bytes32 _hashedName = keccak256(bytes("InputVerifier"));
        bytes32 _hashedVersion = keccak256(bytes("1"));
        return
            keccak256(abi.encode(EIP712DOMAIN_TYPEHASH, _hashedName, _hashedVersion, self.chainId, self.inputVerifier));
    }

    /*
        name = "KMSVerifier"
        version = "1"
    */
    function __buildKmsVerifierDomainSeparator(EncryptedInputSigner memory self) private pure returns (bytes32) {
        bytes32 _hashedName = keccak256(bytes("KMSVerifier"));
        bytes32 _hashedVersion = keccak256(bytes("1"));
        return keccak256(abi.encode(EIP712DOMAIN_TYPEHASH, _hashedName, _hashedVersion, self.chainId, self.kmsVerifier));
    }

    function __hashCiphertextVerificationForCopro(
        EncryptedInputSigner memory self,
        bytes32 hashOfCiphertext,
        uint256[] memory handlesList,
        address userAddress,
        address contractAddress
    ) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                COPROC_TYPEHASH,
                self.acl,
                hashOfCiphertext,
                keccak256(abi.encodePacked(handlesList)),
                userAddress,
                contractAddress
            )
        );
    }

    function __hashCiphertextVerificationForKMS(
        EncryptedInputSigner memory self,
        bytes32 hashOfCiphertext,
        address userAddress,
        address contractAddress
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(KMS_TYPEHASH, self.acl, hashOfCiphertext, userAddress, contractAddress));
    }

    function coprocSign(
        EncryptedInputSigner memory self,
        bytes32 hashOfCiphertext,
        uint256[] memory handlesList,
        address userAddress,
        address contractAddress
    ) internal pure returns (bytes memory signature) {
        // inputVerifierAddr is verifyingContract
        bytes32 domainSep = __buildInputVerifierDomainSeparator(self);
        bytes32 structHash =
            __hashCiphertextVerificationForCopro(self, hashOfCiphertext, handlesList, userAddress, contractAddress);
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(self.coprocSigner.privateKey, MessageHashUtils.toTypedDataHash(domainSep, structHash));
        signature = abi.encodePacked(r, s, v);
    }

    function kmsSign(
        EncryptedInputSigner memory self,
        bytes32 hashOfCiphertext,
        address userAddress,
        address contractAddress,
        uint256 kmsSignerIndex
    ) internal pure returns (bytes memory signature) {
        require(kmsSignerIndex < self.kmsSigners.length, "kmsSignerIndex out of bounds");
        // kmsVerifierAddr is verifyingContract
        bytes32 domainSep = __buildKmsVerifierDomainSeparator(self);
        bytes32 structHash = __hashCiphertextVerificationForKMS(self, hashOfCiphertext, userAddress, contractAddress);
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(self.kmsSigners[kmsSignerIndex].privateKey, MessageHashUtils.toTypedDataHash(domainSep, structHash));
        signature = abi.encodePacked(r, s, v);
    }
}

using EncryptedInputSignerLib for EncryptedInputSigner global;
