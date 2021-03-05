

Function Test-SQLServerAgentService {
    <#
.Synopsis
Test SQL Server Agent Service is Running
.Description
Test that SQL Server Agent Service is running on instance. Requires permission to connect to master database and read data.
.Parameter SqlServer
The SQL Connection as a string that we use to make object SqlConnection
.Example
Test-SQLServerAgentService -SqlServer $sqlSvr
#>
    [CmdletBinding()]
    param
    (   
        [Microsoft.SqlServer.Management.Smo.SqlSmoObject]
        [ValidateNotNullorEmpty()]
        $SqlServer
    )
    $db = $SqlServer.Databases.Item("master")
    $ds = $db.ExecuteWithResults("IF EXISTS (  SELECT 1 
                                    FROM master.dbo.sysprocesses 
                                    WHERE program_name = N'SQLAgent - Generic Refresher')
                                    BEGIN
                                        SELECT 1 AS 'SQLServerAgentRunning'
                                    END
                                    ELSE 
                                    BEGIN
                                        SELECT 0 AS 'SQLServerAgentRunning'
                                    END"
    )
    $SQLServerAgentRunning = $ds.Tables[0].Rows[0]."SQLServerAgentRunning"
    if ($SQLServerAgentRunning -eq 1) {
        Write-Verbose "SQL Server Agent Job Service on $($SqlSvr.JobServer.Name) Is Up And Running!"
    }
    elseif ($SQLServerAgentRunning -eq 0) {
        Write-Error "Check that the Agent Service is running on $($sqlSvr.JobServer) and try again."
        Throw
    }
    else {
        Write-Warning "Unable to check that the Agent Service is running on $($sqlSvr.JobServer). This may be a permissions issue on master.dbo.sysprocesses."
    }
}
