
[<img src="https://sabinio.visualstudio.com/_apis/public/build/definitions/573f7b7f-2303-49f0-9b89-6e3117380331/106/badge"/>](https://sabinio.visualstudio.com/Sabin.IO/_apps/hub/ms.vss-ciworkflow.build-ci-hub?_a=edit-build-definition&id=105)

AUTHOR: Richie Lee 

# salt - A SQL Agent Deploy PowerShell Module Guide

## Introduction

This module is designed to take a SQL Agent Job that is stored in an XML file and deploy the job to an instance of SQL. The PowerShell is idempotent in that if it is re-run on the same XML file then no changesa re applied. Only when there are changes in the XML file will we see changes.
Each one of the modules used have their own documentation in their header. This readme will attempt to exapnd upon that documentation. It is strongly encouraged that you read that documentation.

## Why is SQL Agent Stored in an XML File?

There is no obvious way to script out in T-SQL an alter statement to apply changes to a SQL Agent account. This module makes use of SMO to apply changes, as it is far more powerful and flexible. Therefore we have to present the properties of a SQL Agent job in a way that we can then map those to the corresponding methods to add/edit said properties of a given SQL Agent Job. XML proved to be a suitable method of storing all the properties in a strucuted way.
Please refer to [MSDN](https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.agent.job.aspx) for full information on SQLAgent and SMO. This is not required reading; more of a reference to the module. 

## What is the structure for the XML file?
The structure can vary, depending on the Schedule and step type, but below is the basic structure of every element that can be used.
```XML
<Job>
		<Name></Name>                           	
		<Description></Description>
		<Enabled></Enabled>
		<Category Include="">
            <Value></Value>
        </Category>
		<TargetServers>
			<TargetServer Include="">
				<Name></Name>
			</TargetServer>
		</TargetServers>
		<Operator>
			<Name></Name>
			<EMail></EMail>
            <NetSend></NetSend>
            <Page></Page>
		</Operator>
		<Notification>
			<SendEmail></SendEmail>
			<SendPage></SendPage>
			<SendNetSend></SendNetSend>
			<SendEventLog></SendEventLog>
            </Notification>
            <Schedules>
        <Schedule>
            <Name> Schedule</Name>
            <Enabled></Enabled>
            <Frequency>
                <Type></Type>
                <Interval></Interval>
            </Frequency>
             <DailyFrequency>
                <Every></Every>
                <Interval></Interval>
                <StartHour></StartHour>
                <StartMinute></StartMinute>
                <StartSecond></StartSecond>
                <EndHour></EndHour>
                <EndMinute></EndMinute>
                <EndSecond></EndSecond>
            </DailyFrequency>
            <StartDate></StartDate>
            <EndDate></EndDate>
        </Schedule>
        </Schedules>
        <Steps>
        <Step>
        <Step>
            <Name></Name>
            <SubSystem></SubSystem>
            <RunAs Include="RunAsAccount">
                <Name></Name>
            </RunAs>
            <SsisServer Include="IntegrationServicesCatalogServer">
                <Name></Name>
            </SsisServer>
            <SsisServerDetails Include="">
                <SsisServerCatalog></SsisServerCatalog>
                <SsisServerCatalogFolder></SsisServerCatalogFolder>
                <SsisServerCatalogProject></SsisServerCatalogProject>
                <SsisServerCatalogPackage></SsisServerCatalogPackage>
                <SsisServerCatalogEnvironment></SsisServerCatalogEnvironment>
            </SsisServerDetails>
            <SsisServerCatalogEnvironment></SsisServerCatalogEnvironment>
            <OnSuccessAction></OnSuccessAction>
            <OnFailAction></OnFailAction>
            <RetryAttempts></RetryAttempts>
            <RetryInterval></RetryInterval>
        </Step>
        </Steps>
		</Job>
```

## That's a lot of XML...

Indeed. Which is why it is possible to export a SQL Agent Job that already exists from an instance of SQL Server and save as an XML file. In most cases no changes will need to be applied to the XML file and this can be used as the XML file to other environments.

## How Do I Export a SQL Agent Job from SQL to an XML File?
The process is to download the module from either source or ProGet, import the module, add SMO as a type, make a connection to the instance of SQL you require and run "Get-SqlAgentAsXML". 
```PowerShell
cls
Import-Module .\ps_module\salt -Force
Add-Type -Path "C:\Program Files\Microsoft SQL Server\130\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"
$SqlConnectionString = "data source = .; initial catalog = master; trusted_connection = true;"
$SqlConnection = Connect-SqlConnection -ConnectionString $SqlConnectionString
#Remove-Item c:\reports\*
#Get-SqlAgentAsXml -SqlServer $SqlConnection -filePath ".\"
Get-SqlAgentAsXml -SqlServer $SqlConnection -filePath ".\" -JobName "Our First Job"
Disconnect-SqlConnection -SqlDisconnect $SqlConnection
```

## Is There Anything That Needs to be Altered at Deploy Time?

Several changes are required. Any elements that need changing will have an attribute called "Include." The elements that have an Include attribute are as follows - 

* **Category**

* **RunAs**

* **TargetServer**

* **SSISServer**

* **SSISServerDetails** - *SSISServerDetails is a special case and only needs to be updated if the ssis package exist in a different folder/project/environment from other environments. This should not be the case and is an edge case. If you do have your packages in different folders etc it may be more sensible for each environment to mirror one another.*

Let's take TargetServer as an example - When running a deploy, in the PowerShell session there needs to be a variable with the exact same name that the value of "Include" is. If you are running this locally then you would just create a variable of that given name. Here is an example:
Say my TargetServer is defined as below:
```XML
<TargetServers>
        <TargetServer Include="Local">
            <Value>MyDevBox</Value>
        </TargetServer>
    </TargetServers>
```
I would have to have a variable called "Local" with the value set to whatever server the TargetServer is going to be. This will then be the value of the element "Value". So in the example below the trgetserver will be "ASGLH-WL-11718".
```PowerShell
$Local = "MyDevEnvBox"
Import-Module .\ps_module\SqlAgentJobDeploy -Force
Add-Type -Path "C:\Program Files\Microsoft SQL Server\130\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"
$SqlConnectionString = "data source = .; initial catalog = master; trusted_connection = true;"
$JobManifestXmlFile = ".\Our First Job.xml"
$SqlConnection = Connect-SqlConnection -ConnectionString $SqlConnectionString
[xml] $_xml = [xml] (Get-Content -Path $JobManifestXmlFile)
$x = Get-Xml -XmlFile $_xml
Set-JobCategory -SqlServer $SqlConnection -root $x
Set-JobOperator -SqlServer $SqlConnection -root $x
$sqlAgentJob = Set-Job -SqlServer $SqlConnection -root $x
Set-JobSchedules -SqlServer $SqlConnection -root $x -job $SqlAgentJob
Set-JobSteps -SqlServer $SqlConnection -root $x -job $SqlAgentJob 
Disconnect-SqlConnection -SqlDisconnect $SqlConnection
```
If I were to not include a variable then the deployment will fail. So there is no chance of accidentally targetting the wrong server. 

## How Do I Deploy SQL Agent
The process in PowerShell is outlined exactly above:
* Define variable for all target servers
* Add SMO
* Create SQL Connection ConnectionString
* Import XML
* Set Job Category - if it doesn't existwill create.
* Set Job Operator - if it doesn't exist it will create, otherwise will update.
* Set Job - if it doesn't exist will create, otherwise will update. Returns the SQL Agent Job as this is used by further functions.
* Set Schedules - Will drop all schedules that relate to job and will create all jobs detailed in the XML.
* Set Job Steps - Will drop all current job steps and will create all job steps defined in the XML.
* Finally, Disconnect from SQL.

```PowerShell
$Local = "myLocalDevInstance2"
Import-Module .\ps_module\salt -Force
Add-Type -Path "C:\Program Files\Microsoft SQL Server\130\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"
$SqlConnectionString = "data source = .; initial catalog = master; trusted_connection = true;"
$JobManifestXmlFile = ".\Our First Job.xml"
$SqlConnection = Connect-SqlConnection -ConnectionString $SqlConnectionString
[xml] $_xml = [xml] (Get-Content -Path $JobManifestXmlFile)
$x = Get-Xml -XmlFile $_xml
Set-JobCategory -SqlServer $SqlConnection -root $x
Set-JobOperator -SqlServer $SqlConnection -root $x
$sqlAgentJob = Set-Job -SqlServer $SqlConnection -root $x
Set-JobSchedules -SqlServer $SqlConnection -root $x -job $SqlAgentJob
Set-JobSteps -SqlServer $SqlConnection -root $x -job $SqlAgentJob 
Disconnect-SqlConnection -SqlDisconnect $SqlConnection
```

 ## Any Limitations?

 Other than the ones set by SQL Agent, not that I am aware of. By limitations I mean things like job names have to be unique, job schedule names don't have to be unique other than for the job itself etc.
