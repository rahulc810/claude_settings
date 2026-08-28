---
name: crawl
description: "Explore a codebase and write or update a CODEBASE.md context document covering tech stack, code style, module map, architecture, business description, tradeoffs, and pitfalls. Designed to be fed into other agents to bring them up to speed without manual re-explanation. Trigger on: crawl, explore codebase, map the codebase, document the codebase, onboard agent, bring agent up to speed, codebase overview, codebase context, write CODEBASE.md."
argument-hint: "Root directory to crawl (defaults to repo root). Optionally specify output path."
tools: [read, edit, search, execute, todo, Read, Glob, Grep, Write, Edit, Bash, TodoWrite]
---

# Crawl

Explore a codebase and produce a dense, factual `CODEBASE.md` context document. The output is optimized for agent consumption — it can be attached to any other skill (implement, review, diagnose, improve) to give accurate project context without manual re-explanation.

**Output**: `CODEBASE.md` at the repo root (or caller-specified path), created or updated in place.

## When to Use
- Starting work on an unfamiliar codebase
- Onboarding another agent that needs project context
- `CODEBASE.md` is missing or stale
- Before handing off between plan → dev → review stages

## Output Structure

Always produce all seven sections, even if brief. Omitting a section silently degrades downstream agent quality.

```markdown
# Codebase Context

## Business Description
## Tech Stack
## Code Style
## Module Map
## Architecture
## Tradeoffs
## Pitfalls
```

---

## Procedure

### Step 1 — Anchor on Config Files

Read project root files first. These establish tech stack, runtime, and entry points.

| File(s) | Signals |
|---------|---------|
| `package.json`, `package-lock.json` | Node/JS, framework, scripts |
| `pyproject.toml`, `requirements.txt`, `setup.py` | Python, dependencies |
| `go.mod`, `go.sum` | Go modules |
| `Cargo.toml` | Rust |
| `pom.xml`, `build.gradle` | Java/Kotlin |
| `*.csproj`, `*.sln` | .NET |
| `Dockerfile`, `docker-compose.yml` | Runtime environment |
| `Makefile`, `justfile`, `taskfile.yml` | Build/task system |
| `tsconfig.json`, `.eslintrc*`, `.prettierrc*` | JS toolchain config |
| `README.md`, `docs/` | High-level description and intent |

Record: primary language(s), runtime, major frameworks, key libraries, test framework, build tool.

### Step 2 — Map the Directory Structure

List top-level directories and one level down. Exclude noise directories (`node_modules`, `.git`, `dist`, `__pycache__`).

Tag each significant directory with its role:

| Tag | Meaning |
|-----|---------|
| `entry` | Application entry points |
| `core` | Primary business logic |
| `api` | External-facing interfaces (HTTP routes, CLI commands, RPCs) |
| `data` | Persistence, models, migrations, schemas |
| `infra` | Config, deployment, infrastructure code |
| `test` | Test suites |
| `docs` | Documentation |
| `util` | Shared helpers and utilities |
| `generated` | Machine-generated — do not modify directly |

### Step 3 — Find Entry Points and Architectural Hubs

Identify files that are hubs — files many others import, or that wire the system together. Read the top 3–5 entry points and hubs.

For each hub, understand:
- What starts the application
- What the main abstractions are
- How layers connect (who calls whom)

### Step 4 — Extract Code Style

Sample 2–3 representative files (one per major module). Note the **dominant** pattern — not edge cases:

- **Naming**: snake_case / camelCase / PascalCase per symbol type (vars, types, constants, files)
- **Error handling**: exceptions / Result/Either types / error codes / panic+recover
- **Async model**: sync / async-await / callbacks / goroutines / actors / futures
- **Tests**: structure (unit + integration?), mocking approach, test file naming convention
- **Comments**: docstrings / JSDoc / inline only / minimal
- **Import ordering**: stdlib → third-party → local, or other grouping

### Step 5 — Find Tradeoffs and Decisions

Look for decision artifacts:

- `docs/adr/`, `docs/decisions/`, `docs/rfcs/` — Architecture Decision Records
- Comments tagged `NOTE:`, `WHY:`, `DECISION:`, `TRADEOFF:`
- README sections titled "Why X", "Architecture", "Design Decisions"

Summarize each as:
> **[Topic]**: [What was chosen] because [reason]. Tradeoff: [what was given up].

### Step 6 — Find Pitfalls

Look for signals of fragile or non-obvious areas:

- `FIXME:` and `HACK:` comments — known broken or fragile code
- Files with `workaround`, `bypass`, `kludge` language
- Files >500 lines — potential hidden coupling
- Initialization order dependencies, required env vars, secret bootstrapping
- Non-obvious constraints buried in setup docs or config comments

Capture each as:
> **[File or area]**: [What's fragile], [why], [what to watch out for].

### Step 7 — Write CODEBASE.md

Use this template. Fill every section — prefer brief and accurate over long and vague.

````markdown
# Codebase Context
<!-- Generated by the crawl skill. Re-run to refresh. -->
<!-- Last updated: YYYY-MM-DD -->

## Business Description
[1–3 sentences: what the system does, who uses it, core value delivered. No marketing language.]

## Tech Stack
- **Language**: [e.g. TypeScript 5.4, Python 3.12]
- **Runtime**: [e.g. Node.js 22, CPython, JVM 21]
- **Framework**: [e.g. Express 4, FastAPI 0.111, Spring Boot 3]
- **Database**: [e.g. PostgreSQL 16 via Prisma ORM]
- **Testing**: [e.g. Vitest + Supertest, pytest + httpx]
- **Build**: [e.g. tsc + esbuild, Makefile targets]
- **Key deps**: [2–5 notable libraries and what they do]

## Code Style
- **Naming**: [conventions per symbol type — vars, types, constants, files]
- **Error handling**: [pattern — exceptions / Result types / error codes]
- **Async**: [model — sync / async-await / goroutines / etc.]
- **Tests**: [file structure, naming convention, mocking approach]
- **Formatting**: [tools and key enforced rules]

## Module Map
| Directory | Role | Key Files |
|-----------|------|-----------|
| `src/api` | HTTP route handlers | `routes.ts`, `middleware.ts` |
| `src/core` | Business logic | `order.ts`, `pricing.ts` |
| `src/data` | DB models + migrations | `schema.prisma` |

## Architecture
[2–5 bullets describing layers, how they connect, and the data flow for a typical request/operation. Name the main abstractions. Note any non-obvious coupling.]

## Tradeoffs
- **[Topic]**: [Decision] because [reason]. Tradeoff: [cost].
- [If none documented: "None documented — consider adding ADRs to `docs/adr/`."]

## Pitfalls
- **[File/area]**: [What's fragile, why, what to watch out for.]
- [If none found: "No FIXMEs or HACs found. Monitor for complexity growth in [largest file]."]
````

### Step 8 — Update If CODEBASE.md Already Exists

If `CODEBASE.md` already exists:
1. Read the existing file
2. Identify stale sections (compare tech stack versions, module structure, etc.)
3. Update stale sections in place
4. **Preserve** hand-written annotations — lines prefixed with `> ` are human notes, do not overwrite them
5. Append newly discovered pitfalls and tradeoffs rather than replacing existing ones
6. Update the `Last updated` date

---

## Done Criteria
- All 7 sections are present and non-empty
- Tech stack lists actual versions, not vague framework names
- Module map covers every top-level source directory
- Architecture section names the main abstractions, not just "there are layers"
- At least one tradeoff entry (even if it states none were found)
- Pitfalls section reflects any FIXMEs/HACKs found (even if it states none were found)
- File saved at the target path
