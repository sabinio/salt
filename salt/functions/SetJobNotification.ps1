Function Set-JobNotification {
    <#
.Synopsis
Set the notification setting of the SQL Agent Job to The Operator.
.Description
If the SQL Agent Job has an Operator associated to it then we set the notifications (if any) to point to the Operator.
.Parameter JobToAlter
Job whose properties we will be altering.
.Example
$JobOperatorName = $root.Operator.Name
        if ($JobOperatorName.Length -gt 0) {
            Write-Verbose "Operator assigned to job. Altering notification settings based on XML..." -Verbose
            Set-JobNotification -JobToAlter $JobToAlter -root $root
        }
        else {
            Write-Verbose "No Operator Information to set." -Verbose
        }
#>
    [CmdletBinding()]
    param
    (
        [System.Xml.XmlLinkedNode]
        [ValidateNotNullorEmpty()]
        $root,
        [Microsoft.SqlServer.Management.Smo.Agent.Job]
        [ValidateNotNullorEmpty()]
        $JobToAlter
    )
    $JobEmailLevel = $root.Notification.SendEmail
    $JobPagerLevel = $root.Notification.SendPage
    $JobNetSendLevel = $root.Notification.SendNetSend
    $JobEventLogLevel = $root.Notification.SendEventLog
    $JobToAlter.EmailLevel = $JobEmailLevel
    if ($JobEmailLevel -ne "Never") {
        Write-Verbose "Setting job to email $JobOperatorName on action $JobEmailLevel" -Verbose
        $JobToAlter.OperatorToEmail = $JobOperatorName
    }
    $JobToAlter.PageLevel = $jobPagerLevel
    if ($JobPagerLevel -ne "Never") {
        Write-Verbose "Setting job to page $JobOperatorName on action $jobPagerLevel" -Verbose
        $JobToAlter.OperatorToPage = $JobOperatorName
    }
    $JobToAlter.NetSendLevel = $JobNetSendLevel
    if ($JobNetSendLevel -ne "Never") {
        Write-Verbose "Setting job to netsend $JobOperatorName on action $JobNetSendLevel" -Verbose
        $JobToAlter.OperatorToNetSend = $JobOperatorName
    }
    $JobToAlter.EventLogLevel = $JobEventLogLevel
    if ($JobEventLogLevel -ne "Never") {
        Write-Verbose "Setting job to write to Windows Application event log on action $JobEventLogLevel" -Verbose
    }
    try {
        $JobToAlter.Alter()
        $JobToAlter.Refresh()
    }
    catch {
        Write-Error "Something has gone wrong in setting job notifications on $($jobToAlter.Name)"
        Throw $_.Exception
        Throw
    }
}