#!/bin/bash
set -ex

# we use this as our workspace
mkdir -p /opt/lava-worker
cd /opt/lava-worker

# update all the scripts before running them
if [ ! -d mbed-os-lava-scripts ]; then
   git clone https://github.com/paul-szczepanek-arm/lava-prototype.git mbed-os-lava-scripts
fi
cd mbed-os-lava-scripts
git fetch
git reset --hard origin/master

set +x

# mount all boards
for x in {a..z}
do
  if [ -e "/dev/sd${x}" ]; then
    echo "mounting /dev/sd${x}"
    mkdir -p "/mnt/mbed${x}"
    mount "/dev/sd${x}" "/mnt/mbed${x}"
  fi
done
