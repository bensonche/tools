#!/bin/bash

set -e

# Navigate to root of git repo
cd "$(git rev-parse --show-toplevel)"

BRANCH=release

git checkout $1
if [ $? -ne 0 ]
then
	echo "Error checking out"
	exit 1
fi
git pull origin $1

updated=0

echo ""
if [ `git cherry -v head $BRANCH | grep -c ""` -ne 0 ]
then
	echo "Branch not updated"
	echo ""
	read -p "Press [Enter] key to auto-merge..."
	git merge -sresolve $BRANCH
	
	if [ $? -ne 0 ]
	then
		exit 1
	fi
	
	updated=1
fi

echo -e "\e[0;32mList of commits in this branch:\e[00m"
#git cherry -v $BRANCH head
git log --left-right --cherry-pick --pretty=format:"%ad, %aN: %s" $BRANCH..head
echo ""
read -p "Press [Enter] key to continue..."

echo ""
echo -e "\e[0;32mList of files modified by this branch:\e[00m"
git diff --name-status $BRANCH head
echo ""
read -p "Press [Enter] key to continue..."

git difftool -w $BRANCH..head
git diff -w $BRANCH..head

if [ $updated -ne 0 ]
then
	read -p "Press [Enter] key to push branch"
	git push origin $1
fi
