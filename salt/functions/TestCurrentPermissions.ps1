Function Test-CurrentPermissions {
    <#
.Synopsis
Test permissions of current user to verify that htey have the correct permissions to execute deployment.
.Description
Check that the account running the deployment has the correct permissions to successfully execute a deployment.
If an account is sysadmin then this is very straightforward.
If account is not sysadmin then we check that the minimal permissions have been granted. Consult the readme for list of permisions, or view the SQLbelow.
.Parameter sqlInstance
The SQL Instance we are deploying to.
.Example
Test-CurrentPermissions -SqlInstance $SqlSvr
#>
    param(
        [Microsoft.SqlServer.Management.Smo.SqlSmoObject]
        [ValidateNotNullorEmpty()]
        $SqlInstance
    )
    $missingPermissions = @()
    Write-Host "Yea boy!" -ForegroundColor Green -BackgroundColor DarkMagenta
    $script = "SELECT IS_SRVROLEMEMBER('sysadmin') as 'AmISysAdmin';"
    $SQLSysAdminPermissions = $SqlInstance.ConnectionContext.ExecuteScalar($script)
    if ($SQLSysAdminPermissions -eq 1) {
        Write-Verbose "user is sysadmin on instance. No further checks required!" -Verbose
        return
    }
    elseif ($SQLSysAdminPermissions -eq 0) {
        Write-Verbose "user is not a member of the sysadmin sesrver role. Checking minimal permissions" -Verbose
        $db = $SqlInstance.Databases.Item("msdb")
        $ds = $db.ExecuteWithResults("
        SELECT 'sysschedules' as 'permissions' FROM fn_my_permissions('sysschedules', 'OBJECT') 
        WHERE subentity_name = ''
        AND permission_name = 'SELECT'
        ")
        if ($ds.Tables[0].Rows[0]."permissions" -ne 'sysschedules') {
            $missingPermissions += 'GRANT SELECT ON msdb.dbo.sysschedules'
        }
        $db = $SqlInstance.Databases.Item("msdb")
        $ds = $db.ExecuteWithResults("
        SELECT 'sysjobschedules' as 'permissions' FROM fn_my_permissions('sysjobschedules', 'OBJECT') 
        WHERE subentity_name = ''
        AND permission_name = 'SELECT'
        ")
        if ($ds.Tables[0].Rows[0]."permissions" -ne 'sysjobschedules') {
            $missingPermissions += 'GRANT SELECT ON msdb.dbo.sysjobschedules'
        }
        $db = $SqlInstance.Databases.Item("msdb")
        $ds = $db.ExecuteWithResults("
        SELECT 'sysjobs' as 'permissions' FROM fn_my_permissions('sysjobs', 'OBJECT') 
        WHERE subentity_name = ''
        AND permission_name = 'SELECT'
        ")
        if ($ds.Tables[0].Rows[0]."permissions" -ne 'sysjobs') {
            $missingPermissions += 'GRANT SELECT ON msdb.dbo.sysjobs'
        }
        $db = $SqlInstance.Databases.Item("master")
        $ds = $db.ExecuteWithResults("
        SELECT 'sysprocesses' as 'permissions' FROM fn_my_permissions('sysprocesses', 'OBJECT') 
        WHERE subentity_name = ''
        AND permission_name = 'SELECT'
        ")
        if ($ds.Tables[0].Rows[0]."permissions" -ne 'sysprocesses') {
            $missingPermissions += 'GRANT SELECT ON master.dbo.sysprocesses'
        }
        $db = $SqlInstance.Databases.Item("master")
        $ds = $db.ExecuteWithResults("SELECT IS_ROLEMEMBER('SQLAgentOperatorRole') AS 'SQLAgentOperatorRole';")
        if ($ds.Tables[0].Rows[0]."SQLAgentOperatorRole" -ne 1) {
            $missingPermissions += 'sp_addrolemember @rolename = "SQLAgentOperatorRole"'
        }
        $db = $SqlInstance.Databases.Item("master")
        $ds = $db.ExecuteWithResults("SELECT HAS_PERMS_BY_NAME(null, null, 'VIEW SERVER STATE') AS 'ViewServerState';")
        if ($ds.Tables[0].Rows[0]."ViewServerState" -ne 1) {
            $missingPermissions += 'GRANT VIEW SERVER STATE'
        }
        if ($missingPermissions.Count -gt 0) {
            Throw ("The following permissions need to be granted to the account running the PowerShell on the instance being deployed to `n{0}" -f ($missingPermissions -join " `n"))
        }
    }
    else {
        Throw "Unable to check permisions."
    }
}