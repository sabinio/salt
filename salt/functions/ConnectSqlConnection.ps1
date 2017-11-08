Function Connect-SqlConnection {
    <#
.Synopsis
create a connection to sql instance
.Description
Using sqldataclient.sqlconnection, create a connection to sql instance
return connection
.Parameter ConnectionString
The SQL Connection as a string that we use to make object SqlConnection
.Example
Connect-SqlConnection -ConnectionString "Server=.;Integrated Security=True"
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
            Write-Verbose $wargh.name | Out-Null
        }
        Write-Host "Name: " $SqlSvr.Name
        Write-Host "Edition: " $SqlSvr.Edition
        Write-Host "Build" $SqlSvr.BuildNumber
        Write-Host "Version: " $SqlSvr.Version
        Write-Host "ProductLevel: " $SqlSvr.ProductLevel
    }
    catch {
        Write-Error $_.Exception
        Throw
    }
    $JobServerExists = Test-SQLServerAgentService  -SmoObjectConnection $SqlSvr
    if ($JobServerExists -eq 1) {
        Write-Verbose "Job Server Is Up And Running!" -Verbose
        return $SqlSvr
    }
    else {
        Write-Error "Check that the Agent Service is running on $($sqlSvr.JobServer) and try again." -Verbose
        Throw
    }
}
   