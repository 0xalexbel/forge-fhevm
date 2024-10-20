// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import "./ITFHEExecutorPlugin.sol";

abstract contract TFHEExecutorPluginStorage {
    /// @custom:storage-location erc7201:fhevm.storage.TFHEExecutorWithPlugin
    struct PluginStorage {
        ITFHEExecutorPlugin plugin;
    }

    // keccak256(abi.encode(uint256(keccak256("fhevm.storage.TFHEExecutor.TFHEExecutorPluginStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PluginStorageLocation = 0x827d9ec16e58e998500e12bca7860eb95dd34efdfbbb3d943c8cdf43c0244200;

    function _getPluginStorage() internal pure returns (PluginStorage storage $) {
        assembly {
            $.slot := PluginStorageLocation
        }
    }

    function plugin() public view virtual returns (ITFHEExecutorPlugin) {
        PluginStorage storage $ = _getPluginStorage();
        return $.plugin;
    }

    // Note: IS_TFHE_EXECUTOR_PLUGIN_STORAGE() must return true.
    function IS_TFHE_EXECUTOR_PLUGIN_STORAGE() public pure returns (bool) {
        return true;
    }

    function setPlugin(ITFHEExecutorPlugin _plugin) external {
        PluginStorage storage $ = _getPluginStorage();
        $.plugin = _plugin;
    }
}
