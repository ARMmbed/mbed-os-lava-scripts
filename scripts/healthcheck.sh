#!/bin/bash
set -ex
cd "$(dirname "$0")"
source ./common.sh
mount_boards

cd

clone_repo https://github.com/ARMmbed/mbed-os-lava-healthcheck.git mbed-os-lava-healthcheck
deploy_project

while true
do
  get_board # sets variables like $TARGET and $SERIAL

  # stash the date at compile time
  COMPILE_DATE=$(date "+%b %-d %Y")

  touch main.cpp # so that date inside the binary updates
  mbed compile -t GCC_ARM -m ${TARGET} -f

  # read output of the serial into a file and compare the printed date with date of compilation
  rm -f board_output
  touch board_output # needs to be present for the head command
  screen -S health -dm -L -Logfile board_output ${SERIAL}
  sleep 3 # to guarantee a clean line
  screen -XS health quit
  sleep 1
  BOARD_DATE=$(tail -n2 board_output | head -n1 | xargs) # read one full line from the board

  if [[ "$BOARD_DATE" != "$COMPILE_DATE"* ]]; then # the glob is required to ignore line ending chars
    # this can fail in a corner case when compiled exactly
    # at midnight and dates change between the two operations
    exit 1
  fi

  if [ $BOARD_INDEX -eq $BOARD_NUMBER ]; then
    break
  fi
done
