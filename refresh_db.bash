#!/bin/bash

function create_db_script ()
{
	local sqlcmd_path="sqlcmd"
	local start_ssms="start"
	local silent=0
	local skipCheck=0

	for var in "$@"
	do
		case "$var" in
			-s)
				silent=1
				;;
			-c) skipCheck=1
				;;
		esac
	done

	if [ -f db_script.sql ]
	then
		rm db_script.sql
	fi

	if [ $skipCheck -eq 0 ]
	then
		echo "Checking files..."

		local valid=1

		find Database/repeatable -name \*.sql | egrep sql$ |
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
	fi

	echo "Creating script..."

	find Database/repeatable -name \*.sql | egrep sql$i | sed 's/^/cat \"/' | sed 's/$/\" >> db_script.sql; echo -e "\\ngo\\n" >> db_script.sql/' > db_files.txt
	
	if [ -s db_files.txt ]
	then
		./db_files.txt
	fi

	if [ $silent -eq 1 ]
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
