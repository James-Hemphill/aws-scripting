#!/bin/bash
#Author: Wes Novack
#Usage: resize_ec2.sh i-instanceid new.instancetype

set -e

id=$1
new_instance_type=$2
sleep_duration=5
start_time=$(date +%s)

function check_parameter () {
	if echo "$1" | grep -E '^i-[a-zA-Z0-9]{8,}' > /dev/null; then
		return 0
	else
		echo "An instance id parameter is required. Example: i-0w7vjth3"
		return 1
	fi
}

function stop_instance () {
	aws ec2 stop-instances --instance-ids $1
}

function start_instance () {
	aws ec2 start-instances --instance-ids $1
}

function check_status () {
	aws ec2 describe-instances --instance-ids $1 \
		--query "Reservations[].Instances[].State.Name" --output text
}

function wait_for_status () {
	status=$(check_status $1)
	while [ "$status" != "$2" ]; do
		echo "Instance state not yet $2, sleeping"
		sleep $sleep_duration
		status=$(check_status $1)
	done
}

function resize_instance () {
	aws ec2 modify-instance-attribute --instance-id $1 --instance-type $2
}

function main () {
	check_parameter $id
	status=$(check_status $id)
	if [ "$status" = "running" ]; then
		stop_instance $id
		wait_for_status $id stopped
	fi
	resize_instance $id $new_instance_type
	start_instance $id
	wait_for_status $id running
	end_time=$(date +%s)
	duration=$((end_time - start_time))
	echo "Your restart of instance $id is complete!"
	echo "This script completed in $duration seconds."
}

main
