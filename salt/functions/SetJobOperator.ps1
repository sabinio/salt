Function Set-JobOperator {
    <#
.Synopsis
Create or modify SQL Agent Job Operator.
.Description
SQL Agent Job Operator will be created or updated to match the settings in the xml file.
.Parameter sqlServer
The SQL Connection that SQL Agent Job Opertor is on/will be created on.
.Parameter root
The XML Object
.Example
$JobManifestXmlFile = "C:\Reports\Our_First_Job.xml"
[xml] $_xml = [xml] (Get-Content -Path $JobManifestXmlFile)
$x = Get-Xml -XmlFile $_xml
Set-JobOperator -SqlServer $SqlConnection -root $x
#>
    [CmdletBinding()]
    param
    (
        [Microsoft.SqlServer.Management.Smo.SqlSmoObject]
        [ValidateNotNullorEmpty()]
        $SqlServer,
        [System.Xml.XmlLinkedNode]
        [ValidateNotNullorEmpty()]
        $root
    )
    $JobOperatorName = $root.Operator.Name
    if ($JobOperatorName.Length -eq 0)
    {
        Write-Verbose "No Operator Info in XML" -Verbose
        Return
    }
    $JobOperatorEMail = $root.Operator.EMail
    $JobOperatorPage = $root.Operator.Page
    $JobOperatorNetSend = $root.Operator.NetSend
    $ServerJobOperators = $SqlServer.JobServer.Operators | Select-Object -ExpandProperty Name
    if ($ServerJobOperators -notcontains $JobOperatorName) {
        $op = New-Object ('Microsoft.SqlServer.Management.Smo.Agent.Operator') ($SqlServer.JobServer, $JobOperatorName)
        if (![String]::IsNullOrEmpty($JobOperatorEmail)) {
            $op.EmailAddress = $JobOperatorEmail
        }
        if (![String]::IsNullOrEmpty($JobOperatorPage)) {
            $op.PagerAddress = $JobOperatorPage
        }
        if (![String]::IsNullOrEmpty($JobOperatorNetSend)) {
            $op.NetSendAddress = $JobOperatorNetSend
        }
        try {
            $op.Create()
            Write-Verbose "Job Operator $op created." -Verbose
        }
        catch {
            throw $_.Exception
        }
        finally {
            Remove-Variable -Name "op"    
        }
    }

    else {
        try {
            $op = $SqlServer.JobServer.Operators[$JobOperatorName]
            $op.EmailAddress = $JobOperatorEmail
            $op.Alter()
            Write-Verbose "Job Operator Email Address Updated."
        }
        catch {
            throw $_.Exception
        }
        finally {
            Remove-Variable -Name "op"    
        }
    }
}