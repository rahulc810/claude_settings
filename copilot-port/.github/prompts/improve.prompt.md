---
mode: agent
description: 'Scan code against four architecture checks — layout, isolation, interface strength, extensibility — and propose specific fixes without applying them.'
tools: ['codebase', 'search', 'changes']
---
# Improve Architecture

Reach for it when a file keeps getting harder to touch. For a specific diff or plan use
`/code-review`; to apply routine cleanups use `/simplify` (if you have it).

Good code comes down to four things. Check candidates against these, in order — each one tends
to cause problems in the ones below it.
1. **Simple layout** — can you find things? Directory and file structure should map obviously
   to what's in them, no hunting.
2. **Isolation** — similar things live as separate, isolated workers, not entangled. Shared
   code lives in one obvious shared place, not duplicated or reached-into.
3. **Strong interfaces** — a module's public surface fully covers what callers need, so nobody
   reaches into internals or leaks details out.
4. **Simple (not easy) to extend** — adding a new case fits the existing shape without
   special-casing or touching a pile of unrelated files.

Tests and performance aren't separate checks — they tend to follow once these four hold.

## When to use this
When a file keeps showing up in recent changes and each change feels harder than it should, or
when asked directly to find refactoring opportunities. Skip for a codebase small enough to
hold in your head, or when nothing's actually hurting yet.

## Steps
1. **Find the hot spots.** If the user named a file or area, use that. Otherwise check
   `git log --oneline` over a reasonable stretch for files that keep recurring.
2. **Read the candidate against the four checks, in order.** Stop at the first one actually
   broken — a layout problem often manifests as an interface problem downstream; fix the
   upstream cause.
3. **Propose 1-2 concrete fixes, not a list of vague concerns.** Name the check it fails, what
   changes, what gets simpler as a result. If you can't describe the fix concretely, keep
   reading.
4. **Let the user pick.** Present candidates plainly (file, which check fails, proposed fix)
   and stop. Don't refactor unprompted.

## What not to do
- Don't produce more than a couple of candidates — if everything looks broken, narrow scope.
- Don't refactor speculatively for code nobody's touched recently or complained about.
- Don't chase tests or performance directly here.
