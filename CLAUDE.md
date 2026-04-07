# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

A personal collection of standalone scripts and utilities. There is no build system, package manager, or test framework — each script is self-contained and executable directly.

## Languages and Patterns

- **Shell scripts** (bash/zsh) — the majority of the repo. Most use `#!/bin/bash` or `#!/usr/bin/env bash`.
- **Python scripts** — newer ones use [PEP 723 inline script metadata](https://peps.python.org/pep-0723/) with `uv run --script` shebangs (e.g., `#!/usr/bin/env -S uv run --script`). Dependencies are declared in the `# /// script` block at the top of each file. Do not create `requirements.txt` or `pyproject.toml` — keep dependencies inline.
- **Perl scripts** — older utilities, use `#!/usr/bin/env perl`.
- **One legacy Python 2 script** (`mail-stats.py`) — leave it as-is unless asked to port.

## Running Scripts

Scripts are meant to be run directly from `~/bin` (this repo is symlinked or added to PATH). No build step needed.

For Python scripts using uv inline metadata:
```
uv run --script <script-name>.py [args]
```

## Key Subdirectories

- `feed-gen/` — RSS/Atom feed generators monitoring Minnesota politics, news, and FEC data. All use `uv run --script` with `requests` as a dependency.
- `raycast/` — Raycast script commands (search shortcuts). Follow Raycast's script command metadata format in comments.
- `controlplane/` — Home automation scripts.
- `geektools/` — GeekTool desktop widget scripts.
- `templates/` — Template files used by other scripts (e.g., note templates).

## Conventions

- All scripts should be executable (`chmod +x`).
- Credentials and secrets are stored externally (typically in `~/.credentials/`) and sourced at runtime — never inline.
- The `.gitignore` excludes employer-specific and host-specific scripts that are symlinked into this directory.
- Scripts that wrap other tools (like `pr-snarf.sh` wrapping `nh-pr-fetch.py`) source environment files for configuration rather than hardcoding values.

## When Adding New Scripts

- For new Python scripts, use `uv run --script` with inline PEP 723 metadata — no virtual environments or separate dependency files.
- For new shell scripts, prefer `#!/usr/bin/env bash` for portability.
- Keep scripts self-contained. Shared libraries/modules are not a pattern here.
