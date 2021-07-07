#!/bin/bash
set -ex

while getopts ":ht:j:r:s:t:u:p:" arg; do
  case $arg in
    t)
      TAG_STRING=${OPTARG}
      ;;
    j)
      JOB_YAML=${OPTARG}
      ;;
    r)
      REPOSITORY=${OPTARG}
      ;;
    s)
      SHA=${OPTARG}
      ;;
    u)
      USER_TOKEN=${OPTARG}
      ;;
    l)
      LAVA_URL=${OPTARG}
      ;;
    p)
      LAVA_TOKEN=${OPTARG}
      ;;
    h | *) # Display help.
      usage
      exit 1
      ;;
  esac
done

if [ "$#" -eq 0 ] || [ -z "$JOB_YAML" ] || [ -z "$REPOSITORY" ] || [ -z "$USER_TOKEN" ] || [ -z "$LAVA_URL" ] || [ -z "$LAVA_TOKEN" ] ; then
  echo "Usage:"
  echo "./launch_job [-t TAG] -j JOB_NAME.yaml -r REPOSITORY  [-s SHA] [-u USER_TOKEN] -l LAVA_URL -p LAVA_TOKEN"
  echo "-t -s -u are optional, others are mandatory"
  exit 1
fi

## prepare job

JOB_NAME="job-${SHA}.yaml"

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

## run job

# log in our lavacli
lavacli identities add --uri "$LAVA_URL" --username lava-admin --token "$LAVA_TOKEN" default

LAVA_JOB_NO=$(lavacli jobs submit "${JOB_NAME}")

rm -f ${JOB_NAME}