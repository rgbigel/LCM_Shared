# SharedModules

Central repository for reusable PowerShell atoms shared by multiple solutions.

## Layout
- Source/Modules
- docs

## Initial modules
- Logging.psm1
- TranscriptTools.psm1

## Versioning
- Modules are versioned independently in their headers.
- Consumers should import by path priority:
  1) local Source/Modules
  2) SharedModules/Source/Modules
