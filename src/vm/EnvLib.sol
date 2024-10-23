// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "./IForgeStdVmSafe.sol";
import {AddressLib} from "../utils/AddressLib.sol";

library EnvLib {
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    function envSigner(string memory envVarName, uint256 defaultPk)
        internal
        view
        returns (AddressLib.Signer memory signer)
    {
        // setup fhevm deployer
        uint256 _pk = envPrivateKey(envVarName);
        if (_pk == 0) {
            _pk = defaultPk;
        }
        //signer.addr = vm.rememberKey(_pk);
        signer.addr = vm.addr(_pk);
        signer.privateKey = _pk;
    }

    function envPrivateKey(string memory envName) internal view returns (uint256) {
        if (!vm.envExists(envName)) {
            return 0;
        }

        string memory envStr = vm.envString(envName);
        if (vm.indexOf("0x", envStr) == type(uint256).max) {
            envStr = string.concat("0x", envStr);
        }

        try vm.parseUint(envStr) returns (uint256 parsedValue) {
            return parsedValue;
        } catch {
            return 0;
        }
    }

    function envMnemonicOr(string memory envName, string memory defaultValue) internal view returns (string memory) {
        if (!vm.envExists(envName)) {
            return defaultValue;
        }

        string memory s = vm.envString(envName);
        if (bytes(s).length == 0) {
            return defaultValue;
        }

        return s;
    }

    function envUIntOr(string memory envName, uint256 defaultValue) internal view returns (uint256) {
        if (!vm.envExists(envName)) {
            return defaultValue;
        }

        string memory envStr = vm.envString(envName);
        try vm.parseUint(envStr) returns (uint256 parsedValue) {
            return parsedValue;
        } catch {
            return defaultValue;
        }
    }

    function envBoolOr(string memory envName, bool defaultValue) internal view returns (bool) {
        if (!vm.envExists(envName)) {
            return defaultValue;
        }

        string memory envStr = vm.envString(envName);
        try vm.parseBool(envStr) returns (bool parsedValue) {
            return parsedValue;
        } catch {
            return defaultValue;
        }
    }
}
