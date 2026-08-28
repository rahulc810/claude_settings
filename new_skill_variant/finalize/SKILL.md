---
name: finalize
description: "Prepare code for merging. Use when code is ready to merge, before opening a PR, or after all reviews are resolved. Handles: done checks, pre-merge documentation, changelog updates, version bumps (feature/fix/hotfix/chore), and staged git commits with conventional commit messages. Trigger on: finalize, ready to merge, ship it, prep for PR, version bump, stage and commit, pre-merge."
argument-hint: "Change type (feature|fix|hotfix|chore|refactor) and optional scope or description"
tools: [Read, Edit, Search, Grep, Glob, Bash, Todo]
---

# Finalize

Prepare a branch for merge. Run through done-checks, update docs and version, then produce a clean commit.

## When to Use
- Code is functionally complete and reviewed
- You need to bump the version, update the changelog, and commit
- Pre-PR checklist before opening or merging a pull request

## Step 1 — Determine Change Type

Ask (or infer from context) which type applies:

| Type | Semver Impact | When |
|------|--------------|------|
| `feature` | Minor bump (`0.X.0`) | New user-facing capability |
| `fix` | Patch bump (`0.0.X`) | Bug correction |
| `hotfix` | Patch bump (`0.0.X`) | Urgent production fix on a release branch |
| `chore` | Patch bump or none | Tooling, deps, CI — no user-facing change |
| `refactor` | Patch bump or none | Code restructure, no behavior change |

If the type cannot be inferred, **stop and ask** before continuing.

## Step 2 — Done Checks

Verify before touching any file:

- [ ] All planned work items are resolved (no open TODOs added by this task)
- [ ] Tests pass locally (`run test command`)
- [ ] No debug/temporary code left (`console.log`, `debugger`, `pdb.set_trace`, `TODO(wip)`)
- [ ] No merge conflicts in the branch
- [ ] Linting/type-checks pass if configured

If any check fails, **stop and report what is blocking**. Do not proceed to documentation or versioning until the branch is clean.

## Step 3 — Pre-Merge Documentation

Update only what applies to this repo:

1. **CHANGELOG / RELEASE_NOTES** — Add an entry under `## [Unreleased]` or the new version heading:
   ```
   ### Added / Fixed / Changed / Removed
   - <concise description of what changed and why it matters to users>
   ```
2. **README** — Update if the change affects setup steps, usage examples, or feature lists.
3. **API / schema docs** — Update if public interfaces changed.
4. **Migration guide** — Add a note if the change is breaking.

Skip any file that does not exist in the repo rather than creating it.

## Step 4 — Version Bump

1. Locate the version source (in order of precedence): `package.json`, `pyproject.toml`, `setup.cfg`, `VERSION`, `version.go`, or similar.
2. Read the current version.
3. Apply the semver increment for the change type (see Step 1 table).
4. Write the new version back to **all** version files that must stay in sync.
5. Report: `Version: X.Y.Z → X.Y.Z+1`

If the project uses a manual tagging strategy (no version file), note the tag to create and skip file edits.

## Step 5 — Stage and Commit

### Staging
Stage only files relevant to this change:
```
git add <changed files>
```
Do **not** stage unrelated files or leftover debug edits.

### Commit Message Format
Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short imperative summary>

<optional body — what changed and why, wrapped at 72 chars>

<optional footer — BREAKING CHANGE: ..., Closes #NNN>
```

Rules:
- First line ≤ 72 characters
- Use imperative mood: "add", "fix", "bump", not "added", "fixed"
- Body is optional but recommended for non-trivial changes
- Reference issues in the footer: `Closes #123`
- **Never include a "Co-authored-by" trailer**

### Example Messages

```
feat(auth): add OAuth2 PKCE flow

Replaces the implicit grant with PKCE for improved security.
Token refresh is now handled transparently.

Closes #214
```

```
fix(api): return 404 when resource not found

Previously returned 500 due to unhandled None check.

Closes #301
```

```
chore: bump dependencies to latest patch versions
```

## Done Criteria
- [ ] All done-checks pass
- [ ] Changelog and version files updated
- [ ] Commit staged with a conventional message
- [ ] No "Co-authored-by" in the commit message
- [ ] Ready to push and open a PR
