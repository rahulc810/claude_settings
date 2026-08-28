---
name: code-review
description: "Review code for logical correctness, coding standards, and plan/spec adherence. Use when asked to review, audit, or check an implementation — especially before merging or landing. Trigger on: review this, check my code, does this match the plan, audit."
argument-hint: "File, folder, or plan to review against"
tools: [Read, Grep, Glob, Bash]
---

# Code Review

Review code on three axes together: **logical correctness**, **coding standards**, and **plan adherence** (when a spec or plan is provided). Report findings bucketed by severity. Do not fix anything.

## When to Use
- Before landing or merging code
- To check whether an implementation matches its plan or spec
- To audit code for correctness or standards violations

## Procedure

1. **Establish scope.** Identify what to review — a file, a folder, a diff, or everything a named plan describes. If scope is ambiguous, ask once rather than guessing.

2. **Read the plan or spec first** (if provided). Note every stated requirement, constraint, and decision. This is the correctness baseline.

3. **Survey the code.** Read the relevant files in full. Run linters or the test suite if available (`Bash`) to surface objective failures before manual review.

4. **Review all three axes per file:**
   - **Logical correctness** — does the code do what it claims? Look for off-by-ones, null/error paths, incorrect branching, data races, and misused APIs.
   - **Coding standards** — does it follow the conventions used elsewhere in the codebase, plus any org-specific rules you've been given? Check naming, structure, error handling style, and test coverage for changed logic.
   - **Plan adherence** — does each deliverable from the spec exist and behave as described? Flag both deviations (code does something the plan didn't say) and gaps (plan said to do something the code doesn't).

5. **Bucket every finding:**
   - **Blocking** — must be fixed before landing: bugs, security issues, missing required behaviour, plan deviations that change the contract
   - **Should-fix** — real problems, not launch-blocking
   - **Nit** — style or naming preferences; don't inflate to Should-fix

6. **Report findings in chat.** For each finding include: location (file:line), what is wrong, why it matters, and a suggested fix. Lead with the count by severity, then list Blocking items in full. Keep Nits brief.

## Constraints
- Do NOT fix anything — report only
- Do NOT invent a plan if none was given — review for correctness and standards only, and say so
- Do NOT inflate severity to appear thorough; do NOT bury real issues under nits
- Do NOT assume code is correct because tests pass — tests may be incomplete

## Flagging Format

When scope or a plan reference is unclear, stop and say:

> **FLAG:** [what is unclear]
> **Options:** [A] … [B] … or [ask user]
> **Waiting for:** your decision before proceeding

## Done Criteria
- All files in scope reviewed on all applicable axes
- Every finding bucketed and reported with location and suggested fix
- Summary counts given at the top of the report
