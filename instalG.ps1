# Verificar se o script está sendo executado como administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting the script with administrator privileges..."
    Start-Process powershell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Bypass da política de execução para a sessão atual
Set-ExecutionPolicy Bypass -Scope Process -Force

# Nome do arquivo ISO
$isoFileName = "Setup 2025.iso"  # Substitua pelo nome correto do arquivo ISO

# Procurar a unidade flash que contém a ISO
$usbDrive = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -and (Test-Path "$($_.DeviceID)\$isoFileName") }

if ($usbDrive) {
    $isoPath = "$($usbDrive.DeviceID)\$isoFileName"
    Write-Host "ISO found at: $isoPath"

    # Montar a ISO
    try {
        $mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru -ErrorAction Stop
    } catch {
        Write-Host "Failed to mount the ISO: $($Error[0].Exception.Message)"
        exit
    }

    if ($mountResult) {
        # Obter a letra da unidade montada
        $mountedDriveLetter = (Get-Volume -DiskImage $mountResult).DriveLetter
        Write-Host "ISO mounted on drive: $mountedDriveLetter"

        # Lista de instaladores e seus parâmetros de instalação silenciosa
        $installers = @(
            @{ Name = "WinRAR"; Path = "$mountedDriveLetter`:\winrar-x64-701.exe"; Args = "/S" },
            @{ Name = "7-Zip"; Path = "$mountedDriveLetter`:\7z2409 (1).exe"; Args = "/S" },
            @{ Name = "Google Chrome"; Path = "$mountedDriveLetter`:\Disseuque\4. Navegadores\Chrome 2025.exe"; Args = "/silent /install" },
            @{ Name = "MPC-HC"; Path = "$mountedDriveLetter`:\Disseuque\3. Multimidea\1. MPC-HC.1.9.7 Sitole .x64.exe"; Args = "/S /D=C:\MPC" },
            @{ Name = "VLC"; Path = "$mountedDriveLetter`:\Disseuque\3. Multimidea\2. VLC 3.0.21 x32 Original.exe"; Args = "/S /D=C:\VLC /norestart" },
            @{ Name = "AnyDesk"; Path = "$mountedDriveLetter`:\Disseuque\AnyDesk Original.exe"; Args = "--install `"$env:ProgramFiles\AnyDesk`" --silent --start-with-win --create-shortcuts" },
            @{ Name = "Adobe Reader"; Path = "$mountedDriveLetter`:\Disseuque\Adobe Reader (Win 7).exe"; Args = "/silent /install" },
            @{ Name = "Zuma Deluxe"; Path = "$mountedDriveLetter`:\Disseuque\ZumaDeluxe.exe"; Args = "/silent /install" },
            @{ Name = "Office 2013"; Path = "$mountedDriveLetter`:\Disseuque\1. Office\2013 Pro PT x64\Microsoft Office 2013 X64\setup.exe"; Args = "/silent /install" },
            @{ Name = "Avast"; Path = "$mountedDriveLetter`:\Disseuque\6. Antivirus\Avast 2025 Original.exe"; Args = "/silent /install" }
        )

        # Display enumerated list of applications
        Write-Host "Choose the applications to install by typing the numbers separated by commas or 'Q' to quit."
        for ($i = 0; $i -lt $installers.Count; $i++) {
            Write-Host "$($i + 1). $($installers[$i].Name)"
        }
        Write-Host "If no choice is made within 15 seconds, all applications will be installed automatically."

        # Get user choice with timeout
        $choice = $null
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        while ($timer.Elapsed.TotalSeconds -lt 15 -and -not $choice) {
            if ($Host.UI.RawUI.KeyAvailable) {
                $choice = Read-Host -Prompt "Enter the corresponding numbers (or 'Q' to quit)"
            }
        }
        $timer.Stop()

        if (-not $choice) {
            Write-Host "No input detected. Proceeding with automatic installation of all applications."
        } elseif ($choice -eq 'Q' -or $choice -eq 'q') {
            Write-Host "Installation canceled by the user."
            exit
        }

        # Filtrar os aplicativos escolhidos ou instalar todos se nenhuma escolha for feita
        if ($choice) {
            $selectedIndexes = $choice -split ',' | ForEach-Object { $_.Trim() -as [int] - 1 }
            $selectedInstallers = $installers[$selectedIndexes]
        } else {
            $selectedInstallers = $installers
        }

        # Instalar os aplicativos selecionados
        for ($i = 0; $i -lt $selectedInstallers.Count; $i++) {
            $installer = $selectedInstallers[$i]
            Write-Progress -Activity "Installing applications" -Status "$($installer.Name)" -PercentComplete (($i / $selectedInstallers.Count) * 100)
            if (Test-Path $installer.Path) {
                try {
                    Start-Process -FilePath $installer.Path -ArgumentList $installer.Args -Wait -ErrorAction Stop
                    Write-Host "$($installer.Name) installed successfully."
                } catch {
                    Write-Host "Error installing $($installer.Name): $($Error[0].Exception.Message)"
                }
            } else {
                Write-Host "Installer for $($installer.Name) not found at: $($installer.Path)"
            }
        }

        # Desmontar a ISO após a instalação
        try {
            Dismount-DiskImage -ImagePath $isoPath -ErrorAction Stop
            Write-Host "ISO unmounted successfully."
        } catch {
            Write-Host "Failed to unmount the ISO: $($Error[0].Exception.Message)"
        }

    } else {
        Write-Host "Failed to mount the ISO."
    }
} else {
    Write-Host "Flash drive with the ISO not found."
}