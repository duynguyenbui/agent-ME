---
name: always-use-correct-operation-command
description: Dynamically detect whether running on native Windows (PowerShell/CMD), WSL, macOS, or Linux before executing commands; use environment-appropriate shell commands and prioritize built-in agent tools.
---

# Environment-Aware Command Execution Guidelines

When interacting with the system or proposing terminal commands, agents must first **detect and identify the host operating system and active shell environment** (Windows native, WSL, macOS, or Linux) rather than unconditionally assuming a single environment.

---

## 1. OS & Shell Detection Guidelines

Before executing or proposing any command:

1. **Inspect Environment Indicators**:
   - **Native Windows**: Check for `OS=Windows_NT`, `COMSPEC`, `$PSVersionTable`, `SystemRoot`, or Windows drive paths (`C:\...`).
   - **WSL (Windows Subsystem for Linux)**: Check for `WSL_DISTRO_NAME`, `/proc/version` containing `microsoft`, or `/mnt/c/` path structures.
   - **macOS / Linux Native**: Check for `Darwin`/macOS, standard Linux distributions, POSIX paths (`/Users/...`, `/home/...`).

---

## 2. Environment-Specific Execution Rules

### Case A: Native Windows Environment (PowerShell by Default)
When running directly on Windows:
- **Default to PowerShell**: Assume PowerShell syntax unless CMD is explicitly requested.
- **File System Operations**: Use PowerShell native cmdlets or Windows commands:
  - `Copy-Item` / `copy` instead of `cp`
  - `Remove-Item` / `del` / `rmdir` instead of `rm -rf`
  - `Move-Item` / `move` instead of `mv`
  - `New-Item -ItemType Directory` or `mkdir` instead of `mkdir -p`
  - `Test-Path` instead of `test -e`
- **Text Processing & Search**: Do NOT use Unix-specific tools like `grep`, `sed`, `awk`, or `cat` in raw Windows terminal commands. Use:
  - `Select-String` (for `grep`)
  - `Get-Content` (for `cat`)
  - Object filtering via `Where-Object`
- **Path Separators & Executables**: Use backslashes (`\`) for native Windows paths and binaries.
- **Environment Variables**: Use PowerShell `$env:VAR_NAME` (or `%VAR_NAME%` in CMD) instead of `$VAR_NAME` or `${VAR_NAME}`.
- **Execution Policy**: If a script execution is blocked, use `powershell -ExecutionPolicy Bypass -File <script>`.

### Case B: WSL (Windows Subsystem for Linux)
When running within WSL:
- Use native Linux shell (Bash/Zsh) and standard Unix utilities.
- When crossing filesystem boundaries or invoking Windows-native executables, use `.exe` extensions (e.g., `cmd.exe /c`, `powershell.exe -Command`, `explorer.exe`) and reference Windows drives via `/mnt/c/`.

### Case C: Native macOS / Linux Environment
When running on macOS or Linux:
- Use native POSIX shell commands (Bash/Zsh): `ls`, `cp`, `rm`, `mv`, `mkdir -p`, `grep`, `cat`, `find`.
- Use `$VAR_NAME` or `${VAR_NAME}` for environment variables.
- Use forward slashes (`/`) for paths.

---

## 3. Tool Preference (Highest Priority)

Across **all platforms** (Windows, WSL, macOS, Linux):
- Always prioritize built-in agent file and search tools (`view_file`, `grep_search`, `find_by_name`, `list_dir`, `write_to_file`, `replace_file_content`) over executing raw terminal commands whenever possible.
