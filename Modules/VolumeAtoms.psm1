<# ============================================================================================
    Path:       D:\Git_Repositories\SharedModules\Modules
    Module:     VolumeAtoms.psm1
    Version:    1.0.0
    Author:     Rolf
    Purpose:    Reusable storage, volume serial resolution, partition correlation, and EFI discovery atoms.
============================================================================================ #>

function Get-VolumeSerialHex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $text = fsutil fsinfo volumeinfo $Path 2>$null | Out-String
        if ($text -match '(?im)^\s*Volume Serial Number\s*:\s*0x([0-9a-f]+)\s*$') {
            return $matches[1].ToLower()
        }
    }
    catch {
    }

    return $null
}

function Get-VolumeFsInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $result = [PSCustomObject]@{
        SerialHex      = $null
        VolumeLabel    = $null
        FileSystemName = $null
    }

    try {
        $text = fsutil fsinfo volumeinfo $Path 2>$null | Out-String
        if ($text -match '(?im)^\s*Volume Serial Number\s*:\s*0x([0-9a-f]+)\s*$') {
            $result.SerialHex = $matches[1].ToLower()
        }

        if ($text -match '(?im)^[ \t]*Volume Name[ \t]*:[ \t]*(.*)$') {
            $label = $matches[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($label)) {
                $result.VolumeLabel = $label
            }
        }

        if ($text -match '(?im)^[ \t]*File System Name[ \t]*:[ \t]*(.*)$') {
            $fsName = $matches[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($fsName)) {
                $result.FileSystemName = $fsName
            }
        }
    }
    catch {
    }

    return $result
}

function Get-EfiPartitionVolume {
    [CmdletBinding()]
    param(
        [string]$EfiGptGuid = "{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}"
    )

    $efiPartition = Get-Partition | Where-Object { $_.GptType -eq $EfiGptGuid } | Select-Object -First 1
    if (-not $efiPartition) {
        throw "EFI System Partition not found on system."
    }

    $efiVolume = $efiPartition | Get-Volume -ErrorAction Stop
    if (-not $efiVolume) {
        throw "EFI System Partition volume could not be resolved."
    }

    return $efiVolume
}

function Get-FltmcVolumeRows {
    [CmdletBinding()]
    param()

    $rows = fltmc volumes |
        Select-Object -Skip 2 |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object {
            if ($_ -match '^\s*(?<dos>[A-Z]:)?\s*(?<vol>\\Device\\[^\s]+)\s+(?<fs>\S+)\s*(?<status>\S+)?\s*$') {
                $volumeName = $matches['vol']
                if ($volumeName -match '^\\Device\\(Mailslot|Mup|NamedPipe)(\\|$)') {
                    return
                }

                [PSCustomObject]@{
                    DosName    = $matches['dos']
                    VolumeName = $volumeName
                    FileSystem = $matches['fs']
                    Status     = $matches['status']
                }
            }
        }

    return @($rows)
}

function Get-PartitionMetaBySerial {
    [CmdletBinding()]
    param()

    $map = @{}

    Get-Partition | ForEach-Object {
        $partition = $_
        $accessPaths = @($partition.AccessPaths | Where-Object { $_ -match '^\\\\\?\\Volume\{[^}]+\}\\$' })

        foreach ($accessPath in $accessPaths) {
            $serial = Get-VolumeSerialHex -Path $accessPath
            if (-not $serial) { continue }

            if (-not $map.ContainsKey($serial)) {
                $map[$serial] = [PSCustomObject]@{
                    PartitionType   = $partition.Type
                    GptType         = $partition.GptType
                    MbrType         = $partition.MbrType
                    DiskNumber      = $partition.DiskNumber
                    PartitionNumber = $partition.PartitionNumber
                    StartOffset     = [int64]$partition.Offset
                    SizeBytes       = $partition.Size
                }
            }
        }
    }

    return $map
}

Export-ModuleMember -Function Get-VolumeSerialHex, Get-VolumeFsInfo, Get-EfiPartitionVolume, Get-FltmcVolumeRows, Get-PartitionMetaBySerial
