Write-Host "`nThis script will enable PowerShell remoting and script execution."
$userName = Read-Host -Prompt "`nEnter user name:"
$cred = Get-Credential -Credential $userName
$target = Read-Host -Prompt "`nEnter the computer name to enable remoting on:"
Write-Host "`nVerifying connectivity..."
if (!(Test-Connection -quiet $target))
{
    throw "`nFailed to connect to target host $target. Please confirm that the hostname is correct and that the remote host has network connectivity."
    exit
}
Write-Host "`nEnabling PowerShell remoting..."
try
{
	#Add the path to psexec.exe
    Start-Process -FilePath "psexec.exe" -ArgumentList "\\$target -s powershell Enable-PSRemoting -Force" -Verb runAs
}
catch {
    throw "`nFailed to enable PowerShell remoting on the remote host."
    exit
}
Read-Host -Prompt "`nPress Enter AFTER the psexec window closes."
Write-Host "`nPowerShell remoting enabled on $target."
Write-Host "`nChanging script execution policy on $target..."
try
{
    Invoke-Command -ComputerName $target -Credential $cred { Set-ExecutionPolicy -ExecutionPolicy Unrestricted }
}
catch
{
    throw "`nUnable to change script execution policy. Are you logged in as an administrator?"
    exit
}
Write-Host "`nSuccess!"