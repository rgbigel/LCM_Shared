# SharedModules: Architecture Document

Module: docs/Architecture.md  
Authors: Rolf, SharedModules Architecture Team  
Version: 1.3.0  
Status: Authoritative Architecture  
Date: 2026-08-16  

---

## 1. System Architecture & Module Topology

```mermaid
graph TB
    subgraph SharedModulesRepository ["SharedModules Repository"]
        LOG["Logging.psm1<br/>• Initialize-LogContext<br/>• Write-LogMessage / Write-Log<br/>• Session log formatters"]
        VOL["VolumeAtoms.psm1<br/>• Get-VolumeSerialHex<br/>• Get-VolumeFsInfo<br/>• Get-EfiPartitionVolume<br/>• Get-FltmcVolumeRows<br/>• Get-PartitionMetaBySerial"]
        BCD["BcdAtoms.psm1<br/>• Get-BcdReferencedNtVolumes<br/>• Get-BcdBootEntries<br/>• Get-BcdDisplayOrder<br/>• Export-BcdBackup"]
    end

    subgraph Consumers ["Workspace Consumer Repositories"]
        VI["VolumeInventory<br/>(Combines fltmc + Get-Partition + BCD)"]
        BEM["BootEntryManager<br/>(Interactive BCD Menu & Maintenance)"]
        BGMSAM["BGMSAMVInv<br/>(Desktop Background & Toolbar Telemetry)"]
    end

    LOG --> BEM
    VOL --> BEM
    BCD --> BEM

    VOL --> VI
    BCD --> VI

    LOG --> BGMSAM
    VOL --> BGMSAM
```

---

## 2. Module Boundary Contracts

### A. `Logging.psm1`
* **Exported Functions**: `Initialize-LogContext`, `Write-LogMessage`, `Write-Log`, `Format-SessionLogFileName`.
* **Behavior**: Safe file append, transcript capture, context state preservation.

### B. `VolumeAtoms.psm1`
* **Exported Functions**: `Get-VolumeSerialHex`, `Get-VolumeFsInfo`, `Get-EfiPartitionVolume`, `Get-FltmcVolumeRows`, `Get-PartitionMetaBySerial`.
* **Behavior**: Low-level storage and volume attribute resolution using `fsutil`, `fltmc`, and `Get-Partition`.

### C. `BcdAtoms.psm1`
* **Exported Functions**: `Get-BcdReferencedNtVolumes`, `Get-BcdBootEntries`, `Get-BcdDisplayOrder`, `Export-BcdBackup`.
* **Behavior**: BCD text parsing, object mapping, and automated safety backups.
