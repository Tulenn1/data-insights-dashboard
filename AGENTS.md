# AGENTS — Subagent Pipeline Configuration

This file configures a 6-stage subagent pipeline for AI-assisted software
development. Compatible with both **opencode** and **Claude Code**.

Copy this file to your project root, run the installer, and use the slash
commands below.

## Pipeline Overview

```bash
/planner → /spec → /tasks → /implement-all → /pr-ready
(plan)     (spec)   (split)    (batch: implement→validate→fix)   (ship)

Manual mode: /implement <id> → /validate <id> → /fix <id>
```

<!-- AUTO-GEN: pipeline-table -->
| Stage | Command | Subagent | What it does |
|-------|---------|----------|--------------|
| 1 | `/planner "description"` | @planner | Clarifies requirements interactively, produces section files in `docs/pipeline/plan/`. Reads `docs/context/` if available. |
| 2a | `/spec [--lang <code>]` | @spec-writer | Converts plan section files into Gherkin `.feature` files in `docs/pipeline/features/`. Language auto-detected or set via `--lang`. Asks for user approval before proceeding. |
| 2b | `/tasks` | @task-splitter | Reads `docs/pipeline/plan/` and `.feature` files, decomposes into atomic tasks in `docs/pipeline/tasks/`. Sets phase to "implementation". |
| 3a | `/implement-all` | @batch-implementer | Batch mode: runs implement→validate→fix cycle for all pending tasks. Stops on major issues. |
| 3b | `/implement <task-id>` | @implementer | Implements one task with clean architecture + unit tests driven by feature specs. |
| 4 | `/validate <task-id>` | @validator | Validates implementation against plan, cross-references spec scenarios with unit tests, classifies issues (minor/major). |
| 5 | `/fix <task-id>` | @fixer | Applies surgical fixes for minor validation issues (major issues go back to `/planner`). |
| 6 | `/pr-ready` | @pr-creator | Runs all unit tests, creates commit + PR with results report. |
<!-- END-AUTO-GEN -->

## Utility Commands

These commands run independently of the pipeline.

<!-- AUTO-GEN: utility-commands -->
### `/context` — Project Context Documentation

Generates and maintains structured business/domain documentation about your
project. The `@planner` automatically reads this context if it exists, giving
it deep knowledge of your project before planning.

| Command | When | What it does |
|---------|------|--------------|
| `/context` | First run | Interactive Q&A for all 3 sections: overview, tech stack, roadmap |
| `/context` | Re-run | Update mode — shows current content, asks what changed |
| `/context --add <name>` | Anytime | Adds a new custom section (e.g., `--add domain-model`) |

**Examples:**

```bash
# First time — interactive Q&A for all sections
opencode run "/context"

# Update the roadmap after a milestone
opencode run "/context"

# Add a new custom section
opencode run "/context --add domain-model"
```

**How it integrates:**

```
/context (on demand)
     ↓
docs/context/  ──read by──→  @planner (if exists)
                                  ↓
                            /planner → /tasks → /implement → ...
```

### `/reference` — Repository Reference Importer

Imports an external repository reference into `docs/references/`. Fetches the
repo structure via GitHub/GitLab API and saves it as a single `.md` file with
the URL + filtered project tree — so AI agents can understand a dependency
without browsing the full repo.

```bash
# Import a GitHub repo reference
opencode run "/reference --repo https://github.com/user/repo"
```

### `/readme` — README Generator

Generates a professional `README.md` with auto-detected stack, prerequisites,
scripts, and test commands.

```bash
opencode run "/readme"
```

### `/plan-extend` — Plan Extension

Extends an existing plan with a new requirement without losing prior
planning. Invokes `@planner` in **append mode** — it reads the existing plan,
clarifies the new requirement, and creates a new file in
`docs/pipeline/plan/extensions/`.

After extending, run `/tasks` to merge the new extension into the task
index. The task-splitter auto-detects the extension and enters merge mode.

```bash
# Add a new feature to an existing plan
opencode run "/plan-extend Add export to CSV"
```

### `/archive` — Task Archiver

Archives completed tasks to `tasks/archive/completed.md` and compresses the
task index. When all tasks are archived, offers to reset the pipeline for a
fresh cycle (starting from Task 1).

```bash
# Archive completed tasks and reduce context usage
opencode run "/archive"
```

Use when:
- `tasks/` has 50+ task files and context usage is growing
- A feature cycle is complete and you want to start fresh
- The batch-implementer suggests it (at 50+ completed tasks)
<!-- END-AUTO-GEN -->

## Setup

### 1. Install subagent configurations

```bash
cd agents-stack && ./install.sh --target opencode      # macOS / Linux
# o
cd agents-stack && ./install.sh --target claude
# o
cd agents-stack && ./install.sh --target both
# or
cd agents-stack; .\install.ps1 -Target opencode       # Windows PowerShell
# o
cd agents-stack; .\install.ps1 -Target claude
# o
cd agents-stack; .\install.ps1 -Target both
```

This creates the necessary symlinks/copies in `.opencode/` and `.claude/`.

### 2. Configure models (opencode only)

Add the `agent` section to your `opencode.json`:

<!-- AUTO-GEN: model-config -->
```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "planner":              { "model": "opencode-go/deepseek-v4-pro",    "mode": "subagent" },
    "spec-writer":          { "model": "opencode-go/deepseek-v4-flash", "mode": "subagent" },
    "task-splitter":        { "model": "opencode-go/deepseek-v4-flash", "mode": "subagent" },
    "implementer":          { "model": "opencode-go/minimax-m2.7",      "mode": "subagent" },
    "validator":            { "model": "opencode-go/deepseek-v4-flash", "mode": "subagent" },
    "fixer":                { "model": "opencode-go/deepseek-v4-flash", "mode": "subagent" },
    "pr-creator":           { "model": "opencode-go/deepseek-v4-flash", "mode": "subagent" },
    "batch-implementer":    { "model": "opencode-go/deepseek-v4-pro",   "mode": "subagent" },
    "context-generator":    { "model": "opencode-go/deepseek-v4-flash", "mode": "subagent" },
    "reference-extractor":  { "model": "opencode-go/deepseek-v4-flash", "mode": "subagent" },
    "readme-generator":     { "model": "opencode-go/deepseek-v4-flash", "mode": "subagent" }
  }
}
```
<!-- END-AUTO-GEN -->

Claude Code users don't need this — models are injected by `agents-stack/install.sh`.

### 3. (Optional) Add language-specific skills

<!-- AUTO-GEN: skills-list -->
Copy `agents-stack/skills/_template/` to `agents-stack/skills/<language>/` and customize
`SKILL.md`. The implementer will auto-detect the project stack and load the
matching skill.

After adding a skill, re-run `agents-stack/install.sh`.

| Name | Description |
|------|-------------|
| django-patterns | Django conventions with ORM, class-based views, forms, DRF, Celery, and clean architecture patterns. |
| fastapi-patterns | FastAPI conventions with SQLAlchemy async, Pydantic v2, Alembic, and clean architecture patterns. |
| python-patterns | Python general conventions (type hints, testing, linting, clean architecture). Framework-agnostic base skill. |
| react-patterns | React conventions with hooks, components, TanStack Query, React Router, testing, and clean architecture patterns. |
| textual-patterns | Textual TUI conventions — App/Screen/Widget composition, TCSS styling, reactive attributes, message passing, workers, and pytest-based testing. |
| typescript-patterns | TypeScript general conventions (strict mode, testing, linting, clean architecture). Framework-agnostic base skill. |
<!-- END-AUTO-GEN -->

## Usage Examples

```bash
# OpenCode
opencode run "/planner Add a dark mode toggle to settings"
opencode run "/spec"
opencode run "/tasks"
opencode run "/implement-all"

# Claude Code
claude -p "/planner Add user authentication with OAuth"
claude -p "/spec"
claude -p "/tasks"
claude -p "/implement-all"
```

## Project Structure (after install)

```
<your-project>/
├── .opencode/
│   ├── agents/           → symlinks to agents-stack/agents/
│   ├── commands/         → symlinks to agents-stack/commands/
│   └── skills/           → symlinks to agents-stack/skills/
├── .claude/
│   ├── agents/           → copies with model injected
│   ├── commands/         → symlinks to agents-stack/commands/
│   └── skills/           → symlinks to agents-stack/skills/
├── docs/pipeline/        ← generated by pipeline
│   ├── plan/             ← generated by /planner (section files)
│   │   ├── index.md
│   │   ├── requirements.md
│   │   ├── data-model.md
│   │   ├── api.md
│   │   ├── ui.md
│   │   ├── edge-cases.md
│   │   ├── testing.md
│   │   └── extensions/   ← added by /plan-extend
│   ├── tasks/             ← generated by /tasks (index.md + task-NN.md files)
│   │   └── archive/        ← generated by /archive (completed.md)
│   ├── state.json          ← pipeline phase tracking
│   ├── features/         ← generated by /spec
│   │   └── .specconfig
│   └── reports/          ← generated by /validate and /fix
│       ├── validate/
│       └── fix/
└── AGENTS.md             ← this file
```
