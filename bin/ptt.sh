#!/bin/bash

bc_ptt ()
{
	set -e

	cd ../db
	git gr
	git fetch

	local sprint=$(git branch -r | grep 65348_AT_sprint | tail -n1 | sed "s/\s*origin\///")

	echo $sprint

	git co $sprint

	git reset --hard origin/$sprint

	push_to_test.sh
}

bc_ptt
