#!/bin/bash

bc_ptt ()
{
	set -e

	local cur=`git rev-parse --abbrev-ref HEAD`

	# Use current month/year for branch name if not given
	local test=""
	if [ $# -lt 1 ]
	then
		
		test=$(testbranch.sh)
	else
		test=$1
	fi

	git checkout $test
	git pull origin $test
	git merge $cur
	git push origin $test

	git checkout $cur
}

bc_ptt $1
