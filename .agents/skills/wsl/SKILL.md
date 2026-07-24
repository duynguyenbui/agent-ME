---
name: wsl
description: Safely run Windows-native tools from WSL and transfer minimal artifacts across the Linux/Windows filesystem boundary. Use when invoking pwsh.exe, cmd.exe, or another Windows executable from WSL; when a Windows program must consume a path supplied from WSL; or when diagnosing Windows environment initialization for such a command. Do not use for Linux-only work merely because it runs under WSL.
---

# WSL–Windows Interop

## Boundary Decision

- Keep Linux-only workflows entirely inside WSL.
- Use Windows-native tools only when the task requires Windows-side behavior or state.
- Keep files on the filesystem native to the tool that opens them. When a Windows program needs Linux-produced input, stage only the required artifacts on the Windows filesystem and collect only the required results.

## Rules

- Use `pwsh.exe` for Windows-only shell automation. Invoke a specific Windows executable directly when no PowerShell orchestration is needed.
- Keep the executable, script, and files opened directly by a Windows program on the Windows filesystem by default.
- Do not execute Windows programs against `\\wsl$`, `\\wsl.localhost`, or other Linux-native UNC paths by default.
- Treat `wslpath` only as a path-format converter. Use it for files already stored on the Windows filesystem; do not use it as a substitute for staging a Linux-native file.
- If the user explicitly requests direct UNC access and the Windows program is known to support it, explain the tradeoff and limit the access to the smallest required scope.
- Before passing a command through Bash into PowerShell, protect PowerShell variables from Bash expansion.
- Do not assume a Windows process launched from WSL receives the same per-user environment as an interactive Windows session.

## PowerShell Details

Read [references/powershell-interop.md](references/powershell-interop.md) only when:

- a Windows-side tool is installed but missing from `PATH`;
- a `pwsh.exe -Command` payload contains PowerShell variables; or
- a Windows registry-backed environment variable must be initialized explicitly.
