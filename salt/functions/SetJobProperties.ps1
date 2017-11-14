Function Set-JobProperties {
    <#
.Synopsis
Create or modify SQL Agent Job.
.Description
SQL Agent Job will be created or updated to match the settings in the xml file.
.Parameter JobToAlter
Job whose properties we will be altering.
.Example

#>
    [CmdletBinding()]
    param
    (
        [System.Xml.XmlLinkedNode]
        [ValidateNotNullorEmpty()]
        $root,
        [Microsoft.SqlServer.Management.Smo.Agent.Job]
        [ValidateNotNullorEmpty()]
        $JobToAlter,
        [Microsoft.SqlServer.Management.Smo.SqlSmoObject]
        [ValidateNotNullorEmpty()]
        $SmoObjectConnection
    )
    [string]$JobName = $root.Name
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
    Set-JobOwner -JobToAlter $JobToAlter -root $root -SmoObjectConnection $SmoObjectConnection
    try {
        $jobDescription = $root.Description
        $jobCategory = $root.Category.Value
        [bool]$JobEnabled = if ($root.Enabled -eq "True") {$True} else {$false} 
        $JobToAlter.description = $jobDescription
        $JobToAlter.IsEnabled = $JobEnabled
        $JobToAlter.Category = $jobCategory
        Write-Verbose "Updating Description, Category, Job Enabled Status..." -Verbose
        $JobToAlter.Alter()
        $JobToAlter.Refresh()
        $JobOperatorName = $root.Operator.Name
        if ($JobOperatorName.Length -gt 0) {
            Write-Verbose "Operator assigned to job. Altering notification settings based on XML..." -Verbose
            Set-JobNotification -JobToAlter $JobToAlter -root $root
        }
        else {
            Write-Verbose "No Operator Information to set." -Verbose
        }
        $TargetServersList = $JobToAlter.EnumTargetServers()
        foreach ($TargetServer in $TargetServers.ChildNodes) {
            if ($TargetServersList.ServerName -contains $TargetServer.Value) {
                $JobToAlter.RemoveFromTargetServer($TargetServer.Value)   
            }
            try {
                $JobToAlter.ApplyToTargetServer("$($TargetServer.Value)")
            }
            catch {
                Throw $_.Exception
            }
        }
        Write-Verbose "Applying target servers to job $jobName"
        $JobToAlter.Alter()
        $JobToAlter.Refresh()
        Write-Verbose "SQL Agent Job $jobName updated successfully." -Verbose
        Return $JobToAlter
    }
    catch {
        throw $_.Exception
    }
}