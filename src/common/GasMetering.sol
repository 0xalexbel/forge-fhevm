// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

interface IForgeStdVmSafeGasMetering {
    function pauseGasMetering() external;
    function resumeGasMetering() external;
}

library GasMetering {
    function pause(address _forgeVmAdd) internal {
        if (_forgeVmAdd != address(0)) {
            IForgeStdVmSafeGasMetering(_forgeVmAdd).pauseGasMetering();
        }
    }

    function resume(address _forgeVmAdd) internal {
        if (_forgeVmAdd != address(0)) {
            IForgeStdVmSafeGasMetering(_forgeVmAdd).resumeGasMetering();
        }
    }
}
