# Harkins Log Collector
Write-Host @"

 ██╗  ██╗ █████╗ ██████╗ ██╗  ██╗██╗███╗   ██╗███████╗
 ██║  ██║██╔══██╗██╔══██╗██║ ██╔╝██║████╗  ██║██╔════╝
 ███████║███████║██████╔╝█████╔╝ ██║██╔██╗ ██║███████╗
 ██╔══██║██╔══██║██╔══██╗██╔═██╗ ██║██║╚██╗██║╚════██║
 ██║  ██║██║  ██║██║  ██║██║  ██╗██║██║ ╚████║███████║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝
                                                        
  ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ 
 ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
 ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝
 ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗
 ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║
  ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
                                                        
"@ -ForegroundColor Cyan

Start-Sleep -Seconds 1
Write-Host "Initializing Log Collection..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

$ComputerName = $env:COMPUTERNAME
$CurrentDate = Get-Date -Format "yyyyMMdd_HHmmss"
$BaseFolder = "C:\ForensicLogs\$ComputerName`_$CurrentDate"

if (!(Test-Path $BaseFolder)) {
    New-Item -ItemType Directory -Path $BaseFolder
}

# Define logs to collect (focused on security-relevant logs)
$LogsToCollect = @(
    "Security",
    "System",
    "Application",
    "Microsoft-Windows-PowerShell/Operational",
    "Microsoft-Windows-Sysmon/Operational",
    "Microsoft-Windows-Windows Defender/Operational",
    "Microsoft-Windows-TaskScheduler/Operational",
    "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational",
    "Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational",
    "Microsoft-Windows-DNS-Client/Operational",
    "Microsoft-Windows-NetworkProfile/Operational",
    "Microsoft-Windows-Windows Firewall With Advanced Security/Firewall",
    "Microsoft-Windows-LSA/Operational",
    "Microsoft-Windows-Authentication/AuthenticationPolicyFailures-DomainController",
    "Microsoft-Windows-PrintService/Operational",
    "Microsoft-Windows-Windows Defender/WHC",
    "Microsoft-Windows-AppLocker/EXE and DLL",
    "Microsoft-Windows-AppLocker/MSI and Script",
    "Microsoft-Windows-BitLocker/BitLocker Management",
    "Microsoft-Windows-CodeIntegrity/Operational"
)

function Export-LogSafely {
    param (
        [string]$LogName,
        [string]$OutputPath
    )
    
    try {
        Write-Host "Exporting $LogName..." -ForegroundColor Yellow
        $sanitizedLogName = $LogName.Replace('/', '-')
        $outputFile = Join-Path $OutputPath "$sanitizedLogName.evtx"
        
        # Export the log
        wevtutil epl "$LogName" "$outputFile" 2>$null
        
        if (Test-Path $outputFile) {
            Write-Host "Successfully exported $LogName" -ForegroundColor Green
        } else {
            Write-Host "Failed to export $LogName - File not created" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error exporting $LogName : $_" -ForegroundColor Red
    }
}

$LogFolder = Join-Path $BaseFolder "EventLogs"
New-Item -ItemType Directory -Path $LogFolder -Force

foreach ($Log in $LogsToCollect) {
    Export-LogSafely -LogName $Log -OutputPath $LogFolder
}

# Export system information
Write-Host "Exporting System Information..." -ForegroundColor Yellow
$SystemInfoPath = Join-Path $BaseFolder "SystemInfo.txt"
systeminfo > $SystemInfoPath

# Export network configuration
Write-Host "Exporting Network Configuration..." -ForegroundColor Yellow
$NetworkInfoPath = Join-Path $BaseFolder "NetworkInfo.txt"
ipconfig /all > $NetworkInfoPath
Get-NetAdapter | Format-List * >> $NetworkInfoPath
Get-NetIPAddress | Format-List * >> $NetworkInfoPath

# Export running processes
Write-Host "Exporting Process List..." -ForegroundColor Yellow
$ProcessPath = Join-Path $BaseFolder "Processes.txt"
Get-Process | Format-List * > $ProcessPath

# Export service information
Write-Host "Exporting Service Information..." -ForegroundColor Yellow
$ServicesPath = Join-Path $BaseFolder "Services.txt"
Get-Service | Format-List * > $ServicesPath

# Export scheduled tasks
Write-Host "Exporting Scheduled Tasks..." -ForegroundColor Yellow
$TasksPath = Join-Path $BaseFolder "ScheduledTasks.txt"
Get-ScheduledTask | Format-List * > $TasksPath

# Create summary file
$SummaryPath = Join-Path $BaseFolder "CollectionSummary.txt"
@"
Forensic Log Collection Summary
Computer Name: $ComputerName
Collection Date: $(Get-Date)
Collection Path: $BaseFolder

Collected Items:
- Event Logs (in EventLogs folder)
- System Information
- Network Configuration
- Running Processes
- Service Information
- Scheduled Tasks

Note: Some logs may not be available depending on system configuration and permissions.
"@ | Out-File $SummaryPath

Write-Host "`nCollection Complete!" -ForegroundColor Green
Write-Host "Logs saved to: $BaseFolder" -ForegroundColor Cyan
Write-Host "Remember to check CollectionSummary.txt for details about the collection." -ForegroundColor Yellow
