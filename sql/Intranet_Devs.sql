use rdi_production
go

drop table if exists #devs

select a.empid, b.FULLNAME2, EMAIL
into #devs
from time_sht a
inner join AllUsers b
on a.EMPID = b.USERID
where a.CLIENT_ID = 363
and PROJECT_NO = 9
and WK_DATE > DATEADD(ww, -2, GETDATE())
and RDIItemId is not null
and JOB_CODE in (340,345,430,435,305,310,311, 502,1340,1345,1430,1435,1305,1310,1311, 502, 332, 1332, 322, 1322)

union

select userid, fullname2, email
from allusers
where empid in (198, 430, 116, 643, 368, 178)

order by FULLNAME2


select *
from #devs

-------------------------------------------------------------------

select distinct a.empid, b.FULLNAME2, EMAIL
from time_sht a
inner join AllUsers b
on a.EMPID = b.USERID
where a.CLIENT_ID = 363
and PROJECT_NO = 9
and WK_DATE > DATEADD(ww, -2, GETDATE())
and RDIItemId is null
and JOB_CODE in (340,345,430,435,305,310,311, 502,1340,1345,1430,1435,1305,1310,1311, 502, 332, 1332)
and a.empid not in
(
	select empid
	from #devs
)

order by b.FULLNAME2

