#!/bin/bash

# Navigate to root of git repo
cd "$(git rev-parse --show-toplevel)"

if [ $# -ne 1 ]
then
	echo "Usage: create_db_script.bash <hash>"
	echo
	echo "The hash can be retrieved from the database with the following query:"
	echo "    select Code"
	echo "    from CODES"
	echo "    where FieldName = 'CurrentGitCommit'"
	
	exit 1
fi

LEFT=$1
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

git diff --name-status $LEFT..head Database/ | egrep '^D' | sed 's/^[A-Z][ \t]\+//' | grep Database/rep | sed 's/\(.*\)\.sql$/\1/' | sed 's/^Database\/repeatable\/\(.*\)/\1/' |
	sed 's/triggers\/\(.*\)/drop trigger \1/' |
	sed 's/procs\/\(.*\)/drop proc \1/' |
	sed 's/functions\/\(.*\)/drop function \1/' |
	sed 's/views\/\(.*\)/drop view \1/'	> db_deleted.sql

git diff --name-status $LEFT..head Database/ | egrep '^[a-ce-zA-CE-Z]' | sed 's/^[A-Z][ \t]\+//' | grep Database/rep | sed 's/^/cat \"/' | sed 's/$/\" >> db_script.sql; echo -e "\\ngo\\n" >> db_script.sql/' > db_files.txt

./db_files.txt

echo -en "update CODES\nset code = '" >> db_script.sql
echo -en `git log -1 --format="%H"` >> db_script.sql
echo -en "'\nwhere FieldName = 'CurrentGitCommit'" >> db_script.sql

cat db_deleted.sql

start db_script.sql

if [ -s db_deleted.sql ]
then
	start db_deleted.sql
fi
