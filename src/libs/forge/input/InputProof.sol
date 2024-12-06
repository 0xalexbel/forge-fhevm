// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

library InputProof {
    function numHandles(bytes memory inputProof) internal pure returns (uint256) {
        require(inputProof.length > 0, "Empty input proof");
        return uint256(uint8(inputProof[0]));
    }

    function numKMSSigners(bytes memory inputProof) internal pure returns (uint256) {
        require(inputProof.length > 1, "Invalid input proof");
        return uint256(uint8(inputProof[1]));
    }

    function extractHashCT(bytes memory inputProof) internal pure returns (bytes32) {
        bytes32 hashCT;
        assembly {
            hashCT := mload(add(inputProof, 34))
        }
        return hashCT;
    }

    function checkLength(bytes memory inputProof) internal pure {
        uint256 _numHandles = numHandles(inputProof);
        uint256 _numKMSSigners = numKMSSigners(inputProof);

        require(inputProof.length == 99 + 32 * _numHandles + 65 * _numKMSSigners, "Invalid input proof length");
    }

    function extractHandles(bytes memory inputProof) internal pure returns (uint256[] memory) {
        uint256 _numHandles = numHandles(inputProof);

        checkLength(inputProof);

        bool hasVersion = false;
        uint8 version = 0;

        uint256[] memory listHandles = new uint256[](_numHandles);
        for (uint256 i = 0; i < _numHandles; i++) {
            uint256 element;
            assembly {
                element := mload(add(inputProof, add(66, mul(i, 32))))
            }
            // check all handles are from correct version
            if (!hasVersion) {
                hasVersion = true;
                version = uint8(element);
            } else {
                require(
                    uint8(element) == version,
                    "At least two elements in the proof have been encoded with different version"
                );
            }
            listHandles[i] = element;
        }
        return listHandles;
    }

    /*
        assembly ("memory-safe") {
            value := mload(add(buffer, add(0x20, offset)))
        }
    */

    function extractSignatureCoproc(bytes memory inputProof) internal pure returns (bytes memory) {
        checkLength(inputProof);
        uint256 _numHandles = numHandles(inputProof);
        bytes memory signatureCoproc = new bytes(65);
        for (uint256 i = 0; i < 65; i++) {
            signatureCoproc[i] = inputProof[34 + 32 * _numHandles + i];
        }
        return signatureCoproc;
    }
}
