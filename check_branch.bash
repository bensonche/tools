#!/bin/bash

cleanup()
{
	echo -e "\n\n"
	echo "cleaning up"
	git reset --hard
	git checkout $head
	exit $?
}

check_branch ()
{
	set -e

	# Navigate to root of git repo
	cd "$(git rev-parse --show-toplevel)"

	local branch=origin/release

	local right=$1

	if [[ $1 != origin/* ]]
	then
		right=origin/$1
	fi

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

		trap cleanup SIGINT
		set +e
		git merge -sresolve $branch
		if [ $? -ne 0 ]
		then
			echo -e "\n"
			echo "Error updating the branch,"
			read -p "return to previous branch ${head}? [y/n] " response

			while true;
			do
				if [ -z $response ]
				then
					read -p "please reply with y or n: " response
				elif [ $response == "y" ]
				then
					cleanup
				elif [ $response == "n" ]
				then
					exit 1
				else
					read -p "please reply with y or n: " response
				fi
			done
		fi

		set -e

		right=temp_bc_check_branch
	fi

	echo -e "\e[0;32mList of commits in this branch:\e[00m"
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
	git diff -w $branch..$right

	if [ $(git rev-parse --abbrev-ref HEAD) != $head ]
	then
		git checkout $head
	fi
}

check_branch $1
