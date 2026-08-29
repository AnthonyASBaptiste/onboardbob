# OnboardBob — Autonomous Repo Onboarding Engine
### IBM Bob 2.0 Dev Day Hackathon Submission

---

## The Problem: Day 1 Costs You a Full Day

A contractor clones a production microservices repo at 9 AM.
By 10 AM they're still not running locally.

The blocker isn't the code — it's three things the README doesn't know:

1. **Missing env vars** — the `.env.example` hasn't been updated since Redis was added
2. **Wrong Node version** — the repo now requires Node 22, the README says 18
3. **Unknown boot order** — `api` needs the `worker` service up first; nobody wrote that down

This is the #1 Day 1 blocker for every new hire, contractor, and open-source contributor.
It's solvable. It just requires reading the codebase, not the README.

---

## The Solution: One Command, Full Picture

You type one thing:

```
/onboard
```

Bob fans out three specialized subagents in parallel, each auditing a different
dimension of the repo simultaneously:

```
                    Bob (Orchestrator)
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
   [Subagent 1]    [Subagent 2]    [Subagent 3]
   Env Auditor    Repo Mapper     Runtime Check
   (general)      (explore)       (general)
          │              │              │
          └──────────────┼──────────────┘
                         ▼
              .bob/env-audit.md
              .bob/arch-map.md
              .bob/prereq-report.md
                         │
                         ▼
                  ONBOARDING.md
              + ask_followup_question
              → Fast-Track or Ramp-Up
```

Each subagent writes a structured intermediate file. The orchestrator reads
all three, merges them, and delivers a tailored brief — in under 60 seconds.

---

## What Each Agent Actually Does

### Subagent 1 — Env & Config Auditor (`general`)

Scans every source file for environment variable references:
- `process.env.FOO` / `process.env['FOO']` / `const { FOO } = process.env`
- `os.environ.get('FOO')` / `os.environ['FOO']`
- `os.Getenv("FOO")` / `viper.GetString("FOO")`

Diffs discovered variables against `.env.example`.

If `.env.example` is missing or stale:
- Shows the exact diff (`+ REDIS_URL=... # used by worker/queue.ts:14`)
- Asks for approval
- Patches or creates the file

Writes findings to `.bob/env-audit.md`.

### Subagent 2 — Repo Shape Mapper (`explore`)

Uses `glob` to find entry points (`main.*`, `index.*`, `app.*`, `cmd/*/main.go`).
Runs `GetSymbolsOverview` on each. Maps service boundaries and shared modules.
Identifies DB schema files (migrations, ORM models).

Produces a topology table: service → start command → port → dependencies.
Writes to `.bob/arch-map.md`.

### Subagent 3 — Runtime & Prereq Checker (`general`)

Reads `package.json`, `Makefile`, `Dockerfile`, `docker-compose.yml` for the
correct boot sequence. Runs `node --version`, `python3 --version`, `go version`,
`docker --version`, `docker info` via `execute_command`.

Reports: what's installed, what's missing, what version mismatches exist.
Writes to `.bob/prereq-report.md`.

---

## The Output: Two Paths, Zero Guesswork

After fan-in, Bob asks once:

> "Mapped: 3 services, 2 missing env vars, 1 version mismatch.
> Fast brief (architecture + exact commands) or step-by-step ramp-up?"

### Fast-Track Brief (senior / polyglot dev)

```markdown
# Repo Brief — api-platform · 3 services · Node 22 / Python 3.12

## Entry Points
| Service  | Command               | Port | Depends on        |
|----------|-----------------------|------|-------------------|
| api      | npm run dev           | 3001 | postgres, redis   |
| worker   | python worker/main.py | —    | redis             |
| dashboard| npm run dev -w dash   | 3000 | api               |

## Missing Before You Can Run
| Variable        | Used in              | Status    |
|-----------------|----------------------|-----------|
| REDIS_URL       | worker/queue.ts:14   | ⚠️ missing |
| OPENAI_API_KEY  | api/src/llm.ts:7     | ⚠️ missing |

## Exact Boot Sequence
docker compose up -d postgres redis
cp .env.example .env && nano .env   # fill 2 missing vars
npm install && npm run dev

## Non-Obvious Things
- api must start before worker (worker polls api/health before processing)
- DB migrations run automatically on api startup — don't run them manually
- auth.ts:47 — JWT validation is custom, not a library; secret rotates weekly

---
**Next:** fill .env, then `docker compose up -d && npm run dev`
```

### Interactive Ramp-Up (junior / first-timer)

Step-by-step, gated on confirmation. Bob verifies each step succeeded
via `execute_command` before proceeding:

```
Step 1/4 — Prerequisites  [Bob checks automatically, reports pass/fail]
Step 2/4 — Environment    [Shows diff, asks approval, writes .env.local]
Step 3/4 — Bootstrap      [Runs npm install, captures exit code, fixes errors]
Step 4/4 — Smoke Test     [Starts the app, confirms port is listening]
```

Bob never advances without the developer's "done" — no junior dev left behind.

---

## Live Demo Scenario (48 hours)

**Setup:** The demo-repo in this project is purpose-built with controlled breakage.
Do not demo against a random public repo — variance kills live demos.

**Known breakage in `demo-repo/`:**
- `.env.example` is missing `REDIS_URL` and `OPENAI_API_KEY` (referenced in 4 source files)
- `.nvmrc` says Node 22, `README.md` says Node 18
- `docker-compose.yml` has `worker` depending on `api` — nowhere in the README

**The 60-second demo script (money shot at 0:35):**

| Clock | What the judge sees |
|-------|---------------------|
| 0:00 | Bob opens on `demo-repo/`. Developer types `/onboard`. |
| 0:05 | Three subagents spawn. Activity feed shows parallel fan-out. |
| 0:25 | All three complete. Bob outputs 4 lines: "3 services, 2 missing env vars, 1 version mismatch." |
| 0:30 | Bob asks: "Fast brief or interactive ramp-up?" Developer picks fast brief. |
| **0:35** | **MONEY SHOT:** Full brief appears. `REDIS_URL` and `OPENAI_API_KEY` both flagged ⚠️ with exact file:line. Boot sequence is the correct 4-step sequence from docker-compose. |
| 0:45 | Bob asks: "Patch `.env.example`? Here's the diff." Shows `+` lines with file:line context. |
| 0:50 | Developer approves. File patched. |
| 0:55 | Developer runs the exact boot sequence shown. App starts. |

**Total time from `/onboard` to running: under 60 seconds.**
Previous baseline: 2+ hours of README archaeology and Slack messages.

**What to say at 0:35:** *"Bob read 4 source files, found both missing variables with exact line numbers,
extracted the correct boot order from docker-compose, and flagged the Node version mismatch —
all before I'd finished reading the README."*

---

## Bob 2.0 Capabilities Demonstrated

| Capability | Where used |
|---|---|
| **Agent Mode** | Full autonomous orchestration — no hand-holding |
| **Parallel Subagents** | Three `spawn_subagent` calls in one turn; run concurrently |
| **`general` subagent** | Agents 1 + 3: need `write_file` + `execute_command` |
| **`explore` subagent** | Agent 2: read-only architecture scan |
| **Document Understanding** | `GetSymbolsOverview`, `FindSymbol`, `grep` across the codebase |
| **Bob Shell** | `execute_command` for version checks and bootstrap verification |
| **Plan Mode gate** | `ask_followup_question` for track selection and env patch approval |
| **Structured file I/O** | Intermediate `.bob/*.md` files as machine-readable channels |

---

## Why This Wins

**Problem → Solution → Demo is a straight line.**
Judges can feel the pain (who hasn't wasted a day on a broken clone?),
watch the fix happen live in under a minute, and understand exactly
what Bob 2.0 did that a README or Copilot chat couldn't.

**It's a complete workflow, not a feature.**
Env audit → arch map → prereq check → tailored brief → optional walkthrough.
Every step is autonomous. Bob drives. The developer approves, then runs.

**The output keeps working after the demo.**
`ONBOARDING.md` stays in the repo. Install the CI drift checker
(`bash .bob/hooks/post-push.sh --install`) and every push automatically
checks for new env vars that haven't been documented — before the next
person clones and hits Day 1 breakage.

---

## Installation (One Command)

```bash
# Installs globally — works in every repo you open
curl -fsSL https://onboardbob.dev/install.sh | bash
# → writes ~/.bob/skills/onboard/SKILL.md
# → writes ~/.bob/commands/onboard.md
```

Then from any repo directory in Bob:

```
/onboard
```

That's it.
