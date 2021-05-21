#!/bin/bash
set -ex
cd "$(dirname "$0")"
source ./common.sh

cd

enable_bluetooth
get_board
get_timestamp

REPO=${1:-https://github.com/ARMmbed/mbed-os-experimental-ble-services.git}
SHA="$2"

clone_repo "$REPO" mbed-os-experimental-ble-services "$SHA"
# temporarily until ci branch is merged
git reset --hard origin/github-ci

cd scripts

source ./bootstrap.sh

cd tests/TESTS/

cd LinkLoss/device
time mbed compile -t GCC_ARM -m ${TARGET} -f
cd ../../
python3 -m pytest LinkLoss/host

cb DeviceInformation/device
time mbed compile -t GCC_ARM -m ${TARGET} -f
cd ../..
python3 -m pytest DeviceInformation/host
