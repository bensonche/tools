use rdi_production

;with items as
(
	select
		ri.rdiitemid,
		ro.location,
		isnull(re.NickName, re.fname) + ' ' + re.lname as AssignedTo,
		ri.AssignedTo as Empid,
		ri.title,
		ri.HoursEstimated,
		sum(tst.amount) as TotalHoursWorked
	from rdiitem ri
		left join time_sht tst -- Total hours for PT
			on ri.RDIItemId = tst.RDIItemId
		inner join RDI_Employee re
			on ri.AssignedTo = re.empid
		inner join [RDI OFFICES] ro
			on re.homeofficecode = ro.code
	where ri.client_id = 363 and ri.project_no = 9 
	and statusid not in (2, 8, 10, 60)  -- Closed, Quality Assurance, Deleted, Delivered
	and assignedto <> 10000 -- don't include Intranet Group
	and isnull(hoursEstimated, 0) > 0
	group by ri.rdiitemid, ri.title, ri.HoursEstimated, re.NickName, re.fname, re.lname, ro.location, ri.AssignedTo
	having HoursEstimated * 2 < sum(tst.amount)
)
select
	i.RDIItemId,
	i.LOCATION,
	i.AssignedTo,
	i.Title,
	i.HoursEstimated,
	cast(sum(isnull(ts.amount, 0)) as decimal(18, 2)) as EmployeeHoursWorked,
	cast(i.TotalHoursWorked as decimal(18, 2)) as TotalHoursWorked
from items i
	left join TIME_SHT ts -- Get hours per employee
		on i.RDIItemId = ts.RDIItemId
		and i.empid = ts.EMPID
group by
	i.RDIItemId,
	i.LOCATION,
	i.AssignedTo,
	i.Title,
	i.HoursEstimated,
	i.TotalHoursWorked
order by location, AssignedTo, i.RDIItemId