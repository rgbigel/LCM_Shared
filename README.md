# SharedModules

Central repository for reusable PowerShell atoms shared by multiple solutions.

## Layout
- Modules
- docs

## Initial modules
- Logging.psm1
- PrivatePaths.psm1
- TranscriptTools.psm1

## Versioning
- Modules are versioned independently in their headers.
- Consumers should import by path priority:
  1) local Modules
  2) SharedModules/Modules

## Private paths
- PrivatePaths.psm1 centralizes machine-local path values.
- Installers may later replace or validate these values during deployment.
