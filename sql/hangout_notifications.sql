set nocount on

begin try
	begin tran

	declare @startdate datetime
	declare @enddate datetime

	set @startdate = DATEADD(d, 1, dateadd(dd, 0, datediff(dd, 0, getdate())))

	declare @link1 varchar(max) = ''
	declare @link2 varchar(max) = ''
	declare @link3 varchar(max) = ''
	
	declare @join1 varchar(max) = 'Intranet Hangout on Skype at '
	declare @join2 varchar(max) = 'Intranet Hangout on Skype at '
	declare @join3 varchar(max) = 'Intranet Orientation on Zoom at '
	
	declare @contact1 varchar(max) = '. Contact Benson or Quinn for invite.'
	declare @contact2 varchar(max) = '. Contact Ariel for invite.'

	declare @title varchar(1000)
	declare @id int

	set @enddate = @startdate
	set @title =  @join1 + '10AM AT' + @contact1
	exec Notification_Insert @title, @link1, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 0
	exec Notification_LocationInsert @id, 1
	exec Notification_LocationInsert @id, 2
	exec Notification_LocationInsert @id, 4
	set @title =  @join1 + '11AM PT' + @contact1
	exec Notification_Insert @title, @link1, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 6
	set @title =  @join1 + '12PM MT' + @contact1
	exec Notification_Insert @title, @link1, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 3
	set @title =  @join1 + '1PM CT' + @contact1
	exec Notification_Insert @title, @link1, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 5
	exec Notification_LocationInsert @id, 7
	------------------------------------------------------
	set @startdate = DATEADD(d, 2, @startdate)
	set @enddate = @startdate
	set @title =  @join1 + '11AM AT' + @contact1
	exec Notification_Insert @title, @link2, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 0
	exec Notification_LocationInsert @id, 1
	exec Notification_LocationInsert @id, 2
	exec Notification_LocationInsert @id, 4
	set @title =  @join1 + '12PM PT' + @contact1
	exec Notification_Insert @title, @link2, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 6
	set @title =  @join1 + '1PM MT' + @contact1
	exec Notification_Insert @title, @link2, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 3
	set @title =  @join1 + '2PM CT' + @contact1
	exec Notification_Insert @title, @link2, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 5
	exec Notification_LocationInsert @id, 7
	---------------------------------------------------------
	-- Orientation
	set @startdate = DATEADD(d, 4, @startdate)
	set @enddate = @startdate
	set @title =  @join3 + '9AM AT' + @contact2
	exec Notification_Insert @title, @link3, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 0
	exec Notification_LocationInsert @id, 1
	exec Notification_LocationInsert @id, 2
	exec Notification_LocationInsert @id, 4
	set @title =  @join3 + '10AM PT' + @contact2
	exec Notification_Insert @title, @link3, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 6
	set @title =  @join3 + '11AM MT' + @contact2
	exec Notification_Insert @title, @link3, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 3
	set @title =  @join3 + '12PM CT' + @contact2
	exec Notification_Insert @title, @link3, @startdate, @enddate, @id output
	exec Notification_LocationInsert @id, 5
	exec Notification_LocationInsert @id, 7
	commit
end try
begin catch
	rollback
end catch