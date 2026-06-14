<# ============================================================================================
    Path:       D:\Git_Repositories\SharedModules\Modules
  Module:     Logging.psm1
  Version:    1.0.0
  Author:     Rolf Bercht

  Purpose:
      Provides simple, reusable logging utilities for scripts and modules.
============================================================================================ #>

function Write-Log {
    param(
        [string]$Message,
        [string]$LogFile
    )

    if (-not $LogFile) {
        return
    }

    $Message | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

Export-ModuleMember -Function Write-Log
