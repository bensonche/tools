using namespace System.Collections.Generic
using namespace System.IO
using namespace System

param(
    [String]$restoreDestination = "g:\backups\",
    [String]$azureUrl = "https://prdintranetbackups-secondary.blob.core.windows.net/",
    [string]$fullContainerName = "backup-full",
    [string]$differentialContainerName = "backup-differential",
    [bool]$downloadFromAzure = $true
)

$ErrorActionPreference = "Stop"

function Main {
    $start = Get-Date

    # return
    $databaseList = New-Object List[Database]

    # Autodetect which databases to restore if the list is null.
    # Otherwise, uncomment the following to restore to a specific database

    # $database = New-Object Database
    # $database.Name = "RDI_Development_2"
    # $database.Scrub = $true
    # $databaseList.Add($database)

    if ($databaseList.Count -eq 0) {
        if ($env:computername.ToLower().Contains("dev")) {
            $database = New-Object Database
            $database.Name = "RDI_Development"
            $database.Scrub = $true
            $databaseList.Add($database)
    
            $database = New-Object Database
            $database.Name = "RDI_Development_2"
            $database.Scrub = $true
            $databaseList.Add($database)
        }
        elseif ($env:computername.ToLower().Contains("tst")) {
            $database = New-Object Database
            $database.Name = "RDI_Test"
            $database.Scrub = $false
            $databaseList.Add($database)
    
            $database = New-Object Database
            $database.Name = "RDI_Test_2"
            $database.Scrub = $false
            $databaseList.Add($database)
        }
    }

    $context = New-AzStorageContext -StorageAccountName "prdintranetbackups" -SasToken ""

    # $context | Get-AzStorageContainer -name $differentialContainerName | Get-AzStorageBlob | Select-Object -Property Name
    $fullBackupBlobs = $context | Get-AzStorageContainer -name $fullContainerName | Get-AzStorageBlob -Blob *RDI_Production* | Select-Object -Property Name
    $latestFullBackupDate = Get-Most-Recent-Date $fullBackupBlobs
    $latestFullBackupList = Find-Most-Recent $fullBackupBlobs $latestFullBackupDate

    $differentialBackupBlobs = $context | Get-AzStorageContainer -name $differentialContainerName | Get-AzStorageBlob -Blob *RDI_Production* | Select-Object -Property Name
    $latestDifferentialBackupDate = Get-Most-Recent-Date $differentialBackupBlobs
    $latestDifferentialBackupList = Find-Most-Recent $differentialBackupBlobs $latestDifferentialBackupDate

    if ($downloadFromAzure) {
        $destination = new-object DirectoryInfo($restoreDestination)

        if ($destination.Exists) {
            $destination.Delete($true)
        }

        $destination.Create()

        foreach ($blob in $latestFullBackupList) {
            $fullPath = [Path]::Combine($destination, $blob)
            $context | Get-AzStorageBlobContent -Container $fullContainerName -Blob $blob -Destination $fullPath
        }

        if ($latestDifferentialBackupDate -gt $latestFullBackupDate) {
            foreach ($blob in $latestDifferentialBackupList) {
                $fullPath = [Path]::Combine($destination, $blob)
                $context | Get-AzStorageBlobContent -Container $differentialContainerName -Blob $blob -Destination $fullPath
            }
        }
        
        $end = get-date
        $span = $end - $start

        Write-Output 'Download from Azure took:'
        write-output $span

        $start = $end
    }

    $fullBackupPaths = Get-Csv-Backup-Paths $latestFullBackupList
    
    if ($latestDifferentialBackupDate -gt $latestFullBackupDate) {
        $differentialBackupPaths = Get-Csv-Backup-Paths $latestDifferentialBackupList
    }

    Write-Output $fullBackupPaths
    Write-Output $differentialBackupPaths

    foreach ($database in $databaseList) {
        Write-Output "Restoring $($database.Name), Scrub: $($database.Scrub)"
        Run-Restore-Database "localhost" $database.Name $fullBackupPaths $differentialBackupPaths $database.Scrub
    }

    $end = get-date
    $span = $end - $start

    Write-Output 'Restore all databases took:'
    write-output $span
}

class Database {
    [string]$Name
    [bool]$Scrub
}

function Get-Most-Recent-Date {
    param (
        $backupBlobs
    )

    $latestBackupDate = $null

    foreach ($b in $backupBlobs) {
        $a = $b.Name.Split("-")
        $date = [DateTime]::Parse($a[$a.Length - 2])

        if ($null -eq $latestBackupDate -or $date -gt $latestBackupDate) {
            $latestBackupDate = $date
        }
    }

    return $latestBackupDate
}

function Find-Most-Recent {
    param (
        $backupBlobs,
        $date
    )

    $backupList = New-Object List[string]
    
    foreach ($b in $backupBlobs) {
        $a = $b.Name.Split("-")
        $blobDate = [DateTime]::Parse($a[$a.Length - 2])

        if ($blobDate -eq $date) {
            $backupList.Add($b.Name)
        }
    }

    return $backupList
}

function Get-Csv-Backup-Paths {
    param (
        $backupList
    )

    $backupPaths = ""
    foreach ($backup in $backupList) {
        $path = [Path]::Combine($restoreDestination, $backup)
        $backupPaths += ",disk = '$($path)'`n"
    }
    $backupPaths = $backupPaths.Substring(1)

    return $backupPaths
}

function Run-Restore-Database {
    param (
        [string]$serverName,
        [string]$databaseName,
        [string]$fullBackupPaths,
        [string]$differentialBackupPaths,
        [bool]$scrub
    )

    $start = Get-Date
    Write-Output "Restoring $($databaseName) starting at $($start.ToShortTimeString())"

    $recoveryString = ""
    if ($null -ne $differentialBackupPaths) {
        $recoveryString = ", norecovery"
    }

    $query = "
        use master
        go

        begin try
            alter database $($databaseName)
            set single_user with rollback immediate
        end try
        begin catch
        end catch
        go

        print 'Begin DB Restore'

        restore database $($databaseName)
        from $($fullBackupPaths)
        with
            stats = 1,
            move 'resdat_be2000SQL_dat' to 'F:\Database\$($databaseName).mdf',
            move 'resdat_be2000SQL_log' to 'L:\Database\$($databaseName).ldf'
            $($recoveryString)
        go
        "
    
    if ($null -ne $differentialBackupPaths) {
        $query += "
            restore database $($databaseName)
            from $($differentialBackupPaths)
            with stats = 1
            go
            "
    }

    $query += "
        alter database $($databaseName)
        set recovery simple
        go

        print 'DB Restore Finished'
        "

    Write-Output $query
    invoke-sqlcmd -query $query -Database master -ServerInstance $serverName -ConnectionTimeout 0 -QueryTimeout 0 -Verbose

    if ($true -eq $scrub) {
        $query = "
            print 'Begin scrub'

            use $($databaseName)
            go
            exec RDI_CleanDevDatabase

            print 'End scrub'
            "

        $ErrorActionPreference = "Continue"

        Write-Output $query
        invoke-sqlcmd -query $query -Database master -ServerInstance $serverName -ConnectionTimeout 0 -QueryTimeout 0 -Verbose
        
        $ErrorActionPreference = "Stop"
    }

    $query = "
        use $($databaseName)
        go
        dbcc shrinkfile (resdat_be2000SQL_log, 1)
        go
        
        alter database $($databaseName)
        set multi_user
        "
    
    Write-Output $query
    invoke-sqlcmd -query $query -Database master -ServerInstance $serverName -ConnectionTimeout 0 -QueryTimeout 0 -Verbose

    $query = "
        use $($databaseName)
        go
        declare @username varchar(max)
        declare @orphans table
        (
            username varchar(max),
            userSid varchar(max)
        )
    
        insert into @orphans
        exec sp_change_users_login 'report'
    
        declare GetOrphanUsers cursor
        for
        select username
        FROM @orphans
    
        open GetOrphanUsers
    
        fetch next
        from GetOrphanUsers
        into @username
    
        while @@fetch_status = 0
        begin
            exec sp_change_users_login 'Auto_Fix', @username
            
            fetch next
            from GetOrphanUsers
            into @username
        end
    
        close GetOrphanUsers
        deallocate GetOrphanUsers
    
        declare GetOrphanUsers2 cursor
        for
            select a.name
            from sysusers a
                left join sys.server_principals b
                    on a.sid = b.sid
            where b.sid is null
            and a.islogin = 1
            and a.hasdbaccess = 1
            and a.issqluser = 0
    
        open GetOrphanUsers2
    
        fetch next
        from GetOrphanUsers2
        into @username
    
        while @@fetch_status = 0
        begin
            begin try
                print 'create login [' + @username + '] from windows'
                exec('create login [' + @username + '] from windows')
            end try
            begin catch
            end catch
    
            fetch next
            from GetOrphanUsers2
            into @username
        end
    
        close GetOrphanUsers2
        deallocate GetOrphanUsers2
        "

    Write-Output $query
    invoke-sqlcmd -query $query -Database master -ServerInstance $serverName -ConnectionTimeout 0 -QueryTimeout 0 -Verbose

    $end = get-date
    $span = $end - $start

    Write-Output "Restore $($databaseName) finished, taking:"
    write-output $span
}

Main