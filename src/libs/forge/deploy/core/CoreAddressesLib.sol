// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {FFhevm} from "../../../../FFhevm.sol";

import {AddressLib} from "../../../common/AddressLib.sol";
import {FFhevmDebugConfigStruct} from "../../../debugger/config/FFhevmDebugConfig.sol";

import {EnvLib} from "../../utils/EnvLib.sol";
import {DeployError} from "../error.sol";

import "./constants.sol" as CONST;

library CoreAddressesLib {
    struct Addresses {
        // FFhevmDebugConfigStruct
        address ACLAddress;
        address TFHEExecutorAddress;
        address FHEPaymentAddress;
        address KMSVerifierAddress;
        // InputVerifiers
        address InputVerifierAddress;
        address InputVerifierNativeAddress;
        address InputVerifierCoprocessorAddress;
    }

    function checkACLAddress(address addr) internal pure {
        require(CONST.ACL_ADDRESS == addr, DeployError.message("ACL", CONST.ACL_ADDRESS, addr));
    }

    function checkTFHEExecutorAddress(address addr) internal pure {
        require(
            CONST.TFHE_EXECUTOR_ADDRESS == addr, DeployError.message("TFHEExecutor", CONST.TFHE_EXECUTOR_ADDRESS, addr)
        );
    }

    function checkKMSVerifierAddress(address addr) internal pure {
        require(
            CONST.KMS_VERIFIER_ADDRESS == addr, DeployError.message("KMSVerifier", CONST.KMS_VERIFIER_ADDRESS, addr)
        );
    }

    function checkInputVerifierAddress(address addr) internal pure {
        require(
            CONST.INPUT_VERIFIER_ADDRESS == addr,
            DeployError.message("InputVerifier", CONST.INPUT_VERIFIER_ADDRESS, addr)
        );
    }

    function checkFHEPaymentAddress(address addr) internal pure {
        require(CONST.FHE_PAYMENT_ADDRESS == addr, DeployError.message("FHEPayment", CONST.FHE_PAYMENT_ADDRESS, addr));
    }

    function expectedCreateACLAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce)
    {
        expectedImplNonce = CONST.ACLImplNonce;
        expectedNonce = CONST.ACLNonce;
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, expectedImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, expectedNonce);

        require(
            CONST.ACL_ADDRESS == expectedAddr,
            DeployError.message("ACL", CONST.ACL_ADDRESS, expectedAddr, deployerAddr, expectedNonce)
        );
    }

    function expectedCreateTFHEExecutorAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce)
    {
        expectedImplNonce = CONST.TFHEExecutorImplNonce;
        expectedNonce = CONST.TFHEExecutorNonce;
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, expectedImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, expectedNonce);

        require(
            CONST.TFHE_EXECUTOR_ADDRESS == expectedAddr,
            DeployError.message("TFHEExecutor", CONST.TFHE_EXECUTOR_ADDRESS, expectedAddr, deployerAddr, expectedNonce)
        );
    }

    function expectedCreateKMSVerifierAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce)
    {
        expectedImplNonce = CONST.KMSVerifierImplNonce;
        expectedNonce = CONST.KMSVerifierNonce;
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, expectedImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, expectedNonce);

        require(
            CONST.KMS_VERIFIER_ADDRESS == expectedAddr,
            DeployError.message("KMSVerifier", CONST.KMS_VERIFIER_ADDRESS, expectedAddr, deployerAddr, expectedNonce)
        );
    }

    function expectedCreateInputVerifierAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce)
    {
        expectedImplNonce = CONST.InputVerifierImplNonce;
        expectedNonce = CONST.InputVerifierNonce;
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, expectedImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, expectedNonce);

        require(
            CONST.INPUT_VERIFIER_ADDRESS == expectedAddr,
            DeployError.message(
                "InputVerifier", CONST.INPUT_VERIFIER_ADDRESS, expectedAddr, deployerAddr, expectedNonce
            )
        );
    }

    function expectedCreateFHEPaymentAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce)
    {
        expectedImplNonce = CONST.FHEPaymentImplNonce;
        expectedNonce = CONST.FHEPaymentNonce;
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, expectedImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, expectedNonce);

        require(
            CONST.FHE_PAYMENT_ADDRESS == expectedAddr,
            DeployError.message("FHEPayment", CONST.FHE_PAYMENT_ADDRESS, expectedAddr, deployerAddr, expectedNonce)
        );
    }

    function computeCreateACLAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, CONST.ACLNonce);
    }

    function computeCreateTFHEExecutorAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, CONST.TFHEExecutorNonce);
    }

    function computeCreateKMSVerifierAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, CONST.KMSVerifierNonce);
    }

    function computeCreateInputVerifierAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, CONST.InputVerifierNonce);
    }

    function computeCreateFHEPaymentAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, CONST.FHEPaymentNonce);
    }

    function checkCoprocessorAddress(address coprocAddress) internal pure {
        require(
            CONST.COPROCESSOR_ADDRESS == coprocAddress,
            "Coprocessor address mismtach. The coprocessor private key does not match the required address stored in 'fhevm/lib/CoprocessorAddress.sol'"
        );
    }

    function computeAddresses(address deployerAddr, bool isCoprocessor)
        internal
        pure
        returns (FFhevm.CoreAddresses memory coreAddresses)
    {
        coreAddresses.ACLAddress = computeCreateACLAddress(deployerAddr);
        coreAddresses.TFHEExecutorAddress = computeCreateTFHEExecutorAddress(deployerAddr);
        coreAddresses.FHEPaymentAddress = computeCreateFHEPaymentAddress(deployerAddr);
        coreAddresses.KMSVerifierAddress = computeCreateKMSVerifierAddress(deployerAddr);
        if (isCoprocessor) {
            coreAddresses.InputVerifierNativeAddress = address(0);
            coreAddresses.InputVerifierCoprocessorAddress = computeCreateInputVerifierAddress(deployerAddr);
            coreAddresses.InputVerifierAddress = coreAddresses.InputVerifierCoprocessorAddress;
        } else {
            coreAddresses.InputVerifierCoprocessorAddress = address(0);
            coreAddresses.InputVerifierNativeAddress = computeCreateInputVerifierAddress(deployerAddr);
            coreAddresses.InputVerifierAddress = coreAddresses.InputVerifierNativeAddress;
        }
    }

    // function readEnvAddresses() internal view returns (FFhevm.CoreAddresses memory) {
    //     FFhevm.CoreAddresses memory coreAddresses;

    //     coreAddresses.ACLAddress = EnvLib.envAddressOr(CONST.ACLAddressEnvName, address(0));
    //     coreAddresses.TFHEExecutorAddress = EnvLib.envAddressOr(CONST.TFHEExecutorAddressEnvName, address(0));
    //     coreAddresses.FHEPaymentAddress = EnvLib.envAddressOr(CONST.FHEPaymentAddressEnvName, address(0));
    //     coreAddresses.KMSVerifierAddress = EnvLib.envAddressOr(CONST.KMSVerifierAddressEnvName, address(0));
    //     coreAddresses.InputVerifierAddress = EnvLib.envAddressOr(CONST.InputVerifierAddressEnvName, address(0));

    //     if (
    //         coreAddresses.ACLAddress == address(0) && coreAddresses.TFHEExecutorAddress == address(0)
    //             && coreAddresses.FHEPaymentAddress == address(0) && coreAddresses.KMSVerifierAddress == address(0)
    //             && coreAddresses.InputVerifierAddress == address(0)
    //     ) {
    //         return coreAddresses;
    //     }

    //     if (coreAddresses.ACLAddress == address(0)) {
    //         revert("Missing ACL contract address env value");
    //     } else {
    //         checkACLAddress(coreAddresses.ACLAddress);
    //     }

    //     if (coreAddresses.TFHEExecutorAddress == address(0)) {
    //         revert("Missing TFHEExecutor contract address env value");
    //     } else {
    //         checkTFHEExecutorAddress(coreAddresses.TFHEExecutorAddress);
    //     }

    //     if (coreAddresses.FHEPaymentAddress == address(0)) {
    //         revert("Missing FHEPayment contract address env value");
    //     } else {
    //         checkFHEPaymentAddress(coreAddresses.FHEPaymentAddress);
    //     }

    //     if (coreAddresses.KMSVerifierAddress == address(0)) {
    //         revert("Missing KMSVerifier contract address env value");
    //     } else {
    //         checkKMSVerifierAddress(coreAddresses.KMSVerifierAddress);
    //     }

    //     if (coreAddresses.InputVerifierAddress == address(0)) {
    //         revert("Missing InputVerifier contract address env value");
    //     } else {
    //         checkInputVerifierAddress(coreAddresses.InputVerifierAddress);
    //     }

    //     return coreAddresses;
    // }

    function expectedACLAddress() internal pure returns (address expectedAddr) {
        expectedAddr = CONST.ACL_ADDRESS;
    }

    function expectedTFHEExecutorAddress() internal pure returns (address expectedAddr) {
        expectedAddr = CONST.TFHE_EXECUTOR_ADDRESS;
    }

    function expectedKMSVerifierAddress() internal pure returns (address expectedAddr) {
        expectedAddr = CONST.KMS_VERIFIER_ADDRESS;
    }
    function expectedInputVerifierAddress() internal pure returns (address expectedAddr) {
        expectedAddr = CONST.INPUT_VERIFIER_ADDRESS;
    }

    function expectedFHEPaymentAddress() internal pure returns (address expectedAddr) {
        expectedAddr = CONST.FHE_PAYMENT_ADDRESS;
    }

    function expectedAddresses() internal pure returns (FFhevm.CoreAddresses memory) {
        FFhevm.CoreAddresses memory coreAddresses;
        coreAddresses.ACLAddress = expectedACLAddress();
        coreAddresses.FHEPaymentAddress = expectedFHEPaymentAddress();
        coreAddresses.InputVerifierAddress = expectedInputVerifierAddress();
        coreAddresses.KMSVerifierAddress = expectedKMSVerifierAddress();
        coreAddresses.TFHEExecutorAddress = expectedTFHEExecutorAddress();
        return coreAddresses;
    }
}
