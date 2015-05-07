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
    case when rtrim(ltrim(isnull(ChangedDescription, ''))) = '' then 'missing change description' else '' end as ChangedDescriptionCheck,
    e.DeveloperName,
    e.developerid,
    REPLACE(REPLACE(a.title, CHAR(13), ' '), CHAR(10), ' ')
from RDIItem a
    left join (
        select a.rdiitemid, count(*) sql_ct
        from ItemFile a
            left join DOC_METADATA c
                on a.itemfileid = c.itemfileid
            left join lastQA d
                on a.RDIItemId = d.RDIItemId
        where DOC_EXTENSION = '.sql'
            and (d.date is null or a.ins_date > d.date)
        group by a.rdiitemid ) b
    on a.RDIItemId = b.RDIItemId

    left join (
        select a.rdiitemid, count(*) sql_ct
        from ItemFile a
            left join DOC_METADATA c
                on a.itemfileid = c.itemfileid
        where DOC_EXTENSION = '.sql'
        group by a.rdiitemid ) d
    on a.RDIItemId = d.RDIItemId

    cross apply RDI_GetPTReleaseInfo(a.rdiitemid) e
where
    a.CLIENT_ID = 363
    and a.PROJECT_NO = 9
    and StatusId = 48
    and AssignedTo = 10000
order by a.RDIItemId

;with cte as
(
    select
        'log ' + featurebranch as log
        ,'mprod ' + featurebranch as mprod
        ,ROW_NUMBER() over (order by a.featurebranch desc) seq
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
    log + suffix,
    mprod + suffix
from cte1
order by log

---------------------------------------------
declare @PTLink varchar(500)
set @PTLink = '<a href=''https://www.resdat.com/privatedn/ProjectTrack/IssueGrid.aspx?IssueID=';

with lastQA as
(
    select rdiitemid, max(ChangeDate) changeDate
    from RDIItemHistory
    where StatusId = 8
    group by RDIItemId
),
result as
(
    select url, a.rdiitemid
    from
    (
        select @PTlink + convert(varchar(10), a.RDIItemId) + '''>' + convert(varchar(10), a.RDIItemId) + isnull(b.url, '') + '</a><br />' url, a.RDIItemId
        from RDIItem a
            left join (
                select a.rdiitemid, ' - ' + convert(varchar, count(*)) as url
                    from ItemFile a
                        left join DOC_METADATA c
                            on a.itemfileid = c.itemfileid
                        left join lastQA d
                            on a.RDIItemId = d.RDIItemId
                where DOC_EXTENSION = '.sql'
                    and (d.changeDate is null or a.ins_date > d.changeDate)
                group by a.rdiitemid 
                having count(*) > 0
            ) b
                on a.RDIItemId = b.RDIItemId
        where
            CLIENT_ID = 363
            and PROJECT_NO = 9
            and StatusId = 48
            and AssignedTo = 10000
    ) a

    union all

    select '<br /><br /><br /><br /><br />', 88888

    union all

    select @PTLink + convert(varchar, a.RDIItemId) + '&bcempid=' + convert(varchar, b.developerid) + '''>' + convert(varchar(10), a.RDIItemId) + '</a><br />', 99997
    from rdiitem a
    cross apply dbo.RDI_GetPTReleaseInfo(a.rdiitemid) b
    where AssignedTo = 10000
    and StatusId = 48
    and client_id = 363
    and PROJECT_NO = 9

    union all

    select '<br /><br /><br /><br /><br />', 99998

    union all

    select '<a href="https://www.resdat.com/privatedn/AccountsPayable/AccountsPayableHome.aspx">https://www.resdat.com/privatedn/AccountsPayable/AccountsPayableHome.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/BranchReports/BranchReport_Main.aspx">https://www.resdat.com/privatedn/BranchReports/BranchReport_Main.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Clients/ClientInfoSystem/ClientManagement.aspx">https://www.resdat.com/privatedn/Clients/ClientInfoSystem/ClientManagement.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Projects/Reports/ProjectCostReport.aspx?reporttype=detail">https://www.resdat.com/privatedn/Projects/Reports/ProjectCostReport.aspx?reporttype=detail</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Projects/Reports/ProjectCostReport.aspx?reporttype=summary">https://www.resdat.com/privatedn/Projects/Reports/ProjectCostReport.aspx?reporttype=summary</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Invoicing/DepositHome.aspx">https://www.resdat.com/privatedn/Invoicing/DepositHome.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Invoicing/Deposit.aspx">https://www.resdat.com/privatedn/Invoicing/Deposit.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Payroll/Run_Payroll.aspx">https://www.resdat.com/privatedn/Payroll/Run_Payroll.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Employees/Phone/PhoneList.aspx">https://www.resdat.com/privatedn/Employees/Phone/PhoneList.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/ClientProjectPortal/Default.aspx">https://www.resdat.com/privatedn/ClientProjectPortal/Default.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/ClientProjectPortal/ProjectMain.aspx?ClientID=117&ProjectNo=4">https://www.resdat.com/privatedn/ClientProjectPortal/ProjectMain.aspx?ClientID=117&ProjectNo=4</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Invoicing/DepositSearch.aspx">https://www.resdat.com/privatedn/Invoicing/DepositSearch.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Employees/SheetUpdate/EmployeeSheet.aspx?EmpId=320">https://www.resdat.com/privatedn/Employees/SheetUpdate/EmployeeSheet.aspx?EmpId=320</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Timesheet">https://www.resdat.com/privatedn/Timesheet</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/ProjectTrack/default.aspx">https://www.resdat.com/privatedn/ProjectTrack/default.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/ProjectTrack/IssueGrid.aspx?IssueID=65348">https://www.resdat.com/privatedn/ProjectTrack/IssueGrid.aspx?IssueID=65348</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Employees/EmployeeTrack/EmployeeTrack.aspx">https://www.resdat.com/privatedn/Employees/EmployeeTrack/EmployeeTrack.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/Employees/InOutBoard/inOutBoard.aspx">https://www.resdat.com/privatedn/Employees/InOutBoard/inOutBoard.aspx</a>', 99999
    union all select '<br/><a href="https://www.resdat.com/privatedn/invoicing/invoicelist.aspx">https://www.resdat.com/privatedn/invoicing/invoicelist.aspx</a>', 99999
    union all select '<br/><a href="http://www.resdat.com/careers/apply">http://www.resdat.com/careers/apply</a>', 99999
)
select url
from result
order by rdiitemid