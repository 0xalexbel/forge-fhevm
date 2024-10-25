#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ZAMADIR=$(cd "${SCRIPT_DIR}/../../../../github/repos/zama-ai/fhevm" && pwd) || { exit 1; }
ROOTDIR=$(cd "${SCRIPT_DIR}/.." && pwd) || { exit 1; }

cp -f ${ROOTDIR}/lib/Impl.zama.sol ${ROOTDIR}/lib/Impl.sol

diff -bur ${ZAMADIR}/payment ${ROOTDIR}/payment
diff -bur ${ZAMADIR}/gateway ${ROOTDIR}/gateway
diff -bur ${ZAMADIR}/lib ${ROOTDIR}/lib

cp -f ${ROOTDIR}/lib/Impl.forge-fhevm.sol ${ROOTDIR}/lib/Impl.sol

