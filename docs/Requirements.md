# LCM_Shared: Requirements Specification

Module: docs/Requirements.md  
Authors: Rolf, LCM_Shared Architecture Team  
Version: 10.0.0
Status: Working Draft (NOT Source of Truth - Architectural Concept)  
Date: 2026-10-13

---

## 1. Executive Summary

> [!NOTE]
> **Draft Status**: This document represents an exploratory working concept and is **currently NOT the authoritative source of truth**. It articulates an emerging architecture where `LCM_Shared` functions as the decoupled, satellite execution arm and atom repository for `LCM_Inventory`.

`LCM_Shared` is the foundational utility repository for reusable PowerShell modules ("Atoms") in the workspace. It encapsulates common infrastructure for logging, volume inventory queries, and Windows BCD operations.

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

---

## 3. Governance, Inspection & Tooling Requirements (`REQ-TOOL-*`) [Draft Concept]

> [!IMPORTANT]
> **Tool Ownership & Versioning Boundary (Working Concept)**:
> In this architectural draft, the inspection and visualization tools outlined below (`ShowContracts`, `ShowInterfaces`, `ShowModules`, `ShowAtoms`) are planned to reside physically within and be governed/versioned by **`LCM_Inventory`** (as part of its central system cataloging capabilities).
> 
> * **`LCM_Shared` Versioning**: Governs the implementation code, `.psm1`/`.psd1` files, core classes, unit tests, and internal module documentation.
> * **`LCM_Inventory` Versioning**: Governs the inspection tooling, HTML dashboards, schemas, and ecosystem registry. `LCM_Inventory` serves as the system of record that knows all parts of the implementation and tracks their individual versions.

### A. Contract Verification Engine (`REQ-TOOL-001` / `ShowContracts`) - Core Priority
* **`REQ-TOOL-001` (Authoritative Contract Verification & Visualization)**: `ShowContracts` (`Show-Contracts.ps1`, hosted in `LCM_Inventory`) `MUST` inspect and render all public contract specifications, schema invariants, parameter type assertions, and return-type expectations defined across LCM_Shared. It `MUST` audit consuming repositories for contract adherence, validate API boundary contracts, and detect contract drift or signature mismatches.

### B. Interface & Module Inspection (`REQ-TOOL-002` / `ShowInterfaces`, `REQ-TOOL-003` / `ShowModules`)
* **`REQ-TOOL-002` (Public Interface Discovery)**: `ShowInterfaces` (`Show-Interfaces.ps1`, hosted in `LCM_Inventory`) `MUST` enumerate all exported PowerShell functions, cmdlets, classes, and public API signatures with their input parameter sets, type bindings, and pipeline capabilities.
* **`REQ-TOOL-003` (Module Structure & Dependency Visualization)**: `ShowModules` (`Show-Modules.ps1`, hosted in `LCM_Inventory`) `MUST` map module manifests (`.psd1`), root script files (`.psm1`), module dependencies, version parity, and load order hierarchies across the workspace.

### C. Granular Atom Catalog (`REQ-TOOL-004` / `ShowAtoms`)
* **`REQ-TOOL-004` (Reusable Atom Inventory)**: `ShowAtoms` (`Show-Atoms.ps1`, hosted in `LCM_Inventory`) `MUST` catalogue all granular, pure atomic functions ("Atoms") with their test coverage, Pester unit test linkage, isolation status, and cross-subsystem consumption metrics.
