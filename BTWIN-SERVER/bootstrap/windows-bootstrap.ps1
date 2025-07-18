Invoke-WebRequest -Uri "https://YOUR-BTWIN-SERVER/scripts/windows-install.ps1" -OutFile "$env:TEMP\edr-agent-install.ps1"
& "$env:TEMP\edr-agent-install.ps1" 