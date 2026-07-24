<#
.SYNOPSIS
  Exa API CLI — search, extract contents, and get LLM answers via the Exa API.
.DESCRIPTION
  Cross-platform PowerShell port of the bash exa CLI.
  Supports three subcommands: search, contents, answer.
.PARAMETER Command
  The subcommand: search, contents, or answer.
.PARAMETER Args
  Remaining arguments (flags + query/URL).
.EXAMPLE
  .\exa.ps1 search "latest AI chip launches"
  .\exa.ps1 search --category news --start-date 2026-01-01 "Apple"
  .\exa.ps1 contents --max-chars 3000 "https://example.com"
  .\exa.ps1 answer "What is the latest version of Kubernetes?"
#>

param(
  [Parameter(Position = 0)]
  [string]$Command = "",

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

# ── Help ─────────────────────────────────────────────────
function Show-Help {
  $name = "exa.ps1"
  Write-Host "$name – Exa API CLI`n"
  Write-Host "Commands:"
  Write-Host "  $name search [flags] <query>       Web search with optional filters"
  Write-Host "  $name contents [flags] <url>        Extract page content"
  Write-Host "  $name answer <question>             Quick LLM answer with citations"
  Write-Host "`nAPI key: set `$env:EXA_API_KEY or write to `$HOME\.config\exa-api-key"
}

if (-not $Command -or ($Command -eq "--help" -or $Command -eq "-h")) {
  Show-Help
  exit 0
}

# ── API key ──────────────────────────────────────────────
function Resolve-ApiKey {
  $key = $env:EXA_API_KEY
  if ($key) { return $key }

  $configFile = Join-Path $HOME ".config" "exa-api-key"
  if (Test-Path $configFile) {
    return (Get-Content $configFile -Raw).Trim()
  }

  Write-Error "Missing EXA_API_KEY. Place it in `$HOME\.config\exa-api-key or set `$env:EXA_API_KEY."
  exit 1
}

# ── JSON helpers ─────────────────────────────────────────
function Merge-Hashtable {
  param([hashtable]$Base, [hashtable]$Overlay)
  $result = $Base.Clone()
  foreach ($kv in $Overlay.GetEnumerator()) {
    $result[$kv.Key] = $kv.Value
  }
  return $result
}

# ── sub: search ──────────────────────────────────────────
function Invoke-Search {
  param([string[]]$Positional)

  $query = ""
  $type = ""; $category = ""; $num = 8; $include = ""; $exclude = ""
  $startDate = ""; $endDate = ""
  $text = $false; $summary = $false; $highlights = $true
  $systemPrompt = ""; $maxAge = ""

  $i = 0
  while ($i -lt $Positional.Length) {
    $arg = $Positional[$i]
    switch -Regex ($arg) {
      '^--type$'         { $i++; $type = $Positional[$i] }
      '^--category$'     { $i++; $category = $Positional[$i] }
      '^--num-results$'  { $i++; $num = [int]$Positional[$i] }
      '^--include$'      { $i++; $include = $Positional[$i] }
      '^--exclude$'      { $i++; $exclude = $Positional[$i] }
      '^--start-date$'   { $i++; $startDate = $Positional[$i] }
      '^--end-date$'     { $i++; $endDate = $Positional[$i] }
      '^--text$'         { $text = $true }
      '^--summary$'      { $summary = $true }
      '^--highlights$'   { $highlights = $true }
      '^--no-highlights$'{ $highlights = $false }
      '^--system$'       { $i++; $systemPrompt = $Positional[$i] }
      '^--live$'         { $i++; $maxAge = if ($i -lt $Positional.Length -and $Positional[$i] -notmatch '^--') { $Positional[$i] } else { $i--; "0" } }
      '^--max-age$'      { $i++; $maxAge = $Positional[$i] }
      default            { $query = $arg; break }
    }
    $i++
  }

  if (-not $query) {
    Write-Error "Usage: exa.ps1 search [flags] <query>"
    exit 1
  }

  $apiKey = Resolve-ApiKey

  $body = @{ query = $query; numResults = $num } | ConvertTo-Json -Compress | ConvertFrom-Json
  $body = $body | ConvertTo-Json -Compress | ConvertFrom-Json  # ensure it's a PSObject

  # Build body as hashtable
  $payload = @{ query = $query; numResults = $num }
  if ($type)     { $payload.type = $type }
  if ($category) { $payload.category = $category }
  if ($startDate){ $payload.startPublishedDate = $startDate }
  if ($endDate)  { $payload.endPublishedDate = $endDate }
  if ($systemPrompt) { $payload.systemPrompt = $systemPrompt }
  if ($include)  { $payload.includeDomains = $include -split ',' }
  if ($exclude)  { $payload.excludeDomains = $exclude -split ',' }
  if ($maxAge)   { $payload.maxAgeHours = [int]$maxAge }

  $contentsObj = @{}
  if ($highlights) { $contentsObj.highlights = $true }
  if ($text)       { $contentsObj.text = $true }
  if ($summary)    { $contentsObj.summary = $true }
  if ($contentsObj.Count -gt 0) { $payload.contents = $contentsObj }

  $jsonBody = $payload | ConvertTo-Json -Depth 10 -Compress

  $response = Invoke-RestMethod -Uri 'https://api.exa.ai/search' `
    -Method Post `
    -Headers @{ 'x-api-key' = $apiKey; 'Content-Type' = 'application/json' } `
    -Body $jsonBody

  $output = @{
    requestId = $response.requestId
    results = $response.results | ForEach-Object {
      @{
        title = $_.title
        url = $_.url
        publishedDate = $_.publishedDate
        author = $_.author
        text = $_.text
        highlights = $_.highlights
        summary = $_.summary
      }
    }
    costDollars = $response.costDollars
  }
  return $output | ConvertTo-Json -Depth 10
}

# ── sub: contents ────────────────────────────────────────
function Invoke-Contents {
  param([string[]]$Positional)

  $url = ""
  $includeText = $true; $includeHighlights = $true; $includeSummary = $true
  $maxChars = ""; $subpages = ""; $maxAge = ""; $timeout = ""

  $i = 0
  while ($i -lt $Positional.Length) {
    $arg = $Positional[$i]
    switch -Regex ($arg) {
      '^--text$'         { $includeText = $true }
      '^--no-text$'      { $includeText = $false }
      '^--highlights$'   { $includeHighlights = $true }
      '^--no-highlights$'{ $includeHighlights = $false }
      '^--summary$'      { $includeSummary = $true }
      '^--no-summary$'   { $includeSummary = $false }
      '^--max-chars$'    { $i++; $maxChars = [int]$Positional[$i] }
      '^--subpages$'     { $i++; $subpages = [int]$Positional[$i] }
      '^--live$'         { $i++; $maxAge = if ($i -lt $Positional.Length -and $Positional[$i] -notmatch '^--') { [int]$Positional[$i] } else { $i--; 0 } }
      '^--max-age$'      { $i++; $maxAge = [int]$Positional[$i] }
      '^--timeout$'      { $i++; $timeout = [int]$Positional[$i] }
      default            { $url = $arg }
    }
    $i++
  }

  if (-not $url) {
    Write-Error "Usage: exa.ps1 contents [flags] <url>"
    exit 1
  }

  $apiKey = Resolve-ApiKey

  $payload = @{ urls = @($url) }

  if ($includeText) {
    if ($maxChars) { $payload.text = @{ maxCharacters = $maxChars } }
    else           { $payload.text = $true }
  }
  if ($includeHighlights) { $payload.highlights = $true }
  if ($includeSummary)    { $payload.summary = $true }
  if ($maxAge)   { $payload.maxAgeHours = $maxAge }
  if ($timeout)  { $payload.livecrawlTimeout = $timeout }
  if ($subpages) { $payload.subpages = $subpages }

  $jsonBody = $payload | ConvertTo-Json -Depth 10 -Compress

  $response = Invoke-RestMethod -Uri 'https://api.exa.ai/contents' `
    -Method Post `
    -Headers @{ 'x-api-key' = $apiKey; 'Content-Type' = 'application/json' } `
    -Body $jsonBody

  $output = @{
    requestId = $response.requestId
    results = $response.results | ForEach-Object {
      @{
        title = $_.title
        url = $_.url
        publishedDate = $_.publishedDate
        author = $_.author
        text = $_.text
        highlights = $_.highlights
        summary = $_.summary
        subpages = $_.subpages
      }
    }
    statuses = $response.statuses
    costDollars = $response.costDollars
  }
  return $output | ConvertTo-Json -Depth 10
}

# ── sub: answer ──────────────────────────────────────────
function Invoke-Answer {
  param([string[]]$Positional)

  $query = $Positional -join ' '

  if (-not $query) {
    Write-Error "Usage: exa.ps1 answer <question>"
    exit 1
  }

  $apiKey = Resolve-ApiKey

  $payload = @{ query = $query; text = $true }
  $jsonBody = $payload | ConvertTo-Json -Compress

  $response = Invoke-RestMethod -Uri 'https://api.exa.ai/answer' `
    -Method Post `
    -Headers @{ 'x-api-key' = $apiKey; 'Content-Type' = 'application/json' } `
    -Body $jsonBody

  $output = @{
    requestId = $response.requestId
    answer = $response.answer
    citations = $response.citations | ForEach-Object {
      @{
        title = $_.title
        url = $_.url
        publishedDate = $_.publishedDate
      }
    }
  }
  return $output | ConvertTo-Json -Depth 10
}

# ── Dispatch ─────────────────────────────────────────────
switch ($Command.ToLower()) {
  'search'   { Invoke-Search -Positional $Args }
  'contents' { Invoke-Contents -Positional $Args }
  'answer'   { Invoke-Answer -Positional $Args }
  default {
    Write-Error "Unknown command: $Command"
    Show-Help
    exit 1
  }
}
