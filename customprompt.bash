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

export PS1="\n\$(smiley) ${bold}\[\033[33m\]\w${normal}\[\033[0m\]\n$ "
