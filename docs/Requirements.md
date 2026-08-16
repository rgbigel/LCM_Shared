# SharedModules: Requirements Specification

Module: docs/Requirements.md  
Authors: Rolf, SharedModules Architecture Team  
Version: 1.3.0  
Status: Authoritative Specification  
Date: 2026-08-16  

---

## 1. Executive Summary

`SharedModules` is the foundational utility repository for reusable PowerShell modules ("Atoms") in the workspace. It encapsulates common infrastructure for logging, volume inventory queries, and Windows BCD operations.

---

## 2. Functional Requirements

### A. Logging Atoms (`REQ-LOG-*`)
* **`REQ-LOG-001` (Session Log Formatting)**: The module `MUST` format standard session log paths using the convention `yyyyMMdd HHmm <Label> <ComputerName>.log`.
* **`REQ-LOG-002` (Context-Based Logging)**: The module `MUST` provide `Initialize-LogContext`, `Write-LogMessage`, and `Write-Log` supporting file, transcript, and console output channels.
* **`REQ-LOG-003` (Non-Blocking & Graceful Logging)**: If a log path is unwriteable or disabled, logging operations `MUST` fail silently without interrupting core execution.

---

### B. Volume & Storage Atoms (`REQ-VOL-*`)
* **`REQ-VOL-001` (Volume Serial Resolution)**: `Get-VolumeSerialHex` `MUST` resolve volume serial numbers in hex format using `fsutil fsinfo volumeinfo <path>`.
* **`REQ-VOL-002` (Volume Filesystem Attributes)**: `Get-VolumeFsInfo` `MUST` extract `SerialHex`, `VolumeLabel`, and `FileSystemName`.
* **`REQ-VOL-003` (EFI System Partition Resolution)**: `Get-EfiPartitionVolume` `MUST` discover the active EFI System Partition by GPT type `{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}` and resolve its `FileSystemLabel`.
* **`REQ-VOL-004` (Fltmc Volume Enumeration)**: `Get-FltmcVolumeRows` `MUST` parse `fltmc volumes` into NT device names (`\Device\HarddiskVolumeN`) while filtering non-volume pseudo devices (`Mailslot`, `Mup`, `NamedPipe`).
* **`REQ-VOL-005` (Partition Serial Correlation)**: `Get-PartitionMetaBySerial` `MUST` correlate volume serial numbers with physical disk numbers, partition numbers, start offsets, and GPT/MBR types.

---

### C. BCD Operations Atoms (`REQ-BCD-*`)
* **`REQ-BCD-001` (BCD Referenced NT Volumes)**: `Get-BcdReferencedNtVolumes` `MUST` query `bcdedit /enum all /v` and extract unique referenced `\Device\HarddiskVolumeN` paths.
* **`REQ-BCD-002` (BCD Object Enumeration)**: `Get-BcdBootEntries` `MUST` parse full BCD object blocks into structured objects (GUID, device partition, path, description, recoverysequence).
* **`REQ-BCD-003` (Display Order Parsing)**: `Get-BcdDisplayOrder` `MUST` parse the `{bootmgr}` `displayorder` array.
* **`REQ-BCD-004` (Dual-Format BCD Backup)**: `Export-BcdBackup` `MUST` generate a binary hive (`.bak`) via `bcdedit /export`, generate an alias-annotated text report (`.txt`), and clean up transient `.LOG` transaction sidecars.

---

### D. Quality & Testing (`REQ-QA-*`)
* **`REQ-QA-001` (Pure Atom Testability)**: All atoms `MUST` be testable via Pester unit tests using mockable commands and zero system reboots.
