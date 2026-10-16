# DevTeam Task Manager - API regression test script
# Windows PowerShell 5.1+ / PowerShell 7+
# Uses temporary records and attempts cleanup. Run ONLY against a development/test database.

[CmdletBinding()]
param(
    [string]$BaseUrl = 'http://localhost:5074',
    [string]$ReportPath = "$PSScriptRoot\DevTeamTaskManager-TestReport.json"
)

$ErrorActionPreference = 'Stop'

# Windows PowerShell 5.1 may not auto-load this assembly before resolving HttpClient.
Add-Type -AssemblyName System.Net.Http

$script:Http = [System.Net.Http.HttpClient]::new()
$script:Http.Timeout = [TimeSpan]::FromSeconds(30)
$script:Results = [System.Collections.Generic.List[object]]::new()
$script:CreatedTaskIds = [System.Collections.Generic.List[int]]::new()
$script:CreatedTimeEntryIds = [System.Collections.Generic.List[int]]::new()

function Invoke-Api {
    param(
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Path,
        [object]$Body = $null
    )
    $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::new($Method), "$($script:BaseUrl)$Path")
    if ($null -ne $Body) {
        $json = ConvertTo-Json -InputObject $Body -Depth 20 -Compress
        $request.Content = [System.Net.Http.StringContent]::new($json, [System.Text.Encoding]::UTF8, 'application/json')
    }
    try {
        $response = $script:Http.SendAsync($request).GetAwaiter().GetResult()
        $raw = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $parsed = $raw
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            try { $parsed = ConvertFrom-Json -InputObject $raw -ErrorAction Stop } catch { $parsed = $raw }
        }
        return [pscustomobject]@{
            StatusCode = [int]$response.StatusCode
            Body = $parsed
            RawBody = $raw
        }
    }
    finally {
        if ($null -ne $response) { $response.Dispose() }
        $request.Dispose()
    }
}

function Add-Check {
    param([string]$Name, [int[]]$ExpectedStatus, $ActualResponse, [string]$Detail = '')
    $pass = $ExpectedStatus -contains $ActualResponse.StatusCode
    $script:Results.Add([pscustomobject]@{
        Test = $Name
        Result = if ($pass) { 'PASS' } else { 'FAIL' }
        ExpectedStatus = ($ExpectedStatus -join ' or ')
        ActualStatus = $ActualResponse.StatusCode
        Detail = $Detail
        Response = if ($ActualResponse.RawBody.Length -gt 500) { $ActualResponse.RawBody.Substring(0,500) } else { $ActualResponse.RawBody }
    })
    $color = if ($pass) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} (expected {2}, got {3}) {4}" -f $(if ($pass) {'PASS'} else {'FAIL'}), $Name, ($ExpectedStatus -join '/'), $ActualResponse.StatusCode, $Detail) -ForegroundColor $color
    return $pass
}

function Add-Condition {
    param([string]$Name, [bool]$Passed, [string]$Detail = '')
    $script:Results.Add([pscustomobject]@{
        Test = $Name; Result = if ($Passed) { 'PASS' } else { 'FAIL' }
        ExpectedStatus = 'Condition'; ActualStatus = if ($Passed) { 'OK' } else { 'NOT OK' }
        Detail = $Detail; Response = ''
    })
    Write-Host ("[{0}] {1} {2}" -f $(if ($Passed) {'PASS'} else {'FAIL'}), $Name, $Detail) -ForegroundColor $(if ($Passed) {'Green'} else {'Red'})
}

$script:BaseUrl = $BaseUrl.TrimEnd('/')
$taskId = $null
$timeEntryId = $null
$developerId = $null
$sprintId = $null

Write-Host "`nDevTeam Task Manager API QA" -ForegroundColor Cyan
Write-Host "Base URL: $script:BaseUrl"
Write-Host 'ATTENTION: use only a development/test database.' -ForegroundColor Yellow

try {
    # Connectivity and baseline reads
    $r = Invoke-Api GET '/swagger/v1/swagger.json'
    Add-Check 'Swagger is reachable' @(200) $r | Out-Null

    $developersResponse = Invoke-Api GET '/api/Developers'
    Add-Check 'GET Developers' @(200) $developersResponse | Out-Null
    $developers = @($developersResponse.Body)
    if ($developersResponse.StatusCode -ne 200 -or $developers.Count -eq 0 -or -not $developers[0].id) {
        throw 'Cannot continue safely: GET /api/Developers returned no usable developer ID.'
    }
    $developerId = [int]$developers[0].id

    $tasksResponse = Invoke-Api GET '/api/Tasks'
    Add-Check 'GET Tasks' @(200) $tasksResponse | Out-Null
    $r = Invoke-Api GET '/api/Sprints'
    Add-Check 'GET Sprints' @(200) $r | Out-Null
    $sprints = @($r.Body)
    if ($sprints.Count -gt 0 -and $sprints[0].id) { $sprintId = [int]$sprints[0].id }
    $r = Invoke-Api GET '/api/TimeEntries'
    Add-Check 'GET TimeEntries' @(200) $r | Out-Null

    # Missing resource handling
    $r = Invoke-Api GET '/api/Tasks/999999'
    Add-Check 'Unknown task returns 404' @(404) $r | Out-Null
    $r = Invoke-Api GET '/api/TimeEntries/999999'
    Add-Check 'Unknown time entry returns 404' @(404) $r | Out-Null
    $r = Invoke-Api GET '/api/Sprints/999999/capacity'
    Add-Check 'Unknown sprint capacity returns 404' @(404) $r | Out-Null
    $r = Invoke-Api DELETE '/api/Tasks/999999'
    Add-Check 'Deleting unknown task returns 404' @(404) $r | Out-Null

    # Filter checks
    $r = Invoke-Api GET "/api/Tasks?assigneeId=$developerId"
    Add-Check 'Task filter by assigneeId' @(200) $r | Out-Null
    $r = Invoke-Api GET '/api/Tasks?status=999'
    Add-Check 'Invalid status filter rejected' @(400) $r | Out-Null
    $r = Invoke-Api GET '/api/Tasks?priority=999'
    Add-Check 'Invalid priority filter rejected' @(400) $r | Out-Null

    # Create a unique task for write tests
    $stamp = Get-Date -Format 'yyyyMMddHHmmss'
    $taskBody = @{
        client = "QA_AUTOTEST_$stamp"
        description = 'Temporary task created by API regression test; safe to delete'
        assigneeId = $developerId
        estimatedHours = 5.0
        dueDate = (Get-Date).AddDays(14).ToString('yyyy-MM-ddTHH:mm:ss')
        priority = 2
        sprintId = $null
    }
    $r = Invoke-Api POST '/api/Tasks' $taskBody
    $created = Add-Check 'Create valid task returns 201' @(201) $r
    if ($created -and $r.Body.id) {
        $taskId = [int]$r.Body.id
        $script:CreatedTaskIds.Add($taskId)
    } else {
        throw "Cannot continue write tests: task creation failed. Response: $($r.RawBody)"
    }

    $r = Invoke-Api GET "/api/Tasks/$taskId"
    Add-Check 'Read created task returns 200' @(200) $r | Out-Null
    Add-Condition 'Created task ID matches' ([int]$r.Body.id -eq $taskId) "id=$taskId"

    $r = Invoke-Api GET "/api/Tasks?client=QA_AUTOTEST_$stamp"
    Add-Check 'Client text filter finds test task' @(200) $r | Out-Null
    Add-Condition 'Client filter contains test task' (@($r.Body | Where-Object { $_.id -eq $taskId }).Count -gt 0) "taskId=$taskId"

    # DTO validation probe: if invalid data is accepted, remove it immediately.
    $invalidTaskBody = @{
        client = ''
        description = ''
        assigneeId = $developerId
        estimatedHours = 0
        dueDate = (Get-Date).AddDays(7).ToString('yyyy-MM-ddTHH:mm:ss')
        priority = 999
        sprintId = $null
    }
    $r = Invoke-Api POST '/api/Tasks' $invalidTaskBody
    Add-Check 'Invalid task payload is rejected (expected 400)' @(400,422) $r 'If this fails, DTO validation is missing.' | Out-Null
    if ($r.StatusCode -eq 201 -and $r.Body.id) {
        $invalidId = [int]$r.Body.id
        $null = Invoke-Api DELETE "/api/Tasks/$invalidId"
        Add-Condition 'Cleanup invalid task accepted by API' $true "deleted id=$invalidId"
    }

    # Inline update boundary tests. Restore value immediately if 0 is accepted.
    $r = Invoke-Api PATCH "/api/Tasks/$taskId/inline" @{ estimatedHours = 0 }
    Add-Check 'EstimatedHours=0 rejected (expected 400)' @(400) $r 'Known defect if API returns 204.' | Out-Null
    if ($r.StatusCode -in @(200,204)) {
        $restore = Invoke-Api PATCH "/api/Tasks/$taskId/inline" @{ estimatedHours = 5.0 }
        Add-Check 'Restore estimate after boundary probe' @(200,204) $restore | Out-Null
    }

    $r = Invoke-Api PATCH "/api/Tasks/$taskId/inline" @{ estimatedHours = 0.1 }
    Add-Check 'EstimatedHours=0.1 accepted' @(200,204) $r | Out-Null
    $r = Invoke-Api GET "/api/Tasks/$taskId"
    Add-Condition 'Minimum estimate persisted' ([decimal]$r.Body.estimatedHours -eq [decimal]0.1) "actual=$($r.Body.estimatedHours)"

    # Invalid status must not persist. If accepted, restore status immediately.
    $r = Invoke-Api PATCH "/api/Tasks/$taskId/status" @{ status = 999 }
    Add-Check 'Invalid task status rejected (expected 400)' @(400) $r 'Known defect if API returns 204.' | Out-Null
    if ($r.StatusCode -in @(200,204)) {
        $restore = Invoke-Api PATCH "/api/Tasks/$taskId/status" @{ status = 1 }
        Add-Check 'Restore valid status after boundary probe' @(200,204) $restore | Out-Null
    }

    # PUT update and persistence
    $updateBody = @{
        client = "QA_AUTOTEST_$stamp"
        description = 'Temporary task updated by API regression test'
        assigneeId = $developerId
        estimatedHours = 3.5
        dueDate = (Get-Date).AddDays(21).ToString('yyyy-MM-ddTHH:mm:ss')
        priority = 3
        sprintId = $null
        status = 2
    }
    $r = Invoke-Api PUT "/api/Tasks/$taskId" $updateBody
    Add-Check 'Update task with PUT returns 204' @(204) $r | Out-Null
    $r = Invoke-Api GET "/api/Tasks/$taskId"
    Add-Condition 'PUT changes persisted' ($r.StatusCode -eq 200 -and [decimal]$r.Body.estimatedHours -eq [decimal]3.5 -and [int]$r.Body.status -eq 2 -and [int]$r.Body.priority -eq 3) "status=$($r.Body.status), estimate=$($r.Body.estimatedHours), priority=$($r.Body.priority)"

    # Time-entry validation and creation
    $badTimeBody = @{
        taskId = $taskId; developerId = $developerId
        workDate = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
        durationHours = 25; note = 'QA invalid duration probe'
    }
    $r = Invoke-Api POST '/api/TimeEntries' $badTimeBody
    Add-Check 'Time entry duration 25h rejected' @(400) $r | Out-Null

    $timeBody = @{
        taskId = $taskId; developerId = $developerId
        workDate = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
        durationHours = 0.5; note = 'QA temporary entry'
    }
    $r = Invoke-Api POST '/api/TimeEntries' $timeBody
    $createdTime = Add-Check 'Create valid time entry returns 201' @(201) $r
    if ($createdTime -and $r.Body.id) {
        $timeEntryId = [int]$r.Body.id
        $script:CreatedTimeEntryIds.Add($timeEntryId)
        $r2 = Invoke-Api GET "/api/TimeEntries/$timeEntryId"
        Add-Check 'Read created time entry returns 200' @(200) $r2 | Out-Null
        Add-Condition 'Time entry persisted with expected duration' ([decimal]$r2.Body.durationHours -eq [decimal]0.5 -and [int]$r2.Body.taskId -eq $taskId) "entryId=$timeEntryId"
    }

    # Sprint validation and capacity read-only checks
    $badSprintBody = @{
        name = "QA_INVALID_SPRINT_$stamp"
        startDate = (Get-Date).AddDays(10).ToString('yyyy-MM-ddTHH:mm:ss')
        endDate = (Get-Date).AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss')
        status = 1
    }
    $r = Invoke-Api POST '/api/Sprints' $badSprintBody
    Add-Check 'Sprint end date before start date rejected' @(400) $r | Out-Null

    $r = Invoke-Api GET '/api/Sprints/active'
    Add-Check 'GET active sprints' @(200) $r | Out-Null
    if ($sprintId) {
        $r = Invoke-Api GET "/api/Sprints/$sprintId/capacity"
        Add-Check 'Existing sprint capacity returns 200' @(200) $r | Out-Null
        if ($r.StatusCode -eq 200) {
            Add-Condition 'Sprint capacity has required totals' ($null -ne $r.Body.totalEstimatedHours -and $null -ne $r.Body.totalLoggedHours -and $null -ne $r.Body.developerAllocations) "sprintId=$sprintId"
        }
    } else {
        Add-Condition 'Sprint capacity test skipped (no existing sprint)' $true 'No sprint was returned by GET /api/Sprints.'
    }
}
catch {
    Write-Host "TEST RUN INTERRUPTED: $($_.Exception.Message)" -ForegroundColor Red
    $script:Results.Add([pscustomobject]@{ Test='Test run interruption'; Result='ERROR'; ExpectedStatus='N/A'; ActualStatus='ERROR'; Detail=$_.Exception.Message; Response='' })
}
finally {
    # Cleanup only records created by this script. Task endpoint also removes related time entries.
    foreach ($id in $script:CreatedTaskIds) {
        try {
            $cleanup = Invoke-Api DELETE "/api/Tasks/$id"
            Add-Check "Cleanup test task $id" @(204,404) $cleanup | Out-Null
        } catch { Write-Host "Cleanup failed for task $id : $($_.Exception.Message)" -ForegroundColor Red }
    }
    $script:Http.Dispose()
    $passed = @($script:Results | Where-Object Result -eq 'PASS').Count
    $failed = @($script:Results | Where-Object Result -eq 'FAIL').Count
    $errors = @($script:Results | Where-Object Result -eq 'ERROR').Count
    $report = [pscustomobject]@{
        ExecutedAt = (Get-Date).ToString('o')
        BaseUrl = $script:BaseUrl
        Summary = [pscustomobject]@{ Total = $script:Results.Count; Passed = $passed; Failed = $failed; Errors = $errors }
        Results = @($script:Results)
    }
    $report | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $ReportPath -Encoding UTF8
    Write-Host "`n========== SUMMARY ==========" -ForegroundColor Cyan
    Write-Host "Total: $($script:Results.Count) | PASS: $passed | FAIL: $failed | ERROR: $errors"
    Write-Host "Report saved to: $ReportPath" -ForegroundColor Cyan
}
