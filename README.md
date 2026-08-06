# pkgsync

Keeps one directory (`%USERPROFILE%\bin`) full of symlinks to every command-line
binary installed by any of 10 Windows package managers, and keeps that
directory on your User PATH — so you never manually edit PATH after an
install again.

## Supported package managers

winget, Chocolatey, Scoop, npm (global), pnpm, pipx, uv, cargo, gem, `go install`.

A package manager that isn't installed on your machine is silently skipped —
you don't need all 10.

## Requirements

- Windows PowerShell 5.1 or later.
- Creating symlinks normally requires an elevated (admin) PowerShell session.
  `pkgsync` will prompt for elevation via UAC automatically the first time it
  needs to create a symlink and can't.

## Usage

Run this after installing anything with one of the supported package managers:

```powershell
.\pkgsync.ps1
```

Example output:

```
pkgsync: 3 added, 0 conflicts skipped, 1 removed.
Added your bin directory to the User PATH. Open a new terminal for it to take effect.
```

- **added** — new binaries that got a symlink this run.
- **conflicts skipped** — a binary name was already claimed by a different
  package manager's binary; the existing symlink was kept. A warning is
  printed for each one, naming both sources.
- **removed** — symlinks whose target no longer exists (you uninstalled that
  package) were cleaned up automatically.

If it says it added your bin directory to PATH, open a **new** terminal
window — already-open terminals won't see the change (this is a normal
Windows limitation of environment variable propagation, not a bug).

## How it works

Every run re-scans all installed package managers' default binary locations
from scratch and reconciles that against what's currently symlinked in
`%USERPROFILE%\bin`. There's no background service and no state file — it's
just a script you run after installing something.

## Conflict resolution

If two package managers both provide a binary with the same name (e.g.
`python`), whichever one got symlinked first keeps the name. The other is
skipped with a warning. Nothing is overwritten automatically — resolve it by
hand (e.g. delete the unwanted symlink from `%USERPROFILE%\bin` and rerun
`pkgsync`) if you want the other one instead.

## Troubleshooting

- **"Elevation required..." every single run:** enable Developer Mode
  (Settings → Privacy & Security → For Developers) to allow symlink creation
  without admin rights.
- **A binary doesn't run from a new terminal after `pkgsync` reports it was
  added:** confirm `%USERPROFILE%\bin` is on PATH by running `$env:Path` in
  the new terminal; if it's missing, sign out and back in (or reboot) to
  force full environment reload.
