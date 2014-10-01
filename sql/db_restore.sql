declare @newDBName varchar(50) = 'RDI_Dev_62554'

declare @dir varchar(1000) = 'c:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\'
declare @mdf varchar(1000) = @dir + @newDBName + '.mdf'
declare @ldf varchar(1000) = @dir + @newDBName + '.ldf'

declare @yesterday date = dateadd(d, -1, convert(varchar, getdate(), 101))
declare @datestring varchar(20) = convert(varchar, datepart(yy, @yesterday)) + '.'
set @datestring = @datestring + convert(varchar, datepart(m, @yesterday)) + '.'
set @datestring = @datestring + convert(varchar, datepart(d, @yesterday))

declare @bak varchar(max) = '\\anc-files\sqlbackups\RDI_Production.SqlServer3.' + @datestring + '.bak'

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

restore database @newDBName
from disk = @bak
with move 'resdat_be2000SQL_dat' to @mdf,
move 'resdat_be2000SQL_log' to @ldf

----Make Database to single user Mode
--ALTER DATABASE YourDB
--SET SINGLE_USER WITH
--ROLLBACK IMMEDIATE

----Restore Database
--RESTORE DATABASE YourDB
--FROM DISK = 'D:BackUpYourBaackUpFile.bak'
--WITH MOVE 'YourMDFLogicalName' TO 'D:DataYourMDFFile.mdf',
--MOVE 'YourLDFLogicalName' TO 'D:DataYourLDFFile.ldf'

set @sql = '
	ALTER DATABASE ' + @newDBName + '
	SET MULTI_USER'
exec(@sql)

--exec rdi_cleandevdatabase
