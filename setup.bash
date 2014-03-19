#!/bin/bash

bc_setup ()
{
	cp bashrc.bash ~/.custom_bashrc
	cp customprompt.bash ~/.custom_prompt

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
	
	# set up git config if git is installed
	type git > /dev/null
	if [ $? -eq 0 ]
	then
		local git_conf="git config --global"
		$git_conf alias.gr "!git reset --hard && git clean -df"
		$git_conf alias.grx "!git reset --hard && git clean -dfx --exclude='_Resharper*'"
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
		$git_conf alias.mprod "merge --no-ff -sresolve"
		$git_conf alias.po "!git pull origin \$(git rev-parse --abbrev-ref HEAD)"
		$git_conf push.default current
		$git_conf rebase.autosquash true
		$git_conf color.status always
	fi

	cp vimrc ~/.vimrc
}

bc_setup
