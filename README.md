# DefControl

A console (CMD) utility to turn **Windows Defender** real-time protection **on and off** from a simple menu — a scriptable, open-source take on the classic "Defender Control" idea.

It uses only official Windows mechanisms (the `Set-MpPreference` cmdlet and the documented Defender Group Policy registry keys). Nothing is hidden, nothing is obfuscated, and it requires Administrator rights — exactly like the built-in Windows tools it drives.

> **Why would you turn Defender off?** Temporarily, for things like benchmarking, debugging a false-positive that quarantines your own builds, or installing a tool you trust that Defender keeps blocking. Turn it back on when you're done. Running without antivirus is a real risk — this is a convenience switch, not a recommendation to stay unprotected.

---

## Features

- **One-key disable / enable** of Defender real-time protection
- **Live status readout** — real-time state, Tamper Protection state, and policy state
- **Self-elevating** — relaunches itself as Administrator automatically
- **Honest about Tamper Protection** — detects it and tells you exactly what it blocks
- **Pure batch** — no install, no dependencies, one file

---

## Requirements

- Windows 10 or Windows 11
- Administrator account (the script will prompt to elevate)
- PowerShell (ships with Windows) — used for the Defender cmdlets

---

## Install

Download or clone the repo:

```cmd
git clone https://github.com/yksaionara/DefControl.git
cd DefControl
```

That's it — there's nothing to build. The whole program is `DefControl.cmd`.

---

## Tutorial

### 1. Launch it

Double-click **`DefControl.cmd`**, or run it from a terminal:

```cmd
DefControl.cmd
```

A User Account Control (UAC) prompt appears asking for Administrator rights. Click **Yes** — Defender can only be changed by an administrator, so this is required.

### 2. Read the status panel

When the menu opens, the top of the screen shows the current state:

```
   Real-time protection : True
   Tamper Protection    : False
   Policy (AntiSpyware) : not set
```

| Field | Meaning |
|-------|---------|
| **Real-time protection** | `True` = Defender is actively scanning. `False` = it's off. |
| **Tamper Protection** | `True` = Windows is locking antivirus settings (see step 5). |
| **Policy (AntiSpyware)** | `DISABLED by policy` = the durable registry switch is set. |

### 3. Disable Defender

Press **`1`** and Enter. The tool will:

1. Try the **live switch** (`Set-MpPreference -DisableRealtimeMonitoring $true`) for an instant effect.
2. Write the **policy registry keys** under
   `HKLM\SOFTWARE\Policies\Microsoft\Windows Defender`, which keep Defender off across reboots.

It then re-reads and shows you the new status.

### 4. Enable Defender

Press **`2`** and Enter. The tool removes the policy keys and flips the live switch back on. Status refreshes so you can confirm `Real-time protection : True`.

### 5. If Tamper Protection is ON

Tamper Protection is a Microsoft safeguard that **blocks any program** (including this one, and Sordum's, and even Microsoft's own cmdlets) from changing real-time protection while it's on. This is by design and **cannot be scripted around** — Microsoft deliberately requires a human at the Security app.

The tool detects it and tells you. To turn it off:

- Press **`4`** to open **Windows Security → Virus & threat protection → Manage settings**, or
- Open **Windows Security** manually and toggle **Tamper Protection** off.

With Tamper Protection off, disable/enable take effect immediately. (The policy keys are written either way and apply after a reboot.)

### 6. Menu reference

| Key | Action |
|-----|--------|
| `1` | Disable Windows Defender |
| `2` | Enable Windows Defender |
| `3` | Refresh status |
| `4` | Open Windows Security (to toggle Tamper Protection) |
| `0` | Exit |

---

## How it works

DefControl is a thin, readable wrapper around two official interfaces:

**1. The Defender PowerShell module** — the live, immediate switch:

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true    # off
Set-MpPreference -DisableRealtimeMonitoring $false   # on
```

**2. Group Policy registry keys** — the durable switch that survives reboots:

```
HKLM\SOFTWARE\Policies\Microsoft\Windows Defender
    DisableAntiSpyware = 1
HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection
    DisableRealtimeMonitoring = 1
    DisableBehaviorMonitoring = 1
    DisableOnAccessProtection = 1
    DisableScanOnRealtimeEnable = 1
```

Enabling Defender deletes those keys and sets the preferences back to `$false`. Status is read with `Get-MpComputerStatus`.

---

## FAQ

**Antivirus flags this file — is it malware?**
No. Tools that toggle Defender are commonly flagged by heuristics precisely *because* they toggle Defender, regardless of intent. The source is a single plain-text batch file you can read top to bottom — there's no payload. Inspect `DefControl.cmd` yourself.

**It says disabled but Defender is still running.**
Tamper Protection is on. See step 5 — turn it off, then try again.

**Does this permanently remove Defender?**
No. It only toggles real-time protection and sets reversible policy keys. Option `2` fully restores everything.

---

## License

MIT — see [LICENSE](LICENSE).

## Disclaimer

Provided as-is, for use on machines you own or administer. Disabling antivirus has security consequences; you are responsible for re-enabling it. The authors are not liable for any damage or infection resulting from use of this tool.
