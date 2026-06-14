<# ============================================================================================
  Path:       D:\Git_Repositories\SharedModules\Modules
  Module:     PrivatePaths.psm1
  Version:    1.0.0
  Author:     Rolf Bercht, Copilot

  Purpose:
      Centralizes machine-local path values that should later be substituted by installers.
============================================================================================ #>

$script:PrivatePaths = [ordered]@{
    GitRepositoriesRoot    = "D:\Git_Repositories"
    BootOpsHubRoot         = "C:\BootOpsHub"
    CmdRoot                = "D:\OneDrive\cmd"
    TempRoot               = "C:\Temp"
    BackgroundMotivesRoot  = "C:\BackgroundMotives"
    BackgroundAssetsRoot   = "C:\BackgroundMotives\assets"
    BackgroundLogsRoot     = "C:\BackgroundMotives\logs"
}

function Get-PrivatePaths {
    return [pscustomobject]$script:PrivatePaths
}

function Get-PrivatePathValue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [string]$DefaultValue
    )

    if ($script:PrivatePaths.Contains($Name)) {
        return $script:PrivatePaths[$Name]
    }

    return $DefaultValue
}

Export-ModuleMember -Function Get-PrivatePaths, Get-PrivatePathValue
