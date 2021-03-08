Function Set-IscVariables {
    <#
.Synopsis  
Updates a step that has the subsystem ssis
.Description
Updates a step if a hash table with the matching name as the "include" attribute in the job step exists.
Will update only what exists in the hastable; so if folder is different then only folder will be updated.
This means one hash table per step. 
.Parameter ssisStep
The step that execustes a dtsx package.
.Example
See "SetJobSteps.ps1" for working example.
 if ($step.SubSystem -eq "Ssis") {
Set-IscVariables -SsisStep $Step
 }
#>
    [CmdletBinding()]
    param
    (
        [ValidateNotNullorEmpty()]
        $ssisStep
    )
        $update = $ssisStep.SsisServerDetails.Include
        if (Test-Path variable:$update) { 
            $currentVar2 = @{} 
            $currentVar = Get-Variable $update -valueOnly 
            if ($currentVar.GetType().Name -ne "HashTable") {
                #what is going on here?!
                #Octopus Deploy turns all variables into strings. 
                #We need a hash table.
                #String variable splits on ';' to create pairs, then on '=' to create the key and the value
                $currentVar.Split(';') |ForEach-Object {
                    $key, $value = $_.Split('=')
                    $currentVar2[$key] = $value
                }
            } 
            else {
                $currentVar2 = $currentVar
            }
            $element = $steps.SelectNodes("/Job/Steps/Step/SsisServerDetails") | Where-Object {$_.Include -eq $currentVar2.SsisServerDetails} 
            if ($null -ne $currentVar2.SsisServerCatalog) {
                $element.SsisServerCatalog = $currentVar2.SsisServerCatalog
            }
            if ($null -ne $currentVar2.SsisServerCatalogFolder) {
                $element.SsisServerCatalogFolder = $currentVar2.SsisServerCatalogFolder
            }
            if ($null -ne $currentVar2.SsisServerCatalogEnvironment) {
                $element.SsisServerCatalogEnvironment = $currentVar2.SsisServerCatalogEnvironment
            }
            if ($null -ne $currentVar2.SsisServerCatalogProject) {
                $element.SsisServerCatalogProject = $currentVar2.SsisServerCatalogProject
            }
            if ($null -ne $currentVar2.SsisServerCatalogPackage) {
                $element.SsisServerCatalogPackage = $currentVar2.SsisServerCatalogPackage
            }
            Write-Verbose "SSIS Server Details for Job Step $($element.Include) updated."
            Return $ssisStep
        }
        else {
            Write-Verbose "SSIS Server Details for Job Step $($update) unchanged."
            Write-Verbose $ssisStep.SsisServerDetails.SsisServerCatalogFolder
            Return $ssisStep
        }
    }
    #Write-Verbose $ssisStep.Job.Steps.Step.SsisServerDetails