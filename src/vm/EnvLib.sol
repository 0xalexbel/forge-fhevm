// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Vm} from "forge-std/Vm.sol";

library EnvLib {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function envPrivateKey(string memory envName) public view returns (uint256) {
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

    function envMnemonicOr(string memory envName, string memory defaultValue) public view returns (string memory) {
        if (!vm.envExists(envName)) {
            return defaultValue;
        }

        string memory s = vm.envString(envName);
        if (bytes(s).length == 0) {
            return defaultValue;
        }

        return s;
    }

    function envUIntOr(string memory envName, uint256 defaultValue) public view returns (uint256) {
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

    function envBoolOr(string memory envName, bool defaultValue) public view returns (bool) {
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
