Function Disconnect-SqlConnection {
     <#
.Synopsis
Disconnect from SQL Instance
.Description
Disconnect a sqldataclient.sqlconnection
.Parameter SqlDisconnect
The SQL Connection to disconnect
.Example
Disconnect-SqlConnection -SqlDisconnect $myConnection
#>
    [CmdletBinding()]
    param
    (   [Microsoft.SqlServer.Management.Smo.SqlSmoObject]
        [ValidateNotNullorEmpty()]
        $SqlDisconnect
    )
    try {
        $SqlDisconnect.ConnectionContext.Disconnect()
    }
    catch {
        throw $_.Exception
    }
}