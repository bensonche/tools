#!/bin/bash

function create_db_script ()
{
	local sqlcmd_path="sqlcmd"
	local start_ssms="start"

	if [ -f db_script.sql ]
	then
		rm db_script.sql
	fi

	echo "Checking files..."

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

	echo "Creating script..."

	find Database/repeatable -name \*.sql | egrep sql$i | sed 's/^/cat \"/' | sed 's/$/\" >> db_script.sql; echo -e "\\ngo\\n" >> db_script.sql/' > db_files.txt
	
	if [ -s db_files.txt ]
	then
		./db_files.txt
	fi

	if [ $# -gt 1 ] && [ $2 == "-s" ]
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
