// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {AddressLib} from "../../../common/AddressLib.sol";

import {FFhevm} from "../../../../FFhevm.sol";

import {EnvLib} from "../../utils/EnvLib.sol";
import {DeployError} from "../error.sol";

import "./constants.sol" as CONST;

library DebuggerAddressesLib {
    function checkTFHEDebuggerAddress(address addr) internal pure {
        require(
            CONST.FFHEVM_DEBUGGER_ADDRESS == addr,
            DeployError.message("TFHEDebugger", CONST.FFHEVM_DEBUGGER_ADDRESS, addr)
        );
    }

    function checkTFHEDebuggerDBAddress(address addr) internal pure {
        require(
            CONST.FFHEVM_DEBUGGER_DB_ADDRESS == addr,
            DeployError.message("TFHEDebuggerDB", CONST.FFHEVM_DEBUGGER_DB_ADDRESS, addr)
        );
    }

    function expectedCreateTFHEDebuggerAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce)
    {
        expectedImplNonce = CONST.TFHEDebuggerImplNonce;
        expectedNonce = CONST.TFHEDebuggerNonce;
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, expectedImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, expectedNonce);

        require(
            CONST.FFHEVM_DEBUGGER_ADDRESS == expectedAddr,
            DeployError.message(
                "TFHEDebugger", CONST.FFHEVM_DEBUGGER_ADDRESS, expectedAddr, deployerAddr, expectedNonce
            )
        );
    }

    function expectedCreateTFHEDebuggerDBAddress(address deployerAddr)
        internal
        pure
        returns (address expectedImplAddr, address expectedAddr, uint64 expectedImplNonce, uint64 expectedNonce)
    {
        expectedImplNonce = CONST.TFHEDebuggerDBImplNonce;
        expectedNonce = CONST.TFHEDebuggerDBNonce;
        expectedImplAddr = AddressLib.computeCreateAddress(deployerAddr, expectedImplNonce);
        expectedAddr = AddressLib.computeCreateAddress(deployerAddr, expectedNonce);

        require(
            CONST.FFHEVM_DEBUGGER_DB_ADDRESS == expectedAddr,
            DeployError.message(
                "TFHEDebuggerDB", CONST.FFHEVM_DEBUGGER_DB_ADDRESS, expectedAddr, deployerAddr, expectedNonce
            )
        );
    }

    function computeCreateTFHEDebuggerAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, CONST.TFHEDebuggerNonce);
    }

    function computeCreateTFHEDebuggerDBAddress(address deployerAddr) internal pure returns (address) {
        return AddressLib.computeCreateAddress(deployerAddr, CONST.TFHEDebuggerDBNonce);
    }

    function computeAddresses(address deployerAddr) internal pure returns (FFhevm.DebuggerAddresses memory addresses) {
        addresses.TFHEDebuggerAddress = computeCreateTFHEDebuggerAddress(deployerAddr);
        addresses.TFHEDebuggerDBAddress = computeCreateTFHEDebuggerDBAddress(deployerAddr);
    }

    function _tryCallGetDebuggerDB(address debuggerAddr) private view returns (address) {
        (bool success, bytes memory returnData) = debuggerAddr.staticcall(abi.encodeWithSignature("getDebuggerDB()"));
        if (!success || returnData.length == 0) {
            return address(0);
        }
        return abi.decode(returnData, (address));
    }

    function readEnvAddresses() internal view returns (FFhevm.DebuggerAddresses memory) {
        FFhevm.DebuggerAddresses memory addresses;

        addresses.TFHEDebuggerAddress = EnvLib.envAddressOr(CONST.TFHEDebuggerAddressEnvName, address(0));
        addresses.TFHEDebuggerDBAddress = EnvLib.envAddressOr(CONST.TFHEDebuggerDBAddressEnvName, address(0));

        if (addresses.TFHEDebuggerAddress == address(0) && addresses.TFHEDebuggerDBAddress == address(0)) {
            return addresses;
        }

        if (addresses.TFHEDebuggerAddress == address(0)) {
            revert("Missing TFHEDebugger contract address env value");
        } else {
            checkTFHEDebuggerAddress(addresses.TFHEDebuggerAddress);
        }

        if (addresses.TFHEDebuggerDBAddress == address(0)) {
            addresses.TFHEDebuggerDBAddress = _tryCallGetDebuggerDB(addresses.TFHEDebuggerAddress);
        }

        if (addresses.TFHEDebuggerDBAddress == address(0)) {
            revert("Missing TFHEDebuggerDB contract address env value");
        } else {
            checkTFHEDebuggerDBAddress(addresses.TFHEDebuggerDBAddress);
        }

        return addresses;
    }
}
