#!/bin/bash

cleanup()
{
	rm $blank
	exit $?
}

bc_diff ()
{
	local mine=$1
	local remote=$2
	
	local command=""
	if [ $# -eq 3 ]
	then
		command=$3
	else
		command="sgdm.exe"
	fi

	# trap ctrl-c to run cleanup code
	trap cleanup SIGINT

	# create blank file
	local blank=$RANDOM
	touch $blank

	if [ $mine == "/dev/null" ]
	then
		mine=$blank
	fi
	if [ $remote == "/dev/null" ]
	then
		remote=$blank
	fi

	$command "$mine" "$remote"

	rm $blank
}

bc_diff $1 $2 $3