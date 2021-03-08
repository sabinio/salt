Function Disable-JobSchedules {
    <#
.Synopsis
Disables all schedules for a job
.Description
Disables all schedules for a job
.Parameter sqlServer
The SQL Connection that SQL Agent Job is on.
.Example
$jjob = Get-Job -SqlServer $SqlConnection -root $x
Disable-JobSchedules -job $jjob
#>
    [CmdletBinding()]
    param
    (
        [Microsoft.SqlServer.Management.Smo.Agent.AgentObjectBase]
        [ValidateNotNullorEmpty()]
        $job
    )
    $schedules = $job.JobSchedules
    foreach ($schedule in $schedules) {
        try {
            $jobScheduletoUpdate = $job.JobSchedules | Where-Object {$_.Name -eq $schedule}
            Write-Verbose "Disabling Job Schedule $($jobScheduletoUpdate.Name)."
            $jobScheduletoUpdate.IsEnabled = $false
            $jobScheduletoUpdate.Alter()
        }
        catch {
            $_.Exception
        }
    }
    $job.Alter()
}