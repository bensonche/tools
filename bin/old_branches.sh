#!/bin/bash

echo "declare @git table" > branches.sql
echo "(" >> branches.sql
echo "    branch varchar(500)," >> branches.sql
echo "    id int" >> branches.sql
echo ")" >> branches.sql
echo "" >> branches.sql

echo "insert into @git" >> branches.sql
echo "values" >> branches.sql

git ls-remote --heads |
	sed "s/.*refs\/heads\///" |
	grep "[0-9][0-9][0-9][0-9][0-9]" |
	sed "s/\(.*\([0-9][0-9][0-9][0-9][0-9]\).*\)/('\1', \2),/" |
	sed "$ s/,$//" >> branches.sql

echo "" >> branches.sql
echo "select '../tools/delete_if_merged.bash ' + c.branch, c.branch, 'git push origin :' + c.branch, c.id" >> branches.sql
echo "from rdiitem a" >> branches.sql
echo "    inner join itemstatus b" >> branches.sql
echo "        on a.StatusId = b.itemstatusid" >> branches.sql
echo "    inner join @git c" >> branches.sql
echo "        on a.rdiitemid = c.id" >> branches.sql
echo "where b.ApplicationId = 3" >> branches.sql
echo "and ItemStatus in ('closed', 'deleted')" >> branches.sql
