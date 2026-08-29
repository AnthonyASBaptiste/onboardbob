# OnboardBob

**Autonomous Repo Cartography & Onboarding Copilot**  
Built for IBM Bob 2.0 Dev Day Hackathon · August 2026

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
