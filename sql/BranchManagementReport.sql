 declare @dtFrom datetime ,@dtTo datetime

 set @dtTo = convert(varchar, dateadd(d, -datepart(dw, getdate()), getdate()), 101)
 set @dtFrom = dateadd(d, -13, @dtto)

 select @dtfrom, @dtto

declare @dtFromMonthStart datetime = dateadd(m, -6, @dtTo)
set @dtFromMonthStart = DATEADD(d, -(datepart(d, @dtFromMonthStart) - 1), @dtFromMonthStart)

-- 1
-- items assigned not including QA or Owners (unless the owner is Julie and it is in a working status)
select count(*) as Assigned
from rdiitem 
where client_id = 363 and project_no = 9 
	and statusid not in (2, 8, 10, 60)  -- Closed, Quality Assurance, Deleted, Delivered
	and AssignedTo not in (select empid from tagowner where empid <> 77)  -- no owners except Julie
	and not (assignedto = 77 and statusid in (1, 5)) -- only count Julie's if they aren't New or Open
	and assignedto <> 10000 -- don't include Intranet Group

union all
-- 2
-- unassigned items
select count(*) as Unassigned
from rdiitem 
where client_id = 363 and project_no = 9 
	and statusid in (1, 5)
	and assignedto = 10000

union all
-- 3
-- Intranet hours
select SUM(amount) as IntranetHours
from time_sht
where
	CLIENT_ID = 363
	and PROJECT_NO = 9
	and WK_DATE between @dtFrom and @dtTo

union all
-- 4
-- Staff count >= 4 hours
select COUNT(*) as StaffCount
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
select count(*) as Owners
from rdiitem 
where client_id = 363 and project_no = 9 
	and statusid not in (2, 8, 10, 60)
	and AssignedTo in (select empid from tagowner where empid <> 77) 
	and not (assignedto = 77 and statusid not in (1, 5))
	and assignedto <> 10000

union all
-- 6
-- people who created intranet tickets last 2 weeks
select  count(*) as TicketsCreated
from rdiitem i
where i.ins_date between @dtFrom and @dtTo
	and i.client_id = 363
	and i.project_no = 9
	and i.itemtypeid in (1, 2, 3, 4, 5)

union all
select COUNT(*) as NewEmployees
from
	(
	select au.fullname2
	from EmployeePosition ep
		inner join allusers au on ep.empid = au.empid
		inner join time_sht t on t.empid = ep.empid
	where startdate >= dateadd(mm, -6, @dtTo)
		and not exists (select 1 from EmployeePosition x where x.empid = ep.empid and x.EmployeePositionID <> ep.EmployeePositionID)
		and t.client_id = 363 and t.project_no = 9
		and t.wk_date between dateadd(dd, -14, @dtTo) and @dtTo
	group by au.fullname2
	) a

-- 7
-- New staff < 6 months
select au.fullname2 as NewStaff, sum(t.amount)
from EmployeePosition ep
	inner join allusers au on ep.empid = au.empid
	inner join time_sht t on t.empid = ep.empid
where startdate >= dateadd(mm, -6, @dtTo)
	and not exists (select 1 from EmployeePosition x where x.empid = ep.empid and x.EmployeePositionID <> ep.EmployeePositionID)
	and t.client_id = 363 and t.project_no = 9
	and t.wk_date between dateadd(dd, -14, @dtTo) and @dtTo
group by au.fullname2
order by au.fullname2

-- 8
-- Total Hours
;with Intranet_cte as
(
	select
		cast(datepart(yy, t.wk_date) as varchar(4))
			+ '-'
			+ right('0' + cast(datepart(mm, t.wk_date) as varchar(2)), 2) as date, 
		sum(t.amount) as IntranetHours
	from time_sht t
	where t.client_id = 363 and t.project_no = 9
		and WK_DATE between @dtFromMonthStart and @dtTo
	group by datepart(yy, t.wk_date), datepart(mm, t.wk_date)
),
Total_cte as
(
	select
		cast(datepart(yy, t.wk_date) as varchar(4))
			+ '-'
			+ right('0' + cast(datepart(mm, t.wk_date) as varchar(2)), 2) as date, 
		sum(t.amount) as TotalHours
	from time_sht t
	where EMPID < 1000
		and WK_DATE between @dtFromMonthStart and @dtTo
	group by datepart(yy, t.wk_date), datepart(mm, t.wk_date)
)
select a.date, b.IntranetHours, a.TotalHours
from total_cte a
	left join Intranet_cte b
		on a.date = b.date

-- 9
-- people who billed time to the intranet last two weeks
select
    au.fullname2,
    cast(sum(t.amount) as numeric(18,2)) as HrsLast2Wks,
    ho.home_office + case when t.empid in (320, 198, 77) then ' (IG)' else '' end
from time_sht t 
	inner join allusers au on t.empid = au.empid
	left join vw_all_active_employee_info ho on t.empid = ho.empid
where t.client_id = 363 and t.project_no = 9
	and t.wk_date between dateadd(dd, -14, @dtTo) and @dtTo
group by au.fullname2, ho.home_office, t.empid
having sum(t.amount) >= 4
order by sum(t.amount) desc

-- declare @dtTo datetime = getdate()

select
	date as [Yr-Mo],
	Anchorage,
	Boise,
	Corporate,
	Fairbanks,
	Houston,
	Juneau,
	Minneapolis,
	Portland
from
(
	select
		a.LOCATION as Location,
		a.date,
		case
			when totalhours = 0
				then 0
			else
				convert(numeric(18, 4), isnull(IntranetHours, 0) / TotalHours * 100)
		end as Percentage
	from
		(
			select
				LOCATION,
				cast(datepart(yy, wk_date) as varchar(4))
					+ '-'
					+ right('0' + cast(datepart(mm, wk_date) as varchar(2)), 2) as date,
				SUM(a.amount) TotalHours
			from time_sht a
				inner join RDI_Employee b
					on a.EMPID = b.empid
			where WK_DATE between @dtFromMonthStart and @dtTo
			group by b.LOCATION, DATEPART(yy, a.wk_date), DATEPART(mm, a.wk_date)
		) a
		left join
			(
				select
					LOCATION,
					cast(datepart(yy, wk_date) as varchar(4))
						+ '-'
						+ right('0' + cast(datepart(mm, wk_date) as varchar(2)), 2) as date,
					SUM(a.amount) IntranetHours
				from time_sht a
					inner join RDI_Employee b
						on a.EMPID = b.empid
				where
					WK_DATE between @dtFromMonthStart and @dtTo
					and CLIENT_ID = 363
					and PROJECT_NO = 9
				group by b.LOCATION, DATEPART(yy, a.wk_date), DATEPART(mm, a.wk_date)
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
		Minneapolis,
		Portland
	)
) as p
order by date


select
	a.LOCATION as Location,
	case
		when totalhours = 0
			then 0
		else
			convert(numeric(18, 2), isnull(IntranetHours, 0) / TotalHours * 100)
	end as Percentage
from
	(
		select
			LOCATION,
			cast(datepart(yy, wk_date) as varchar(4))
				+ '-'
				+ right('0' + cast(datepart(mm, wk_date) as varchar(2)), 2) as date,
			SUM(a.amount) TotalHours
		from time_sht a
			inner join RDI_Employee b
				on a.EMPID = b.empid
		where WK_DATE between CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(getdate())-1),getdate()),101) and getdate()
		group by b.LOCATION, DATEPART(yy, a.wk_date), DATEPART(mm, a.wk_date)
	) a
	left join
		(
			select
				LOCATION,
				cast(datepart(yy, wk_date) as varchar(4))
					+ '-'
					+ right('0' + cast(datepart(mm, wk_date) as varchar(2)), 2) as date,
				SUM(a.amount) IntranetHours
			from time_sht a
				inner join RDI_Employee b
					on a.EMPID = b.empid
			where
				WK_DATE between CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(getdate())-1),getdate()),101) and getdate()
				and CLIENT_ID = 363
				and PROJECT_NO = 9
			group by b.LOCATION, DATEPART(yy, a.wk_date), DATEPART(mm, a.wk_date)
		) b
		on a.LOCATION = b.location and a.date = b.date
order by percentage desc