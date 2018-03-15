$userName = Read-Host -Prompt "`nEnter user name:"
$cred = Get-Credential -Credential $userName
$target = Read-Host -Prompt "`nEnter target computer name:"
#Pings $target, if ping fails, end script
Write-Host "`nVerifying connectivity..."
if (!(Test-Connection -quiet $target))
{
    throw "`nFailed to connect to target host $target. Please confirm that the hostname is correct and that the remote host has network connectivity."
    exit
}
#Removes any existing session configuration that may conflict with the script
Write-Host "`nChecking for pre-existing session configuration..."
Remove-PSSession -ComputerName $target -ErrorAction Ignore
Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock { Unregister-PSSessionConfiguration -Name usmt -Force } -ErrorAction Ignore
#Registers session configuration on $target. Needed to bypass second hop problem
Write-Host "`nRegistering session configuration on remote host..."
try {
    Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock { Register-PSSessionConfiguration -Name usmt -RunAsCredential $using:cred -Force -WarningAction SilentlyContinue} | out-null
}
catch {
    throw "`n$target is reachable, but is not accepting remote commands. Is PowerShell active on the remote host?`n"
    exit
}
#Starts a remote PowerShell session after 3 seconds. Script fails without a delay.
Write-Host "`nCreating session..."
try {
    Start-Sleep -s 3
    $usmtSession = New-PSSession -ComputerName $target -Credential $cred -ConfigurationName usmt -ErrorAction Stop
}
catch {
	Remove-PSSession -ComputerName $target -ErrorAction Ignore
	Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock { Unregister-PSSessionConfiguration -Name usmt -Force -ErrorAction Ignore } | out-null
	throw "`nThere was an error starting a PowerShell session on the remote host.`n"
    exit
}
#Run the loadRecentUsers script, calling LoadState.
Write-Host "`nInvoking load script..."
try {
    #Replace LOADRECENTUSERS.PS1_PATH with the path to the loadRecentUsers.ps1 script
    Invoke-Command -Session $usmtSession -ScriptBlock { & LOADRECENTUSERS.PS1_PATH }
}
catch {
    throw "`nRemote connection successful, but unable to access USMT network location.`n"
    Remove-PSSession -ComputerName $target -ErrorAction Ignore
	Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock { Unregister-PSSessionConfiguration -Name usmt -Force -ErrorAction Ignore } | out-null
    exit
}
#Ends the remote session, and deletes the session configuration.
Remove-PSSession -ComputerName $target
Remove-PSSession -Session $usmtSession
Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock { Unregister-PSSessionConfiguration -Name usmt -Force}
