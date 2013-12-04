#!/bin/bash

check_branch ()
{
	set -e

	# Navigate to root of git repo
	cd "$(git rev-parse --show-toplevel)"

	local branch=release

	git checkout $1
	if [ $? -ne 0 ]
	then
		echo "Error checking out"
		exit 1
	fi
	git pull origin $1

	local updated=0

	echo ""
	if [ `git cherry -v head $branch | grep -c ""` -ne 0 ]
	then
		echo "Branch not updated"
		echo ""
		read -p "Press [Enter] key to auto-merge..."
		git merge -sresolve $branch
		
		if [ $? -ne 0 ]
		then
			exit 1
		fi
		
		updated=1
	fi

	echo -e "\e[0;32mList of commits in this branch:\e[00m"
	#git cherry -v $branch head
	git log --left-right --cherry-pick --pretty=format:"%ad, %aN: %s" $branch..head
	echo ""
	read -p "Press [Enter] key to continue..."

	echo ""
	echo -e "\e[0;32mList of files modified by this branch:\e[00m"
	git diff --name-status $branch head
	echo ""
	read -p "Press [Enter] key to continue..."

	git difftool -w $branch..head
	git diff -w $branch..head

	if [ $updated -ne 0 ]
	then
		read -p "Press [Enter] key to push branch"
		git push origin $1
	fi
}

check_branch
