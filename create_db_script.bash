#!/bin/bash

create_commit_hash_query ()
{
	echo "select 'db ' + Code" > create_commit_hash_query.sql
	echo "from CODES" >> create_commit_hash_query.sql
	echo "where FieldName = 'CurrentGitCommit'" >> create_commit_hash_query.sql
	echo "go" >> create_commit_hash_query.sql
}

cmdline()
{
	while getopts ":s" OPTION
	do
		case $OPTION in
			s)
				readonly SILENT=1
				;;
			\?)
				echo "Invalid option: -$OPTARG"
				exit 1
				;;
		esac
	done
	shift $((OPTIND-1))
	readonly COMMIT=$1
}

function create_db_script ()
{
	local sqlcmd_path="sqlcmd"
	local start_ssms="start"

	local dev="-S sql-intranet2 -d RDI_Development"
	local test="-S sqlserver3 -d RDI_Test"
	local prod="-S sqlserver3 -d RDI_Production"

	cmdline $@

	# Navigate to root of git repo
	cd "$(git rev-parse --show-toplevel)"

	if [ $# -lt 1 ]
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

	local batchread=0
	local env=""
	local hash=""
	if [ $COMMIT = "dev" ]
	then
		env=$dev
		batchread=1
	elif [ $COMMIT = "test" ]
	then
		env=$test
		batchread=1
	elif [ $COMMIT = "prod" ]
	then
		env=$prod
		batchread=1
	else
		hash=$COMMIT
	fi

	if [ $batchread -eq 1 ]
	then
		create_commit_hash_query
		hash=`$sqlcmd_path $env -i create_commit_hash_query.sql | grep db | sed "s/db \([0-9a-zA-Z]*\) *$/\1/"`
		echo $hash
		
		start_ssms="ssms $env"
	fi

	local left=$hash
	local right=head

	if [ -f db_script.sql ]
	then
		rm db_script.sql
	fi

	git diff --name-status $left..head Database/

	read -p "Press [Enter] key to continue..."

	git diff -w $left..head Database/

	echo
	echo
	
	local valid=1

	git diff --name-status $left..head Database/ | egrep '^[a-ce-zA-CE-Z]' | sed 's/^[A-Z][ \t]\+//' | grep Database/rep |
	while read line; do
		local file=$line
		local fileWin=$(echo $file | sed 's/\//\\/g')
		
		grep -q ÿþ "$file"
		if [ $? -eq 0 ]
		then
			valid=0
			echo "$file is in UTF-16"

			cmd //c type "$fileWin" > cb_temp_sql
			cp cb_temp_sql "$file"
		fi
		grep -q ï»¿ "$file"
		if [ $? -eq 0 ]
		then
			valid=0
			echo "$file is in UTF-8 with BOM"

			cmd //c type "$fileWin" > cb_temp_sql
			cp cb_temp_sql "$file"
		fi
	done
	
	if [ $valid -eq 0 ]
	then
		exit 1
	fi

	git diff --name-status $left..head Database/ | egrep '^D' | sed 's/^[A-Z][ \t]\+//' | grep Database/rep | sed 's/\(.*\)\.sql$/\1/' | sed 's/^Database\/repeatable\/\(.*\)/\1/' |
		sed 's/triggers\/\(.*\)/drop trigger \1/' |
		sed 's/procs\/\(.*\)/drop proc \1/' |
		sed 's/functions\/\(.*\)/drop function \1/' |
		sed 's/views\/\(.*\)/drop view \1/'	> db_deleted.sql

	git diff --name-status $left..head Database/ | egrep '^[a-ce-zA-CE-Z]' | sed 's/^[A-Z][ \t]\+//' | grep Database/rep | sed 's/^/cat \"/' | sed 's/$/\" >> db_script.sql; echo -e "\\ngo\\n" >> db_script.sql/' > db_files.txt
	
	if [ -s db_files.txt ]
	then
		echo -en "/*\nupdate CODES\nset code = '" >> db_script.sql
		echo -n $left >> db_script.sql
		echo -en "'\nwhere FieldName = 'CurrentGitCommit'\n*/\n\n" >> db_script.sql
		
		./db_files.txt
	fi

	if [ -s db_script.sql ]
	then
		echo "exec RDISecurity.SynchronizeIntranetItemAndDb" >> db_script.sql
		echo >> db_script.sql
		echo -en "update CODES\nset code = '" >> db_script.sql
		echo -en `git log -1 --format="%H"` >> db_script.sql
		echo -en "'\nwhere FieldName = 'CurrentGitCommit'" >> db_script.sql
	else
		echo "No database script created because there were no changes"
	fi

	cat db_deleted.sql

	if [ $# -gt 1 ] && [ $SILENT == 1 ]
	then
		exit 0
	fi

	local files=""
	if [ -s db_script.sql ]
	then
		files="$files db_script.sql"
	fi
	if [ -s db_deleted.sql ]
	then
		files="$files db_deleted.sql"
	fi

	if [ ! "$files" == "" ]
	then
		echo "Starting ssms..."
		$start_ssms $files &
	fi
}

create_db_script $@
