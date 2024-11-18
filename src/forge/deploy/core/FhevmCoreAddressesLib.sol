// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {aclAdd} from "fhevm-core-contracts/addresses/ACLAddress.sol";
import {kmsVerifierAdd} from "fhevm-core-contracts/addresses/KMSVerifierAddress.sol";
import {inputVerifierAdd} from "fhevm-core-contracts/addresses/InputVerifierAddress.sol";
import {coprocessorAdd} from "fhevm-core-contracts/addresses/CoprocessorAddress.sol";
import {fhePaymentAdd} from "fhevm-core-contracts/addresses/FHEPaymentAddress.sol";
import {tfheExecutorAdd} from "fhevm-core-contracts/addresses/TFHEExecutorAddress.sol";
import {AddressLib} from "../../utils/AddressLib.sol";

/// Note: forge does not handle libraries very well in a script setUp context.
/// Therefore, solidity code like this one is deployed as a contract instead of a library
library FhevmCoreAddressesLib {
    uint8 private constant ACLImplNonce = 0;
    uint8 private constant ACLNonce = 1;
    uint8 private constant TFHEExecutorImplNonce = 2;
    uint8 private constant TFHEExecutorNonce = 3;
    uint8 private constant KMSVerifierImplNonce = 4;
    uint8 private constant KMSVerifierNonce = 5;
    uint8 private constant InputVerifierImplNonce = 6;
    uint8 private constant InputVerifierNonce = 7;
    uint8 private constant FHEPaymentImplNonce = 8;
    uint8 private constant FHEPaymentNonce = 9;
    uint8 private constant TFHEExecutorDBNonce = 10;

    /// Returns a tuple of two addresses:
    /// - the computed 'ACL' contact implementation address
    /// - the 'ACL' contract address
    /// Fails if the 'ACL' contact address differs from the value of 'aclAdd' stored in
    /// the 'fhevm/lib/ACLAddress.sol' solidity file.
    function expectedCreateACLAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, ACLImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, ACLNonce);

        require(
            aclAdd == expectedAddr,
            "ACL contract address differs from its expected create address. Address solidity files must be regenerated."
        );
    }

    /// Returns a tuple of two addresses:
    /// - the computed 'TFHEExecutor' contact implementation address
    /// - the 'TFHEExecutor' contract address
    /// Fails if the 'TFHEExecutor' contact address differs from the value of 'tfheExecutorAdd' stored in
    /// the 'fhevm/lib/TFHEExecutorAddress.sol' solidity file.
    function expectedCreateTFHEExecutorAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, TFHEExecutorImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, TFHEExecutorNonce);

        require(
            tfheExecutorAdd == expectedAddr,
            "TFHEExecutor contract address differs from its expected create address. Address solidity files must be regenerated."
        );
    }

    /// Returns a tuple of two addresses:
    /// - the computed 'KMSVerifier' contact implementation address
    /// - the 'KMSVerifier' contract address
    /// Fails if the 'KMSVerifier' contact address differs from the value of 'kmsVerifierAdd' stored in
    /// the 'fhevm/lib/KMSVerifierAddress.sol' solidity file.
    function expectedCreateKMSVerifierAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, KMSVerifierImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, KMSVerifierNonce);

        require(
            kmsVerifierAdd == expectedAddr,
            "KMSVerifier contract address differs from its expected create address. Address solidity files must be regenerated."
        );
    }

    /// Returns a tuple of two addresses:
    /// - the computed 'InputVerifier' contact implementation address
    /// - the 'InputVerifier' contract address
    /// Fails if the 'InputVerifier' contact address differs from the value of 'inputVerifierAdd' stored in
    /// the 'fhevm/lib/InputVerifierAddress.sol' solidity file.
    function expectedCreateInputVerifierAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, InputVerifierImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, InputVerifierNonce);

        require(
            inputVerifierAdd == expectedAddr,
            "InputVerifier contract address differs from its expected create address. Address solidity files must be regenerated."
        );
    }

    /// Returns a tuple of two addresses:
    /// - the computed 'FHEPayment' contact implementation address
    /// - the 'FHEPayment' contract address
    /// Fails if the 'FHEPayment' contact address differs from the value of 'fhePaymentAdd' stored in
    /// the 'fhevm/lib/FHEPaymentAddress.sol' solidity file.
    function expectedCreateFHEPaymentAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, FHEPaymentImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, FHEPaymentNonce);

        require(
            fhePaymentAdd == expectedAddr,
            "FHEPayment contract address differs from its expected create address. Address solidity files must be regenerated."
        );
    }

    /// FHEVM contracts

    function computeCreateACLAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, ACLNonce);
    }

    function computeCreateTFHEExecutorAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, TFHEExecutorNonce);
    }

    function computeCreateKMSVerifierAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, KMSVerifierNonce);
    }

    function computeCreateInputVerifierAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, InputVerifierNonce);
    }

    function computeCreateFHEPaymentAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, FHEPaymentNonce);
    }

    /// Fails if the provided address is not equal to 'fhevm/lib/CoprocessorAddress.sol'
    function checkCoprocessorAddress(address coprocAddress) internal pure {
        require(
            coprocessorAdd == coprocAddress,
            "Coprocessor address mismtach. The coprocessor private key does not match the required address stored in 'fhevm/lib/CoprocessorAddress.sol'"
        );
    }
}
