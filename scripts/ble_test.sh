#!/bin/bash
set -ex
cd "$(dirname "$0")"
source ./common.sh
mount_boards

cd

REPO=${1:-ARMmbed/mbed-os-bluetooth-integration-testsuite}
REPO_URL="https://github.com/${REPO}.git"
SHA="$2"
set +x
USER_TOKEN="$3"
BARE_TOKEN=`echo "$USER_TOKEN" | cut -d':' -f 2`
set -x

clone_repo "$REPO_URL" mbed-os-bluetooth-integration-testsuite "$SHA"
cd ble-cliapp
deploy_project


while true
do
  get_board # sets variables like $TARGET and $SERIAL

  if [ -n "$USER_TOKEN" ]; then
    set +x
    download_artifacts "$REPO_NAME" "ble-cliapp-GCC_ARM-${TARGET}-${SHA}" "$BARE_TOKEN" ble-cliapp.hex
    set -x
    cp ble-cliapp.hex "$MOUNTPOINT"
    sync
    sleep 5
    # remount the drive - mount is still present, programming doesn't work?
    # mount "/dev/sd${MOUNTPOINT: -1}" "$MOUNTPOINT"
  else
    time mbed compile -t GCC_ARM -m ${TARGET} --profile toolchains_profile.json -f
  fi

  if [ $BOARD_INDEX -eq $BOARD_NUMBER ]; then
    break
  fi
done


cd ../test_suite

pip3 install -r requirements.txt

get_timestamp

python3 -m pytest --log-cli-level=ERROR --log-file="ble_tests_$TIMESTAMP.log" --junit-xml="ble_tests_$TIMESTAMP.result" -r a
