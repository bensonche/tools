#!/bin/bash

CUR=`git rev-parse --abbrev-ref HEAD`

MONTH=`date +%b | tr '[A-Z]' '[a-z]'`
YEAR=`date +%y`
TEST=test_$MONTH$YEAR

git checkout $TEST &&
git pull origin $TEST &&
git merge $CUR &&
git push origin $TEST
