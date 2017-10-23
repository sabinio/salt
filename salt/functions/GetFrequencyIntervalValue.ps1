Function Get-FrequencyIntervalValue {
         <#
.Synopsis
Take days of the week and convert to relative frequency value
.Description
In SQL Agent as XML file, days of the week can be used to make creating xml files easier for users.
We can then take these days of the week and create a sum of the value that will be used when setting the frequency of a weekly schedule.  
.Parameter Freq
The weekly frequency interval from the SQl Agent as XML file.
.Example
Redacted example: see SetJobSchedules.ps1 for full version - 
[string]$Schedule_DailyFrequencyInterval = $schedule.DailyFrequency.Interval
...
if ($schedule_FrequencyInterval -ne $null) {
            if ($schedule_frequencyType -eq "Weekly") {
                [int]$FrequencyInterVal = Get-FrequencyIntervalValue $schedule_FrequencyInterval
            }
            else {
                [int]$FrequencyInterVal = [convert]::ToInt32($schedule_FrequencyInterval, 10)
            }
        }
#>
    [CmdletBinding()]
    param
    (
        [string[]]
        [ValidateNotNullorEmpty()]
        $Freq
    )
    [int]$Value = 0
    if (($Freq -contains "Sunday") -eq $True) {$Value = $Value + 1}
    if (($Freq -contains "Monday") -eq $True) {$Value = $Value + 2}
    if (($Freq -contains "Tuesday") -eq $True) {$Value = $Value + 4}
    if (($Freq -contains "Wednesday") -eq $True) {$Value = $Value + 8}
    if (($Freq -contains "Thursday") -eq $True) {$Value = $Value + 16}
    if (($Freq -contains "Friday") -eq $True) {$Value = $Value + 32}
    if (($Freq -contains "Saturday") -eq $True) {$Value = $Value + 64}
    if (($Freq -contains "WeekEnds") -eq $True) {$Value = $Value + 65}
    if (($Freq -contains "WeekDays") -eq $True) {$Value = $Value + 62}
    if (($Freq -contains "EveryDay") -eq $True) {$Value = $Value + 127}
    Return $Value 
}