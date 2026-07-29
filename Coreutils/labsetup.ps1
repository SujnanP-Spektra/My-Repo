<#
    labsetup.ps1  —  PHASE 1 (machine preparation, runs as SYSTEM)

    Lab: Windows Developer Platform: Coreutils & Dev Config Quick-Start
    Invoked once by the Azure Custom Script Extension after VM provisioning.

    SCOPE — deliberately minimal.
    This script does ONLY what the lab cannot do for itself:

      1. Stage the lab folder tree, sample log data and the Module 2 fallback slot.
      2. Enable Developer Mode. Module 2 cannot run packaged WinUI apps without it.
      3. Enable the optional Windows features, which require a reboot.
      4. Refresh the WinGet client, because `winget configure` needs the DSC v3
         processor and the in-box client may predate it.
      5. Download dev-config.winget and register Phase 2 to apply it at first logon.

    EXPLICITLY NOT DONE HERE, and why:

      * PowerShell 7 and .NET SDK 10 — the Microsoft dev-config installs both in
        Phase 2 (Microsoft.PowerShell, Microsoft.dotnet.SDK.10). Installing them
        twice adds provisioning time for no benefit.
      * Coreutils for Windows — installing it IS Exercise 01, Task 2.
      * Windows Terminal, VS Code, Git — installed by the dev-config in Phase 2,
        and inspected by the attendee in Exercise 01, Task 3.
      * "Show file extensions" — this is Exercise 01, Task 3, step 11. Pre-setting
        it would remove the exercise.
      * Long paths, Sudo, sideloading, execution policy — not used anywhere in
        either exercise.
#>

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$labRoot   = 'C:\LabFiles'
$workDir   = Join-Path $labRoot 'DevQuickStart'
$refDir    = Join-Path $labRoot 'Reference'
$prereqDir = Join-Path $labRoot '_prereq'
$setupDir  = Join-Path $labRoot '_setup'
$logFile   = Join-Path $setupDir 'labsetup-phase1.log'

foreach ($d in @($labRoot, $workDir, $refDir, $prereqDir, $setupDir)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0}  [{1}]  {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

Write-Log '================ PHASE 1 START ================'
Write-Log "Host $env:COMPUTERNAME | build $((Get-CimInstance Win32_OperatingSystem).BuildNumber)"

# ---------------------------------------------------------------------------
# 1. Lab tree, permissions, sample data
# ---------------------------------------------------------------------------
try {
    $acl  = Get-Acl $labRoot
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'BUILTIN\Users','FullControl','ContainerInherit,ObjectInherit','None','Allow')
    $acl.SetAccessRule($rule)
    Set-Acl -Path $labRoot -AclObject $acl
    Write-Log 'Applied Users:FullControl to C:\LabFiles'
} catch {
    Write-Log "ACL apply failed: $($_.Exception.Message)" 'WARN'
}

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
    # devlog.txt — has a final newline
    [IO.File]::WriteAllText((Join-Path $workDir 'devlog.txt'), (($logLines -join "`r`n") + "`r`n"))
    # devlog-noeol.txt — identical, NO trailing newline. Drives the wc -l lesson
    # in Exercise 01 Task 4, so the two files must differ only in that respect.
    [IO.File]::WriteAllText((Join-Path $workDir 'devlog-noeol.txt'), ($logLines -join "`r`n"))
    Write-Log "Staged devlog.txt ($($logLines.Count) lines) and devlog-noeol.txt"
} catch {
    Write-Log "Sample data staging failed: $($_.Exception.Message)" 'ERROR'
}

Set-Content -Path (Join-Path $refDir 'README.txt') -Encoding UTF8 -Value @'
Reference WinUI 3 project — fallback for Exercise 02.

If an attendee's agent cannot produce a project that builds after two attempts,
they copy DevLogViewer from here to C:\LabFiles\DevLogViewer and continue from
Task 3.

TO DO before first delivery: build a DevLogViewer that satisfies all five
success criteria in Exercise 02 Task 4 and place it in this folder.
'@

# ---------------------------------------------------------------------------
# 2. Developer Mode — the one registry setting the lab genuinely depends on.
#    Module 2 cannot deploy or run a packaged WinUI 3 app without it. The
#    dev-config sets it too, but Module 2 must not depend on Phase 2 succeeding.
# ---------------------------------------------------------------------------
try {
    $unlock = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    if (-not (Test-Path $unlock)) { New-Item -Path $unlock -Force | Out-Null }
    New-ItemProperty -Path $unlock -Name 'AllowDevelopmentWithoutDevLicense' `
        -Value 1 -PropertyType DWord -Force | Out-Null
    Write-Log 'Developer Mode enabled'
} catch {
    Write-Log "Developer Mode registry write failed: $($_.Exception.Message)" 'ERROR'
}

# ---------------------------------------------------------------------------
# 3. Optional features.
#    VirtualMachinePlatform is the important one: the dev-config's RebootForVmp
#    resource tests for the vmcompute service, so satisfying it here means the
#    config skips its own Restart-Computer -Force during Phase 2.
#    Containers-DisposableClientVM backs the optional Windows Sandbox task in
#    Exercise 01 Task 3. Remove it from this list if you cut that task — doing
#    so also removes the nested-virtualization requirement on the VM size.
# ---------------------------------------------------------------------------
foreach ($f in @('VirtualMachinePlatform','Microsoft-Windows-Subsystem-Linux','Containers-DisposableClientVM')) {
    try {
        if ((Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction Stop).State -ne 'Enabled') {
            Enable-WindowsOptionalFeature -Online -FeatureName $f -All -NoRestart -ErrorAction Stop | Out-Null
            Write-Log "Enabled optional feature: $f"
        } else {
            Write-Log "Already enabled: $f"
        }
    } catch {
        Write-Log "Could not enable ${f}: $($_.Exception.Message)" 'WARN'
    }
}

# ---------------------------------------------------------------------------
# 4. Refresh the WinGet client.
#    dev-config.winget is a DSC v3 document and needs the dscv3 processor.
#    Best effort: if this fails, Phase 2 logs the client version it found.
# ---------------------------------------------------------------------------
try {
    $bundle = Join-Path $prereqDir 'winget.msixbundle'
    Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $bundle -UseBasicParsing -TimeoutSec 300
    Add-AppxProvisionedPackage -Online -PackagePath $bundle -SkipLicense -ErrorAction Stop | Out-Null
    Write-Log 'Provisioned current App Installer (WinGet) machine-wide'
} catch {
    Write-Log "App Installer refresh failed - Phase 2 will report the in-box version: $($_.Exception.Message)" 'WARN'
}

# ---------------------------------------------------------------------------
# 5. Download the dev-config document applied in Phase 2
# ---------------------------------------------------------------------------
$devConfig = Join-Path $prereqDir 'dev-config.winget'
try {
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 300 `
      -Uri 'https://raw.githubusercontent.com/microsoft/WindowsDeveloperConfig/main/windows-dev-config/dev-config.winget' `
      -OutFile $devConfig
    Write-Log "Downloaded dev-config.winget ($([math]::Round((Get-Item $devConfig).Length/1KB,1)) KB)"
} catch {
    Write-Log "dev-config.winget download failed - Phase 2 will retry: $($_.Exception.Message)" 'WARN'
}

# ---------------------------------------------------------------------------
# 6. Register Phase 2 for the attendee's first interactive logon.
#    winget runs in user context and is unreliable under SYSTEM, so every
#    winget operation belongs in Phase 2 rather than here.
# ---------------------------------------------------------------------------
try {
    $src = Join-Path $PSScriptRoot 'labsetup-user.ps1'
    $dst = Join-Path $prereqDir   'labsetup-user.ps1'
    if (-not (Test-Path $src)) { throw 'labsetup-user.ps1 not found alongside labsetup.ps1' }

    Copy-Item $src $dst -Force
    Register-ScheduledTask -TaskName 'CloudLabs-DevQuickStart-Phase2' -Force `
        -Action    (New-ScheduledTaskAction -Execute 'powershell.exe' `
                     -Argument "-ExecutionPolicy Bypass -WindowStyle Normal -File `"$dst`"") `
        -Trigger   (New-ScheduledTaskTrigger -AtLogOn) `
        -Principal (New-ScheduledTaskPrincipal -GroupId 'BUILTIN\Users' -RunLevel Highest) `
        -Settings  (New-ScheduledTaskSettingsSet -StartWhenAvailable `
                     -ExecutionTimeLimit (New-TimeSpan -Hours 2)) | Out-Null
    Write-Log 'Registered scheduled task CloudLabs-DevQuickStart-Phase2 (at logon)'
} catch {
    Write-Log "Phase 2 NOT registered: $($_.Exception.Message)" 'ERROR'
}

# ---------------------------------------------------------------------------
# 7. Summary and reboot for the optional features
# ---------------------------------------------------------------------------
[ordered]@{
    Phase            = 1
    CompletedUtc     = (Get-Date).ToUniversalTime().ToString('s')
    DeveloperMode    = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name AllowDevelopmentWithoutDevLicense -EA SilentlyContinue).AllowDevelopmentWithoutDevLicense
    SampleDataStaged = (Test-Path (Join-Path $workDir 'devlog.txt'))
    DevConfigStaged  = (Test-Path $devConfig)
    Phase2Registered = [bool](Get-ScheduledTask -TaskName 'CloudLabs-DevQuickStart-Phase2' -EA SilentlyContinue)
} | ConvertTo-Json | Set-Content -Path (Join-Path $setupDir 'labsetup-phase1-summary.json') -Encoding UTF8

Write-Log '================ PHASE 1 COMPLETE - restarting for optional features ================'
Start-Process shutdown.exe -ArgumentList '/r /t 90 /c "Lab setup complete - restarting"' -NoNewWindow
exit 0
