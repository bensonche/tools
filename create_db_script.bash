#!/bin/bash

LEFT=b8a15fa177907b37786fcb984d6529a26e044820
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

git diff --name-status $LEFT..head Database/ | egrep '^[a-ce-zA-CE-Z]' | sed 's/^[A-Z][ \t]\+//' | grep Database/rep |
while read line; do
	FILE=$line
	
	grep -q ÿþ "$FILE"
	if [ $? -eq 0 ]
		then
		echo "$FILE is in UTF-16"
		/c/Program\ Files\ \(x86\)/Notepad++/notepad++.exe "$FILE" &
	fi
	grep -q ï»¿ "$FILE"
	if [ $? -eq 0 ]
		then
		echo "$FILE is in UTF-8 with BOM"
		/c/Program\ Files\ \(x86\)/Notepad++/notepad++.exe "$FILE" &
	fi
done

git diff --name-status $LEFT..head Database/ | egrep '^D' | sed 's/^[A-Z][ \t]\+//' | grep Database/rep > db_deleted.txt

git diff --name-status $LEFT..head Database/ | egrep '^[a-ce-zA-CE-Z]' | sed 's/^[A-Z][ \t]\+//' | grep Database/rep | sed 's/^/cat \"/' | sed 's/$/\" >> db_script.sql; echo -e "\\ngo\\n" >> db_script.sql/' > db_files.txt

./db_files.txt

git log -1 --format="%H" > /c/temp/test_hash.txt