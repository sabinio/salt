

Function Test-SQLServerAgentService {
    <#
.Synopsis
Test SQL Server Agent Service is Running
.Description
Test that SQl Server 
.Parameter ConnectionString
The SQL Connection as a string that we use to make object SqlConnection
.Example
Connect-SqlConnection -ConnectionString "Server=.;Integrated Security=True"
#>
    [CmdletBinding()]
    param
    (   
        [Microsoft.SqlServer.Management.Smo.SqlSmoObject]$SmoObjectConnection
    )
   $db =  $SmoObjectConnection.Databases.Item("master")
    $ds = $db.ExecuteWithResults("IF EXISTS (  SELECT 1 
                                    FROM master.dbo.sysprocesses 
                                    WHERE program_name = N'SQLAgent - Generic Refresher')
                                    BEGIN
                                        SELECT  1 AS 'SQLServerAgentRunning'
                                    END
                                    ELSE 
                                    BEGIN
                                        SELECT  0 AS 'SQLServerAgentRunning'
                                    END"
)
$SQLServerAgentRunning = $ds.Tables[0].Rows[0]."SQLServerAgentRunning"
Return $SQLServerAgentRunning
}
