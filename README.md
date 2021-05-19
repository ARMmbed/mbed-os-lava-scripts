# Files for running tests with LAVA

This is a collection of files that work together across many machines to run tests of mbed-os applications on real boards.

## Lava testing architecture for Mbed OS

Jobs are launched by Github workflows or manually by submitting jobs to the lava server using the definitions provided
in this repo in `jobs` directory. The lava server will then trigger one of the worker machines that have boards connected
to them to run one of the tests defined in the `scripts` directory. The test might need extra configuration to build,
provided in the `configs` directory. The job will then report back to Github (if it was triggered with Github credentials)
and set the PR's status.

## Contents

### configs

Configurations needed by some jobs

### jobs

LAVA job definitions for tests.

### lava-server

Configuration files for lava server. These can be copied wholesale to `/etc`

### scripts

The actual code that runs individual tests. Jobs run on lava launch one of these to perform the test.
