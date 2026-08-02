# SSH policy

Skills that touch the server over SSH follow this rule:

- **Read-only commands** (inspecting logs, processes, config, resource usage, git state,
  service status) — run freely, no confirmation needed.
- **Anything that writes or changes state** (editing files, restarts, deploys, package
  installs, DB writes, deletes) — never run without explicit confirmation first. State
  the exact command(s), the expected effect, and any risk, then wait for a "yes" before
  executing.
- If unsure whether a command is read-only, treat it as a write and confirm.
- This applies per-command, not per-session — being told "yes, investigate" is not
  standing permission to also fix things found along the way.


  ## Targets

  - **server**: `DNS=fujitsu` , `ip: 192.168.1.115` `user: prisha`