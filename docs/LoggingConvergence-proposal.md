# Proposal: Logging Module Convergence Baseline

proposal_id: SM-20260813-logging-convergence
status: pending-review
repository: SharedModules
created: 20260813_194051
scope: SharedModules; read-only observations under D:/Git_Repositories

## Summary

Use `SharedModules/Modules/Logging.psm1` as the preferred cross-repository logging baseline unless a repo-local proposal documents why a local logging implementation must remain divergent.

## Current SharedModules Baseline

`Modules/Logging.psm1` is version `1.2.0` and provides:

- Legacy compatibility: `Write-Log`.
- Context API: `Initialize-LogContext`, `Write-LogMessage`, `Write-LogHeader`, `Write-TraceLog`, `Write-LogFinalStatus`, `Close-LogContext`.
- Default repository-scoped log root behavior under `%TEMP%/<repo>/<prefix>/Logs`.
- Timestamped log filenames using `yyyyMMdd_HHmmss_fff`.

The scan found this copy has the newest `LastWriteTime` among discovered `Logging.psm1` files: `20260719_164225`.

## Divergence Observed

Read-only scan under `D:/Git_Repositories` found divergent copies:

| Repo or folder | Proper repo | Path | LastWriteTime | SHA256 | Recommendation |
| --- | --- | --- | --- | --- | --- |
| BackgroundModifier | yes | `D:/Git_Repositories/BackgroundModifier/Modules/Logging.psm1` | `20260719_164217` | `7D0A7DAB83C4D4D9247BE15309EB244B9856F66AD06E3D6F7683655421935AC1` | Create a repo-local migration proposal when scope allows. |
| BackgroundModifier_AC | yes | `D:/Git_Repositories/BackgroundModifier_AC/Modules/Logging.psm1` | `20260719_164217` | `7D0A7DAB83C4D4D9247BE15309EB244B9856F66AD06E3D6F7683655421935AC1` | Create a repo-local migration proposal when scope allows. |
| BootOpsHub | no | `D:/Git_Repositories/BootOpsHub/SolutionCode/Modules/Logging.psm1` | `20260719_164219` | `383AF2B6CE22AC3DD1582635665014F7AA9189577365E01F99AC8E670C55AA50` | Non-proper repo observation only. |

## Proposal

1. Treat `SharedModules/Modules/Logging.psm1` as the current preferred baseline.
2. Do not replace solution-specific local logging blindly. Require each proper repo to document whether local behavior should be migrated, retained as an adapter, or proposed for promotion into SharedModules.
3. Keep `docs/LoggingUpgrade.md` as the migration guide for consumers adopting the context API.
4. If a local repo needs functionality not present in SharedModules, prepare a SharedModules change proposal before modifying the central module.

## Current Decision

No code change to `Modules/Logging.psm1` is proposed by this scan. There is no evidence that the SharedModules copy is outdated; it is the newest discovered copy and has the most complete interface documentation.
