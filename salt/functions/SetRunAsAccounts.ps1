Function Set-RunAsAccounts{
    param(
        [System.Xml.XmlLinkedNode]
        [ValidateNotNullorEmpty()]
        $root
    )
    $RunAsAccounts = @()
    $Steps = $root.Steps
    foreach ($step in $Steps.ChildNodes) {
        if ($Step.RunAs) {
            $RunAs = $Step.RunAs.Include
            if (Test-Path variable:$RunAs) {
                [string]$value = Get-Variable $RunAs -ValueOnly
                Write-Verbose ('Setting variable: {0} = {1}' -f $update, $value)
                foreach ($element in $step.SelectNodes("/Job/Steps/Step/RunAs") | Where-Object {$_.Include -eq $RunAs}) { 
                    $element.Name = $value
                }
            }
            else {
                throw ('RunAs Account is not set in the current scope for step {0} (but are defined in the xml): {1}' -f $StepName, $RunAs.Include)
            }
            $RunAsAccounts += $Step.RunAs.Name
        }
    }
    Return $RunAsAccounts
}