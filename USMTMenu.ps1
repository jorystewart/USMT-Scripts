function Show-Menu {
    Clear-Host
    Write-Host "============================ USMT Menu ==================================="
    Write-Host "1: Save state of a remote computer"
    Write-Host "2: Load state onto a remote computer"
    Write-Host "3: Save state of this computer"
    Write-Host "4: Load state onto this computer"
    Write-Host "5: Enable PowerShell remoting on a remote computer"
    Write-Host "`nPress q to exit."
}
function Remove-Connection {
    Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock { Unregister-PSSessionConfiguration -Name "usmt" -Force} -ErrorAction SilentlyContinue
}
function Export-Userstate {
    Write-Host "`nExecuting:"
    Write-Host "`nscanstate $USMTPATH\$env:COMPUTERNAME\State\ /i:MigApp.xml /i:MigDocs.xml /localonly /ue:$env:COMPUTERNAME\* /uel:7 /l:$USMTPATH\$env:COMPUTERNAME\scanstate.log /listfiles:$USMTPATH\$env:COMPUTERNAME\filelist.log /o"
    Push-Location -Path "FileSystem::$USMTPATH"
    $StopWatch = [system.diagnostics.stopwatch]::startNew()
    .\scanstate $USMTPATH\$env:COMPUTERNAME\State\ /i:MigApp.xml /i:MigDocs.xml /localonly /ue:$env:COMPUTERNAME\* /uel:7 /l:$USMTPATH\$env:COMPUTERNAME\scanstate.log /listfiles:$USMTPATH\$env:COMPUTERNAME\filelist.log /o
    $StopWatch.Stop()
    Write-Host "`nScanState completed in " $StopWatch.Elapsed.Hours " hours and " $StopWatch.Elapsed.Minutes " minutes and " $StopWatch.Elapsed.Seconds " seconds."
    Write-Host "`nUSMTUtils will now verify the integrity of the migration store.`n"
    $StopWatch = [system.diagnostics.stopwatch]::startNew()
    Write-Host "`nExecuting:"
    Write-Host "`nusmtutils $USMTPATH\$env:COMPUTERNAME\State\USMT\USMT.MIG /verify:failureonly /l:$USMTPATH\$env:COMPUTERNAME\verify.log"
    $ErrorActionPreference = "silentlycontinue"
    .\usmtutils /verify:failureonly $USMTPATH\$env:COMPUTERNAME\State\USMT\USMT.MIG /l:$USMTPATH\$env:COMPUTERNAME\verify.log
    $ErrorActionPreference = "continue"
    Write-Host "`nVerification completed in " $StopWatch.Elapsed.Hours " hours and " $StopWatch.Elapsed.Minutes " minutes and " $StopWatch.Elapsed.Seconds " seconds."
    Write-Host "`nA log has been written to $USMTPATH\$env:COMPUTERNAME\verify.log"
}
function Import-Userstate {
    param ($oldComp)

    Write-Host "`nExecuting:"
    Write-Host "`nloadstate $USMTPATH\$oldComp\State /i:MigApp.xml /i:MigDocs.xml /l:$USMTPATH\$oldComp\loadstatelog.txt /progress:$USMTPATH\$oldComp\loadprogresslog.txt /ue:$oldComp\* /uel:7"
    Push-Location -Path "FileSystem::$USMTPATH"
    $StopWatch = [system.diagnostics.stopwatch]::startNew()
    .\loadstate $USMTPATH\$oldComp\State\ /i:MigApp.xml /i:MigDocs.xml /l:$USMTPATH\$oldComp\loadstatelog.txt /progress:$USMTPATH\$oldComp\loadprogresslog.txt /ue:$oldComp\* /uel:7
    $StopWatch.Stop()
    Write-Host LoadState complete.
    Write-Host "`nTask completed in " $StopWatch.Elapsed.Hours " hours and " $StopWatch.Elapsed.Minutes " minutes."
    Write-Host "`nYour computer will now restart."
    Read-Host -Prompt "Press Enter to continue..."
    Restart-Computer -Force
}
function Enable-Remoting {
    $target = Read-Host -Prompt "`nEnter the computer name to enable remoting on:"
    Write-Host "`nVerifying connectivity..."
    if (!(Test-Connection -quiet $target)) {
        Write-Error -Message "`nFailed to connect to target host $target. Please confirm that the hostname is correct and that the remote host has network connectivity."
        Read-Host -Prompt "Press Enter to return to the menu..."
        Show-MainMenu
    }
    Write-Host "`nEnabling PowerShell remoting..."
    try {
        Invoke-CimMethod -ComputerName $target -Class Win32_Process -MethodName Create -Arguments @{ CommandLine="powershell.exe -Command Enable-PSRemoting -force"  }
    }
    catch {
        Write-Error -Message "`nFailed to enable PowerShell remoting on the remote host."
        Read-Host -Prompt "Press Enter to return to the menu..."
        Show-MainMenu
    }
    Write-Host "`nPowerShell remoting enabled on $target."
    Start-Sleep -Seconds "5"
    Write-Host "`nChanging script execution policy on $target..."
    try
    {
        Start-Sleep -Seconds "5"
        Invoke-Command -ComputerName $target -Credential $cred { Set-ExecutionPolicy -ExecutionPolicy Unrestricted }
    }
    catch
    {
        Write-Error -Message "`nUnable to change script execution policy. Are you logged in as an administrator?"
        Read-Host -Prompt "Press Enter to return to the menu..."
        Show-MainMenu
    }
    Write-Host "`nSuccess!"
    Read-Host -Prompt "`nPress Enter to return to the main menu."
}
function Show-MainMenu {
    do
    {
        Show-Menu
        $selection = Read-Host -Prompt "`nPlease make a selection:"
        switch ($selection)
        {
            '1'
            {
                $target = Read-Host -Prompt "`nEnter target computer name:"
                #Pings $target, if ping fails, return to menu
                Write-Host "`nVerifying connectivity..."
                if (!(Test-Connection -quiet $target)) {
                    Write-Error -Message "`nFailed to connect to target host $target. Please confirm that the hostname is correct and that the remote host has network connectivity."
                    Read-Host -Prompt "Press Enter to return to the main menu..."
                    Show-MainMenu
                }
                #Removes any existing session configuration that may conflict with the script
                Write-Host "`nChecking for pre-existing session configuration..."
                Remove-PSSession -ComputerName $target -ErrorAction Ignore
                Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock { Unregister-PSSessionConfiguration -Name "usmt" -Force } -ErrorAction Ignore
                #Registers session configuration on $target. Needed to bypass second hop problem
                Write-Host "`nRegistering session configuration on remote host..."
                try {
                    Start-Sleep -Seconds "10"
                    Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock { Register-PSSessionConfiguration -Name "usmt" -RunAsCredential $using:cred -Force -WarningAction SilentlyContinue} -ErrorAction stop | out-null
                }
                catch {
                    Write-Error -Message "`n$target is reachable, but is not accepting remote commands. Is PowerShell remoting enabled on the remote host?`n"
                    Read-Host -Prompt "Press Enter to return to the main menu..."
                    Show-MainMenu
                }
                #Starts a remote PowerShell session.
                Write-Host "`nCreating session..."
                try {
                        Start-Sleep -Seconds "5"
                        $usmtSession = New-PSSession -ComputerName $target -Credential $cred -ConfigurationName "usmt"
                    }
                catch {
                        Remove-Connection
                        Write-Error -Message "`nThere was an error starting a PowerShell session on the remote host.`n"
                        Read-Host -Prompt "Press Enter to return to the main menu..."
                        Show-MainMenu
                }
                #Run the migRecentUsers script, calling ScanState and USMTUtils.
                Write-Host "`nInvoking migration script..."
                try {
                        Invoke-Command -Session $usmtSession -ScriptBlock ${Function:Export-Userstate}
                    }
                catch {
                        Remove-Connection
                        Write-Error -Message "`nRemote connection successful, but unable to access USMT network location.`n"
                        Read-Host -Prompt "Press Enter to return to the main menu..."
                        Show-MainMenu
                }
                #Ends the remote session, and deletes the session configuration.
                Remove-Connection
            }
            '2'
            {
                $target = Read-Host -Prompt "`nEnter target computer name:"
                #Pings $target, if ping fails, end script
                Write-Host "`nVerifying connectivity..."
                if (!(Test-Connection -quiet $target)) {
                    Write-Error -Message "`nFailed to connect to target host $target. Please confirm that the hostname is correct and that the remote host has network connectivity."
                    Read-Host -Prompt "Press Enter to return to the main menu..."
                    Show-MainMenu
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
                    Write-Error -Message "`n$target is reachable, but is not accepting remote commands. Is PowerShell active on the remote host?`n"
                    Read-Host -Prompt "Press Enter to return to the main menu..."
                    Show-MainMenu
                    }
                #Starts a remote PowerShell session after 3 seconds. Script fails without a delay.
                Write-Host "`nCreating session..."
                try {
                    Start-Sleep -s 3
                    $usmtSession = New-PSSession -ComputerName $target -Credential $cred -ConfigurationName usmt -ErrorAction Stop
                    }
                catch {
                    Remove-Connection    
                    Write-Error -Message "`nThere was an error starting a PowerShell session on the remote host.`n"
                    Read-Host -Prompt "Press Enter to return to the main menu..."
                    Show-MainMenu
                    }
                #Run the loadRecentUsers script, calling LoadState.
                Write-Host "`nInvoking load script..."
                try {
                    Invoke-Command -Session $usmtSession -ScriptBlock { & Import-Userstate -oldComp $target }
                }
                catch {
                    Write-Error -Message "`nRemote connection successful, but unable to access USMT network location.`n"
                    Remove-Connection
                    Read-Host -Prompt "Press Enter to return to the main menu..."
                    Show-MainMenu
                }
                #Ends the remote session, and deletes the session configuration.
                Remove-Connection
                }
            '3'
            {
                Export-Userstate
            }
            '4'
            {
                $oldCompName = Read-Host -Prompt "`nEnter the source computer name:`n"
                Import-Userstate -oldComp $oldCompName
            }
            '5'
            {
                Enable-Remoting
            }
        }
    }
    until ($selection -eq 'q')
}
Clear-Host
Write-Host "`nEnter administrator credentials:`n"
$cred = Get-Credential
Show-MainMenu