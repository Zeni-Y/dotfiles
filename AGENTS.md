# Repository Guidelines

## Project Structure & Module Organization
This repository manages dotfiles with `chezmoi`; `.chezmoiroot` points the source root at `home/`. Put managed files under `home/` using chezmoi naming rules such as `dot_`, `private_`, `encrypted_`, `executable_`, and `.tmpl`. Use `home/.chezmoiscripts/` for apply-time hooks, split by scope (`common/`, `ubuntu/`) and ordered with numeric prefixes like `run_once_after_01-*`. Keep reusable install logic in `install/` and include it from chezmoi scripts. Supporting docs live in `books/`, container helpers in `docker/`, and the bootstrap entrypoint is `install.sh`.

## Build, Test, and Development Commands
Use `chezmoi` for the normal edit/apply loop:

- `chezmoi diff` checks drift before applying changes.
- `chezmoi apply --dry-run --verbose` previews rendered changes.
- `make update` applies the repo with verbose output.
- `make init` runs `chezmoi init --apply --verbose` for fresh-machine validation.
- `make docker` starts a clean Ubuntu test container with the repo mounted.
- `make docker-rebuild` rebuilds that image without cache.
- `make reset` clears the `scriptState` bucket so `run_once_*` scripts can be re-tested.

## Coding Style & Naming Conventions
Shell is the primary implementation language. Use `#!/usr/bin/env bash`, keep scripts idempotent, and prefer strict mode (`set -Eeuo pipefail`) for new bootstrap logic. `.editorconfig` currently defines `indent_size = 4` for `*.sh`; follow that consistently. Write comments and user-facing docs in Japanese where the surrounding file already does. Name chezmoi-managed files by target behavior, for example `home/dot_zshrc`, `home/private_dot_ssh/`, or `home/dot_config/git/config.tmpl`.

## Testing Guidelines
There is no top-level `tests/` suite in the current tree, so validation is primarily integration-based. Test changes with `chezmoi diff`, `chezmoi apply --dry-run`, and a real apply in Docker via `make docker`. When touching `run_once_*` or install logic, use `make reset` before re-running the flow. If you add automated tests later, mirror the source layout under `tests/`.

## Commit & Pull Request Guidelines
Recent history mostly follows Conventional Commits, for example `feat:`, `fix:`, and `docs:`; keep using that style and make the scope explicit. Avoid vague messages like `update`. For pull requests, include a short summary, affected paths, platform impact (`darwin`/`linux`, `client`/`server`), and the commands you used to validate the change. Include screenshots only when editor UI settings or rendered documentation materially change.
