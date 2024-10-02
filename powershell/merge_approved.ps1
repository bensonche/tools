Set-StrictMode -Version 3
$ErrorActionPreference = 'Stop'

$token = $env:INTRANET_TOKEN

if ($null -eq $token)
{
    Write-Host "Missing INTRANET_TOKEN environment variable"
    
    exit 1
}

$Headers = @{
    'Authorization' = "token $token"
}

$MergePriorityLabel = @{
    'deploy priority skip' = -1;
    'on hold' = -1;
    'deploy priority critical' = 1;
    'deploy priority high' = 2;
    'deploy priority medium' = 3;
    'deploy priority low' = 4
}

$PullRequests = Invoke-RestMethod -Uri https://api.github.com/repos/ResourceDataInc/Intranet/pulls?state=open`&per_page=100`&base=master -Headers $Headers

# Add MergePrioritySort property to all the pull requests for sorting
$PullRequests | ForEach-Object {
    Add-Member -InputObject $_ -NotePropertyName MergePrioritySort -NotePropertyValue 100
    if($_.labels.Count -ne 0){
        $priorities = $_.labels.name | %{
            if($MergePriorityLabel.ContainsKey($_)) {
                return $MergePriorityLabel[$_]
            } else {
                return -100;
            }
        }

        $_.MergePrioritySort = ($priorities | measure -Maximum).Maximum
        if ($_.MergePrioritySort -eq -100) {
            $_.MergePrioritySort = 100
        }
    }
}

foreach($request in $PullRequests | Sort-Object -Property MergePrioritySort, created_at) {
    $hasLabel = $request.labels.Count -ne 0 -and $request.labels.name -contains "approved-for-release"

    if($hasLabel) {
        if($request.MergePrioritySort -eq -1) {
            Write-Host "Skipping PR $($request.number) - $($request.title) due to labels ($($request.labels.name))" -Fore yellow
            Continue
        }
        
        # Fetch mergeable state
        $retries = 0

        $pullRequest = Invoke-RestMethod -Uri $request.url -Headers $Headers
        $stateUnknown = $pullRequest.mergeable_state -eq "unknown"

        while($retries -lt 6 -and $stateUnknown) {
            $retries++
            Start-Sleep -Seconds 1

            $pullRequest = Invoke-RestMethod -Uri $request.url -Headers $Headers

            $stateUnknown = $pullRequest.mergeable_state -eq "unknown"
        }
        
        if($requestDetails.mergeable_state -ne 'clean') {
            Write-Host "Skipping PR $($request.number) - $($request.title) due to a state of $($requestDetails.mergeable_state)" -Fore orange

            Continue
        }

        # Invoke endpoint to merge
        $url = "https://api.github.com/repos/ResourceDataInc/Intranet/pulls/$($request.number)/merge" | Out-Null

        try {
            Invoke-RestMethod -Method Put -Uri $url -Headers $Headers -Body '{"merge_method": "rebase"}'

            Write-Host "Merged PR $($request.number) - $($request.title)" -Fore green
        }
        catch {
            Write-Host "Failed to merge PR $($request.number) - $($request.title)" -Fore red
            $_.Exception

            Write-Host
        }
    }
}