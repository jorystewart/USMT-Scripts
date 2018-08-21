Replace instances of $USMTPATH with the path you wish to use. Requires the USMT files to be present in that location.


Run the USMTMenu.ps1 script and follow the prompts.

Troubleshooting:

1)	PowerShell returns the following error stating that a script cannot be loaded because running scripts is disabled on this system

Solution: Open PowerShell as an administrator and type in the following:

Set-ExecutionPolicy –ExecutionPolicy unrestricted –Scope process

The above command allows scripts to run, but only in the current shell. If you remove the –Scope flag, scripts will be allowed until you change the execution policy back:

Set-ExecutionPolicy –ExecutionPolicy unrestricted

To disable scripts again:

Set-ExecutionPolicy –ExecutionPolicy Restricted



2)	Scanning or loading fails with an error stating that the remote computer is reachable, but is not accepting commands.


Solution: Ensure PowerShell remoting is enabled on the remote host. Choose option 5 at the main menu and follow the prompts to enable PowerShell remoting and script execution on the remote host, then try scanning or loading again.
