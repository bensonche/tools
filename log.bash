#!/bin/bash

bc_log ()
{
	set -e

	# Navigate to root of git repo
	cd "$(git rev-parse --show-toplevel)"

	echo $1
	echo

	local branch=release

	git checkout $1
	if [ $? -ne 0 ]
	then
		echo "Error checking out"
		exit 1
	fi
	git pull origin $1

	echo $1 >> log.txt
	git log --left-right --cherry-pick --pretty=format:"%ad, %aN: %s" $branch..head >> log.txt
	echo -e "\n" >> log.txt

	echo
	echo
}

bc_log $1