Function Get-JobCurrentRunStatus    {
    <#
.Synopsis
Get the current run status of the SQL Agent Job.
.Description
Before altering jobs, we will want to check that the status of the job is not running.
So before we continue, we check the current run status of the job. 
This returns the current run status to whatever is calling it.   
.Parameter Job
The Job we want to check the status on
.Example
$jjob = Get-Job -SqlServer $SqlConnection -root $x
Get-JobCurrentRunStatus -job $jjob
#>
    [CmdletBinding()]
    param
    (
        [Microsoft.SqlServer.Management.Smo.Agent.AgentObjectBase]
        [ValidateNotNullorEmpty()]
        $job
    )
    try {
        $job.Refresh()
        Return $job.CurrentRunStatus
    }
    catch {
        $_.Exception        
    }
}