use master
go
declare @newDBName varchar(50) = 'RDI_Development'
declare @scrubbed bit = 0

--declare @dir varchar(1000) = 'c:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\'
declare @dir varchar(1000) = 'E:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\'
declare @mdf varchar(1000) = @dir + @newDBName + '.mdf'
declare @ldf varchar(1000) = @dir + @newDBName + '.ldf'

declare @yesterday date = dateadd(d, -1, convert(varchar, getdate(), 101))
declare @datestring varchar(20) = convert(varchar, datepart(yy, @yesterday)) + '.'
set @datestring = @datestring + convert(varchar, datepart(m, @yesterday)) + '.'
set @datestring = @datestring + convert(varchar, datepart(d, @yesterday))

declare @bak varchar(max) = '\\anc-backupnas02\sqlbackups\RDI_Production.inet-sql-prod.' + @datestring + '.bak'

--RESTORE FILELISTONLY
--FROM DISK = @bak

--goto quit

----Make Database to single user Mode

declare @sql varchar(max)

set @sql = '
	ALTER DATABASE ' + @newDBName + '
	SET SINGLE_USER WITH
	ROLLBACK IMMEDIATE'
exec( @sql)

print 'Begin DB Restore'

restore database @newDBName
from disk = @bak
with move 'resdat_be2000SQL_dat' to @mdf,
move 'resdat_be2000SQL_log' to @ldf

print 'DB Restore Finished'

if @scrubbed = 1
begin
	print 'Begin scrub'

	set @sql = '
		use ' + @newDBName + '
		exec rdi_cleandevdatabase'
	exec(@sql)

	print 'End scrub'
end

set @sql = '
	ALTER DATABASE ' + @newDBName + '
	SET MULTI_USER'
exec(@sql)

set @sql = '
	use ' + @newDBName + '

	DECLARE @username VARCHAR(25)
	DECLARE @password VARCHAR(25)
	DECLARE GetOrphanUsers CURSOR
	FOR
	SELECT UserName = name
	FROM sysusers
	WHERE issqluser = 1
	AND (sid IS NOT NULL
	AND sid <> 0x0)
	AND SUSER_SNAME(sid) IS NULL
	ORDER BY name
	OPEN GetOrphanUsers
	FETCH NEXT
	FROM GetOrphanUsers
	INTO @username
	SET @password = @username
	WHILE @@FETCH_STATUS = 0
	BEGIN
	IF @username=''dbo''
	EXEC sp_changedbowner ''sa''
	ELSE
	EXEC sp_change_users_login ''Auto_Fix'', @username, NULL, @password
	FETCH NEXT
	FROM GetOrphanUsers
	INTO @username
	END
	CLOSE GetOrphanUsers
	DEALLOCATE GetOrphanUsers'

exec (@sql)

set @sql = '
	use ' + @newDBName + '

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
		exec(''create login ['' + @username + ''] from windows'')

		fetch next
		from GetOrphanUsers
		into @username
	end

	close GetOrphanUsers
	deallocate GetOrphanUsers'

exec (@sql)

quit: