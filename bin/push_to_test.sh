#!/bin/bash

bc_ptt ()
{
	set -e

	local cur=`git rev-parse --abbrev-ref HEAD`

	# Use current month/year for branch name if not given
	local test=""
	if [ $# -lt 1 ]
	then
		local path=$(dirname "$0")
		test=$(${path}\\testbranch.bash)
	else
		test=$1
	fi

	git checkout $test
	git pull origin $test
	git merge $cur
	git push origin $test
}

bc_ptt $1
