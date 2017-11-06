Function Set-Job {
    <#
.Synopsis
Create or modify SQL Agent Job.
.Description
SQL Agent Job will be created or updated to match the settings in the xml file.
.Parameter sqlServer
The SQL Connection that SQL Agent Job is on/will be created on.
.Parameter root
The XML Object
.Example
$JobManifestXmlFile = "C:\Reports\Our_First_Job.xml"
[xml] $_xml = [xml] (Get-Content -Path $JobManifestXmlFile)
$x = Get-Xml -XmlFile $_xml
$sqlAgentJob = Set-Job -SqlServer $SqlConnection -root $x

#>
    [CmdletBinding()]
    param
    (
        [Microsoft.SqlServer.Management.Smo.SqlSmoObject]
        [ValidateNotNullorEmpty()]
        $SqlServer,
        [System.Xml.XmlLinkedNode]
        [ValidateNotNullorEmpty()]
        $root
    )
    [string]$JobName = $root.Name
    $jobDescription = $root.Description
    $jobCategory = $root.Category.Value.Value
    [bool]$JobEnabled = if ($root.Enabled -eq "True") {$True} else {$false} 
    $JobOperatorName = $root.Operator.Name
    $JobEmailLevel = $root.Notification.SendEmail
    $JobPagerLevel = $root.Notification.SendPage
    $JobNetSendLevel = $root.Notification.SendNetSend
    $JobEventLogLevel = $root.Notification.SendEventLog
    $missingVariables = @()
    $keys = $($root.TargetServers.TargetServer)
    foreach ($var in $keys) {
        $update = $var.Include
        if (Test-Path variable:$update) {
            [string]$value = Get-Variable $update -ValueOnly
            Write-Verbose ('Setting variable: {0} = {1}' -f $update, $value) -Verbose
            $element = $root.SelectNodes("/Job/TargetServers/TargetServer") | Where-Object {$_.Include -eq $update} 
            $element.Value = $value
        }
        else {
            $missingVariables += $update
        }
    }
    if ($missingVariables.Count -gt 0) {
        throw ('The following variables are not defined in the current scope (but are defined in the xml): {0}' -f ($missingVariables -join " `n"))
    }
    $TargetServers = $root.TargetServers
    [string]$jobOwner = $root.Owner
    if ([string]::IsNullOrEmpty($jobOwner)) {
        Write-Verbose 'Parameter jobOwner not included in XML document. Setting account running this task as owner of job.' -Verbose
        $domain = [Environment]::UserDomainName
        $uname = [Environment]::UserName
        [string]$jobOwner = "$domain\$uname"
    }
    $serverJobs = $sqlserver.JobServer.Jobs | Select-Object -ExpandProperty Name
    $job = new-object ('Microsoft.SqlServer.Management.Smo.Agent.Job') ($SqlServer.JobServer, $jobName)
    if ($serverJobs -notcontains $jobName) {
        try {
            $job.Create()
            $job.Refresh()
            Write-Verbose "SQL Agent Job $jobName created successfully." -Verbose
        }
        catch {
            throw $_.Exception
        }
    }
    $job = $SqlServer.JobServer.Jobs | Where-Object {$_.Name -eq $JobName}
    $job.Refresh()
    try {
        $job.description = $jobDescription
        $job.IsEnabled = $JobEnabled
        $job.Category = $jobCategory
        $job.OwnerLoginName = $jobOwner
        $job.EmailLevel = $JobEmailLevel
        if ($JobEmailLevel -ne "Never") {
            $job.OperatorToEmail = $JobOperatorName
        }
        $job.PageLevel = $jobPagerLevel
        if ($JobPagerLevel -ne "Never") {
            $job.OperatorToPage = $JobOperatorName
        }
        $job.NetSendLevel = $JobNetSendLevel
        if ($JobNetSendLevel -ne "Never") {
            $job.OperatorToNetSend = $JobOperatorName
        }
        $job.EventLogLevel = $JobEventLogLevel
        $TargetServersList = $job.EnumTargetServers()
        foreach ($TargetServer in $TargetServers.ChildNodes) {
            if ($TargetServersList.ServerName -contains $TargetServer.Value) {
                $job.RemoveFromTargetServer($TargetServer.Value)   
            }
            try {
                $job.ApplyToTargetServer("$($TargetServer.Value)")
            }
            catch {
                Throw $_.Exception
            }
        }
        $job.Alter()
        $job.Refresh()
        Write-Verbose "SQL Agent Job $jobName updated successfully." -Verbose
        Return $job
    }
    catch {
        throw $_.Exception
    }
}