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
	./merge.cmd -GithubToken <token> -Label "Test-DB-scripts-ran"

	create_db_script.sh $@

	git tag -f Test_DB_Script
	git push -f origin Test_DB_Script
}

create_test_db_script $@
