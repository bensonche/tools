declare
	@empid int = 908,
	@fname varchar(max) = 'Jennifer',
	@lname varchar(max) = 'Lober',
	@username varchar(max) = 'jlober'

begin tran

insert into entity(entityid, EntitySourceTypeId)
values
(@empid, 1)

insert into employee(empid, lname, fname, username, email, auth_email, EmployeeTypeId)
values
(@empid, @lname, @fname, 'RESDAT\' + @username, @username + '@resourcedata.com', @username + '@resdat.com', 1)

insert into EMPLOYEE_FINANCIALS(empid, MSTATUS, WC_CODE, AREACODE, HIRE_DATE)
values
(@empid, '?', '8803', 98, cast(datepart(month, getdate()) as varchar) + cast('/1/' as varchar) + cast(datepart(year, getdate()) as varchar))

insert into EmployeePosition(empid, JobTitleId, salary, EmpType, StartDate, HomeOfficeCode)
values
(@empid, 100, 50000, 'S', cast(datepart(month, getdate()) as varchar) + cast('/1/' as varchar) + cast(datepart(year, getdate()) as varchar), 4)

/*

rollback

commit

*/