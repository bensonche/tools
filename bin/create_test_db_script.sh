#!/bin/bash
usage ()
{
	echo "Usage: create_db_script.bash <hash>"
	echo "   Or: create_db_script.bash [dev|test|prod]"
	echo
	echo "The hash can be retrieved from the database with the following query:"
	echo "    select 'db ' + Code"
	echo "    from CODES"
	echo "    where FieldName = 'CurrentGitCommit'"
}

function create_test_db_script ()
{
	git fetch --tags

	if [[ -z $INTRANET_TOKEN ]] then
		echo "Missing INTRANET_TOKEN environment variable"
		exit 1
	fi

	git checkout origin/master

	./merge.cmd -GithubToken $INTRANET_TOKEN -Label "Test-DB-scripts-ran" -RepoName "Intranet"

	TAG_NAME=Test_DB_Script_$(date +%s)

	git tag $TAG_NAME
	git push origin $TAG_NAME

	create_db_script.sh $@

}

create_test_db_script $@
