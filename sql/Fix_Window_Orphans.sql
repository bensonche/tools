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
    exec('create login [' + @username + '] from windows')

    fetch next
    from GetOrphanUsers
    into @username
end

close GetOrphanUsers
deallocate GetOrphanUsers