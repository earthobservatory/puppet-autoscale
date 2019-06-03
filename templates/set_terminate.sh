#!/bin/bash

# detect if system is running on ec2, exit if not on ec2
http_code=$(curl --max-time 30 -s -o /dev/null -w "%{http_code}" "http://169.254.169.254/latest/meta-data/placement/availability-zone")
if [[ $http_code == "404" ]]; then
  # this is coded with the assumption that a non-AWS endpoint will return a 404
  echo "This system is running on a cloud platform that is not AWS. Exiting..."
  exit 0
elif [[ $http_code == "000" ]]; then
  # there might be a more robust way to do on-prem vs cloud detection than this
  # this is coded with the assumption that the metadata IP is unreachable in on-prem environments
  echo "Unable to get metadata, this system might be running on-premise. Exiting..."
  exit 0
fi

if [[ $http_code != "200" ]]; then
  echo "Unable to determine machine location, retrying with backoff..."
  http_code=$(curl --max-time 10 --retry 5 -s -o /dev/null -w "%{http_code}" "http://169.254.169.254/latest/meta-data/placement/availability-zone")
  if [[ $http_code != "200" ]]; then
    echo "Exponential backoff failed, marking this service as failed"
    exit 1
  fi
fi

# system is confirmed to be in AWS due to HTTP 200

# instance id
az=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
region="`echo \"$az\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
region_underscores="`echo \"$region\" | sed -e 's/-/_/g'`"
instance_id=`curl -s http://169.254.169.254/latest/meta-data/instance-id`

# set to terminate on instance initiated shutdown
aws --region $region ec2 modify-instance-attribute \
  --instance-initiated-shutdown-behavior terminate \
  --instance-id $instance_id || \
  echo "Failed to set instance $instance_id to terminate on shutdown." 1>&2

# print setting
aws --region $region ec2 describe-instance-attribute \
  --attribute instanceInitiatedShutdownBehavior \
  --instance-id $instance_id
