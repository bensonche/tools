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

export PS1="\$(smiley) ${bold}\w${normal}\n$ "
