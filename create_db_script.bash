#!/bin/bash

LEFT=c40b28736408dc7866a7a795dae8a8bf29aab294
RIGHT=head

if [ -f db_script.sql ]
then
	rm db_script.sql
fi

git diff --name-status $LEFT..head Database/

read -p "Press [Enter] key to continue..."

git diff -w $LEFT..head Database/

echo
echo

git diff --name-only $LEFT..head Database/ | grep Database/rep |
while read line; do
	FILE=$line
	
	grep -q ÿþ "$FILE"
	if [ $? -eq 0 ]
		then
		echo "$FILE is in UTF-16"
	fi
	grep -q ï»¿ "$FILE"
	if [ $? -eq 0 ]
		then
		echo "$FILE is in UTF-8 with BOM"
	fi
done

git diff --name-only $LEFT..head Database/ | grep Database/rep | sed 's/^/cat \"/' | sed 's/$/\" >> db_script.sql; echo -e "\\ngo\\n" >> db_script.sql/' > db_files.txt

./db_files.txt

git log -1 --format="%H" > /c/temp/test_hash.txt