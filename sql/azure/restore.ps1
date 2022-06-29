using namespace System.Collections.Generic
using namespace System.IO
using namespace System

param(
    [String]$restoreDestination = "g:\backups\",
    [String]$azureUrl = "https://prdintranetbackups.blob.core.windows.net/",
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


    Run-Restore-Database "inet-sql-dev-az" "RDI_Development_2" $fullBackupPaths $differentialBackupPaths

    $end = get-date
    $span = $end - $start

    Write-Output 'Restore took:'
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

    $query = "
        use master
        go

        alter database $($databaseName)
        set single_user with rollback immediate
        go

        print 'Begin DB Restore'

        restore database $($databaseName)
        from $($fullBackupPaths)
        with stats = 1
        go
        "
    
    if ($null -ne $differentialBackupPaths)
    {
        $query += "
            restore database $($databaseName)
            from $($fullBackupPaths)
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

    if ($true -eq $scrub)
    {
        $query += "
            print 'Begin scrub'

            use $($databaseName)
            go
            exec RDI_CleanDevDatabase

            print 'End scrub'
            "
    }

    $query += "
        use $($databaseName)
        go
        dbcc shrinkfile (resdat_bd2000SQL_log, 1)
        go
        
        alter database $($databaseName)
        set multi_user
        "
    
    Write-Output $query
    
    invoke-sqlcmd -query $query -Database $databaseName -ServerInstance $serverName
}

Main