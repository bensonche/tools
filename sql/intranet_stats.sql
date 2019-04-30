-- Change these flags if you want to run only portions of the query
declare
	@BeingWorkedNoEstimate bit = 1,
	@BeingWorkedButStalled bit = 1,
	@IntTestingButStalled bit = 1,
	@EstimateExceeded bit = 1,
	@StaffOnIntranetNotScheduled bit = 1,
	@TotalHoursWorkedOnIntranet bit = 1

drop table if exists #PTs

if @BeingWorkedNoEstimate = 1
	or @BeingWorkedButStalled = 1
	or @IntTestingButStalled = 1
	or @EstimateExceeded = 1
with TagOwnersCte as
(
	select o.RDIItemId, string_agg(o.fullname2, ', ') within group (order by o.fullname2) as Owner
	from (
		select distinct ri.RDIItemId, au.fullname2
		from RDIItem ri
		inner join RDIItemTag rit
			on ri.RDIItemId = rit.RDIItemId
		inner join TagOwner tgo
			on rit.TagId = tgo.TagId
		inner join allusers au
			on tgo.EmpId = au.USERID
	) o
	group by o.RDIItemId
), ActivePTs as
(
	select distinct
		ri.rdiitemid,
		ri.Title,
		ri.AssignedTo,
		ri.HoursEstimated,
		its.ItemStatus,
		au.fullname2 as AssignedToName,
		e.LOCATION as AssignedToBranch,
		toc.Owner as TagOwner
	from rdiitem ri
	inner join ItemStatus its
		on ri.StatusId = its.ItemStatusId
	inner join Allusers au
		on ri.assignedTo = au.userid
	left join RDI_Employee e
		on ri.AssignedTo = e.EMPID
	left join TagOwnersCte toc
		on ri.RDIItemId = toc.RDIItemId
	where
		ri.client_id = 363
		and ri.project_no = 9
		and statusid in (1, 5, 6, 7, 46, 47)

	EXCEPT

	-- Remove those assigned to owners and IG
	select distinct
		ri.rdiitemid,
		ri.Title,
		ri.AssignedTo,
		ri.HoursEstimated,
		its.ItemStatus,
		au.fullname2 as AssignedToName,
		e.LOCATION as AssignedToBranch,
		toc.Owner as TagOwner
	from rdiitem ri
	inner join ItemStatus its
		on ri.StatusId = its.ItemStatusId
	inner join Allusers au
		on ri.assignedTo = au.userid
	left join RDI_Employee e
		on ri.AssignedTo = e.EMPID
		left join RDIItemTag rit
			on ri.RDIItemId = rit.RDIItemId
		left join TagOwner tgo
			on rit.TagId = tgo.TagId
	left join TagOwnersCte toc
		on ri.RDIItemId = toc.RDIItemId
	where
		au.type = 'Group'
		or AssignedTo = tgo.EmpId
),PTReassignments as
(
		select
			ap.RDIItemId,
			ap.AssignedTo as CurrentAssignedTo,
			rih.AssignedTo as HistoricAssignedTo,
			lag(rih.AssignedTo)
			over (
			partition by ap.RDIItemId
				order by ChangeDate) as lastAssignedTo,
			rih.ChangeDate
		from ActivePTs ap
			inner join RDIItemHistory rih
				on ap.RDIItemId = rih.RDIItemId
), lastAssignedTo as
(
		select
			RDIItemId,
			min(ChangeDate) as lastAssignmentDate
		from PTReassignments
		where HistoricAssignedTo <> isnull(lastAssignedTo, -1)
				and CurrentAssignedTo = HistoricAssignedTo
		group by RDIItemId
), lastWorkedOnByEmployee as
(
		select
			ap.RDIItemId,
			max(WK_DATE) as lastWorkedDate
		from ActivePTs ap
			inner join TIME_SHT ts
				on ap.RDIItemId = ts.RDIItemId
					and ap.AssignedTo = ts.EMPID
		group by ap.RDIItemId
), lastWorkedOnByAnyone as
(
		select
			ap.RDIItemId,
			max(WK_DATE) as lastWorkedDate
		from ActivePTs ap
			inner join TIME_SHT ts
				on ap.RDIItemId = ts.RDIItemId
		group by ap.RDIItemId
), lastCommentByEmployee as
(
		select
			rih.RDIItemId,
			lastCommentDate,
			rih.Comments,
			au.FULLNAME2 as LastCommentBy
		from (
					 select
						 ap.RDIItemId,
						 max(rih.ChangeDate) as lastCommentDate
					 from ActivePTs ap
						 inner join RDIItemHistory rih
							 on ap.RDIItemId = rih.RDIItemId
					 where rih.UpdatedBy = ap.AssignedTo
							 and ltrim(rtrim(isnull(Comments, ''))) <> ''
					 group by ap.RDIItemId
				 ) lastComment
			inner join RDIItemHistory rih
				on lastComment.RDIItemId = rih.RDIItemId
					and lastComment.lastCommentDate = rih.ChangeDate
			left join AllUsers au
				on rih.UpdatedBy = au.USERID
				where ltrim(rtrim(isnull(Comments, ''))) <> ''
), lastCommentByAnyone as
(
		select
			rih.RDIItemId,
			lastCommentDate,
			rih.Comments,
			au.FULLNAME2 as LastCommentBy
		from (
					 select
						 ap.RDIItemId,
						 max(rih.ChangeDate) as lastCommentDate
					 from ActivePTs ap
						 inner join RDIItemHistory rih
							 on ap.RDIItemId = rih.RDIItemId
					 where ltrim(rtrim(isnull(Comments, ''))) <> ''
					 group by ap.RDIItemId
				 ) lastComment
			inner join RDIItemHistory rih
				on lastComment.RDIItemId = rih.RDIItemId
					and lastComment.lastCommentDate = rih.ChangeDate
			left join AllUsers au
				on rih.UpdatedBy = au.USERID
		where ltrim(rtrim(isnull(Comments, ''))) <> ''
)
select ap.RDIItemId, ap.title, ap.AssignedTo, ap.AssignedToName, ap.AssignedToBranch, ap.HoursEstimated,
 ap.ItemStatus, lat.lastAssignmentDate, lwo.lastWorkedDate as LastWorkedOnByEmployee,
 lwoa.lastWorkedDate as LastWorkdOnByAnyone, lce.lastCommentDate as lastCommentDateByEmployee, lce.Comments as CommentByEmployee, 
 lca.lastCommentDate as  lastCommentDateByAnyone,lca.Comments as CommentByAnyone, lca.LastCommentBy, ap.TagOwner
into #PTs
from ActivePTs ap
	left join lastAssignedTo lat
		on ap.RDIItemId = lat.RDIItemId
	left join lastWorkedOnByEmployee lwo
		on ap.RDIItemId = lwo.RDIItemId
		left join lastWorkedOnByAnyone lwoa
		on ap.RDIItemId = lwoa.RDIItemId
	left join lastCommentByEmployee lce
		on ap.RDIItemId = lce.RDIItemId
	left join lastCommentByAnyone lca
		on lca.RDIItemId = lce.RDIItemId

-------------------------------------------------------------------------------------------------------------------
-- 1: Being worked, no estimate
if @BeingWorkedNoEstimate = 1
with ActiveNoEstimatePTs as
(
	select pt.rdiitemid, pt.title, pt.AssignedToName, pt.AssignedToBranch, pt.ItemStatus, pt.AssignedTo
	from #PTs pt
		inner join TIME_SHT ts
			on pt.RDIItemId = ts.RDIItemId
				and ts.EMPID = pt.AssignedTo
	where isnull(pt.HoursEstimated, 0) = 0
), result as
(
	select
		c.AssignedToName as AssignedTo,
		c.AssignedToBranch as EmployeeBranch,
		c.RDIItemId,
		c.Title,
		c.ItemStatus,
		min(ts.WK_DATE) as FirstWorkedDate,
		2 as seq
	from ActiveNoEstimatePTs c
		inner join TIME_SHT as ts
			on c.RDIItemId = ts.RDIItemId
				and c.AssignedTo = ts.EMPID
	group by c.AssignedToName, c.AssignedToBranch, c.RDIItemId, c.title, c.ItemStatus


	union all

	select
		null,
		null,
		null,
		'Being worked, no estimate',
		null,
		null,
		1 as seq
)
select
	AssignedTo,
	EmployeeBranch,
	RDIItemId,
	Title,
	ItemStatus,
	FirstWorkedDate
from result
order by seq, EmployeeBranch, AssignedTo, RDIItemId

-- 2: Being worked, but stalled
if @BeingWorkedButStalled = 1
with result as
(
	select
		apt.AssignedToName as AssignedTo,
		apt.AssignedToBranch as EmployeeBranch,
		apt.RDIItemId,
		apt.Title,
		apt.ItemStatus,
		apt.lastAssignmentDate as AssignedToDate,
		apt.LastWorkedOnByEmployee as LastWorkedDate,
		datediff(d, apt.LastWorkedOnByEmployee, getdate()) as DaysSinceLastWork,
		apt.lastCommentDateByEmployee as LastCommentDate,
		datediff(d, apt.lastCommentDateByEmployee, getdate()) as DaysSinceLastComment,
		apt.CommentByEmployee as LastComment,
		datediff(d, isnull(apt.LastWorkedOnByEmployee, apt.lastAssignmentDate), isnull(apt.lastCommentDateByEmployee, apt.lastAssignmentDate)) as diff,
		2 as seq
	from #PTs apt
	where apt.ItemStatus <> 'Testing'
	and apt.lastAssignmentDate < dateadd(wk, -2, getdate())
	and isnull(apt.LastWorkedOnByEmployee, '1/1/1970') < dateadd(wk, -2, getdate())
	and isnull(apt.lastCommentDateByEmployee, '1/1/1970') < dateadd(wk, -2, getdate())

	union all

	select
		null,
		null,
		null,
		'Being worked, but stalled',
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		1 as seq
)
select
	AssignedTo,
	EmployeeBranch,
	RDIItemId,
	Title,
	ItemStatus,
	AssignedToDate,
	LastWorkedDate,
	DaysSinceLastWork,
	LastCommentDate as LastCommentByAssignedToEmployee,
	DaysSinceLastComment,
	LastComment as LastCommentByAssignedToEmployee,
	abs(diff) as DaysBetweenLastWorkedAndCommented
from result
order by seq, EmployeeBranch, AssignedTo, RDIItemId

-- 3: In testing, but stalled
if @IntTestingButStalled = 1
with ActivePTs as
(
	select *
	from #PTs
	where ItemStatus = 'Testing'
), result as
(
	select
		c.AssignedToName as AssignedTo,
		c.AssignedToBranch as EmployeeBranch,
		c.RDIItemId,
		c.Title,
		c.ItemStatus,
		c.lastAssignmentDate as AssignedToDate,
		c.LastWorkdOnByAnyone,
		datediff(d, c.LastWorkdOnByAnyone, getdate()) as DaysSinceLastWork,
		c.lastCommentDateByAnyone as LastCommentDate,
		datediff(d, c.lastCommentDateByAnyone, getdate()) as DaysSinceLastComment,
		c.CommentByAnyone as LastComment,
		c.LastCommentBy as LastCommentBy,
		datediff(d, isnull(c.LastWorkdOnByAnyone, c.lastAssignmentDate), isnull(c.lastCommentDateByAnyone, c.lastAssignmentDate)) as diff,
		2 as seq
	from ActivePTs c
	where c.lastAssignmentDate < dateadd(wk, -2, getdate())
	and isnull(c.LastWorkdOnByAnyone, '1/1/1970') < dateadd(wk, -2, getdate())
	and isnull(c.lastCommentDateByAnyone, '1/1/1970')  < dateadd(wk, -2, getdate())

	union all

	select
		null,
		null,
		null,
		'In testing, but stalled',
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		1 as seq
)
select
	AssignedTo,
	EmployeeBranch,
	RDIItemId,
	Title,
	ItemStatus,
	AssignedToDate,
	LastWorkdOnByAnyone as LastWorkedDateByAnyone,
	DaysSinceLastWork,
	LastCommentDate,
	DaysSinceLastComment,
	LastComment,
	LastCommentBy,
	abs(diff) as DaysBetweenLastWorkedAndCommented
from result
order by seq, EmployeeBranch, AssignedTo, RDIItemId


-- 4: Estimate exceeded
if @EstimateExceeded = 1
with HasEstimate as
(
	select *
	from #PTs
	where isnull(hoursEstimated, 0) > 0
), hoursWorkedByEmployee as
(
		select
			he.RDIItemId,
			sum(ts.AMOUNT) as HoursWorkedByEmployee,
			max(WK_DATE) as LastWorkedDate
		from HasEstimate he
			inner join TIME_SHT ts
				on he.RDIItemId = ts.RDIItemId
					and he.AssignedTo = ts.EMPID
		group by he.RDIItemId
), hoursWorkedTotal as
(
		select
			he.RDIItemId,
			sum(ts.AMOUNT) as HoursWorked
		from HasEstimate he
			inner join TIME_SHT ts
				on he.RDIItemId = ts.RDIItemId
		group by he.RDIItemId
), result as
(
	select
		isnull(e.NickName, e.FNAME) + ' ' + e.LNAME as AssignedTo,
		e.LOCATION as EmployeeBranch,
		ri.RDIItemId,
		ri.Title,
		s.ItemStatus,
		ri.HoursEstimated,
		hwt.HoursWorked as HoursWorkedTotal,
		hwe.HoursWorkedByEmployee as HoursWorkedByEmployee,
		hwe.LastWorkedDate as LastWorkedDateByEmployee,
		2 as seq
	from HasEstimate c
		inner join RDIItem ri
			on c.RDIItemId = ri.RDIItemId
		inner join RDI_Employee e
			on ri.AssignedTo = e.EMPID
		inner join ItemStatus s
			on ri.StatusId = s.ItemStatusId
		left join hoursWorkedTotal hwt
			on ri.RDIItemId = hwt.RDIItemId
		left join hoursWorkedByEmployee hwe
			on ri.RDIItemId = hwe.RDIItemId
	where ri.HoursEstimated < hwt.HoursWorked

	union all

	select
		null,
		null,
		null,
		'Estimate exceeded',
		null,
		null,
		null,
		null,
		null,
		1 as seq
)
select
	AssignedTo,
	EmployeeBranch,
	RDIItemId,
	Title,
	ItemStatus,
	HoursEstimated,
	HoursWorkedTotal,
	HoursWorkedByEmployee,
	LastWorkedDateByEmployee
from result
order by seq, EmployeeBranch, AssignedTo, RDIItemId

-- 5: Staff on Intranet, not scheduled
if @StaffOnIntranetNotScheduled = 1
with dates as
(
		select
			cast(dateadd(day, -datepart(weekday, getdate()) + 1 - 7, getdate()) as date) as ThisSunday,
			cast(dateadd(day, -datepart(weekday, getdate()) + 1 - 14, getdate()) as date) as LastSunday
), EmployeesNotInWLM as
(
		select wa.EmployeeID
		from WorkAssignment wa
			inner join WorkAssignmentHours wah
				on wa.WorkAssignmentID = wah.WorkAssignmentID
			inner join WorkItem wi
				on wa.WorkItemID = wi.WorkItemID
			inner join dates d1
				on wah.Week = d1.ThisSunday
					or wah.Week = d1.LastSunday
		where wi.ClientID = 363
				and wi.ProjectID = 9
), OnIntranetLastWeek as (
		select
			ts.EMPID,
			sum(ts.AMOUNT) as amountLastWeek
		from time_sht ts
			inner join dates d
				on ts.WK_DATE between LastSunday and ThisSunday
		where CLIENT_ID = 363
				and PROJECT_NO = 9
				and ts.EMPID not in (
			select EmployeeID
			from EmployeesNotInWLM
		)
		group by ts.empid
), OnIntranetThisWeek as (
		select
			ts.EMPID,
			sum(ts.AMOUNT) as amountThisWeek
		from time_sht ts
			inner join dates d
				on ts.WK_DATE between ThisSunday and getdate()
		where CLIENT_ID = 363
				and PROJECT_NO = 9
				and ts.EMPID not in (
			select EmployeeID
			from EmployeesNotInWLM
		)
		group by ts.empid
), results as
(
	select
		isnull(e.NickName, e.FNAME) + ' ' + e.LNAME as AssignedTo,
		e.LOCATION as EmployeeBranch,
		lw.amountLastWeek as HoursWorkedLastWeek,
		tw.amountThisWeek as HoursWorkedThisWeek,
		2 as seq
	from RDI_Employee e
		left join OnIntranetLastWeek lw
			on e.empid = lw.EMPID
		left join OnIntranetThisWeek tw
			on e.empid = tw.EMPID
	where lw.amountLastWeek is not null or tw.amountThisWeek is not null

	union all

	select
		'Staff on Intranet, not scheduled',
		null,
		null,
		null,
		1 as seq
)
select
	AssignedTo,
	EmployeeBranch,
	HoursWorkedLastWeek,
	HoursWorkedThisWeek
from results
order by seq, EmployeeBranch, AssignedTo

-- 6: Total Hours worked on Intranet
if @TotalHoursWorkedOnIntranet = 1
with dates as
(
	select cast(dateadd(day, -datepart(weekday, getdate()) + 1 - 7, getdate()) as date) as sunday
	union all
	select cast(dateadd(day, -datepart(weekday, getdate()) + 1 - 14, getdate()) as date)
)
select
	'Total Hours worked on Intranet',
	null
	
union all

select cast(d.sunday as varchar) + ' to ' + cast(dateadd(day, 6, d.sunday) as varchar) as week, sum(amount) as total
from time_sht ts
inner join dates d
	on ts.WK_DATE between d.sunday and dateadd(day, 6, sunday)
where
	ts.client_id = 363
	and ts.project_no = 9
group by d.sunday
