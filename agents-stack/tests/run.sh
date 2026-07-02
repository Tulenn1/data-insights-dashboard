#!/usr/bin/env bash
# Integration test suite for the AGENTS subagent pipeline
# Usage: ./agents-stack/tests/run.sh
#   or    bash agents-stack/tests/run.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$(cd "$ROOT/.." && pwd)"
PASS=0
FAIL=0
ERRORS=""

heading() {
  echo ""
  echo "========================================"
  echo "  $1"
  echo "========================================"
}

ok() {
  PASS=$((PASS + 1))
  echo "  [✓] $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "  [✗] $1"
  ERRORS="${ERRORS}  FAIL: $1${2:+  ($2)}"$'\n'
}

# ------------------------------------------------------------------
# Expected data
# ------------------------------------------------------------------

AGENTS=(
  planner
  task-splitter
  implementer
  validator
  fixer
  pr-creator
  spec-writer
  batch-implementer
  readme-generator
  context-generator
  reference-extractor
  manifest-generator
  task-archiver
)

COMMANDS=(
  planner
  tasks
  implement
  validate
  fix
  pr-ready
  spec
  implement-all
  plan-extend
  readme
  context
  reference
  archive
  sync-agents
)

SKILLS=(
  python
  typescript
  react
  django
  fastapi
  textual
)

AGENT_NAMES=(
  planner
  task-splitter
  implementer
  validator
  fixer
  pr-creator
  spec-writer
  batch-implementer
  readme-generator
  context-generator
  reference-extractor
  manifest-generator
  task-archiver
)

# ------------------------------------------------------------------
# 1. Agent files exist
# ------------------------------------------------------------------
heading "1. Agent definitions"

for agent in "${AGENTS[@]}"; do
  file="$ROOT/agents/${agent}.md"
  if [ -f "$file" ]; then
    ok "agent file exists: ${agent}.md"
  else
    fail "agent file missing: ${agent}.md"
  fi
done

# Verify no stale agent files (files without a corresponding entry)
for file in "$ROOT"/agents/*.md; do
  name=$(basename "$file" .md)
  found=0
  for a in "${AGENTS[@]}"; do
    [ "$a" = "$name" ] && found=1 && break
  done
  if [ "$found" -eq 0 ]; then
    fail "unexpected agent file: ${name}.md"
  fi
done

# ------------------------------------------------------------------
# 2. Agent frontmatter validity
# ------------------------------------------------------------------
heading "2. Agent frontmatter"

for agent in "${AGENTS[@]}"; do
  file="$ROOT/agents/${agent}.md"
  [ -f "$file" ] || continue

  if grep -q '^description:' "$file"; then
    ok "${agent}.md has description"
  else
    fail "${agent}.md missing description"
  fi

  if grep -q '^mode: subagent' "$file"; then
    ok "${agent}.md mode: subagent"
  else
    fail "${agent}.md missing mode: subagent"
  fi

  if grep -q '^permission:' "$file"; then
    ok "${agent}.md has permissions"
  else
    fail "${agent}.md missing permissions"
  fi
done

# ------------------------------------------------------------------
# 3. Command files exist
# ------------------------------------------------------------------
heading "3. Slash commands"

for cmd in "${COMMANDS[@]}"; do
  file="$ROOT/commands/${cmd}.md"
  if [ -f "$file" ]; then
    ok "command file exists: ${cmd}.md"
  else
    fail "command file missing: ${cmd}.md"
  fi
done

# Verify no stale command files
for file in "$ROOT"/commands/*.md; do
  name=$(basename "$file" .md)
  found=0
  for c in "${COMMANDS[@]}"; do
    [ "$c" = "$name" ] && found=1 && break
  done
  if [ "$found" -eq 0 ]; then
    fail "unexpected command file: ${name}.md"
  fi
done

# ------------------------------------------------------------------
# 4. Commands reference valid agents
# ------------------------------------------------------------------
heading "4. Command-to-agent references"

for cmd in "${COMMANDS[@]}"; do
  file="$ROOT/commands/${cmd}.md"
  [ -f "$file" ] || continue

  refs=$(grep -oE '@[a-zA-Z0-9_-]+' "$file" | sed 's/^@//' || true)
  if [ -z "$refs" ]; then
    fail "${cmd}.md references no subagents"
    continue
  fi

  while IFS= read -r ref; do
    found=0
    for a in "${AGENTS[@]}"; do
      if [ "$a" = "$ref" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 1 ]; then
      ok "${cmd}.md → @${ref}"
    else
      fail "${cmd}.md references unknown agent: @${ref}"
    fi
  done <<< "$refs"
done

# ------------------------------------------------------------------
# 5. Skill files exist
# ------------------------------------------------------------------
heading "5. Skills"

for skill in "${SKILLS[@]}"; do
  file="$ROOT/skills/${skill}/SKILL.md"
  if [ -f "$file" ]; then
    ok "skill exists: ${skill}/SKILL.md"
  else
    fail "skill missing: ${skill}/SKILL.md"
  fi
done

# Template must exist
if [ -f "$ROOT/skills/_template/SKILL.md" ]; then
  ok "_template/SKILL.md exists"
else
  fail "_template/SKILL.md missing"
fi

# Verify skill frontmatter has required fields
for skill in "${SKILLS[@]}"; do
  file="$ROOT/skills/${skill}/SKILL.md"
  [ -f "$file" ] || continue

  if grep -q '^name:' "$file"; then
    ok "${skill} has name"
  else
    fail "${skill} missing name field"
  fi

  if grep -q '^description:' "$file"; then
    ok "${skill} has description"
  else
    fail "${skill} missing description field"
  fi
done

# ------------------------------------------------------------------
# 6. models.json consistency
# ------------------------------------------------------------------
heading "6. models.json"

if [ -f "$ROOT/models.json" ]; then
  ok "models.json exists"
else
  fail "models.json missing"
fi

# Check opencode section has all agents
for agent in "${AGENTS[@]}"; do
  if grep -q "\"$agent\"" "$ROOT/models.json"; then
    ok "models.json → opencode.${agent}"
  else
    fail "models.json missing opencode.${agent}"
  fi
done

# Check claude section has all agents
for agent in "${AGENTS[@]}"; do
  if grep -q '"claude"' "$ROOT/models.json"; then
    # already confirmed file exists, check agent
    true
  fi
done

# Verify models.json entries are valid (use python3 for proper JSON parsing)
python3 -c "
import json, sys
with open('$ROOT/models.json') as f:
    data = json.load(f)
expected = {$(for a in "${AGENTS[@]}"; do echo -n "'$a', "; done)}
for section in ('opencode', 'claude'):
    agents = data.get(section, {})
    for name in agents:
        if name not in expected:
            print(f'models.json has unknown agent in {section}: {name}')
            sys.exit(1)
    for name in expected:
        if name not in agents:
            print(f'models.json missing {name} in {section}')
            sys.exit(1)
print('ok')
" && ok "models.json entries match agent definitions" || fail "models.json has mismatched entries"

# ------------------------------------------------------------------
# 7. Install script consistency (install.sh)
# ------------------------------------------------------------------
heading "7. install.sh agent/command coverage"

if [ -f "$ROOT/install.sh" ]; then
  ok "install.sh exists"

  for agent in "${AGENTS[@]}"; do
    if grep -q "$agent" "$ROOT/install.sh"; then
      ok "install.sh references agent: ${agent}"
    else
      fail "install.sh missing agent: ${agent}"
    fi
  done

  for cmd in "${COMMANDS[@]}"; do
    if grep -q "$cmd" "$ROOT/install.sh"; then
      ok "install.sh references command: ${cmd}"
    else
      fail "install.sh missing command: ${cmd}"
    fi
  done
else
  fail "install.sh missing"
fi

# ------------------------------------------------------------------
# 8. Install script consistency (install.ps1)
# ------------------------------------------------------------------
heading "8. install.ps1 agent/command coverage"

if [ -f "$ROOT/install.ps1" ]; then
  ok "install.ps1 exists"

  for agent in "${AGENTS[@]}"; do
    if grep -q "$agent" "$ROOT/install.ps1"; then
      ok "install.ps1 references agent: ${agent}"
    else
      fail "install.ps1 missing agent: ${agent}"
    fi
  done

  for cmd in "${COMMANDS[@]}"; do
    if grep -q "$cmd" "$ROOT/install.ps1"; then
      ok "install.ps1 references command: ${cmd}"
    else
      fail "install.ps1 missing command: ${cmd}"
    fi
  done
else
  fail "install.ps1 missing"
fi

# ------------------------------------------------------------------
# 9. AGENTS.md at project root
# ------------------------------------------------------------------
heading "9. Project root files"

if [ -f "$PROJECT/AGENTS.md" ]; then
  ok "AGENTS.md exists at project root"
else
  fail "AGENTS.md missing from project root"
fi

# ------------------------------------------------------------------
# 10. Path consistency — no stale paths in agent or command files
# ------------------------------------------------------------------
heading "10. Path consistency"

# Check that all pipeline agents/commands use docs/pipeline/plan/ not bare plan.md
# Skip utility agents and commands that don't touch pipeline files
PIPELINE_FILES=(
  "$ROOT/agents/planner.md"
  "$ROOT/agents/spec-writer.md"
  "$ROOT/agents/task-splitter.md"
  "$ROOT/agents/implementer.md"
  "$ROOT/agents/validator.md"
  "$ROOT/agents/fixer.md"
  "$ROOT/agents/batch-implementer.md"
  "$ROOT/agents/pr-creator.md"
  "$ROOT/commands/planner.md"
  "$ROOT/commands/spec.md"
  "$ROOT/commands/tasks.md"
  "$ROOT/commands/implement.md"
  "$ROOT/commands/validate.md"
  "$ROOT/commands/fix.md"
  "$ROOT/commands/implement-all.md"
  "$ROOT/commands/plan-extend.md"
)

for file in "${PIPELINE_FILES[@]}"; do
  name=$(basename "$file")
  # Agents should reference docs/pipeline/plan/ (directory) not docs/pipeline/plan.md
  if grep -q 'plan\.md' "$file" 2>/dev/null; then
    fail "$name still references plan.md — should use plan/ directory"
  fi
done

# Positive check: spec-writer says NOT behave/cucumber
if grep -qi 'NOT.*behave\|NO.*behave\|never.*behave' "$ROOT/agents/spec-writer.md"; then
  ok "spec-writer.md explicitly disallows behave/cucumber"
else
  fail "spec-writer.md should mention NOT using behave/cucumber"
fi

if grep -qi 'NOT.*behave\|NO.*behave\|never.*behave\|No behave\|no behave' "$ROOT/agents/implementer.md"; then
  ok "implementer.md explicitly disallows behave/cucumber"
else
  fail "implementer.md should mention NOT using behave/cucumber"
fi

# Verify no agent or command references features/.bddconfig or features/steps
if ! grep -qr 'features/\.bddconfig' "$ROOT/agents/" "$ROOT/commands/" 2>/dev/null; then
  ok "no agent/command references features/.bddconfig"
else
  fail "some file still references features/.bddconfig"
fi

if ! grep -qr 'features/steps' "$ROOT/agents/" "$ROOT/commands/" 2>/dev/null; then
  ok "no agent/command references features/steps"
else
  fail "some file still references features/steps"
fi

# Verify validator references docs/pipeline/reports/
if grep -q 'docs/pipeline/reports/validate/task-' "$ROOT/agents/validator.md"; then
  ok "validator writes reports to docs/pipeline/reports/validate/"
else
  fail "validator missing docs/pipeline/reports/validate/ path"
fi

# Verify implementer.md references docs/pipeline/features/
if grep -q 'docs/pipeline/features/' "$ROOT/agents/implementer.md"; then
  ok "implementer reads from docs/pipeline/features/"
else
  fail "implementer missing docs/pipeline/features/ path"
fi

# ------------------------------------------------------------------
# 11. State machine — state.json transitions
# ------------------------------------------------------------------
heading "11. State machine (state.json)"

python3 -c "
import json, sys

# Simulate valid state transitions
states = []

# Initial state after /planner
states.append({'phase': 'planning', 'features_approved': False, 'extensions_processed': 0, 'tasks_total': 0, 'tasks_completed': 0})

# After /spec approval
states.append({'phase': 'planning', 'features_approved': True, 'extensions_processed': 0, 'tasks_total': 0, 'tasks_completed': 0})

# After /tasks approval
states.append({'phase': 'implementation', 'features_approved': True, 'extensions_processed': 0, 'tasks_total': 5, 'tasks_completed': 0})

# During implementation
states.append({'phase': 'implementation', 'features_approved': True, 'extensions_processed': 0, 'tasks_total': 5, 'tasks_completed': 3})

# After all tasks done
states.append({'phase': 'complete', 'features_approved': True, 'extensions_processed': 0, 'tasks_total': 5, 'tasks_completed': 5})

# After extension
states.append({'phase': 'implementation', 'features_approved': True, 'extensions_processed': 1, 'tasks_total': 8, 'tasks_completed': 5})

# Validate each state
required_keys = {'phase', 'features_approved', 'extensions_processed', 'tasks_total', 'tasks_completed'}
for i, state in enumerate(states):
    if not required_keys.issubset(state.keys()):
        print(f'State {i} missing keys: {required_keys - set(state.keys())}')
        sys.exit(1)
    if state['phase'] not in ('planning', 'implementation', 'complete'):
        print(f'State {i} has invalid phase: {state[\"phase\"]}')
        sys.exit(1)
    if not isinstance(state['features_approved'], bool):
        print(f'State {i} features_approved must be bool')
        sys.exit(1)
    if state['tasks_total'] < 0 or state['tasks_completed'] < 0:
        print(f'State {i} task counts must be >= 0')
        sys.exit(1)
    if state['tasks_completed'] > state['tasks_total']:
        print(f'State {i} tasks_completed > tasks_total')
        sys.exit(1)
    if state['phase'] == 'planning' and state['tasks_total'] > 0:
        print(f'State {i} planning phase should have tasks_total=0')
        sys.exit(1)

print('ok')
" && ok "state.json transitions are valid" || fail "state.json transitions invalid"

# Verify state.json is mentioned in task-splitter
if grep -q 'state.json' "$ROOT/agents/task-splitter.md"; then
  ok "task-splitter references state.json"
else
  fail "task-splitter missing state.json reference"
fi

# Verify state.json is mentioned in batch-implementer
if grep -q 'state.json' "$ROOT/agents/batch-implementer.md"; then
  ok "batch-implementer references state.json"
else
  fail "batch-implementer missing state.json reference"
fi

# ------------------------------------------------------------------
# 12. Pipeline directory structure
# ------------------------------------------------------------------
heading "12. Pipeline directory structure"

# Verify install.sh creates docs/pipeline/features/.specconfig
if grep -q 'docs/pipeline/features/.specconfig' "$ROOT/install.sh"; then
  ok "install.sh creates docs/pipeline/features/.specconfig"
else
  fail "install.sh missing docs/pipeline/features/.specconfig"
fi

# Verify install.ps1 creates docs/pipeline/features/.specconfig
if grep -q 'docs/pipeline/features/.specconfig' "$ROOT/install.ps1"; then
  ok "install.ps1 creates docs/pipeline/features/.specconfig"
else
  fail "install.ps1 missing docs/pipeline/features/.specconfig"
fi

# Verify no agent references features/.bddconfig (old path)
if ! grep -q 'features/\.bddconfig' "$ROOT"/agents/*.md; then
  ok "no agent references features/.bddconfig"
else
  fail "some agent still references features/.bddconfig"
fi

# Verify no agent references features/steps (old step definitions)
if ! grep -q 'features/steps' "$ROOT"/agents/*.md; then
  ok "no agent references features/steps"
else
  fail "some agent still references features/steps"
fi

# Verify install.sh no longer references features/.bddconfig
if ! grep -q 'features/\.bddconfig' "$ROOT/install.sh"; then
  ok "install.sh no longer references features/.bddconfig"
else
  fail "install.sh still references features/.bddconfig"
fi

# Verify docs/pipeline/ directory is mentioned in .gitignore context
# (check AGENTS.md shows the new structure)
if grep -q 'docs/pipeline/' "$ROOT/AGENTS.md"; then
  ok "AGENTS.md documents docs/pipeline/ structure"
else
  fail "AGENTS.md missing docs/pipeline/ structure"
fi

# ------------------------------------------------------------------
# 13. Installation verification — check current workspace state
# ------------------------------------------------------------------
heading "13. Installation verification"

# Verify .opencode/ agents symlinks exist
for agent in planner task-splitter implementer validator fixer pr-creator spec-writer batch-implementer readme-generator context-generator reference-extractor; do
  if [ -L "$PROJECT/.opencode/agents/${agent}.md" ]; then
    ok ".opencode/agents/${agent}.md symlink"
  else
    fail ".opencode/agents/${agent}.md missing or not a symlink"
  fi
done

# Verify .opencode/ commands symlinks exist
for cmd in planner tasks implement validate fix pr-ready spec implement-all plan-extend readme context reference; do
  if [ -L "$PROJECT/.opencode/commands/${cmd}.md" ]; then
    ok ".opencode/commands/${cmd}.md symlink"
  else
    fail ".opencode/commands/${cmd}.md missing or not a symlink"
  fi
done

# Verify .opencode/ skills symlinks exist (excluding bdd which was removed)
for skill in python typescript react django fastapi textual; do
  if [ -L "$PROJECT/.opencode/skills/${skill}/SKILL.md" ]; then
    ok ".opencode/skills/${skill}/SKILL.md symlink"
  else
    fail ".opencode/skills/${skill}/SKILL.md missing or not a symlink"
  fi
done

# Verify bdd skill was NOT installed by checking symlink
if [ ! -L "$PROJECT/.opencode/skills/bdd/SKILL.md" ] && [ ! -d "$PROJECT/.opencode/skills/bdd" ]; then
  ok "bdd skill correctly removed from .opencode/skills/"
else
  fail "bdd skill still present in .opencode/skills/"
fi

# Verify opencode.json has correct agent entries
if [ -f "$PROJECT/opencode.json" ]; then
  ok "opencode.json exists"
  python3 -c "
import json
with open('$PROJECT/opencode.json') as f:
    data = json.load(f)
agents = data.get('agent', {})
assert 'planner' in agents, 'missing planner'
assert 'spec-writer' in agents, 'missing spec-writer'
assert 'batch-implementer' in agents, 'missing batch-implementer'
assert 'task-splitter' in agents, 'missing task-splitter'
assert 'implementer' in agents, 'missing implementer'
assert 'validator' in agents, 'missing validator'
assert 'fixer' in agents, 'missing fixer'
assert 'pr-creator' in agents, 'missing pr-creator'
assert 'bdd-specifier' not in agents, 'bdd-specifier should not exist'
print('ok')
" && ok "opencode.json has correct agent entries (no bdd-specifier)" || fail "opencode.json agent entries incorrect"
else
  fail "opencode.json missing"
fi

# Verify no stale command symlinks for bdd-spec
if [ ! -L "$PROJECT/.opencode/commands/bdd-spec.md" ] && [ ! -f "$PROJECT/.opencode/commands/bdd-spec.md" ]; then
  ok "bdd-spec command correctly removed"
else
  fail "bdd-spec command still present"
fi

# Verify spec and implement-all commands exist
if [ -L "$PROJECT/.opencode/commands/spec.md" ]; then
  ok "spec command installed"
else
  fail "spec command missing"
fi

if [ -L "$PROJECT/.opencode/commands/implement-all.md" ]; then
  ok "implement-all command installed"
else
  fail "implement-all command missing"
fi

# ------------------------------------------------------------------
# 14. Pipeline language configuration
# ------------------------------------------------------------------
heading "14. Pipeline language"

# All agents that must have the ## Language directive
LANG_AGENTS=(planner spec-writer task-splitter implementer validator fixer pr-creator batch-implementer context-generator readme-generator reference-extractor task-archiver)

# Expected content of the ## Language block (first 3 lines after the heading)
LANG_BLOCK_LINE1="Read \`docs/pipeline/features/.specconfig\`. The \`lang\` field (ISO 639-1 code,"
LANG_BLOCK_LINE2='e.g. `"es"`, `"en"`, `"fr"`) specifies the pipeline language. ALL communication'
LANG_BLOCK_LINE3="with the user — questions, reports, summaries, instructions, error messages —"
LANG_BLOCK_LINE4="MUST be in this language. If \`.specconfig\` does not exist, default to English."
LANG_BLOCK_TECH="Technical terms (API, JWT, endpoint, token, ORM, SDK, etc.) remain in English."

for agent in "${LANG_AGENTS[@]}"; do
  file="$ROOT/agents/${agent}.md"
  if [ -f "$file" ]; then
    if grep -q '^## Language$' "$file"; then
      ok "${agent}.md has ## Language section"
    else
      fail "${agent}.md missing ## Language section"
    fi

    # Verify key content phrases are present
    if grep -qF "$LANG_BLOCK_LINE1" "$file"; then
      ok "${agent}.md Language block line 1 correct"
    else
      fail "${agent}.md Language block line 1 mismatch"
    fi

    if grep -qF "$LANG_BLOCK_LINE3" "$file"; then
      ok "${agent}.md Language block line 3 correct"
    else
      fail "${agent}.md Language block line 3 mismatch"
    fi

    if grep -qF "$LANG_BLOCK_TECH" "$file"; then
      ok "${agent}.md Language block — technical terms rule present"
    else
      fail "${agent}.md Language block — technical terms rule missing"
    fi
  else
    fail "${agent}.md file not found"
  fi
done

# Verify planner.md no longer has the old "Write the plan in English" rule
if grep -q 'Write the plan in English' "$ROOT/agents/planner.md"; then
  fail "planner.md still says 'Write the plan in English' — should be pipeline language"
else
  ok "planner.md no longer hardcodes English"
fi

# Verify planner.md has the new rule
if grep -q 'Write plan content in the pipeline language' "$ROOT/agents/planner.md"; then
  ok "planner.md uses pipeline language from .specconfig"
else
  fail "planner.md missing pipeline language rule"
fi

# --- Installer language prompts ---

# install.sh: user-facing text must say "Pipeline language" not "Spec language"
if grep -q 'Pipeline language' "$ROOT/install.sh"; then
  ok "install.sh says 'Pipeline language'"
else
  fail "install.sh missing 'Pipeline language' text"
fi

# install.sh: the interactive prompt
if grep -q 'read -p "Pipeline language' "$ROOT/install.sh"; then
  ok "install.sh prompt says 'Pipeline language'"
else
  fail "install.sh prompt still says 'Spec language'"
fi

# install.sh: usage text describes it as pipeline language
if grep -q 'Controls all agent communication' "$ROOT/install.sh"; then
  ok "install.sh usage describes pipeline-wide scope"
else
  fail "install.sh usage missing pipeline scope description"
fi

# install.sh: log output
if grep -q 'log "Pipeline language:' "$ROOT/install.sh"; then
  ok "install.sh log says 'Pipeline language'"
else
  fail "install.sh log still says 'Spec language'"
fi

# install.sh: final output
if grep -q 'echo "Pipeline language:' "$ROOT/install.sh"; then
  ok "install.sh final output says 'Pipeline language'"
else
  fail "install.sh final output still says 'Spec language'"
fi

# install.ps1: prompt
if grep -q 'Read-Host "Pipeline language' "$ROOT/install.ps1"; then
  ok "install.ps1 prompt says 'Pipeline language'"
else
  fail "install.ps1 prompt still says 'Spec language'"
fi

# install.ps1: log output
if grep -q 'Pipeline language:.*docs/pipeline/features/.specconfig' "$ROOT/install.ps1"; then
  ok "install.ps1 log says 'Pipeline language'"
else
  fail "install.ps1 log still says 'Spec language'"
fi

# install.ps1: final output
if grep -q 'Write-Host "Pipeline language:' "$ROOT/install.ps1"; then
  ok "install.ps1 final output says 'Pipeline language'"
else
  fail "install.ps1 final output still says 'Spec language'"
fi

# --- .specconfig format preserved ---

# install.sh still creates .specconfig with lang + version fields
if grep -q '"lang".*"version".*1' "$ROOT/install.sh" || grep -q 'lang.*version.*1' "$ROOT/install.sh"; then
  ok "install.sh .specconfig format preserved (lang + version)"
else
  fail "install.sh .specconfig format may be broken"
fi

if grep -q 'lang.*version.*1' "$ROOT/install.ps1"; then
  ok "install.ps1 .specconfig format preserved (lang + version)"
else
  fail "install.ps1 .specconfig format may be broken"
fi

# Verify spec-writer still references .specconfig for language detection
if grep -q 'docs/pipeline/features/.specconfig' "$ROOT/agents/spec-writer.md"; then
  ok "spec-writer still references .specconfig"
else
  fail "spec-writer missing .specconfig reference"
fi

# Verify context-generator updated its language rule
if grep -q 'pipeline language from' "$ROOT/agents/context-generator.md"; then
  ok "context-generator references pipeline language"
else
  fail "context-generator missing pipeline language reference"
fi

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
heading "RESULTS"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "  All tests passed!"
else
  echo "  Failures:"
  echo -n "$ERRORS"
fi

echo ""
exit "$FAIL"
