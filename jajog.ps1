param (
    [string]$messagecontain = "*", 
    [string]$startTime = "*",    
    [string]$endTime = "*",
    [string]$hourStart = "*",
    [string]$hourEnd = "*",
    [string]$id = "*",
    [string]$logontype = "*"
)

#MOIS/JOUR/ANNEE

Write-Output "Started"

$filter = ""
$nameFile = "JajogResult_"

if ($startTime -ne "*") {
    $Oldest = Get-Date -Day $startTime.split('/')[0] -Month $startTime.split('/')[1] -Year $startTime.split('/')[2] -Hour 0 -Minute 0 -Second 0
    $filter = 'StartTime='''+$Oldest+''';'
    $forName = $Oldest -replace ' ','_'
    $forName = $forName -replace ':','_'
    $nameFile = $nameFile+'StartTime'+$forName
}

if ($endTime -ne "*") {
    $Recent = Get-Date -Day $endTime.split('/')[0] -Month $endTime.split('/')[1] -Year $endTime.split('/')[2] -Hour 0 -Minute 0 -Second 0
    $filter = $filter+'EndTime='''+$endTime+''';'
    $forName = $Oldest -replace ' ','_'
    $forName = $forName -replace ':','_'
    $nameFile = $nameFile+'EndTime'+$forName
}

if($id -ne '*') {
    $filter = $filter+'ID='''+$id+''';'
    $nameFile = $nameFile+'ID'+$id
}

$eval = ' | '

if($hourStart -ne '*' -and $hourEnd -eq '*') {
    "Missing hourEnd"
    exit
}

elseif ($hourStart -eq '*' -and $hourEnd -ne '*') {
    "Missing hourStart"
    exit
}
elseif($hourStart -ne '*' -and $hourEnd -ne '*') {
    if ($hourStart -gt $hourEnd) {
        $eval = '| ?{ (($_.TimeCreated.Hour -ge '+$hourStart+') -OR ($_.TimeCreated.Hour -lt '+$hourEnd+')) } |'
    }
    else {
        $eval = '| ?{ (($_.TimeCreated.Hour -ge '+$hourStart+') -AND ($_.TimeCreated.Hour -lt '+$hourEnd+')) } |'
    }
    $nameFile = $nameFile+'HourStart'+$hourStart+'HourEnd'+$hourEnd
}

if ($messagecontain -ne '*') {
  #$evalmessage = '| Where-Object -Property Message -Match '''+$messagecontain+''''
  $evalmessage = '| where { $_.Message | Select-String "'+$messagecontain+'"}'
  $nameFile = $nameFile+'MessageContain'+$evalmessage
}

if ($logontype -ne '*') {
  $evallogon = '| Where-Object {$_.properties[8].value -in '+$logontype+'}'
  $tmp = $logontype -replace ' ',''
  $tmp = $tmp -replace ',','_'
  $nameFile = $nameFile+'LogonType'+$tmp
}

Get-ChildItem -include *.evt,*.evtx -Path .\ -recurse |

ForEach-Object {


Try
{ 
  "Current file : $($_.fullname)`r`n"
  $command = 'Get-WinEvent -FilterHashtable @{Path='''+$_.fullname+''';'+$filter+'} -EA Stop '+$evallogon+$evalmessage+$eval+' Select-Object machinename,timecreated,id,leveldisplayname,message | select machinename,timecreated,id,leveldisplayname,message | export-csv -Encoding UTF8 -Append -Path .\$nameFile.csv -NoTypeInformation | Out-Null'
  Invoke-Expression $command
  "Event found"
}

Catch [System.Exception] {$_.Exception.Message}

}