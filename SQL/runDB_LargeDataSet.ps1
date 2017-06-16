##############################################################################################
# Script to invoke the LoanChargeOff data science workflow with a larger dataset of 1,000,000
# loans. 
# It can also optionally creates a SQL Server user and stores the password in
# 'ExporedSqlPassword.txt'. Users can retrieve the password from the file and decrypt using 
# ConvertTo-SecureString commandlet in PowerShell.
#
# Parameters:
#            dbuser - (Optional) username for database LoanChargeOff
#            dbpass - (Optional) database password
#            createuser - (Optional) whethere to create a database user
##############################################################################################
Param([string]$dbuser, [string]$dbpass, [bool]$createuser = $true, [string]$datadir)
# Function to generate a temporary password for SQL Server
Function Get-TempPassword()
{
	Param
	(
		[int]$length=10,
		[string[]]$sourcedata
	)
	
	For ($loop=1; $loop -le $length; $loop++)
	{
		$TempPassword += ($sourcedata | Get-Random)
	}
	return $TempPassword
}

$passwordSource=$NULL
$dbpassword = ""
$dbusername = "rdemo"
$passwordFile = "ExportedSqlPassword.txt"
For ($a=33;$a -le 126; $a++)
{
	$passwordSource += ,[char][byte]$a
}

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
			Write-Host -ForegroundColor Yellow "Either ExportedSqlPassword.txt must exist with encrypted database password or must provide password using dbpass parameter."
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
	$dbpassword = Get-TempPassword -length 15 -sourcedata $passwordSource
	$securePassword = $dbpassword | ConvertTo-SecureString -AsPlainText -Force
	$secureTxt = $securePassword | ConvertFrom-SecureString
	Set-Content $passwordFile $secureTxt
	
	sqlcmd -S $env:COMPUTERNAME -v username="$dbusername" -v password="$dbpassword" -i .\createuser.sql  
}

.\Loan_ChargeOff.ps1 -ServerName $env:COMPUTERNAME -DBName LoanChargeOff -username $dbusername -password $dbpassword -uninterrupted y  -dataPath $datadir -dataSize L
