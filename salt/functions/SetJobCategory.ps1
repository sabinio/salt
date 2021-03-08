Function Set-JobCategory {
      <#
.Synopsis
Create or modify SQL Agent Job Category.
.Description
SQL Agent Job Category will be created or updated to match the settings in the xml file.
.Parameter sqlServer
The SQL Connection that SQL Agent Job Category is on/will be created on.
.Parameter root
The XML Object
.Example
$JobManifestXmlFile = "C:\Reports\Our_First_Job.xml"
[xml] $_xml = [xml] (Get-Content -Path $JobManifestXmlFile)
$x = Get-Xml -XmlFile $_xml
Set-JobCategory -SqlServer $SqlConnection -root $x
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
    $keys = $($root.Category)
    foreach ($var in $keys) {
        $update = $var.Include
        if (Test-Path variable:$update) {
            [string]$value = Get-Variable $update -ValueOnly
            Write-Verbose ('Setting category: {0} = {1}' -f $update, $value)
            $element = $root.SelectNodes("/Job/Category") | Where-Object {$_.Include -eq $update} 
            $element.Value = $value
        }
        else {
            $missingVariables += $update
        }
    }
    if ($missingVariables.Count -gt 0) {
        throw ('The variable {0} for Job Category is not defined in the current scope (but is defined in the xml). ' -f ($missingVariables -join " `n"))
    }
    $jobCategory = $root.Category.Value
    $ServerJobCategories = $SqlServer.JobServer.JobCategories | Select-Object -ExpandProperty Name
    if ($ServerJobCategories -notcontains $jobCategory) {
        $jc = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobCategory') ($SqlServer.JobServer, $jobCategory)
        try {
            $jc.Create()
            Write-Verbose "Job Category $jc created." 
        }
        catch {
            throw $_.Exception
        }
        finally {
            Remove-Variable -Name "jc"
        }
    }
    else {
        Write-Verbose "There is already a Job Cateogry named $jobcategory "
    }
}