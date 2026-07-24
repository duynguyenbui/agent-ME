# agent-ME - Daily Supportive Agent

agent-Me is a supportive agent designed to assist users across daily workflows, development tasks, and automation based on MCP Servers, Skills, and Rules.

---

## Agent Guidelines & References

All AI agents (**Grok**, **Antigravity**, **Cursor**, **Claude**, etc.) operating in this repository must consult and adhere to the configured rules, skills, and MCP definitions:

### Rules (`.agents/rules/`, `.grok/rules/`)
- **[always-use-correct-operation-command.md](.agents/rules/always-use-correct-operation-command.md)** (or **[.grok/rules/always-use-correct-operation-command.md](.grok/rules/always-use-correct-operation-command.md)**): Dynamically detect the operating system/shell environment (Native Windows/PowerShell vs. WSL vs. macOS/Linux Bash/Zsh) and use appropriate platform commands.
- **[anti-hallucination.md](.agents/rules/anti-hallucination.md)** (or **[.grok/rules/anti-hallucination.md](.grok/rules/anti-hallucination.md)**): Enforce tool-first verification, cite sources, and admit uncertainty to prevent AI hallucinations.

---

### Skills Reference (`.agents/skills/`)

Modular capabilities and specialized domain knowledge available for agents:

- **[exa-search](.agents/skills/exa-search/SKILL.md)**: Web search, page content extraction, and real-time research using the Exa API.
- **[thue-tncn-vietnam](.agents/skills/thue-tncn-vietnam/SKILL.md)**: Tra cứu luật thuế TNCN Việt Nam (Luật 109/2025/QH15 - kỳ tính thuế 2026), hướng dẫn quyết toán, giảm trừ gia cảnh, và quy định cho freelancer / KOL / hộ kinh doanh.
- **[use-required-mcps](.agents/skills/use-required-mcps/SKILL.md)**: Mandatory direct execution of MCP tools without unnecessary code modifications or searches (triggers on explicit user request).
- **[wsl](.agents/skills/wsl/SKILL.md)**: Safe interop between Windows-native tools and WSL environments.

---

### MCP Configuration

- **General Agents**: Defined in [`mcp_config.json`](.agents/mcp_config.json).
- **Grok**: Defined in [`config.toml`](.grok/config.toml).