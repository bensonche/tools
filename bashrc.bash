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

local GIT_CONF="git config --global"

$GIT_CONF alias.gr "!git reset --hard && git clean -dfx"
$GIT_CONF alias.cm commit
$GIT_CONF alias.s status
$GIT_CONF alias.l "log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold red)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%an - %s%C(reset)%C(bold yellow)%d%C(reset)'"
$GIT_CONF alias.mt "mergetool --no-prompt"
$GIT_CONF alias.m merge
$GIT_CONF alias.dt difftool
$GIT_CONF alias.d diff
$GIT_CONF alias.a add
$GIT_CONF alias.co checkout
$GIT_CONF alias.mprod "merge --no-ff -sresolve"
$GIT_CONF alias.po "!git pull origin $(git rev-parse --abbrev-ref HEAD)"
$GIT_CONF push.default current
$GIT_CONF color.status always
	
source ~/.custom_prompt
