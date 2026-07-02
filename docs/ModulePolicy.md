# Module Policy

## Goals
- Reuse stable atoms across repositories.
- Keep modules narrowly scoped and backward compatible.

## Compatibility
- Avoid breaking signatures of exported functions.
- Add optional parameters instead of changing required ones.

## Logging interface upgrades
- Logging module migration guidance is documented in `docs/LoggingUpgrade.md`.
- Repositories adopting Logging v1.2.0 should migrate local logging helpers to the shared context API.
- Keep `Write-Log` only as a temporary compatibility path during phased migrations.

## Consumer strategy
- Repositories may keep local overrides under Modules.
- SharedModules is the default fallback location.

## Private path handling
- Machine-local roots belong in PrivatePaths.psm1, not scattered across scripts.
- Installers may later substitute these values for target systems.
