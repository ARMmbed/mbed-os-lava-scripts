#!/bin/bash
# this script creates a file test.log and prints the failure or success of the job as last line
set -ex
OUTPUT_DIR="$PWD"
cd "$(dirname "$0")"

source ./launch_job.sh "$@"
# additionally these are set by the script above:
# USER_TOKEN LAVA_TOKEN LAVA_JOB_NO

echo "waiting for lava job ${LAVA_JOB_NO}"
lavacli jobs wait ${LAVA_JOB_NO}
echo "lava job ${LAVA_JOB_NO} completed with result:"

# so that we create the log where we were called from
cd $OUTPUT_DIR

lavacli jobs logs ${LAVA_JOB_NO} > test.log

# hide secrets in the log
sed -i "s/${USER_TOKEN}/==USER_TOKEN==/" test.log
sed -i "s/${LAVA_TOKEN}/==LAVA_TOKEN==/" test.log

# print the test result
JOB_RESULT=`lavacli jobs show $LAVA_JOB_NO | grep Health | cut -d':' -f 2 | xargs`

if [ $JOB_RESULT = Complete ]; then
  echo "success"
else
  echo "failure"
fi


