DECLARE @spwho TABLE(
        SPID INT,
        Status VARCHAR(MAX),
        LOGIN VARCHAR(MAX),
        HostName VARCHAR(MAX),
        BlkBy VARCHAR(MAX),
        DBName VARCHAR(MAX),
        Command VARCHAR(MAX),
        CPUTime INT,
        DiskIO INT,
        LastBatch VARCHAR(MAX),
        ProgramName VARCHAR(MAX),
        SPID_1 INT,
        REQUESTID INT
)

declare @query table(
	eventtype varchar(max),
	params int,
	eventinfo varchar(max),
	spid int 
)

INSERT INTO @spwho EXEC sp_who2

select login, count(*)
from @spwho
where spid > 50
group by login
order by count(*) desc

declare @spid int

declare cur cursor for
select spid
from @spwho
where spid > 50
and login = 'resdat\bche'

open cur

fetch next from cur into @spid

while @@FETCH_STATUS = 0
begin
	insert into @query(eventtype, params, eventinfo)
	exec('DBCC INPUTBUFFER(' + @spid + ')')

	update @query
	set spid = @spid
	where spid is null

	fetch next from cur into @spid
end

close cur
deallocate cur

select *
from @query
order by eventtype