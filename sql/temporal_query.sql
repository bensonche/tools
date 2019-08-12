declare @time datetimeoffset = cast('2019-08-05 10:40:27' as datetime) at time zone 'alaskan standard time' at time zone 'utc'

select *
from time_sht
for system_time as of @time
where empid = 695
and wk_date between '7/28/19' and '8/3/19'


select
	sysstarttime at time zone 'utc' at time zone 'alaskan standard time' as sysStartAK,
	sysendtime at time zone 'utc' at time zone 'alaskan standard time' as sysEndAK,
	ins_user,
	ins_date,
	upd_user,
	upd_date,
	date_exported,
	*
from time_sht_history
where empid = 695
and wk_date between '7/28/19' and '8/3/19'
order by sysstarttime, time_sht_key
