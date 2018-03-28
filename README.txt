The scripts are completely portable. It does not matter if they reside on the local hard drive, on a removable drive, or on the network. Sysinternals psexec.exe is required to remotely enable PowerShell remoting.
There are two methods: One executes the scripts remotely via a local terminal, and the other requires remoting in the source and destination computers and running the script manually.

Executing remotely:

Navigate to the script location.
Type ./scanRemote.ps1 and follow the prompts.
Type ./loadRemote.ps1 and follow the prompts.

Remoting to computer and running scripts manually:

On the source computer, right click on Windows Powershell and choose to run as an administrator.
Navigate to the script location.
Type ./migRecentUsers.ps1
Follow the prompts from the script.

On the destination computer, right click on Windows Powershell and choose to run as an administrator.
Navigate to the script location.
Type ./loadRecentUsers.ps1
Follow the prompts from the script. You will need to enter the name of the source computer.
Troubleshooting:

1)	PowerShell returns the following error stating that a script cannot be loaded because running scripts is disabled on this system

Solution: Open PowerShell as an administrator and type in the following:

Set-ExecutionPolicy –ExecutionPolicy unrestricted –Scope process

The above command allows scripts to run, but only in the current shell. If you remove the –Scope flag, scripts will be allowed until you change the execution policy back:

Set-ExecutionPolicy –ExecutionPolicy unrestricted

To disable scripts again:

Set-ExecutionPolicy –ExecutionPolicy Restricted



2)	scanRemote.ps1 fails with an error stating that the remote computer is reachable, but is not accepting commands.


Solution: Run the enableRemoting.ps1 script. Follow the prompts to enable PowerShell remoting and script execution on the remote host, then run scanRemote.ps1 again.
