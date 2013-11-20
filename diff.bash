#!/bin/bash

cleanup()
{
	rm $BLANK
	exit $?
}

LOCAL=$1
REMOTE=$2

if [ $# -eq 3 ]
then
	COMMAND=$3
else
	COMMAND="sgdm.exe"
fi

# trap ctrl-c to run cleanup code
trap cleanup SIGINT

# create blank file
BLANK=$RANDOM
echo "" > $BLANK

echo $BLANK

if [ $LOCAL == "/dev/null" ]
then
	LOCAL=$BLANK
fi
if [ $REMOTE == "/dev/null" ]
then
	REMOTE=$BLANK
fi

$COMMAND "$LOCAL" "$REMOTE"

rm $BLANK