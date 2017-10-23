function Get-Xml {
         <#
.Synopsis
Return XML object
.Description
Input xml content, output xml object.
.Parameter xmlFile
The xml.
.Example
$JobManifestXmlFile = "C:\Reports\Our_First_Job.xml"
[xml] $_xml = [xml] (Get-Content -Path $JobManifestXmlFile)
$x = Get-Xml -XmlFile $_xml
#>
        [CmdletBinding()]
    param
    (
        [xml]
        [ValidateNotNullOrEmpty()]
        $XmlFile
    )
    try {
        [System.Xml.XmlElement] $xml = $xmlFile.get_DocumentElement()
        return $xml
    }
    catch {
        throw $_.Exception
    }
}