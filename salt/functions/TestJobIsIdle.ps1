Function Test-JobIsIdle {
    <#
.Synopsis
Teet Job is idle
.Description
Before altering jobs, we will want to check that the status of the job is not running.
So before we continue, we check the current run status of the job. 
Will run a loop calling Get-JobCurrentRUnStatus until job is idle.
Util then we Start-Sleep for 10 seconds before re-checking status.   
Before making sure job is idle, make sure that the job is disabled and all schedues are disabled. Otherwise job may just start runnign mid-change!
.Parameter Job
The Job we want to make usre is idle.
.Example
$jjob = Get-Job -SqlServer $SqlConnection -root $x
Get-TestJobIsIdle -job $jjob
#>
    [CmdletBinding()]
    param
    (
        [Microsoft.SqlServer.Management.Smo.Agent.AgentObjectBase]
        [ValidateNotNullorEmpty()]
        $job
    )
    [int32] $retry = 0
    [String] $JobCurrentRunStatus
    Write-Verbose "Checking that job $($job.Name) is idle. If status is not idle will try again in 5 seconds. Updates during this time are every minute." -Verbose
    do {
        $JobCurrentRunStatus = $null
        $JobCurrentRunStatusEnum = Get-JobCurrentRunStatus -job $job
        if ($JobCurrentRunStatusEnum -eq 1) {$JobCurrentRunStatus = "value = 1. The job is being run."}
        if ($JobCurrentRunStatusEnum -eq 2) {$JobCurrentRunStatus = "value = 2. The job is waiting for a worker thread."}
        if ($JobCurrentRunStatusEnum -eq 3) {$JobCurrentRunStatus = "value = 3. The job is waiting to retry after a failure."}
        if ($JobCurrentRunStatusEnum -eq 4) {$JobCurrentRunStatus = "value = 4. The job is idle."}
        if ($JobCurrentRunStatusEnum -eq 5) {$JobCurrentRunStatus = "value = 5. The job is suspended."}
        if ($JobCurrentRunStatusEnum -eq 6) {$JobCurrentRunStatus = "value = 6. The job is waiting for another branch of logic to finish before it can continue."}
        if ($JobCurrentRunStatusEnum -eq 7) {$JobCurrentRunStatus = "value = 7. The job is in the final completion stage."}
        $retry = $retry + 5
        if ($retry % 12 -eq 0) {
            Write-Verbose "Currently the job run status $($JobCurrentRunStatus)" -Verbose
        }
        Start-Sleep -Seconds 5
    }
    until ($JobCurrentRunStatusEnum -eq 4)
    Write-Verbose "Job is idle." -Verbose
}