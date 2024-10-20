// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {EnvLib} from "./EnvLib.sol";

struct FhevmEnvConfig {
    string mnemonic;
    uint256 numKmsSigners;
    bool isCoprocessor;
    FhevmEnvConfigLib.FhevmEnvSigner fhevmDeployer;
    FhevmEnvConfigLib.FhevmEnvSigner gatewayDeployer;
    FhevmEnvConfigLib.FhevmEnvSigner gatewayRelayer;
    FhevmEnvConfigLib.FhevmEnvSigner[] kmsSigners;
    FhevmEnvConfigLib.FhevmEnvSigner coprocessorAccount;
}

library FhevmEnvConfigLib {
    struct FhevmEnvSigner {
        uint256 privateKey;
        address addr;
    }

    string private constant DEFAULT_MNEMONIC =
        "adapt mosquito move limb mobile illegal tree voyage juice mosquito burger raise father hope layer";
    uint256 private constant DEFAULT_PRIVATE_KEY_FHEVM_DEPLOYER =
        0x0c66d8cde71d2faa29d0cb6e3a567d31279b6eace67b0a9d9ba869c119843a5e;
    uint256 private constant DEFAULT_PRIVATE_KEY_GATEWAY_DEPLOYER =
        0x717fd99986df414889fd8b51069d4f90a50af72e542c58ee065f5883779099c6;
    uint256 private constant DEFAULT_PRIVATE_KEY_GATEWAY_RELAYER =
        0x7ec931411ad75a7c201469a385d6f18a325d4923f9f213bd882bbea87e160b67;
    uint256 private constant DEFAULT_PRIVATE_KEY_COPROCESSOR_ACCOUNT =
        0x7ec8ada6642fc4ccfb7729bc29c17cf8d21b61abd5642d1db992c0b8672ab901;
    bool private constant DEFAULT_IS_COPROCESSOR = true;
    uint256 private constant DEFAULT_NUM_KMS_SIGNERS = 1;

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function initializeWithEnv(FhevmEnvConfig storage self) public {
        self.mnemonic = EnvLib.envMnemonicOr("MNEMONIC", DEFAULT_MNEMONIC);
        self.numKmsSigners = EnvLib.envUIntOr("NUM_KMS_SIGNERS", DEFAULT_NUM_KMS_SIGNERS);
        self.isCoprocessor = EnvLib.envBoolOr("IS_COPROCESSOR", DEFAULT_IS_COPROCESSOR);

        self.fhevmDeployer = _getEnvSigner("PRIVATE_KEY_FHEVM_DEPLOYER", DEFAULT_PRIVATE_KEY_FHEVM_DEPLOYER);
        self.gatewayDeployer = _getEnvSigner("PRIVATE_KEY_GATEWAY_DEPLOYER", DEFAULT_PRIVATE_KEY_GATEWAY_DEPLOYER);
        self.gatewayRelayer = _getEnvSigner("PRIVATE_KEY_GATEWAY_RELAYER", DEFAULT_PRIVATE_KEY_GATEWAY_RELAYER);
        self.coprocessorAccount =
            _getEnvSigner("PRIVATE_KEY_COPROCESSOR_ACCOUNT", DEFAULT_PRIVATE_KEY_COPROCESSOR_ACCOUNT);

        // self.kmsSigners = new FhevmEnvConfigLib.FhevmEnvSigner[](self.numKmsSigners);
        for (uint8 i = 0; i < self.numKmsSigners; ++i) {
            FhevmEnvSigner memory s = _getEnvKmsSignerKeys(i);
            self.kmsSigners.push(s);
        }
    }

    function _getEnvSigner(string memory envVarName, uint256 defaultPk)
        private
        returns (FhevmEnvSigner memory signer)
    {
        // setup fhevm deployer
        uint256 _pk = EnvLib.envPrivateKey(envVarName);
        if (_pk == 0) {
            _pk = defaultPk;
        }
        signer.addr = vm.rememberKey(_pk);
        signer.privateKey = _pk;
    }

    /// Reads env var PRIVATE_KEY_KMS_SIGNER_${idx}
    function _getEnvKmsSignerKeys(uint8 idx) private returns (FhevmEnvSigner memory signer) {
        uint256[4] memory DEFAULT_PRIVATE_KEY_KMS_SIGNER = [
            0x388b7680e4e1afa06efbfd45cdd1fe39f3c6af381df6555a19661f283b97de91,
            0xbbaed91514fa4b7c86aa4f73becbabcf4bce0ae130240f0d6ac3f87e06812440,
            0x1bfa3e2233b0103ad67954a728b246c528916791f7fab4894ff361e3937b47e1,
            0x7a604eed8cf4a43277d192aa0c7894d368577a4021e52bf45420f256e34c7dd7
        ];

        // setup gateway deployer
        uint256 _deployerPk = EnvLib.envPrivateKey(string.concat("PRIVATE_KEY_KMS_SIGNER_", vm.toString(idx)));
        if (_deployerPk == 0) {
            _deployerPk = DEFAULT_PRIVATE_KEY_KMS_SIGNER[idx];
        }

        signer.addr = vm.rememberKey(_deployerPk);
        signer.privateKey = _deployerPk;
    }

    function getKmsSignersPk(FhevmEnvConfig memory self) public pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](self.numKmsSigners);
        for (uint8 i = 0; i < self.numKmsSigners; ++i) {
            arr[i] = self.kmsSigners[i].privateKey;
        }
        return arr;
    }

    function getKmsSignersAddr(FhevmEnvConfig memory self) public pure returns (address[] memory) {
        address[] memory arr = new address[](self.numKmsSigners);
        for (uint8 i = 0; i < self.numKmsSigners; ++i) {
            arr[i] = self.kmsSigners[i].addr;
        }
        return arr;
    }
}

using FhevmEnvConfigLib for FhevmEnvConfig global;
