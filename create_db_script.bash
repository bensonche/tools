#!/bin/bash

function create_commit_hash_query
{
	echo "select 'db ' + Code" > create_commit_hash_query.sql
	echo "from CODES" >> create_commit_hash_query.sql
	echo "where FieldName = 'CurrentGitCommit'" >> create_commit_hash_query.sql
	echo "go" >> create_commit_hash_query.sql
}

SQLCMD_PATH="sqlcmd"
START_SSMS="start"

DEV="-S sql-intranet2 -d RDI_Development"
TEST="-S sqlserver3 -d RDI_Test"
PROD="-S sqlserver3 -d RDI_Production"

# Navigate to root of git repo
cd "$(git rev-parse --show-toplevel)"

if [ $# -ne 1 ]
then
	echo "Usage: create_db_script.bash <hash>"
	echo "   Or: create_db_script.bash [dev|test|prod]"
	echo
	echo "The hash can be retrieved from the database with the following query:"
	echo "    select 'db ' + Code"
	echo "    from CODES"
	echo "    where FieldName = 'CurrentGitCommit'"
	
	exit 1
fi

BATCHREAD=0
if [ $1 = "dev" ]
then
	ENV=$DEV
	BATCHREAD=1
elif [ $1 = "test" ]
then
	ENV=$TEST
	BATCHREAD=1
elif [ $1 = "prod" ]
then
	ENV=$PROD
	BATCHREAD=1
else
	HASH=$1
fi

if [ $BATCHREAD -eq 1 ]
then
	create_commit_hash_query
	HASH=`$SQLCMD_PATH $ENV -i create_commit_hash_query.sql | grep db | sed "s/db \([0-9a-zA-Z]*\) *$/\1/"`
	echo $HASH
	
	START_SSMS="ssms $ENV"
fi

LEFT=$HASH
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

if [ -s db_script.sql ]
then
	echo -en "update CODES\nset code = '" >> db_script.sql
	echo -en `git log -1 --format="%H"` >> db_script.sql
	echo -en "'\nwhere FieldName = 'CurrentGitCommit'" >> db_script.sql
else
	echo "No database script created because there were no changes"
fi

cat db_deleted.sql

FILES=""
if [ -s db_script.sql ]
then
	FILES="$FILES db_script.sql"
fi
if [ -s db_deleted.sql ]
then
	FILES="$FILES db_deleted.sql"
fi

if [ ! "$FILES" == "" ]
then
	$START_SSMS $FILES &
fi
