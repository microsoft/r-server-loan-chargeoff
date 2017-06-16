##############################################################################################
# Script to invoke the LoanChargeOff data science workflow with a smaller dataset of 10,000
# loans. 
# It also creates a SQL Server user and stores the password in 'ExporedSqlPassword.txt'. 
# Users can retrieve the password from the file and decrypt using ConvertTo-SecureString 
# commandlet in PowerShell.
#
# Parameters:
#            datadir - directory where raw csv data has been downloaded
#            script - directory where scripts are checked out from github
#            dbuser - (Optional) username for database LoanChargeOff
#            dbpass - (Optional) database password
#            createuser - (Optional) whethere to create a database user
#            datasize - size of the data to train on (10k, 100k, 1m)
##############################################################################################
Param([string]$datadir, [string]$scriptdir, [string]$dbuser, [string]$dbpass, [bool]$createuser = $true, [ValidateSet("10k", "100k", "1m")][string]$datasize="10k")
cd $scriptdir

$dbpassword = ""
$dbusername = "rdemo"
$passwordFile = "ExportedSqlPassword.txt"

if ($dbuser)
{
	$dbusername = $dbuser
}
if (!$createuser)
{
	if (!$dbpass)
	{
		if (Test-Path $passwordFile)
		{
			$secureTxtFromFile = Get-Content $passwordFile
			$securePasswordObj = $secureTxtFromFile | ConvertTo-SecureString
			#get back the original unencrypted password
			$PasswordBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePasswordObj)
			$dbpassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordBSTR)
		}
		else
		{
			Write-Host -ForegroundColor DarkYellow "Either ExportedSqlPassword.txt must exist with encrypted database password or must provide password using dbpass parameter."
			throw
		}
	}
	else
	{
		$dbpassword = $dbpass
	}
}
else
{
	Write-Host -ForegroundColor Cyan "Creating database user"
	[Reflection.Assembly]::LoadWithPartialName("System.Web")
	$dbpassword = [System.Web.Security.Membership]::GeneratePassword(15,0)
	$securePassword = $dbpassword | ConvertTo-SecureString -AsPlainText -Force
	$secureTxt = $securePassword | ConvertFrom-SecureString
	Set-Content $passwordFile $secureTxt
	
	sqlcmd -S $env:COMPUTERNAME -v username="$dbusername" -v password="$dbpassword" -i .\createuser.sql  
}

.\Loan_ChargeOff.ps1 -ServerName $env:COMPUTERNAME -DBName LoanChargeOff -username $dbusername -password $dbpassword -uninterrupted y -dataPath $datadir -dataSize $datasize
