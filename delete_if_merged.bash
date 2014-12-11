#!/bin/bash

function bc_delete
{
	set -e

	if [ $# -lt 1 ]
	then
		echo "Branch name missing"
		exit 1
	fi

	local count=$(git log --left-right --cherry-pick release..origin/$1 | wc -l)

	if [ $count -ne 0 ]
	then
		echo "$1 is not merged"
		exit 0
	fi

	git push origin :$1

	echo "$1 has been deleted"
}

bc_delete $@
