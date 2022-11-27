#! /bin/bash

if [ -z "$1" ]; then
  echo "Usage: ./fly_set_secrets.sh <secrets-file>"
  exit 1
fi

FILE=$1

env_vars=($(cat $FILE | tr "\n" " "))

echo "Setting secrets"
fly secrets set ${env_vars[*]}
