#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ZAMADIR=$(cd "${SCRIPT_DIR}/../../../../github/repos/zama-ai/fhevm" && pwd) || { exit 1; }
ROOTDIR=$(cd "${SCRIPT_DIR}/.." && pwd) || { exit 1; }
TMPDIR="${SCRIPT_DIR}/../tmp-sync"

# update zama repo
cd ${ZAMADIR}
git pull && exit 1
cd ${SCRIPT_DIR}

rm -rf ${TMPDIR} || { exit 1; }
mkdir ${TMPDIR} || { exit 1; }
TMPDIR=$(cd "${TMPDIR}" && pwd) || { exit 1; }

cp -f ${ROOTDIR}/lib/Impl.forge-fhevm.sol ${TMPDIR}

# remove old
rm -rf ${ROOTDIR}/gateway
rm -rf ${ROOTDIR}/lib
rm -rf ${ROOTDIR}/payment

# make a fresh copy
cp -R ${ZAMADIR}/gateway/ ${ROOTDIR}/gateway
cp -R ${ZAMADIR}/lib/ ${ROOTDIR}/lib
cp -R ${ZAMADIR}/payment/ ${ROOTDIR}/payment
cp -R ${ZAMADIR}/lib/Impl.sol ${ROOTDIR}/lib/Impl.zama.sol

# restore
cp -f ${TMPDIR}/Impl.forge-fhevm.sol ${ROOTDIR}/lib
cp -f ${TMPDIR}/Impl.forge-fhevm.sol ${ROOTDIR}/lib/Impl.sol

# delete tmp
rm -rf ${TMPDIR}
