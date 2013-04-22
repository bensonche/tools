#!/bin/bash

CUR=`git rev-parse --abbrev-ref HEAD`
TEST=test_apr13

git checkout $TEST &&
git pull origin $TEST &&
git merge $CUR &&
git push origin $TEST
