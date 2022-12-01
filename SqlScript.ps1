$REPO_SQL = "D:\CompareSQL\SQL-Updated"
$SERVER_SQL = "D:\CompareSQL\SQL-Present"
$Folder = "SQL_SCRIPTS"
$Date = $Folder + (Get-Date).tostring("dd-MM-yyyy")
$dest = New-Item -itemtype Directory -Path "D:\CompareSQL\CompareResult" -Name ($Date)

# Get all files under $folder1, filter out directories
$firstFolder = Get-ChildItem -Recurse $REPO_SQL | Where-Object { -not $_.PsIsContainer }

$failedCount = 0
$i = 0
$totalCount = $firstFolder.Count
$firstFolder | ForEach-Object {
    $i = $i + 1
    Write-Progress -Activity "Searching Files" -status "Searching File  $i of     $totalCount" -percentComplete ($i / $firstFolder.Count * 100)
    # Check if the file, from $REPO_SQL, exists with the same path under $SERVER_SQL
    If ( Test-Path ( $_.FullName.Replace($REPO_SQL, $SERVER_SQL) ) ) {
        # Compare the contents of the two files...
        If ( Compare-Object (Get-Content $_.FullName) (Get-Content $_.FullName.Replace($REPO_SQL, $SERVER_SQL) ) ) {
            # List the paths of the files containing diffs
            $fileSuffix = $_.FullName.TrimStart($REPO_SQL)
            $failedCount = $failedCount + 1
            Write-Host "$fileSuffix is on each server, but does not match"
        }
    }
    else
    {
        $fileSuffix = $_.FullName.TrimStart($REPO_SQL)
        $failedCount = $failedCount + 1
        Write-Host "$fileSuffix is only in REPO_SQL"
    }
}

$secondFolder = Get-ChildItem -Recurse $SERVER_SQL | Where-Object { -not $_.PsIsContainer }

$i = 0
$totalCount = $secondFolder.Count
$secondFolder | ForEach-Object {
    $i = $i + 1
    Write-Progress -Activity "Searching for files only on second folder" -status "Searching File  $i of $totalCount" -percentComplete ($i / $secondFolder.Count * 100)
    # Check if the file, from $SERVER_SQL, exists with the same path under $REPO_SQL
    If (!(Test-Path($_.FullName.Replace($SERVER_SQL, $REPO_SQL))))
    {
        $fileSuffix = $_.FullName.TrimStart($SERVER_SQL)
        $failedCount = $failedCount + 1
        Write-Host "$file Suffix is only in SERVER_SQL"
    }
}
$AllDiffs = Compare-Object $firstFolder $secondFolder -Property Name,Length -PassThru

$Changes = $AllDiffs | Where-Object {$_.Directory.Fullname -eq $REPO_SQL}
$Changes | Copy-Item -Destination $dest 

#Provide SQLServerName
$SQLServer ="AIO-CO-HOSHAYYA\SQLEXPRESS"
#Provide Database Name
$DatabaseName ="master"
#Scripts Folder Path
$FolderPath ="$dest"
$file = "SCRIPT_log"
$d = $file + (Get-Date).tostring("dd-MM-yyyy")
$out = New-Item -itemtype File -Path "D:\CompareSQL\CompareResult" -Name ($d + ".txt")



#Loop through the .sql files and run them
foreach ($filename in get-childitem -path $FolderPath -recurse -file -filter "*.sql" |  
 sort-object)
{
   invoke-sqlcmd -InputFile $filename.fullname -ServerInstance $SQLServer -Database $DatabaseName 
   
    
    if($?) 
           
      {

        Write-Host $filename.fullname + " File executed successfully"  -foregroundcolor "green";
        "successfully executed $filename" | out-file -Append $out 

      }

    else

      {

        Write-Host $filename.fullname + " File execution FAILED" -foregroundcolor "red";
        "execution FAILED $filename" | out-file -Append  $out
      } 
       
}