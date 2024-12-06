// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {TFHEHandle} from "../../common/TFHEHandle.sol";
import {IRandomGenerator} from "../../common/interfaces/IRandomGenerator.sol";

import {einput} from "../../fhevm-debug/lib/TFHE.sol";

import {ITFHEDebuggerDB} from "../../debugger/impl/interfaces/ITFHEDebuggerDB.sol";

import {EncryptedInput} from "../../../FFhevm.sol";

import {EncryptedInputSigner} from "./EncryptedInputSigner.sol";
import {EncryptedInputList} from "./EncryptedInputList.sol";

// For gas metering
import {IForgeStdVmSafe as IVmSafe, forgeStdVmSafeAdd} from "../interfaces/IForgeStdVm.sol";

library EncryptedInputLib {
    // solhint-disable const-name-snakecase
    IVmSafe private constant vm = IVmSafe(forgeStdVmSafeAdd);

    function addBool(EncryptedInput memory self, bool value) internal {
        vm.pauseGasMetering();
        self._list.addBool(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function addBool(EncryptedInput memory self, bool value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.addBool(value, random);
        vm.resumeGasMetering();
    }

    function add4(EncryptedInput memory self, uint8 value) internal {
        vm.pauseGasMetering();
        self._list.add4(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function add4(EncryptedInput memory self, uint8 value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.add4(value, random);
        vm.resumeGasMetering();
    }

    function add8(EncryptedInput memory self, uint8 value) internal {
        vm.pauseGasMetering();
        self._list.add8(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function add8(EncryptedInput memory self, uint8 value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.add8(value, random);
        vm.resumeGasMetering();
    }

    function add16(EncryptedInput memory self, uint16 value) internal {
        vm.pauseGasMetering();
        self._list.add16(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function add16(EncryptedInput memory self, uint16 value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.add16(value, random);
        vm.resumeGasMetering();
    }

    function add32(EncryptedInput memory self, uint32 value) internal {
        vm.pauseGasMetering();
        self._list.add32(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function add32(EncryptedInput memory self, uint32 value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.add32(value, random);
        vm.resumeGasMetering();
    }

    function add64(EncryptedInput memory self, uint64 value) internal {
        vm.pauseGasMetering();
        self._list.add64(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function add64(EncryptedInput memory self, uint64 value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.add64(value, random);
        vm.resumeGasMetering();
    }

    function add128(EncryptedInput memory self, uint128 value) internal {
        vm.pauseGasMetering();
        self._list.add128(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function add128(EncryptedInput memory self, uint128 value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.add128(value, random);
        vm.resumeGasMetering();
    }

    function addAddress(EncryptedInput memory self, address value) internal {
        vm.pauseGasMetering();
        self._list.addAddress(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function addAddress(EncryptedInput memory self, address value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.addAddress(value, random);
        vm.resumeGasMetering();
    }

    function add256(EncryptedInput memory self, uint256 value) internal {
        vm.pauseGasMetering();
        self._list.add256(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function add256(EncryptedInput memory self, uint256 value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.add256(value, random);
        vm.resumeGasMetering();
    }

    function addBytes64(EncryptedInput memory self, bytes memory value) internal {
        vm.pauseGasMetering();
        self._list.addBytes64(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function addBytes64(EncryptedInput memory self, bytes memory value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.addBytes64(value, random);
        vm.resumeGasMetering();
    }

    function addBytes128(EncryptedInput memory self, bytes memory value) internal {
        vm.pauseGasMetering();
        self._list.addBytes128(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function addBytes128(EncryptedInput memory self, bytes memory value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.addBytes128(value, random);
        vm.resumeGasMetering();
    }

    function addBytes256(EncryptedInput memory self, bytes memory value) internal {
        vm.pauseGasMetering();
        self._list.addBytes256(value, bytes32(IRandomGenerator(self._randomGeneratorAddress).randomUint()));
        vm.resumeGasMetering();
    }

    function addBytes256(EncryptedInput memory self, bytes memory value, bytes32 random) internal {
        vm.pauseGasMetering();
        self._list.addBytes256(value, random);
        vm.resumeGasMetering();
    }

    function encrypt(EncryptedInput memory self) internal returns (einput[] memory handles, bytes memory inputProof) {
        vm.pauseGasMetering();
        uint256[] memory _handles;
        (_handles, inputProof) = self._list.encrypt(self._signer, self._contractAddress, self._userAddress);

        require(_handles.length <= 255);
        require(_handles.length == self._list._length);

        ITFHEDebuggerDB debuggerDB = ITFHEDebuggerDB(self._debuggerDBAddress);

        handles = new einput[](_handles.length);

        for (uint16 i = 0; i < _handles.length; i++) {
            uint8 typeCt = self._list._items[i]._type;
            uint256 h = _handles[i];
            //typeOf(_handles[i]) == uint8(_handles[i] >> 8)
            require(uint8(h >> 8) == typeCt);
            TFHEHandle.checkTypeEq(h, typeCt);

            if (TFHEHandle.isType256Bits(typeCt)) {
                // 256-bits
                debuggerDB.insertEncryptedInput(h, self._list._items[i]._numericalValue, typeCt);
            } else {
                // bytes
                debuggerDB.insertEncryptedInput(h, self._list._items[i]._bytesValue, typeCt);
            }

            handles[i] = einput.wrap(bytes32(h));
        }

        vm.resumeGasMetering();
    }

    function encryptSingleton(EncryptedInput memory self) internal returns (einput handle, bytes memory inputProof) {
        vm.pauseGasMetering();
        require(self._list._length == 1, "encryptSingle only supports list with only one element");

        uint256[] memory _handles;
        (_handles, inputProof) = self._list.encrypt(self._signer, self._contractAddress, self._userAddress);

        require(_handles.length == 1);
        uint256 h = _handles[0];

        uint8 typeCt = self._list._items[0]._type;
        //typeOf(_handles[i]) == uint8(_handles[i] >> 8)
        //require(uint8(h >> 8) == typeCt);
        TFHEHandle.checkTypeEq(h, typeCt);

        ITFHEDebuggerDB debuggerDB = ITFHEDebuggerDB(self._debuggerDBAddress);

        if (TFHEHandle.isType256Bits(typeCt)) {
            // 256-bits
            debuggerDB.insertEncryptedInput(h, self._list._items[0]._numericalValue, typeCt);
        } else {
            // bytes
            debuggerDB.insertEncryptedInput(h, self._list._items[0]._bytesValue, typeCt);
        }

        handle = einput.wrap(bytes32(h));
        vm.resumeGasMetering();
    }
}
