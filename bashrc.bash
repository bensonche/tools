home () {
	if [ -d "/c/svn/Intranet" ]
	then
		cd /c/svn/Intranet
	fi
}

custom_bashrc () {
	if [ -d "/c/svn/Intranet" ]
	then
		# intranet specific settings
		cd /c/svn/Intranet

		local tools_dir='/c/svn/tools/'
		
		alias cb="${tools_dir}check_branch.bash"
		alias gt="${tools_dir}tag.bash"
		alias pt="${tools_dir}push_to_test.bash"
		alias db="${tools_dir}create_db_script.bash"
		alias log="${tools_dir}log.bash"
		alias mprod="${tools_dir}mprod.bash"

		alias testdb="cd /c/svn/db && git po && db test"
	fi

	ls --color=auto > /dev/null
	if [ $? -eq 0 ]
	then
		alias ls="ls --color=auto"
	else
		ls -G > /dev/null
		if [ $? -eq 0 ]
		then
			alias ls="ls -G"
		fi
	fi
		
	source ~/.custom_prompt
}

custom_bashrc
