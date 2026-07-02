<# ============================================================================================
    Path:       D:\Git_Repositories\SharedModules\Modules
  Module:     TranscriptTools.psm1
    Version:    1.1.0
  Author:     Rolf Bercht

  Purpose:
      Provides helper functions for starting and stopping transcripts.
============================================================================================ #>

function Start-TraceTranscript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Start-Transcript -LiteralPath $Path -Force | Out-Null
}

function Stop-TraceTranscript {
    [CmdletBinding()]
    param()

    try {
        Stop-Transcript | Out-Null
    }
    catch {
        # Ignore when no transcript is active.
    }
}

Export-ModuleMember -Function Start-TraceTranscript, Stop-TraceTranscript
