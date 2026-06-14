# Module Policy

## Goals
- Reuse stable atoms across repositories.
- Keep modules narrowly scoped and backward compatible.

## Compatibility
- Avoid breaking signatures of exported functions.
- Add optional parameters instead of changing required ones.

## Consumer strategy
- Repositories may keep local overrides under Source/Modules.
- SharedModules is the default fallback location.
