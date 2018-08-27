#Require -Version 5.0
# [sourcecode language='powershell' ]
$url = [System.Configuration.ConfigurationManager]::AppSettings["url"]
$SQLInstance = [System.Configuration.ConfigurationManager]::AppSettings["SQLInstance"]
$SQLDatabase = [System.Configuration.ConfigurationManager]::AppSettings["SQLDatabase"]
$SQLUsername = [System.Configuration.ConfigurationManager]::AppSettings["SQLUsername"]
$SQLPassword = [System.Configuration.ConfigurationManager]::AppSettings["SQLPassword"]

$statusCode = 0
$statusDescription = ''
$IsSuccess = 1
try {
  $PageLoadStartTime = ((Get-Date -Format u) -replace "Z", "")
  $PageLoadDuration = '00:00:00.000000'
  $WebResponse = Invoke-WebRequest $url -TimeoutSec 30
  $statusCode = $WebResponse.StatusCode
  $statusDescription = $WebResponse.StatusDescription
  $PageLoadDuration = (NEW-TIMESPAN -Start $PageLoadStartTime -End (Get-Date)).ToString()
} catch [System.Net.WebException] {
  Write-Output "generic catch";
  $Response = $_.Exception;
  Write-host "Exception caught: $Response";
  $statusCode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
  $statusDescription = ($_.Exception.Message).ToString().Trim();
  $PageLoadDuration = (NEW-TIMESPAN -Start $PageLoadStartTime -End (Get-Date)).ToString()
  $IsSuccess = 0
} catch {
  # handle all other exceptions
  Write-Output "generic catch";
  $e = $_.Exception
  $msg = $e.Message
  while ($e.InnerException) {
    $e = $e.InnerException
    $msg += "`n" + $e.Message
  }
  $statusDescription = $msg
  $PageLoadDuration = (NEW-TIMESPAN -Start $PageLoadStartTime -End (Get-Date)).ToString()
  $IsSuccess = 0;
  Write-Output $IsSuccess;
} finally {
  $stmt="EXECUTE [dbo].[insertwebpageloadlog]" +
  " @siteurl = '$url'" +
  ",@PageLoadStartTime = '$PageLoadStartTime'" +
  ",@PageLoadDuration = '$PageLoadDuration'" +
  ",@IsSuccess = $IsSuccess" +
  ",@StatusCode = $statusCode" +
  ",@StatusDescription = '" + ($statusDescription -replace "'", "''" ) + "'";

  Write-Output $stmt;
  Invoke-Sqlcmd `
    -Query $stmt `
    -ServerInstance $SQLInstance `
    -Database $SQLDatabase `
    -Username $SQLUsername `
    -Password $SQLPassword `
    -EncryptConnection
}
