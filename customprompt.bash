bold=$(tput bold)
normal=$(tput sgr0)

smiley () {
	if [ $? -eq 0 ]
	then
		echo ":)"
	else
		echo "x("
	fi
}

export PROMPT_COMMAND="echo -n \"\$(smiley) \""
export PS1="${bold}\w${normal}\n$ "
