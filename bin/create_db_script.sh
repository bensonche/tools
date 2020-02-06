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
	while getopts ":sham" OPTION
	do
		case $OPTION in
			s)
				readonly SILENT=1
				;;
			h)
				usage
				exit 0
				;;
			a)
				readonly ALL=1
				;;
			m)
				readonly COPY=1
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

usage ()
{
	echo "Usage: create_db_script.bash <hash>"
	echo "   Or: create_db_script.bash [dev|test|prod]"
	echo
	echo "The hash can be retrieved from the database with the following query:"
	echo "    select 'db ' + Code"
	echo "    from CODES"
	echo "    where FieldName = 'CurrentGitCommit'"
}

function create_db_script ()
{
	local sqlcmd_path='sqlcmd.exe'
	local start_ssms="start"

	local dev="-S inet-sql-dev -d RDI_Development"
	local test="-S inet-sql-test -d RDI_Test"
	local prod="-S inet-sql-prod -d RDI_Production"

	cmdline $@

	# Navigate to root of git repo
	cd "$(git rev-parse --show-toplevel)"

	if [ -z $COMMIT ] && [ -z $ALL ]
	then
		usage		
		exit 1
	fi

	if [ -z $ALL ]
	then
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
			hash=`$sqlcmd_path $env -i create_commit_hash_query.sql | grep db | sed "s/db \([0-9a-zA-Z]*\).*$/\1/"`
			echo $hash
			
			start_ssms="ssms.exe $env"
		fi

		local left=$hash
		local right=head

		local diff=$(git diff -M100% --name-status $left..head Database/)
		local diffCount=$(echo -n "$diff" | wc -l)

		if [ $diffCount -gt "0" ]
		then
			echo "$diff"
			read -p "Press [Enter] key to continue..."
		fi

		git diff -w $left..head Database/

		echo
		echo
	fi

	if [ -f db_script.sql ]
	then
		rm db_script.sql
	fi

	if [ -z $ALL ]
	then
		local filelist=$(git diff -M100% --name-status $left..head Database/ | egrep '^[a-ce-zA-CE-Z]' | sed 's/^[A-Z][ \t]\+//' | grep Database/rep) 
	else
		local filelist=$(du -a Database/ | cut -f2 | sed '/sql$/!d')
	fi

	if [ -z "$filelist" ]
	then
		echo "No database script created because there were no changes"
		exit 0
	fi


	echo "$filelist" |
		while read line; do
			local file=$line
			
			grep -q ÿþ "$file"
			if [ $? -eq 0 ]
			then
				echo "$file is in UTF-16"

				iconv -f utf-16 -t ascii//TRANSLIT "$file" > cb_temp_sql
				rm "$file"
				mv cb_temp_sql "$file"
			fi
			grep -q ï»¿ "$file"
			if [ $? -eq 0 ]
			then
				echo "$file is in UTF-8 with BOM"

				sed '1s/^ï»¿//' "$file" > cb_temp_sql
				rm "$file"
				mv cb_temp_sql "$file"
			fi
		done

	if [ -z $ALL ]
	then	
		git diff --name-status $left..head Database/ |
			egrep '^D' |
			sed 's/^[A-Z][ \t]\+//' |
			grep Database/rep |
			sed 's/\(.*\)\.sql$/\1/' |
			sed 's/^Database\/repeatable\/\(.*\)/\1/' |
			sed 's/triggers\/\(.*\)/drop trigger if exists \1/' |
			sed 's/procs\/\(.*\)/drop proc if exists \1/' |
			sed 's/functions\/\(.*\)/drop function if exists \1/' |
			sed 's/views\/\(.*\)/drop view if exists \1/'	> db_deleted.sql
	fi

	echo "$filelist" |
		sed 's/^/cat \"/' |
		sed 's/$/\" >> db_script.sql; echo -e "\\ngo\\n" >> db_script.sql/' > db_files.txt
	
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

	if [ $COPY ]
	then
		local date=`date +%Y-%m-%d`
		local dir="/c/users/bche/Dropbox/work/release/${date}"

		if [ -d "$dir" ]
		then
			mv db_script.sql "$dir"
			mv db_files.txt "$dir"
			mv db_deleted.sql "$dir"
		else
			echo "Destination directory does not exist: $dir"
		fi
	fi


	if [ $# -gt 1 ] && [ -n $SILENT ]
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
