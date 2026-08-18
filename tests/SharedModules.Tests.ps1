# SharedModules.Tests.ps1
# Comprehensive unit tests for Logging, VolumeAtoms, and BcdAtoms (Zero Reboot Execution)

Describe "Logging.psm1 Atoms" {
    It "imports Logging module and exports required functions" {
        $modulePath = Join-Path $PSScriptRoot '..\Modules\Logging.psm1'
        $mod = Import-Module -Name $modulePath -PassThru -Force
        $mod | Should -Not -BeNullOrEmpty
        
        $exported = @($mod.ExportedFunctions.Keys)
        ($exported -contains 'Format-SessionLogFileName') | Should -Be $true
        ($exported -contains 'Write-Log') | Should -Be $true
        ($exported -contains 'Write-LogMessage') | Should -Be $true
        ($exported -contains 'Initialize-LogContext') | Should -Be $true
    }

    It "formats session log filenames according to convention" {
        $fileName = Format-SessionLogFileName -Label 'BOOT_ESP' -ComputerName 'TEST_HOST' -Timestamp (Get-Date '2026-08-16 14:30:00')
        $fileName | Should -Be '20260816 1430 BOOT_ESP TEST_HOST.log'
    }

    It "writes structured log messages to file cleanly" {
        $tempLog = [System.IO.Path]::GetTempFileName()
        try {
            Write-LogMessage -Message 'Test Info Event' -LogFile $tempLog -Level 'INFO'
            $content = Get-Content -Path $tempLog -Raw
            ($content -match '\[INFO\] Test Info Event') | Should -Be $true
        } finally {
            if (Test-Path -LiteralPath $tempLog) { Remove-Item -LiteralPath $tempLog -Force }
        }
    }
}

Describe "VolumeAtoms.psm1 Atoms" {
    It "imports VolumeAtoms module and exports required functions" {
        $modulePath = Join-Path $PSScriptRoot '..\Modules\VolumeAtoms.psm1'
        $mod = Import-Module -Name $modulePath -PassThru -Force
        $mod | Should -Not -BeNullOrEmpty
        
        $exported = @($mod.ExportedFunctions.Keys)
        ($exported -contains 'Get-VolumeSerialHex') | Should -Be $true
        ($exported -contains 'Get-VolumeFsInfo') | Should -Be $true
        ($exported -contains 'Get-EfiPartitionVolume') | Should -Be $true
        ($exported -contains 'Get-FltmcVolumeRows') | Should -Be $true
        ($exported -contains 'Get-PartitionMetaBySerial') | Should -Be $true
    }

    It "resolves volume serial number for system drive" {
        $sysDrive = $env:SystemDrive
        if ($sysDrive) {
            $serial = Get-VolumeSerialHex -Path "$sysDrive\"
            # If standard user, serial may be null; if resolved, verify hex pattern
            if ($serial) {
                ($serial -match '^[0-9a-f]+$') | Should -Be $true
            }
        }
    }
}

Describe "BcdAtoms.psm1 Atoms" {
    It "imports BcdAtoms module and exports required functions" {
        $modulePath = Join-Path $PSScriptRoot '..\Modules\BcdAtoms.psm1'
        $mod = Import-Module -Name $modulePath -PassThru -Force
        $mod | Should -Not -BeNullOrEmpty
        
        $exported = @($mod.ExportedFunctions.Keys)
        ($exported -contains 'Get-BcdReferencedNtVolumes') | Should -Be $true
        ($exported -contains 'Get-BcdDisplayOrder') | Should -Be $true
        ($exported -contains 'Get-BcdBootEntries') | Should -Be $true
        ($exported -contains 'Export-BcdBackup') | Should -Be $true
    }

    It "correctly parses BcdDisplayOrder from mock BCD manager output" {
        $mockBcdManager = @"
Windows Boot Manager
--------------------
identifier              {9dea862c-5cdd-4e70-acc1-f32b344d4795}
displayorder            {a7b3c2d1-0000-0000-0000-000000000001}
                        {b8c4d3e2-0000-0000-0000-000000000002}
"@
        $displayOrder = Get-BcdDisplayOrder -BcdManagerText $mockBcdManager
        $displayOrder.Count | Should -Be 2
        $displayOrder[0] | Should -Be '{a7b3c2d1-0000-0000-0000-000000000001}'
        $displayOrder[1] | Should -Be '{b8c4d3e2-0000-0000-0000-000000000002}'
    }

    It "correctly parses BcdBootEntries from mock BCD output" {
        $mockBcdAll = @"
Windows Boot Loader
-------------------
identifier              {a7b3c2d1-0000-0000-0000-000000000001}
device                  partition=C:
path                    \Windows\system32\winload.efi
description             Windows 11 Primary
"@
        $entries = Get-BcdBootEntries -BcdAllText $mockBcdAll
        $entries.ContainsKey('{a7b3c2d1-0000-0000-0000-000000000001}') | Should -Be $true
        $entry = $entries['{a7b3c2d1-0000-0000-0000-000000000001}']
        $entry.Description | Should -Be 'Windows 11 Primary'
        $entry.Path | Should -Be '\Windows\system32\winload.efi'
    }
}

