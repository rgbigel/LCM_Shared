<# ============================================================================================
    Path:       D:\Git_Repositories\LCM_Shared\Modules
    Module:     BcdAtoms.psm1
    Version:    10.0.0
    Author:     Rolf
    Purpose:    Reusable BCD discovery, object parser, displayorder parser, and dual-format backup atoms.
============================================================================================ #>

function Get-BcdReferencedNtVolumes {
    [CmdletBinding()]
    param(
        [string]$BcdEditPath = (Join-Path $env:WINDIR "System32\bcdedit.exe")
    )

    $all = & $BcdEditPath /enum all /v 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "bcdedit /enum all /v failed or requires administrator privileges. Continuing without BCD reference flags."
        return @()
    }

    $volumes = $all -split "`r?`n" |
        Where-Object { $_ -match '^\s*(device|osdevice)\s+partition=\\Device\\HarddiskVolume\d+' } |
        ForEach-Object {
            if ($_ -match 'partition=(\\Device\\HarddiskVolume\d+)') {
                $matches[1]
            }
        } |
        Sort-Object -Unique

    return @($volumes)
}

function Get-BcdDisplayOrder {
    [CmdletBinding()]
    param(
        [string]$BcdEditPath = (Join-Path $env:WINDIR "System32\bcdedit.exe"),
        [string]$BcdManagerText
    )

    if (-not $BcdManagerText) {
        $BcdManagerText = & $BcdEditPath /enum '{bootmgr}' /v 2>&1 | Out-String
    }

    $guids = @()
    $matches = [regex]::Matches($BcdManagerText, '(?ms)displayorder\s+((?:\{[a-f0-9-]+\}\s*)+)')
    foreach ($m in $matches) {
        foreach ($guidMatch in [regex]::Matches($m.Groups[1].Value, '\{[a-f0-9-]+\}')) {
            if ($guidMatch.Value -and ($guids -notcontains $guidMatch.Value)) {
                $guids += $guidMatch.Value
            }
        }
    }

    return @($guids)
}

function Get-BcdBootEntries {
    [CmdletBinding()]
    param(
        [string]$BcdEditPath = (Join-Path $env:WINDIR "System32\bcdedit.exe"),
        [string]$BcdAllText
    )

    if (-not $BcdAllText) {
        $BcdAllText = & $BcdEditPath /enum all /v 2>&1 | Out-String
    }

    $entries = @{}
    $blocks = $BcdAllText -split "(?m)(?=^[A-Za-z0-9 ]+\r?\n[-=]+\r?\n)"
    
    foreach ($block in $blocks) {
        if ($block -match '(?m)^identifier\s+(\{[a-f0-9-]+\})') {
            $guid = $matches[1]
            $entry = [PSCustomObject]@{
                Identifier       = $guid
                Description      = if ($block -match '(?m)^description\s+(.+)$') { $matches[1].Trim() } else { $null }
                Device           = if ($block -match '(?m)^device\s+(.+)$') { $matches[1].Trim() } else { $null }
                Path             = if ($block -match '(?m)^path\s+(.+)$') { $matches[1].Trim() } else { $null }
                RecoverySequence = if ($block -match '(?m)^recoverysequence\s+(\{[a-f0-9-]+\})') { $matches[1] } else { $null }
                SystemRoot       = if ($block -match '(?m)^systemroot\s+(.+)$') { $matches[1].Trim() } else { $null }
            }
            $entries[$guid] = $entry
        }
    }

    return $entries
}

function Export-BcdBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupDirectory,
        [Parameter(Mandatory = $true)]
        [string]$BootVolumeLabel,
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$BcdEditPath = (Join-Path $env:WINDIR "System32\bcdedit.exe")
    )

    if (-not (Test-Path -LiteralPath $BackupDirectory)) {
        New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd HHmm")
    $baseName = "$timestamp $BootVolumeLabel $ComputerName"
    $bakPath = Join-Path $BackupDirectory "$baseName.bak"
    $txtPath = Join-Path $BackupDirectory "$baseName.txt"

    # 1. Export binary hive
    & $BcdEditPath /export "$bakPath"
    if ($LASTEXITCODE -ne 0) {
        throw "bcdedit /export failed with exit code $LASTEXITCODE"
    }

    # 2. Cleanup transaction log sidecars
    $sidecars = @("$bakPath.LOG", "$bakPath.LOG1", "$bakPath.LOG2")
    foreach ($sc in $sidecars) {
        if (Test-Path -LiteralPath $sc) {
            Remove-Item -LiteralPath $sc -Force -ErrorAction SilentlyContinue
        }
    }

    # 3. Export verbose text report
    $reportText = & $BcdEditPath /enum all /v 2>&1 | Out-String
    $reportText | Set-Content -Path $txtPath -Encoding UTF8

    return [PSCustomObject]@{
        BackupPath = $bakPath
        ReportPath = $txtPath
        Timestamp  = $timestamp
    }
}

Export-ModuleMember -Function Get-BcdReferencedNtVolumes, Get-BcdDisplayOrder, Get-BcdBootEntries, Export-BcdBackup
