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
    $jobCategory = $root.Category
    $ServerJobCategories = $SqlServer.JobServer.JobCategories | Select-Object -ExpandProperty Name
    if ($ServerJobCategories -notcontains $jobCategory) {
        $jc = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobCategory') ($SqlServer.JobServer, $jobCategory)
        try {
            $jc.Create()
            Write-Verbose "Job Category $jc created." -Verbose 
        }
        catch {
            throw $_.Exception
        }
        finally {
            Remove-Variable -Name "jc"
        }
    }
    else {
        Write-Verbose "There is already a Job Cateogry named $jobcategory " -Verbose
    }
}