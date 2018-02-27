#Require -Version 5.0
# [sourcecode language='powershell' ]
$url = [System.Configuration.ConfigurationManager]::AppSettings["url"]
$storageAccountName = [System.Configuration.ConfigurationManager]::AppSettings["storageAccountName"]
$storageAccountKey = [System.Configuration.ConfigurationManager]::AppSettings["storageAccountKey"]
$tableName = [System.Configuration.ConfigurationManager]::AppSettings["tableName"]

$ctx = New-AzureStorageContext $storageAccountName -StorageAccountKey $storageAccountKey

function GetOrCreateTable ($storageContext, $tableName) {
    $table = Get-AzureStorageTable –Name $tableName -Context $ctx -ErrorAction Ignore
 
    if ($table -eq $null) {
       $table = New-AzureStorageTable –Name $tableName -Context $ctx
    }
 
    return $table
}

 
$table = GetOrCreateTable $ctx $tableName

# adds a new row to an azure table but checks at first if entry already exists
function Add-Entity($table, $partitionKey, $rowKey, $values) {
  # check if entry already exists
  $existing = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Retrieve($partitionKey, $rowKey))
  if($existing.HttpStatusCode -eq "200") { return; }
 
  $entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity $partitionKey, $rowKey
 
  foreach($value in $values.GetEnumerator()) {
    $entity.Properties.Add($value.Key, $value.Value);
  }
 
  $result = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($entity))
}
# usage sample:
#$values = @{"MyKey" = "MyValue"; "MySecondKey" = "MySecondValue"; "CurrentDate" = (get-date)}
#Add-Entity $table "MyPartitionKey" "MyRowKey" $values
try
{ 
    $s = [int][double]::Parse((Get-Date -UFormat %s)) 
    $m = Measure-Command {$res = Invoke-WebRequest $url -UseBasicParsing}
}
catch { break; }

$values = @{ "Url" = $url;
    "StartTime"=$s;
    "DurationSeconds"=$m.TotalSeconds;
    "StatusCode"=$res.StatusCode;
    "StatusDescription"=$res.StatusDescription;
    "RawContentLength"=$res.RawContentLength
}

Add-Entity $table $tableName $s $values
