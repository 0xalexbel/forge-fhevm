// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Common} from "../../lib/TFHE.sol";
import {EncryptedInputSigner} from "./EncryptedInputSigner.sol";
import {EncryptedInputItem} from "./EncryptedInputItem.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

struct EncryptedInputList {
    uint16 _length;
    uint16 _totalBits;
    EncryptedInputItem[256] _items;
}

library EncryptedInputListLib {
    function length(EncryptedInputList memory self) public pure returns (uint16) {
        return self._length;
    }

    function _addItem(EncryptedInputList memory self, EncryptedInputItem memory e) private pure {
        require(self._length < 256, "Packing more than 256 variables in a single input ciphertext is unsupported");
        require(
            self._totalBits + e._numBits <= 2048,
            "Packing more than 2048 bits in a single input ciphertext is unsupported"
        );
        self._items[self._length] = e;
        self._items[self._length]._index = uint8(self._length);
        self._length = self._length + 1;
        self._totalBits = self._totalBits + e._numBits;
    }

    function addBool(EncryptedInputList memory self, bool value, bytes32 random) internal pure {
        EncryptedInputItem memory e;
        e._type = Common.ebool_t;
        e._numBits = 2;
        uint8 v = (value) ? uint8(1) : uint8(0);
        e._data = bytes.concat(bytes1(e._type), bytes1(v), random);
        e._numericalValue = uint256(v);
        _addItem(self, e);
    }

    function add4(EncryptedInputList memory self, uint8 value, bytes32 random) internal pure {
        require(value < 16, "add4 failed. Value overflow.");
        EncryptedInputItem memory e;
        e._type = Common.euint4_t;
        e._numBits = 4;
        e._data = bytes.concat(bytes1(e._type), bytes1(value), random);
        e._numericalValue = uint256(value);
        _addItem(self, e);
    }

    function add8(EncryptedInputList memory self, uint8 value, bytes32 random) internal pure {
        EncryptedInputItem memory e;
        e._type = Common.euint8_t;
        e._numBits = 8;
        e._data = bytes.concat(bytes1(e._type), bytes1(value), random);
        e._numericalValue = uint256(value);
        _addItem(self, e);
    }

    function add16(EncryptedInputList memory self, uint16 value, bytes32 random) internal pure {
        EncryptedInputItem memory e;
        e._type = Common.euint16_t;
        e._numBits = 16;
        e._data = bytes.concat(bytes1(e._type), bytes2(value), random);
        e._numericalValue = uint256(value);
        _addItem(self, e);
    }

    function add32(EncryptedInputList memory self, uint32 value, bytes32 random) internal pure {
        EncryptedInputItem memory e;
        e._type = Common.euint32_t;
        e._numBits = 32;
        e._data = bytes.concat(bytes1(e._type), bytes4(value), random);
        e._numericalValue = uint256(value);
        _addItem(self, e);
    }

    function add64(EncryptedInputList memory self, uint64 value, bytes32 random) internal pure {
        EncryptedInputItem memory e;
        e._type = Common.euint64_t;
        e._numBits = 64;
        e._data = bytes.concat(bytes1(e._type), bytes8(value), random);
        e._numericalValue = uint256(value);
        _addItem(self, e);
    }

    function add128(EncryptedInputList memory self, uint128 value, bytes32 random) internal pure {
        EncryptedInputItem memory e;
        e._type = Common.euint128_t;
        e._numBits = 128;
        e._data = bytes.concat(bytes1(e._type), bytes16(value), random);
        e._numericalValue = uint256(value);
        _addItem(self, e);
    }

    function addAddress(EncryptedInputList memory self, address value, bytes32 random) internal pure {
        EncryptedInputItem memory e;
        e._type = Common.euint160_t;
        e._numBits = 160;
        e._data = bytes.concat(bytes1(e._type), bytes20(value), random);
        e._numericalValue = uint256(uint160(value));
        _addItem(self, e);
    }

    function add256(EncryptedInputList memory self, uint256 value, bytes32 random) internal pure {
        EncryptedInputItem memory e;
        e._type = Common.euint256_t;
        e._numBits = 256;
        e._data = bytes.concat(bytes1(e._type), bytes32(value), random);
        e._numericalValue = value;
        _addItem(self, e);
    }

    function addBytes64(EncryptedInputList memory self, bytes memory value, bytes32 random) internal pure {
        require(value.length <= 64);
        bytes memory pad = new bytes(64 - value.length);
        EncryptedInputItem memory e;
        e._type = Common.ebytes64_t;
        e._numBits = 512;
        e._data = bytes.concat(bytes1(e._type), pad, value, random);
        e._bytesValue = value;
        _addItem(self, e);
    }

    function addBytes128(EncryptedInputList memory self, bytes memory value, bytes32 random) internal pure {
        require(value.length <= 128);
        bytes memory pad = new bytes(128 - value.length);
        EncryptedInputItem memory e;
        e._type = Common.ebytes128_t;
        e._numBits = 1024;
        e._data = bytes.concat(bytes1(e._type), pad, value, random);
        e._bytesValue = value;
        _addItem(self, e);
    }

    function addBytes256(EncryptedInputList memory self, bytes memory value, bytes32 random) internal pure {
        require(value.length <= 256);
        bytes memory pad = new bytes(256 - value.length);
        EncryptedInputItem memory e;
        e._type = Common.ebytes256_t;
        e._numBits = 2048;
        e._data = bytes.concat(bytes1(e._type), pad, value, random);
        e._bytesValue = value;
        _addItem(self, e);
    }

    function encryptedData(EncryptedInputList memory self) internal pure returns (bytes memory) {
        bytes memory b;
        for (uint16 i = 0; i < self._length; ++i) {
            b = bytes.concat(b, self._items[i]._data);
        }
        return b;
    }

    function hashData(EncryptedInputList memory self) internal pure returns (bytes32) {
        return keccak256(encryptedData(self));
    }

    function computeHandles(EncryptedInputList memory self) internal pure returns (uint256[] memory) {
        bytes32 hashedData = keccak256(encryptedData(self));
        return _handles(self, hashedData);
    }

    function _handles(EncryptedInputList memory self, bytes32 hashedData) private pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](self._length);
        for (uint16 i = 0; i < self._length; ++i) {
            bytes32 h = self._items[i].handle(hashedData);
            arr[i] = uint256(h);
        }
        return arr;
    }

    /**
     * Format:
     *     =======
     *     for coprocessor : numHandles + numSignersKMS + hash(bundleCiphertext) + list_handles + signatureCopro + signatureKMSSigners
     *     for native      : numHandles + numSignersKMS +                        + list_handles +                + signatureKMSSigners + bundleCiphertext
     *
     *     Total length:
     *     =============
     *     for coprocessor : 1+1+32+NUM_HANDLES*32+65+65*numSignersKMS
     *     for native      : 1+1+NUM_HANDLES*32+65*numSignersKMS+bundleCiphertext.length
     */
    function encrypt(
        EncryptedInputList memory self,
        EncryptedInputSigner memory signer,
        address contractAddress,
        address userAddress
    ) internal pure returns (uint256[] memory handles, bytes memory inputProof) {
        if (self._length < 256) {
            inputProof = bytes.concat(bytes1(uint8(self._length)), bytes1(uint8(signer.kmsSigners.length)));
        } else {
            inputProof = bytes.concat(bytes2(self._length), bytes1(uint8(signer.kmsSigners.length)));
        }

        // Equivalent to hashEncryptedData()
        bytes memory _bundleCiphertext = encryptedData(self);
        bytes32 hashedData = keccak256(_bundleCiphertext);

        if (signer.coprocSigner != uint256(0)) {
            inputProof = bytes.concat(inputProof, hashedData);
        }
        handles = _handles(self, hashedData);

        for (uint8 i = 0; i < handles.length; ++i) {
            inputProof = bytes.concat(inputProof, bytes32(handles[i]));
        }

        // Coproc
        if (signer.coprocSigner != 0) {
            bytes memory sig = signer.coprocSign(hashedData, handles, userAddress, contractAddress);
            inputProof = bytes.concat(inputProof, sig);
        }

        for (uint8 i = 0; i < signer.kmsSigners.length; ++i) {
            bytes memory sig = signer.kmsSign(hashedData, userAddress, contractAddress, i);
            inputProof = bytes.concat(inputProof, sig);
        }

        // Native
        if (signer.coprocSigner == 0) {
            inputProof = bytes.concat(inputProof, _bundleCiphertext);
        }
    }
}

using EncryptedInputListLib for EncryptedInputList global;
