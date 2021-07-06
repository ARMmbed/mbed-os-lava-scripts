#!/bin/bash
set -ex
cd "$(dirname "$0")"
source ./common.sh
mount_boards

cd

REPO=${1:-ARMmbed/mbed-os}
REPO_URL="https://github.com/${REPO}.git"
SHA="$2"

clone_repo "$REPO_URL" mbed-os "$SHA"
deploy_project
# disco needs external component for wifi
clone_repo https://github.com/ARMmbed/wifi-ism43362/ COMPONENT_ism43362
cd ..

get_board # sets variables like $TARGET and $SERIAL

time mbed test --compile -t GCC_ARM -m ${TARGET} -n connectivity-netsocket-tests-tests-network-wifi --app-config /opt/lava-worker/mbed-os-lava-scripts/configs/netsocket_wifi_mbed_app.json

mbedgt -m $TARGET -n connectivity-netsocket-tests-tests-network-wifi --polling-timeout 300 -v -V 
