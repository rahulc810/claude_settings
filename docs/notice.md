# Notice — scratch log for skill friction

One line per note: `- <date>: <what happened> → <what it might mean for a skill>`.
Skim it whenever you are touching skills anyway; delete each line once it is actioned
or judged dead.

<!-- 2026-08-01: cleared six actioned lines — the devkit-coupling of implement /
     land-feature / plan-doc (logged twice: vacbat, then erp), venv resolution, the
     `git add -A` sweep, return-shape assertions, and inherited-vs-regression test
     failures. All fixed in those three skills, which are now symlinked into
     ~/.claude/skills so they load outside devkit. -->

- 2026-08-02: diagnosing an HVAC unit "offline", I concluded the DHCP reservation was missing from the absence of its effect, without reading the erp dnsmasq config that governed it — user corrected me, the binding was there all along → diagnose could say: before blaming config for being absent, go read that config; absence of effect is not absence of cause.
- 2026-08-02: landing deebot from the devkit session, `git add -A` staged devkit — an earlier `cd` into the target repo had silently reverted to the primary working dir between Bash calls → land-feature (and any skill running git on a repo that is not the primary working dir) could say: pass `git -C <repo>` explicitly rather than relying on a persisted `cd`, and check the staged-path list names the repo you meant before committing.
- 2026-08-02: an ARP-vs-bindings comparison returned "absent" for all 16 rows because `ip neigh show dev X` drops a field my awk indexed on; I read the uniform result as a parsing bug, not a finding → diagnose could say: a derived table that comes back uniform (all-absent, all-zero, all-null) is a parser smoke test failing, not evidence — sanity-check the intermediate before interpreting it.
- 2026-08-02: auditing 146 sessions I reported "planit never fires, agents unused" — but every skill and agent dir was created 07-31/08-02, so a 30-day session history was being compared against 2-day-old tooling; user caught it → any skill that analyses history could say: check the mtime/creation date of the thing you are measuring before reading a zero as a signal — a zero over a window where the subject did not exist is not evidence.
- 2026-08-02: session audit found 49 user interruptions and 11 compactions across 146 sessions, concentrated where a bare nudge ("continue", "implement") opened a multi-file task → planit/implement could say: when the opening prompt is a bare nudge and no plan doc is in play, restate the intended scope in one line and start, rather than running long on an inferred scope.
