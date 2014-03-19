#!/bin/bash

check_branch ()
{
	set -e

	# Navigate to root of git repo
	cd "$(git rev-parse --show-toplevel)"

	#local branch=release
	local branch=origin/release

	local right=$1

	if [[ $1 != origin/* ]]
	then
		right=origin/$1
	fi

	#git checkout $right
	#if [ $? -ne 0 ]
	#then
	#	echo "Error checking out"
	#	exit 1
	#fi
	#git pull origin $right

	#local updated=0

	local head=$(git rev-parse --abbrev-ref HEAD)

	echo ""
	if [ `git cherry -v $right $branch | grep -c ""` -ne 0 ]
	then
		echo "Branch not updated"
		echo ""

		set +e
		git branch -D temp_bc_check_branch
		set -e

		git checkout -b temp_bc_check_branch $right
		git merge -sresolve $branch

		right=temp_bc_check_branch

		#read -p "Press [Enter] key to auto-merge..."
		#git merge -sresolve $branch
		#
		#if [ $? -ne 0 ]
		#then
		#	exit 1
		#fi
		#
		#updated=1
	fi

	echo -e "\e[0;32mList of commits in this branch:\e[00m"
	#git cherry -v $branch $right
	git log --left-right --cherry-pick --pretty=format:"%ad, %aN: %s" $branch..$right
	echo ""
	read -p "Press [Enter] key to continue..."

	echo ""
	echo -e "\e[0;32mList of files modified by this branch:\e[00m"
	git diff --name-status $branch $right
	echo ""
	read -p "Press [Enter] key to continue..."

	for name in $(git diff --name-only $branch $right);
	do
		git difftool -w $branch $right -- "$name" &
	done
	#git difftool -w $branch..$right
	git diff -w $branch..$right

	if [ $(git rev-parse --abbrev-ref HEAD) != $head ]
	then
		git checkout $head
	fi

	#if [ $updated -ne 0 ]
	#then
	#	read -p "Press [Enter] key to push branch"
	#	git push origin $right
	#fi
}

check_branch $1
