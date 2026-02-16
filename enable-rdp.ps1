# Executar como Administrador

Write-Host "Activando Remote Desktop..."

# Habilitar Remote Desktop
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
-Name "fDenyTSConnections" -Value 0

# Permitir no Firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Opcional: permitir NLA (mais seguro)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
-Name "UserAuthentication" -Value 1

Write-Host "Remote Desktop activado com sucesso."

# Abrir Remote Desktop Connection
Start-Process "mstsc.exe"
