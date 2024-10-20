// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Example
// =======
//
// keyPair.publicKey = 0x20000000000000008fcea1dc16897f40ea5142b829cb04b7527e48727a63e993e4561b6824104c2d
// keyPair.privateKey = 0x2000000000000000a5cb64ce9aea0f7dd66f04fdf61592c74ef6aa16b8f63c1d53da17211bd3ec0e
//
// {
//   "types": {
//     "EIP712Domain": [
//       {
//         "name": "name",
//         "type": "string"
//       },
//       {
//         "name": "version",
//         "type": "string"
//       },
//       {
//         "name": "chainId",
//         "type": "uint256"
//       },
//       {
//         "name": "verifyingContract",
//         "type": "address"
//       }
//     ],
//     "Reencrypt": [
//       {
//         "name": "publicKey",
//         "type": "bytes"
//       }
//     ]
//   },
//   "primaryType": "Reencrypt",
//   "domain": {
//     "name": "Authorization token",
//     "version": "1",
//     "chainId": 31337,
//     "verifyingContract": "0xcEc0e9723bF28D2A2C867108cC4C3A38a011d4D1"
//   },
//   "message": {
//     "publicKey": "0x20000000000000008fcea1dc16897f40ea5142b829cb04b7527e48727a63e993e4561b6824104c2d"
//   }
// }
//
// wallet.privateKey = 0x21521291d36b38112e2ae2b780ac39df94dd40bace399f479833f6a813e43b09
// wallet.publicKey = 0x036419875c269b24c1e5a9b35e0d49124f60d8bd588d8f50ff5b8afa8563a3f3f6
// wallet.address = 0x813787401A8CC716B6C7B834Ecd89D0fA34e0132
//
// signature = 0xeb4e999aa1eb1013aadb9de7e9d9e427a7a8e0bbd1dbb70d5d5fb25c35ab0d595d46ee783a78c3ac433990b296aeb4063b8dbde210aacafc2be1320e7cb482551c

library ReencryptLib {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 constant REENCRYPT_TYPEHASH = keccak256("Reencrypt(bytes publicKey)");

    function generateKeyPair() public returns (bytes memory publicKey, bytes memory privateKey) {
        Vm.Wallet memory w = vm.createWallet(vm.randomUint());
        publicKey = bytes.concat(bytes8(0x2000000000000000), bytes32(w.publicKeyX));
        privateKey = bytes.concat(bytes8(0x2000000000000000), bytes32(w.privateKey));
    }

    function createEIP712Digest(bytes memory publicKey, uint256 chainId, address contractAddress)
        public
        pure
        returns (bytes32 digest)
    {
        bytes32 domainSep = _buildAuthorizationTokenDomainSeparator(chainId, contractAddress);
        bytes32 structHash = _hashReencrypt(publicKey);
        digest = MessageHashUtils.toTypedDataHash(domainSep, structHash);
    }

    function sign(bytes32 digest, uint256 signer) public pure returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer, digest);
        signature = abi.encodePacked(r, s, v);
    }

    function reencryptSign(bytes memory publicKey, uint256 chainId, address contractAddress, uint256 signer)
        public
        pure
        returns (bytes memory signature)
    {
        bytes32 domainSep = _buildAuthorizationTokenDomainSeparator(chainId, contractAddress);
        bytes32 structHash = _hashReencrypt(publicKey);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer, MessageHashUtils.toTypedDataHash(domainSep, structHash));
        signature = abi.encodePacked(r, s, v);
    }

    /*
        name = "Authorization token"
        version = "1"
    */
    function _buildAuthorizationTokenDomainSeparator(uint256 chainId, address contractAddress)
        private
        pure
        returns (bytes32)
    {
        bytes32 _hashedName = keccak256(bytes("Authorization token"));
        bytes32 _hashedVersion = keccak256(bytes("1"));
        return keccak256(abi.encode(EIP712DOMAIN_TYPEHASH, _hashedName, _hashedVersion, chainId, contractAddress));
    }

    function _hashReencrypt(bytes memory publicKey) private pure returns (bytes32) {
        return keccak256(abi.encode(REENCRYPT_TYPEHASH, keccak256(publicKey)));
    }

    function verifySig(bytes memory publicKey, uint256 chainId, address contractAddress, bytes memory signature)
        public
        pure
        returns (address)
    {
        bytes32 domainSep = _buildAuthorizationTokenDomainSeparator(chainId, contractAddress);
        bytes32 structHash = _hashReencrypt(publicKey);
        address signer = ECDSA.recover(MessageHashUtils.toTypedDataHash(domainSep, structHash), signature);
        return signer;
    }
}

/*
function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    function verifyEIP712Copro(CiphertextVerificationForCopro memory cv, bytes memory signature) internal view virtual {
        bytes32 digest = hashCiphertextVerificationForCopro(cv);
        address signer = ECDSA.recover(digest, signature);
        require(signer == coprocessorAddress, "Coprocessor address mismatch");
    }

    function hashCiphertextVerificationForCopro(
        CiphertextVerificationForCopro memory CVcopro
    ) internal view virtual returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        CIPHERTEXTVERIFICATION_COPRO_TYPE_HASH,
                        CVcopro.aclAddress,
                        CVcopro.hashOfCiphertext,
                        keccak256(abi.encodePacked(CVcopro.handlesList)),
                        CVcopro.userAddress,
                        CVcopro.contractAddress
                    )
                )
            );
    }

*/
