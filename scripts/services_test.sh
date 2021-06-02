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
set +x
USER_TOKEN=$3
set -x

clone_repo "$REPO" mbed-os-experimental-ble-services "$SHA"
# temporarily until ci branch is merged
git reset --hard origin/github-ci

cd scripts

source ./bootstrap.sh

cd tests/TESTS/

cd LinkLoss/device
if [ -n "$USER_TOKEN" ]; then
  set +x
  download_artifacts "$REPO" "LinkLoss-GCC_ARM-NRF52840_DK-${SHA}" "$USER_TOKEN" LinkLoss.hex
  set -x
  cp LinkLoss.hex "$MOUNTPOINT"
else
  time mbed compile -t GCC_ARM -m ${TARGET} -f
fi
cd ../../
python3 -m pytest LinkLoss/host

cb DeviceInformation/device
if [ -n "$USER_TOKEN" ]; then
  set +x
  download_artifacts "$REPO" "DeviceInformation-GCC_ARM-NRF52840_DK-${SHA}" "$USER_TOKEN" DeviceInformation.hex
  set -x
  cp DeviceInformation.hex "$MOUNTPOINT"
else
  time mbed compile -t GCC_ARM -m ${TARGET} -f
fi
cd ../..
python3 -m pytest DeviceInformation/host
