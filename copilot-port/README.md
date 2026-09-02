# copilot-port

15 Claude Code skills ported to GitHub Copilot **prompt files** for the work machine.

## Skills included
diagnose, bug-echo, improve, crawl, plan-doc, prototype, tldr, distill, grill,
code-review, finalize, resolve-review, implement, forge, designit

## Getting them onto the work machine (no file transfer)

### Option A — Copilot fetches it (preferred)
1. Make sure this repo is **public** (or copy `BOOTSTRAP.md` into a public gist).
2. On the work machine, VS Code Copilot Chat (agent mode):
   ```
   #fetch https://raw.githubusercontent.com/<user>/<repo>/master/copilot-port/BOOTSTRAP.md
   Follow the instructions in that file.
   ```
3. Copilot writes all 15 `.github/prompts/*.prompt.md` files into the open workspace.

### Option B — browser paste
Open `copilot-port/BOOTSTRAP.md` on github.com, copy the whole rendered doc, paste into
Copilot Chat with "follow this".

### Option C — hand-type
Each file is small. `BOOTSTRAP.md` has every one inline with its target path.

## Using them
Type `/diagnose`, `/crawl`, `/code-review full`, etc. in Copilot Chat. Prompt files with
`${input:...}` will ask for the argument or accept it after the slash command.

## Notes on the port
- `model:` frontmatter dropped (Copilot model names differ — set per-request).
- `allowed-tools` mapped to Copilot tool sets (`codebase`, `search`, `editFiles`,
  `runCommands`, `runTests`, `changes`, `problems`).
- Claude-Code-specific bits removed: mcp-erp tasks, SSH policy path, hard constitution
  dependency (now "if it exists").
- `forge` was about managing skills; repointed at `.github/prompts/` + `docs/prompt-ideas/`.
