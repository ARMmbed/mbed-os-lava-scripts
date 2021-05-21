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

cd ..
cd tests/TESTS/

cd LinkLoss/device
time mbed compile -t GCC_ARM -m ${TARGET} -f
cd ../../
python3 -m pytest LinkLoss/host --log-cli-level=ERROR --log-file="link_loss_$TIMESTAMP.log" --junit-xml="link_loss_$TIMESTAMP.result" -r a

cb DeviceInformation/device
time mbed compile -t GCC_ARM -m ${TARGET} -f
cd ../..
python3 -m pytest DeviceInformation/host --log-cli-level=ERROR --log-file="device_information_$TIMESTAMP.log" --junit-xml="device_information_$TIMESTAMP.result" -r a
