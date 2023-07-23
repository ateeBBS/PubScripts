#
# THIS SCRIPT IS READY TO USE
#

# Schedule task parameters
# PowerShell.exe
# -windowstyle hidden C:\Scripts\Automated_Windows_Updates.ps1
# Execute Script as Administrator
Function Check-RunAsAdministrator()
{
  #Get current user context
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  
  #Check user is running the script is member of Administrator Group
  if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Write-host "Script is running with Administrator privileges!"
  }
  else
    {
       #Create a new Elevated process to Start PowerShell
       $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
 
       # Specify the current script path and name as a parameter
       $ElevatedProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
 
       #Set the Process to elevated
       $ElevatedProcess.Verb = "runas"
 
       #Start the new elevated process
       [System.Diagnostics.Process]::Start($ElevatedProcess)
 
       #Exit from the current, unelevated, process
       Exit
 
    }
}


# Script to automatically install Windows updates
Function InstallWindowsModules
{
    # Installs NuGet with Forced
    Install-PackageProvider -Name NuGet -Force

    # Trusts Microsofts PSGallery
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    
    # Install PSWindowsUpdate Module
    Install-Module PSWindowsUpdate

    # Sets Progress file to 1, to indicate modules etc. are installed.
    Set-Content C:\AutoUpdates\Progress.txt -Value 1
}

Function InstallWindowsUpdates
{
    # Gets latest Windows updates
    Get-WindowsUpdate | Out-File C:\AutoUpdates\History\Updates_"$((Get-Date).ToString('dd-MM-yyyy_HH.mm.ss'))".txt

    #Installs updates, accepts all automatically and reboots.
    Install-WindowsUpdate -Install -AcceptAll -AutoReboot
}


# Checks if folder "AutoUpdates already exists on the server. If it doesn't it creates it."
$ChkPath = "C:\AutoUpdates"
$PathExists = Test-Path $ChkPath
If ($PathExists -eq $false)
{
    mkdir C:\AutoUpdates
    mkdir C:\AutoUpdates\History
}
else
{
    # Do nothing
}


$ChkFile = "C:\AutoUpdates\Progress.txt"
$FileExists = Test-Path $ChkFile
If ($FileExists -eq $false)
{
    New-Item C:\AutoUpdates\Progress.txt
    Set-Content C:\AutoUpdates\Progress.txt -Value 0
}
else
{
    # Do nothing
}



# Reads the file for status
# This is the logic used to control the installation status of the server.
$Status = Get-Content C:\AutoUpdates\Progress.txt -First 1

If ($Status -eq 0) 
{
    # Installs required modules
    InstallWindowsModules
    InstallWindowsUpdates
}
elseif ($Status -eq 1)
{
    # Installs windows updates
    InstallWindowsUpdates
}
