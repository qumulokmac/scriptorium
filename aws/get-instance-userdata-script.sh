#!/bin/bash

INSTANCE_ID=""
DECODE=""

usage() {
  echo "Usage: $0 [-i <instance-id> | --instance-id <instance-id>] [-d | --decode]"
  exit 1
}

while getopts ":i:d-:" opt; do
  case $opt in
    i)
      INSTANCE_ID="$OPTARG"
      ;;
    d)
      DECODE=" | base64 -D"
      ;;
    -)
      case "$OPTARG" in
        instance-id)
          INSTANCE_ID="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          ;;
        decode)
          DECODE=" | base64 -D"
          ;;
        *)
          echo "Invalid option --$OPTARG"
          usage
          ;;
      esac
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      usage
      ;;
  esac
done

if [ -z "$INSTANCE_ID" ]; then
  usage
fi

COMMAND="aws ec2 describe-instance-attribute --instance-id ${INSTANCE_ID} --attribute userData --query \"UserData.Value\" --output text"
eval $COMMAND$DECODE
