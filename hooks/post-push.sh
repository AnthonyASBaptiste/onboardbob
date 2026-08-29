#!/usr/bin/env bash
# OnboardBob — CI Drift Checker
#
# Checks whether .env.example is in sync with the env vars referenced in code.
# Run this on push or in CI to catch drift before it becomes a Day 1 blocker.
#
# Usage:
#   ./post-push.sh             — run drift check now
#   ./post-push.sh --install   — install as a git post-push hook
#   ./post-push.sh --ci        — run in CI mode (non-zero exit on drift found)
#
# Requirements: IBM Bob CLI (bob) with API key auth for non-interactive mode.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="check"

for arg in "$@"; do
  case "$arg" in
    --install) MODE="install" ;;
    --ci)      MODE="ci" ;;
  esac
done

# ── Install mode: write the git hook ────────────────────────────────────────
if [ "$MODE" = "install" ]; then
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$GIT_ROOT" ]; then
    echo "Error: not inside a git repository" >&2
    exit 1
  fi

  # Copy this script into the target repo so the git hook can find it
  DEST_HOOKS="$GIT_ROOT/.bob/hooks"
  mkdir -p "$DEST_HOOKS"
  cp "$SCRIPT_DIR/post-push.sh" "$DEST_HOOKS/post-push.sh"
  chmod +x "$DEST_HOOKS/post-push.sh"

  HOOK_FILE="$GIT_ROOT/.git/hooks/post-push"
  cat > "$HOOK_FILE" << 'HOOK'
#!/usr/bin/env bash
# OnboardBob drift check — installed by: bash .bob/hooks/post-push.sh --install
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
HOOK_SCRIPT="$REPO_ROOT/.bob/hooks/post-push.sh"
if [ -f "$HOOK_SCRIPT" ]; then
  bash "$HOOK_SCRIPT" --ci 2>/dev/null || true  # non-blocking: log but don't fail push
fi
HOOK
  chmod +x "$HOOK_FILE"
  echo "✅ OnboardBob drift check installed at .git/hooks/post-push"
  echo "   Script copied to: .bob/hooks/post-push.sh"
  echo "   It runs automatically on every git push."
  echo "   To run manually: bash .bob/hooks/post-push.sh"
  exit 0
fi

# ── Check / CI mode: run bob ─────────────────────────────────────────────────

# Verify bob CLI is available
if ! command -v bob >/dev/null 2>&1; then
  echo "⚠️  OnboardBob drift check skipped: 'bob' CLI not found in PATH" >&2
  echo "   Install IBM Bob and set up API key auth to enable drift checking." >&2
  exit 0
fi

REPORT_FILE=".bob/drift-report.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "🔍 OnboardBob drift check — $TIMESTAMP"

# Run bob in non-interactive mode with a targeted drift check prompt
bob --hide-intermediary-output -p "
You are running a quick OnboardBob drift check.

TASK: Compare environment variable references in the codebase against .env.example.
Only report NEW gaps — variables present in code but missing from .env.example.

Steps:
1. grep for process\.env\.[A-Z_]+ and os\.environ in all .ts, .js, .py, .go files
2. read_file('.env.example')
3. Compare — list only variables in code but NOT in .env.example
4. Write a short report to $REPORT_FILE:
   - If no drift: write 'DRIFT: none' and a timestamp
   - If drift found: list each missing variable with the file:line it was found in

Keep the report under 30 lines. Do not patch any files — report only.
" 2>/dev/null

# Parse the result
if [ -f "$REPORT_FILE" ]; then
  if grep -q "DRIFT: none" "$REPORT_FILE" 2>/dev/null; then
    echo "✅ No .env drift detected."
    exit 0
  else
    echo "⚠️  .env drift detected — new variables found in code but missing from .env.example:"
    cat "$REPORT_FILE"
    echo ""
    echo "   Run '/onboard' in Bob to patch .env.example automatically."

    if [ "$MODE" = "ci" ]; then
      # In CI mode: exit non-zero so the pipeline can flag it (optional — teams
      # can choose to treat drift as a warning rather than a failure)
      exit 1
    fi
  fi
else
  echo "⚠️  Drift check did not produce a report. Check bob CLI output." >&2
fi
