<# ============================================================================================
    Path:       D:\Git_Repositories\SharedModules\Modules
  Module:     Logging.psm1
    Version:    1.2.0
  Author:     Rolf Bercht

  Purpose:
      Provides reusable logging utilities for scripts and modules.
      Phase 1 adds a context-based API while preserving Write-Log compatibility.
============================================================================================ #>

# Module-level setup: use transcript helpers when available.
$TranscriptToolsPath = Join-Path $PSScriptRoot "TranscriptTools.psm1"
if (Test-Path -LiteralPath $TranscriptToolsPath) {
    Import-Module -Name $TranscriptToolsPath -Force
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

    $Message | Out-File -FilePath $LogFile -Append -Encoding UTF8
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
        # Global rule: trace mode implies interactive mode unless explicitly forced off.
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
        InteractiveMode    = [bool]$InteractiveMode
        NonInteractive     = [bool]$NonInteractive
        RepositoryName     = $effectiveRepositoryName
        Mode               = $Mode
        LogRoot            = $effectiveRoot
        LogPath            = $logPath
        TranscriptStarted  = $transcriptStarted
        FinalStatusWritten = $false
        StartedAt          = (Get-Date)
    }
}

function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Context,
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet("INFO", "TRACE", "WARN", "ERROR", "OK", "FINAL")]
        [string]$Level = "INFO",
        [bool]$EmitToHost = $true
    )

    if ($Level -eq "TRACE" -and -not $Context.TraceEnabled) {
        return
    }

    $formatted = "[$Level] $Message"
    if ($EmitToHost) {
        Write-Host $formatted
    }

    if ($Context.LogEnabled -and $Context.Mode -eq "File" -and -not [string]::IsNullOrWhiteSpace($Context.LogPath)) {
        Write-Log -Message $formatted -LogFile $Context.LogPath
    }
}

function Write-LogHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Context
    )

    Write-LogMessage -Context $Context -Message "$($Context.ScriptName) v$($Context.ScriptVersion)" -Level "INFO"
    if ($Context.LogEnabled -and -not [string]::IsNullOrWhiteSpace($Context.LogPath)) {
        Write-LogMessage -Context $Context -Message "Log file: $($Context.LogPath)" -Level "INFO"
    }
}

function Write-TraceLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Context,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-LogMessage -Context $Context -Message $Message -Level "TRACE"
}

function Write-LogFinalStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Context,
        [Parameter(Mandatory = $true)]
        [int]$Code,
        [string]$Message
    )

    $state = if ($Code -eq 0) { "SUCCESS" } else { "FAILURE" }
    Write-LogMessage -Context $Context -Message "$($Context.ScriptName) v$($Context.ScriptVersion) - $state" -Level "FINAL"
    if (-not [string]::IsNullOrWhiteSpace($Message)) {
        Write-LogMessage -Context $Context -Message $Message -Level "FINAL"
    }

    $Context.FinalStatusWritten = $true
}

function Invoke-InteractiveLogOffer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Context
    )

    if (-not $Context.InteractiveMode) {
        return
    }
    if (-not $Context.FinalStatusWritten) {
        return
    }
    if (-not $Context.LogEnabled -or [string]::IsNullOrWhiteSpace($Context.LogPath)) {
        return
    }

    Write-Host "[INFO] Log available: $($Context.LogPath)"
    $answer = Read-Host "Open this log in Notepad++ now? [y/N]"
    if ($answer -notmatch '^(y|yes)$') {
        return
    }

    $notepadpp = Get-Command -Name "notepad++" -ErrorAction SilentlyContinue
    if ($null -eq $notepadpp) {
        Write-Host "[WARN] Notepad++ was not found in PATH."
        return
    }

    Start-Process -FilePath $notepadpp.Source -ArgumentList "`"$($Context.LogPath)`"" | Out-Null
}

function Close-LogContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Context
    )

    if ($Context.Mode -eq "Transcript" -and $Context.TranscriptStarted) {
        if (Get-Command -Name Stop-TraceTranscript -ErrorAction SilentlyContinue) {
            Stop-TraceTranscript
        }
        else {
            Stop-Transcript | Out-Null
        }
        $Context.TranscriptStarted = $false
    }

    Invoke-InteractiveLogOffer -Context $Context
}

Export-ModuleMember -Function Write-Log, Initialize-LogContext, Write-LogMessage, Write-LogHeader, Write-TraceLog, Write-LogFinalStatus, Close-LogContext
