#!/bin/bash
set +x
# $1 user:password
# $2 github-user/repo-name
# $3 PR SHA
# $4 result (success or failure)

if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ] && [ -n "$4" ]; then
  echo "Reporting status $4 to github"
  curl --user ${1} -H "POST" https://api.github.com/repos/${2}/statuses/${3} -d "{\"state\": \"${4}\", \"context\": \"lava-test\" }"
  echo "Reported"
fi
