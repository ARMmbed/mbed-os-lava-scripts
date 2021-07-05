# LAVA setup

This document lists all the steps needed to setup a lava server and a worker.

`These Lines` can be copy pasted to the command line. Elements in `<brackets>` need to be replaced with real values.

## Running LAVA server docker compose

Instead of installing your lava server you may use docker compose provided by us.

- `git clone https://github.com/ARMmbed/mbed-os-lava-docker-compose`
-  Create a certificate and key and replace the ones in apache2/cert (you can try the free cert from
   [zerossl](https://app.zerossl.com/certificate/new))
- `docker-compose build lava-server`
- `docker-compose up lava-server`

Website is available on localhost, username and password are `lava-admin`. Change the password after logging in.

## Running a premade SD card image with the worker on your RPi

Download the SD card image [MISSING LINK](http://) and use [Raspberry PI imager](https://www.raspberrypi.org/software)
to copy to the SD card.

The filesystem on the SD card is not automatically expanded to a larger SD card. To do that the user must install
raspi config:

- `echo "deb http://archive.raspberrypi.org/debian/ buster main" >> /etc/apt/sources.list`
- `apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7FA3303E`
- `apt-get update && apt-get install raspi-config`

Then use raspi-config to extend the partition to the size of the medium:

- `raspi-config --expand-rootfs`

It's good practice to change the host name so it can be detected properly on the local network (raspi-config can be used
for that too).

You will need to edit the config file to give the worker its unique name and password. If you're using a different
server you will also need to change the server URL.

- `sudo vim /etc/lava-dispatcher/lava-worker`
    * set WORKER_NAME (and URL if needed)
    * set the token to the string you get from adding a worker in the server

If you're doing this on a running worker then you need to restart lava for it to take effect:

- `sudo service lava-worker restart`

## Adding Device and Device Types in the server

Open the web interface of the lava server and enter administration tab.

Device:

- In "Home › lava_scheduler_app › Devices" add a new device with the same name as the file (mbed_nrf or mbed_disco).
- Select device type mbed (click plus to add new device type, name it docker, untick the health check or leave ticked
  but then you need the health check below).
- Add worker (only hostname matters and has to match what is in the worker file in that worker, for example RPI001).
- The token string has to match the string in the worker file on that worker machine.
- Set health of device to unknown.
- Save device.

Device type:

- In "Home › lava_scheduler_app › Device types" click `add device type` button.
- The only entry that matters is the name which should match the file on the server that describes it.

This will only work if there already is a file with the same name on the server. If you're using the docker compose you
need to add this file to the `device-types` or `devices` directory in the
[lava scripts repo](https://github.com/ARMmbed/mbed-os-lava-scripts/tree/master/lava-server/dispatcher-config). Once the
file is merged to the repo you need to rebuild the docker compose and restart it.

## Running tests

Tests are run by submitting jobs on the server through the web interface after logging in or with
[lavacli](https://docs.lavasoftware.org/lava/lavacli.html). The server will wait until a worker connects to it
and it will dispatch the job to a matching device hosted on one of such workers. Hence only the server IP needs to be
known.

### Network environment

RPis need to be on the outside network for security reasons. For network tests you'll need two APs. One unsecured with
SSID: UNSECURED. One secured with password: PASSWORD and SSID: SECURED.

### Verification

You can submit a test job to verify it works. Connect a NRF52840_DK to your worker and submit one of the jobs
(http://localhost/scheduler/jobsubmit) in https://github.com/ARMmbed/mbed-os-lava-scripts/tree/master/jobs

### Healthcheck

[Healthcheck](https://docs.lavasoftware.org/lava/healthchecks.html) is now part of the lava scripts repo. It's a job
that runs every day and makes sure the board flashes and connects.

Add new healthchecks to the `health-checks` directory in the 
[lava scripts repo](https://github.com/ARMmbed/mbed-os-lava-scripts/tree/master/lava-server/dispatcher-config).

### Debugging devices

If device is down make sure the worker is up and the device health is good.

If the worker is down check the RPi, ssh to it and see if the lava-dispatcher is running. Check logs in /var/log.

If the health is bad edit the device and set health to Unknown. This will trigger the healthcheck to run.

# Advanced section

## Building LAVA server and client from scratch

Lava server and worker can be made from scratch or you can use the docker compose and RPi SD card image (recommended).
The process below describes how to do it from scratch.

### Lava software versions

Lava worker and server and not backwards or forwards compatible, both must be the same version. If you're not using the
docker compose and the SD card image and installing your own you will have to use the same version of both.

Older version of lava-dispatcher/server can be installed from the
[snapshots repository](https://apt.lavasoftware.org/snapshot/)
More information about installing different versions can be found the
[LAVA website](https://docs.lavasoftware.org/lava/installing_on_debian.html)

### OS setup

Lava uses debian buster as base for both server and workers.

- Install debian buster https://www.debian.org/releases/buster/debian-installer/
- Log in as root
- `usermod -a -G sudo <username>`
- `echo "deb https://apt.lavasoftware.org/release buster main" >> /etc/apt/sources.list`
- you may now login as user
- `wget https://apt.lavasoftware.org/lavasoftware.key.asc`
- `sudo apt-key add lavasoftware.key.asc`
- `sudo apt-get update`

Note: although it is not officially supported, lava-server can be installed in Ubuntu (e.g. on WSL) by adding the below step:
`sudo apt-get install postgresql && sudo service postgresql start`

This resolves a dpkg-configure error that occurs because Postgres is not listening to port 5432 during installation

### Server setup

Here is the process you'll need to build the server from scratch. It's recommended you use the docker compose instead -
see below.

#### Install LAVA server

- `sudo apt install lava-server`
- `sudo a2dissite 000-default`
- `sudo a2enmod proxy`
- `sudo a2enmod proxy_http`
- `sudo a2ensite lava-server.conf`
- `sudo service apache2 restart`

#### Setup user

- `sudo lava-server manage users add <usernane> --passwd <password>`
- `sudo lava-server manage authorize_superuser --username <usernane>`

#### Set website URL (this affect internal web interface links)

- go to http://localhost/admin/sites/site/
- click on example.com and delete it
- add new one with the correct url
- edit /usr/lib/python3/dist-packages/lava_server/settings/common.py
    * search for SITE_ID and change it to SITE_ID = 2
    * `sudo service lava-server-gunicorn restart`
    * any time you change site domain you have to change the index to match

#### Add Worker

- `sudo lava-server manage workers add <WORKER_NAME>`
    * don't do that on a single machine install, it will break lava
    * set the hostname to the worker name
- copy the token string to be used when configuring the worker

#### Add device definition

- create a new file in /etc/lava-server/dispatcher-config/devices with the name of the device (you can use the one from https://github.com/ARMmbed/mbed-os-lava-scripts)
    * You can just copy the whole directory https://github.com/ARMmbed/mbed-os-lava-scripts/tree/master/lava-server to /etc/, otherwise follow steps below
    * must have extension jinja2: `mbed.jinja2`
    * the device should inherit from a device type in /usr/share/lava-server/device-types, to inherit from docker add line: `{% extends "docker.jinja2" %}`
    * Must pass in extra parameters to docker: `{% set docker_extra_arguments = ["-v /dev:/dev --group-add=dialout --device-cgroup-rule 'a 166:* rwm'"] %}`
    * all files in `/etc/lava-server` must be owned by the `lavaserver` user
- `sudo service lava-server-gunicorn restart`

### Worker setup

#### Install dependencies

`sudo apt install docker.io git`
Install docker following official [docker documentation](https://docs.docker.com/engine/install/debian/).
`sudo apt install bluez bluetooth`
`sudo killall -9 bluetoothd`
* daemon cannot be running when docker starts
* you can change AutoEnable=true to false in /etc/bluetooth/main.conf but it still needs to start at least once

#### Install worker

`sudo apt install lava-dispatcher`
`sudo vim /etc/lava-dispatcher/lava-worker`
* set WORKER_NAME and URL
* set the token to the string you get from adding a worker in the server
`sudo service lava-worker restart`

You can verify the ping works by viewing the log file at `/var/log/lava-dispatcher/lava-worker.log`.

#### Device access

`sudo usermod -aG dialout $(whoami)`
`git clone https://github.com/pyocd/pyOCD.git`
`sudo cp pyOCD/udev/*.rules /etc/udev/rules.d`

`sudo nano /etc/dbus-1/system.d/bluetooth.conf`
* copy the bluetooth policy from root to lava-admin
