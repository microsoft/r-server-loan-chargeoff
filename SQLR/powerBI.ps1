<#
.SYNOPSIS 
Script to invoke the LoanChargeOff data science workflow

.DESCRIPTION
This script by default uses a smaller dataset of 10,000 loans for the first time. 
It creates the SQL Server user and uses it to create the database.

#>
# Download PowerBI Desktop installer
Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?LinkId=521662&clcid=0x409" -Destination powerbi-desktop.msi

# Silently install PowerBI Desktop
msiexec.exe /i powerbi-desktop.msi /qn /norestart  ACCEPT_EULA=1