# SharedModules Documentation Directory

Module: docs/README.md  
Authors: Rolf, SharedModules Architecture Team  
Version: 1.3.0  
Status: Authoritative Standard  
Date: 2026-08-16  

---

## 1. Documentation Fabric

- **[Requirements.md](Requirements.md)** — Normative requirements for Logging, VolumeAtoms, and BcdAtoms modules.
- **[Architecture.md](Architecture.md)** — Architectural design, module contracts, and cross-repository consumer topology.
- **[Standards.md](Standards.md)** — Coding conventions and LCM governance invariants.
- **[Changelog.md](Changelog.md)** — Release history.

---

## 2. Verification & Quality Gates

Run the local readiness test runner:
```powershell
pwsh -ExecutionPolicy Bypass -File .\tools\Test-RepoReadiness.ps1
```
