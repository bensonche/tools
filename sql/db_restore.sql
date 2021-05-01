use master
go
declare @newDBName varchar(50) = 'RDI_Development'
declare @scrubbed bit = 0

--declare @dir varchar(1000) = 'c:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\'
declare @dir varchar(1000) = 'E:\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\'
declare @mdf varchar(1000) = @dir + @newDBName + '.mdf'
declare @ldf varchar(1000) = @dir + @newDBName + '.ldf'

declare @today date = getdate()
declare @datestring varchar(20) = convert(varchar, datepart(yy, @today)) + '.'
set @datestring = @datestring + convert(varchar, datepart(m, @today)) + '.'
set @datestring = @datestring + convert(varchar, datepart(d, @today))

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
with
	move 'resdat_be2000SQL_dat' to @mdf,
	move 'resdat_be2000SQL_log' to @ldf,
	stats = 1

set @sql = '
	ALTER DATABASE ' + @newDBName + '
	SET recovery simple'
exec( @sql)

set @sql = '
	use ' + @newDBName + '
	dbcc shrinkfile (resdat_be2000SQL_log, 1)'
exec(@sql)

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

	declare @username varchar(max)
	declare @orphans table
	(
		username varchar(max),
		userSid varchar(max)
	)

	insert into @orphans
	exec sp_change_users_login ''report''

	declare GetOrphanUsers cursor
	for
	select username
	FROM @orphans

	open GetOrphanUsers

	fetch next
	from GetOrphanUsers
	into @username

	while @@fetch_status = 0
	begin
		exec sp_change_users_login ''Auto_Fix'', @username
		
		fetch next
		from GetOrphanUsers
		into @username
	end

	close GetOrphanUsers
	deallocate GetOrphanUsers'

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
		begin try
			print ''create login ['' + @username + ''] from windows''
			exec(''create login ['' + @username + ''] from windows'')
		end try
		begin catch
		end catch

		fetch next
		from GetOrphanUsers
		into @username
	end

	close GetOrphanUsers
	deallocate GetOrphanUsers
'

exec (@sql)

declare @envShortName varchar(10) = null
if charindex('dev', @newDBName) > 0
	set @envShortName = 'dev'
else if charindex('test', @newDBName) > 0
	set @envShortName = 'test'

if @envShortName is not null
begin
	set @sql = '
		use ' + @newDBName + '

		CREATE USER [RESDAT\svc.' + @envShortName + 'api] FOR LOGIN [RESDAT\svc.' + @envShortName + 'api]

		alter role IntranetApplicationAccount
		add member [resdat\svc.' + @envShortName + 'api]'

	exec (@sql)
end

quit:
