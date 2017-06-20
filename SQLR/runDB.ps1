##############################################################################################
# Script to invoke the LoanChargeOff data science workflow with a smaller dataset of 10,000
# loans for the first time. 
# It creates a SQL Server user and stores the password in 'ExporedSqlPassword.txt'. 
# Users can retrieve the password from the file and decrypt executing GetSQLUserPassword.ps1
# script.
# WARNING: This script should only be run once through the template deployment process. It is
#          not meant to be run by users as it assumes database and users don't already exist.
# Parameters:
#            datadir - directory where raw csv data has been downloaded
#            scriptdir - directory where scripts are checked out from github
#            datasize - size of the dataset (10k, 100k, 1m)
##############################################################################################
Param([string]$datadir, [string]$scriptdir, [string]$dbname="LoanChargeOff")
cd $scriptdir
$desktop = [Environment]::GetFolderPath("Desktop")
$dbusername = "rdemo"
$passwordFile = $desktop + "\ExportedSqlPassword.txt"

# Utility function to generate random alphanumeric password. SQL connection string does not like some of the more 
# complex passwords with special characters so limiting to alphanumeric.
Function GetRandomSQLPassword([Int]$length=30)
{
	$passwordChars = 48..57 + 65..90 + 97..122
	Get-Random -Count $length -InputObject $passwordChars | % -begin {$pwd=$null} -process {$pwd +=[char]$_} -end {$pwd}
}
# create the database user
Write-Host -ForegroundColor 'Cyan' "Creating database user"
$dbpassword = GetRandomSQLPassword

# Variables to pass to createuser.sql script
# Cannot use -v option as sqlcmd does not like special characters which maybe part of the randomly generated password.
$sqlcmdvars = @{"username" = "$dbusername"; "password" = "$dbpassword"}
$old_env = @{}

foreach ($var in $sqlcmdvars.GetEnumerator()) {
	# Save Environment
	$old_env.Add($var.Name, [Environment]::GetEnvironmentVariable($var.Value, "User"))
	[Environment]::SetEnvironmentVariable($var.Name, $var.Value)
}
try {
	#sqlcmd -S $env:COMPUTERNAME -b -i .\createuser.sql
	Invoke-Sqlcmd -ServerInstance $env:COMPUTERNAME -InputFile .\createuser.sql
	# save password securely for later retrieval
	$securePassword = $dbpassword | ConvertTo-SecureString -AsPlainText -Force
	$secureTxt = $securePassword | ConvertFrom-SecureString
	Set-Content $passwordFile $secureTxt
} catch {
	Write-Host -ForegroundColor 'Yellow' "Error creating database user, see error message output"
	Write-Host -ForegroundColor 'Red' $Error[0].Exception 
} finally {
	# Restore Environment
	foreach ($var in $old_env.GetEnumerator()) {
		[Environment]::SetEnvironmentVariable($var.Name, $var.Value)
	}
}
Write-Host -ForegroundColor 'Cyan' "Done creating database user"

# Create database if doesn't exist
$query = "IF NOT EXISTS(SELECT * FROM sys.databases WHERE NAME = '$dbname') CREATE DATABASE $dbname"
Invoke-Sqlcmd -ServerInstance $ServerName -Username $dbusername -Password "$dbpassword" -Query $query -ErrorAction SilentlyContinue
if ($? -eq $false)
{
	Write-Host -ForegroundColor Red "Failed to execute sql query to create database."
}
.\Loan_ChargeOff.ps1 -ServerName $env:COMPUTERNAME -DBName $dbname -username $dbusername -password "$dbpassword" -uninterrupted y -dataPath $datadir
