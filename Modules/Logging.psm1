<# ============================================================================================
    Path:       D:\Git_Repositories\SharedModules\Modules
    Module:     Logging.psm1
    Version:    1.3.0
    Author:     Rolf
    Purpose:    Provides reusable logging utilities, session log formatting, and transcript helpers.
============================================================================================ #>

$TranscriptToolsPath = Join-Path $PSScriptRoot "TranscriptTools.psm1"
if (Test-Path -LiteralPath $TranscriptToolsPath) {
    Import-Module -Name $TranscriptToolsPath -Force
}

function Format-SessionLogFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [string]$ComputerName = $env:COMPUTERNAME,
        [datetime]$Timestamp = (Get-Date)
    )

    $timeStr = $Timestamp.ToString('yyyyMMdd HHmm')
    return "$timeStr $Label $ComputerName.log"
}

function Write-Log {
    [CmdletBinding()]
    param(
        [string]$Message,
        [string]$LogFile
    )

    if (-not $LogFile) {
        return
    }

    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $formatted = "[$timestamp] $Message"
    try {
        $formatted | Out-File -FilePath $LogFile -Append -Encoding UTF8
    } catch {
    }
}

function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$LogFile,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [switch]$ToHost
    )

    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $formatted = "[$timestamp] [$Level] $Message"

    if ($LogFile) {
        try {
            $formatted | Out-File -FilePath $LogFile -Append -Encoding UTF8
        } catch {
        }
    }

    if ($ToHost) {
        switch ($Level) {
            "WARN"  { Write-Warning $Message }
            "ERROR" { Write-Error $Message }
            "DEBUG" { Write-Debug $Message }
            default { Write-Host $formatted }
        }
    }
}

function Initialize-LogContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [Parameter(Mandatory = $true)]
        [string]$ScriptVersion,
        [bool]$EnableLogging = $false,
        [bool]$EnableTrace = $false,
        [Alias("i")]
        [switch]$InteractiveMode,
        [switch]$NonInteractive,
        [switch]$RequireInteractiveModeInInteractiveHost,
        [string]$RepositoryName,
        [ValidateSet("File", "Transcript")]
        [string]$Mode = "File",
        [string]$LogRoot,
        [string]$LogFilePrefix
    )

    if ($NonInteractive) {
        $InteractiveMode = $false
    }
    elseif ($EnableTrace) {
        $InteractiveMode = $true
    }

    $isInteractiveHost = ($Host.Name -match "ConsoleHost|Visual Studio Code Host")
    if ($RequireInteractiveModeInInteractiveHost -and $isInteractiveHost -and -not $InteractiveMode) {
        throw "InteractiveMode (-i) is required in interactive host sessions."
    }

    $effectivePrefix = if ([string]::IsNullOrWhiteSpace($LogFilePrefix)) { $ScriptName } else { $LogFilePrefix }
    $effectiveRepositoryName = if ([string]::IsNullOrWhiteSpace($RepositoryName)) { "General" } else { $RepositoryName }
    $effectiveRoot = if ([string]::IsNullOrWhiteSpace($LogRoot)) {
        Join-Path $env:TEMP "$effectiveRepositoryName\$effectivePrefix\Logs"
    }
    else {
        $LogRoot
    }

    $logPath = ""
    $transcriptStarted = $false
    if ($EnableLogging) {
        if (-not (Test-Path -LiteralPath $effectiveRoot)) {
            New-Item -ItemType Directory -Path $effectiveRoot -Force | Out-Null
        }

        $logPath = Join-Path $effectiveRoot "$effectivePrefix-$((Get-Date).ToString('yyyyMMdd_HHmmss_fff')).log"
        if ($Mode -eq "File") {
            New-Item -ItemType File -Path $logPath -Force | Out-Null
        }
        else {
            if (Get-Command -Name Start-TraceTranscript -ErrorAction SilentlyContinue) {
                Start-TraceTranscript -Path $logPath
            }
            else {
                Start-Transcript -LiteralPath $logPath -Force | Out-Null
            }
            $transcriptStarted = $true
        }
    }

    return [pscustomobject]@{
        ScriptName         = $ScriptName
        ScriptVersion      = $ScriptVersion
        LogEnabled         = $EnableLogging
        TraceEnabled       = $EnableTrace
        Interactive        = $InteractiveMode
        HostName           = $Host.Name
        RepositoryName     = $effectiveRepositoryName
        LogPath            = $logPath
        TranscriptStarted  = $transcriptStarted
        Mode               = $Mode
        TimestampUtc       = (Get-Date).ToUniversalTime().ToString("o")
    }
}

Export-ModuleMember -Function Format-SessionLogFileName, Write-Log, Write-LogMessage, Initialize-LogContext
