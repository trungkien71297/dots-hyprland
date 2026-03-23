# AGENTS.md (dots-hyprland)

## Commands (repo root)
- Install/update: `./setup install` (interactive; modifies your system)
- Safer preview: `./setup exp-update --dry-run` (then re-run without it)
- Quickshell dev: `pkill qs; qs -c ii` (from your user session)
- Bash syntax: `bash -n setup` (or `bash -n path/to/script.sh`)
- Bash lint (if installed): `shellcheck -e SC1090,SC1091,SC2148,SC2034,SC2155,SC2164 setup` (and `shellcheck path/to/*.sh`)
- Tests: `bash sdata/subcmd-exp-update/exp-update-tester.sh`
- Single test: `bash -c 'source sdata/subcmd-exp-update/exp-update-tester.sh; test_shellcheck'` (replace function)

## Style / conventions
- Bash: prefer `set -euo pipefail`, quote vars, avoid `sudo`/root; add `# shellcheck shell=bash` to sourced scripts.
- Bash errors: use `log_info/log_warning/log_error/log_die` + `require_command` from `sdata/lib/functions.sh`.
- Paths: vet user-provided paths via `sanitize_path`; don’t write outside repo/$HOME without explicit intent.
- QML: keep `pragma` lines first; group imports `qs.*` → `QtQuick` → `Quickshell*`.
- QML: prefer typed `property <type>` and `function foo(): void`; `id` lowerCamel, components `PascalCase`.
- QML: avoid deep nesting (early returns, small `component`s/`Loader`s); keep spaces around operators.
- Python: use uv venv `$ILLOGICAL_IMPULSE_VIRTUAL_ENV`; update deps via `sdata/uv/requirements.in` → `uv pip compile ...`.

## Editor rules
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` found.
