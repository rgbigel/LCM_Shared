# Logging Module Upgrade Notes

This document describes interface changes introduced by `Modules/Logging.psm1` v1.2.0 and what repositories must update when migrating.

## Scope of change
- Legacy function remains available: `Write-Log`
- New context-based logging API is added for standard run behavior across scripts.
- Default log root is repository-scoped: `%TEMP%\\<repo>\\<log-prefix>\\Logs`.

## Backward compatibility
- Existing calls to `Write-Log -Message <...> -LogFile <...>` continue to work.
- Migration can be phased: old calls may coexist temporarily with new API.

## New exported interface (v1.2.0)
- `Initialize-LogContext`
- `Write-LogMessage`
- `Write-LogHeader`
- `Write-TraceLog`
- `Write-LogFinalStatus`
- `Close-LogContext`
- `Write-Log` (legacy compatibility)

## Addendum: interactive switch `-i`
- `Initialize-LogContext` now supports `-InteractiveMode` (alias: `-i`).
- Global rule: trace mode implies interactive mode.
    - If `-EnableTrace:$true`, the logging context automatically enables interactive mode.
    - Callers may still pass `-i`, but it is no longer required for trace behavior.
- New override: `-NonInteractive`
    - Forces interactive mode off, even when trace is enabled.
    - Use this for automation or unattended flows where prompts are not allowed.
- Interactive-host enforcement is caller policy controlled via `-RequireInteractiveModeInInteractiveHost`.
    - If this switch is set and host is interactive, omitting `-i` throws.
    - If this switch is not set, callers may omit `-i` when their solution does not require interactive log offering.
- When `-i` is set, after final status is written and `Close-LogContext` runs, user is prompted to optionally open the current log in Notepad++.

## Notepad++ path prerequisite
- Interactive log-open uses command resolution for `notepad++`.
- If `notepad++` is not resolvable from PATH, the module prints a warning and continues safely.
- For multi-repository consistency, define/provision Notepad++ command availability via your `@always_Customize` baseline on target systems.

## Required repository changes when upgrading

### 1. Import and initialize context once per script
Replace local ad-hoc log setup with one call near startup:
- `Initialize-LogContext -ScriptName <name> -ScriptVersion <version> -EnableLogging <bool> -EnableTrace <bool> -InteractiveMode -RepositoryName <repo> -Mode File|Transcript`

### 2. Replace local header/final output helpers
Use shared API:
- Start of run: `Write-LogHeader -Context $ctx`
- End of run: `Write-LogFinalStatus -Context $ctx -Code <int> -Message <text>`

### 3. Replace local trace writers
Use:
- `Write-TraceLog -Context $ctx -Message <text>`

### 4. Replace message output wrappers
Use:
- `Write-LogMessage -Context $ctx -Level INFO|WARN|ERROR|OK|FINAL -Message <text>`

### 5. Ensure transcript lifecycle is closed
For scripts using transcript mode, always call:
- `Close-LogContext -Context $ctx`
Typically this should happen in the final exit helper or a `finally` block.

### 6. Preserve script contract semantics
The migration should not change:
- existing flag meanings (`-t`, `-l`, etc.)
- user-visible success/failure semantics
- existing exit codes

## Recommended mode by script type
- Runtime scripts with optional logging flag: `Mode File`
- Installer/setup branch with always-on logging: `Mode Transcript`

## Minimal migration template
```powershell
$ctx = Initialize-LogContext -ScriptName "MyScript.ps1" -ScriptVersion "1.0.0" -EnableLogging:$true -EnableTrace:$TraceMode -InteractiveMode:$InteractiveMode -NonInteractive:$NonInteractive -RequireInteractiveModeInInteractiveHost:$EnforceInteractivePolicy -Mode "Transcript"
Write-LogHeader -Context $ctx

try {
    Write-TraceLog -Context $ctx -Message "Working..."
    Write-LogFinalStatus -Context $ctx -Code 0 -Message "Completed."
    Close-LogContext -Context $ctx
    exit 0
}
catch {
    Write-LogMessage -Context $ctx -Level "ERROR" -Message $_.Exception.Message
    Write-LogFinalStatus -Context $ctx -Code 1 -Message $_.Exception.Message
    Close-LogContext -Context $ctx
    exit 1
}
```

## Interface changes for repo maintainers checklist
- Replace local logging init with `Initialize-LogContext`
- Optionally expose and route `-i` to `Initialize-LogContext -InteractiveMode`
- Add optional non-interactive switch and route to `-NonInteractive` for unattended execution paths
- Decide and set caller policy for interactive-host enforcement via `-RequireInteractiveModeInInteractiveHost`
- Replace local trace function with `Write-TraceLog`
- Replace local final block with `Write-LogFinalStatus`
- Add `Close-LogContext` on all terminal paths
- Keep any legacy `Write-Log` use only where context migration is deferred
