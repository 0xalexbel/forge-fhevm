// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

library AddressLib {
    function computeCreateAddress(address _origin, uint256 _nonce) internal pure returns (address) {
        bytes memory data;
        if (_nonce == 0x00) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
        } else if (_nonce <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
        } else if (_nonce <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce));
        } else if (_nonce <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce));
        } else if (_nonce <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce));
        } else {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce));
        }
        return address(uint160(uint256(keccak256(data))));
    }

    function isDeployed(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getOwner(address contractAddress) internal view returns (address) {
        require(contractAddress != address(0), "Null contract address");
        (bool success, bytes memory returnData) = contractAddress.staticcall(abi.encodeWithSignature("owner()"));
        if (!success || returnData.length == 0) {
            return address(0);
        }
        return abi.decode(returnData, (address));
    }
}
