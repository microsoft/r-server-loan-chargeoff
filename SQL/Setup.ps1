################################################################################################
# Powershell script for setting up the solution template. This script checks out the solution 
# from github and deploys it to SQL Server on the local Data Science VM (DSVM).
# 
# Parameters:
#            serverName - Name of the server with SQL Server with R Services (this is the DSVM server)
#            baseurl = 
#            username = login username for the server
#            password = login password for the server
################################################################################################
param([string]$serverName,[string]$baseurl,[string]$username,[string]$password)

# This is the directory for the data/code download
$solutionTemplateSetupDir = "D:\SolutionTemplateSetup"
$dataDir = $solutionTemplateSetupDir + "Data"
$checkoutDir = "LoanChargeOff"
New-Item -Name $solutionTemplateSetupDir -ItemType directory

$setupLog = $solutionTemplateSetupDir + "setup_log.txt"
Start-Transcript -Path $setupLog -Append

cd $dataDir

$helpShortCutFile = "LoanChargeOffHelp.url"

# List of files to be downloaded
$dataList = "loan_info_10k.csv", "member_info_10k.csv", "payments_info_10k.csv", "loan_info_1m.csv", "member_info_1m.csv", "payments_info_1m.csv","step1_create_tables_10k.sql","step1_create_tables_1m.sql","step2_features_label_view_10k.sql","step2_features_label_view_1m.sql","step2a_optional_feature_selection.sql","step3_train_test_model.sql","step4_chargeoff_batch_prediction.sql","step4a_chargeoff_ondemand_prediction.sql","createuser.sql","Loan_ChargeOff.ps1","runDB.ps1","runDB_LargeDataSet.ps1","setupHelp.ps1",$helpShortCutFile
foreach ($dataFile in $dataList)
{
    $down = $baseurl + '/' + $dataFile
    Write-Host $down
    Start-BitsTransfer -Source $down  
}

cd $solutionTemplateSetupDir
git clone -n https://github.com/Microsoft/r-server-loan-chargeoff $checkoutDir
cd $checkoutDir
git config core.sparsecheckout true
echo "/*`r`n!HDI" | out-file -encoding ascii .git/info/sparse-checkout
git checkout master

# making sure that the data files conform to windows style of line ending. 

$dataList = "loan_info_10k.csv", "member_info_10k.csv", "payments_info_10k.csv", "loan_info_1m.csv", "member_info_1m.csv", "payments_info_1m.csv"
foreach ($dataFile in $dataList)
{
    unix2dos $dataDir + "/" + $dataFile 
}


# Start the script for DB creation. Due to privilege issues with SYSTEM user (the user that runs the 
# extension script), we use ps-remoting to login as admin use and run the DB creation scripts

$passwords = $password | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$serverName\$username", $passwords)
$command1 = "C:\Windows\Temp\runDB.ps1"
$command2 ="C:\Windows\Temp\setupHelp.ps1"

Enable-PSRemoting -Force
Invoke-Command  -Credential $credential -ComputerName $serverName -FilePath $command1 -ArgumentList $dataDir
Invoke-Command  -Credential $credential -ComputerName $serverName -FilePath $command2 -ArgumentList $helpShortCutFile
Disable-PSRemoting -Force

Stop-Transcript

