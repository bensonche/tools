use rdi_production

set nocount on

declare
	@newline char(1) = char(13),
	@newLineTab char(2) =  char(13) + char(9)

;with lastQA as
(
	select RDIItemId, max(changedate) date
	from RDIItemHistory
	where StatusId = 8
	group by RDIItemId
)
select
	a.RDIItemId id,
	FeatureBranch,
	case when rtrim(ltrim(isnull(ChangedDescription, ''))) = '' then 'missing change description' else '' end as CDC,
	e.DeveloperName,
	e.developerid,
	REPLACE(REPLACE(a.title, CHAR(13), ' '), CHAR(10), ' ')
from RDIItem a
cross apply RDI_GetPTReleaseInfo(a.rdiitemid) e
where
	a.CLIENT_ID = 363
	and a.PROJECT_NO = 9
	and StatusId = 48
	and AssignedTo = 10000
order by a.RDIItemId

---------------------------------------------------------------------------------
declare @json varchar(max)

;with cte as
(
	select distinct
		featurebranch
		,'="log " & INDIRECT(ADDRESS(ROW(), 1))' as log
		,'"mprod " & INDIRECT(ADDRESS(ROW(), 1))' as mprod
		,'"markBranch " & INDIRECT(ADDRESS(ROW(), 1)) & " ' + cast(a.RDIItemId as varchar) + '"' as markBranch
		,'"git checkout " & INDIRECT(ADDRESS(ROW(), 1)) & " && export SKIP_BUILD_BEFORE_PUSH=1 && git push -f && unset SKIP_BUILD_BEFORE_PUSH"' as pushAll
		,'"echo -e ""git checkout " & INDIRECT(ADDRESS(ROW(), 1)) & " && git reset --hard $(git rev-parse origin/" & INDIRECT(ADDRESS(ROW(), 1)) & ") &&"" >> resetMark.sh"' as resetMark
		,'"git push origin :" & INDIRECT(ADDRESS(ROW(), 1))' as deleteBranch
		,dense_rank() over (order by a.featurebranch desc, rdiitemid desc) seq
		,dense_rank() over (order by a.featurebranch, rdiitemid) reverseSeq
	from RDIItem a
	where
		a.CLIENT_ID = 363
		and a.PROJECT_NO = 9
		and StatusId = 48
		and AssignedTo = 10000
),
cte1 as
(
	select *, case when seq > 1 then ' && ' else ';' end as suffix
	from cte
)
select
	featurebranch as 'FeatureBranch---------------------------------',
	log as 'log---------------------------------', suffix,
	'="echo -e ""\e[32m" & ' + mprod + ' & "\n' + cast(seq as varchar) + ' remaining\e[39m"" && " & ' + mprod as ' & "mprod---------------------------------"', suffix,
	'="echo -e ""\e[32m" & ' + markBranch + ' & "\n' + cast(seq as varchar) + ' remaining\e[39m"" && " & ' + markBranch as ' & "markBranch---------------------------------"', suffix,
	'="echo -e ""\e[32m" & ' + pushAll + ' & "\n' + cast(seq as varchar) + ' remaining\e[39m"" && " & ' + pushAll as ' & "pushAll---------------------------------"', suffix,
	'="echo -e ""\e[32m" & INDIRECT(ADDRESS(ROW(), 1)) & "\n' + cast(seq as varchar) + ' remaining\e[39m"" && " & ' + resetMark as ' & "resetMark---------------------------------"', suffix,
	'="echo -e ""\e[32m" & ' + deleteBranch + ' & "\n' + cast(seq as varchar) + ' remaining\e[39m"" && " & ' + deleteBranch as ' & "deleteBranch---------------------------------"', ';'
from cte1
order by reverseSeq

---------------------------------------------------------

declare @dateJs varchar(100) =
	cast(datepart(yyyy, getdate()) as varchar)
	+ ', ' + cast(datepart(m, getdate()) - 1 as varchar)
	+ ', ' + cast(datepart(d, getdate()) as varchar)
	+ ', ' + cast(datepart(hh, getdate()) as varchar)
	+ ', ' + cast(datepart(mi, getdate()) as varchar)

;with lastQA as
(
	select rdiitemid, max(ChangeDate) changeDate
	from RDIItemHistory
	where StatusId = 8
	group by RDIItemId
),
result as
(
	select 
	(
		select a.RDIItemId, c.DeveloperId
		from RDIItem a
		cross apply dbo.RDI_GetPTReleaseInfo(a.rdiitemid) c
		where
			CLIENT_ID = 363
			and PROJECT_NO = 9
			and StatusId = 48
			and AssignedTo = 10000
		for json path
	) PTItems,
	(
		select *
		from
		(
			select 'https://www.resdat.com/privatedn/AccountsPayable/AccountsPayableHome.aspx' Page
			union all select 'https://www.resdat.com/privatedn/BranchReports/BranchReport_Main.aspx'
			union all select 'https://www.resdat.com/privatedn/Clients/ClientInfoSystem/ClientManagement.aspx'
			union all select 'https://www.resdat.com/privatedn/Projects/Reports/ProjectCostReport.aspx?reporttype=detail'
			union all select 'https://www.resdat.com/privatedn/Projects/Reports/ProjectCostReport.aspx?reporttype=summary'
			union all select 'https://www.resdat.com/privatedn/Invoicing/DepositHome.aspx'
			union all select 'https://www.resdat.com/privatedn/Invoicing/Deposit.aspx'
			union all select 'https://www.resdat.com/privatedn/Payroll/Run_Payroll.aspx'
			union all select 'https://www.resdat.com/privatedn/Employees/Phone/PhoneList.aspx'
			union all select 'https://www.resdat.com/privatedn/ClientProjectPortal/Default.aspx'
			union all select 'https://www.resdat.com/privatedn/ClientProjectPortal/ProjectMain.aspx?ClientID=117&ProjectNo=4'
			union all select 'https://www.resdat.com/privatedn/Invoicing/DepositSearch.aspx'
			union all select 'https://www.resdat.com/privatedn/Employees/SheetUpdate/EmployeeSheet.aspx?EmpId=320'
			union all select 'https://www.resdat.com/privatedn/Timesheet'
			union all select 'https://www.resdat.com/privatedn/ProjectTrack/default.aspx'
			union all select 'https://www.resdat.com/privatedn/ProjectTrack/IssueGrid.aspx?IssueID=65348'
			union all select 'https://www.resdat.com/privatedn/Employees/EmployeeTrack/EmployeeTrack.aspx'
			union all select 'https://www.resdat.com/privatedn/invoicing/invoicelist.aspx'
			union all select 'https://intranet.resourcedata.com/Standards/UserInterfaceStandards'
		) pages
		for json auto
	) QAPages
)
select @json =
	'var PTItems = ' + PTItems + ';'
	+ 'var QAPages = ' + QAPages + ';'
	+ 'var current = new Date(' +  @dateJs + ');'
	--'git grx && /c/NuGet.exe restore Intranet.sln && /c/Program\ Files\ \(x86\)/MSBuild/14.0/Bin/MSBuild.exe Intranet.sln /p:Configuration=Release /p:AspNetConfiguration=Release /p:RunCodeAnalysis=false' as buildCmd,
	--'git grx && /c/NuGet.exe restore RDIPublicSite.sln && /c/Program\ Files\ \(x86\)/MSBuild/14.0/Bin/MSBuild.exe RDIPublicSite.sln /p:Configuration=Release /p:AspNetConfiguration=Release /p:RunCodeAnalysis=false' as publicBuildCmd
from result

--set @json = replace(@json, '[', '[' + @newline)
set @json = replace(@json, '{', @newline + '{' + @newLineTab)
set @json = replace(@json, '}', @newline + '}')
set @json = replace(@json, ';', ';' + @newline + @newline)

print @json

select @json