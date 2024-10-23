// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {aclAdd} from "fhevm/lib/ACLAddress.sol";
import {kmsVerifierAdd} from "fhevm/lib/KMSVerifierAddress.sol";
import {inputVerifierAdd} from "fhevm/lib/InputVerifierAddress.sol";
import {coprocessorAdd} from "fhevm/lib/CoprocessorAddress.sol";
import {fhePaymentAdd} from "fhevm/lib/FHEPaymentAddress.sol";
import {tfheExecutorAdd} from "fhevm/lib/TFHEExecutorAddress.sol";
import {GATEWAY_CONTRACT_PREDEPLOY_ADDRESS} from "fhevm/gateway/lib/GatewayContractAddress.sol";
import {tfheExecutorDBAdd} from "../executor/TFHEExecutorDBAddress.sol";
import {AddressLib} from "../utils/AddressLib.sol";

/// Note: forge does not handle libraries very well in a script setUp context.
/// Therefore, solidity code like this one is deployed as a contract instead of a library
library FhevmAddressesLib {
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

    uint8 private constant GatewayContractImplNonce = 0;
    uint8 private constant GatewayContractNonce = 1;

    function computeCreateAddress(address _origin, uint256 _nonce) private pure returns (address) {
        address sol_a = AddressLib.computeCreateAddress(_origin, _nonce);

        // // For debug purpose
        // if (address(forgeVm).codehash != bytes32(0)) {
        //     address forgeVm_a = forgeVm.computeCreateAddress(_origin, _nonce);
        //     require(forgeVm_a == sol_a, "computeCreateAddress solidity function failed.");
        // }

        return sol_a;
    }

    /// FHEVM contracts

    /// Returns a tuple of two addresses:
    /// - the computed 'ACL' contact implementation address
    /// - the 'ACL' contract address
    /// Fails if the 'ACL' contact address differs from the value of 'aclAdd' stored in
    /// the 'fhevm/lib/ACLAddress.sol' solidity file.
    function expectedCreateACLAddress(address deployerAddr)
        public
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = computeCreateAddress(deployerAddr, ACLImplNonce);
        expectedAddr = computeCreateAddress(deployerAddr, ACLNonce);

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
        public
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = computeCreateAddress(deployerAddr, TFHEExecutorImplNonce);
        expectedAddr = computeCreateAddress(deployerAddr, TFHEExecutorNonce);

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
        public
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = computeCreateAddress(deployerAddr, KMSVerifierImplNonce);
        expectedAddr = computeCreateAddress(deployerAddr, KMSVerifierNonce);

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
        public
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = computeCreateAddress(deployerAddr, InputVerifierImplNonce);
        expectedAddr = computeCreateAddress(deployerAddr, InputVerifierNonce);

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
        public
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = computeCreateAddress(deployerAddr, FHEPaymentImplNonce);
        expectedAddr = computeCreateAddress(deployerAddr, FHEPaymentNonce);

        require(
            fhePaymentAdd == expectedAddr,
            "FHEPayment contract address differs from its expected create address. Address solidity files must be regenerated."
        );
    }

    /// Returns a tuple of two addresses:
    /// - the computed 'GatewayContract' contact implementation address
    /// - the 'GatewayContract' contract address
    /// Fails if the 'GatewayContract' contact address differs from the value of 'GATEWAY_CONTRACT_PREDEPLOY_ADDRESS' stored in
    /// the 'fhevm/gateway/lib/GatewayContractAddress.sol' solidity file.
    function expectedCreateGatewayContractAddress(address deployerAddr)
        public
        pure
        returns (address expectedImplAddr, address expectedAddr)
    {
        expectedImplAddr = computeCreateAddress(deployerAddr, GatewayContractImplNonce);
        expectedAddr = computeCreateAddress(deployerAddr, GatewayContractNonce);

        require(
            GATEWAY_CONTRACT_PREDEPLOY_ADDRESS == expectedAddr,
            "GatewayContract contract address differs from its expected create address. Address solidity files must be regenerated."
        );
    }

    /// Extra contracts

    /// Returns a single address:
    /// - the 'TFHEExecutorDB' contract address
    /// Fails if the 'TFHEExecutorDB' contact address differs from the value of 'tfheExecutorDBAdd' stored in
    /// the 'fhevm/lib/TFHEExecutorDBAddress.sol' solidity file.
    function expectedCreateTFHEExecutorDBAddress(address deployerAddr) public pure returns (address expectedAddr) {
        expectedAddr = computeCreateAddress(deployerAddr, TFHEExecutorDBNonce);

        require(
            tfheExecutorDBAdd == expectedAddr,
            "TFHEExecutorDB contract address differs from its expected create address. Address solidity files must be regenerated."
        );
    }

    /// FHEVM contracts

    function computeCreateACLAddress(address deployerAddr) public pure returns (address) {
        return computeCreateAddress(deployerAddr, ACLNonce);
    }

    function computeCreateTFHEExecutorAddress(address deployerAddr) public pure returns (address) {
        return computeCreateAddress(deployerAddr, TFHEExecutorNonce);
    }

    function computeCreateKMSVerifierAddress(address deployerAddr) public pure returns (address) {
        return computeCreateAddress(deployerAddr, KMSVerifierNonce);
    }

    function computeCreateInputVerifierAddress(address deployerAddr) public pure returns (address) {
        return computeCreateAddress(deployerAddr, InputVerifierNonce);
    }

    function computeCreateFHEPaymentAddress(address deployerAddr) public pure returns (address) {
        return computeCreateAddress(deployerAddr, FHEPaymentNonce);
    }

    function computeCreateGatewayContractAddress(address deployerAddr) public pure returns (address) {
        return computeCreateAddress(deployerAddr, GatewayContractNonce);
    }

    /// Extra contracts

    function computeCreateTFHEExecutorDBAddress(address deployerAddr) public pure returns (address) {
        return computeCreateAddress(deployerAddr, TFHEExecutorDBNonce);
    }
}
