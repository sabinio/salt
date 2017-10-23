Function Disable-Job {
    <#
.Synopsis
Disables a job.
.Description
Disables a Job
.Parameter sqlServer
The SQL Connection that SQL Agent Job is on.
.Example
$jjob = Get-Job -SqlServer $SqlConnection -root $x
Disable-Job-job $jjob
#>
    [CmdletBinding()]
    param
    (
        [Microsoft.SqlServer.Management.Smo.Agent.AgentObjectBase]
        [ValidateNotNullorEmpty()]
        $job
    )
    try {
        $job.IsEnabled = $false
        $job.Alter()
        Write-Verbose "$($job.Name) disabled." -Verbose
    }
    catch {
        $_.Exception        
    }
}