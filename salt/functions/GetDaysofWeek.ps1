Function Get-DaysofWeek {
    <#
.Synopsis
Takes a list of numbers and creates a string list of the days of the week based off the values contained within the numbered list.  
.Description
Once we have figured out the rnge of numbers that the sql agent frequency interval is representing, we then need to figure out what those relative days of the week are.
This is based off the frequency type being weekly. Refer to MSDN page below for values.
https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.agent.jobschedule.frequencyinterval.aspx
.Parameter Enum
Integer list of bit flags that is used to represent the days of the week in SQL Agent.
.Example
Refer to GetSqlAgentAsXml.ps1 for full example. Here is a redacted version:
if ($serverJobSchedule.Frequencytypes -eq "Weekly") {
                $range = 1, 2, 4, 8, 16, 32, 62, 64, 65, 127
                $combi = Get-SumUp -numbers $range -target $serverJobSchedule.FrequencyInterval
                if ($combi.part.count -gt 1) {
                    [string[]]$combo = $combi.part[-1].Split()
                }
                else {
                    [string[]]$combo = $combi.part.Split()
                }
                [int[]]$combee = [int[]]$combo
                $WeeklyFrequencyInterval = Get-DaysOfWeek -enum $combee
                }
#>
    [CmdletBinding()]
    param
    (
        [System.Collections.Generic.List[Int]]
        [ValidateNotNullorEmpty()]
        $Enum
    )
    $daysofWeek = New-Object "System.Collections.Generic.List[String]"
    
    if (($Enum -contains 1) -eq $True) {$daysofWeek.Add("Sunday")}
    if (($Enum -contains 2) -eq $True) {$daysofWeek.Add("Monday")}
    if (($Enum -contains 4) -eq $True) {$daysofWeek.Add("Tuesday")}
    if (($Enum -contains 8) -eq $True) {$daysofWeek.Add("Wednesday")}
    if (($Enum -contains 16) -eq $True) {$daysofWeek.Add("Thursday")}
    if (($Enum -contains 32) -eq $True) {$daysofWeek.Add("Friday")}
    if (($Enum -contains 64) -eq $True) {$daysofWeek.Add("Saturday")}
    if (($Enum -contains 65) -eq $True) {$daysofWeek.Add("Weekends")}
    if (($Enum -contains 62) -eq $True) {$daysofWeek.Add("Weekdays")}
    if (($Enum -contains 127) -eq $True) {$daysofWeek.Add("EveryDay")}
    Return $daysofWeek 
}