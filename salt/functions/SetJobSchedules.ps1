Function Set-JobSchedules {
    <#
.Synopsis
Create or modify SQL Agent Job Schedules.
.Description
SQL Agent Job Schedule will be created or updated to match the settings in the xml file.
.Parameter sqlServer
The SQL Connection that SQL Agent Job Schedule is on/will be created on.
.Parameter root
The XML Object
.Example
$SqlConnectionString = "data source = .; initial catalog = master; trusted_connection = true;"
$JobManifestXmlFile = "C:\Reports\Our_First_Job.xml"
$SqlConnection = Connect-SqlConnection -ConnectionString $SqlConnectionString
[xml] $_xml = [xml] (Get-Content -Path $JobManifestXmlFile)
$x = Get-Xml -XmlFile $_xml
$sqlAgentJob = Set-Job -SqlServer $SqlConnection -root $x
Set-JobSchedules -SqlServer $SqlConnection -root $x -job $SqlAgentJob
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
    
    [string]$JobName = $Job.Name
    $schedules = $root.Schedules
    [System.Xml.XmlElement] $schedule = $null
    $domain = [Environment]::UserDomainName
    $uname = [Environment]::UserName
    [string]$whoAmI = "$domain\$uname"
    $ServerResults = @{}
    try {
        $db = New-Object Microsoft.SqlServer.Management.Smo.Database
        $db = $SqlServer.Databases.Item("msdb")
        $ds = $db.ExecuteWithResults("select s.schedule_id, s.name from sysjobs j
    inner join sysjobschedules js on js.job_id = j.job_id
    inner join sysschedules s on s.schedule_id = js.schedule_id
    where j.name = '" + $jobName + "'") 
        $t = $ds.Tables[0]
        Foreach ($row in $t.Rows) {
            $ServerResults.Add($row.name, $row.schedule_id)
        }
    }
    catch {
        throw $_.Exception
    }
    if ($ServerResults.Count -gt 0) {
        $msg = "Dropping all schedules for job $jobName that do not exist in XML..."
        Write-Verbose $msg -Verbose
        $ds = $db.ExecuteWithResults("SELECT IS_SRVROLEMEMBER('sysadmin') as 'AmISysAdmin';")
        $AmISysAdmin = $ds.Tables[0].Rows[0]."AmISysAdmin"
        if ($AmISysAdmin -eq 1) {
            Write-Verbose "User $whoAmI is sysadmin on instance, so job schedule can be dropped irrespetive of owner." -Verbose
        }
        if ($AmISysAdmin -eq 0){
            Write-Verbose "User $whoAmI not sysadmin, so need to check that they are owner of job schedules, otherwise schedules not owned by user cannot be dropped."
            $ds = $db.ExecuteWithResults("SELECT SUSER_SID() AS SID;")
            [String]$CurrentUserSid = $ds.Tables[0].Rows[0]."SID"
        }
        foreach ($ServerSchedule in $ServerResults.Keys) {
            if ($schedules.schedule.name -notcontains $ServerSchedule) {
                try {
                    if ($AmISysAdmin -eq 0)
                    {
                        $ds = $db.ExecuteWithResults("select owner_sid from sysschedules syssch where syssch.name = '$ServerSchedule'")
                        [string]$JobScheduleOwnerSid = $ds.Tables[0].Rows[0]."owner_sid"
                        if ($CurrentUserSid -notmatch $JobScheduleOwnerSid)
                        {
                            Write-Error "User $whoAmI is not owner of Schedule $ServerSchedule. Either alter or set user executing PowerShell to sysadmin!"
                            Throw
                        }
                    }
                    Write-Verbose "SQL Statement executed to drop schedule:" -Verbose
                    Write-Verbose "EXEC dbo.sp_delete_schedule @schedule_id = '$($ServerResults.Get_Item($ServerSchedule)) ',@force_delete = 1;" -Verbose
                    $db.ExecuteNonQuery("EXEC dbo.sp_delete_schedule  
        @schedule_id = '" + $($ServerResults.Get_Item($ServerSchedule)) + "',  
        @force_delete = 1;")
                    $msg = "Schedule $($ServerSchedule) on job $jobName deleted..."
                    Write-Verbose $msg -Verbose 
                }
                catch {
                    throw $_.Exception
                }
            }
        }
    }
    
    foreach ($schedule in $schedules.ChildNodes) {
        #name of schedule
        [string]$schedule_name = $schedule.Name
        #schedule child nodes
        if ($schedule.Enabled) {
            [bool]$schedule_enabled = if ($schedule.Enabled -eq "True") {$True} else {$false}
        }
        else {
            [bool]$schedule_enabled = $false
        }
        [string]$Schedule_startDateString = $schedule.StartDate
        [string]$Schedule_EndDateString = $schedule.EndDate
        #frequency child nodes
        [string[]]$schedule_FrequencyInterval = $schedule.Frequency.Interval
        [string]$schedule_FrequencyRecurrs = $schedule.Frequency.Recurrs
        [string]$schedule_frequencyType = $schedule.Frequency.Type
        #daily frequency child nodes
        [string]$Schedule_DailyFrequencyEvery = $schedule.DailyFrequency.Every
        [string]$Schedule_DailyFrequencyInterval = $schedule.DailyFrequency.Interval
        [string]$Schedule_DailyFrequencyStartTimeHour = $schedule.DailyFrequency.StartHour 
        [string]$Schedule_DailyFrequencyStartTimeMinute = $schedule.DailyFrequency.StartMinute
        [string]$Schedule_DailyFrequencyStartTimeSecond = $schedule.DailyFrequency.StartSecond
        [string]$Schedule_DailyFrequencyEndTimeHour = $schedule.DailyFrequency.EndHour 
        [string]$Schedule_DailyFrequencyEndTimeMinute = $schedule.DailyFrequency.EndMinute
        [string]$Schedule_DailyFrequencyEndTimeSecond = $schedule.DailyFrequency.EndSecond 
        try {
            $js = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobSchedule') ($job, $schedule_name)
            if ($ServerResults.Keys -notcontains $schedule_name){
                $create = $true
            }
            else {
                $create = $false
                $js = $job.JobSchedules | Where-Object {$_.Name -eq $schedule_name}
                $js.Refresh()
            }
        }
        catch {
            throw $_.Exception
        }
        #formatting frequency type or assigning it a numeric value if it is something like "Monday, Wednesday" or "Weekday".
        if (![String]::IsNullOrWhiteSpace($schedule_FrequencyInterval)) {
            if ($schedule_frequencyType -eq "Weekly") {
                [int]$FrequencyInterVal = Get-FrequencyIntervalValue $schedule_FrequencyInterval
            }
            else {
                [int]$FrequencyInterVal = [convert]::ToInt32($schedule_FrequencyInterval, 10)
            }
        }
        try {
            $js.IsEnabled = $schedule_enabled
            #"if" statements are used to verify string is not empty in those cases where an enpty string will cause a "create job schedule" failure.
            if (![string]::IsNullOrEmpty($Schedule_startDateString)) {
                $js.ActiveStartDate = [DateTime]$Schedule_startDateString
            }
            if (![String]::IsNullOrEmpty($Schedule_EndDateString)) {
                $js.ActiveEndDate = [DateTime]$Schedule_EndDateString
            }
            if (![String]::IsNullOrEmpty($FrequencyInterVal)) {
                $js.FrequencyInterval = $FrequencyInterVal
            }
            if (![String]::IsNullOrEmpty($schedule_FrequencyRecurrs)) {
                $js.FrequencyRecurrenceFactor = $schedule_FrequencyRecurrs
            }
            if (![String]::IsNullOrEmpty($schedule_frequencyType)) {
                $js.FrequencyTypes = $schedule_frequencyType
            }
            if (![String]::IsNullOrEmpty($Schedule_DailyFrequencyEvery)) {
                $js.FrequencySubDayTypes = $Schedule_DailyFrequencyEvery
            }
            if (![String]::IsNullOrEmpty($Schedule_DailyFrequencyInterval)) {
                $js.FrequencySubDayInterval = [convert]::ToInt32($Schedule_DailyFrequencyInterval, 10)
            }
            if (![String]::IsNullOrEmpty($Schedule_DailyFrequencyStartTimeHour)) {
                $StartTimeSpan = New-TimeSpan -Hours ([convert]::ToInt32($Schedule_DailyFrequencyStartTimeHour , 10)) -Minutes ([convert]::ToInt32($Schedule_DailyFrequencyStartTimeMinute , 10)) -Seconds ([convert]::ToInt32($Schedule_DailyFrequencyStartTimeSecond , 10))
                $js.ActiveStartTimeOfDay = $StartTimeSpan
            }
            if (![string]::IsNullOrEmpty($Schedule_DailyFrequencyEndTimeHour)) {
                $EndTimeSpan = New-TimeSpan -Hours ([convert]::ToInt32($Schedule_DailyFrequencyEndTimeHour , 10)) -Minutes ([convert]::ToInt32($Schedule_DailyFrequencyEndTimeMinute , 10)) -Seconds ([convert]::ToInt32($Schedule_DailyFrequencyEndTimeSecond , 10))
                $js.ActiveEndTimeOfDay = $EndTimeSpan
            }
            if ($create) {
                try {
                    $js.Create()
                    Write-Verbose "Job Schedule $schedule_name created successfully." -Verbose
                    $create = $false
                    Remove-Variable -Name js
                }
                catch {
                    throw $_.Exception
                }
            }
            else {
                $js.Alter()
                Remove-Variable -Name js
                Write-Verbose "Job Schedule $schedule_name properties updated successfully." -Verbose
            }
        }
        catch {
            throw $_.Exception
        }
    }
}