#!/bin/bash
set -x
set -e

# get optional tag
TAG_STRING=$1
if [[ "${TAG_STRING:0:1}" == "[" ]]; then
  shift
else
  TAG_STRING=""
fi

JOB_YAML=$1
REPOSITORY=$2
SHA=$3
USER_TOKEN=$4

JOB_NAME="job-${SHA}.yaml"

if [ "$#" -eq 0 ]; then
  echo "Usage:"
  echo "./launch_job JOB_NAME.yaml [CUSTOM_REPO [SHA [USER_TOKEN]]]"
  exit 1
fi

# check in case script already running
if [ -f "${JOB_NAME}" ]; then
    echo "Temporary file ${JOB_NAME} exists. Previous call still running? If not, remove file."
    exit 1
fi

# create a temp job file
rm -f ${JOB_NAME}
cp "$JOB_YAML" ${JOB_NAME}

# substitute job parameters
if [ -n "$TAG_STRING" ]; then
  sed -i "/^job_name: .*/a tags: $TAG_STRING" ${JOB_NAME}
fi
ESCAPED_REPOSITORY=$(echo "$REPOSITORY" | sed -e 's/[\/&]/\\&/g')
ESCAPED_USER_TOKEN=$(echo "$USER_TOKEN" | sed -e 's/[\/&]/\\&/g')
sed -i "s/REPOSITORY=\"\"/REPOSITORY=\"${ESCAPED_REPOSITORY}\"/" ${JOB_NAME}
sed -i "s/SHA=\"\"/SHA=\"${SHA}\"/" ${JOB_NAME}
sed -i "s/USER_TOKEN=\"\"/USER_TOKEN=\"${ESCAPED_USER_TOKEN}\"/" ${JOB_NAME}
sed -i "s/path: inline\/job\.yaml/path: inline\/job-${SHA}\.yaml/" ${JOB_NAME}

lavacli jobs submit "${JOB_NAME}"

rm -f ${JOB_NAME}