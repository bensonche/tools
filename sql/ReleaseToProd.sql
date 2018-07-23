use rdi_production;

with lastQA as
(
    select RDIItemId, max(changedate) date
    from RDIItemHistory
    where StatusId = 8
    group by RDIItemId
)
select
    a.RDIItemId id,
    FeatureBranch,
    case when b.sql_ct is null then '' else convert(varchar(2), b.sql_ct) end [sql count],
    case when d.sql_ct is null then '' else convert(varchar(2), d.sql_ct) end [all sql count],
    case when rtrim(ltrim(isnull(ChangedDescription, ''))) = '' then 'missing change description' else '' end as CDC,
    e.DeveloperName,
    e.developerid,
    REPLACE(REPLACE(a.title, CHAR(13), ' '), CHAR(10), ' ')
from RDIItem a
    left join (
        select a.rdiitemid, count(distinct a.itemfileid) sql_ct
        from ItemFile a
            left join DOC_METADATA c
                on a.itemfileid = c.itemfileid
            left join lastQA d
                on a.RDIItemId = d.RDIItemId
        where DOC_EXTENSION like '%sql'
            and (d.date is null or a.ins_date > d.date)
        group by a.rdiitemid ) b
    on a.RDIItemId = b.RDIItemId

    left join (
        select a.rdiitemid, count(distinct a.itemfileid) sql_ct
        from ItemFile a
            left join DOC_METADATA c
                on a.itemfileid = c.itemfileid
        where DOC_EXTENSION like '%sql'
        group by a.rdiitemid ) d
    on a.RDIItemId = d.RDIItemId

    cross apply RDI_GetPTReleaseInfo(a.rdiitemid) e
where
    a.CLIENT_ID = 363
    and a.PROJECT_NO = 9
    and StatusId = 48
    and AssignedTo = 10000
order by a.RDIItemId

---------------------------------------------------------------------------------

;with cte as
(
    select distinct
        'log ' + featurebranch as log
        ,'mprod ' + featurebranch as mprod
		,'markBranch ' + FeatureBranch + ' ' + cast(a.RDIItemId as varchar) as markBranch
		,'git checkout ' + FeatureBranch + ' && export SKIP_BUILD_BEFORE_PUSH=1 && git push -f && export SKIP_BUILD_BEFORE_PUSH=0' as pushAll
        ,dense_rank() over (order by a.featurebranch desc) seq
        ,dense_rank() over (order by a.featurebranch) reverseSeq
    from RDIItem a
    where
        a.CLIENT_ID = 363
        and a.PROJECT_NO = 9
        and StatusId = 48
        and AssignedTo = 10000
),
cte1 as
(
    select *, case when seq > 1 then ' &&' else '' end as suffix
    from cte
)
select
    log, suffix,
    'echo -e "\e[32m' + mprod + '\n' + cast(seq as varchar) + ' remaining\e[39m" && ' + mprod, suffix,
    'echo -e "\e[32m' + markBranch + '\n' + cast(seq as varchar) + ' remaining\e[39m" && ' + markBranch, suffix,
    'echo -e "\e[32m' + pushAll + '\n' + cast(seq as varchar) + ' remaining\e[39m" && ' + pushAll, suffix
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
        select a.RDIItemId, isnull(b.sqlcount, 0) as SQLCount, c.DeveloperId
        from RDIItem a
            left join (
                select count(distinct a.itemfileid) sqlcount, a.rdiitemid
                    from ItemFile a
                        left join DOC_METADATA c
                            on a.itemfileid = c.itemfileid
                        left join lastQA d
                            on a.RDIItemId = d.RDIItemId
                where DOC_EXTENSION like '%sql'
                    and (d.changeDate is null or a.ins_date > d.changeDate)
                group by a.rdiitemid 
                having count(*) > 0
            ) b
                on a.RDIItemId = b.RDIItemId
        cross apply dbo.RDI_GetPTReleaseInfo(a.rdiitemid) c
        where
            CLIENT_ID = 363
            and PROJECT_NO = 9
            and StatusId = 48
            and AssignedTo = 10000
        for xml path('Item'), root('PTItems')
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
            union all select 'https://www.resdat.com/privatedn/Employees/InOutBoard/inOutBoard.aspx'
            union all select 'https://www.resdat.com/privatedn/invoicing/invoicelist.aspx'
            union all select 'http://www.resdat.com/careers/apply'
        ) pages
        for xml path(''), root('QAPages')
    ) QAPages
)
select
    'var PTItems = "' + PTItems + '";'
    + 'var QAPages = "' + QAPages + '";'
    + 'var current = new Date(' +  @dateJs + ');' as JS
	--'git grx && /c/NuGet.exe restore Intranet.sln && /c/Program\ Files\ \(x86\)/MSBuild/14.0/Bin/MSBuild.exe Intranet.sln /p:Configuration=Release /p:AspNetConfiguration=Release /p:RunCodeAnalysis=false' as buildCmd,
	--'git grx && /c/NuGet.exe restore RDIPublicSite.sln && /c/Program\ Files\ \(x86\)/MSBuild/14.0/Bin/MSBuild.exe RDIPublicSite.sln /p:Configuration=Release /p:AspNetConfiguration=Release /p:RunCodeAnalysis=false' as publicBuildCmd
from result