Function Get-SqlAgentAsXml {
    <#
.Synopsis
Takes a SQL Agent Job that exists on a SQL Instance and converts into XML
.Description
Rather than trying to create XML files that represent SQL Agent Jobs from scratch, this function aims to take all jobs that already exists on an instance and convert into 
an XML file that can be used by the rest of the module to import job/schedules/steps etc.

Not intended to be used in an automated process, but rather a function designed to help teams adopt the whole automate SQl Agent as XML files quicker.
.Parameter SqlServer
SQL Server Instance that has Agent Job on it.
.Parameter filePath
Folder directory where we want to create the XML files.
.Parameter dateFormat
Date Format that the SQL Server Instance uses: some might be EN-GB, some EN-US. 
.Parameter jobName
Optional parameter. Name of SQL Agent Job that we want to export to XML.
If not included all SQL Agent Jobs will be exported, except for the following:
     -SSIS Server Maintenance Job
    - syspolicy_purge_history
.Example
 $SqlConnectionString = "data source = .; initial catalog = master; trusted_connection = true;"
 $SqlConnection = Connect-SqlConnection -ConnectionString $SqlConnectionString
 Get-SqlAgentAsXml -SqlServer $SqlConnection -filePath "C:\Reports" -dateFormat 'MM/dd/yyyy'
 Get-SqlAgentAsXml -SqlServer $SqlConnection -filePath "C:\Reports" -dateFormat 'MM/dd/yyyy' -JobName "My SQL Agent Job"
 Disconnect-SqlConnection -SqlDisconnect $SqlConnection
#>
    [CmdletBinding()]
    param
    (
        [Microsoft.SqlServer.Management.Smo.SqlSmoObject]
        [ValidateNotNullorEmpty()]
        $SqlServer,
        [string]
        $JobName,
        [String]
        [ValidateNotNullorEmpty()]
        $filePath
    )
    if ($jobName) {
        $serverJobs = $sqlserver.JobServer.Jobs |where-object {$_.Name -like $jobName}
    }
    else {
        $serverJobs = $sqlserver.JobServer.Jobs |where-object {$_.Name -notmatch 'SSIS Server Maintenance Job|syspolicy_purge_history'}

    }
    foreach ($job in $serverJobs) {
        $pattern = '[^a-zA-Z0-9_]'
        Write-Verbose "Removing non-alphanumeric chars from job name, so that we can use job name as file name." -Verbose
        $FormattedJobName = $Job.Name -replace $pattern, ""
        Write-Verbose "The job name is $($job.name)" -Verbose
        $FileOutput = Join-Path $filePath "$($FormattedJobName).xml"
        Write-Verbose "File output - $FileOutput" -Verbose
        # Create The Document
        $XmlWriter = New-Object System.XMl.XmlTextWriter($FileOutput, $Null)
        # Set The Formatting
        $xmlWriter.Formatting = "Indented"
        $xmlWriter.Indentation = "4"
        # Write the XML Decleration
        $xmlWriter.WriteStartDocument()
        # Write Root Element
        $xmlWriter.WriteStartElement("Job")
        # Write the Document
        $xmlWriter.WriteElementString("Name", "$($Job.Name)")
        $XmlWriter.WriteElementString("Owner", "$($Job.OwnerLoginName)")
        $xmlWriter.WriteElementString("Description", "$($Job.Description)")
        $xmlWriter.WriteElementString("Enabled", "$($Job.IsEnabled)")
        $xmlWriter.WriteStartElement("Category")
        $xmlWriter.WriteAttributeString("Include", "ServerJobCategory")
        $xmlWriter.WriteElementString("Value", "$($Job.Category)")
        $xmlWriter.WriteEndElement()
        $xmlWriter.WriteStartElement("TargetServers")
        $xmlWriter.WriteStartElement("TargetServer")
        $xmlWriter.WriteAttributeString("Include", "$($job.EnumTargetServers().ServerName)")
        $xmlWriter.WriteElementString("Value", "$($job.EnumTargetServers().ServerName)")
        $xmlWriter.WriteEndElement()
        $xmlWriter.WriteEndElement()
        $xmlWriter.WriteStartElement("Operator")
        $xmlWriter.WriteElementString("Name", "$($Job.OperatorToEmail)")
        $xmlWriter.WriteElementString("Email", "$(($SqlServer.JobServer.Operators[$job.OperatorToEmail]).EmailAddress)")
        $xmlWriter.WriteElementString("NetSend", "$(($SqlServer.JobServer.Operators[$job.OperatorToNetSend]).NetSendAddress)")
        $xmlWriter.WriteElementString("Page", "$(($SqlServer.JobServer.Operators[$job.OperatorToPage]).PagerAddress)")
        # Write Close Tag for Root Element
        $xmlWriter.WriteEndElement() # <-- Closing OperatorElement
        $xmlWriter.WriteStartElement("Notification")
        $xmlWriter.WriteElementString("SendEmail", "$($Job.EmailLevel)")
        $xmlWriter.WriteElementString("SendEventLog", "$($Job.EventLogLevel)")
        $xmlWriter.WriteElementString("SendPage", "$($Job.PageLevel)")
        $xmlWriter.WriteElementString("SendNetSend", "$($Job.NetSendLevel)")
        $xmlWriter.WriteEndElement() # <-- Closing NotificationElement
        $xmlWriter.WriteStartElement("Schedules")
        $serverJobSchedules = $job.JobSchedules
        ForEach ($serverJobSchedule in $serverJobSchedules) {
            $xmlWriter.WriteStartElement("Schedule")
            $scheduleNameRedacted = $serverJobSchedule.Name.replace(" ", "")
            $scheduleNameRedacted = $scheduleNameRedacted.replace('[^a-zA-Z]', "")
            $xmlWriter.WriteAttributeString("Include", "$scheduleNameRedacted")
            $xmlWriter.WriteElementString("Name", "$($serverJobSchedule.Name)")
            $xmlWriter.WriteElementString("Enabled", "$($serverJobSchedule.IsEnabled)")
            #$xmlWriter.WriteElementString("Enabled", "$($serverJobSchedule.IsEnabled -replace "$", '')")
            $xmlWriter.WriteStartElement("Frequency")
            $xmlWriter.WriteElementString("Type", "$($serverJobSchedule.FrequencyTypes)")
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
                foreach ($w in $WeeklyFrequencyInterval) {
                    $xmlWriter.WriteElementString("Interval", "$($w)")
                }
            }
            elseif ($serverJobSchedule.Frequencytypes -eq "Monthly" -or $serverJobSchedule.Frequencytypes -eq "Daily") {
                $xmlWriter.WriteElementString("Interval", "$($serverJobSchedule.FrequencyInterval)")
            }
            $xmlWriter.WriteElementString("Recurrs", "$($serverJobSchedule.FrequencyRecurrenceFactor)")
            $xmlWriter.WriteEndElement() # <-- Closing FrequencyElement
            $xmlWriter.WriteStartElement("DailyFrequency")
            $xmlWriter.WriteElementString("Every", "$($serverJobSchedule.FrequencySubDayTypes)")
            Write-Host $serverJobSchedule.FrequencySubDayTypes  -ForegroundColor DarkGreen
            Write-Host $serverJobSchedule.FrequencySubDayInterval -ForegroundColor DarkMagenta
            if ($serverJobSchedule.FrequencySubDayTypes -ne "Unknown") {
                $xmlWriter.WriteElementString("Interval", "$($serverJobSchedule.FrequencySubDayInterval)") 
            }
            $StartTimeSpan = $serverJobSchedule.ActiveStartTimeOfDay -split ":"
            $EndTimeSpan = $serverJobSchedule.ActiveEndTimeOfDay -split ":"
            $xmlWriter.WriteElementString("StartHour", "$($startTimeSpan[0])")
            $xmlWriter.WriteElementString("StartMinute", "$($startTimeSpan[1])")
            $xmlWriter.WriteElementString("StartSecond", "$($startTimeSpan[2])")
            if ($serverJobSchedule.FrequencyTypes -ne "OneTime") {
                $xmlWriter.WriteElementString("EndHour", "$($endTimeSpan[0])")
                $xmlWriter.WriteElementString("EndMinute", "$($endTimeSpan[1])")
                $xmlWriter.WriteElementString("EndSecond", "$($endTimeSpan[2])")
            }
            $xmlWriter.WriteEndElement() # <-- Closing ScheduleElement
            $xmlWriter.WriteElementString("StartDate", "$(Get-Date $serverJobSchedule.ActiveStartDate -format yyyy-MM-dd)")
            $xmlWriter.WriteElementString("EndDate", "$(Get-Date $serverJobSchedule.ActiveEndDate -format yyyy-MM-dd)")
            $xmlWriter.WriteEndElement() # <-- Closing ScheduleElement
            #Clear-Variable -Name "serverJobSchedule.Name"
            Clear-Variable -Name "serverJobSchedule"
        }
        $xmlWriter.WriteEndElement() # <-- Closing SchedulesElement
        $xmlWriter.WriteStartElement("Steps")
        $JobSteps = $job.JobSteps
        foreach ($Step in $JobSteps) {
            $xmlWriter.WriteStartElement("Step")
            $xmlWriter.WriteElementString("Name", "$($step.name)")
            $xmlWriter.WriteElementString("SubSystem", "$($step.subSystem)")
            $xmlWriter.WriteStartElement("RunAs")
            $xmlWriter.WriteAttributeString("Include", "RunAsAccount")
            $xmlWriter.WriteElementString("Name", "$($step.ProxyName)")
            $xmlWriter.WriteEndElement()#<- End RunAs
            if ($step.subSystem -eq "PowerShell" -or $step.subSystem -eq "TransactSql") {
                $xmlWriter.WriteElementString("Command", "$($step.Command)")
            }
            if ($step.subSystem -eq "Ssis") {
                $StepCommand = $Step.Command
                $pattern = '(?<=SERVER ).\w([^\s]+)'
                [String]$SsisServer = [regex]::match($StepCommand, $pattern)
                $xmlWriter.WriteStartElement("SsisServer")
                $xmlWriter.WriteAttributeString("Include", "IntegrationServicesCatalogServer")
                $xmlWriter.WriteElementString("Name", "$($ssisServer)")
                $xmlWriter.WriteEndElement() #<- Closing SsisServer
                $xmlWriter.WriteStartElement("SsisServerDetails")
                $stepNameRedacted = $step.name.replace(" ", "")
                $stepNameRedacted = $stepNameRedacted.replace('[^a-zA-Z]', "")
                $xmlWriter.WriteAttributeString("Include", "$($stepNameRedacted)")
                $pattern = 'SSISDB.*.dtsx'
                [String]$ssisCatalog = [regex]::match($StepCommand, $pattern)
                $SsisProperties = $ssisCatalog.Split('\')
                $xmlWriter.WriteElementString("SsisServerCatalog", "$($SsisProperties[0])")
                $xmlWriter.WriteElementString("SsisServerCatalogFolder", "$($SsisProperties[1])")
                $xmlWriter.WriteElementString("SsisServerCatalogProject", "$($SsisProperties[2])")
                $xmlWriter.WriteElementString("SsisServerCatalogPackage", "$($SsisProperties[3])")
                $pattern = '(?<=ENVREFERENCE).[0-9]*'
                [string]$EnvReference = [regex]::match($StepCommand, $pattern)
                if ($EnvReference -match "[0-9]") {
                    $script = "SELECT [environment_name]
	                        FROM [SSISDB].[catalog].[environment_references] er
	                        WHERE er.reference_id = $($EnvReference.Trim(' '))"
                    try {
                        $ssisEnvironment = $SqlServer.ConnectionContext.ExecuteScalar($script)
                    }
                    catch {
                        throw $_.Exception
                    }
                    $xmlWriter.WriteElementString("SsisServerCatalogEnvironment", "$($ssisEnvironment)")
                }
                $xmlWriter.WriteEndElement() # <-- Closing Step
            }
            $xmlWriter.WriteElementString("OnSuccessAction", "$($step.OnSuccessAction)")
            if ($step.OnSuccessAction -eq "GoToStep") {
                $OnSuccessGoToStepName = Get-GoToStepName -JobObject $job -StepId $step.OnSuccessStep
                $xmlWriter.WriteElementString("OnSuccessStep", "$($OnSuccessGoToStepName)")
            }
            $xmlWriter.WriteElementString("OnFailAction", "$($step.OnFailAction)")
            if ($step.OnFailAction -eq "GoToStep") {
                $OnFailGoToStepName = Get-GoToStepName -JobObject $job -StepId $step.OnFailStep
                $xmlWriter.WriteElementString("OnFailStep", "$($OnFailGoToStepName)")
            }
            $xmlWriter.WriteElementString("RetryAttempts", "$($step.RetryAttempts)")
            $xmlWriter.WriteElementString("RetryInterval", "$($step.RetryInterval)")
            $xmlWriter.WriteEndElement() # <-- Closing Step
        }
        $xmlWriter.WriteEndElement() # <-- Closing Steps
        $xmlWriter.WriteEndElement() # <-- Closing JobElement
        $xmlWriter.WriteEndDocument()
        $xmlWriter.Finalize
        $xmlWriter.Flush | Out-Null
        $xmlWriter.Close()
    }
    Remove-Variable -Name "serverJobs"
}