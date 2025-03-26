# Function to list and execute PowerShell scripts on a USB drive
function List-And-Execute-Scripts {
    # Check if the script is running as administrator
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Restarting the script with administrator privileges..."
        Start-Process powershell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
        exit
    }

    # Bypass the execution policy for the current session
    Set-ExecutionPolicy Bypass -Scope Process -Force

    # Get all connected USB drives
    $usbDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }

    if ($usbDrives.Count -eq 0) {
        Write-Host "No USB drives found." -ForegroundColor Red
        return
    }

    Write-Host "Detected USB drives:"
    for ($i = 0; $i -lt $usbDrives.Count; $i++) {
        Write-Host "$($i + 1). $($usbDrives[$i].DeviceID) - $($usbDrives[$i].VolumeName)"
    }

    # Ask the user to select a USB drive by number
    $driveChoice = Read-Host "Enter the number of the USB drive you want to select (e.g., 1)"

    # Validate the user's choice
    if (-not ($driveChoice -as [int]) -or $driveChoice -lt 1 -or $driveChoice -gt $usbDrives.Count) {
        Write-Host "Invalid choice." -ForegroundColor Red
        return
    }

    # Get the selected drive
    $selectedDrive = $usbDrives[$driveChoice - 1].DeviceID

    # Check if the drive exists
    if (-not (Test-Path "${selectedDrive}\")) {
        Write-Host "Invalid or not found drive." -ForegroundColor Red
        return
    }

    # Search for PowerShell scripts (*.ps1) on the selected drive
    $scripts = Get-ChildItem -Path "${selectedDrive}\" -Recurse -Filter "*.ps1"

    if ($scripts.Count -eq 0) {
        Write-Host "No PowerShell scripts (*.ps1) found on drive ${selectedDrive}." -ForegroundColor Yellow
        return
    }

    # Display the found scripts
    Write-Host "Scripts found on drive ${selectedDrive}:"
    for ($i = 0; $i -lt $scripts.Count; $i++) {
        Write-Host "$($i + 1). $($scripts[$i].FullName)"
    }

    # Ask the user to select a script to execute
    $choice = Read-Host "Enter the number of the script you want to execute (or 'q' to exit)"

    if ($choice -eq 'q') {
        Write-Host "Exiting..." -ForegroundColor Yellow
        return
    }

    # Validate the user's choice
    if (-not ($choice -as [int]) -or $choice -lt 1 -or $choice -gt $scripts.Count) {
        Write-Host "Invalid choice." -ForegroundColor Red
        return
    }

    # Execute the selected script
    $selectedScript = $scripts[$choice - 1].FullName
    Write-Host "Executing script: $selectedScript" -ForegroundColor Green
    Start-Process powershell -ArgumentList "-File `"$selectedScript`"" -Verb RunAs
}

# Call the function
List-And-Execute-Scripts