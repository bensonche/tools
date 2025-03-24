declare @roles table
(
	name varchar(max),
	level int
)

insert into @roles(name, level)
values
('RDI_Admin', 1),
('RDI_Branch_Manager', 2),
('RDI_Project_Manager', 3),
('RDI_Employee', 4)

;with multipleRDIRoles as
(
	select MemberName
	from RDISecurity.MemberRoles m
	inner join @roles r
		on m.RoleName = r.name
	group by MemberName
	having count(*) > 1
),
minLevel as
(
	select MemberName, min(level) minLevel
	from RDISecurity.MemberRoles m
	inner join @roles r
		on m.RoleName = r.name
	group by MemberName
)
select a.*, level, minlevel, formatmessage('alter role [%s] drop member [%s]', a.RoleName, a.MemberName)
from rdisecurity.memberroles a
inner join multipleRDIRoles b
	on a.MemberName = b.MemberName
inner join @roles r
	on a.RoleName = r.name
inner join minLevel ml
	on a.MemberName = ml.MemberName
where level > minlevel
order by a.MemberName, level

--exec RDISecurity.SynchronizeDatabaseRoleMembers