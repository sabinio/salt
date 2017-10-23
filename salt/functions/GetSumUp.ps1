Function Get-SumUp {
         <#
.Synopsis
Find all the possible combinations of a sum
.Description
Frequency interval of a weekly schedule is stored as an integer.
Need to figure out what days of the week this weekly schedule represents.
Pass in the range of values that represent the days of the week. 
Pass in the value of frequency interval.
This will output the possible combinations of the sums.
If there is more than one then we output all, hence use of PSCustomObject. 
This is based off the frequency type being weekly. Refer to MSDN page below for values.
https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.agent.jobschedule.frequencyinterval.aspx
.Parameter numbers
The range of values
.Parameter target
The value that could be the answer to any combination of the range of values in $numbers
.Example
Redacted version, for full use see GetSqlAgentAsXml - 
$range = 1, 2, 4, 8, 16, 32, 62, 64, 65, 127
$combi = Get-SumUp -numbers $range -target $serverJobSchedule.FrequencyInterval
#>
    [CmdletBinding()]
    param
    (
        [System.Collections.Generic.List[Int]]
        $numbers,
        [int32]
        $target
    )
    $part = New-Object "System.Collections.Generic.List[Int]"
    Get-SumUpRecursive -numbers $numbers -target $target -part $part 
}

Function Get-SumUpRecursive {
    param
    (
        [System.Collections.Generic.List[Int]]
        $numbers,
        [int16]
        $target,
        [System.Collections.Generic.List[Int]]
        $part
    )
    [int16]$result = 0
    foreach ($p in $part) {
        $result += $p
    }
    if ($result -eq $target) {
        $output = New-Object -TypeName PSObject
        $output | Add-Member -MemberType NoteProperty -Name part -Value "$($part)"
        $output
    }
    if ($result -ge $target) {
        return
    }
    for ($i = 0; $i -lt $numbers.Count; $i++) {
        $leftovers = New-Object "System.Collections.Generic.List[Int]"
        [int16]$number = $numbers[$i]
        for ($j = $i + 1; $j -lt $numbers.Count; $j++) {
            $leftovers.Add($numbers[$j])
        }
        $partList = New-Object "System.Collections.Generic.List[Int]"
        foreach ($l in $part) {
            $partList.Add($l)
        }
        $partList.Add($number)
        Get-SumUpRecursive -numbers $leftovers -target $target -part $partList
    }
}