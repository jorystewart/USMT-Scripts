Write-Host "`n`nThis script calls ScanState for all domain user accounts logged in in the past 7 days."
Read-Host -Prompt "Press Enter to continue..."
Write-Host "`nExecuting:"
#Replace all instances of TARGETPATH with the path to where you want to save the user state file
Write-Host "`nscanstate TARGETPATH /i:MigApp.xml /i:MigDocs.xml /localonly /ue:$env:COMPUTERNAME\* /uel:7 /l:TARGETPATH\scanstate.log /listfiles:TARGETPATH\filelist.log /o"
#Replace SCANSTATE_PATH with the location where scanstate.exe is located
Push-Location -Path "SCANSTATE_PATH"
$StopWatch = [system.diagnostics.stopwatch]::startNew()
#Replace all instances of TARGETPATH with the path to where you want to save the user state file
.\scanstate TARGETPATH /i:MigApp.xml /i:MigDocs.xml /localonly /ue:$env:COMPUTERNAME\* /uel:7 /l:TARGETPATH\scanstate.log /listfiles:TARGETPATH\filelist.log /o
$StopWatch.Stop()
Write-Host "`nScanState completed in " $StopWatch.Elapsed.Hours " hours and " $StopWatch.Elapsed.Minutes " minutes and " $StopWatch.Elapsed.Seconds " seconds."
Write-Host "`nUSMTUtils will now verify the integrity of the migration store.`n"
$StopWatch = [system.diagnostics.stopwatch]::startNew()
Write-Host "`nExecuting:"
#Replace TARGETPATH with the same path you chose above.
Write-Host "`nusmtutils TARGETPATH\USMT.MIG /verify:failureonly /l:TARGETPATH\verify.log"
$ErrorActionPreference = "silentlycontinue"
.\usmtutils /verify:failureonly TARGETPATH\USMT.MIG /l:TARGETPATH\verify.log
$ErrorActionPreference = "continue"
Write-Host "`nVerification completed in " $StopWatch.Elapsed.Hours " hours and " $StopWatch.Elapsed.Minutes " minutes and " $StopWatch.Elapsed.Seconds " seconds."
#Replace TARGETPATH with the same path you chose above.
Write-Host "`nA log has been written to TARGETPATH\verify.log"
Read-Host -Prompt "Press Enter to exit..."
Pop-Location
Exit-PSHostProcess
