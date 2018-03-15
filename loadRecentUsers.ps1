Write-Host "`nThis script is designed to load user state backups. You will need the name of the source computer.`n"
Read-Host -Prompt "Press Enter to continue..."
$oldComp = Read-Host -Prompt "Enter the source computer name:"
Write-Host "`nExecuting:"
Write-Host "`nloadstate TARGETPATH /i:MigApp.xml /i:MigDocs.xml /l:TARGETPATH\loadstatelog.txt /progress:TARGETPATH\loadprogresslog.txt /ue:$oldComp\* /uel:7"
Push-Location -Path "LOADSTATE_PATH"
$StopWatch = [system.diagnostics.stopwatch]::startNew()
.\loadstate TARGETPATH /i:MigApp.xml /i:MigDocs.xml /l:TARGETPATH\loadstatelog.txt /progress:TARGETPATH\loadprogresslog.txt /ue:$oldComp\* /uel:7
$StopWatch.Stop()
Write-Host LoadState complete.
Write-Host "`nTask completed in " $StopWatch.Elapsed.Hours " hours and " $StopWatch.Elapsed.Minutes " minutes."
Write-Host "`nYour computer will now restart."
Read-Host -Prompt "Press Enter to continue..."
Restart-Computer -Force