Set-StrictMode -Version 3
$ErrorActionPreference = 'Stop'

$token = $env:INTRANET_TOKEN

if ($null -eq $token)
{
    Write-Host "Missing INTRANET_TOKEN environment variable"
    
    exit 1
}

git fetch
git checkout origin/master

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

$results = @()

foreach($request in $PullRequests | Sort-Object -Property MergePrioritySort, created_at) {
    $hasLabel = $request.labels.Count -ne 0 -and $request.labels.name -contains "approved-for-release"

    if($hasLabel) {
        if($request.MergePrioritySort -eq -1) {
            $results += @{
                SortOrder = 1
                Status = 'skipped'
                Number = $request.number
                Title = $request.title
                Message = "Skipping PR $($request.number) - $($request.title) due to labels ($($request.labels.name))"
                Color = "yellow"
            }

            Write-Host "Skipping PR $($request.number) - $($request.title) due to labels ($($request.labels.name))" -Fore yellow
            Continue
        }

        Write-Host "Attempting to merge PR $($request.number) - $($request.title)" -Fore green

        git -c user.email="intranet-pipeline@resorucedata.com" -c user.name="Intranet Pipeline" merge --no-edit origin/$($request.head.ref)

        $conflicts = (git diff --check) | Out-String
    
        if($conflicts -like '*leftover conflict marker*') {
            $results += @{
                SortOrder = 3
                Status = 'conflict'
                Number = $request.number
                Title = $request.title
                Message = "Failed to merge PR $($request.number) - $($request.title) due to conflicts"
                Color = "red"
            }
            
            Write-Host "Failed to merge PR $($request.number) - $($request.title) due to conflicts" -Fore red

            git reset --merge

            Continue
        }

        $results += @{
            SortOrder = 2
            Status = 'deployed'
            Title = $request.title
            Number = $request.number
            Message = "Merged $($request.number) - $($request.title)"
            Color = "green"
        }
    }
}

Write-Host
Write-Host
Write-Host "Merge results:"
Write-Host

foreach($result in $results | Sort-Object -Property { $_.SortOrder, $_.Number }) {
    Write-Host -Fore $result.Color $result.Message
}