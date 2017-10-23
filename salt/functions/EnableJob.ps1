Function enable-Job {
    <#
.Synopsis
enables a job
.Description
enables a Job
.Parameter sqlServer
The SQL Connection that SQL Agent Job is on.
.Example
$jjob = Get-Job -SqlServer $SqlConnection -root $x
enable-Job-job $jjob
#>
    [CmdletBinding()]
    param
    (
        [Microsoft.SqlServer.Management.Smo.Agent.AgentObjectBase]
        [ValidateNotNullorEmpty()]
        $job
    )
    try {
        $job.IsEnabled = $true
        $job.Alter()            
        Write-Verbose "$($Job.Name) enabled." -Verbose
    }
    catch {
        $_.Exception
    }
}