#!/bin/bash

bc_mark_branch ()
{
	set -e
	
	local branch=$1
	local ptNum=$2
	
	git checkout $branch
	
	git pull origin $branch
	
	git pull origin release
	
	git filter-branch -f --msg-filter "cat && printf '\n\nReleased to prod on ' && date +%x && printf 'PT ' && echo $ptNum" release..$branch
}

bc_mark_branch $1 $2
