Param (
    [Parameter(Mandatory = $true)]
    [string] $AzureUserName,
    [string] $AzurePassword,
    [string] $AzureTenantID,
    [string] $AzureSubscriptionID,
    [string] $ODLID,
    [string] $DeploymentID,
    [string] $adminUsername,
    [string] $adminPassword,
    [string] $trainerUserName,
    [string] $trainerUserPassword
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

# ---------------------------------------------------------------------------
# CloudLabs common functions
# The CustomScriptExtension downloads cloudlabs-windows-functions.ps1 alongside
# this script, preserving the blob's folder structure, so it dot-sources from
# .\cloudlabs-common\ in the extension's working directory.
# ---------------------------------------------------------------------------
$path = (Get-Location).Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

# ---------------------------------------------------------------------------
# Base VM configuration
# This is a plain Windows Server 2022 image, so the standard CloudLabs block
# runs in full — Chocolatey, Edge, the credentials file and the VM validator.
# ---------------------------------------------------------------------------
WindowsServerCommon
InstallAzPowerShellModule
InstallAzCLI
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID
InstallModernVmValidator
Enable-CloudLabsEmbeddedShadow $adminUsername $trainerUserName $trainerUserPassword

# Power BI Desktop is required for authoring the report in Challenge 04
InstallPowerBiDesktopChoco

# ---------------------------------------------------------------------------
# Lab-specific setup: Proactive Customer Intelligence
#
# The lab itself is browser-based. This script exists to produce the Dataverse
# import files, which are generated rather than shipped so the case dates always
# fall inside the trailing 30-day window the scoring model reads.
# ---------------------------------------------------------------------------

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force

$assetPath = "C:\Users\Public\Desktop\Lab Assets"
New-Item -ItemType Directory -Path $assetPath -Force | Out-Null
New-Item -ItemType Directory -Path C:\LabFiles -Force | Out-Null
New-Item -ItemType Directory -Path C:\Packages -Force | Out-Null

# --- Generate-LabData.ps1, written to disk so the logon task can re-run it ---
$generator = @'
<#
    Generate-LabData.ps1

    Produces every Dataverse import file the Proactive Customer Intelligence lab needs.

    All dates are computed relative to the moment this script runs, so the trailing
    30-day scoring window in Challenge 01 is always valid regardless of when the ODL
    was deployed. This script runs at CSE time and again at first user logon.

    Case CSAT and resolution values are generated with small jitter and then balanced
    so each account's average lands exactly on the documented target. That is what
    makes the expected scores in Challenge 01 reproducible.

    Output: <OutputPath>\
        accounts.csv                  Challenge 1  - 10 accounts
        cases-baseline.csv            Challenge 1  - 57 cases producing the baseline aggregates
        accounts-round2.csv           Challenge 2  - updated renewal dates for 5 accounts
        cases-round2.csv              Challenge 2  - replacement case set for 5 deteriorating accounts
        cases-recovery.csv            Challenge 5  - post-recovery case set for ACC-1008
        expected-scores.csv           Trainer reference - every expected score and tier
        README.txt                    What each file is and how to import it
#>

param(
    [string]$OutputPath = "C:\Users\Public\Desktop\Lab Assets"
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

# Deterministic jitter so repeat runs on the same VM produce identical files
$script:rng = New-Object System.Random(20260828)

$today = (Get-Date).Date

$caseTitles = @(
    "Integration endpoint returning 500 errors",
    "Invoice export missing line items",
    "User cannot access reporting module",
    "Scheduled sync failed overnight",
    "Performance degradation on dashboard load",
    "Password reset emails not delivered",
    "Data import rejected on validation",
    "API rate limit reached unexpectedly",
    "Mobile app crashes on record save",
    "Duplicate records created after merge",
    "Export to Excel truncates rows",
    "Notification rules not firing",
    "Attachment upload times out",
    "Permission change not reflected for team",
    "Repeat integration failure after last release"
)

function New-BalancedValues {
    param(
        [int]$Count,
        [double]$Target,
        [double]$Min,
        [double]$Max,
        [int]$Decimals
    )
    if ($Count -le 0) { return @() }
    if ($Count -eq 1) { return @([math]::Round($Target, $Decimals)) }

    $headroom = [math]::Min($Max - $Target, $Target - $Min)
    $jitter = [math]::Min(0.3, [math]::Max(0.0, $headroom))

    $values = @()
    for ($i = 0; $i -lt ($Count - 1); $i++) {
        $offset = ($script:rng.NextDouble() * 2 * $jitter) - $jitter
        $values += [math]::Round($Target + $offset, $Decimals)
    }
    $sum = ($values | Measure-Object -Sum).Sum
    $last = [math]::Round(($Count * $Target) - $sum, $Decimals)
    if ($last -lt $Min) { $last = $Min }
    if ($last -gt $Max) { $last = $Max }
    $values += $last
    return $values
}

function Get-HealthScore {
    param(
        [int]$Cases,
        [object]$Csat,
        [object]$ResolutionHours,
        [int]$RenewalDays,
        [int]$OpenCritical
    )
    $caseComponent = [math]::Max(0, [math]::Min(30, 30 - ($Cases * 3)))

    if ($null -eq $Csat -or $Csat -ge 4.5) { $csatComponent = 30 }
    else { $csatComponent = ($Csat / 4.5) * 30 }
    $csatComponent = [math]::Max(0, [math]::Min(30, $csatComponent))

    if ($null -eq $ResolutionHours -or $ResolutionHours -lt 4) { $resComponent = 20 }
    else { $resComponent = 20 - (($ResolutionHours - 4) * 2) }
    $resComponent = [math]::Max(0, [math]::Min(20, $resComponent))

    if ($RenewalDays -gt 90) { $contractComponent = 20 }
    else { $contractComponent = ($RenewalDays / 90) * 20 }
    $contractComponent = [math]::Max(0, [math]::Min(20, $contractComponent))

    $total = [math]::Round($caseComponent, 0, [MidpointRounding]::AwayFromZero) +
             [math]::Round($csatComponent, 0, [MidpointRounding]::AwayFromZero) +
             [math]::Round($resComponent, 0, [MidpointRounding]::AwayFromZero) +
             [math]::Round($contractComponent, 0, [MidpointRounding]::AwayFromZero)

    if ($total -ge 70) { $tier = "Green" } elseif ($total -ge 40) { $tier = "Amber" } else { $tier = "Red" }
    if ($OpenCritical -ge 2 -and $tier -eq "Green") { $tier = "Amber" }

    return [pscustomobject]@{ Score = [int]$total; Tier = $tier }
}

function New-CaseRows {
    param(
        [string]$AccountCode,
        [int]$TotalCases,
        [int]$OpenCritical,
        [object]$TargetCsat,
        [object]$TargetResolutionHours,
        [int]$WindowDays = 28
    )

    $rows = @()
    if ($TotalCases -le 0) { return $rows }

    $resolvedCount = $TotalCases - $OpenCritical
    $csatValues = @()
    $resValues = @()
    if ($resolvedCount -gt 0) {
        $csatValues = New-BalancedValues -Count $resolvedCount -Target $TargetCsat -Min 1.0 -Max 5.0 -Decimals 2
        $resValues  = New-BalancedValues -Count $resolvedCount -Target $TargetResolutionHours -Min 0.5 -Max 60.0 -Decimals 1
    }

    $seq = 1
    for ($i = 0; $i -lt $resolvedCount; $i++) {
        $ageDays = 3 + ($script:rng.Next(0, $WindowDays - 3))
        $created = $today.AddDays(-$ageDays).AddHours($script:rng.Next(8, 17))
        $resolvedOn = $created.AddHours([double]$resValues[$i])
        $rows += [pscustomobject]@{
            CaseTitle        = $caseTitles[$script:rng.Next(0, $caseTitles.Count - 1)]
            AccountCode      = $AccountCode
            CaseReference    = "$AccountCode-C{0:D3}" -f $seq
            Priority         = @("Normal", "Low", "Normal")[$script:rng.Next(0, 3)]
            Status           = "Resolved"
            CreatedOn        = $created.ToString("yyyy-MM-dd HH:mm")
            ResolvedOn       = $resolvedOn.ToString("yyyy-MM-dd HH:mm")
            CSATScore        = $csatValues[$i]
            ResolutionHours  = $resValues[$i]
        }
        $seq++
    }

    for ($i = 0; $i -lt $OpenCritical; $i++) {
        $ageDays = 1 + ($script:rng.Next(0, 10))
        $created = $today.AddDays(-$ageDays).AddHours($script:rng.Next(8, 17))
        $rows += [pscustomobject]@{
            CaseTitle        = $caseTitles[$script:rng.Next(0, $caseTitles.Count - 1)]
            AccountCode      = $AccountCode
            CaseReference    = "$AccountCode-C{0:D3}" -f $seq
            Priority         = "High"
            Status           = "Active"
            CreatedOn        = $created.ToString("yyyy-MM-dd HH:mm")
            ResolvedOn       = ""
            CSATScore        = ""
            ResolutionHours  = ""
        }
        $seq++
    }

    return $rows
}

# ---------------------------------------------------------------------------
# Baseline: Prerequisite Task 4, scored in Challenge 01
# ---------------------------------------------------------------------------

$baseline = @(
    @{ Code = "ACC-1001"; Name = "Fabrikam Residences";    CSM = "Priya Nair";  RenewalDays = 210; Cases = 0;  Csat = $null; Res = $null; Critical = 0 },
    @{ Code = "ACC-1002"; Name = "Northwind Traders";      CSM = "Priya Nair";  RenewalDays = 180; Cases = 1;  Csat = 4.6;   Res = 3.0;   Critical = 0 },
    @{ Code = "ACC-1003"; Name = "Adventure Works Cycles"; CSM = "Priya Nair";  RenewalDays = 120; Cases = 2;  Csat = 4.5;   Res = 3.5;   Critical = 0 },
    @{ Code = "ACC-1004"; Name = "Tailspin Toys";          CSM = "Jordan Blake";RenewalDays = 95;  Cases = 3;  Csat = 4.2;   Res = 5.0;   Critical = 0 },
    @{ Code = "ACC-1005"; Name = "Woodgrove Bank";         CSM = "Jordan Blake";RenewalDays = 75;  Cases = 6;  Csat = 3.6;   Res = 7.0;   Critical = 1 },
    @{ Code = "ACC-1006"; Name = "Contoso Suites";         CSM = "Jordan Blake";RenewalDays = 60;  Cases = 7;  Csat = 3.2;   Res = 9.0;   Critical = 1 },
    @{ Code = "ACC-1007"; Name = "Litware Inc.";           CSM = "Maria Chen";  RenewalDays = 45;  Cases = 8;  Csat = 3.0;   Res = 10.0;  Critical = 2 },
    @{ Code = "ACC-1008"; Name = "Proseware Inc.";         CSM = "Maria Chen";  RenewalDays = 25;  Cases = 9;  Csat = 2.6;   Res = 14.0;  Critical = 2 },
    @{ Code = "ACC-1009"; Name = "VanArsdel Ltd.";         CSM = "Maria Chen";  RenewalDays = 20;  Cases = 10; Csat = 2.4;   Res = 16.0;  Critical = 3 },
    @{ Code = "ACC-1010"; Name = "Relecloud";              CSM = "Maria Chen";  RenewalDays = 15;  Cases = 11; Csat = 2.2;   Res = 18.0;  Critical = 3 }
)

$accountRows = @()
$baselineCases = @()
$expected = @()

foreach ($a in $baseline) {
    $accountRows += [pscustomobject]@{
        AccountCode         = $a.Code
        AccountName         = $a.Name
        AssignedCSM         = $a.CSM
        ContractRenewalDate = $today.AddDays($a.RenewalDays).ToString("yyyy-MM-dd")
        CurrentHealthTier   = "Green"
        PrimaryContactEmail = ("{0}@contoso-lab.example.com" -f ($a.Name -replace '[^a-zA-Z]', '').ToLower())
        City                = "Seattle"
    }

    $baselineCases += New-CaseRows -AccountCode $a.Code -TotalCases $a.Cases -OpenCritical $a.Critical `
                                   -TargetCsat $a.Csat -TargetResolutionHours $a.Res

    $s = Get-HealthScore -Cases $a.Cases -Csat $a.Csat -ResolutionHours $a.Res -RenewalDays $a.RenewalDays -OpenCritical $a.Critical
    $expected += [pscustomobject]@{
        Stage = "Challenge 01 baseline"; AccountCode = $a.Code; Cases = $a.Cases
        AvgCSAT = $a.Csat; AvgResolutionHours = $a.Res; RenewalDays = $a.RenewalDays
        OpenCritical = $a.Critical; ExpectedScore = $s.Score; ExpectedTier = $s.Tier
    }
}

# ---------------------------------------------------------------------------
# Round 2: Challenge 02 controlled deterioration
# ---------------------------------------------------------------------------

$round2 = @(
    @{ Code = "ACC-1003"; RenewalDays = 110; Cases = 9;  Csat = 3.4; Res = 8.0;  Critical = 0; From = "Green" },
    @{ Code = "ACC-1004"; RenewalDays = 55;  Cases = 8;  Csat = 3.1; Res = 11.0; Critical = 0; From = "Green" },
    @{ Code = "ACC-1005"; RenewalDays = 65;  Cases = 12; Csat = 2.5; Res = 15.0; Critical = 1; From = "Amber" },
    @{ Code = "ACC-1006"; RenewalDays = 50;  Cases = 13; Csat = 2.3; Res = 17.0; Critical = 1; From = "Amber" },
    @{ Code = "ACC-1008"; RenewalDays = 18;  Cases = 9;  Csat = 2.6; Res = 14.0; Critical = 2; From = "Red"   }
)

$round2Accounts = @()
$round2Cases = @()

foreach ($a in $round2) {
    $base = $baseline | Where-Object { $_.Code -eq $a.Code }
    $round2Accounts += [pscustomobject]@{
        AccountCode         = $a.Code
        AccountName         = $base.Name
        ContractRenewalDate = $today.AddDays($a.RenewalDays).ToString("yyyy-MM-dd")
    }
    $round2Cases += New-CaseRows -AccountCode $a.Code -TotalCases $a.Cases -OpenCritical $a.Critical `
                                 -TargetCsat $a.Csat -TargetResolutionHours $a.Res

    $s = Get-HealthScore -Cases $a.Cases -Csat $a.Csat -ResolutionHours $a.Res -RenewalDays $a.RenewalDays -OpenCritical $a.Critical
    $expected += [pscustomobject]@{
        Stage = "Challenge 02 deterioration"; AccountCode = $a.Code; Cases = $a.Cases
        AvgCSAT = $a.Csat; AvgResolutionHours = $a.Res; RenewalDays = $a.RenewalDays
        OpenCritical = $a.Critical; ExpectedScore = $s.Score; ExpectedTier = $s.Tier
    }
}

# ---------------------------------------------------------------------------
# Recovery: Challenge 05 post-resolution state for ACC-1008
# ---------------------------------------------------------------------------

$recovery = @{ Code = "ACC-1008"; RenewalDays = 25; Cases = 5; Csat = 4.0; Res = 6.0; Critical = 0 }
$recoveryCases = New-CaseRows -AccountCode $recovery.Code -TotalCases $recovery.Cases -OpenCritical $recovery.Critical `
                              -TargetCsat $recovery.Csat -TargetResolutionHours $recovery.Res

$s = Get-HealthScore -Cases $recovery.Cases -Csat $recovery.Csat -ResolutionHours $recovery.Res `
                     -RenewalDays $recovery.RenewalDays -OpenCritical $recovery.Critical
$expected += [pscustomobject]@{
    Stage = "Challenge 05 recovery"; AccountCode = $recovery.Code; Cases = $recovery.Cases
    AvgCSAT = $recovery.Csat; AvgResolutionHours = $recovery.Res; RenewalDays = $recovery.RenewalDays
    OpenCritical = $recovery.Critical; ExpectedScore = $s.Score; ExpectedTier = $s.Tier
}

# ---------------------------------------------------------------------------
# Write files
# ---------------------------------------------------------------------------

$accountRows    | Export-Csv -Path (Join-Path $OutputPath "accounts.csv")          -NoTypeInformation -Encoding UTF8
$baselineCases  | Export-Csv -Path (Join-Path $OutputPath "cases-baseline.csv")    -NoTypeInformation -Encoding UTF8
$round2Accounts | Export-Csv -Path (Join-Path $OutputPath "accounts-round2.csv")   -NoTypeInformation -Encoding UTF8
$round2Cases    | Export-Csv -Path (Join-Path $OutputPath "cases-round2.csv")      -NoTypeInformation -Encoding UTF8
$recoveryCases  | Export-Csv -Path (Join-Path $OutputPath "cases-recovery.csv")    -NoTypeInformation -Encoding UTF8
$expected       | Export-Csv -Path (Join-Path $OutputPath "expected-scores.csv")   -NoTypeInformation -Encoding UTF8

$readme = @"
Proactive Customer Intelligence - Lab Assets
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')

These files are regenerated every time you sign in, so all dates stay inside the
trailing 30-day scoring window the lab depends on.

accounts.csv          Prerequisite, Task 4. Import into the Account table.
                      Contract renewal dates are already calculated as real dates.

cases-baseline.csv    Prerequisite, Task 4. Import into the Case table.
                      57 rows. Resolved rows carry CSAT Score and Resolution Hours;
                      Active rows are the open critical cases and carry neither.

accounts-round2.csv   Challenge 02, Task 6. Updated renewal dates only.
cases-round2.csv      Challenge 02, Task 6. Delete the existing cases for
                      ACC-1003, 1004, 1005, 1006 and 1008 first, then import this set.

cases-recovery.csv    Challenge 05, Task 4. Replacement case set for ACC-1008
                      after the recovery case is resolved.

expected-scores.csv   Every expected health score and tier at each stage. Use it to
                      check your scoring flow before moving on.

IMPORTANT - two Case columns the lab relies on
The Case table needs two custom columns before importing:
  CSAT Score        Decimal number, 2 decimal places, range 1.00 to 5.00
  Resolution Hours  Decimal number, 1 decimal place
The out-of-the-box satisfaction field is a whole-number choice and cannot express
averages such as 4.6, and actual resolution duration is not directly importable.
Add these two columns in the Prerequisite, Task 3.
"@

$readme | Out-File -FilePath (Join-Path $OutputPath "README.txt") -Encoding UTF8

Write-Output "Lab data generated in $OutputPath"
Get-ChildItem -Path $OutputPath -File | ForEach-Object { Write-Output ("  {0}  ({1} bytes)" -f $_.Name, $_.Length) }
Write-Output ""
Write-Output "Baseline case rows: $($baselineCases.Count)  (expected 57)"
Write-Output "Round 2 case rows:  $($round2Cases.Count)   (expected 51)"
'@
Set-Content -Path "C:\LabFiles\Generate-LabData.ps1" -Value $generator -Encoding UTF8

# --- logon.ps1, refreshes the seed data at each sign-in ---
$logon = @'
<#
    logon.ps1

    Runs at first sign-in of the ODL user. Two jobs:
      1. Regenerate the Dataverse import files so the case CreatedOn dates sit
         inside the trailing 30-day window on the day the learner actually starts.
         An ODL deployed on Monday and opened on Thursday would otherwise drift.
      2. Confirm the assets are present and log the result for support triage.
#>

$ErrorActionPreference = "Continue"
$logPath   = "C:\WindowsAzure\Logs\lab-logon.txt"
$assetPath = "C:\Users\Public\Desktop\Lab Assets"

Start-Transcript -Path $logPath -Append

if (Test-Path "C:\LabFiles\Generate-LabData.ps1") {
    try {
        & "C:\LabFiles\Generate-LabData.ps1" -OutputPath $assetPath
        Write-Output "Seed data regenerated with current dates."
    }
    catch {
        Write-Output "Seed regeneration failed: $($_.Exception.Message)"
    }
}
else {
    Write-Output "Generate-LabData.ps1 not found - seed files may carry deployment-time dates."
}

$expected = @(
    "accounts.csv",
    "cases-baseline.csv",
    "accounts-round2.csv",
    "cases-round2.csv",
    "cases-recovery.csv",
    "expected-scores.csv",
    "deployment-names.txt",
    "README.txt"
)

$missing = @()
foreach ($file in $expected) {
    if (-not (Test-Path (Join-Path $assetPath $file))) { $missing += $file }
}

if ($missing.Count -eq 0) {
    Write-Output "All lab assets present in $assetPath"
}
else {
    Write-Output "MISSING lab assets: $($missing -join ', ')"
}

# Confirm Power BI Desktop landed, since Challenge 5 depends on it
$pbiPaths = @(
    "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
    "C:\Program Files (x86)\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
)
if ($pbiPaths | Where-Object { Test-Path $_ }) {
    Write-Output "Power BI Desktop is installed."
}
else {
    Write-Output "WARNING: Power BI Desktop not found. Challenge 5 can be completed in the Power BI service instead."
}

Stop-Transcript
'@
Set-Content -Path "C:\LabFiles\logon.ps1" -Value $logon -Encoding UTF8

try {
    & "C:\LabFiles\Generate-LabData.ps1" -OutputPath $assetPath
    Write-Output "Seed data generated."
}
catch {
    Write-Output "FAILED to generate seed data: $($_.Exception.Message)"
}

# --- Desktop shortcuts for the portals the lab uses ---
$edgePaths = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)
$edgeExe = $edgePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($edgeExe) {
    $shortcuts = [ordered]@{
        "Power Platform Admin Center" = "https://admin.powerplatform.microsoft.com"
        "Power Apps"                  = "https://make.powerapps.com"
        "Copilot Studio"              = "https://copilotstudio.microsoft.com"
        "Power Automate"              = "https://make.powerautomate.com"
        "Power BI Service"            = "https://app.powerbi.com"
    }
    $wsh = New-Object -ComObject WScript.Shell
    foreach ($name in $shortcuts.Keys) {
        $lnk = $wsh.CreateShortcut("C:\Users\Public\Desktop\$name.lnk")
        $lnk.TargetPath = """$edgeExe"""
        $lnk.Arguments  = """$($shortcuts[$name])"""
        $lnk.Save()
    }
    Write-Output "Portal shortcuts created."
}

# --- Deployment-specific names, next to the seed files ---
@"
Deployment ID:            $DeploymentID
Service environment:      ODL_User $DeploymentID Service

Solution:                 Proactive Customer Intelligence  (publisher prefix: cchs)
Copilot Studio agent:     Customer Health Monitor

Flows:
  Calculate-Health-Score-$DeploymentID
  Detect-Tier-Change-$DeploymentID
  Monitor-Health-Daily-$DeploymentID
  Notify-CSM-$DeploymentID
  Proactive-Outreach-$DeploymentID
  Portfolio-Risk-Alert-$DeploymentID
  Service-Recovery-Trigger-$DeploymentID
  Service-Recovery-Closure-$DeploymentID

AI Builder prompt:
  Generate-Outreach-Email-$DeploymentID

Power BI:
  Workspace: ws-custhealth-$DeploymentID
  Report:    rpt-csm-health-$DeploymentID

Dynamics 365 Customer Service:
  Queue: Tier 3 Senior Support
  SLA:   SLA-Service-Recovery-$DeploymentID
"@ | Out-File -FilePath "$assetPath\deployment-names.txt" -Encoding UTF8

# --- Autologon and the logon task ---
$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -Type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\$adminUsername" -Type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value "$adminPassword" -Type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -Type DWord

$Trigger = New-ScheduledTaskTrigger -AtLogOn
$User    = "$($env:ComputerName)\$adminUsername"
$Action  = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\LabFiles\logon.ps1"
Register-ScheduledTask -TaskName "CloudLabs Lab Setup" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force

Get-ChocoInstallReport

Stop-Transcript
Restart-Computer -Force
