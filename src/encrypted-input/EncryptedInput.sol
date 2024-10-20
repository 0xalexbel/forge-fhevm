// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {EncryptedInputSigner} from "./EncryptedInputSigner.sol";
import {EncryptedInputList} from "./EncryptedInputList.sol";
import {TFHEExecutorDB} from "../executor/TFHEExecutorDB.sol";
import {IRandomGenerator} from "../utils/IRandomGenerator.sol";
import {einput, Common} from "fhevm/lib/TFHE.sol";

struct EncryptedInput {
    EncryptedInputList _list;
    EncryptedInputSigner _signer;
    address _contractAddress;
    address _userAddress;
    address _db;
    IRandomGenerator _randomGenerator;
}

library EncryptedInputLib {
    function addBool(EncryptedInput memory self, bool value) internal {
        self._list.addBool(value, bytes32(self._randomGenerator.randomUint()));
    }

    function addBool(EncryptedInput memory self, bool value, bytes32 random) internal pure {
        self._list.addBool(value, random);
    }

    function add4(EncryptedInput memory self, uint8 value) internal {
        self._list.add4(value, bytes32(self._randomGenerator.randomUint()));
    }

    function add4(EncryptedInput memory self, uint8 value, bytes32 random) internal pure {
        self._list.add4(value, random);
    }

    function add8(EncryptedInput memory self, uint8 value) internal {
        self._list.add8(value, bytes32(self._randomGenerator.randomUint()));
    }

    function add8(EncryptedInput memory self, uint8 value, bytes32 random) internal pure {
        self._list.add8(value, random);
    }

    function add16(EncryptedInput memory self, uint16 value) internal {
        self._list.add16(value, bytes32(self._randomGenerator.randomUint()));
    }

    function add16(EncryptedInput memory self, uint16 value, bytes32 random) internal pure {
        self._list.add16(value, random);
    }

    function add32(EncryptedInput memory self, uint32 value) internal {
        self._list.add32(value, bytes32(self._randomGenerator.randomUint()));
    }

    function add32(EncryptedInput memory self, uint32 value, bytes32 random) internal pure {
        self._list.add32(value, random);
    }

    function add64(EncryptedInput memory self, uint64 value) internal {
        self._list.add64(value, bytes32(self._randomGenerator.randomUint()));
    }

    function add64(EncryptedInput memory self, uint64 value, bytes32 random) internal pure {
        self._list.add64(value, random);
    }

    function add128(EncryptedInput memory self, uint128 value) internal {
        self._list.add128(value, bytes32(self._randomGenerator.randomUint()));
    }

    function add128(EncryptedInput memory self, uint128 value, bytes32 random) internal pure {
        self._list.add128(value, random);
    }

    function add256(EncryptedInput memory self, uint256 value) internal {
        self._list.add256(value, bytes32(self._randomGenerator.randomUint()));
    }

    function add256(EncryptedInput memory self, uint256 value, bytes32 random) internal pure {
        self._list.add256(value, random);
    }

    function addBytes64(EncryptedInput memory self, bytes memory value) internal {
        self._list.addBytes64(value, bytes32(self._randomGenerator.randomUint()));
    }

    function addBytes64(EncryptedInput memory self, bytes memory value, bytes32 random) internal pure {
        self._list.addBytes64(value, random);
    }

    function addBytes128(EncryptedInput memory self, bytes memory value) internal {
        self._list.addBytes128(value, bytes32(self._randomGenerator.randomUint()));
    }

    function addBytes128(EncryptedInput memory self, bytes memory value, bytes32 random) internal pure {
        self._list.addBytes128(value, random);
    }

    function addBytes256(EncryptedInput memory self, bytes memory value) internal {
        self._list.addBytes256(value, bytes32(self._randomGenerator.randomUint()));
    }

    function addBytes256(EncryptedInput memory self, bytes memory value, bytes32 random) internal pure {
        self._list.addBytes256(value, random);
    }

    function encrypt(EncryptedInput memory self) public returns (einput[] memory handles, bytes memory inputProof) {
        uint256[] memory _handles;
        (_handles, inputProof) = self._list.encrypt(self._signer, self._contractAddress, self._userAddress);

        require(_handles.length <= 255);
        require(_handles.length == self._list._length);

        TFHEExecutorDB db = TFHEExecutorDB(self._db);

        handles = new einput[](_handles.length);

        for (uint16 i = 0; i < _handles.length; i++) {
            uint8 typeCt = self._list._items[i]._type;

            //typeOf(_handles[i]) == uint8(_handles[i] >> 8)
            require(uint8(_handles[i] >> 8) == typeCt);

            if (typeCt <= Common.euint256_t) {
                db.insertDB256(_handles[i], self._list._items[i]._numericalValue, typeCt);
            } else {
                db.insertDB2048(_handles[i], self._list._items[i]._bytesValue, typeCt);
            }

            handles[i] = einput.wrap(bytes32(_handles[i]));
        }
    }

    function encryptSingleton(EncryptedInput memory self) public returns (einput handle, bytes memory inputProof) {
        require(self._list._length == 1, "encryptSingle only supports list with only one element");

        uint256[] memory _handles;
        (_handles, inputProof) = self._list.encrypt(self._signer, self._contractAddress, self._userAddress);

        require(_handles.length == 1);
        uint256 h = _handles[0];

        uint8 typeCt = self._list._items[0]._type;
        //typeOf(_handles[i]) == uint8(_handles[i] >> 8)
        require(uint8(h >> 8) == typeCt);

        TFHEExecutorDB db = TFHEExecutorDB(self._db);

        if (typeCt <= Common.euint256_t) {
            db.insertDB256(h, self._list._items[0]._numericalValue, typeCt);
        } else {
            db.insertDB2048(h, self._list._items[0]._bytesValue, typeCt);
        }

        handle = einput.wrap(bytes32(h));
    }
}

using EncryptedInputLib for EncryptedInput global;
