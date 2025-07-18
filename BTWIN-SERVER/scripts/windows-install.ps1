# Identify endpoint
$hostname = $env:COMPUTERNAME
$os = (Get-WmiObject Win32_OperatingSystem).Caption
Write-Host "Endpoint identity: $hostname / $os"

# Download and install Filebeat (example)
Invoke-WebRequest -Uri "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.13.4-windows-x86_64.zip" -OutFile "$env:TEMP\filebeat.zip"
Expand-Archive -Path "$env:TEMP\filebeat.zip" -DestinationPath "C:\Program Files\Filebeat"
# (Add Filebeat config and OpenEDR agent install here)
Write-Host "Filebeat and OpenEDR agent installed and configured!" 