# LCM_Shared

Version: 10.0.0 (LCM Governed 10.0.0)

Central library of reusable, specialized functional **PowerShell Modules ("Atoms")** for the workspace ecosystem.

`LCM_Shared` exposes cohesive, decoupled utility modules consumed by multiple repositories:
- **`Logging.psm1`**: Standardized session logging, transcript capture, context initialization, and structured log message formatters.
- **`VolumeAtoms.psm1`**: Low-level volume serial resolution (`fsutil`), filesystem attributes, filter-manager device parsing (`fltmc`), and EFI System Partition discovery by GPT type.
- **`BcdAtoms.psm1`**: Windows Boot Configuration Data (BCD) parser, displayorder array extraction, BCD referenced volume resolution, and dual-format backup generation (`.bak` hive + annotated `.txt` snapshot).
- **`PrivatePaths.psm1`** & **`TranscriptTools.psm1`**: Local system paths and transcript helpers.

---

## Repository Layout

- `Modules/Logging.psm1`: Shared logging utilities.
- `Modules/VolumeAtoms.psm1`: Shared storage and volume inventory atoms.
- `Modules/BcdAtoms.psm1`: Shared BCD discovery, parsing, and backup atoms.
- `Modules/PrivatePaths.psm1`: Private system paths.
- `Modules/TranscriptTools.psm1`: Transcript helpers.
- `tests/LCM_Shared.Tests.ps1`: Pester test suite for all exported atoms.
- `docs/`: Requirements, architecture, standards, and LCM governance specifications.
- `tools/`: Quality gates and elevated readiness test runner.

---

## System Prerequisites

- **Operating System**: Windows 10/11 x64
- **PowerShell**: PowerShell 7 (`pwsh.exe` 7.0+) or Windows PowerShell 5.1
- **Git**: Git for Windows
- **Filesystem**: NTFS filesystem (directory junctions & hardlinks)
- **Privileges**: Administrator privileges required for low-level storage query APIs (`bcdedit`, `fltmc`, `fsutil`)

---

## Documentation

- **[Requirements.md](docs/Requirements.md)** — Functional specifications and exported atom contracts.
- **[Architecture.md](docs/Architecture.md)** — Architectural design and cross-repository dependency topology.
- **[Implementation.md](docs/Implementation.md)** — Current module, test, and repository-layout inventory.
- **[Standards.md](docs/Standards.md)** — Module standards and LCM governance rules.
- **[Changelog.md](docs/Changelog.md)** — Release history.
