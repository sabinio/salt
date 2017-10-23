Function Get-GoToStepId {
         <#
.Synopsis
Get the Id of the Job Step that SQl Agent Job will go to on success/ fail.
.Description
Using job step name, get the job step id from the properties and return.
.Parameter JobObject
SQL Agent Job that exists on the SQL Server Instance.
.Parameter GoToJobStep
The name of the job step that job will go to on success/onfail. This is stored in the SQL Agent XML file.
.Example
Redacted example. Please see SetJobSteps.ps1 for full example.
 $JobStep_Properties = $job.JobSteps | Where-Object {$_.Name -eq $step.Name}
            $StepName = $Step.Name
            $JobStep_Properties.SubSystem = $step.SubSystem
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
#>
    [CmdletBinding()]
    param
    (
        [ValidateNotNullorEmpty()]
        [Microsoft.SqlServer.Management.Smo.Agent.AgentObjectBase]
        $JobObject,
        [ValidateNotNullorEmpty()]
        [string]
        $GoToJobStep
    )
    $GoToJobStepProperties = $JobObject.JobSteps | Where-Object {$_.Name -eq $GoToJobStep}
    $JobStepId = $GoToJobStepProperties.Id
    return $JobStepId
}