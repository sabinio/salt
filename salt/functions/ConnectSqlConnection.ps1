Function Connect-SqlConnection {
    <#
.Synopsis
create a connection to sql instance
.Description
Using sqldataclient.sqlconnection, create a connection to sql instance
return connection
.Parameter ConnectionString
The SQL Connection as a string that we use to make object SqlConnection
.Parameter IgnoreCheck
Ignores check in master database that SQL Agent Service is up and running 
.Parameter CheckPermissions
Checks permisions of the current user against instance of SQL being deployed to. 
.Example
Connect-SqlConnection -ConnectionString "Server=.;Integrated Security=True"
Connect-SqlConnection -ConnectionString "Server=.;Integrated Security=True" -IgnoreCheck
#>
    [CmdletBinding()]
    param
    (
        [string]
        [ValidateNotNullorEmpty()]
        $ConnectionString
    )
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString      
    try {
        $SqlSvr = New-Object Microsoft.SqlServer.Management.Smo.Server $SqlConnection
        foreach ($wargh in $SqlSvr.Databases) {
            # workaround for Connect Issue that is Closed: Won't Fix
            # https://connect.microsoft.com/SQLServer/feedback/details/636401/smo-is-inconsistent-when-raising-errors-for-login-faliures#
            # https://stackoverflow.com/questions/13072207/cant-get-powershell-to-handle-a-sql-server-connection-failure
            Write-Verbose $wargh.name | Out-Null
        }
        Write-Host "Name: " $SqlSvr.Name -ForegroundColor DarkGreen -BackgroundColor White
        Write-Host "Edition: " $SqlSvr.Edition -ForegroundColor DarkGreen -BackgroundColor White
        Write-Host "Build" $SqlSvr.BuildNumber -ForegroundColor DarkGreen -BackgroundColor White
        Write-Host "Version: " $SqlSvr.Version -ForegroundColor DarkGreen -BackgroundColor White
        Write-Host "ProductLevel: " $SqlSvr.ProductLevel -ForegroundColor DarkGreen -BackgroundColor White
        return $SqlSvr
    }
    catch {
        Write-Error $_.Exception
        Throw        
    }
}
   