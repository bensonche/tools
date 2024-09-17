custom_bashrc_intranet ()
{
	# intranet specific settings
	alias cb="check_branch.sh"
	alias gt="tag.sh"
	alias pt="push_to_test.sh"
	alias db="create_db_script.sh"
	alias tdb="create_test_db_script.sh"
	alias log="log.sh"
	alias mprod="mprod.sh"
	alias ptt="ptt.sh"
	alias markBranch="mark_branch.sh"

	alias testdb="cd ../db && git fetch && git grx && git co origin/auto-dev-branch && tdb test"

	alias build="
/c/NuGet.exe restore Intranet.sln && /c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2019/Enterprise/MSBuild/Current/Bin/MSBuild.exe Intranet.sln //p:Configuration=Release //p:AspNetConfiguration=Release //p:RunCodeAnalysis=false"
	alias buildPublic="/c/NuGet.exe restore RDIPublicSite.sln && /c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2019/Enterprise/MSBuild/Current/Bin/MSBuild.exe RDIPublicSite.sln //p:Configuration=Release //p:AspNetConfiguration=Release //p:RunCodeAnalysis=false"

	export GIT_MERGE_AUTOEDIT=no
}

custom_bashrc ()
{
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
