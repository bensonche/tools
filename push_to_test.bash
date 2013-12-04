#!/bin/bash

bc_ptt ()
{
	set -e

	local cur=`git rev-parse --abbrev-ref HEAD`

	# Use current month/year for branch name if not given
	local test=""
	if [ $# -lt 1 ]
	then
		local month=`date +%b | tr '[A-Z]' '[a-z]'`
		local year=`date +%y`
		test=test_$month$year
	else
		test=$1
	fi

	git checkout $test
	git pull origin $test
	git merge $cur
	git push origin $test
}

bc_ptt $1