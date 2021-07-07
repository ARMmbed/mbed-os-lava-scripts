#!/bin/bash
set -ex
cd "$(dirname "$0")"
source ./common.sh
mount_boards

cd

enable_bluetooth
get_board
get_timestamp

REPO_NAME=${1:-ARMmbed/mbed-os-experimental-ble-services}
REPO_URL="https://github.com/${REPO_NAME}.git"
SHA="$2"
set +x
USER_TOKEN="$3"
BARE_TOKEN=`echo "$USER_TOKEN" | cut -d':' -f 2`
set -x

clone_repo "$REPO_URL" mbed-os-experimental-ble-services "$SHA"
# temporarily until ci branch is merged
git reset --hard origin/github-ci

cd scripts

source ./bootstrap.sh

cd tests/TESTS/

run_test () {
  TEST_NAME="$1"
  cd ${TEST_NAME}/device
  if [ -n "$USER_TOKEN" ]; then
    set +x
    download_artifacts "$REPO_NAME" "${TEST_NAME}-GCC_ARM-${TARGET}-${SHA}" "$BARE_TOKEN" ${TEST_NAME}.hex
    set -x
    cp ${TEST_NAME}.hex "$MOUNTPOINT"
    sync
    sleep 5
    # remount the drive - mount is still present, programming doesn't work?
    # mount "/dev/sd${MOUNTPOINT: -1}" "$MOUNTPOINT"
  else
    time mbed compile -t GCC_ARM -m ${TARGET} -f
  fi
  cd ../../
  pyocd reset
  sleep 1
  python3 -m pytest ${TEST_NAME}/host
}

run_test LinkLoss

run_test DeviceInformation
