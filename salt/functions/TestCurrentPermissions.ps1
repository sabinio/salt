Function Test-CurrentPermissions{
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
    Write-Host "Yea boy!" -ForegroundColor Green -BackgroundColor DarkMagenta
    $script = "SELECT IS_SRVROLEMEMBER('sysadmin') as 'AmISysAdmin';"
    $SQLSysAdminPermissions = $SqlInstance.ConnectionContext.ExecuteScalar($script)
    if ($SQLSysAdminPermissions -eq 1)
    {
        Write-Verbose "user is sysadmin on instance. No further checks required!" -Verbose
        return
    }
    elseif($SQLSysAdminPermissions -eq 0)
    {
        Write-Verbose "user is not a member of the sysadmin sesrver role. Checking minimal permissions"
        # /*
        # USE msdb
        # CREATE USER [asdf] FOR LOGIN [asdf]
        # GO 
        # GRANT SELECT ON dbo.sysschedules  TO [asdf]
        # GRANT SELECT ON dbo.sysjobschedules  TO [asdf]
        # GRANT SELECT ON dbo.sysjobs  TO [asdf]
        # exec sp_addrolemember  @rolename = 'SQLAgentOperatorRole',  
        #      @membername = 'asdf'  
        # use master
        # GO
        
        # CREATE USER [asdf] FOR LOGIN [asdf]
        # GO
        # GRANT SELECT ON master.dbo.sysprocesses  TO [asdf]
        
        # GRANT VIEW SERVER STATE TO [asdf]
        
        
        # */
    }
    else{
        Write-Error "Unable to check permisions."
        Throw
    }

}