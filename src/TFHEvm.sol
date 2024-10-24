// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {
    TFHE,
    einput,
    eaddress,
    ebool,
    euint4,
    euint8,
    euint16,
    euint32,
    euint64,
    euint128,
    euint256,
    ebytes64,
    ebytes128,
    ebytes256
} from "../lib/TFHE.sol";

import {ACL} from "fhevm/lib/ACL.sol";
import {FHEVMConfig} from "fhevm/lib/FHEVMConfig.sol";

import {IRandomGenerator} from "./utils/IRandomGenerator.sol";
import {DeterministicRandomGenerator} from "./utils/DeterministicRandomGenerator.sol";

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "./vm/IForgeStdVmSafe.sol";
import {FhevmDeployConfig} from "./vm/FhevmDeployConfig.sol";
import {TFHEvmStorage} from "./vm/TFHEvmStorage.sol";

import {FhevmAddressesLib} from "./deploy/FhevmAddressesLib.sol";
import {FhevmDeployLib} from "./deploy/FhevmDeployLib.sol";
import {TFHEExecutorDB} from "./executor/TFHEExecutorDB.sol";
import {ReencryptLib} from "./reencrypt/Reencrypt.sol";
import {EncryptedInput} from "./encrypted-input/EncryptedInput.sol";
import {DBLib} from "./db/DB.sol";

// uint256 constant vmTFHEPrivateKey = uint256(keccak256("forge-fhevm cheat code"));
// // = vm.computeCreateAddress(vm.addr(uint256(keccak256("forge-fhevm cheat code"))), 0);
// address constant vmTFHEAdd = 0x2bc76923c34298ddbb470B7f087A20166fdF23C0;

// interface VmTFHE {}

// contract __VmTFHEContract is VmTFHE {
//     IRandomGenerator private _randomGenerator;
//     FhevmDeployConfig private _deployConfig;

//     constructor(FhevmDeployConfig memory deployConfig) {
//         _deployConfig.storageCopyFrom(deployConfig);

//         if (deployConfig.useDeterministicRandomGenerator) {
//             _randomGenerator = IRandomGenerator(address(new DeterministicRandomGenerator(0)));
//         } else {
//             _randomGenerator = IRandomGenerator(forgeStdVmSafeAdd);
//         }
//     }
// }

//ln -s ./node_modules/fhevm/lib/ACL.sol ./src/fhevm/lib/.
//ln -s ./node_modules/fhevm/lib/ACLAddress.sol ./src/fhevm/lib/.

//"forge-std/=dependencies/forge-std-1.9.3/",
//"fhevm/lib/=dependencies/forge-fhevm/src/fhevm/lib",
enum ArithmeticCheckingMode {
    Operands,
    OperandsAndResult
}

library TFHEvm {
    // keccak256(abi.encode(uint256(keccak256("forge-fhevm.storage.TFHEvm")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TFHEvmStorageLocation = 0x43727d8b11d0755cbc84c6fab7d46a0b3153c4c95e15288858b7ea51d9adcd00;

    function __get() internal pure returns (TFHEvmStorage storage $) {
        assembly {
            $.slot := TFHEvmStorageLocation
        }
    }

    function __db() internal view returns (TFHEExecutorDB) {
        return TFHEExecutorDB(__get().TFHEExecutorDBAddress);
    }

    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    function setUp() internal {
        FhevmDeployConfig memory deployConfig;
        deployConfig.initializeWithEnv();
        setUp(deployConfig);
    }

    function setUp(FhevmDeployConfig memory deployConfig) internal {
        require(
            keccak256(abi.encode(uint256(keccak256("forge-fhevm.storage.TFHEvm")) - 1)) & ~bytes32(uint256(0xff))
                == TFHEvmStorageLocation,
            "Wrong TFHEvmStorageLocation, recompute needed"
        );
        TFHEvmStorage storage $ = __get();
        require($.initialized == false, "TFHEvm already setUp");
        $.initialized = true;

        // vm.startBroadcast(vmTFHEPrivateKey);
        // __VmTFHEContract vmTFHE = new __VmTFHEContract(deployConfig);
        // vm.stopBroadcast();
        // require(address(vmTFHE) == vmTFHEAdd, "ForgeTFHE.setUp: unexpected deploy address");

        if (deployConfig.isCoprocessor) {
            FhevmAddressesLib.checkCoprocessorAddress(deployConfig.coprocessorAccount.addr);
        }

        vm.startBroadcast(deployConfig.fhevmDeployer.privateKey);
        FhevmDeployLib.FhevmDeployment memory res = FhevmDeployLib.deployFhevmNoPlugin(
            deployConfig.fhevmDeployer.addr, deployConfig.isCoprocessor, deployConfig.getKmsSignersAddr()
        );
        vm.stopBroadcast();

        vm.startBroadcast(deployConfig.gatewayDeployer.privateKey);
        address gatewayContractAddress =
            FhevmDeployLib.deployGateway(deployConfig.gatewayDeployer.addr, deployConfig.gatewayRelayer.addr);
        vm.stopBroadcast();

        IRandomGenerator randomGenerator;
        if (deployConfig.useDeterministicRandomGenerator) {
            randomGenerator = IRandomGenerator(address(new DeterministicRandomGenerator(0)));
        } else {
            randomGenerator = IRandomGenerator(forgeStdVmSafeAdd);
        }

        $.deployConfig.storageCopyFrom(deployConfig);
        $.fhevmConfig.ACLAddress = res.ACLAddress;
        $.fhevmConfig.FHEPaymentAddress = res.FHEPaymentAddress;
        $.fhevmConfig.KMSVerifierAddress = res.KMSVerifierAddress;
        $.fhevmConfig.TFHEExecutorAddress = res.TFHEExecutorAddress;
        $.InputVerifierCoprocessorAddress = res.InputVerifierCoprocessorAddress;
        $.InputVerifierNativeAddress = res.InputVerifierNativeAddress;
        $.InputVerifierAddress = res.InputVerifierAddress;
        $.TFHEExecutorDBAddress = res.TFHEExecutorDBAddress;
        $.GatewayContractAddress = gatewayContractAddress;
        $.IRandomGeneratorAddress = address(randomGenerator);

        TFHE.setFHEVM(FHEVMConfig.defaultConfig());
    }

    // ====================================================================== //
    //
    //                      ⭐️ Public API ⭐️
    //
    // ====================================================================== //

    function fhevmDeployer() internal view returns (address) {
        TFHEvmStorage storage $ = __get();
        return $.deployConfig.fhevmDeployer.addr;
    }

    function acl() private view returns (ACL) {
        TFHEvmStorage storage $ = __get();
        return ACL($.fhevmConfig.ACLAddress);
    }

    function isCoprocessor() public view returns (bool) {
        TFHEvmStorage storage $ = __get();
        return $.deployConfig.isCoprocessor;
    }

    // ====================================================================== //
    //
    //                      ⭐️ API: Encrypt functions ⭐️
    //
    // ====================================================================== //

    function createEncryptedInput(address contractAddress, address userAddress)
        internal
        view
        returns (EncryptedInput memory input)
    {
        TFHEvmStorage storage $ = __get();
        return $.createEncryptedInput(contractAddress, userAddress);
    }

    /// Helper: encrypts a single bool value and returns the handle+inputProof pair
    function encryptBool(bool value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBool(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single bool value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptBool(bool value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBool(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 4-bits unsigned integer value and returns the handle+inputProof pair
    function encryptU4(uint8 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add4(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single 4-bits unsigned integer value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU4(uint8 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add4(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint8 value and returns the handle+inputProof pair
    function encryptU8(uint8 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add8(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint8 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU8(uint8 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add8(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint16 value and returns the handle+inputProof pair
    function encryptU16(uint16 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add16(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint16 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU16(uint16 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add16(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint32 value and returns the handle+inputProof pair
    function encryptU32(uint32 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add32(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint32 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU32(uint32 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add32(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint64 value and returns the handle+inputProof pair
    function encryptU64(uint64 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add64(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint64 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU64(uint64 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add64(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint128 value and returns the handle+inputProof pair
    function encryptU128(uint128 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add128(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint128 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU128(uint128 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add128(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single uint256 value and returns the handle+inputProof pair
    function encryptU256(uint256 value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add256(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single uint256 value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptU256(uint256 value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.add256(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 64-bytes value and returns the handle+inputProof pair
    /// Fails if value.length > 64
    function encryptBytes64(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes64(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single 64-bytes value value using
    /// a given random salt and returns the handle+inputProof pair
    /// Fails if value.length > 64
    function encryptBytes64(bytes memory value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes64(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 128-bytes value and returns the handle+inputProof pair
    /// Fails if value.length > 128
    function encryptBytes128(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes128(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single 128-bytes value value using
    /// a given random salt and returns the handle+inputProof pair
    /// Fails if value.length > 128
    function encryptBytes128(bytes memory value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes128(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: encrypts a single 256-bytes value and returns the handle+inputProof pair
    /// Fails if value.length > 256
    function encryptBytes256(bytes memory value, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes256(value);
        (handle, inputProof) = input.encryptSingleton();
    }

    /// Helper: deterministically encrypts a single 256-bytes value value using
    /// a given random salt and returns the handle+inputProof pair
    function encryptBytes256(bytes memory value, bytes32 random, address contractAddress, address userAddress)
        internal
        returns (einput handle, bytes memory inputProof)
    {
        EncryptedInput memory input = createEncryptedInput(contractAddress, userAddress);
        input.addBytes256(value, random);
        (handle, inputProof) = input.encryptSingleton();
    }

    // ====================================================================== //
    //
    //                  ⭐️ API: getClear cheat functions ⭐️
    //
    // ====================================================================== //

    function getClear(ebool value) internal view returns (bool) {
        return __db().getBool(ebool.unwrap(value));
    }

    function getClear(euint4 value) internal view returns (uint8) {
        return __db().getU4(euint4.unwrap(value));
    }

    function getClear(euint8 value) internal view returns (uint8) {
        return __db().getU8(euint8.unwrap(value));
    }

    function getClear(euint16 value) internal view returns (uint16) {
        return __db().getU16(euint16.unwrap(value));
    }

    function getClear(euint32 value) internal view returns (uint32) {
        return __db().getU32(euint32.unwrap(value));
    }

    function getClear(euint64 value) internal view returns (uint64) {
        return __db().getU64(euint64.unwrap(value));
    }

    function getClear(euint128 value) internal view returns (uint128) {
        return __db().getU128(euint128.unwrap(value));
    }

    function getClear(euint256 value) internal view returns (uint256) {
        return __db().getU256(euint256.unwrap(value));
    }

    function getClear(ebytes64 value) internal view returns (bytes memory) {
        return __db().getBytes64(ebytes64.unwrap(value));
    }

    function getClear(ebytes128 value) internal view returns (bytes memory) {
        return __db().getBytes128(ebytes128.unwrap(value));
    }

    function getClear(ebytes256 value) internal view returns (bytes memory) {
        return __db().getBytes256(ebytes256.unwrap(value));
    }

    // ====================================================================== //
    //
    //                     ⭐️ API: Decrypt functions ⭐️
    //
    // ====================================================================== //

    /**
     * @dev Decrypts an encrypted boolean value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptBool(ebool value, address contractAddress, address userAddress)
        internal
        view
        returns (bool result)
    {
        uint256 handle = ebool.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getBool(handle);
    }

    /**
     * @dev Decrypts an encrypted boolean value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero, overfow, underflow).
     */
    function decryptBoolStrict(ebool value, address contractAddress, address userAddress)
        internal
        view
        returns (bool result)
    {
        uint256 handle = ebool.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getBool(handle);
    }

    /**
     * @dev Decrypts an encrypted 4bits unsigned integer value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptU4(euint4 value, address contractAddress, address userAddress) public view returns (uint8 result) {
        uint256 handle = euint4.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU4(handle);
    }

    /**
     * @dev Decrypts an encrypted 4bits unsigned integer value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero, overfow, underflow).
     */
    function decryptU4Strict(euint4 value, address contractAddress, address userAddress)
        internal
        view
        returns (uint8 result)
    {
        uint256 handle = euint4.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU4(handle);
    }

    /**
     * @dev Decrypts an encrypted uint8 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptU8(euint8 value, address contractAddress, address userAddress) public view returns (uint8 result) {
        uint256 handle = euint8.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU8(handle);
    }

    /**
     * @dev Decrypts an encrypted uint8 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero, overfow, underflow).
     */
    function decryptU8Strict(euint8 value, address contractAddress, address userAddress)
        internal
        view
        returns (uint8 result)
    {
        uint256 handle = euint8.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU8(handle);
    }

    /**
     * @dev Decrypts an encrypted uint16 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptU16(euint16 value, address contractAddress, address userAddress)
        public
        view
        returns (uint16 result)
    {
        uint256 handle = euint16.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU16(handle);
    }

    /**
     * @dev Decrypts an encrypted uint16 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero, overfow, underflow).
     */
    function decryptU16Strict(euint16 value, address contractAddress, address userAddress)
        internal
        view
        returns (uint16 result)
    {
        uint256 handle = euint16.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU16(handle);
    }

    /**
     * @dev Decrypts an encrypted uint32 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptU32(euint32 value, address contractAddress, address userAddress)
        public
        view
        returns (uint32 result)
    {
        uint256 handle = euint32.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU32(handle);
    }

    /**
     * @dev Decrypts an encrypted uint32 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero, overfow, underflow).
     */
    function decryptU32Strict(euint32 value, address contractAddress, address userAddress)
        internal
        view
        returns (uint32 result)
    {
        uint256 handle = euint32.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU32(handle);
    }

    /**
     * @dev Decrypts an encrypted uint64 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptU64(euint64 value, address contractAddress, address userAddress)
        public
        view
        returns (uint64 result)
    {
        uint256 handle = euint64.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU64(handle);
    }

    /**
     * @dev Decrypts an encrypted uint64 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero, overfow, underflow).
     */
    function decryptU64Strict(euint64 value, address contractAddress, address userAddress)
        public
        view
        returns (uint64 result)
    {
        uint256 handle = euint64.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU64(handle);
    }

    /**
     * @dev Decrypts an encrypted uint128 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptU128(euint128 value, address contractAddress, address userAddress)
        public
        view
        returns (uint128 result)
    {
        uint256 handle = euint128.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU128(handle);
    }

    /**
     * @dev Decrypts an encrypted uint128 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero, overfow, underflow).
     */
    function decryptU128Strict(euint128 value, address contractAddress, address userAddress)
        public
        view
        returns (uint128 result)
    {
        uint256 handle = euint128.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU128(handle);
    }

    /**
     * @dev Decrypts an encrypted uint256 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptU256(euint256 value, address contractAddress, address userAddress)
        public
        view
        returns (uint256 result)
    {
        uint256 handle = euint256.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU256(handle);
    }

    /**
     * @dev Decrypts an encrypted uint256 value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     * - If the handle is the result of any prior arithmetically invalid operation (division by zero, overfow, underflow).
     */
    function decryptU256Strict(euint256 value, address contractAddress, address userAddress)
        public
        view
        returns (uint256 result)
    {
        uint256 handle = euint256.unwrap(value);

        __assertArithmeticallyValidHandle(handle);
        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getU256(handle);
    }

    /**
     * @dev Decrypts an encrypted 64-bytes value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptBytes64(ebytes64 value, address contractAddress, address userAddress)
        public
        view
        returns (bytes memory result)
    {
        uint256 handle = ebytes64.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getBytes64(handle);
    }

    /**
     * @dev Decrypts an encrypted 128-bytes value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptBytes128(ebytes128 value, address contractAddress, address userAddress)
        public
        view
        returns (bytes memory result)
    {
        uint256 handle = ebytes128.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getBytes128(handle);
    }

    /**
     * @dev Decrypts an encrypted 256-bytes value given a contract address and a user address
     *
     * The function will fail:
     *
     * - If handle == 0
     * - If the contact address does not have the permission to decrypt the value
     * - If the user address does not have the permission to decrypt the value
     */
    function decryptBytes256(ebytes256 value, address contractAddress, address userAddress)
        public
        view
        returns (bytes memory result)
    {
        uint256 handle = ebytes256.unwrap(value);

        __assertDecryptAllowed(handle, contractAddress, userAddress);

        return __db().getBytes256(handle);
    }

    // ====================================================================== //
    //
    //                      ⭐️ API: Reencrypt ⭐️
    //
    // ====================================================================== //

    function generateKeyPair() internal returns (bytes memory publicKey, bytes memory privateKey) {
        return ReencryptLib.generateKeyPair();
    }

    function createEIP712Digest(bytes memory publicKey, address contractAddress) internal view returns (bytes32) {
        return ReencryptLib.createEIP712Digest(publicKey, block.chainid, contractAddress);
    }

    function sign(bytes32 digest, uint256 signer) internal pure returns (bytes memory signature) {
        return ReencryptLib.sign(digest, signer);
    }

    function reencryptBool(
        ebool value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (bool) {
        uint256 handle = ebool.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptBool(value, contractAddress, userAddress);
    }

    function reencryptU4(
        euint4 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (uint8) {
        uint256 handle = euint4.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptU4(value, contractAddress, userAddress);
    }

    function reencryptU8(
        euint8 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (uint8) {
        uint256 handle = euint8.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptU8(value, contractAddress, userAddress);
    }

    function reencryptU16(
        euint16 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (uint16) {
        uint256 handle = euint16.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptU16(value, contractAddress, userAddress);
    }

    function reencryptU32(
        euint32 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (uint32) {
        uint256 handle = euint32.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptU32(value, contractAddress, userAddress);
    }

    function reencryptU64(
        euint64 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (uint64) {
        uint256 handle = euint64.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptU64(value, contractAddress, userAddress);
    }

    function reencryptU128(
        euint128 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (uint128) {
        uint256 handle = euint128.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptU128(value, contractAddress, userAddress);
    }

    function reencryptU256(
        euint256 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (uint256) {
        uint256 handle = euint256.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptU256(value, contractAddress, userAddress);
    }

    function reencryptBytes64(
        ebytes64 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (bytes memory) {
        uint256 handle = ebytes64.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptBytes64(value, contractAddress, userAddress);
    }

    function reencryptBytes128(
        ebytes128 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (bytes memory) {
        uint256 handle = ebytes128.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptBytes128(value, contractAddress, userAddress);
    }

    function reencryptBytes256(
        ebytes256 value,
        bytes memory privateKey,
        bytes memory publicKey,
        bytes memory signature,
        address contractAddress,
        address userAddress
    ) internal view returns (bytes memory) {
        uint256 handle = ebytes256.unwrap(value);
        vm.assertNotEq(handle, 0, "Handle is null");

        ReencryptLib.assertValidEIP712Sig(privateKey, publicKey, signature, block.chainid, contractAddress, userAddress);

        return decryptBytes256(value, contractAddress, userAddress);
    }

    // ====================================================================== //
    //
    //                     🔍 Assert functions 🔍
    //
    // ====================================================================== //

    /// Asserts that the `ebool` value is arithmetically valid.
    function assertArithmeticallyValid(ebool value) internal view {
        __assertArithmeticallyValidHandle(ebool.unwrap(value));
    }

    /// Asserts that the `euint4` value is arithmetically valid.
    function assertArithmeticallyValid(euint4 value) internal view {
        __assertArithmeticallyValidHandle(euint4.unwrap(value));
    }

    /// Asserts that the `euint8` value is arithmetically valid.
    function assertArithmeticallyValid(euint8 value) internal view {
        __assertArithmeticallyValidHandle(euint8.unwrap(value));
    }

    /// Asserts that the `euint16` value is arithmetically valid.
    function assertArithmeticallyValid(euint16 value) internal view {
        __assertArithmeticallyValidHandle(euint16.unwrap(value));
    }

    /// Asserts that the `euint32` value is arithmetically valid.
    function assertArithmeticallyValid(euint32 value) internal view {
        __assertArithmeticallyValidHandle(euint32.unwrap(value));
    }

    /// Asserts that the `euint64` value is arithmetically valid.
    function assertArithmeticallyValid(euint64 value) internal view {
        __assertArithmeticallyValidHandle(euint64.unwrap(value));
    }

    /// Asserts that the `eaddress` value is arithmetically valid.
    function assertArithmeticallyValid(eaddress value) internal view {
        __assertArithmeticallyValidHandle(eaddress.unwrap(value));
    }

    /// Asserts that the `euint128` value is arithmetically valid.
    function assertArithmeticallyValid(euint128 value) internal view {
        __assertArithmeticallyValidHandle(euint128.unwrap(value));
    }

    /// Asserts that the `euint256` value is arithmetically valid.
    function assertArithmeticallyValid(euint256 value) internal view {
        __assertArithmeticallyValidHandle(euint256.unwrap(value));
    }

    function isArithmeticallyValid(ebool value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(ebool.unwrap(value));
    }

    function isArithmeticallyValid(euint4 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint4.unwrap(value));
    }

    function isArithmeticallyValid(euint8 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint8.unwrap(value));
    }

    function isArithmeticallyValid(euint16 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint16.unwrap(value));
    }

    function isArithmeticallyValid(euint32 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint32.unwrap(value));
    }

    function isArithmeticallyValid(euint64 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint64.unwrap(value));
    }

    function isArithmeticallyValid(eaddress value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(eaddress.unwrap(value));
    }

    function isArithmeticallyValid(euint128 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint128.unwrap(value));
    }

    function isArithmeticallyValid(euint256 value) internal view returns (bool) {
        return _isArithmeticallyValidHandle(euint256.unwrap(value));
    }

    function isTrivial(ebool value) internal view returns (bool) {
        return _isTrivialHandle(ebool.unwrap(value));
    }

    function isTrivial(euint4 value) internal view returns (bool) {
        return _isTrivialHandle(euint4.unwrap(value));
    }

    function isTrivial(euint8 value) internal view returns (bool) {
        return _isTrivialHandle(euint8.unwrap(value));
    }

    function isTrivial(euint16 value) internal view returns (bool) {
        return _isTrivialHandle(euint16.unwrap(value));
    }

    function isTrivial(euint32 value) internal view returns (bool) {
        return _isTrivialHandle(euint32.unwrap(value));
    }

    function isTrivial(euint64 value) internal view returns (bool) {
        return _isTrivialHandle(euint64.unwrap(value));
    }

    function isTrivial(euint128 value) internal view returns (bool) {
        return _isTrivialHandle(euint128.unwrap(value));
    }

    function isTrivial(euint256 value) internal view returns (bool) {
        return _isTrivialHandle(euint256.unwrap(value));
    }

    function isTrivial(eaddress value) internal view returns (bool) {
        return _isTrivialHandle(eaddress.unwrap(value));
    }

    function isTrivial(ebytes64 value) internal view returns (bool) {
        return _isTrivialHandle(ebytes64.unwrap(value));
    }

    function isTrivial(ebytes128 value) internal view returns (bool) {
        return _isTrivialHandle(ebytes128.unwrap(value));
    }

    function isTrivial(ebytes256 value) internal view returns (bool) {
        return _isTrivialHandle(ebytes256.unwrap(value));
    }

    function _isTrivialHandle(uint256 handle) private view returns (bool) {
        return __db().isTrivial(handle);
    }

    /// Check any arithmetic error in all subsequent fhevm operations with
    /// mode equal to 'ArithmeticCheckingMode.Operands'
    function startCheckArithmetic() public {
        __db().startCheckArithmetic();
    }

    /// Check any arithmetic error in all subsequent fhevm operations.
    /// if mode = 'ArithmeticCheckingMode.Operands', test only applies to operands, for example c = a + b,
    /// both a and b are checked, c is ignored.
    /// if mode = 'ArithmeticCheckingMode.OperandsAndResult', test applies to both operands and result, for example c = a + b,
    /// a, b and c are all checked.
    function startCheckArithmetic(ArithmeticCheckingMode mode) public {
        __db().startCheckArithmetic(uint8(mode));
    }

    /// Stops checking fhevm arithmetic errors.
    function stopCheckArithmetic() public {
        __db().stopCheckArithmetic();
    }

    /// Check any arithmetic error in the next fhevm operation with
    /// mode equal to 'ArithmeticCheckingMode.Operands'
    function checkArithmetic() public {
        __db().checkArithmetic();
    }

    /// Check any arithmetic error in the next fhevm operation
    /// using specified mode.
    function checkArithmetic(ArithmeticCheckingMode mode) public {
        __db().checkArithmetic(uint8(mode));
    }

    // ====================================================================== //
    //
    //                  📦 Private testing functions 📦
    //
    // ====================================================================== //

    function _isArithmeticallyValidHandle(uint256 handle) private view returns (bool) {
        return __db().isArithmeticallyValid(handle);
    }

    function __assertDecryptAllowed(uint256 handle, address contractAddress, address userAddress) private view {
        vm.assertNotEq(handle, 0, "Handle is null");
        vm.assertTrue(
            acl().persistAllowed(handle, contractAddress), "contractAddress does not have permission to decrypt handle"
        );
        vm.assertTrue(
            acl().persistAllowed(handle, userAddress), "userAddress does not have permission to decrypt handle"
        );
        vm.assertNotEq(
            uint160(userAddress),
            uint160(contractAddress),
            "userAddress should not be equal to contractAddress when requesting reencryption!"
        );
    }

    function __assertArithmeticallyValidHandle(uint256 handle) private view {
        vm.assertNotEq(handle, 0, "Handle is null");

        DBLib.RecordMeta memory meta = __db().getMeta(handle);

        vm.assertNotEq(meta.valueType, 0, "Handle does not exist");

        vm.assertFalse(meta.arithmeticFlags.divisionByZero, "Handle inherits from a division by zero");
        vm.assertFalse(meta.arithmeticFlags.overflow, "Handle inherits from an arithmetic overflow");
        vm.assertFalse(meta.arithmeticFlags.underflow, "Handle inherits from an arithmetic underflow");
    }
}
