Function Disable-JobNotifications {
    <#
.Synopsis
Disables all job notifications
.Description
Because it is not possible to set an operator to a notification when it is set to never, we have to use this function to disable all notifications after a
job has been deployed. This is because in some environments we may not want to send notifications if in wrong domain/clog up the event viewer 
We have to clear operators as if we try to set to never with operators attached then alter will fail.
.Parameter job
Name of the job whose notifications we want to disable
.Example
Disable-JobNotifications - SqlServer $sqlConnection -job $sqlServerAgentJob 
#>
    [CmdletBinding()]
    param
    (
        [Microsoft.SqlServer.Management.Smo.Agent.AgentObjectBase]
        [ValidateNotNullorEmpty()]
        $job
    )
    $SendLevel = "Never"
    $job.OperatorToEmail = ''
    $job.OperatorToPage = ''
    $job.OperatorToNetSend = ''
    $job.NetSendLevel = $SendLevel
    $job.PageLevel = $SendLevel
    $job.EventLogLevel = $SendLevel
    $job.EmailLevel = $SendLevel
    try{
    $job.Alter()
    }
    catch {
        throw $_.Exception
    }
}