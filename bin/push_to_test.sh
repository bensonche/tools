#!/bin/bash

cmdline()
{
	while getopts ":x" OPTION
	do
		case $OPTION in
			x)
				readonly CHANGEBRANCH=0
				;;
			\?)
				echo "Invalid option: -$OPTARG"
				exit 1
				;;
		esac
	done
	shift $((OPTIND-1))
	readonly TARGETBRANCH=$1
}

bc_ptt ()
{
	set -e

	cmdline $@

	local cur=`git rev-parse --abbrev-ref HEAD`

	# Use current month/year for branch name if not given
	local test=""
	if [ -n $TARGETBRANCH ]
	then
		test=$(testbranch.sh)
	else
		test=$TARGETBRANCH
	fi

	git checkout $test
	git pull origin $test
	git merge $cur
	git push origin $test

	if [ -z "$CHANGEBRANCH" ]
	then
		git checkout $cur
	fi
}

bc_ptt $1
