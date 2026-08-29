# OnboardBob

**Autonomous Repo Cartography & Onboarding Copilot**
Built for IBM Bob 2.0 Dev Day Hackathon · August 2026

---

## Security: Poisoned Repo Protection

OnboardBob reads files from repos you may not own or fully trust. Attackers
can and do embed instructions in source files, READMEs, and comments
specifically designed to hijack AI agents — this attack class is called
**prompt injection via repository content**.

OnboardBob defends against it at three layers:

1. **Orchestrator rule** — The SKILL.md begins with an explicit
   anti-manipulation block that takes precedence over all file content.
   Any instruction found inside a repo file is treated as data only.

2. **Per-subagent rule** — Every spawned subagent description opens with a
   SECURITY RULE that repeats the same constraint in isolated context.
   Each subagent cannot be manipulated by file content even if the
   orchestrator somehow was.

3. **No verbatim execution** — Boot sequences, Makefile targets, and
   `package.json` scripts are extracted and *displayed* to the developer.
   Bob never executes a command whose text came directly from a repo file.

**What this does NOT cover:**
- Repos that contain malicious *code* which executes when you `npm install`
  or `pip install` (supply chain attack — use a sandbox for untrusted installs)
- Repos that serve a fake web service that responds to health checks with
  malicious content
- Social engineering: a repo README that tricks *you* (not Bob) into running
  a harmful command

**Recommendation for untrusted repos:** Run OnboardBob in a VM or container
with no access to your real credentials, SSH keys, or cloud accounts. Never
run `npm install` or `pip install` from an untrusted repo on your host machine.

---

## What it does

You point Bob at any codebase and type `/onboard`.

Three specialized subagents fan out in parallel:
- **Env Auditor** — scans every source file for env var references, diffs against `.env.example`, proposes a patch
- **Repo Mapper** — maps entry points, service topology, and shared modules
- **Runtime Checker** — verifies your local toolchain and extracts the exact boot sequence

Bob synthesizes the results and asks: **fast brief** (architecture map + exact commands) or **interactive ramp-up** (step-by-step verified setup)?

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/onboardbob/main/install.sh | bash
```

Or manually copy:
```bash
cp skills/onboard/SKILL.md ~/.bob/skills/onboard/SKILL.md
cp commands/onboard.md ~/.bob/commands/onboard.md
```

---

## Usage

Open Bob in any repo directory:

```
/onboard
```

For a specific subdirectory (monorepo):
```
/onboard packages/auth-service
```

---

## Project Structure

```
onboardbob/
├── PITCH.md                    # Competition submission pitch
├── README.md                   # This file
├── install.sh                  # One-line global installer
├── skills/
│   └── onboard/
│       └── SKILL.md            # Main Bob skill (the orchestrator)
├── commands/
│   └── onboard.md              # Slash command entry point
├── agents/
│   ├── env-auditor.md          # Subagent 1 prompt (Env & Config)
│   ├── repo-mapper.md          # Subagent 2 prompt (Architecture)
│   └── runtime-checker.md      # Subagent 3 prompt (Runtime)
├── templates/
│   ├── fast-track-brief.md     # Output template: senior dev brief
│   └── ramp-up.md              # Output template: step-by-step walkthrough
└── demo-repo/                  # Controlled broken repo for live demo
    ├── README.md
    ├── package.json
    ├── .env.example            # INTENTIONALLY INCOMPLETE
    ├── docker-compose.yml
    ├── api/
    ├── worker/
    └── dashboard/
```

---

## How it works (technical)

Bob 2.0's `spawn_subagent` runs multiple agents concurrently when called in the same turn. Each agent type is chosen deliberately:

| Agent | Type | Why |
|---|---|---|
| Env Auditor | `general` | Needs `write_file` to patch `.env.example` |
| Repo Mapper | `explore` | Read-only; lighter model, pure codebase scan |
| Runtime Checker | `general` | Needs `execute_command` to check tool versions |

Each subagent writes a structured intermediate file to `.bob/`:
```
.bob/env-audit.md       → env var findings, diff proposal
.bob/arch-map.md        → topology, entry points, service matrix
.bob/prereq-report.md   → installed tools, version mismatches, boot sequence
```

The orchestrator reads all three with `read_file` and synthesizes `ONBOARDING.md`.

This avoids relying on natural-language summaries as a data channel — a known limitation of Bob's subagent model where `.summary` is prose, not structured data.

---

## Demo

See [`demo-repo/`](demo-repo/) for the controlled broken repo used in the live demo.

Known breakage:
- `.env.example` missing `REDIS_URL` and `OPENAI_API_KEY`  
- `.nvmrc` says Node 22, `README.md` says Node 18
- `worker` boot dependency on `api` undocumented

Expected OnboardBob output: detects all three issues, patches `.env.example` with approval, delivers exact boot sequence.
