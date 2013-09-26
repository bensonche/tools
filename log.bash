#!/bin/bash

set -e

echo $1
echo

BRANCH=release

git checkout $1
if [ $? -ne 0 ]
then
	echo "Error checking out"
	exit 1
fi
git pull origin $1

echo $1 >> log.txt
git log --left-right --cherry-pick --pretty=format:"%ad, %aN: %s" $BRANCH..head >> log.txt
echo -e "\n" >> log.txt

echo
echo
