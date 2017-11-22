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
    Write-Verbose "Job Owner in XML is $jobOwner" -Verbose
    Write-Verbose "Job Owner on Server is $($JobToAlter.OwnerLoginName)" -Verbose
    if ($jobOwner -eq $JobToAlter.OwnerLoginName) {
        Write-Verbose "Job Owner in XML matches Server. Not attempting to alter." -Verbose
        Return
    }
    else {
        $db = $SmoObjectConnection.Databases.Item("msdb")
        $ds = $db.ExecuteWithResults("SELECT IS_SRVROLEMEMBER('sysadmin') as 'AmISysAdmin';")
        $AmISysAdmin = $ds.Tables[0].Rows[0]."AmISysAdmin"
        if ($AmISysAdmin -eq 1) {
            Write-Verbose "$whoAmI is sysadmin on instance, so job owner can be altered." -Verbose
            try {
                Write-Verbose "owner of Agent Job is$($JobToAlter.OwnerLoginName)"
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
            Throw "$whoAmI is NOT a sysadmin on the instance, so job owner CANNOT be altered. Either set account running PowerShell to be sysadmin or alter Job Owner outside of this PowerShell Module."
        }
        else {
            Write-Warning "Unable to check whether or not user is sysadmin on the instance."
        }
    }
}