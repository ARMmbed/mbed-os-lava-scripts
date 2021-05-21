#!/bin/bash
set +x
set -e

JOB_YAML=$1
REPOSITORY=$2
SHA=$3
USER_TOKEN=$4

if [ "$#" -eq 0 ]; then
  echo "Usage:"
  echo "./launch_job JOB_NAME.yaml [CUSTOM_REPO [SHA [USER_TOKEN]]]"
  exit 1
fi

# check in case script already running
if [ -f ".tmp_job.yaml" ]; then
    echo "Temporary file .tmp_job.yaml exists. Previous call still running? If not, remove file."
    exit 1
fi

# create a temp job file
rm -f .tmp_job.yaml
cp "$JOB_YAML" .tmp_job.yaml

# substitute job parameters
ESCAPED_REPOSITORY=$(echo "$REPOSITORY" | sed -e 's/[\/&]/\\&/g')
ESCAPED_USER_TOKEN=$(echo "$USER_TOKEN" | sed -e 's/[\/&]/\\&/g')
sed -i "s/REPOSITORY=\"\"/REPOSITORY=\"${ESCAPED_REPOSITORY}\"/" .tmp_job.yaml
sed -i "s/SHA=\"\"/SHA=\"${SHA}\"/" .tmp_job.yaml
sed -i "s/USER_TOKEN=\"\"/USER_TOKEN=\"${ESCAPED_USER_TOKEN}\"/" .tmp_job.yaml

lavacli jobs submit .tmp_job.yaml
rm -f .tmp_job.yaml
