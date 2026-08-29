#!/usr/bin/env bash
set -e

# OnboardBob — Global Installer
# Installs the /onboard skill and command globally so it works in every
# Bob workspace without per-repo configuration.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/your-repo/onboardbob/main/install.sh | bash
#   OR:
#   ./install.sh

SKILL_DIR="$HOME/.bob/skills/onboard"
COMMAND_DIR="$HOME/.bob/commands"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing OnboardBob..."

# Create directories
mkdir -p "$SKILL_DIR"
mkdir -p "$COMMAND_DIR"

# Copy skill file
if [ -f "$SCRIPT_DIR/skills/onboard/SKILL.md" ]; then
  cp "$SCRIPT_DIR/skills/onboard/SKILL.md" "$SKILL_DIR/SKILL.md"
  echo "  ✅ Skill installed: $SKILL_DIR/SKILL.md"
else
  echo "  ❌ Error: skills/onboard/SKILL.md not found in $SCRIPT_DIR"
  exit 1
fi

# Copy command file
if [ -f "$SCRIPT_DIR/commands/onboard.md" ]; then
  cp "$SCRIPT_DIR/commands/onboard.md" "$COMMAND_DIR/onboard.md"
  echo "  ✅ Command installed: $COMMAND_DIR/onboard.md"
else
  echo "  ❌ Error: commands/onboard.md not found in $SCRIPT_DIR"
  exit 1
fi

echo ""
echo "OnboardBob installed."
echo ""
echo "Usage:"
echo "  1. Open Bob in any repo directory"
echo "  2. Type: /onboard"
echo ""
echo "For a specific subdirectory (monorepo):"
echo "  /onboard packages/auth-service"
