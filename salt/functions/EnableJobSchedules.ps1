Function Enable-JobSchedules {
    <#
.Synopsis
enables a job schedules.
.Description
Enables all Job Schedules.
If job schedules end date is in the past, then job cannot be enabled. An attempt doesn't cause a failure, but it doesn't change status to enabled.
.Parameter sqlServer
The SQL Connection that SQL Agent Job is on.
.Example
$jjob = Get-Job -SqlServer $SqlConnection -root $x
enable-JobSchedules-job $jjob
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
            If ((Get-Date) -gt ($jobScheduletoUpdate.ActiveEndDate)) {
                Write-Verbose "End date of schedule $($jobScheduletoUpdate.Name) is in the past. Schedule cannot be enabled."
            }
            Else {
                Write-Verbose "Enabling Job Schedule $($jobScheduletoUpdate.Name)."
                $jobScheduletoUpdate.IsEnabled = $true
                $jobScheduletoUpdate.Alter()
            }
        }
        catch {
            $_.Exception     
        }
    }
    $job.Alter()
}