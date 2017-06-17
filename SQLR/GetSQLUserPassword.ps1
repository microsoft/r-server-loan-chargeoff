##############################################################################
# Helper script to retrieve the password for 'rdemo' user if needed. During
# deployment of the solution template a new user is created with a random
# password which is stored in encrypted form in a text file. 
#
# Must be run as the same user as the Data Science VM user supplied during
# deployment.
##############################################################################
$passwordFile = "ExportedSqlPassword.txt"

$secureTxtFromFile = Get-Content $passwordFile
$securePasswordObj = $secureTxtFromFile | ConvertTo-SecureString
#get back the original unencrypted password
$PasswordBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePasswordObj)
[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordBSTR)
