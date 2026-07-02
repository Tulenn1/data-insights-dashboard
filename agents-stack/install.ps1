# ============================================================================
# Subagent Stack Installer (Windows PowerShell)
# Installs agent configs for opencode, Claude Code, or both
# ============================================================================

param(
    [string]$Target = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SrcDir = $ScriptDir
$ModelsFile = Join-Path $SrcDir "models.json"
$InstallAgentsFile = Join-Path $SrcDir "AGENTS.md"

function Show-Usage {
    Write-Host "Usage: .\install.ps1 [-Target opencode|claude|both]" -ForegroundColor Cyan
}

function Normalize-Target($Value) {
    switch ($Value.ToLowerInvariant()) {
        "opencode" { return "opencode" }
        "claude"   { return "claude" }
        "both"     { return "both" }
        default     { return $null }
    }
}

if ($args -contains "-h" -or $args -contains "--help") {
    Show-Usage
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Target)) {
    if (-not [Console]::IsInputRedirected) {
        $Target = Read-Host "Choose installation target (opencode/claude/both) [both]"
        if ([string]::IsNullOrWhiteSpace($Target)) {
            $Target = "both"
        }
    } else {
        $Target = "both"
    }
}

if (-not (Test-Path $ModelsFile)) {
    Write-Host "[✗] models.json not found at $ModelsFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $InstallAgentsFile)) {
    Write-Host "[✗] AGENTS.md not found at $InstallAgentsFile" -ForegroundColor Red
    exit 1
}

$Models = Get-Content $ModelsFile | ConvertFrom-Json

$Target = Normalize-Target $Target
if (-not $Target) {
    Write-Host "[✗] Invalid target. Use opencode, claude, or both." -ForegroundColor Red
    Show-Usage
    exit 1
}

function Get-Model($Tool, $Agent) {
    $m = $Models.$Tool.$Agent
    if ($m) { return $m } else { return "" }
}

function Prepare-Dir($Dir) {
    if (-not (Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    }
}

function Install-ProjectAgentsFile {
    $dst = Join-Path $ProjectRoot "AGENTS.md"
    Copy-Item $InstallAgentsFile $dst -Force
    Write-Host "[✓] project AGENTS: $dst" -ForegroundColor Green
}

function Install-OpenCodeAgent($AgentName) {
    $src = Join-Path $SrcDir "agents" "$AgentName.md"
    $dst = Join-Path $ProjectRoot ".opencode" "agents" "$AgentName.md"

    if (-not (Test-Path $src)) {
        Write-Host "[✗] Source not found: $src" -ForegroundColor Red
        return
    }

    Prepare-Dir (Split-Path $dst -Parent)
    New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
    Write-Host "[✓] opencode agent: $AgentName → .opencode/agents/$AgentName.md" -ForegroundColor Green
}

function Install-ClaudeAgent($AgentName) {
    $src = Join-Path $SrcDir "agents" "$AgentName.md"
    $dst = Join-Path $ProjectRoot ".claude" "agents" "$AgentName.md"
    $model = Get-Model "claude" $AgentName

    if (-not (Test-Path $src)) {
        Write-Host "[✗] Source not found: $src" -ForegroundColor Red
        return
    }

    Prepare-Dir (Split-Path $dst -Parent)

    $content = Get-Content $src -Raw
    if ($model) {
        $content = $content -replace "(?m)^(description:.*)$", "`$1`nmodel: $model"
    }
    Set-Content -Path $dst -Value $content -NoNewline

    if ($model) {
        Write-Host "[✓] claude agent:   $AgentName → .claude/agents/$AgentName.md  (model: $model)" -ForegroundColor Green
    } else {
        Write-Host "[✓] claude agent:   $AgentName → .claude/agents/$AgentName.md  (model: inherit)" -ForegroundColor Green
    }
}

function Install-Commands($TargetName, $CmdName) {
    $src = Join-Path $SrcDir "commands" "$CmdName.md"
    $dst = Join-Path $ProjectRoot ".$TargetName" "commands" "$CmdName.md"

    if (-not (Test-Path $src)) {
        Write-Host "[✗] Source not found: $src" -ForegroundColor Red
        return
    }

    Prepare-Dir (Split-Path $dst -Parent)

    New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
    Write-Host "[✓] command:        $CmdName → .$TargetName/commands/" -ForegroundColor Green
}

function Install-Skills($TargetName, $SkillName) {
    $src = Join-Path $SrcDir "skills" $SkillName "SKILL.md"
    $dst = Join-Path $ProjectRoot ".$TargetName" "skills" $SkillName "SKILL.md"

    if (-not (Test-Path $src)) {
        Write-Host "[✗] Source not found: $src" -ForegroundColor Red
        return
    }

    Prepare-Dir (Split-Path $dst -Parent)

    New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
    Write-Host "[✓] skill:          $SkillName → .$TargetName/skills/" -ForegroundColor Green
}

function Merge-OpenCodeConfig {
    $dst = Join-Path $ProjectRoot "opencode.json"
    $agent = [ordered]@{}

    foreach ($name in @("planner", "task-splitter", "task-archiver", "implementer", "validator", "fixer", "pr-creator", "spec-writer", "batch-implementer", "readme-generator", "context-generator", "reference-extractor")) {
        $model = Get-Model "opencode" $name
        if ($model) {
            $agent[$name] = [ordered]@{
                model = $model
                mode  = "subagent"
            }
        }
    }

    $existing = $null
    if (Test-Path $dst) {
        $raw = Get-Content $dst -Raw
        try {
            $existing = $raw | ConvertFrom-Json
        } catch {
            Write-Host "[✗] opencode.json must be valid JSON for automatic merge." -ForegroundColor Red
            throw
        }
    } else {
        $existing = [ordered]@{}
    }

    if (-not $existing.PSObject.Properties.Match("`$schema").Count) {
        $merged = [ordered]@{ "`$schema" = "https://opencode.ai/config.json" }
        foreach ($prop in $existing.PSObject.Properties) {
            $merged[$prop.Name] = $prop.Value
        }
        $existing = $merged
    }

    if (-not $existing.PSObject.Properties.Match("agent").Count) {
        $existing | Add-Member -NotePropertyName agent -NotePropertyValue ([ordered]@{})
    }

    if ($existing.agent -is [pscustomobject]) {
        $currentAgent = [ordered]@{}
        foreach ($prop in $existing.agent.PSObject.Properties) {
            $currentAgent[$prop.Name] = $prop.Value
        }
        $existing.agent = $currentAgent
    } elseif ($existing.agent -isnot [System.Collections.IDictionary]) {
        Write-Host "[✗] opencode.json agent section must be an object." -ForegroundColor Red
        exit 1
    }

    foreach ($prop in $agent.GetEnumerator()) {
        $existing.agent[$prop.Key] = $prop.Value
    }

    $existing | ConvertTo-Json -Depth 20 | Set-Content $dst -NoNewline
    Write-Host "[✓] opencode config: $dst" -ForegroundColor Green
}

# ============================================================================
# Main
# ============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Subagent Stack Installer (Windows)" -ForegroundColor Cyan
Write-Host "  Target: $Target" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Install-ProjectAgentsFile

switch ($Target) {
    "opencode" { $RuntimeTargets = @("opencode") }
    "claude"   { $RuntimeTargets = @("claude") }
    default     { $RuntimeTargets = @("opencode", "claude") }
}

# Internal tools (not auto-installed): manifest-generator, sync-agents
switch ($Target) {
    "opencode" {
        Write-Host "[→] Installing opencode assets..." -ForegroundColor Cyan
        @("planner", "task-splitter", "task-archiver", "implementer", "validator", "fixer", "pr-creator", "spec-writer", "batch-implementer", "readme-generator", "context-generator", "reference-extractor") | ForEach-Object {
            Install-OpenCodeAgent $_
        }

        Write-Host ""
        Write-Host "[→] Merging opencode config..." -ForegroundColor Cyan
        Merge-OpenCodeConfig
    }
    "claude" {
        Write-Host "[→] Installing Claude Code assets..." -ForegroundColor Cyan
        @("planner", "task-splitter", "task-archiver", "implementer", "validator", "fixer", "pr-creator", "spec-writer", "batch-implementer", "readme-generator", "context-generator", "reference-extractor") | ForEach-Object {
            Install-ClaudeAgent $_
        }
    }
    default {
        Write-Host "[→] Installing opencode assets..." -ForegroundColor Cyan
        @("planner", "task-splitter", "task-archiver", "implementer", "validator", "fixer", "pr-creator", "spec-writer", "batch-implementer", "readme-generator", "context-generator", "reference-extractor") | ForEach-Object {
            Install-OpenCodeAgent $_
        }

        Write-Host ""
        Write-Host "[→] Merging opencode config..." -ForegroundColor Cyan
        Merge-OpenCodeConfig

        Write-Host ""
        Write-Host "[→] Installing Claude Code assets..." -ForegroundColor Cyan
        @("planner", "task-splitter", "task-archiver", "implementer", "validator", "fixer", "pr-creator", "spec-writer", "batch-implementer", "readme-generator", "context-generator", "reference-extractor") | ForEach-Object {
            Install-ClaudeAgent $_
        }
    }
}

# --- Commands ---
Write-Host ""
Write-Host "[→] Installing slash commands..." -ForegroundColor Cyan
@("planner", "tasks", "implement", "validate", "fix", "pr-ready", "spec", "implement-all", "plan-extend", "readme", "context", "reference", "archive") | ForEach-Object {
    $cmd = $_
    $RuntimeTargets | ForEach-Object {
        Install-Commands $_ $cmd
    }
}

# --- Skills ---
Write-Host ""
Write-Host "[→] Installing skills..." -ForegroundColor Cyan
$skillDir = Join-Path $SrcDir "skills"
if (Test-Path $skillDir) {
    Get-ChildItem $skillDir -Directory | ForEach-Object {
        $skillName = $_.Name
        if ($skillName -eq "_template") { continue }
        $skillFile = Join-Path $_.FullName "SKILL.md"
        if (Test-Path $skillFile) {
            $RuntimeTargets | ForEach-Object {
                Install-Skills $_ $skillName
            }
        }
    }
}

# --- Spec language configuration ---
Write-Host ""
Write-Host "[→] Configuring pipeline language..." -ForegroundColor Cyan
$BDDLang = if ($args -contains "--spec-lang") {
    $idx = [array]::IndexOf($args, "--spec-lang")
    $args[$idx + 1]
} elseif ([Console]::IsOutputRedirected -eq $false -and [Environment]::UserInteractive) {
    $userLang = Read-Host "Pipeline language [en]"
    if ([string]::IsNullOrWhiteSpace($userLang)) { "en" } else { $userLang }
} else { "en" }

$specConfigDir = Join-Path $ProjectRoot "docs/pipeline/features"
if (-not (Test-Path $specConfigDir)) { New-Item -ItemType Directory -Path $specConfigDir -Force | Out-Null }
$specConfig = @{ lang = $BDDLang; version = 1 } | ConvertTo-Json
Set-Content -Path (Join-Path $specConfigDir ".specconfig") -Value $specConfig
Write-Host "[✓] Pipeline language: $BDDLang → docs/pipeline/features/.specconfig" -ForegroundColor Green

# --- Final instructions ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed AGENTS.md at project root."
switch ($Target) {
    "opencode" { Write-Host "Installed: .opencode/, opencode.json" }
    "claude"   { Write-Host "Installed: .claude/" }
    default     { Write-Host "Installed: .opencode/, .claude/, opencode.json" }
}
Write-Host "Pipeline language: $BDDLang"
Write-Host ""
