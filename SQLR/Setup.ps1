<#
.SYNOPSIS
Powershell script for setting up the solution template. 

.DESCRIPTION
This script checks out the solution from github and deploys it to SQL Server on the local Data Science VM (DSVM).

.WARNING: This script is only meant to be run from the solution template deployment process.

.PARAMETER serverName
Name of the server with SQL Server with R Services (this is the DSVM server)

.PARAMETER baseurl
url from which to download data files

.PARAMETER username
login username for the server

.PARAMETER password
login password for the server

#>
param([string]$serverName,[string]$baseurl,[string]$username,[string]$password)

$startTime= Get-Date
Write-Host "Start time for setup is:" $startTime
$originalLocation = Get-Location
# This is the directory for the data/code download
$solutionTemplateSetupDir = "LoanChargeOffSolution"
$solutionTemplateSetupPath = "D:\" + $solutionTemplateSetupDir
$dataDir = "Data"
$dataDirPath = $solutionTemplateSetupPath + "\" + $dataDir
$checkoutDir = "Source"
New-Item -Path "D:\" -Name $solutionTemplateSetupDir -ItemType directory -force
New-Item -Path $solutionTemplateSetupPath -Name $dataDir -ItemType directory -force

$setupLog = $solutionTemplateSetupPath + "\setup_log.txt"
Start-Transcript -Path $setupLog -Append

cd $dataDirPath

# List of files to be downloaded
$dataList = "loan_info_10k", "member_info_10k", "payments_info_10k", "loan_info_100k", "member_info_100k", "payments_info_100k", "loan_info_1m", "member_info_1m", "payments_info_1m"
$dataExtn = ".csv"
$hashExtn = ".hash"
foreach ($dataFile in $dataList)
{
    $down = $baseurl + '/' + $dataFile + $dataExtn
    Write-Host -ForeGroundColor 'magenta' "Downloading file $down..."
    Start-BitsTransfer -Source $down  
}

#checkout setup scripts/code from github
cd $solutionTemplateSetupPath

if (Test-Path $checkoutDir)
{
	Remove-Item $checkoutDir -Force -Recurse
}

git clone -n https://github.com/Microsoft/r-server-loan-chargeoff $checkoutDir
cd $checkoutDir
git config core.sparsecheckout true
echo "/*`r`n!HDI`r`n!/SQLR/Setup.ps1" | out-file -encoding ascii .git/info/sparse-checkout
git checkout master

$sqlsolutionCodePath = $solutionTemplateSetupPath + "\" + $checkoutDir + "\SQLR"
$helpShortCutFilePath = $sqlsolutionCodePath + "\LoanChargeOffHelp.url"
cd $sqlsolutionCodePath

# make sure the hashes match for data files
Write-Host -ForeGroundColor 'magenta' "Checking integrity of downloaded files..."
foreach ($dataFile in $dataList)
{
	$dataFileHash = Get-FileHash ($dataDirPath + "\" + $dataFile + $dataExtn) -Algorithm SHA512
	$storedHash = Get-Content ($dataFile + $hashExtn)
	if ($dataFileHash.Hash -ne $storedHash)
	{
		Write-Error "Data file has been corrupted. Please try again."
		throw
	}
}
Write-Host -ForeGroundColor 'magenta' "File integrity check successful."

# Start the script for DB creation. Due to privilege issues with SYSTEM user (the user that runs the 
# extension script), we use ps-remoting to login as admin use and run the DB creation scripts

$passwords = $password | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$serverName\$username", $passwords)
$command1 = "runDB.ps1"
$command2 ="setupHelp.ps1"

Enable-PSRemoting -Force
Invoke-Command  -Credential $credential -ComputerName $serverName -FilePath $command1 -ArgumentList $dataDirPath, $sqlsolutionCodePath
Invoke-Command  -Credential $credential -ComputerName $serverName -FilePath $command2 -ArgumentList $helpShortCutFilePath, $solutionTemplateSetupPath
Disable-PSRemoting -Force

cd $originalLocation.Path
$endTime= Get-Date
$totalTime = $endTime - $startTime
Write-Host "Finished running setup at " $endTime
Write-Host "Total time for setup:" $totalTime
Stop-Transcript

