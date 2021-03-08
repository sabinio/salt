
beta package - [<img src="https://sabinio.visualstudio.com/_apis/public/build/definitions/573f7b7f-2303-49f0-9b89-6e3117380331/106/badge"/>](https://sabinio.visualstudio.com/Sabin.IO/_apps/hub/ms.vss-ciworkflow.build-ci-hub?_a=edit-build-definition&id=106)

latest package - [<img src="https://sabinio.visualstudio.com/_apis/public/build/definitions/573f7b7f-2303-49f0-9b89-6e3117380331/109/badge"/>](https://sabinio.visualstudio.com/Sabin.IO/_apps/hub/ms.vss-ciworkflow.build-ci-hub?_a=edit-build-definition&id=109)

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
        <OutputFileName></OutputFileName>
        <LogOutput>
            <!-- Valid options include:
            <AppendToLogFile/>
            <AppendToJobHistory/>
            <LogToTableWithOverwrite/>
            <AppendToTableLog/>
            <AppendAllCmdExecOutputToJobHistory/>
            <ProvideStopProcessEvent/>
            -->
        </LogOutput>
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
## Does salt drop and recreate everything, or does it alter?

salt will alter
* Operator
* Category
* Job
* Job Properties
* Job Schedules

salt will drop and recreate 
* Job Steps

### Why aren't Job Steps Altered?

Job Steps are fiddly to work with in that they are not independent of themselves - they rely on other steps to exist. So easier to drop/recreate every time. 

 ## What if I Want To Drop and Recreate The Job Every Time?
 
 There is a Switch on the function "Set-Job" called "dropAndRecreate". This will drop the Job every time.
 
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
I would have to have a variable called "Local" with the value set to whatever server the TargetServer is going to be. This will then be the value of the element "Value". So in the example below the trgetserver will be "MyDevEnvBox".
```PowerShell
$Local = "MyDevEnvBox"
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
If I were to not include a variable then the deployment will fail. So there is no chance of accidentally targetting the wrong server. 

## How Do I Deploy SQL Agent
The process in PowerShell is outlined exactly above:
* Define variable for all target servers
* Add SMO
* Create SQL Connection ConnectionString
* Import XML
* Set Job Category - if it doesn't exist will create.
* Set Job Operator - if it doesn't exist it will create, otherwise will update.
* Set Job - if it doesn't exist will create, otherwise will update. Inside this function we call other functions to set owner, notifications etc. Returns the SQL Agent Job as this is used by further functions.
* Set Schedules - Will drop all schedules that relate to job and will create all jobs detailed in the XML.
* Set Job Steps - Will drop all current job steps and will create all job steps defined in the XML.
* Finally, Disconnect from SQL.

### Is there anything optional?
There are two Test functions that check that the account running the deployment has the necessary permissions to run the changes/has access to proxies (RunAs accounts). The other function tests that SQL Agent is up and running. 

```PowerShell
$Local = "myLocalDevInstance2"
Import-Module .\ps_module\salt -Force
Add-Type -Path "C:\Program Files\Microsoft SQL Server\130\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"
$SqlConnectionString = "data source = .; initial catalog = master; trusted_connection = true;"
$JobManifestXmlFile = ".\Our First Job.xml"
$SqlConnection = Connect-SqlConnection -ConnectionString $SqlConnectionString
[xml] $_xml = [xml] (Get-Content -Path $JobManifestXmlFile)
$x = Get-Xml -XmlFile $_xml
Test-SQLServerAgentService -SqlServer $SqlConnection
Test-CurrentPermissions -SqlServer $SqlConnection -ProxyCheck -root $x
Set-JobCategory -SqlServer $SqlConnection -root $x
Set-JobOperator -SqlServer $SqlConnection -root $x
$sqlAgentJob = Set-Job -SqlServer $SqlConnection -root $x
Set-JobSchedules -SqlServer $SqlConnection -root $x -job $SqlAgentJob
Set-JobSteps -SqlServer $SqlConnection -root $x -job $SqlAgentJob 
Disconnect-SqlConnection -SqlDisconnect $SqlConnection
```

 ## Any Limitations?

 Other than the ones set by SQL Agent, not that I am aware of. By limitations I mean things like job names have to be unique, job schedule names don't have to be unique other than for the job itself etc.
 
 ```PowerShell
$sqlAgentJob = Set-Job -SqlServer $SqlConnection -root $x -dropAndRecreate
```
 ## I Don't Want an Operator Created
 
 If you don't want to include an operator, then leave it blank. The Function to set an operator checks to see if the name attribute is empty or not. If it is then it will skip creating an operator.
 
 ## Checking SQL Agent Service is Up and Running
 
There is a check to verify that SQL Agent Service is up and running. As this requires access to master, and some accounts may not have permissions to master, you cna override this check by including the Switch "IgnoreCheck"

Another check we have to make in the function [Connect-SqlConnection](https://github.com/sabinio/salt/blob/master/salt/functions/ConnectSqlConnection.ps1) is that the connection to the instance is successful by querying all the database names and piping to "Out-Null". This is because of this [https://connect.microsoft.com/SQLServer/feedback/details/636401/smo-is-inconsistent-when-raising-errors-for-login-faliures#](Microsoft Connect Issue) where SMO is inconsistent with throwing login failures.

## What Permissions Are Required on the SQL Server Instance?

Here is a list of the minimal permissions required if you are not going to attempt to alter the owner of the job. 

#### MSDB Database
* GRANT SELECT on dbo.sysschedules
* GRANT SELECT on dbo.sysjobschedules
* GRANT SELECT on dbo.sysjobs
* ROLE MEMBER of SQLAgentOperatorRole
* Grant the login to the RunAs proxy 

#### MASTER Database
* GRANT SELECT on dbo.sysprocesses
* GRANT VIEW SERVER STATE

If you wish to set the owner of the SQL Agent Job, then the account needs to be sysadmin. There are no minimal permissions for this option. Set-JobOwner runs a check before attempting to change owner. 

if you plan on only altering what was created through using salt, the permisisons granted by the role SQLAgentOpertorRole will be enough. If you are planning on changing objects already deployed that are owned by other accounts, and the account running hte deployment is NOT a sysmadin,  then you will need to manually alter those jobs/job schedules to be owned by the account that is runnning the deployment.
[https://technet.microsoft.com/en-us/library/ms188283(v=sql.110).aspx](SQL Server Agent Fixed Database Roles) 

Below is a sample SQL Script to add the permissions required.
```sql
--perms
USE msdb
GO 
CREATE USER [buildaccount] FOR LOGIN [buildaccountlogin] 
GO 
GRANT SELECT ON dbo.sysschedules  TO [buildaccount] 
GRANT SELECT ON dbo.sysjobschedules  TO [buildaccount] 
GRANT SELECT ON dbo.sysjobs  TO [buildaccount] 
EXEC msdb.dbo.sp_addrolemember @membername = 'buildaccount', @rolename = 'SQLAgentOperatorRole'
EXEC msdb.dbo.sp_grant_login_to_proxy  
                @login_name = N'buildaccount',  
                @proxy_name = N'proxyaccount';

use master
GO
CREATE USER [buildaccount] FOR LOGIN [buildaccountlogin] 
GO
GRANT SELECT ON master.dbo.sysprocesses  TO [buildaccount] 
GRANT VIEW SERVER STATE TO [buildaccount] 
```

### Checking Permissions
Assuming that you are using Integrated Security, you can run Test-CurrentPermissions, which will verify that the account executing deployment has the correct minimum permissions on the server before executing.

### How Do I Get SMO?

If the machine you are deploying from has .NET Standard 2.0 installed you can use the SMO Nuget package. As of saLt 2.0 and onwards, this can be downloaded as part of the deploy process. The function to download the Nuget package is called ```Install-SaltSmo```. You need to pass in a working folder and it will download Nuget to then download the package, and return the full path. Below is a sample script to deploy a SQL Agent Job using saLt and downloading SMO.

```powershell
Param(
    [parameter(mandatory = $true)][string] $serverToDeployTo,
    [parameter(mandatory = $true)][string] $ServerJobCategory,
    [parameter(mandatory = $true)][string] $JobManifestXmlFile,
    [parameter(mandatory = $true)][string] $serverName,
    [parameter(mandatory = $true)][string] $DatabaseName,
    [parameter(mandatory = $false)][switch] $DownloadSmoFromNuGet,
    [parameter(Mandatory = $false)] [string] $sqlAdministratorLogin,
    [parameter(Mandatory = $false)] [String] $sqlAdministratorLoginPassword

)

if ($PSBoundParameters.ContainsKey('sqlAdministratorLogin') -eq $true) {
    Write-Host "Using Login AAD Password to deploy"
    [string] $SqlConnectionString = "Server=$($serverName);Initial Catalog=$($DatabaseName);Persist Security Info=False;User ID=$($sqlAdministratorLogin);Password=$($sqlAdministratorLoginPassword);MultipleActiveResultSets=False;TrustServerCertificate=True;Connection Timeout=30;;Authentication=`"Active Directory Password`""
}
else {
    Write-Host "Using Integrated Security to deploy"
    [string] $SqlConnectionString = "integrated security=True;data source=$($serverName);initial catalog=$($DatabaseName);TrustServerCertificate=True;Connection Timeout=30;"
}

$global:serverToDeployTo = $serverToDeployTo
$global:ServerJobCategory = $ServerJobCategory
Import-Module .\salt -Force
if ($PSBoundParameters.ContainsKey('DownloadSmoFromNuGet') -eq $false) {
    $smoDll = "C:\Program Files\Microsoft SQL Server\140\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"
    If ((Test-Path $smoDll) -eq $false) {
        $smoDll = "C:\Program Files\Microsoft SQL Server\130\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"
        If ((Test-Path $smoDll) -eq $false) {
            Write-Error "no usable version of smo dll is found on box."
            Throw
        }
    }
}
else {
    Write-Host "Downloading smo from NuGet"
    $smoDll = Install-SaltSmo -workingFolder $PSScriptRoot
}
[System.Reflection.Assembly]::LoadFrom($smoDll)
If ((Test-Path $JobManifestXmlFile) -eq $false) {
    Write-Error "job manifest file not found!"
    Throw
}
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