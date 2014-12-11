#!/bin/bash

echo "declare @git table" > create.sql
echo "(" >> create.sql
echo "    branch varchar(500)," >> create.sql
echo "    id int" >> create.sql
echo ")" >> create.sql
echo "" >> create.sql

echo "insert into @git" >> create.sql
echo "values" >> create.sql

git ls-remote --heads |
	sed "s/.*refs\/heads\///" |
	grep "[0-9][0-9][0-9][0-9][0-9]" |
	sed "s/\(.*\([0-9][0-9][0-9][0-9][0-9]\).*\)/('\1', \2),/" |
	sed "$ s/,$//" >> create.sql

echo "" >> create.sql
echo "select '../tools/delete_if_merged.bash ' + c.branch, c.branch, 'git push origin :' + c.branch, c.id" >> create.sql
echo "from rdiitem a" >> create.sql
echo "    inner join itemstatus b" >> create.sql
echo "        on a.StatusId = b.itemstatusid" >> create.sql
echo "    inner join @git c" >> create.sql
echo "        on a.rdiitemid = c.id" >> create.sql
echo "where b.ApplicationId = 3" >> create.sql
echo "and ItemStatus in ('closed', 'deleted')" >> create.sql