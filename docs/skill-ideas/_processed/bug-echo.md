After you fix a bug, it hunts the same pattern everywhere else in the codebase and rates each hit. It often surfaces sibling instances that stay hidden from ordinary audits, because an audit checks whether code is wrong on its own terms and has no reason to connect one file's defect to the same mistake three files away. Use case: I fixed a sheet that had no dismiss button on macOS. bug-echo found three more with the same gap. The bug you just fixed is rarely the only one of its kind. Daily. 

---
**/forge verdict (2026-08-29): ADD** as `skills/bug-echo/SKILL.md` (utility, post-fix). See `_assessments/2026-08-29.md`.
