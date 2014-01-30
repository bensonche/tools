#!/bin/bash

bc_log ()
{
	set -e

	# Navigate to root of git repo
	cd "$(git rev-parse --show-toplevel)"

	echo $1
	echo

	local right=$1

	if [[ $1 != origin/* ]]
	then
		right=origin/$1
	fi

	local branch=release

	echo $1 >> log.txt
	git log --left-right --cherry-pick --pretty=format:"%ad, %aN: %s" $branch..$right >> log.txt
	echo -e "\n" >> log.txt

	echo
	echo
}

bc_log $1
