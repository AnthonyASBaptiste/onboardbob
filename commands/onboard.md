# /onboard

Runs the OnboardBob autonomous repo onboarding skill.

## Usage

```
/onboard [subpath]
```

- With no argument: audits the entire workspace root
- With a path: audits that subdirectory (useful for monorepos)

## Examples

```
/onboard
/onboard packages/auth-service
/onboard services/api
```

## What it does

Fans out three parallel subagents to:
1. Audit environment variable gaps (compares code vs `.env.example`)
2. Map the repo architecture (entry points, service topology, dependencies)
3. Check your local prerequisites (tool versions, docker status, boot sequence)

Synthesizes results into `ONBOARDING.md` and offers:
- **Fast brief** — architecture map, missing vars, exact run commands
- **Step-by-step ramp-up** — verified setup walkthrough with Bob checking each step

## Skill

See `~/.bob/skills/onboard/SKILL.md` for the full orchestration logic.
