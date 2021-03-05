Function Get-Job {
    <#
.Synopsis
Create or modify SQL Agent Job.
.Description
SQL Agent Job will be created or updated to match the settings in the xml file.
.Parameter sqlServer
The SQL Connection that SQL Agent Job is on/will be created on.
.Parameter root
The XML Object
.Example
$JobManifestXmlFile = "C:\Reports\Our_First_Job.xml"
[xml] $_xml = [xml] (Get-Content -Path $JobManifestXmlFile)
$x = Get-Xml -XmlFile $_xml
$sqlAgentJob = Set-Job -SqlServer $SqlConnection -root $x

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
    [string]$JobName = $root.Name
    $job = new-object ('Microsoft.SqlServer.Management.Smo.Agent.Job')
    try {
        $job = $SqlServer.JobServer.Jobs | Where-Object {$_.Name -eq $JobName}
        if ($null -eq $job) {
            Write-Warning "Job does not exist. This may be because this is the first run and job is not yet deployed."
            Return $null
        }
        else {
            Write-Verbose "$($Job.Name) found."
            return $job
        }
    }
    catch {
        $_.Exception    
    }    
}