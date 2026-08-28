# .specify/

Spec-driven pipeline scaffolding, after GitHub Spec Kit.

- `memory/constitution.md` — the always-on rules every core skill reads first.
- `templates/` — artifact scaffolds the pipeline skills copy from.
- `bridge.md` — spec for the optional file↔store adapter (built in the orchestrator phase).

Pipeline artifacts themselves live in `specs/NNN-<slug>/` (`spec.md`, `plan.md`,
`review.md`, `gates/`), not here. `CODEBASE.md` stays at the repo root.
