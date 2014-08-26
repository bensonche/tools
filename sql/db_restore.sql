declare @newDBName varchar(50) = 'RDI_Dev_62554'

declare @dir varchar(1000) = 'c:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\'
declare @mdf varchar(1000) = @dir + @newDBName + '.mdf'
declare @ldf varchar(1000) = @dir + @newDBName + '.ldf'

select @mdf, @ldf

--RESTORE FILELISTONLY
--FROM DISK = '\\anc-files\sqlbackups\RDI_Production.SqlServer3.2014.8.20.bak'

restore database @newDBName
from disk = '\\anc-files\sqlbackups\RDI_Production.SqlServer3.2014.8.20.bak'
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