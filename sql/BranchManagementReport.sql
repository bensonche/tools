use rdi_production

declare @knownTuesday date = '12/11/2018'

declare @numbers table ( num int )
declare @dates table ( date date )

insert into @numbers
select top 31 row_number() over (order by name)
from sys.all_columns

insert into @dates
select datefromparts(year(getdate()), month(getdate()), num)
from @numbers
where num <= day(eomonth(getdate()))
union
select datefromparts(year(dateadd(m, -1, getdate())), month(dateadd(m, -1, getdate())), num)
from @numbers
where num <= day(eomonth(dateadd(m, -1, getdate())))
union
select datefromparts(year(dateadd(m, -2, getdate())), month(dateadd(m, -2, getdate())), num)
from @numbers
where num <= day(eomonth(dateadd(m, -2, getdate())))

declare @dtFrom date ,@dtTo date, @dt2MonthsAgo date

-- Second Tues of last month
set @dt2MonthsAgo = (
	select date
	from @dates
	where
		datepart(mm, date) = month(dateadd(m, -2, getdate()))
		and datepart(dw, date) = datepart(dw, @knownTuesday)
		and day(date) between 8 and 15
)
-- Second Tues of last month
set @dtFrom = (
	select date
	from @dates
	where
		datepart(mm, date) = month(dateadd(m, -1, getdate()))
		and datepart(dw, date) = datepart(dw, @knownTuesday)
		and day(date) between 8 and 15
)
-- Second Tues of this month
set @dtTo = (
	select date
	from @dates
	where
		datepart(mm, date) = month(getdate())
		and datepart(dw, date) = datepart(dw, @knownTuesday)
		and day(date) between 8 and 15
)

set @dt2MonthsAgo = dateadd(dd, -2, @dt2MonthsAgo)
set @dtFrom = dateadd(dd, -2, @dtFrom)
set @dtTo = dateadd(dd, -3, @dtTo)

declare @dtFromMonthStart2 datetime = dateadd(m, -12, @dtTo)
set @dtFromMonthStart2 = DATEADD(wk, DATEDIFF(wk, 0, @dtFromMonthStart2), -1) -- Get sunday

select cast(@dtfrom as date), cast(@dtto as date)

-- 1
-- items assigned not including QA or Owners (unless the owner is Julie and it is in a working status)
select cast(count(*) as varchar) as Assigned
from rdiitem ri
	inner join itemstatus ist
		on ri.statusid = ist.itemstatusid
	inner join allusers au
		on ri.assignedto = au.userid
where ri.client_id = 363 and ri.project_no = 9 
	and statusid not in (2, 3, 8, 10, 60, 61)  -- Closed, Quality Assurance, Deleted, Delivered
	and assignedto <> 10000 -- don't include Intranet Group
	and ist.ApplicationId = 3 -- only look at PT (ignore Pivotal Tracker)
	and assignedto not in (select distinct empid from tagowner)

union all
-- 2
-- unassigned items
select cast(count(*) as varchar) as Unassigned
from rdiitem 
where client_id = 363 and project_no = 9 
	and statusid in (1, 5)
	and assignedto = 10000

union all
-- 3
-- Intranet hours
select cast(cast(SUM(amount) as decimal(18, 2)) as varchar) as IntranetHours
from time_sht
where
	CLIENT_ID = 363
	and PROJECT_NO = 9
	and WK_DATE between @dtFrom and @dtTo

union all
-- 4
-- Staff count >= 4 hours
select cast(COUNT(*) as varchar) as StaffCount
from
	(
		select empid
		from time_sht
		where
			CLIENT_ID = 363
			and PROJECT_NO = 9
			and WK_DATE between @dtFrom and @dtTo
			and EMPID < 1000
		group by EMPID
		having SUM(amount) >= 4
	) a

union all
-- 5
-- items assigned to owners (if the owner is Julie, new and open status only)
select cast(count(*) as varchar) as Owners
from rdiitem 
where client_id = 363 and project_no = 9 
	and statusid not in (2, 8, 10, 60)
	and AssignedTo in (select empid from tagowner where empid <> 77) 
	and not (assignedto = 77 and statusid not in (1, 5))
	and assignedto <> 10000

union all
-- 6
-- people who created intranet tickets last 2 weeks
select  cast(count(*) as varchar) as TicketsCreated
from rdiitem i
where i.ins_date between @dtFrom and @dtTo
	and i.client_id = 363
	and i.project_no = 9
	and i.itemtypeid in (1, 2, 3, 4, 5)

union all
select cast(COUNT(*) as varchar) as NewEmployees
from
	(
	select au.fullname2
	from EmployeePosition ep
		inner join allusers au on ep.empid = au.empid
		inner join time_sht t on t.empid = ep.empid
	where startdate >= dateadd(mm, -1, @dtTo)
		and not exists (select 1 from EmployeePosition x where x.empid = ep.empid and x.EmployeePositionID <> ep.EmployeePositionID)
		and t.client_id = 363 and t.project_no = 9
		and t.wk_date between dateadd(dd, -14, @dtTo) and @dtTo
	group by au.fullname2
    having sum(t.amount) > 4
	) a

-- 7
-- New staff < 1 months
select au.fullname2 as NewStaff, sum(t.amount)
from EmployeePosition ep
	inner join allusers au on ep.empid = au.empid
	inner join time_sht t on t.empid = ep.empid
where startdate between @dtFrom and @dtTo
	and not exists (select 1 from EmployeePosition x where x.empid = ep.empid and x.EmployeePositionID <> ep.EmployeePositionID)
	and t.client_id = 363 and t.project_no = 9
	and t.wk_date between dateadd(dd, -14, @dtTo) and @dtTo
group by au.fullname2
having sum(t.amount) > 4
order by au.fullname2

-- 8
-- Total Hours
;with Intranet_cte as
(
	select
		cast(DATEADD(wk, DATEDIFF(wk, 0, t.WK_DATE), -1) as date) as date, -- Get sunday of the week
		sum(t.amount) as IntranetHours
	from time_sht t
	where t.client_id = 363 and t.project_no = 9
		and WK_DATE between dateadd(dd, 1, dateadd(wk, -80, @dtTo)) and @dtTo
	group by cast(DATEADD(wk, DATEDIFF(wk, 0, t.WK_DATE), -1) as date)
),
Total_cte as
(
	select
		cast(DATEADD(wk, DATEDIFF(wk, 0, t.WK_DATE), -1) as date) as date,
		sum(t.amount) as TotalHours
	from time_sht t
	where EMPID < 1000
		and WK_DATE between dateadd(dd, 1, dateadd(wk, -80, @dtTo)) and @dtTo
	group by cast(DATEADD(wk, DATEDIFF(wk, 0, t.WK_DATE), -1) as date)
)
select a.date, b.IntranetHours, a.TotalHours
from total_cte a
	left join Intranet_cte b
		on a.date = b.date
order by a.date

-- 9
-- people who billed time to the intranet last two weeks
select
    au.fullname2,
    cast(sum(t.amount) as numeric(18,2)) as HrsLast2Wks,
    ho.home_office + case when t.empid in (320, 198, 77) then ' (IG)' else '' end,
	case when devs.empid is not null then null else 'non dev' end
from time_sht t 
	inner join allusers au
		on t.empid = au.empid
	left join vw_all_active_employee_info ho
		on t.empid = ho.empid
	left join
	(
		select a.empid as empid
		from time_sht a
		inner join AllUsers b
			on a.EMPID = b.USERID
		where
			a.CLIENT_ID = 363
			and PROJECT_NO = 9
			and wk_date between dateadd(dd, -14, @dtTo) and @dtTo
			and RDIItemId is not null
			and JOB_CODE in (332,340,345,430,435,305,310,311,1332,1340,1345,1430,1435,1305,1310,1311)
		group by a.empid
		having sum(a.amount) >= 4
	) devs
		on t.empid = devs.empid
where t.client_id = 363 and t.project_no = 9
	and t.wk_date between dateadd(dd, -14, @dtTo) and @dtTo
group by au.fullname2, ho.home_office, t.empid, devs.empid
having sum(t.amount) >= 4
order by sum(t.amount) desc

select
	cast(date as date) as [Yr-Mo],
	Anchorage,
	Boise,
	Corporate,
	Houston,
	Juneau,
	Portland
from
(
	select
		a.LOCATION as Location,
		a.date,
		case
			when isnull(totalhours, 0) = 0
				then 0
			else
				convert(numeric(18, 4), isnull(IntranetHours, 0) / TotalHours * 100)
		end as Percentage
	from
		(
			select
				LOCATION,
				dateadd(dd, -(datediff(dd, a.wk_date, @dtTo) / 14) * 14 - 13, @dtTo) as date,
				SUM(a.amount) TotalHours
			from time_sht a
				inner join RDI_Employee b
					on a.EMPID = b.empid
			where WK_DATE between @dtFromMonthStart2 and @dtTo
			group by b.LOCATION, datediff(dd, a.wk_date, @dtTo) / 14
		) a
		left join
			(
				select
					LOCATION,
					dateadd(dd, -(datediff(dd, a.wk_date, @dtTo) / 14) * 14 - 13, @dtTo) as date,
					SUM(a.amount) IntranetHours
				from time_sht a
					inner join RDI_Employee b
						on a.EMPID = b.empid
				where
					WK_DATE between @dtFromMonthStart2 and @dtTo
					and CLIENT_ID = 363
					and PROJECT_NO = 9
				group by b.LOCATION, datediff(dd, a.wk_date, @dtTo) / 14
			) b
			on a.LOCATION = b.location and a.date = b.date
) main
pivot
(
	sum(Percentage)
	for	Location in
	(
		Anchorage,
		Boise,
		Corporate,
		Fairbanks,
		Houston,
		Juneau,
		Portland
	)
) as p
order by date


select
	a.LOCATION as Location,
	case
		when a.totalhours = 0
			then 0
		else
			convert(numeric(18, 2), isnull(b.IntranetHours, 0) / a.TotalHours * 100)
	end as Percentage,
	case
		when c.totalhours = 0
			then 0
		else
			convert(numeric(18, 2), isnull(d.IntranetHours, 0) / c.TotalHours * 100)
	end as OldPercentage
from
	(
		select
			LOCATION,
			SUM(a.amount) TotalHours
		from time_sht a
			inner join RDI_Employee b
				on a.EMPID = b.empid
		where WK_DATE between @dtFrom and @dtTo
		group by b.LOCATION
	) a
	left join
		(
			select
				LOCATION,
				SUM(a.amount) IntranetHours
			from time_sht a
				inner join RDI_Employee b
					on a.EMPID = b.empid
			where
				WK_DATE between @dtFrom and @dtTo
				and CLIENT_ID = 363
				and PROJECT_NO = 9
			group by b.LOCATION
		) b
		on a.LOCATION = b.location
	left join
		(
			select
				LOCATION,
				SUM(a.amount) TotalHours
			from time_sht a
				inner join RDI_Employee b
					on a.EMPID = b.empid
			where WK_DATE between @dt2MonthsAgo and dateadd(dd, -1, @dtFrom)
			group by b.LOCATION
		) c
		on a.location = c.location
		left join
			(
				select
					LOCATION,
					SUM(a.amount) IntranetHours
				from time_sht a
					inner join RDI_Employee b
						on a.EMPID = b.empid
				where
					WK_DATE between @dt2MonthsAgo and dateadd(dd, -1, @dtFrom)
					and CLIENT_ID = 363
					and PROJECT_NO = 9
				group by b.LOCATION
			) d
			on a.LOCATION = d.location
order by percentage desc, Location


-- Overestimates

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
	i.LOCATION,
	i.RDIItemId,
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
having i.HoursEstimated < cast(sum(isnull(ts.amount, 0)) as decimal(18, 2))
order by location, AssignedTo, i.RDIItemId