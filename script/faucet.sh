#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cast send --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0xea63e594de67c2b32545c4b8fec9676285602852 -r http://127.0.0.1:8545
cast send --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x305F1F471e9baCFF2b3549F9601f9A4BEafc94e1 -r http://127.0.0.1:8545
cast send --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x5e85529F07A87868b853fda7eB518Ce1B6f58B92 -r http://127.0.0.1:8545
cast send --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x568294c3043895f54d076Dd453345bAA2f35015e -r http://127.0.0.1:8545