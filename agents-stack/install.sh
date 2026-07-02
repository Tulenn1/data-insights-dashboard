#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Subagent Stack Installer
# Installs agent configs for opencode, Claude Code, or both
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$SCRIPT_DIR"
MODELS_FILE="$SRC_DIR/models.json"
INSTALL_AGENTS_FILE="$SRC_DIR/AGENTS.md"

TARGET=""
TARGET_EXPLICIT=0
BDD_LANG="en"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${CYAN}[→]${NC} $1"; }

usage() {
  cat <<'EOF'
Usage: ./install.sh [--target opencode|claude|both] [--spec-lang <code>]

Targets:
  opencode      Install .opencode assets and merge opencode.json
  claude        Install .claude assets only
  both          Install both sets (default)
  --spec-lang   Pipeline language code (e.g., en, es, fr, de, pt).
                 Controls all agent communication and generated content.
                 Default: en.
EOF
}

normalize_target() {
  case "${1:-}" in
    opencode|claude|both) printf '%s' "$1" ;;
    *) return 1 ;;
  esac
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -t|--target)
        [ $# -ge 2 ] || { err "Missing value for $1"; exit 1; }
        TARGET="$2"
        TARGET_EXPLICIT=1
        shift 2
        ;;
      --opencode)
        TARGET="opencode"
        TARGET_EXPLICIT=1
        shift
        ;;
      --claude)
        TARGET="claude"
        TARGET_EXPLICIT=1
        shift
        ;;
      --both)
        TARGET="both"
        TARGET_EXPLICIT=1
        shift
        ;;
      --spec-lang)
        [ $# -ge 2 ] || { err "Missing value for $1"; exit 1; }
        BDD_LANG="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

prompt_target() {
  info "Select installation target:"
  select choice in opencode claude both; do
    if [ -n "$choice" ]; then
      TARGET="$choice"
      break
    fi
  done
}

# ---------------------------------------------------------------------------
# Parse models.json using python3
# ---------------------------------------------------------------------------
get_model() {
  local tool="$1" agent="$2"
  python3 -c "
import json, sys
with open('$MODELS_FILE') as f:
    data = json.load(f)
print(data.get('$tool', {}).get('$agent', ''))
"
}

# ---------------------------------------------------------------------------
# Create directory and clean existing symlinks/copies
# ---------------------------------------------------------------------------
prepare_dir() {
  local dir="$1"
  mkdir -p "$dir"
}

# ---------------------------------------------------------------------------
# Install agent for opencode (symlink)
# ---------------------------------------------------------------------------
install_project_agents_file() {
  local src="$INSTALL_AGENTS_FILE"
  local dst="$PROJECT_ROOT/AGENTS.md"

  [ -f "$src" ] || { err "Source not found: $src"; return 1; }

  cp -f "$src" "$dst"
  log "project AGENTS:  $dst"
}

# ---------------------------------------------------------------------------
# Install agent for opencode (symlink)
# ---------------------------------------------------------------------------
install_opencode_agent() {
  local agent_name="$1"
  local src="$SRC_DIR/agents/${agent_name}.md"
  local dst="$PROJECT_ROOT/.opencode/agents/${agent_name}.md"

  [ -f "$src" ] || { err "Source not found: $src"; return 1; }

  prepare_dir "$(dirname "$dst")"
  ln -sf "$src" "$dst"
  log "opencode agent: ${agent_name} → .opencode/agents/${agent_name}.md"
}

# ---------------------------------------------------------------------------
# Install agent for Claude Code (copy with model injected)
# ---------------------------------------------------------------------------
install_claude_agent() {
  local agent_name="$1"
  local src="$SRC_DIR/agents/${agent_name}.md"
  local dst="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  local model
  model=$(get_model "claude" "$agent_name")

  [ -f "$src" ] || { err "Source not found: $src"; return 1; }

  prepare_dir "$(dirname "$dst")"

  if [ -n "$model" ]; then
    # Inject model line after 'description:' line in frontmatter
    awk -v model="$model" '
      BEGIN { injected = 0 }
      /^description:/ && !injected {
        print
        print "model: " model
        injected = 1
        next
      }
      { print }
    ' "$src" > "$dst"
    log "claude agent:   ${agent_name} → .claude/agents/${agent_name}.md  (model: ${model})"
  else
    cp "$src" "$dst"
    log "claude agent:   ${agent_name} → .claude/agents/${agent_name}.md  (model: inherit)"
  fi
}

# ---------------------------------------------------------------------------
# Install commands for a single target
# ---------------------------------------------------------------------------
install_commands_for_target() {
  local target="$1"
  local cmd_name="$2"
  local src="$SRC_DIR/commands/${cmd_name}.md"
  local dst_root="$PROJECT_ROOT/.$target/commands/${cmd_name}.md"

  [ -f "$src" ] || { err "Source not found: $src"; return 1; }

  prepare_dir "$(dirname "$dst_root")"

  ln -sf "$src" "$dst_root"
  log "command:        ${cmd_name} → .$target/commands/"
}

# ---------------------------------------------------------------------------
# Install skills for a single target
# ---------------------------------------------------------------------------
install_skills_for_target() {
  local target="$1"
  local skill_name="$2"
  local src="$SRC_DIR/skills/${skill_name}/SKILL.md"
  local dst_root="$PROJECT_ROOT/.$target/skills/${skill_name}/SKILL.md"

  [ -f "$src" ] || { err "Source not found: $src"; return 1; }

  prepare_dir "$(dirname "$dst_root")"

  ln -sf "$src" "$dst_root"
  log "skill:          ${skill_name} → .$target/skills/"
}

# ---------------------------------------------------------------------------
# Merge opencode.json directly
# ---------------------------------------------------------------------------
merge_opencode_config() {
  local config_file="$PROJECT_ROOT/opencode.json"

  python3 - "$config_file" "$MODELS_FILE" <<'PY'
import json
import pathlib
import re
import sys

config_path = pathlib.Path(sys.argv[1])
models_path = pathlib.Path(sys.argv[2])

def strip_jsonc(text: str) -> str:
    out = []
    i = 0
    in_string = False
    escape = False
    line_comment = False
    block_comment = False

    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""

        if line_comment:
            if ch in "\r\n":
                line_comment = False
                out.append(ch)
            i += 1
            continue

        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
            else:
                i += 1
            continue

        if in_string:
            out.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
            continue

        if ch == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue

        if ch == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue

        out.append(ch)
        i += 1

    text = "".join(out)
    text = re.sub(r",(?=\s*[}\]])", "", text)
    return text


def load_config(path: pathlib.Path) -> dict:
    if not path.exists():
        return {}

    raw = path.read_text()
    try:
        data = json.loads(raw)
    except Exception:
        data = json.loads(strip_jsonc(raw))

    if not isinstance(data, dict):
        raise SystemExit(f"{path} must contain a JSON object")

    return data


models = json.loads(models_path.read_text())
opencode_models = models.get("opencode", {})
agent = {}

for name in ("planner", "task-splitter", "task-archiver", "implementer", "validator", "fixer", "pr-creator", "spec-writer", "batch-implementer", "readme-generator", "context-generator", "reference-extractor"):
    model = opencode_models.get(name, "")
    if model:
        agent[name] = {"model": model, "mode": "subagent"}

data = load_config(config_path)
if "$schema" not in data:
    data = {"$schema": "https://opencode.ai/config.json", **data}

existing_agent = data.get("agent", {})
if existing_agent and not isinstance(existing_agent, dict):
    raise SystemExit(f"{config_path} agent section must be an object")

# Start fresh from the current models.json — don't preserve obsolete entries
merged_agent = dict(agent)
# But preserve any existing agent configs for agents NOT in models.json
# (user may have manually added custom agents)
for k, v in existing_agent.items():
    if k not in merged_agent:
        merged_agent[k] = v
data["agent"] = merged_agent

config_path.write_text(json.dumps(data, indent=2) + "\n")
PY

  log "opencode config: $config_file"
}

# ============================================================================
# Main
# ============================================================================

parse_args "$@"

if [ -z "$TARGET" ]; then
  if [ -t 0 ] && [ "$TARGET_EXPLICIT" -eq 0 ]; then
    prompt_target
  else
    TARGET="both"
  fi
fi

TARGET="$(normalize_target "$TARGET")" || {
  err "Invalid target: $TARGET"
  usage
  exit 1
}

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Subagent Stack Installer${NC}"
echo -e "${CYAN}  Target: ${TARGET}${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

[ -f "$MODELS_FILE" ] || { err "models.json not found at $MODELS_FILE"; exit 1; }
[ -f "$INSTALL_AGENTS_FILE" ] || { err "AGENTS.md not found at $INSTALL_AGENTS_FILE"; exit 1; }

install_project_agents_file

# Internal tools (not auto-installed): manifest-generator, sync-agents
# --- Agents ---
echo ""
case "$TARGET" in
  opencode)
    info "Installing opencode assets..."
    for agent in planner task-splitter task-archiver implementer validator fixer pr-creator spec-writer batch-implementer readme-generator context-generator reference-extractor; do
      install_opencode_agent "$agent"
    done
    echo ""
    info "Merging opencode config..."
    merge_opencode_config
    ;;
  claude)
    info "Installing Claude Code assets..."
    for agent in planner task-splitter task-archiver implementer validator fixer pr-creator spec-writer batch-implementer readme-generator context-generator reference-extractor; do
      install_claude_agent "$agent"
    done
    ;;
  both)
    info "Installing opencode assets..."
    for agent in planner task-splitter task-archiver implementer validator fixer pr-creator spec-writer batch-implementer readme-generator context-generator reference-extractor; do
      install_opencode_agent "$agent"
    done
    echo ""
    info "Merging opencode config..."
    merge_opencode_config
    echo ""
    info "Installing Claude Code assets..."
    for agent in planner task-splitter task-archiver implementer validator fixer pr-creator spec-writer batch-implementer readme-generator context-generator reference-extractor; do
      install_claude_agent "$agent"
    done
    ;;
esac

# --- Commands ---
echo ""
info "Installing slash commands..."
case "$TARGET" in
  opencode) command_targets=(opencode) ;;
  claude) command_targets=(claude) ;;
  both) command_targets=(opencode claude) ;;
esac
for cmd in planner tasks implement validate fix pr-ready spec implement-all plan-extend readme context reference archive; do
  for runtime_target in "${command_targets[@]}"; do
    install_commands_for_target "$runtime_target" "$cmd"
  done
done

# --- Skills ---
echo ""
info "Installing skills..."
case "$TARGET" in
  opencode) skill_targets=(opencode) ;;
  claude) skill_targets=(claude) ;;
  both) skill_targets=(opencode claude) ;;
esac
for skill_dir in "$SRC_DIR"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  [ "$skill_name" = "_template" ] && continue
  [ -f "$skill_dir/SKILL.md" ] || continue
  for runtime_target in "${skill_targets[@]}"; do
    install_skills_for_target "$runtime_target" "$skill_name"
  done
done

# --- Spec language configuration ---
echo ""
info "Configuring pipeline language..."
mkdir -p "$PROJECT_ROOT/docs/pipeline/features"
if [ -t 0 ] && [ "$BDD_LANG" = "en" ] && ! echo "$*" | grep -q -- --spec-lang; then
  echo ""
  read -p "Pipeline language [en]: " user_lang
  BDD_LANG="${user_lang:-en}"
fi
echo "{\"lang\": \"$BDD_LANG\", \"version\": 1}" > "$PROJECT_ROOT/docs/pipeline/features/.specconfig"
log "Pipeline language: $BDD_LANG → docs/pipeline/features/.specconfig"

# --- Final instructions ---
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Installed to project root: AGENTS.md"
case "$TARGET" in
  opencode)
    echo "Installed: .opencode/, opencode.json"
    ;;
  claude)
    echo "Installed: .claude/"
    ;;
  both)
    echo "Installed: .opencode/, .claude/, opencode.json"
    ;;
esac
echo "Pipeline language: $BDD_LANG"
echo ""
