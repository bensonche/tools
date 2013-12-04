if [ -d "/c/svn/Intranet" ]
then
	# intranet specific settings
	cd /c/svn/Intranet

	local TOOLS_DIR='/c/svn/tools/'
	
	alias cb="${TOOLS_DIR}check_branch.bash"
	alias gt="${TOOLS_DIR}tag.bash"
	alias gr="git reset --hard && git clean -dfx"
	alias pt="${TOOLS_DIR}push_to_test.bash"
	alias db="${TOOLS_DIR}create_db_script.bash"
	alias log="${TOOLS_DIR}log.bash"
fi

git config --global alias.gr "!git reset --hard && git clean -dfx"

source ~/.custom_prompt
