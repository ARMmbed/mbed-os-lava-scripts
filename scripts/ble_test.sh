#!/bin/bash
set -ex
cd "$(dirname "$0")"
source ./common.sh
mount_boards

cd

REPO=${1:-ARMmbed/mbed-os-bluetooth-integration-testsuite}
REPO_URL="https://github.com/${REPO}.git"
SHA="$2"

clone_repo "$REPO_URL" mbed-os-bluetooth-integration-testsuite "$SHA"
cd ble-cliapp
deploy_project

while true
do
  get_board
  time mbed compile -t GCC_ARM -m ${TARGET} --profile toolchains_profile.json -f
  if [ $BOARD_INDEX -eq $BOARD_NUMBER ]; then
    break
  fi
done

cd ../test_suite

pip3 install -r requirements.txt

get_timestamp

python3 -m pytest --log-cli-level=ERROR --log-file="ble_tests_$TIMESTAMP.log" --junit-xml="ble_tests_$TIMESTAMP.result" -r a
