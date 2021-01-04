declare @username varchar(max)
declare GetOrphanUsers cursor
for
    select a.name
    from sysusers a
        left join sys.server_principals b
            on a.sid = b.sid
    where b.sid is null
    and a.islogin = 1
    and a.hasdbaccess = 1
    and a.issqluser = 0

open GetOrphanUsers

fetch next
from GetOrphanUsers
into @username

while @@fetch_status = 0
begin
	alter user [resdat\glee] with login = [resdat\glee]

	begin try
		print 'create login [' + @username + '] from windows'
		exec('create login [' + @username + '] from windows')
	end try
	begin catch
	end catch

    fetch next
    from GetOrphanUsers
    into @username
end

close GetOrphanUsers
deallocate GetOrphanUsers