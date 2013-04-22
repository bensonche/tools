cd /c/svn/Intranet

function create_aliases {
	local TOOLS_DIR='/c/svn/tools/'
	
	alias cb="${TOOLS_DIR}check_branch.bash"
	alias gt="${TOOLS_DIR}tag.bash"
	alias gr="git reset --hard && git clean -dfx"
	alias pt="${TOOLS_DIR}push_to_test.bash"
}

create_aliases
