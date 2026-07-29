<#
    labsetup-user.ps1  —  PHASE 2 (runs at the attendee's first interactive logon)

    Lab: Windows Developer Platform: Coreutils & Dev Config Quick-Start

    WHY THIS EXISTS
    ---------------
    winget runs in user context and is unreliable under SYSTEM, so everything
    winget-dependent lives here rather than in the Custom Script Extension.

    WHAT IT DOES
    ------------
    Applies the Microsoft Windows Developer Configuration once, before the
    attendee starts the lab. The dev-config installs 13 packages including
    PowerShell 7, Git, GitHub CLI, GitHub Copilot CLI, VS Code, .NET SDK 10 and
    the Windows Application CLI, and applies ~24 developer-friendly registry
    settings.

    Pre-applying it means:
      * The attendee never waits through a 30-40 minute install during a timed
        60-minute exercise.
      * The hard reboot inside the dev-config does not drop their RDP session.
        Phase 1 already enabled Virtual Machine Platform, so the config's
        RebootForVmp resource finds vmcompute present and no-ops.
      * Exercise 01 Task 2 becomes a REAL exercise: the attendee runs the same
        one command and observes idempotency, with every resource reporting it
        is already in the desired state.

    WHAT IT DELIBERATELY DOES NOT DO
    --------------------------------
    It does not install Coreutils for Windows, Windows Terminal, VS Code or Git
    beyond whatever the dev-config itself installs. Installing Coreutils is
    Exercise 01 Task 2, and inspecting the configured tools is Task 3.
#>

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$labRoot   = 'C:\LabFiles'
$prereqDir = Join-Path $labRoot '_prereq'
$setupDir  = Join-Path $labRoot '_setup'
$logFile   = Join-Path $setupDir 'labsetup-phase2.log'
$doneMark  = Join-Path $setupDir 'phase2.done'
$taskName  = 'CloudLabs-DevQuickStart-Phase2'

New-Item -ItemType Directory -Path $setupDir -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0}  [{1}]  {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

# Idempotent: if a previous logon already completed Phase 2, exit immediately.
if (Test-Path $doneMark) {
    Write-Log 'Phase 2 already completed on a previous logon - nothing to do'
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    exit 0
}

Write-Log '================ PHASE 2 START ================'
Write-Log "Running as: $env:USERNAME"

# ---------------------------------------------------------------------------
# 1. Wait for winget to become available in this session
# ---------------------------------------------------------------------------
$winget = $null
for ($i = 1; $i -le 30; $i++) {
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($cmd) { $winget = $cmd.Source; break }
    Write-Log "Waiting for winget to register (attempt $i/30)..."
    Start-Sleep -Seconds 10
}

if (-not $winget) {
    Write-Log 'winget never became available. Dev-config cannot be applied automatically.' 'ERROR'
    Write-Log 'Fallback: the attendee must apply C:\LabFiles\_prereq\dev-config.winget manually.' 'ERROR'
    exit 1
}

$wingetVersion = (& $winget --version) -join ''
Write-Log "winget found at $winget (version $wingetVersion)"

# Accept source agreements once so later calls are non-interactive
& $winget source update --accept-source-agreements 2>&1 | Out-Null
Write-Log 'winget sources updated'

# ---------------------------------------------------------------------------
# 2. Apply the Microsoft Windows Developer Configuration
#    Canonical invocation from the microsoft/WindowsDeveloperConfig README.
# ---------------------------------------------------------------------------
$devConfig = Join-Path $prereqDir 'dev-config.winget'

if (-not (Test-Path $devConfig)) {
    Write-Log 'dev-config.winget missing from _prereq - attempting a live download' 'WARN'
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 300 `
          -Uri 'https://raw.githubusercontent.com/microsoft/WindowsDeveloperConfig/main/windows-dev-config/dev-config.winget' `
          -OutFile $devConfig
        Write-Log 'Downloaded dev-config.winget'
    } catch {
        Write-Log "Could not obtain dev-config.winget: $($_.Exception.Message)" 'ERROR'
    }
}

if (Test-Path $devConfig) {
    Write-Log 'Validating dev-config.winget'
    & $winget configure validate --file $devConfig 2>&1 | ForEach-Object { Write-Log "  validate: $_" }

    Write-Log 'Applying dev-config.winget (this installs 13 packages and ~24 settings - expect 20-40 minutes)'
    $sw = [Diagnostics.Stopwatch]::StartNew()

    # --disable-interactivity is required for unattended application.
    & $winget configure --file $devConfig `
        --accept-configuration-agreements --disable-interactivity 2>&1 |
        ForEach-Object { Write-Log "  configure: $_" }

    $sw.Stop()
    Write-Log ('dev-config apply finished in {0:N1} minutes (exit code {1})' -f $sw.Elapsed.TotalMinutes, $LASTEXITCODE)
} else {
    Write-Log 'dev-config.winget unavailable - skipping' 'ERROR'
}

# ---------------------------------------------------------------------------
# 3. Verify what the dev-config delivered.
#    These are Module 2's prerequisites, installed as a side effect of Module 1's
#    subject matter - which is the narrative link between the two exercises.
# ---------------------------------------------------------------------------
$expected = @(
    @{ Id = 'Microsoft.PowerShell';       Label = 'PowerShell 7 (required by Coreutils)' }
    @{ Id = 'Microsoft.dotnet.SDK.10';    Label = '.NET SDK 10 (required by WinUI 3)'    }
    @{ Id = 'Microsoft.VisualStudioCode'; Label = 'VS Code'                              }
    @{ Id = 'Git.Git';                    Label = 'Git'                                  }
    @{ Id = 'GitHub.Cli';                 Label = 'GitHub CLI'                           }
    @{ Id = 'GitHub.Copilot';             Label = 'GitHub Copilot CLI (Module 2 agent)'   }
    @{ Id = 'Microsoft.winappcli';        Label = 'Windows Application CLI (Module 2)'    }
)

$results = @{}
foreach ($e in $expected) {
    $out = (& $winget list --id $e.Id --exact 2>&1) -join "`n"
    $ok  = $out -notmatch 'No installed package'
    $results[$e.Id] = $ok
    Write-Log ('{0} {1}' -f $(if ($ok) { '[ OK ]' } else { '[MISS]' }), $e.Label)
}

# ---------------------------------------------------------------------------
# 4. Confirm the state Module 1 and Module 2 depend on
# ---------------------------------------------------------------------------
$devMode = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
              -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
Write-Log "Developer Mode = $devMode (must be 1 for Module 2 packaged apps)"

$ps7 = Test-Path "$env:ProgramFiles\PowerShell\7\pwsh.exe"
if ($ps7) {
    $ps7v = & "$env:ProgramFiles\PowerShell\7\pwsh.exe" -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
    Write-Log "PowerShell version available: $ps7v (Coreutils requires 7.4 or later)"
} else {
    Write-Log 'PowerShell 7 not found - Coreutils will not behave correctly in Module 1' 'WARN'
}

# Coreutils must NOT be installed - installing it is Module 1's exercise
$cu = (& $winget list --id Microsoft.Coreutils --exact 2>&1) -join "`n"
if ($cu -match 'No installed package') {
    Write-Log '[ OK ] Coreutils absent, as intended - Module 1 installs it'
} else {
    Write-Log 'Coreutils is already installed. Module 1 Task 2 will show it as already present.' 'WARN'
}

# ---------------------------------------------------------------------------
# 5. Write summary, mark complete, remove the logon task
# ---------------------------------------------------------------------------
$summary = [ordered]@{
    Phase           = 2
    CompletedUtc    = (Get-Date).ToUniversalTime().ToString('s')
    RanAs           = $env:USERNAME
    WingetVersion   = $wingetVersion
    DevConfigApplied= (Test-Path $devConfig)
    Packages        = $results
    DeveloperMode   = $devMode
    PowerShell7     = $ps7
    CoreutilsAbsent = ($cu -match 'No installed package')
    ReadyForLab     = ($ps7 -and $devMode -eq 1 -and $results['Microsoft.dotnet.SDK.10'])
}
$summary | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $setupDir 'labsetup-phase2-summary.json') -Encoding UTF8

Set-Content -Path $doneMark -Value (Get-Date).ToUniversalTime().ToString('s') -Encoding UTF8
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

Write-Log ('ReadyForLab = {0}' -f $summary.ReadyForLab)
Write-Log '================ PHASE 2 COMPLETE ================'
exit 0
