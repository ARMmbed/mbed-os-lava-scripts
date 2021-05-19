#!/bin/bash
set -ex
cd "$(dirname "$0")"
source ./common.sh

cd

REPO=${1:-https://github.com/ARMmbed/mbed-os.git}
SHA="$2"

clone_repo "$REPO" mbed-os "$SHA"
deploy_project
# disco needs external component for wifi
clone_repo https://github.com/ARMmbed/wifi-ism43362/ COMPONENT_ism43362
cd ..

get_board # sets variables like $TARGET and $SERIAL

time mbed test --compile -t GCC_ARM -m ${TARGET} -n connectivity-netsocket-tests-tests-network-wifi --app-config /opt/lava-worker/mbed-os-lava-scripts/configs/netsocket_wifi_mbed_app.json

mbedgt -m $TARGET -n connectivity-netsocket-tests-tests-network-wifi --polling-timeout 300 -v -V 
