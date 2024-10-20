// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/src/Vm.sol";
import {console} from "forge-std/src/console.sol";

import {IRandomGenerator} from "../utils/IRandomGenerator.sol";
import {DeterministicRandomGenerator} from "../utils/DeterministicRandomGenerator.sol";
import {EnvLib} from "./EnvLib.sol";
import {ReencryptLib} from "../reencrypt/Reencrypt.sol";
import {FhevmDeployLib} from "../deploy/FhevmDeployLib.sol";
import {EncryptedInputSigner} from "../encrypted-input/EncryptedInputSigner.sol";
import {EncryptedInput} from "../encrypted-input/EncryptedInput.sol";

import {TFHEExecutor as TFHEExecutorWithPlugin} from "../executor/TFHEExecutor.plugin.sol";
import {TFHEExecutorDB} from "../executor/TFHEExecutorDB.sol";

import {Common} from "fhevm/lib/TFHE.sol";
import {ACL} from "fhevm/lib/ACL.sol";
import {KMSVerifier} from "fhevm/lib/KMSVerifier.sol";
import {InputVerifier as InputVerifierNative} from "fhevm/lib/InputVerifier.native.sol";
import {InputVerifier as InputVerifierCoprocessor} from "fhevm/lib/InputVerifier.coprocessor.sol";
import {FHEPayment} from "fhevm/lib/FHEPayment.sol";
import {GatewayContract} from "fhevm/gateway/GatewayContract.sol";
import {FHEVMConfig} from "fhevm/lib/FHEVMConfig.sol";
import {FhevmEnvConfig} from "./FhevmEnvConfig.sol";

contract FhevmEnv {
    // Note: IS_FHEVM_ENV() must return true.
    bool public IS_FHEVM_ENV = true;

    ACL private _acl;
    address private _inputVerifierAddress;
    InputVerifierNative private _inputVerifierNative;
    InputVerifierCoprocessor private _inputVerifierCoprocessor;
    GatewayContract private _gateway;

    TFHEExecutorDB private _db;
    IRandomGenerator private _randomGenerator;

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    FHEVMConfig.FHEVMConfigStruct _FHEVMConfig;
    FhevmEnvConfig private _config;

    constructor() {}

    function initialize(bool useDeterministicRandomGenerator) public {
        require(address(_randomGenerator) == address(0), "Already initialized");
        _config.initializeWithEnv();
        if (useDeterministicRandomGenerator) {
            _randomGenerator = IRandomGenerator(address(new DeterministicRandomGenerator(0)));
        } else {
            _randomGenerator = IRandomGenerator(address(vm));
        }
    }

    function acl() public view returns (ACL) {
        return _acl;
    }

    function db() public view returns (TFHEExecutorDB) {
        return _db;
    }

    function isCoprocessor() public view returns (bool) {
        return _config.isCoprocessor;
    }

    /// In the context of a forge script/test, at setup time, users nonces may sometimes not
    /// equal zero. Maybe because the solidity code is running within the setUp script/test
    /// special function. Consequently, we have to reset each nonce manually.
    function _resetDeployerNonceIfNeeded(address deployerAddr) private {
        if (vm.getNonce(deployerAddr) == 0) {
            return;
        }

        uint256 n = vm.getNonce(deployerAddr);
        for (uint256 i = 0; i < n; ++i) {
            address a = vm.computeCreateAddress(deployerAddr, i);
            bytes memory c = a.code;
            if (c.length != 0) {
                console.log("A contract has already been deployed at address %s", a);
                vm.assertEq(uint8(1), uint8(0), "A contract has already been deployed at a reserved address");
            }
        }
        vm.resetNonce(deployerAddr);
        console.log("FhevmEnv: resetNonce needed!!");
    }

    /// Note deployerAddr will also be the initial owner
    function deployFhevmWithPlugin(address deployerAddr) private {
        _resetDeployerNonceIfNeeded(deployerAddr);

        FhevmDeployLib.FhevmDeployment memory res =
            FhevmDeployLib.deployFhevmWithPlugin(deployerAddr, _config.isCoprocessor, _config.getKmsSignersAddr());

        _FHEVMConfig.ACLAddress = res.ACLAddress;
        _FHEVMConfig.TFHEExecutorAddress = res.TFHEExecutorAddress;
        _FHEVMConfig.KMSVerifierAddress = res.KMSVerifierAddress;
        _FHEVMConfig.FHEPaymentAddress = res.FHEPaymentAddress;

        _acl = ACL(res.ACLAddress);

        if (_config.isCoprocessor) {
            vm.assertEq(res.inputVerifierNative, address(0));
            vm.assertNotEq(res.inputVerifierCoprocessor, address(0));
            _inputVerifierAddress = res.inputVerifierCoprocessor;
        } else {
            vm.assertNotEq(res.inputVerifierNative, address(0));
            vm.assertEq(res.inputVerifierCoprocessor, address(0));
            _inputVerifierAddress = res.inputVerifierNative;
        }

        _inputVerifierCoprocessor = InputVerifierCoprocessor(res.inputVerifierCoprocessor);
        _inputVerifierNative = InputVerifierNative(res.inputVerifierNative);

        // Setup executor plugin
        _db = new TFHEExecutorDB(deployerAddr);

        TFHEExecutorWithPlugin executorWithPlugin = TFHEExecutorWithPlugin(res.TFHEExecutorAddress);
        // Make sure 'TFHEExecutorAddress' points to a 'TFHEExecutorWithPlugin' contract.
        vm.assertTrue(executorWithPlugin.IS_TFHE_EXECUTOR_PLUGIN_STORAGE());

        executorWithPlugin.setPlugin(_db);

        // Make sure FHEVMConfig is well defined
        FHEVMConfig.FHEVMConfigStruct memory defaultCfg = FHEVMConfig.defaultConfig();
        vm.assertEq(defaultCfg.ACLAddress, res.ACLAddress, "ACL address is invalid. Deployment is inconsistent.");
        vm.assertEq(
            defaultCfg.TFHEExecutorAddress,
            res.TFHEExecutorAddress,
            "TFHEExecutor address is invalid. Deployment is inconsistent."
        );
        vm.assertEq(
            defaultCfg.KMSVerifierAddress,
            res.KMSVerifierAddress,
            "KMSVerifier address is invalid. Deployment is inconsistent."
        );
        vm.assertEq(
            defaultCfg.FHEPaymentAddress,
            res.FHEPaymentAddress,
            "FHEPayment address is invalid. Deployment is inconsistent."
        );
    }

    /// Note deployerAddr will also be the initial owner
    function deployGateway(address deployerAddr) private {
        _resetDeployerNonceIfNeeded(deployerAddr);

        _gateway = FhevmDeployLib.deployGatewayContract(deployerAddr);
        _gateway.initialize(deployerAddr);

        _gateway.addRelayer(_config.gatewayRelayer.addr);
    }

    function deploy() public {
        vm.startBroadcast(_config.fhevmDeployer.privateKey);
        deployFhevmWithPlugin(_config.fhevmDeployer.addr);
        vm.stopBroadcast();

        vm.startBroadcast(_config.gatewayDeployer.privateKey);
        deployGateway(_config.gatewayDeployer.addr);
        vm.stopBroadcast();
    }

    function getEncryptedInputSigner() public view returns (EncryptedInputSigner memory) {
        EncryptedInputSigner memory s;
        s.chainId = block.chainid;
        s.acl = _FHEVMConfig.ACLAddress;
        s.kmsVerifier = _FHEVMConfig.KMSVerifierAddress;
        s.inputVerifier = _inputVerifierAddress;
        s.kmsSigners = _config.getKmsSignersPk();
        s.coprocSigner = _config.coprocessorAccount.privateKey;
        return s;
    }

    function createEncryptedInput(address contractAddress, address userAddress)
        external
        view
        returns (EncryptedInput memory input)
    {
        input._signer = getEncryptedInputSigner();
        input._contractAddress = contractAddress;
        input._userAddress = userAddress;
        input._db = address(_db);
        input._randomGenerator = _randomGenerator;
    }

    function assertArithmeticallyValidHandle(uint256 handle) external view {
        vm.assertNotEq(handle, 0, "Handle is null");

        TFHEExecutorDB.Entry256 memory entry = _db.get256(handle);

        vm.assertNotEq(entry.valueType, 0, "Handle does not exist");

        vm.assertFalse(entry.divisionByZero, "Handle inherits from a division by zero");
        vm.assertFalse(entry.overflow, "Handle inherits from an arithmetic overflow");
        vm.assertFalse(entry.underflow, "Handle inherits from an arithmetic underflow");
    }
}
