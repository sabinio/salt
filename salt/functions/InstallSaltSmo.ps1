

function Install-SaltSmo {
     <#
.SYNOPSIS
Install Microsoft.SQLServer.SMO from NuGet
.DESCRIPTION
Installs Microsoft.SQLServer.SMO into a folder path, optionally using NuGet that is already preinstalled.
.PARAMETER WorkingFolder
Mandatory - Location of where NuGet package is to be installed.
.PARAMETER  NuGetPath
Optional - Can use NuGet already installed or leave blank to downloadNuGet from the internet.   
.INPUTS
N/A
.OUTPUTS
Directory of Nuget package.
.NOTES
  N/A
#>
    [cmdletbinding()]
    param ( 
        [parameter(Mandatory)]
        [string] $WorkingFolder, 
        [string] $NuGetPath
    )
    Write-Verbose "Verbose Folder : $WorkingFolder" -Verbose
    Write-Verbose "DataToolsVersion : $DataToolsMsBuildPackageVersion" -Verbose 
    Write-Warning "If DataToolsVersion is blank latest will be used"
    if ($PSBoundParameters.ContainsKey('NuGetPath') -eq $false) {
        $NuGetExe = Install-SaltNuGet -WorkingFolder $WorkingFolder
    }
    else {
        Write-Verbose "Skipping Nuget download..." -Verbose
        $NuGetExe = Join-Path $NuGetPath "nuget.exe"
        if (-not (Test-Path $($NuGetExe))) {
            Throw "NuGetpath specified, but nuget exe does not exist!"
        }
    }
    $nugetArgs = @("install","Microsoft.SQLServer.SMO","-ExcludeVersion","-OutputDirectory",$WorkingFolder)
    Write-Host $nugetExe ($nugetArgs -join " ") -BackgroundColor White -ForegroundColor DarkGreen
    &$nugetExe $nugetArgs  2>&1 | Out-Host
    $MicrosoftSQLServerSMOLibrary20 = "$WorkingFolder\Microsoft.SQLServer.SMO\lib\Microsoft.SqlServer.Smo.dll"
    if (-not (Test-Path $MicrosoftSQLServerSMOLibrary20)) {
            Throw "It appears that the nuget install hasn't worked, check output above to see whats going on."
    }
        return $MicrosoftSQLServerSMOLibrary20
}

