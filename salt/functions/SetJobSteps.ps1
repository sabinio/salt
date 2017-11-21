Function Set-JobSteps {
    <#
.Synopsis
Delete steps of a SQL Agent Job and re-create.
.Description
Steps for SQL Agent Job will be deleted and re-created to match the settings in the xml file.
.Parameter sqlServer
The SQL Connection that SQL Agent Job is on.
.Parameter root
The XML Object
.Example
$SqlConnectionString = "data source = .; initial catalog = master; trusted_connection = true;"
$JobManifestXmlFile = "C:\Reports\Our_First_Job.xml"
$SqlConnection = Connect-SqlConnection -ConnectionString $SqlConnectionString
[xml] $_xml = [xml] (Get-Content -Path $JobManifestXmlFile)
$x = Get-Xml -XmlFile $_xml
$sqlAgentJob = Set-Job -SqlServer $SqlConnection -root $x
Set-JobSteps -SqlServer $SqlConnection -root $x -job $SqlAgentJob 
Disconnect-SqlConnection -SqlDisconnect $SqlConnection
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
        [Microsoft.SqlServer.Management.Smo.Agent.AgentObjectBase]
        [ValidateNotNullorEmpty()]
        $job
    )
    #clear steps and always re-create
    $job.RemoveAllJobSteps()
    $job.Refresh()
    #re-create steps; defaults for properties are created at first
    $Steps = $root.Steps
    foreach ($step in $Steps.ChildNodes) {
        try {
            $StepName = $step.Name
            $JobStep = New-Object ('Microsoft.SqlServer.Management.Smo.Agent.JobStep') ($job, $StepName)
            $JobStep.Create()
            Write-Verbose "Blank step $StepName Created" -Verbose
            $job.Refresh()
        }
        catch {
            throw $_.Exception
        }
        finally {
            if ($null -ne $JobStep) {
                Remove-Variable -Name "JobStep"
            }
        }
    }
    foreach ($step in $Steps.ChildNodes) {
        #Question: huh? Why re-enter the loop? 
        #Answer: We need to create all job steps up front so that we can set on success or on fail accordingly
        #eg if step succeeds and user wants to use "GoToStep" on Action, then have to get ID of step they want to go to from "OnSuccessStep"
        #same applies to Failures {
        try {
            $JobStep_Properties = $job.JobSteps | Where-Object {$_.Name -eq $step.Name}
            $StepName = $Step.Name
            $JobStep_Properties.SubSystem = $step.SubSystem
            if ($Step.RunAs) {
                $RunAs = $Step.RunAs.Include
                if (Test-Path variable:$RunAs) {
                    [string]$value = Get-Variable $RunAs -ValueOnly
                    Write-Verbose ('Setting variable: {0} = {1}' -f $update, $value) -Verbose
                    foreach ($element in $step.SelectNodes("/Job/Steps/Step/RunAs") | Where-Object {$_.Include -eq $RunAs}) { 
                        $element.Name = $value
                    }
                }
                else {
                    throw ('RunAs Account is not set in the current scope for step {0} (but are defined in the xml): {1}' -f $StepName, $RunAs.Include)
                }
                $JobStep_Properties.ProxyName = $Step.RunAs.Name
            }
            if ($step.OnSuccessAction -eq "GoToStep") {
                $OnSuccessGoToStepId = Get-GoToStepId -JobObject $job -GoToJobStep $step.OnSuccessStep
                $JobStep_Properties.OnSuccessAction = $step.OnSuccessAction
                $JobStep_Properties.OnSuccessStep = $OnSuccessGoToStepId
            }
            else {
                $JobStep_Properties.OnSuccessAction = $step.OnSuccessAction
            }
            if ($step.OnFailAction -eq "GoToStep") {
                $OnFailGoToStepId = Get-GoToStepId -JobObject $job -GoToJobStep $step.OnFailStep
                $JobStep_Properties.OnFailAction = $step.OnFailAction
                $JobStep_Properties.OnFailStep = $OnFailGoToStepId
            }
            else {
                $JobStep_Properties.OnFailAction = $step.OnFailAction
            }
            $JobStep_Properties.RetryAttempts = $step.RetryAttempts
            $JobStep_Properties.RetryInterval = $step.RetryInterval
           
            if ($step.SubSystem -eq "Ssis") {
                Write-Verbose "Setting SSIS Server for step."
                $keys = $($step.SsisServer)
                foreach ($var in $keys) {
                    $update = $var.Include
                    if (Test-Path variable:$update) {
                        [string]$value = Get-Variable $update -ValueOnly
                        Write-Verbose ('Setting variable: {0} = {1}' -f $update, $value) -Verbose
                        foreach ($element in $step.SelectNodes("/Job/Steps/Step/SsisServer") | Where-Object {$_.Include -eq $update}) { 
                            $element.Name = $value
                        }
                    }
                    else {
                        $missingVariables += $update
                    }
                }
                if ($missingVariables.Count -gt 0) {
                    throw ('Ssis Server is not set in the current scope (but are defined in the xml): {0}' -f ($missingVariables -join " `n"))
                }
                $thisSsisServer = $step.SsisServer.Name
                $step = Set-IscVariables -SsisStep $Step
                Write-Verbose "Step $stepName is a Ssis step. Connecting to SSIS Instance to verify the catalog exists. If it does will assume everything else required exists." -Verbose
                $script = "SELECT 'exists'
                FROM ssisdb.CATALOG.folders folder
                INNER JOIN ssisdb.CATALOG.projects project on project.folder_id = folder.folder_id
                WHERE folder.NAME = '$($Step.SsisServerDetails.SsisServerCatalogFolder)'
                AND project.name = '$($Step.SsisServerDetails.SsisServerCatalogProject)'"
                $checkSsisExists = $SqlServer.ConnectionContext.ExecuteScalar($script)
                # if ($checkSsisExists -ne "exists") {
                #     $msg = "Either Folder " + $Step.SsisServerDetails.SsisServerCatalogFolder + " or Project " + $Step.SsisServerDetails.SsisServerCatalogProject + " does not exist. Cannot fill variables for ssisCommand correctly. Please deploy all SSIS Projects first "
                #     Write-Verbose $msg -Verbose
                #     Throw $msg;
                # }
                $script = "SELECT er.reference_id
                FROM ssisdb.CATALOG.environment_references er
                INNER JOIN ssisdb.CATALOG.projects p ON p.project_id = er.project_id
                WHERE er.environment_name = '$($Step.SsisServerDetails.SsisServerCatalogEnvironment)'
                    AND p.NAME = '$($Step.SsisServerDetails.SsisServerCatalogProject)'"
                Write-Host $script
                try {
                    $environmentReference = $SqlServer.ConnectionContext.ExecuteScalar($script) 
                }
                catch {
                    throw $_.Exception
                }
                try {
                    $ssisCommand = @"
                    /ISSERVER "\"\SSISDB\$($Step.SsisServerDetails.SsisServerCatalogFolder)\$($Step.SsisServerDetails.SsisServerCatalogProject)\$($Step.SsisServerDetails.SsisServerCatalogPackage)\"" /SERVER "$($thisSsisServer)" /ENVREFERENCE $environmentReference /Par "\"`$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"`$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E
"@ 
                    Write-Host "This is the ssiscommand"
                    Write-Host $ssisCommand 
                    $JobStep_Properties.Command = $ssisCommand
                }
                catch {
                    throw $_.Exception
                }   
            }
            else {
                $JobStep_Properties.Command = $step.Command
            }
            $JobStep_Properties.Alter()
            $JobStep_Properties.Refresh()
            Write-Verbose "Successfully Updated properties for Step $StepName." -Verbose
        }
        catch {
            throw $_.Exception
        }
        finally {
            if ($null -ne $JobStep) {
                Remove-Variable -Name "JobStep"
                Remove-Variable -Name "JobStep_Properties"
            }
        }
    }
}