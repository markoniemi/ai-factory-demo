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

$skillNames = @('task', 'next-task', 'clean-tasks', 'init')

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
    foreach ($rule in @('Tasks.md', 'branch:', 'priority:')) {
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

$script:ConfigDefaults = @{ create_branch = $true; create_pull_request = $false }
$script:ConfigOptionKeys = @('type', 'title', 'description', 'required', 'default',
                             'options', 'multiple', 'sensitive', 'min', 'max')

function Get-TaskConfig {
    param([string] $Text)

    $config = @{}
    foreach ($key in $script:ConfigDefaults.Keys) { $config[$key] = $script:ConfigDefaults[$key] }

    $lines = $Text -split "`r?`n"
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return $config }

    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { return $config }
        if ($lines[$i] -match '^([A-Za-z0-9_-]+):\s*(\S+)\s*$') {
            $key = $matches[1]
            $value = $matches[2]
            if (-not $config.ContainsKey($key)) { continue }
            if ($value -eq 'true') { $config[$key] = $true }
            elseif ($value -eq 'false') { $config[$key] = $false }
            else { throw "$key must be true or false, not '$value'" }
        }
    }
    throw 'the frontmatter has no closing delimiter'
}

Write-Host 'heading-derived task ids'

function Get-TaskSlug {
    param([string] $Heading)

    return ($Heading.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
}

function Test-TaskSlug {
    param([string] $Slug)

    return ($Slug -cmatch '^[a-z0-9][a-z0-9-]*[a-z0-9]$') -and ($Slug.Length -le 60)
}

function Get-TaskFiles {
    $dir = Join-Path $root 'docs/tasks'
    if (-not (Test-Path $dir)) { return @() }

    return @(Get-ChildItem -Path $dir -Filter '*.md' -File |
        Where-Object { $_.Name -ne 'README.md' -and $_.Name -ne 'Tasks.md' })
}

function Get-Frontmatter {
    param([string] $Path)

    $lines = Get-Content $Path
    Assert-Equal '---' $lines[0].Trim() "$Path must start with frontmatter"

    $fields = @{}
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { return $fields }
        if ($lines[$i] -match '^([A-Za-z0-9_-]+):\s*(.*)$') {
            $fields[$matches[1]] = $matches[2].Trim()
        }
    }
    throw "$Path has no closing frontmatter delimiter"
}

Test-Case 'the protocol states the slug rule and the stop-and-ask' {
    $body = Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw
    Assert-True ($body -match [regex]::Escape('^[a-z0-9][a-z0-9-]*[a-z0-9]$')) 'the slug pattern is missing'
    # The phrase may be wrapped across lines, so match across whitespace.
    Assert-True ($body -match 'ask\s+the\s+human\s+to\s+edit\s+the\s+heading') 'the stop-and-ask on a bad heading is missing'
}

Test-Case 'no skill prescribes the numbered scheme any more' {
    foreach ($name in @('task', 'next-task')) {
        $body = Get-Content (Join-Path $root "skills/$name/SKILL.md") -Raw
        foreach ($dead in @('task-NNN', 'task/NNN-', 'next free number')) {
            Assert-True (-not ($body -match [regex]::Escape($dead))) "skills/$name/SKILL.md still prescribes '$dead'"
        }
    }
}

Test-Case 'the protocol states which files are task files' {
    $body = Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw
    Assert-True ($body -match [regex]::Escape('*.md')) 'the scan rule must name every *.md'
    Assert-True ($body -match 'except') 'the scan rule must state an exception'
    Assert-True ($body -match 'README\.md' -and $body -match 'Tasks\.md') 'README.md and Tasks.md must be excluded'
}

Test-Case 'every task file states id, status, priority and branch' {
    $files = Get-TaskFiles
    Assert-True ($files.Count -gt 0) 'docs/tasks holds no task files'

    # branch: is there only when the project permits a branch per task.
    $keys = @('id', 'status', 'priority')
    if ((Get-TaskConfig (Get-Content (Join-Path $root 'docs/tasks/Tasks.md') -Raw))['create_branch']) {
        $keys += 'branch'
    }

    $statuses = @('draft', 'planning', 'planned', 'in_progress', 'in_review',
                  'changes_requested', 'approved', 'done')
    foreach ($file in $files) {
        $fm = Get-Frontmatter $file.FullName
        foreach ($key in $keys) {
            Assert-True ($fm.ContainsKey($key)) "$($file.Name) has no $key"
        }
        Assert-True ($statuses -contains $fm['status']) "$($file.Name) has an unknown status '$($fm['status'])'"
        Assert-True (@('high', 'medium', 'low') -contains $fm['priority']) "$($file.Name) has an unknown priority '$($fm['priority'])'"
    }
}

Test-Case 'every task id is its file name, or a legacy numbered id' {
    foreach ($file in (Get-TaskFiles)) {
        $fm = Get-Frontmatter $file.FullName
        $id = $fm['id']
        if ($id -cmatch '^task-\d{3}$') {
            Assert-True ($file.BaseName.StartsWith($id)) "$($file.Name) is not named for its legacy id '$id'"
        }
        else {
            Assert-Equal $file.BaseName $id "$($file.Name): id must equal the file name"
            Assert-True (Test-TaskSlug $id) "$($file.Name): id '$id' does not match the slug rule"
        }
    }
}

$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    Test-Case 'every branch name is a legal git ref' {
        foreach ($file in (Get-TaskFiles)) {
            $branch = (Get-Frontmatter $file.FullName)['branch']
            if ([string]::IsNullOrWhiteSpace($branch)) { continue }
            $null = & $git.Source check-ref-format "refs/heads/$branch"
            if ($LASTEXITCODE -ne 0) { throw "$($file.Name): '$branch' is not a legal branch name" }
        }
    }
}
else {
    Skip-Case 'every branch name is a legal git ref' 'git is not on PATH'
}

Test-Case 'slug derivation follows the rule' {
    $cases = @(
        @{ Heading = 'task id/name';           Slug = 'task-id-name' },
        @{ Heading = 'feature vs task';        Slug = 'feature-vs-task' },
        @{ Heading = '  Spaces  and--dashes '; Slug = 'spaces-and-dashes' },
        @{ Heading = 'C# & .NET';              Slug = 'c-net' }
    )
    foreach ($case in $cases) {
        $slug = Get-TaskSlug $case.Heading
        Assert-Equal $case.Slug $slug "slug of '$($case.Heading)'"
        Assert-True (Test-TaskSlug $slug) "slug '$slug' must pass the rule"
    }
}

Test-Case 'a heading that cannot make a slug is rejected' {
    Assert-True (-not (Test-TaskSlug (Get-TaskSlug '???'))) 'a heading with no letters or digits must be rejected'
    Assert-True (-not (Test-TaskSlug (Get-TaskSlug 'a'))) 'a one-character slug must be rejected'
    Assert-True (-not (Test-TaskSlug ('x' * 61))) 'a slug longer than 60 characters must be rejected'
}

Write-Host 'plugin configuration'


Test-Case 'the manifest declares both configuration options' {
    $manifest = Get-JsonFile '.claude-plugin/plugin.json'
    Assert-True ($null -ne $manifest.userConfig) 'plugin.json must declare userConfig'

    foreach ($pair in @(@('create_branch', $true), @('create_pull_request', $false))) {
        $option = $manifest.userConfig.($pair[0])
        Assert-True ($null -ne $option) "userConfig.$($pair[0]) is missing"
        Assert-Equal 'boolean' $option.type "type of $($pair[0])"
        Assert-Equal $pair[1] $option.default "default of $($pair[0])"
        Assert-True (-not [string]::IsNullOrWhiteSpace($option.title)) "title of $($pair[0])"
        Assert-True (-not [string]::IsNullOrWhiteSpace($option.description)) "description of $($pair[0])"
    }
}

Test-Case 'no userConfig option carries a key Claude Code would reject' {
    # userConfig options are strict objects: an unknown key stops the plugin loading.
    $manifest = Get-JsonFile '.claude-plugin/plugin.json'
    foreach ($option in $manifest.userConfig.PSObject.Properties) {
        foreach ($field in $option.Value.PSObject.Properties.Name) {
            Assert-True ($script:ConfigOptionKeys -contains $field) "userConfig.$($option.Name).$field is not a documented field"
        }
    }
}

Test-Case 'the protocol states the keys, the layers and the precedence' {
    $body = Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw
    foreach ($rule in @('create_branch', 'create_pull_request', 'Tasks.md',
                        '${user_config.', 'frontmatter', 'recedence')) {
        Assert-True ($body -match [regex]::Escape($rule)) "the configuration section must state '$rule'"
    }
}

Test-Case 'the protocol states that a key is a ceiling, not a default' {
    $body = Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw
    Assert-True ($body -match 'ceiling') 'the ceiling reading is missing'
    Assert-True ($body -match 'contradiction') 'the create_pull_request without create_branch case is missing'
}

Test-Case 'the branch path survives the rewrite' {
    $body = Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw
    # Wrapped prose: match across whitespace, so the test does not dictate the wrap.
    Assert-True ($body -match 'create\s+the\s+branch\s+named\s+in') 'the protocol must still create the branch named in branch:'
    Assert-True ($body -match 'fast-forward') 'the local merge must still be stated'
}

Test-Case 'the request path names both hosts and their commands' {
    $body = Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw
    foreach ($rule in @('gh pr create', 'gh pr view', 'glab mr create', 'glab mr view', 'origin')) {
        Assert-True ($body -match [regex]::Escape($rule)) "the request path must name '$rule'"
    }
    Assert-True (-not ($body -match 'uses no pull requests')) 'the "no pull requests" sentence must be gone'
}

Test-Case 'configuration is read from the frontmatter over the defaults' {
    $cases = @(
        @{ Name = 'no frontmatter';  Text = "# Task Backlog`n`ntext";                       Branch = $true;  Pr = $false },
        @{ Name = 'branch off';      Text = "---`ncreate_branch: false`n---`n# Backlog";    Branch = $false; Pr = $false },
        @{ Name = 'request on';      Text = "---`ncreate_pull_request: true`n---`n";        Branch = $true;  Pr = $true },
        @{ Name = 'both set';        Text = "---`ncreate_branch: false`ncreate_pull_request: true`n---`n"; Branch = $false; Pr = $true },
        @{ Name = 'unknown key';     Text = "---`nwhatever: 3`n---`n";                      Branch = $true;  Pr = $false },
        @{ Name = 'not at the top';  Text = "# Backlog`n`n---`ncreate_branch: false`n---`n"; Branch = $true; Pr = $false }
    )
    foreach ($case in $cases) {
        $config = Get-TaskConfig $case.Text
        Assert-Equal $case.Branch $config['create_branch'] "create_branch with $($case.Name)"
        Assert-Equal $case.Pr $config['create_pull_request'] "create_pull_request with $($case.Name)"
    }
}

Test-Case 'a value that is not a boolean is rejected' {
    $rejected = $false
    try { Get-TaskConfig "---`ncreate_branch: yes`n---`n" }
    catch { $rejected = $true }
    Assert-True $rejected 'create_branch: yes must be rejected, not guessed at'
}

Test-Case 'this project states its own configuration' {
    $text = Get-Content (Join-Path $root 'docs/tasks/Tasks.md') -Raw
    Assert-True ($text.TrimStart() -match '^---') 'docs/tasks/Tasks.md must open with the configuration frontmatter'

    $config = Get-TaskConfig $text
    foreach ($key in @('create_branch', 'create_pull_request')) {
        Assert-True ($config[$key] -is [bool]) "$key must be a boolean"
    }
}

Write-Host 'the init skill'

function Get-TemplatePath {
    param([string] $Name)

    return (Join-Path $root "skills/init/templates/$Name")
}

Test-Case 'both templates exist' {
    foreach ($name in @('Tasks.md', 'README.md')) {
        Assert-True (Test-Path (Get-TemplatePath $name)) "skills/init/templates/$name is missing"
    }
}

Test-Case 'the backlog template is a valid backlog' {
    $text = Get-Content (Get-TemplatePath 'Tasks.md') -Raw
    Assert-True ($text.TrimStart() -match '^---') 'the template must open with the configuration frontmatter'

    $config = Get-TaskConfig $text
    Assert-Equal $true $config['create_branch'] 'the template default for create_branch'
    Assert-Equal $false $config['create_pull_request'] 'the template default for create_pull_request'

    foreach ($status in @('draft', 'planning', 'planned', 'in_progress', 'in_review',
                          'changes_requested', 'approved', 'done')) {
        Assert-True ($text -match [regex]::Escape($status)) "the template must name the status '$status'"
    }
    foreach ($priority in @('high', 'medium', 'low')) {
        Assert-True ($text -match [regex]::Escape($priority)) "the template must name the priority '$priority'"
    }

    Assert-True ($text -match '(?m)^##\s+Backlog\s*$') 'the template must have a Backlog heading'
    $after = ($text -split '(?m)^##\s+Backlog\s*$')[1]
    Assert-True (-not ($after -match '(?m)^###\s')) 'the template must hold no backlog entry'
}

Test-Case 'the template and this project do not drift' {
    $template = Get-Content (Get-TemplatePath 'Tasks.md') -Raw
    $mine = Get-Content (Join-Path $root 'docs/tasks/Tasks.md') -Raw

    foreach ($shared in @('draft', 'planning', 'planned', 'in_progress', 'in_review',
                          'changes_requested', 'approved', 'done',
                          'create_branch', 'create_pull_request')) {
        Assert-True ($template -match [regex]::Escape($shared)) "the template is missing '$shared'"
        Assert-True ($mine -match [regex]::Escape($shared)) "this project's Tasks.md is missing '$shared'"
    }
    foreach ($text in @($template, $mine)) {
        Assert-True ($text -match '(?m)^##\s+Backlog\s*$') 'both must have a Backlog heading'
        Assert-True ($text -match 'Priorities') 'both must state the priorities'
    }
}

Test-Case 'the README template points at the plugin, not at itself' {
    $text = Get-Content (Get-TemplatePath 'README.md') -Raw
    foreach ($rule in @('task', '/task:task', '/task:next-task', 'Tasks.md')) {
        Assert-True ($text -match [regex]::Escape($rule)) "the README template must mention '$rule'"
    }
    Assert-True (-not ($text -match 'AGENTS\.md')) 'the README template must not mention AGENTS.md'
}

Test-Case 'the init skill states its two guards' {
    $body = Get-Content (Join-Path $root 'skills/init/SKILL.md') -Raw
    Assert-True ($body -match 'templates') 'the skill must copy the templates'
    Assert-True ($body -match 'overwrite|change nothing|already exists') 'the skill must refuse to overwrite an existing Tasks.md'
    Assert-True ($body -match 'task file') 'the skill must say it writes no task file'
}

Test-Case 'the plugin advertises four skills' {
    $readme = Get-Content (Join-Path $root 'README.md') -Raw
    Assert-True ($readme -match [regex]::Escape('/task:init')) 'README.md must list /task:init'

    $marketplace = Get-JsonFile '.claude-plugin/marketplace.json'
    Assert-True (-not ($marketplace.plugins[0].description -match 'three skills')) 'the marketplace entry still says three skills'
}

Test-Case 'the protocol makes branch: conditional when it creates a task' {
    $body = Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw
    $step = [regex]::Match($body, '(?s)3\. Write `docs/tasks/<slug>\.md`.*?\n\d\. ').Value
    Assert-True ($step.Length -gt 0) 'the Creating a task step that writes the file was not found'
    Assert-True ($step -match 'create_branch') 'that step must make branch: conditional on create_branch'
}


Test-Case 'the implementation transition owns the documentation' {
    $body = (Get-Content (Join-Path $root 'skills/task/SKILL.md') -Raw) -replace "`r`n", "`n"
    # The block runs from the planned heading to the next transition heading, and
    # the phrases are matched across whitespace: the test must not dictate where
    # the prose wraps, nor how many paragraphs a transition takes.
    $step = [regex]::Match($body, '(?s)planned.{0,10}in_progress.{0,4}\*\*(.*?)(?=\n\*\*\x60)').Value
    Assert-True ($step.Length -gt 0) 'the planned to in_progress transition was not found'
    Assert-True ($step -match 'documentation') 'that transition must say the implementation updates the documentation'

    $clean = Get-Content (Join-Path $root 'skills/clean-tasks/SKILL.md') -Raw
    Assert-True ($clean -match 'not\s+this\s+skill') 'clean-tasks must say keeping documentation correct is not its job'
    Assert-True ($clean -match 'never\s+as\s+part\s+of\s+reaching') 'clean-tasks must keep its never-on-your-own guard'
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
