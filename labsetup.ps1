<#
    labsetup.ps1
    Windows Developer Platform: Coreutils & Dev Config Quick-Start

    Runs once via the Azure Custom Script Extension as SYSTEM immediately after
    VM provisioning. Prepares machine-level state only.

    Deliberately does NOT install Windows Terminal, VS Code, Coreutils, the WinApp
    CLI or the agent plugin. Those are installed by the participant during the
    exercises, and pre-installing them would remove the point of Module 1.

    Note: winget runs in user context and is unreliable under SYSTEM, which is a
    further reason package installs are left to the lab exercises.
#>

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$logDir  = 'C:\LabFiles\_setup'
$logFile = Join-Path $logDir 'labsetup.log'
$labRoot = 'C:\LabFiles'
$workDir = Join-Path $labRoot 'DevQuickStart'
$refDir  = Join-Path $labRoot 'Reference'

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

Write-Log '=== labsetup.ps1 starting ==='

# ---------------------------------------------------------------------------
# 1. Lab folder structure
# ---------------------------------------------------------------------------
foreach ($dir in @($labRoot, $workDir, $refDir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Log "Created lab folders under $labRoot"

# Grant Users full control so the attendee's non-elevated session can write here
try {
    $acl  = Get-Acl $labRoot
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'BUILTIN\Users', 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $acl.SetAccessRule($rule)
    Set-Acl -Path $labRoot -AclObject $acl
    Write-Log 'Applied Users FullControl ACL to C:\LabFiles'
} catch {
    Write-Log "WARN: could not set ACL on ${labRoot}: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 2. Enable Developer Mode (required by WinUI 3 packaged apps in Module 2)
# ---------------------------------------------------------------------------
try {
    $unlockKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    if (-not (Test-Path $unlockKey)) { New-Item -Path $unlockKey -Force | Out-Null }
    New-ItemProperty -Path $unlockKey -Name 'AllowDevelopmentWithoutDevLicense' `
        -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $unlockKey -Name 'AllowAllTrustedApps' `
        -Value 1 -PropertyType DWord -Force | Out-Null
    Write-Log 'Developer Mode enabled'
} catch {
    Write-Log "WARN: Developer Mode registry write failed: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 3. Enable optional features for the clean-target validation task
#    Requires nested virtualization, hence the D-series requirement.
# ---------------------------------------------------------------------------
foreach ($feature in @('Containers-DisposableClientVM', 'Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')) {
    try {
        $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction Stop).State
        if ($state -ne 'Enabled') {
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart -ErrorAction Stop | Out-Null
            Write-Log "Enabled optional feature: $feature"
        } else {
            Write-Log "Optional feature already enabled: $feature"
        }
    } catch {
        Write-Log "WARN: could not enable ${feature}: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# 4. Install .NET SDK 10 machine-wide (prerequisite for WinUI 3 tooling)
# ---------------------------------------------------------------------------
try {
    $installScript = Join-Path $env:TEMP 'dotnet-install.ps1'
    Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile $installScript -UseBasicParsing
    & $installScript -Channel '10.0' -InstallDir 'C:\Program Files\dotnet' -NoPath
    Write-Log '.NET SDK 10 install script completed'

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if ($machinePath -notlike '*C:\Program Files\dotnet*') {
        [Environment]::SetEnvironmentVariable('Path', "$machinePath;C:\Program Files\dotnet", 'Machine')
        Write-Log 'Added dotnet to machine PATH'
    }
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
} catch {
    Write-Log "WARN: .NET SDK install failed: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 5. Stage Module 1 sample log data
# ---------------------------------------------------------------------------
$logLines = @(
    'INFO Build started'
    'INFO Restoring packages'
    'WARN Package cache miss'
    'INFO Build started'
    'ERROR Unit test failure in AuthTests'
    'INFO Retrying build'
    'WARN Deprecated API in use'
    'INFO Build completed'
    'ERROR Publish step failed'
    'INFO Restoring packages'
    'WARN Package cache miss'
    'INFO Build completed'
    'ERROR Unit test failure in DataTests'
    'INFO Workspace bootstrap complete'
    'WARN Extension load exceeded threshold'
)

try {
    # devlog.txt - terminated with a final newline
    $withEol = ($logLines -join "`r`n") + "`r`n"
    [System.IO.File]::WriteAllText((Join-Path $workDir 'devlog.txt'), $withEol)

    # devlog-noeol.txt - identical content, no trailing newline
    $withoutEol = $logLines -join "`r`n"
    [System.IO.File]::WriteAllText((Join-Path $workDir 'devlog-noeol.txt'), $withoutEol)

    Write-Log "Staged devlog.txt ($($logLines.Count) lines) and devlog-noeol.txt"
} catch {
    Write-Log "WARN: could not stage sample log data: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 6. Environment hardening / convenience
# ---------------------------------------------------------------------------
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
    Write-Log 'Set machine execution policy to RemoteSigned'
} catch {
    Write-Log "WARN: execution policy not set: $($_.Exception.Message)"
}

# Disable IE Enhanced Security Configuration so the portal sign-in step is not blocked
foreach ($escKey in @(
    'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}',
    'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}'
)) {
    try {
        if (Test-Path $escKey) {
            Set-ItemProperty -Path $escKey -Name 'IsInstalled' -Value 0 -Force
        }
    } catch { }
}
Write-Log 'IE ESC disabled where applicable'

# Show file extensions by default for new profiles
try {
    reg load HKLM\DefaultUser 'C:\Users\Default\NTUSER.DAT' 2>$null | Out-Null
    reg add 'HKLM\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
        /v HideFileExt /t REG_DWORD /d 0 /f 2>$null | Out-Null
    reg unload HKLM\DefaultUser 2>$null | Out-Null
    Write-Log 'Default profile set to show file extensions'
} catch {
    Write-Log "WARN: default profile tweak skipped: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 7. Reference project placeholder for the Module 2 fallback path
# ---------------------------------------------------------------------------
$refReadme = @'
Reference WinUI 3 project - fallback for Exercise 02

If a participant's agent cannot produce a project that builds after two full
attempts, they copy the DevLogViewer folder from here into
C:\LabFiles\DevLogViewer and continue from Task 3.

TO DO before first delivery: build a working DevLogViewer that satisfies all
five success criteria in Exercise 02 Task 4, and place it in this folder.
'@
Set-Content -Path (Join-Path $refDir 'README.txt') -Value $refReadme
Write-Log 'Created reference project placeholder'

# ---------------------------------------------------------------------------
# 8. Summary marker
# ---------------------------------------------------------------------------
$summary = [ordered]@{
    CompletedUtc     = (Get-Date).ToUniversalTime().ToString('s')
    DeveloperMode    = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
    DotnetPresent    = (Test-Path 'C:\Program Files\dotnet\dotnet.exe')
    SampleDataPresent= (Test-Path (Join-Path $workDir 'devlog.txt'))
    RestartRequired  = $true
}
$summary | ConvertTo-Json | Set-Content -Path (Join-Path $logDir 'labsetup-summary.json')

Write-Log '=== labsetup.ps1 complete - restart required for optional features ==='

# Optional features need a restart to become usable
Start-Process -FilePath 'shutdown.exe' -ArgumentList '/r /t 60 /c "Lab setup complete - restarting to finalise Windows features"' -NoNewWindow
exit 0
