# SharedModules: Architectural Specification

Module: docs/Architecture.md  
Purpose: Architectural design, satellite relationship with Workspace_Inventory, and component layout for SharedModules.  
Path: docs/Architecture.md  
Authors: Rolf, SharedModules Architecture Team  
Version: 1.1.0  
Status: Working Draft (NOT Source of Truth - Architectural Concept)  
Date: 2026-09-28  

---

> [!NOTE]
> **Draft Status Warning**: This document is an exploratory architectural working concept and is **currently NOT the authoritative source of truth**. It establishes the draft framework under which `SharedModules` acts as a satellite execution repository and atom library aligned with `Workspace_Inventory`.

---

## 1. System Context & Architectural Foundation

`SharedModules` provides foundational, reusable PowerShell modules ("Atoms") across the Lifecycle Model (LCM) workspace. Under this emerging architecture:

1. **Satellite Execution App for `Workspace_Inventory`**:
   - `SharedModules` functions as the decoupled, headless execution engine for system introspection and volume topology.
   - It provides pure, stateless atoms that discover, query, and format OS, storage, and BCD data.
   - `Workspace_Inventory` acts as the primary data store and system of record that ingests, models, and stores this information.

2. **Decoupled Lifecycle & Physical Separation**:
   - `SharedModules` is deliberately maintained in a separate repository to isolate pure module code, Pester tests, and semantic versioning from the frequent commit churn of inventory scans, review receipts, and telemetry data.

```mermaid
graph LR
    subgraph SharedModules_Repo["SharedModules (Execution & Atoms)"]
        SM_VOL["Volume Atoms<br/>(fsutil, fltmc, GPT)"]
        SM_BCD["BCD Atoms<br/>(bootmgr, objects)"]
        SM_LOG["Logging Atoms<br/>(context, streams)"]
        SM_TEST["Pester Unit Tests<br/>(tests/)"]
    end

    subgraph Workspace_Inventory_Repo["Workspace_Inventory (System of Record & Tooling)"]
        INV_DATA[("inventory.json<br/>System Matrix")]
        INV_TOOLS["Diagnostic Inspectors<br/>(ShowContracts, ShowInterfaces, etc.)"]
        INV_SCHEMAS["JSON Data Schemas"]
    end

    SM_VOL -->|Raw Hardware State| INV_DATA
    SM_BCD -->|Boot Configuration State| INV_DATA
    INV_TOOLS -.->|AST & Contract Audit| SharedModules_Repo
```

---

## 2. Versioning & Ownership Boundaries

| Domain | Governing Repository | Scope & Lifecycle |
| :--- | :--- | :--- |
| **Inspection Tools & Dashboards** | **`Workspace_Inventory`** | Governs `ShowContracts`, `ShowInterfaces`, `ShowModules`, `ShowAtoms`, HTML viewers, and validation scanners. |
| **Modules, Sources & Atoms** | **`SharedModules`** | Governs `.psm1`/`.psd1` files, core classes, Pester unit tests, and module documentation with independent `M.Y.Z` versioning. |
| **Ecosystem State Registry** | **`Workspace_Inventory`** | Single source of truth that tracks, records, and audits all parts of the implementation and their individual versions. |

---

## 3. Core Component Layout

* **`Modules/` & `Source/`**: Pure PowerShell module definitions and atom implementations.
* **`tests/`**: Unit test suites executing mockable Pester tests without host side-effects or system reboots (`REQ-QA-001`).
* **`docs/`**: Tripartite specifications (`Architecture.md`, `Requirements.md`, `Implementation.md`).
