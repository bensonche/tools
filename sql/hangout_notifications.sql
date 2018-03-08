set nocount on

begin try
	begin tran

	declare @startdate datetime
	declare @enddate datetime

	set @startdate = DATEADD(d, 1, dateadd(dd, 0, datediff(dd, 0, getdate())))

    declare @link1 varchar(max) = 'https://resdat.zoom.us/j/2173845937'
    declare @link2 varchar(max) = 'https://resdat.zoom.us/j/2173845937'
    declare @link3 varchar(max) = 'https://zoom.us/j/818722140'
	
	declare @join1 varchar(max) = 'Intranet Hangout on Zoom ' + @link1 + ' at '
	declare @join2 varchar(max) = 'Intranet Hangout on Zoom ' + @link2 + ' at '
	declare @join3 varchar(max) = 'Intranet Orientation on Zoom ' + @link3 + ' at '

	declare @title varchar(1000)
	declare @id int

	set @enddate = @startdate
	set @title =  @join1 + '10AM AT'
	exec Notification_Insert @title, @link1, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 0
	exec Notification_LocationInsert @id, 1
	exec Notification_LocationInsert @id, 2
	exec Notification_LocationInsert @id, 4
	set @title =  @join1 + '11AM PT'
	exec Notification_Insert @title, @link1, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 6
	set @title =  @join1 + '12PM MT'
	exec Notification_Insert @title, @link1, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 3
	set @title =  @join1 + '1PM CT'
	exec Notification_Insert @title, @link1, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 5
	exec Notification_LocationInsert @id, 7
	------------------------------------------------------
	set @startdate = DATEADD(d, 2, @startdate)
	set @enddate = @startdate
	set @title =  @join1 + '11AM AT'
	exec Notification_Insert @title, @link2, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 0
	exec Notification_LocationInsert @id, 1
	exec Notification_LocationInsert @id, 2
	exec Notification_LocationInsert @id, 4
	set @title =  @join1 + '12PM PT'
	exec Notification_Insert @title, @link2, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 6
	set @title =  @join1 + '1PM MT'
	exec Notification_Insert @title, @link2, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 3
	set @title =  @join1 + '2PM CT'
	exec Notification_Insert @title, @link2, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 5
	exec Notification_LocationInsert @id, 7
	---------------------------------------------------------
	-- Orientation
	set @startdate = DATEADD(d, 4, @startdate)
	set @enddate = @startdate
	set @title =  @join3 + '9AM AT'
	exec Notification_Insert @title, @link3, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 0
	exec Notification_LocationInsert @id, 1
	exec Notification_LocationInsert @id, 2
	exec Notification_LocationInsert @id, 4
	set @title =  @join3 + '10AM PT'
	exec Notification_Insert @title, @link3, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 6
	set @title =  @join3 + '11AM MT'
	exec Notification_Insert @title, @link3, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 3
	set @title =  @join3 + '12PM CT'
	exec Notification_Insert @title, @link3, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 5
	exec Notification_LocationInsert @id, 7
	commit
end try
begin catch
	rollback
end catch