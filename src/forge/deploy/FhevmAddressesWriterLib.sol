// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "../interfaces/IForgeStdVm.sol";
import {FhevmCoreAddressesLib} from "../deploy/core/FhevmCoreAddressesLib.sol";
import {FhevmGatewayAddressesLib} from "../deploy/gateway/FhevmGatewayAddressesLib.sol";

/// Note: forge does not handle libraries very well in a script setUp context.
/// Therefore, solidity code like this one is deployed as a contract instead of a library
library FhevmAddressesWriterLib {
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    /// Generates '<rootDir>/fhevm-core-contracts/addresses/ACLAddress.sol' solidity file.
    /// This file contains a single line formatted as follow:
    /// "address constant aclAdd = <address>" with <address> = the required 'ACL' contract address.
    function writeACLAddressDotSol(address deployerAddr, string memory rootDir) private {
        _writeDotSolAddressFile(
            "aclAdd",
            FhevmCoreAddressesLib.computeCreateACLAddress(deployerAddr),
            string.concat(rootDir, "/fhevm-core-contracts/addresses/ACLAddress.sol")
        );
    }

    /// Generates '<rootDir>/fhevm-core-contracts/addresses/TFHEExecutorAddress.sol' solidity file.
    /// This file contains a single line formatted as follow:
    /// "address constant tfheExecutorAdd = <address>" with <address> = the required 'TFHEExecutor' contract address.
    function writeTFHEExecutorAddressDotSol(address deployerAddr, string memory rootDir) private {
        _writeDotSolAddressFile(
            "tfheExecutorAdd",
            FhevmCoreAddressesLib.computeCreateTFHEExecutorAddress(deployerAddr),
            string.concat(rootDir, "/fhevm-core-contracts/addresses/TFHEExecutorAddress.sol")
        );
    }

    /// Generates '<rootDir>/fhevm-core-contracts/addresses/KMSVerifierAddress.sol' solidity file.
    /// This file contains a single line formatted as follow:
    /// "address constant kmsVerifierAdd = <address>" with <address> = the required 'KMSVerifier' contract address.
    function writeKMSVerifierAddressDotSol(address deployerAddr, string memory rootDir) private {
        _writeDotSolAddressFile(
            "kmsVerifierAdd",
            FhevmCoreAddressesLib.computeCreateKMSVerifierAddress(deployerAddr),
            string.concat(rootDir, "/fhevm-core-contracts/addresses/KMSVerifierAddress.sol")
        );
    }

    /// Generates '<rootDir>/fhevm-core-contracts/addresses/InputVerifierAddress.sol' solidity file.
    /// This file contains a single line formatted as follow:
    /// "address constant inputVerifierAdd = <address>" with <address> = the required 'InputVerifier' contract address.
    function writeInputVerifierAddressDotSol(address deployerAddr, string memory rootDir) private {
        _writeDotSolAddressFile(
            "inputVerifierAdd",
            FhevmCoreAddressesLib.computeCreateInputVerifierAddress(deployerAddr),
            string.concat(rootDir, "/fhevm-core-contracts/addresses/InputVerifierAddress.sol")
        );
    }

    /// Generates '<rootDir>/fhevm-core-contracts/addresses/FHEPaymentAddress.sol' solidity file.
    /// This file contains a single line formatted as follow:
    /// "address constant fhePaymentAdd = <address>" with <address> = the required 'FHEPayment' contract address.
    function writeFHEPaymentAddressDotSol(address deployerAddr, string memory rootDir) private {
        _writeDotSolAddressFile(
            "fhePaymentAdd",
            FhevmCoreAddressesLib.computeCreateFHEPaymentAddress(deployerAddr),
            string.concat(rootDir, "/fhevm-core-contracts/addresses/FHEPaymentAddress.sol")
        );
    }

    /// Generates '<rootDir>/fhevm/gateway/lib/GatewayContractAddress.sol' solidity file.
    /// This file contains a single line formatted as follow:
    /// "address constant GATEWAY_CONTRACT_PREDEPLOY_ADDRESS = <address>" with <address> = the required 'GatewayContract' contract address.
    function writeGatewayContractAddressDotSol(address deployerAddr, string memory rootDir) private {
        _writeDotSolAddressFile(
            "GATEWAY_CONTRACT_PREDEPLOY_ADDRESS",
            FhevmGatewayAddressesLib.computeCreateGatewayContractAddress(deployerAddr),
            string.concat(rootDir, "/fhevm/gateway/lib/GatewayContractAddress.sol")
        );
    }

    /// Write a contract address solidity file with path equals './forge-fhevm/<dotSolRelPathname>'
    /// The file content is as follow:
    ///
    /// // SPDX-License-Identifier: BSD-3-Clause-Clear
    ///
    /// pragma solidity ^0.8.24;
    ///
    /// address constant <varName> = <varAddress>;
    ///
    function _writeDotSolAddressFile(string memory varName, address varAddress, string memory path) private {
        string memory s =
            "// SPDX-License-Identifier: BSD-3-Clause-Clear\n\npragma solidity ^0.8.24;\n\naddress constant ";
        s = string.concat(s, varName, " = ", vm.toString(varAddress), ";\n");
        vm.writeFile(path, s);
    }
}
