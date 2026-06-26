---
name: opencli-browser-automation
description: Use OpenCLI to make websites and browser sessions available as CLI workflows. Use when the user asks Codex to install, configure, diagnose, or use opencli; automate a live Chrome/Chromium page; inspect website state through a browser bridge; interact with web apps that need a real browser session; or use OpenCLI site/app adapters, external CLIs, browser commands, profiles, daemon, doctor, or plugin commands.
---

# Opencli Browser Automation

## Overview

OpenCLI exposes websites, browser tabs, app adapters, and some external tools as command-line interfaces. Prefer it when a task benefits from a real browser session instead of plain HTTP requests, especially for logged-in pages, dynamic DOM state, screenshots, form workflows, or supported site adapters.

## Setup

Check the local installation before using browser commands:

```powershell
opencli --version
opencli doctor
```

Install or update the CLI with npm:

```powershell
npm install -g @jackwener/opencli@latest
```

If `opencli doctor` says the daemon is running but the extension is missing, install the Browser Bridge extension:

1. Download the latest `opencli-extension-v*.zip` from `https://github.com/jackwener/opencli/releases`.
2. Extract it to a stable folder, such as `C:\Users\WIN11\.opencli\extension`.
3. Open `chrome://extensions/`, enable Developer Mode, choose `Load unpacked`, and select the extracted extension folder.
4. Run `opencli daemon restart` and `opencli doctor`.

On this machine, the prepared extension directory is:

```text
C:\Users\WIN11\.opencli\extension
```

## Decision Guide

Use OpenCLI when:

- The user asks to use, configure, diagnose, or automate `opencli`.
- The target website requires JavaScript execution, cookies, login state, or interaction through a real tab.
- A supported adapter exists and can return structured results faster than manual browser automation.
- The task needs browser screenshots, DOM state, form filling, clicking, scrolling, downloads, console logs, or network capture.

Do not use OpenCLI as the first choice when a stable public API, local file operation, or ordinary web search is simpler and more reliable.

## Core Commands

Inspect capabilities:

```powershell
opencli list
opencli <site> --help
opencli <site> --help -f yaml
opencli external list
opencli adapter status
```

Daemon and diagnostics:

```powershell
opencli daemon status
opencli daemon restart
opencli daemon stop
opencli doctor --verbose
```

Browser workflow pattern:

```powershell
opencli browser work open https://example.com
opencli browser work state
opencli browser work click 12
opencli browser work type "Search" "query text"
opencli browser work fill "Email" "user@example.com"
opencli browser work screenshot C:\Users\WIN11\Desktop\opencli-shot.png
opencli browser work extract
opencli browser work close
```

Use a stable session name such as `work`, `research`, or the site name. Reuse the same session name to keep tab state.

## Browser Bridge Notes

If `opencli doctor` reports `Browser Bridge extension not connected`:

- Verify Chrome or Chromium is open.
- Verify the OpenCLI extension is enabled in `chrome://extensions/`.
- Restart the daemon with `opencli daemon restart`.
- If Chrome was already running, close all Chrome processes and reopen Chrome after loading the extension.
- Do not assume browser commands work until `opencli doctor` shows the extension connected.

If command output warns about an existing symlink under `.opencli\node_modules`, treat it as non-blocking when normal commands still run.

## Usage Discipline

Prefer adapter commands over generic browser clicks when a specific site adapter exists. For browser automation, call `state` before click/type/fill so target indices are based on current DOM state. After actions that mutate the page, call `state`, `wait`, `console`, or `screenshot` to verify the result.
