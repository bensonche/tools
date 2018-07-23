use rdi_production
go

select a.empid, b.FULLNAME2, EMAIL
from time_sht a
inner join AllUsers b
on a.EMPID = b.USERID
where a.CLIENT_ID = 363
and PROJECT_NO = 9
and WK_DATE > DATEADD(ww, -2, GETDATE())
and RDIItemId is not null
and JOB_CODE in (340,345,430,435,305,310,311, 502,1340,1345,1430,1435,1305,1310,1311, 502, 332, 1332)

union

select userid, fullname2, email
from allusers
where empid in (198, 236, 430)

order by FULLNAME2

/*

select distinct a.empid, b.FULLNAME2, EMAIL
from time_sht a
inner join AllUsers b
on a.EMPID = b.USERID
where a.CLIENT_ID = 363
and PROJECT_NO = 9
and WK_DATE > DATEADD(ww, -2, GETDATE())
and RDIItemId is null
and JOB_CODE in (340,345,430,435,305,310,311, 502,1340,1345,1430,1435,1305,1310,1311, 502, 332, 1332)

*/