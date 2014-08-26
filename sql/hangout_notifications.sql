set nocount on

begin try
	begin tran

	declare @join1 varchar(500)
	declare @join2 varchar(500)
	declare @startdate datetime
	declare @enddate datetime

	set @startdate = DATEADD(d, 1, dateadd(dd, 0, datediff(dd, 0, getdate())))
	
	set @join1 = 'Intranet Hangout on join.me https://join.me/RDIHangout at '
	set @join2 = 'Intranet Hangout on join.me https://join.me/RDIHangout at '

	declare @title varchar(1000)
	declare @id int

	set @enddate = @startdate
	set @title =  @join1 + '10AM AT'
	exec Notification_Insert @title, 'https://join.me/RDIHangout', @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 0
	exec Notification_LocationInsert @id, 1
	exec Notification_LocationInsert @id, 2
	exec Notification_LocationInsert @id, 4
	set @title =  @join1 + '11AM PT'
	exec Notification_Insert @title, 'https://join.me/RDIHangout', @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 6
	set @title =  @join1 + '12PM MT'
	exec Notification_Insert @title, 'https://join.me/RDIHangout', @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 3
	set @title =  @join1 + '1PM CT'
	exec Notification_Insert @title, 'https://join.me/RDIHangout', @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 5
	exec Notification_LocationInsert @id, 7
	------------------------------------------------------
	set @startdate = DATEADD(d, 2, @startdate)
	set @enddate = @startdate
	set @title =  @join1 + '11AM AT'
	exec Notification_Insert @title, 'https://join.me/RDIHangout', @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 0
	exec Notification_LocationInsert @id, 1
	exec Notification_LocationInsert @id, 2
	exec Notification_LocationInsert @id, 4
	set @title =  @join1 + '12PM PT'
	exec Notification_Insert @title, 'https://join.me/RDIHangout', @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 6
	set @title =  @join1 + '1PM MT'
	exec Notification_Insert @title, 'https://join.me/RDIHangout', @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 3
	set @title =  @join1 + '2PM CT'
	exec Notification_Insert @title, 'https://join.me/RDIHangout', @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 5
	exec Notification_LocationInsert @id, 7
	
	commit
end try
begin catch
	rollback
end catch