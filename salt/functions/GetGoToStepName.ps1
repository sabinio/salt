Function Get-GoToStepName {
      <#
.Synopsis
Get the Name of the Job Step that SQL Agent Job will go to on success/fail.
.Description
Using job step id, get the job step name from the properties and return.
.Parameter JobObject
SQL Agent Job that exists on the SQL Server Instance.
.Parameter StepId
The id of the job step that job will go to on success/onfail.
.Example
Redacted example. Please see GetSqlAgentAsXml.ps1 for full example.
 if ($step.OnSuccessAction -eq "GoToStep") {
                $OnSuccessGoToStepName = Get-GoToStepName -JobObject $job -StepId $step.OnSuccessStep
                $xmlWriter.WriteElementString("OnSuccessStep", "$($OnSuccessGoToStepName)")
            }
            $xmlWriter.WriteElementString("OnFailAction", "$($step.OnFailAction)")
            if ($step.OnFailAction -eq "GoToStep") {
                $OnFailGoToStepName = Get-GoToStepName -JobObject $job -StepId $step.OnFailStep
                $xmlWriter.WriteElementString("OnFailStep", "$($OnFailGoToStepName)")
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
        $StepId
    )
    $GoToJobStepProperties = $JobObject.JobSteps | Where-Object {$_.Id -eq $StepId}
    $JobStepName = $GoToJobStepProperties.Name
    return $JobStepName
}