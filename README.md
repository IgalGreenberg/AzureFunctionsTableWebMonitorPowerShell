# AzureFunctionsTableWebMonitorPowerShell
A little script that runs in Azure Functions and populates an Azure SQL table with page load timings of a given web page.

## Create an Azure SQL database
Create an Azure SQL Database and create the following:
```TSQL
CREATE TABLE [dbo].[webpageloadlog](
	[logid] [int] IDENTITY(0,1) NOT NULL,
	[siteurl] [nvarchar](1000) NOT NULL,
	[PageLoadStartTime] [datetime] NOT NULL,
	[PageLoadDuration] [time](7) NOT NULL,
	[IsSuccess] [bit] NOT NULL,
	[StatusCode] [int] NULL,
	[StatusDescription] [nvarchar](1000) NULL,
	[RawContentLength] [int] NULL
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Igal Greenberg
-- Create Date: 26 Aug 2018
-- Description: Insert a web log
-- =============================================
CREATE PROCEDURE [dbo].[insertwebpageloadlog]
(
	@siteurl nvarchar(1000)
	,@PageLoadStartTime datetime
	,@PageLoadDuration time(7)
	,@IsSuccess bit
	,@StatusCode int
	,@StatusDescription nvarchar(1000)
	,@RawContentLength int = 0
)
AS
BEGIN
SET NOCOUNT ON
	INSERT INTO [dbo].[webpageloadlog]
	([siteurl],[PageLoadStartTime],[PageLoadDuration],[IsSuccess]
	,[StatusCode],[StatusDescription],[RawContentLength])
	VALUES
	(@siteurl,@PageLoadStartTime,@PageLoadDuration,@IsSuccess
	,@StatusCode,@StatusDescription,@RawContentLength)
END
GO
```
## Create an Azure Function using PowerShell.
Setup the these variables for the azure function application settings:

| APP SETTING NAME | Description                   |
| :--------------- |:------------------------------:| 
| url              | The site one wishes to monitor | 
| SQLInstance      | Azure SQL Instance             |
| SQLDatabase      | Azure SQL Database name        |
| SQLUsername      | Azure SQL Username             |
| SQLPassword      | Azure SQL Password             |

Deploy the code from run.ps1 to the function body.

## The result
One should be able to see the pefromance load times of their website in Azure SQL:
![Website Load Performance](https://github.com/IgalGreenberg/AzureFunctionsTableWebMonitorPowerShell/blob/master/WebsiteLoadPerformanceData.PNG?raw=true)
