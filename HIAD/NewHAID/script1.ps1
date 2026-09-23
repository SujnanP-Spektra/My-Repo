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
# D1: InstallPowerBiDesktopChoco in cloudlabs-windows-functions.ps1 carries a
# package name that no longer resolves, so Desktop silently fails to install and
# the attendee discovers it at Challenge 04 Task 1. That file is shared and not
# ours to change, so install directly here and verify rather than trust it.
$pbiBin = @("C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
            "C:\Program Files (x86)\Microsoft Power BI Desktop\bin\PBIDesktop.exe")
$pbiOk = $false
foreach ($pkg in @("powerbi", "powerbidesktop")) {
    if ($pbiOk) { break }
    try {
        choco install $pkg -y --no-progress --ignore-checksums
        Start-Sleep -Seconds 5
        foreach ($b in $pbiBin) { if (Test-Path $b) { $pbiOk = $true } }
    }
    catch { Write-Output "choco install $pkg failed: $($_.Exception.Message)" }
}
if (-not $pbiOk) {
    try {
        $msi = "C:\Packages\PBIDesktopSetup_x64.msi"
        Invoke-WebRequest -Uri "https://aka.ms/pbiSingleInstaller" -OutFile $msi -UseBasicParsing
        Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn ACCEPT_EULA=1" -Wait
        foreach ($b in $pbiBin) { if (Test-Path $b) { $pbiOk = $true } }
    }
    catch { Write-Output "Power BI MSI fallback failed: $($_.Exception.Message)" }
}
if ($pbiOk) { Write-Output "Power BI Desktop installed." }
else { Write-Output "ERROR: Power BI Desktop NOT installed - Challenge 04 Task 1 will block." }

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
        [string]$AccountName,
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
            AccountName      = $AccountName
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
            AccountName      = $AccountName
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

function ConvertTo-LoaderJson {
    <#
        Reshapes case rows for the attendee's loader flow.

        Drops CreatedOn/ResolvedOn in favour of DaysAgo, so the flow resolves the
        creation date at run time with addDays(utcNow(), -DaysAgo) rather than
        inheriting a timestamp baked in when the ODL was deployed. A pooled ODL
        opened a week later would otherwise carry cases outside the trailing
        30-day window, and the account reads as having no case history at all.

        Empty CSAT/ResolutionHours become real nulls. Power Automate treats "" as
        a value, and an empty string written to a decimal column fails Create row.
    #>
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Rows,
        [Parameter(Mandatory = $true)][datetime]$Reference
    )

    $out = New-Object System.Collections.ArrayList
    foreach ($r in $Rows) {
        $created = [datetime]::ParseExact($r.CreatedOn, 'yyyy-MM-dd HH:mm', $null)
        $daysAgo = [int]($Reference.Date - $created.Date).Days
        if ($daysAgo -lt 0) { $daysAgo = 0 }

        $csat = $null
        if ("$($r.CSATScore)".Trim() -ne '') { $csat = [double]$r.CSATScore }
        $hours = $null
        if ("$($r.ResolutionHours)".Trim() -ne '') { $hours = [double]$r.ResolutionHours }

        $null = $out.Add([ordered]@{
            CaseTitle = $r.CaseTitle; AccountCode = $r.AccountCode
            AccountName = $r.AccountName; CaseReference = $r.CaseReference
            Priority = $r.Priority; Status = $r.Status; DaysAgo = $daysAgo
            CSATScore = $csat; ResolutionHours = $hours
        })
    }
    return , $out.ToArray()
}

# ---------------------------------------------------------------------------
# Baseline: Prerequisite Task 4, scored in Challenge 01
# ---------------------------------------------------------------------------

# Renewal day counts are deliberately placed near the TOP of their contract-component
# rounding band rather than at a round number. The component is round(days * 20 / 90),
# so each whole-point band is only 4.5 days wide, and the day count shrinks every day
# the ODL sits in a pool between generation and use. At the old values ACC-1005 had
# 0.75 days of headroom and ACC-1008 had 0.25 before their published score dropped a
# point. These values preserve every documented score while giving roughly four days
# of shelf life, which is the widest the 4.5-day band allows.
$baseline = @(
    @{ Code = "ACC-1001"; Name = "Fabrikam Residences";    CSM = "Priya Nair";  RenewalDays = 210; Cases = 0;  Csat = $null; Res = $null; Critical = 0 },
    @{ Code = "ACC-1002"; Name = "Northwind Traders";      CSM = "Priya Nair";  RenewalDays = 180; Cases = 1;  Csat = 4.6;   Res = 3.0;   Critical = 0 },
    @{ Code = "ACC-1003"; Name = "Adventure Works Cycles"; CSM = "Priya Nair";  RenewalDays = 120; Cases = 2;  Csat = 4.5;   Res = 3.5;   Critical = 0 },
    @{ Code = "ACC-1004"; Name = "Tailspin Toys";          CSM = "Jordan Blake";RenewalDays = 98;  Cases = 3;  Csat = 4.2;   Res = 5.0;   Critical = 0 },
    @{ Code = "ACC-1005"; Name = "Woodgrove Bank";         CSM = "Jordan Blake";RenewalDays = 78;  Cases = 6;  Csat = 3.6;   Res = 7.0;   Critical = 1 },
    @{ Code = "ACC-1006"; Name = "Contoso Suites";         CSM = "Jordan Blake";RenewalDays = 60;  Cases = 7;  Csat = 3.2;   Res = 9.0;   Critical = 1 },
    @{ Code = "ACC-1007"; Name = "Litware Inc.";           CSM = "Maria Chen";  RenewalDays = 47;  Cases = 8;  Csat = 3.0;   Res = 10.0;  Critical = 2 },
    @{ Code = "ACC-1008"; Name = "Proseware Inc.";         CSM = "Maria Chen";  RenewalDays = 29;  Cases = 9;  Csat = 2.6;   Res = 14.0;  Critical = 2 },
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

    $baselineCases += New-CaseRows -AccountCode $a.Code -AccountName $a.Name -TotalCases $a.Cases -OpenCritical $a.Critical `
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
    @{ Code = "ACC-1004"; RenewalDays = 56;  Cases = 8;  Csat = 3.1; Res = 11.0; Critical = 0; From = "Green" },
    @{ Code = "ACC-1005"; RenewalDays = 65;  Cases = 12; Csat = 2.5; Res = 15.0; Critical = 1; From = "Amber" },
    @{ Code = "ACC-1006"; RenewalDays = 51;  Cases = 13; Csat = 2.3; Res = 17.0; Critical = 1; From = "Amber" },
    @{ Code = "ACC-1008"; RenewalDays = 20;  Cases = 9;  Csat = 2.6; Res = 14.0; Critical = 2; From = "Red"   }
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
    $round2Cases += New-CaseRows -AccountCode $a.Code -AccountName $base.Name -TotalCases $a.Cases -OpenCritical $a.Critical `
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

# Renewal days here MUST match the round 2 value for ACC-1008, not the baseline one.
# Challenge 05 replaces that account's cases but nothing moves its renewal date back,
# so the contract component is still whatever round 2 set. Using the baseline figure
# publishes an expected score the learner's environment cannot produce.
$round2Renewal1008 = ($round2 | Where-Object { $_.Code -eq "ACC-1008" }).RenewalDays
# FOUR loaded cases, not five. The learner creates the fifth as the recovery
# case in Challenge 05 Task 4, so loading five would give six. Four at these
# targets plus the learner's case at CSAT 5.0 / 3.0 hours average to exactly
# 4.0 and 6.0 across five, which is the verified low-sixties Amber result.
$recovery     = @{ Code = "ACC-1008"; RenewalDays = $round2Renewal1008; Cases = 4; Csat = 3.75; Res = 6.75; Critical = 0 }
$postRecovery = @{ Cases = 5; Csat = 4.0; Res = 6.0; Critical = 0 }
$recoveryCases = New-CaseRows -AccountCode $recovery.Code -AccountName "Proseware Inc." -TotalCases $recovery.Cases -OpenCritical $recovery.Critical `
                              -TargetCsat $recovery.Csat -TargetResolutionHours $recovery.Res

# The expected row describes the state AFTER the learner resolves their case.
$s = Get-HealthScore -Cases $postRecovery.Cases -Csat $postRecovery.Csat -ResolutionHours $postRecovery.Res `
                     -RenewalDays $recovery.RenewalDays -OpenCritical $postRecovery.Critical
$expected += [pscustomobject]@{
    Stage = "Challenge 05 recovery"; AccountCode = $recovery.Code; Cases = $postRecovery.Cases
    AvgCSAT = $postRecovery.Csat; AvgResolutionHours = $postRecovery.Res; RenewalDays = $recovery.RenewalDays
    OpenCritical = $postRecovery.Critical; ExpectedScore = $s.Score; ExpectedTier = $s.Tier
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

# JSON for the attendee's loader flow. challenge-2.md Task 6 and challenge-5.md
# Task 4 both instruct the learner to load .json into a flow that takes a JSON
# array; until now the script emitted CSV only and neither instruction worked.
ConvertTo-LoaderJson -Rows $baselineCases -Reference $today | ConvertTo-Json -Depth 4 |
    Set-Content -Path (Join-Path $OutputPath "cases-baseline.json") -Encoding UTF8
ConvertTo-LoaderJson -Rows $round2Cases   -Reference $today | ConvertTo-Json -Depth 4 |
    Set-Content -Path (Join-Path $OutputPath "cases-round2.json")   -Encoding UTF8
ConvertTo-LoaderJson -Rows $recoveryCases -Reference $today | ConvertTo-Json -Depth 4 |
    Set-Content -Path (Join-Path $OutputPath "cases-recovery.json") -Encoding UTF8

$readme = @"
Proactive Customer Intelligence - Lab Assets
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')

These files are regenerated every time you sign in, so all dates stay inside the
trailing 30-day scoring window the lab depends on.

accounts.csv          Prerequisite, Task 4. Import into the Account table - this one
                      does work through the wizard. Contract renewal dates are real
                      dates calculated from the moment this file was generated, which
                      is why it is regenerated at every sign-in. Import it on the day
                      you intend to work through the lab. The renewal day counts are
                      chosen to hold their published scores for about four days, so a
                      short delay costs nothing, but a stale import eventually moves an
                      account's score by a point.

cases-baseline.csv    Prerequisite, Task 4. LOAD WITH A FLOW - do not use the import
                      wizard. 57 rows. Resolved rows carry CSAT Score and Resolution
                      Hours; Active rows are the open critical cases and carry neither.
                      The Case Customer field is a polymorphic lookup and the wizard
                      cannot populate it from an account code or an account name, so
                      imported cases end up with no customer and contribute nothing to
                      any score. Build a small cloud flow instead: paste this file's
                      contents into it as JSON, read the Account table once to map each
                      code to its id, then create one case per record with customerid
                      set to /accounts(<id>). Set CreatedOn from the file, not today -
                      the scoring model reads a trailing window.
                      Map CSATScore and ResolutionHours to their own columns. They sit
                      next to each other under Advanced parameters and both take a
                      decimal, so mapping one value into both produces plausible-looking
                      data that silently inflates every score and raises no error.

accounts-round2.csv   Challenge 02, Task 6. Updated renewal dates only. Five rows,
                      few enough to edit by hand on the account records.
cases-round2.csv      Challenge 02, Task 6. Delete the existing cases for
                      ACC-1003, 1004, 1005, 1006 and 1008 first, then load this set
                      with the same flow you built in the Prerequisite. Same columns.

cases-recovery.csv    Challenge 05, Task 4. Replacement case set for ACC-1008.
                      FOUR cases - you create the fifth yourself as the recovery
                      case, and the five together average 4.0 CSAT / 6.0 hours.

cases-baseline.json   The same three case sets, in the shape the loader flow takes.
cases-round2.json     Load these rather than the CSVs. DaysAgo replaces CreatedOn:
cases-recovery.json   resolve it in the flow with addDays(utcNow(), -DaysAgo), so the
                      cases stay inside the trailing 30-day window however long this
                      environment sat in a pool before you opened it.

expected-scores.csv   Every expected health score and tier at each stage. Use it to
                      check your scoring flow before moving on.

IMPORTANT - the tier labels are matched as strings
The Account table's Current Health Tier choice must read exactly Green, Amber and Red.
Every later challenge matches those strings - the alert severity mapping, the Power BI
measures and the service recovery trigger all read this column. A different middle
label raises no error at all: the underlying integers are unaffected, so the flows keep
working and every at-risk account simply displays under the wrong name.

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
Write-Output "Recovery case rows: $($recoveryCases.Count)    (expected 5)"
Write-Output ""
Write-Output "Contract renewal headroom - days before a published score drops a point:"
foreach ($a in $baseline) {
    if ($a.RenewalDays -gt 90) { $floor = 87.75 } else {
        $v = [math]::Round(($a.RenewalDays * 20 / 90), 0, [MidpointRounding]::AwayFromZero)
        $floor = ($v - 0.5) * 4.5
    }
    $life = [math]::Round($a.RenewalDays - $floor, 2)
    if ($life -lt 2) { Write-Output ("  WARNING {0} has only {1} days of headroom" -f $a.Code, $life) }
}
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
    "cases-baseline.json",
    "cases-round2.json",
    "cases-recovery.json",
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

# Report the oldest case date. Anything beyond 30 days is outside the scoring
# window, which makes every expected score in Challenge 01 unreachable. This is
# the single fastest triage signal when an attendee reports wrong scores.
$baselinePath = Join-Path $assetPath "cases-baseline.csv"
if (Test-Path $baselinePath) {
    try {
        $dates = Import-Csv $baselinePath |
                 ForEach-Object { [datetime]::ParseExact($_.CreatedOn, 'yyyy-MM-dd HH:mm', $null) }
        $oldest = ($dates | Measure-Object -Minimum).Minimum
        $ageDays = [int]((Get-Date).Date - $oldest.Date).Days
        if ($ageDays -gt 30) {
            Write-Output "WARNING: oldest seeded case is $ageDays days old - OUTSIDE the 30-day scoring window. Regeneration has not run. Challenge 01 expected scores will not match."
        }
        else {
            Write-Output "Seed data is current - oldest case is $ageDays days old."
        }
    }
    catch {
        Write-Output "Could not read case dates: $($_.Exception.Message)"
    }
}

# Confirm Power BI Desktop landed, since Challenge 04 depends on it
$pbiPaths = @(
    "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
    "C:\Program Files (x86)\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
)
if ($pbiPaths | Where-Object { Test-Path $_ }) {
    Write-Output "Power BI Desktop is installed."
}
else {
    Write-Output "WARNING: Power BI Desktop not found. Challenge 04 Task 1 CANNOT be done in the Power BI service - modelling and measures need Desktop. Escalate to lab support."
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

  Write-Health-Alert-$DeploymentID
  Load-Case-Data                         (Prerequisite Task 4, your own loader)

AI Builder prompts:
  Generate-Outreach-Email-$DeploymentID
  Portfolio-Summary-$DeploymentID
  Service-Recovery-Summary-$DeploymentID

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

# Two triggers, not one.
#
# AutoLogonCount is 1, so autologon fires once. If nobody signs in to the VM
# again - and most of this lab is done from the attendee's own browser - the
# logon task never runs and the seed data is never refreshed. Observed in a live
# environment: cases up to 44 days old against a 30-day scoring window, which
# silently invalidates every expected score in Challenge 01.
#
# The daily trigger makes the refresh happen whether or not anyone signs in.
$User = "$($env:ComputerName)\$adminUsername"
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
              -Argument "-ExecutionPolicy Bypass -File C:\LabFiles\logon.ps1"
$Triggers = @(
    (New-ScheduledTaskTrigger -AtLogOn),
    (New-ScheduledTaskTrigger -Daily -At 5am)
)
Register-ScheduledTask -TaskName "CloudLabs Lab Setup" -Trigger $Triggers -User $User `
                       -Action $Action -RunLevel Highest -Force

Get-ChocoInstallReport

Stop-Transcript
Restart-Computer -Force
