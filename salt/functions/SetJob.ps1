Function Set-Job {
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
        $root,
        [Switch]
        $dropAndRecreate
    )
    [string]$JobName = $root.Name
    $serverJobs = $sqlserver.JobServer.Jobs | Select-Object -ExpandProperty Name
    $job = new-object ('Microsoft.SqlServer.Management.Smo.Agent.Job') ($SqlServer.JobServer, $jobName)
    if ($serverJobs -contains $jobName){
        if($dropAndRecreate){
            Write-Verbose "Dropping and re-creating $jobName from $($SqlServer.JobServer)" -Verbose
            try {
                $jobDrop = $SqlServer.JobServer.Jobs | Where-Object {$_.Name -eq $JobName}
                $jobDrop.Drop()
                Remove-Variable -Name JobDrop
                Write-Verbose "$JobName dropped from $($SqlServer.JobServer)" -Verbose
                $job.Create()
                $job.Refresh()
                Write-Verbose "SQL Agent Job $jobName created successfully." -Verbose
            }
            catch {
                throw $_.Exception
            }
        }
    }
    if ($serverJobs -notcontains $jobName) {
        try {
            $job.Create()
            $job.Refresh()
            Write-Verbose "SQL Agent Job $jobName created successfully." -Verbose
        }
        catch {
            throw $_.Exception
        }
    }
    $Job = Get-Job -SqlServer $SqlServer -root $root
    $job.Refresh()
    Set-JobProperties -root $root -JobToAlter $job -SmoObjectConnection $SqlServer
}