#!/bin/bash

install_custom_bashrc ()
{
	cp bashrc.sh ~/.custom_bashrc
	cp customprompt.sh ~/.custom_prompt

	chmod 777 ~/.custom_bashrc
	chmod 777 ~/.custom_prompt

	if [ ! -e ~/.bashrc ]
	then
		touch ~/.bashrc
	fi

	local cmd="source ~/.custom_bashrc"
	grep -q "$cmd" ~/.bashrc
	if [ $? -ne 0 ]
	then
		echo "" >> ~/.bashrc
		echo $cmd >> ~/.bashrc
	fi
}

setup_custom_home ()
{
	local default_dir
	read -e -p "Specify default home dir:" default_dir
	if [ -n "$default_dir" ]
	then
		if [ $default_dir == "" ]
		then
			default_dir="/c/svn/Intranet"
		elif [ $default_dir == "~" ]
		then
			default_dir="$(cd $(dirname $BASH_SOURCE[0]) && pwd)"
		fi

		if [ -d "$default_dir" ]
		then
			echo "cd $default_dir" >> ~/.custom_bashrc
			echo alias home="\"cd $default_dir\"" >> ~/.custom_bashrc
		else
			echo "Not a valid dir"
			return 1
		fi
	fi
}


bc_setup ()
{
	install_custom_bashrc

	# set up home alias and directory
	setup_custom_home
	while [ $? -ne 0 ]; do
		setup_custom_home
	done

	echo $default_dir

	local tools_dir=$(cd $(dirname $BASH_SOURCE[0]) && cd bin && pwd)

	echo "PATH=\$PATH:$tools_dir" >> ~/.custom_bashrc

	local include_intranet
	while [[ -z "$include_intranet"  \
		|| ( "$include_intranet" != "n"  \
			&& "$include_intranet" != "N" \
			&& "$include_intranet" != "y" \
			&& "$include_intranet" != "Y" ) ]]; do
		read -p "Include Intranet tools? " include_intranet
	done

	if [[ "$include_intranet" == "y" || "$include_intranet" == "Y" ]]
	then
		echo "custom_bashrc_intranet" >> ~/.custom_bashrc
	fi

	# set up git config if git is installed
	type git > /dev/null
	if [ $? -eq 0 ]
	then
		local git_conf="git config --global"
		$git_conf alias.gr "!git reset --hard && git clean -df && exit 0"
		$git_conf alias.grx "!git reset --hard && git clean -dfx --exclude='*sln.DotSettings.user' --exclude='_Resharper*' && exit 0"
		$git_conf alias.cm commit
		$git_conf alias.ac "!git add -u && git commit"
		$git_conf alias.s status
		$git_conf alias.l "log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold red)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%an - %s%C(reset)%C(bold yellow)%d%C(reset)'"
		$git_conf alias.ll "log --stat"
		$git_conf alias.mt "mergetool --no-prompt"
		$git_conf alias.m merge
		$git_conf alias.dt difftool
		$git_conf alias.d diff
		$git_conf alias.a add
		$git_conf alias.co checkout
		$git_conf alias.po "!git pull origin \$(git rev-parse --abbrev-ref HEAD)"
		$git_conf alias.gp "!git grep --break --heading"
		$git_conf alias.lt "!git for-each-ref --sort=taggerdate --format '%(refname) %09 %(color:yellow)%(taggerdate)' refs/tags | sed 's/^refs\/tags\///' | egrep '^Release'"
		$git_conf push.default current
		$git_conf rebase.autosquash true
		$git_conf color.status always
	fi

	cp vimrc ~/.vimrc
}

bc_setup
