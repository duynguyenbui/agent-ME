# PowerShell Interop Reference

## Restore the Windows PATH

`pwsh.exe -NoProfile` is predictable, but it does not run profile scripts that might repair missing per-user `PATH` entries. When a Windows-side tool is installed but cannot be found, rebuild `PATH` from the Windows registry before invoking it:

```powershell
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = @($machinePath, $userPath) -join ";"
```

If only one known directory is required, append that directory instead of rebuilding the entire value:

```powershell
$env:Path += ";$env:USERPROFILE\.cargo\bin"
```

## Protect PowerShell Variables from Bash

Bash parses a `pwsh.exe -Command` payload before PowerShell receives it. Wrap the complete payload in Bash single quotes when it contains `$name` or `$env:NAME`, and use PowerShell double quotes inside the payload as needed:

```bash
pwsh.exe -NoLogo -NoProfile -Command '$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine"); $userPath = [Environment]::GetEnvironmentVariable("Path", "User"); $env:Path = @($machinePath, $userPath) -join ";"; cargo --version'
```

Do not wrap that payload in Bash double quotes unless Bash expansion is intentional.

## Initialize Another Windows Environment Variable

Read registry-backed variables explicitly when a Windows command launched from WSL needs them:

```powershell
$env:FOO = [Environment]::GetEnvironmentVariable("FOO", "User")
```

Use PowerShell double quotes when the assigned string must expand variables such as `$env:USERPROFILE`; use single quotes for literal strings.
