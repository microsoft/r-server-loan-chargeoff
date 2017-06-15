################################################################################################
# Powershell script for setting up the solution template. This script checks out the solution 
# from github and deploys it to SQL Server on the local Data Science VM (DSVM).
# 
# Parameters:
#            serverName - Name of the server with SQL Server with R Services (this is the DSVM server)
#            baseurl - url from which to download data files
#            username - login username for the server
#            password - login password for the server
################################################################################################
param([string]$serverName,[string]$baseurl,[string]$username,[string]$password)

$originalLocation = Get-Location
# This is the directory for the data/code download
$solutionTemplateSetupDir = "LoanChargeOffSolution"
$solutionTemplateSetupPath = "D:\" + $solutionTemplateSetupDir
$dataDir = "Data"
$dataDirPath = $solutionTemplateSetupPath + "\" + $dataDir
$checkoutDir = "Code"
New-Item -Path "D:\" -Name $solutionTemplateSetupDir -ItemType directory -force
New-Item -Path $solutionTemplateSetupPath -Name $dataDir -ItemType directory -force

$setupLog = $solutionTemplateSetupDir + "setup_log.txt"
Start-Transcript -Path $setupLog -Append

cd $dataDirPath

$helpShortCutFile = "LoanChargeOffHelp.url"

# List of files to be downloaded
$dataList = "loan_info_10k", "member_info_10k", "payments_info_10k", "loan_info_100k", "member_info_100k", "payments_info_100k", "loan_info_1m", "member_info_1m", "payments_info_1m"
$dataExtn = ".csv"
$hashExtn = ".hash"
foreach ($dataFile in $dataList)
{
    $down = $baseurl + '/' + $dataFile + $dataExtn
    Write-Host $down
    Start-BitsTransfer -Source $down  
}

#checkout setup scripts/code from github
cd $solutionTemplateSetupPath
Remove-Item $checkoutDir -Force -Recurse
git clone -n https://github.com/Microsoft/r-server-loan-chargeoff $checkoutDir
cd $checkoutDir
git config core.sparsecheckout true
echo "/*`r`n!HDI" | out-file -encoding ascii .git/info/sparse-checkout
git checkout master

$sqlsolutionCodePath = $solutionTemplateSetupPath + "\" + $checkoutDir + "\SQL"
cd $sqlsolutionCodePath

# make sure the hashes match for data files
foreach ($dataFile in $dataList)
{
	$dataFileHash = $dataDirPath + "\" + $dataFile + $dataExtn | Get-Hash -Algorithm SHA512
	$storedHash = $dataFile + $hashExtn | Get-Content
	if ($dataFileHash.Hash -ne $storedHash)
	{
		Write-Host -ForeGroundColor 'Red' "Data file has been corrupted. Please try again."
		throw
	}
}
# making sure that the data files conform to windows style of line ending. 
foreach ($dataFile in $dataList)
{
    unix2dos $dataFile + $dataExtn
}

# Start the script for DB creation. Due to privilege issues with SYSTEM user (the user that runs the 
# extension script), we use ps-remoting to login as admin use and run the DB creation scripts

$passwords = $password | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$serverName\$username", $passwords)
$command1 = "runDB.ps1"
$command2 ="setupHelp.ps1"

Enable-PSRemoting -Force
Invoke-Command  -Credential $credential -ComputerName $serverName -FilePath $command1 -ArgumentList $dataDirPath, $sqlsolutionCodePath
Invoke-Command  -Credential $credential -ComputerName $serverName -FilePath $command2 -ArgumentList $helpShortCutFile
Disable-PSRemoting -Force

cd $originalLocation.Path
Stop-Transcript

