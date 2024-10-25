#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ZAMADIR=$(cd "${SCRIPT_DIR}/../../../../github/repos/zama-ai/fhevm" && pwd) || { exit 1; }
ROOTDIR=$(cd "${SCRIPT_DIR}/.." && pwd) || { exit 1; }
TMPDIR="${SCRIPT_DIR}/../tmp-sync"

# update zama repo
cd ${ZAMADIR}
git pull && exit 1
cd ${SCRIPT_DIR}
