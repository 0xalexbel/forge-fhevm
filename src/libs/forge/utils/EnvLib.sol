// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "../interfaces/IForgeStdVm.sol";
import {FFhevm} from "../../../FFhevm.sol";

import {console} from "forge-std/src/console.sol";

library EnvLib {
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    function envSigner(string memory envName, uint256 defaultPk) internal returns (FFhevm.Signer memory signer) {
        // setup fhevm deployer
        uint256 _pk = envPrivateKey(envName);
        if (_pk == 0) {
            _pk = defaultPk;
        }
        signer.addr = (_pk != 0) ? vm.rememberKey(_pk) : address(0);
        signer.privateKey = _pk;
    }

    function envSignersArray(string memory envNamePrefix, uint256[] memory defaultPks)
        internal
        returns (FFhevm.Signer[] memory signers)
    {
        signers = new FFhevm.Signer[](defaultPks.length);
        string memory firstMissing = "";
        uint256 countMissing = 0;
        for (uint256 i = 0; i < signers.length; ++i) {
            string memory envName = string.concat(envNamePrefix, vm.toString(i));
            if (!vm.envExists(envName)) {
                if (countMissing == 0) {
                    firstMissing = envName;
                }
                countMissing++;
            }
            signers[i] = envSigner(envName, defaultPks[i]);
        }

        if (countMissing > 0 && countMissing < signers.length) {
            revert(string.concat("Missing signer env variable ", firstMissing));
        }
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

    function envAddressOr(string memory envName, address defaultValue) internal view returns (address) {
        if (!vm.envExists(envName)) {
            return defaultValue;
        }

        string memory envStr = vm.envString(envName);
        try vm.parseAddress(envStr) returns (address parsedValue) {
            return parsedValue;
        } catch {
            return defaultValue;
        }
    }
}
