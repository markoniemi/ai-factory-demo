# Unit tests for the `task` plugin.
#
#   powershell -File tests/Test-Plugin.ps1
#
# Plain PowerShell: Pester is not assumed to be installed. Exits 1 on any failure.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$script:Passed = 0
$script:Failed = 0
$script:Skipped = 0

function Test-Case {
    param([string] $Name, [scriptblock] $Body)

    try {
        & $Body
        $script:Passed++
        Write-Host "  PASS  $Name"
    }
    catch {
        $script:Failed++
        Write-Host "  FAIL  $Name"
        Write-Host "        $($_.Exception.Message)"
    }
}

function Skip-Case {
    param([string] $Name, [string] $Reason)

    $script:Skipped++
    Write-Host "  SKIP  $Name ($Reason)"
}

function Assert-True {
    param([bool] $Condition, [string] $Message)

    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param($Expected, $Actual, [string] $Message)

    if ($Expected -ne $Actual) { throw "$Message - expected '$Expected', got '$Actual'" }
}

function Get-JsonFile {
    param([string] $RelativePath)

    $path = Join-Path $root $RelativePath
    Assert-True (Test-Path $path) "$RelativePath is missing"
    return (Get-Content $path -Raw | ConvertFrom-Json)
}

function Get-SkillFrontmatter {
    param([string] $SkillName)

    $path = Join-Path $root "skills/$SkillName/SKILL.md"
    Assert-True (Test-Path $path) "skills/$SkillName/SKILL.md is missing"

    $lines = Get-Content $path
    Assert-Equal '---' $lines[0].Trim() "skills/$SkillName/SKILL.md must start with frontmatter"

    $fields = @{}
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { return $fields }
        if ($lines[$i] -match '^([A-Za-z0-9_-]+):\s*(.*)$') {
            $fields[$matches[1]] = $matches[2].Trim()
        }
    }
    throw "skills/$SkillName/SKILL.md has no closing frontmatter delimiter"
}

$skillNames = @('task', 'next-task', 'clean-tasks')

Write-Host 'plugin manifest'

Test-Case 'plugin.json declares the plugin as `task`' {
    $manifest = Get-JsonFile '.claude-plugin/plugin.json'
    Assert-Equal 'task' $manifest.name 'plugin name'
    Assert-True (-not [string]::IsNullOrWhiteSpace($manifest.version)) 'version must be set'
    Assert-True (-not [string]::IsNullOrWhiteSpace($manifest.description)) 'description must be set'
    Assert-True (-not [string]::IsNullOrWhiteSpace($manifest.author.name)) 'author.name must be set'
}

Write-Host 'marketplace manifest'

Test-Case 'marketplace.json lists the plugin at the repository root' {
    $marketplace = Get-JsonFile '.claude-plugin/marketplace.json'
    Assert-Equal 'task-plugin' $marketplace.name 'marketplace name'
    Assert-True (-not [string]::IsNullOrWhiteSpace($marketplace.owner.name)) 'owner.name must be set'
    Assert-True (-not [string]::IsNullOrWhiteSpace($marketplace.description)) 'description must be set'

    $entries = @($marketplace.plugins)
    Assert-Equal 1 $entries.Count 'one plugin entry'
    Assert-Equal 'task' $entries[0].name 'entry name'
    Assert-Equal './' $entries[0].source 'entry source'
}

Write-Host 'skills'

foreach ($name in $skillNames) {
    $skill = $name
    Test-Case "skills/$skill/SKILL.md has frontmatter naming the skill" {
        $fields = Get-SkillFrontmatter $skill
        Assert-Equal $skill $fields['name'] "frontmatter name of $skill"
        Assert-True (-not [string]::IsNullOrWhiteSpace($fields['description'])) "description of $skill must be set"
    }
}

Test-Case 'the task skill takes the task name as an argument' {
    $body = Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw
    Assert-True ($body -match '\$ARGUMENTS') 'skills/task/SKILL.md must reference $ARGUMENTS'
}

Write-Host 'protocol carried over from AGENTS.md'

Test-Case 'every status name survives in the task skill' {
    $body = Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw
    foreach ($status in @('draft', 'planning', 'planned', 'in_progress', 'in_review',
                          'changes_requested', 'approved', 'done')) {
        Assert-True ($body -match [regex]::Escape($status)) "status '$status' is missing"
    }
}

Test-Case 'the task skill states the task file shape and the backlog mirror' {
    $body = Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw
    foreach ($rule in @('task-NNN-', 'Tasks.md', 'branch:', 'priority:')) {
        Assert-True ($body -match [regex]::Escape($rule)) "rule '$rule' is missing"
    }
}

Test-Case 'next-task states the selection rule' {
    $body = Get-Content (Join-Path $root 'skills/next-task/SKILL.md') -Raw
    Assert-True ($body -match 'plan:') 'next-task must skip entries that already have a plan: line'
    Assert-True ($body -match 'priority') 'next-task must order by priority'
}

Test-Case 'clean-tasks keeps its two guards' {
    $body = Get-Content (Join-Path $root 'skills/clean-tasks/SKILL.md') -Raw
    Assert-True ($body -match 'done') 'clean-tasks must only delete done tasks'
    Assert-True ($body -match 'never') 'clean-tasks must keep the "never on your own" guard'
}

Write-Host 'the plugin replaces docs/tasks/AGENTS.md'

Test-Case 'docs/tasks/AGENTS.md is deleted' {
    Assert-True (-not (Test-Path (Join-Path $root 'docs/tasks/AGENTS.md'))) 'docs/tasks/AGENTS.md still exists'
}

Test-Case 'no living file names AGENTS.md as the rules' {
    # Task files are records of work already done and may mention it as history;
    # the files a reader is sent to for the rules may not.
    # The plugin's own README is exempt: it says there is no AGENTS.md, which is
    # the point.
    $living = @((Join-Path $root 'docs/tasks/README.md'))

    $hits = @(Select-String -Path $living -Pattern 'AGENTS\.md' |
        ForEach-Object { "$($_.Filename):$($_.LineNumber)" })

    # In Tasks.md only the preamble counts, not the backlog entries' own wording.
    $lines = Get-Content (Join-Path $root 'docs/tasks/Tasks.md')
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+Backlog') { break }
        if ($lines[$i] -match 'AGENTS\.md') { $hits += "Tasks.md:$($i + 1)" }
    }

    if ($hits.Count -gt 0) {
        throw "AGENTS.md is still named as the rules in $($hits -join ', ')"
    }
}

Write-Host 'claude plugin validate'

$claude = Get-Command claude -ErrorAction SilentlyContinue
if ($claude) {
    Test-Case 'claude plugin validate passes' {
        $output = & $claude.Source plugin validate $root
        if ($LASTEXITCODE -ne 0) { throw ($output -join "`n") }
    }
}
else {
    Skip-Case 'claude plugin validate passes' 'claude is not on PATH'
}

Write-Host ''
Write-Host "passed $script:Passed, failed $script:Failed, skipped $script:Skipped"

if ($script:Failed -gt 0) { exit 1 }
exit 0
