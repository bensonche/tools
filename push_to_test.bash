#!/bin/bash

set -e

CUR=`git rev-parse --abbrev-ref HEAD`

# Use current month/year for branch name if not given
if [ $# -lt 1 ]
then
	MONTH=`date +%b | tr '[A-Z]' '[a-z]'`
	YEAR=`date +%y`
	TEST=test_$MONTH$YEAR
else
	TEST=$1
fi

git checkout $TEST
git pull origin $TEST
git merge $CUR
git push origin $TEST
