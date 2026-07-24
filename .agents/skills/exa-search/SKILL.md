---
name: exa-search
description: Search the web and extract page contents via the Exa API. Use for general web search, fact-checking, documentation lookup, GitHub/code research, news, company/product/person research, and reading/summarizing URLs. Supports filters (type, category, date, domain), deep search, and LLM answers with citations.
---

# Exa Search Skill

## CLI

### Unix (bash)
```bash
~/.agents/skills/exa-search/exa <command> [flags] <query-or-url>
```

### Windows (PowerShell)
```powershell
~/.agents/skills/exa-search/exa.ps1 <command> [flags] <query-or-url>
```

| Command | Purpose |
|---------|---------|
| `search <query>` | Web search with highlights (default 8 results) |
| `contents <url>` | Extract page content (text + highlights + summary by default) |
| `answer <question>` | Quick LLM-generated answer with citations |

### search flags

| Flag | Values / Example |
|------|------------------|
| `--type` | `auto` (default), `neural`, `fast`, `deep`, `deep-reasoning`, `instant` |
| `--category` | `news`, `company`, `research paper`, `people`, `personal site`, `financial report` |
| `--num-results` | `15` (max 100) |
| `--include` / `--exclude` | `arxiv.org,paperswithcode.com` (comma-separated) |
| `--start-date` / `--end-date` | `2025-01-01` (ISO 8601) |
| `--text` / `--summary` | Include full text or LLM summary (adds cost) |
| `--no-highlights` | Skip highlights (on by default) |
| `--system` | System prompt for deep search |
| `--live [hours]` | `--live` = always fresh; `--live 24` = cache if < 24h old |

### contents flags

| Flag | Description |
|------|-------------|
| `--no-text` / `--no-highlights` / `--no-summary` | Toggle content modes (all on by default) |
| `--max-chars` | `5000` — limit text length |
| `--subpages` | `5` — crawl linked subpages |
| `--live [hours]` | Freshness control; `--live 24` = cache if < 24h |
| `--timeout` | `15000` — livecrawl timeout in ms |

### Examples

```bash
# Basic search
exa search "latest AI chip launches"

# News with date filter
exa search --category news --start-date 2026-01-01 "Apple"

# Research papers only
exa search --category "research paper" --num-results 5 "transformer architectures"

# Deep search with system prompt
exa search --type deep --system "Prefer official sources" "Claude API pricing"

# Highlights only from a URL (most token-efficient)
exa contents --no-text --no-summary "https://example.com/long-page"

# Deep extraction with subpages
exa contents --max-chars 3000 --subpages 3 "https://docs.example.com"

# Quick answer
exa answer "What is the latest version of Kubernetes?"
```

## Rules

- API key: `EXA_API_KEY` env var or `~/.config/exa-api-key` (Unix) / `$HOME\.config\exa-api-key` (Windows). Never print it.
- Search first. Use `contents` only for the most relevant URLs.
- For latest/current questions, use `--live` and compare `publishedDate`.
- For technical questions, use `--include` to restrict to official docs / GitHub / arXiv.
- For news, cross-check with ≥2 independent sources.
- Summarize findings and include source URLs. Don't paste raw full-page text unless asked.
- If results are weak, refine the query and retry with different flags.
