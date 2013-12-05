smiley ()
{
	if [ $? -eq 0 ]
	then
		echo -e "\033[1m\033[32m:)\033[0m"
	else
		echo -e "\033[1m\033[31mx(\033[0m"
	fi
}

create_prompt ()
{
	bold="\033[1m"
	normal="\033[0m"

	#check that __git_ps1 exists
	local GIT_PS1=""
	type __git_ps1 > /dev/null
	if [ $? -eq 0 ]
	then
		GIT_PS1="\$(__git_ps1)"
	fi

	export PS1="\n${bold}\[\033[33m\][\!] \[\033[0m\]\$(smiley) ${bold}\[\033[33m\]\w${GIT_PS1}${normal}\[\033[0m\]\n$ "
}

create_prompt
