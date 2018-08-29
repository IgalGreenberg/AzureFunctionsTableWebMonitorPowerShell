# [sourcecode language='powershell' ]
$url = [System.Configuration.ConfigurationManager]::AppSettings["url"]
$SQLInstance = [System.Configuration.ConfigurationManager]::AppSettings["SQLInstance"]
$SQLDatabase = [System.Configuration.ConfigurationManager]::AppSettings["SQLDatabase"]
$SQLUsername = [System.Configuration.ConfigurationManager]::AppSettings["SQLUsername"]
$SQLPassword = [System.Configuration.ConfigurationManager]::AppSettings["SQLPassword"]

$statusCode = 0
$statusDescription = ''
$IsSuccess = 1
$PageLoadStartTime = ((Get-Date -Format u) -replace "Z", "")
$PageLoadDuration = '00:00:00.000000'

try {
  $PageLoadDuration = (Measure-Command {$WebResponse = Invoke-WebRequest $url -UseBasicParsing}).ToString()
  $statusCode = $WebResponse.StatusCode
  $statusDescription = $WebResponse.StatusDescription
} catch [System.Net.WebException] {
  Write-Output "System.Net.WebException catch";
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
  try {
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server = $SQLInstance ; Database = $SQLDatabase ; User ID = $SQLUsername ; Password = $SQLPassword ;Encrypt = 'true'"  
    $SqlConnection.Open()
    $sqlCommand = new-object System.Data.SqlClient.SqlCommand
    $sqlCommand.CommandTimeout = 120
    $sqlCommand.Connection = $sqlConnection
    $sqlCommand.CommandText= $stmt
    $text = $stmt.Substring(0, 50)
    Write-Output "Executing SQL => $text..."
    $result = $sqlCommand.ExecuteNonQuery()
    $sqlConnection.Close()
  } catch {
    Write-Output "generic catch";
    $e = $_.Exception
    $msg = $e.Message
    while ($e.InnerException) {
      $e = $e.InnerException
      $msg += "`n" + $e.Message
    }
    $statusDescription = $msg
    $PageLoadDuration = (NEW-TIMESPAN -Start $PageLoadStartTime -End (Get-Date)).ToString()
    Write-Output $statusDescription;
    Write-Output $PageLoadDuration;
  }
}
