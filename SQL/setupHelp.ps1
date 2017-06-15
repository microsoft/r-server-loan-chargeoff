param( [string]$helpfile)

#git clone 
$desktop = [Environment]::GetFolderPath("Desktop")

$desktop = $desktop + '\'

#create the help link in startup program 

$startmenu = [Environment]::GetFolderPath("StartMenu")
$startupfolder = $startmenu + '\Programs\Startup\'
# We create this since the user startup folder is only created after first login 
# Alternative is to add is to all user startup
mkdir $startupfolder
#copy 
$down = $helpfile
Write-Host $down
Write-Host $startmenu
ls $startmenu
Write-Host $startupfolder
ls $startupfolder
cp -Verbose $down $startupfolder
cp -Verbose $down $desktop