Function Set-JobOwner {
    <#
.Synopsis
Sets SQL Agent Job Owner.
.Description
Set the owner of the SQL Agent Job. If owner in xml is left blank job will set account running the deploy as owner of job.
Changing ownership of a job requires sysadmin permissions.
.Parameter JobToAlter
Job whose properties we will be altering.
.Parameter SmoObjectConnection
Connectio nto instance so we cna check if account running PowerShell has sysadmin permissions
.Example
Set-JobOwner -JobToAlter $JobToAlter -root $root -SmoObjectConnection $SmoObjectConnection
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
    [string]$jobOwner = $root.Owner
    $domain = [Environment]::UserDomainName
    $uname = [Environment]::UserName
    [string]$whoAmI = "$domain\$uname"
    if ([string]::IsNullOrEmpty($jobOwner)) {
        Write-Verbose 'Parameter jobOwner not included in XML document. Setting account running this task as owner of job. This requires sysadmin permissions.' -Verbose
        $jobOwner = $whoAmI 
    }
    $db = $SmoObjectConnection.Databases.Item("msdb")
    $ds = $db.ExecuteWithResults("SELECT IS_SRVROLEMEMBER('sysadmin') as 'AmISysAdmin';")
    $AmISysAdmin = $ds.Tables[0].Rows[0]."AmISysAdmin"
    if ($AmISysAdmin -eq 1) {
        Write-Verbose "$whoAmI is sysadmin on instance, so job owner can be altered." -Verbose
        try {
            $JobToAlter.OwnerLoginName = $jobOwner
            Write-Verbose "Updating Job Owner to $jobOwner..." -Verbose
            $JobToAlter.Alter()
            $JobToAlter.Refresh()
        }
        catch {
            throw $_.Exception
        }
    }
    elseif ($AmISysAdmin -eq 0) {
        Write-Verbose "$whoAmI is NOT a sysadmin on the instance, job owner CANNOT be altered." -Verbose
    }
    else {
        Write-Warning "Unable to check whether or not user is sysadmin on the instance."
    }
}