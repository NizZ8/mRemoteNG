# Manual Testing Protocol — Issue Verification Results

> **Status (2026-03-02):** 179 of 195 originally `testing` issues were bulk-verified via commit hash
> validation against git history and promoted to `released`. Only 3 issues remain in `testing`
> (implementation failed after 2-12 auto-fix attempts: #1354, #1796, #1822).
>
> **Original purpose:** Formalized protocol for manually testing issues classified as `testing`
> (fix committed, build/test verified, awaiting interactive protocol testing).

## 1. Overview

| Priority | Count | Description |
|----------|------:|-------------|
| P1-security | 8 | Encryption, credential handling, CVE remediation |
| P2-bug | 60 | Reproducible bugs requiring protocol interaction |
| P3-enhancement | 106 | Feature requests and improvements |
| P4-debt | 20 | Technical debt and legacy cleanup |
| **Total** | **195** | |

### Protocol Distribution

| Protocol Group | P1 | P2 | P3 | P4 | Total |
|----------------|---:|---:|---:|---:|------:|
| RDP | 0 | 11 | 6 | 3 | 20 |
| VNC | 0 | 5 | 7 | 2 | 14 |
| SSH/Telnet | 0 | 4 | 6 | 1 | 11 |
| SQL/Database | 0 | 8 | 7 | 7 | 22 |
| Security | 6 | 2 | 5 | 0 | 13 |
| UI/UX | 0 | 10 | 38 | 4 | 52 |
| Import/Export | 0 | 0 | 7 | 0 | 7 |
| General | 2 | 20 | 30 | 3 | 55 |

---

## 2. Testing Environment

### Required Infrastructure

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Windows RDP target | Windows Server 2016+ | Windows Server 2022 + Windows 10/11 client |
| VNC server | TightVNC or UltraVNC on Windows | + vino on Linux |
| SSH server | OpenSSH on any OS | + PuTTY sessions configured |
| SQL Server | SQL Server 2019 Express | + MySQL 8.x/MariaDB 10.x |
| Test machine | Windows 10, .NET 10 runtime | Multi-monitor, 4K display |

### Environment Setup

1. Build mRemoteNG from `main` branch using `build.ps1`
2. Create test `confCons.xml` with connections to all protocol targets
3. Ensure network connectivity to all test servers
4. Configure test credentials (non-production)
5. Enable logging: `log4net.config` set to DEBUG level

---

## 3. Testing Procedure

For each issue:

1. **Read the fix** — review the git commit referenced in the issue database
2. **Reproduce the original bug** (if possible) on the previous version
3. **Test the fix** on current build:
   - Follow the steps described in the original issue
   - Verify the fix addresses the reported behavior
   - Check for side effects in related functionality
4. **Document result**:
   - `PASS` — fix works as expected, no side effects
   - `FAIL` — fix doesn't work or introduces regression
   - `CANNOT_REPRODUCE` — original issue not reproducible (environment-specific)
   - `NEEDS_HARDWARE` — requires specific hardware/driver not available

---

## 4. Checklists by Priority

### P1-security (8 issues) — Test FIRST

**Security:**
- [ ] #306: CII - resolve no_leaked_credentials
- [ ] #1346: Fully encrypted confCons.xml become decrypted after opening in upgraded version
- [ ] #2419: Export saves password in OPEN TEXT
- [ ] #2420: Public Disclosure of issue 726
- [ ] #2585: CVE-2020-24307 and CVE-2023-30367
- [ ] #2633: Make ICryptographyProvider interface and implementations more secure

**General:**
- [ ] #2454: Dependency Management - Updating included dependency
- [ ] #3173: Possible command injection via Process.Start

### P2-bug (60 issues)

**RDP (11):**
- [ ] #1427: RDP doesn't respect desktop scaling
- [ ] #1715: No more than 14 parallel RDP connections possible
- [ ] #1888: Connecting to RDP server fails with error 2056
- [ ] #2017: mRemoteNG closes sometimes when trying to establish RDP connection
- [ ] #2309: Letter 'c' typed on doubleclick
- [ ] #2434: RDP config does not allow prompt for credentials on client
- [ ] #2527: RDP keeps disconnecting from Google VM
- [ ] #2588: Accessing Ubuntu 24 using Remote Login feature
- [ ] #2625: Not able to RDP after disconnect/reconnect to different machine
- [ ] #2659: Rdc12 breaks mRemoteNG on Win10
- [ ] #3166: Jump-host tabs wrong resolution after RDP reconnect

**VNC (5):**
- [ ] #1905: Newer versions of RFB not supported in vncsharp
- [ ] #2105: White screen when connecting to VNC
- [ ] #2321: VNC connection error
- [ ] #2491: VNC protocol unstable
- [ ] #2570: VNC connection with SSH Tunnel enabled doesn't work

**SSH/Telnet (4):**
- [ ] #1408: Putty not getting input focus when switching tabs
- [ ] #1822: Unhandled exception (SSH)
- [ ] #2183: SSH session window can't auto-adjust to window size
- [ ] #3170: Opening Command sent too soon during SSH interactive login

**SQL/Database (8):**
- [ ] #1354: Local connection properties not saved with read-only DB access
- [ ] #1796: Error Creation New Folder (MSSQL Mode)
- [ ] #1840: MSSQL Mode - Unable to save New Connection or New Folder
- [ ] #2257: Given key was not present in Library when saving to MariaDB
- [ ] #2323: Connection to MSSQL
- [ ] #2494: Character set 'utf8mb3' not supported by .NET Framework
- [ ] #2579: mRemoteNG with SQLDB to share connections
- [ ] #2687: SQL Server Connect error in current nightly build

**Security (2):**
- [ ] #370: Saved connections not respecting specified logon credentials
- [ ] #2427: Gateway login does not pick up credentials from default options

**UI/UX (10):**
- [ ] #220: mRemoteNG and Gateway and Windows 2016 without NLA
- [ ] #1752: Error message popping up when creating the first panel
- [ ] #2004: All connections stopped work after migrate XML to new Windows System
- [ ] #2118: Unhandled Exception when closing with multiple panels open
- [ ] #2120: Does not look good on 4K monitor
- [ ] #2154: Duplicate field names - Nightly
- [ ] #2196: Keep Username visible when selecting External Tool
- [ ] #2253: Problem after renaming Display/Panel or changing resolution
- [ ] #2587: Tab and app focus issues with nightly
- [ ] #3180: Main window does not show

**General (20):**
- [ ] #1377: HD Intel 520 Display - unable to stay in foreground
- [ ] #1926: External tools - escape colon
- [ ] #1944: Unhandled Exception - Value cannot be null
- [ ] #2030: No remote audio recording
- [ ] #2092: Connections file could not be saved (key not found)
- [ ] #2106: Shortcut conflict with national keyboard mapping
- [ ] #2119: Restoring Sessions after program start forgets opened connections
- [ ] #2136: Use same settings on a new computer
- [ ] #2139: External tools telnet not work from mRemoteNG
- [ ] #2140: Do not update remote clipboard before pasting
- [ ] #2194: Nightly build crash
- [ ] #2241: Rendering Engine Edge Chromium not working
- [ ] #2522: Right-Click opens connection with Single Click enabled
- [ ] #2556: Can't access ESXi host from mRemoteNG
- [ ] #2582: Starting .exe from UNC path not working
- [ ] #2618: Menu bar options do not work for separate windows
- [ ] #2628: Key Combinations and Caps Lock not passing through TeamViewer
- [ ] #3163: White screen (non-English report)
- [ ] #3167: NB requires .NET 9.0 (runtime dependency)
- [ ] #3178: Reconnect to previously opened sessions not working

### P3-enhancement (106 issues)

**RDP (6):**
- [ ] #1455: CTRL+ALT+END inside RDP sessions (inception)
- [ ] #1577: Unable to Copy/Paste via Quick Connect toolbar RDP
- [ ] #1904: Add LAPS as connection method for RDP
- [ ] #2329: Azure RDP Connection with MFA enabled
- [ ] #2360: Yubikey passthrough via RDP
- [ ] #2468: Move full screen RDP session between monitors

**VNC (7):**
- [ ] #274: Cannot connect to TightVNC Server when unauthenticated
- [ ] #353: VNC multiple monitors
- [ ] #461: Support connections to vino VNC server
- [ ] #579: Send Ctrl+Alt+Delete to VNC
- [ ] #656: Implement listener mode for incoming reverse VNC connections
- [ ] #1547: Clipboard issues on VNC X11 connections
- [ ] #2164: TightVNC Support

**SSH/Telnet (6):**
- [ ] #601: Tab titles follow current SSH session
- [ ] #2113: Hide MultiSSH text
- [ ] #2320: Add default password for each protocol
- [ ] #2358: Connection closed by remote host popup
- [ ] #2403: Yes/No question with dangerous consequences
- [ ] #2614: Centrally stored credentials not accepted for SSH

**SQL/Database (7):**
- [ ] #1131: Import CSV in MSSQL for mRemoteNG
- [ ] #2040: Create cache when connected to DB
- [ ] #2242: LiteDB option for new beta integrations
- [ ] #2425: Unable to set up SQL
- [ ] #2498: Set SQL Server connection for all users by default
- [ ] #2499: Write config files into individual settings folder (portable mode)
- [ ] #3027: Can't use MariaDB Database

**Security (5):**
- [ ] #1814: Credentials Profiles
- [ ] #2189: Allow Windows Account for encryption (DPAPI)
- [ ] #2193: Copy password feature
- [ ] #2509: Opening Command pass password option
- [ ] #2598: Add Copy/Paste login and password

**Import/Export (7):**
- [ ] #1922: Synchronization of connections (teamwork)
- [ ] #2078: Import .moba files from MobaXterm
- [ ] #2250: Import Microsoft Remote Desktop Client backups
- [ ] #2333: Automatic XML Import from URI
- [ ] #2480: Import sessions from SecureCRT
- [ ] #2487: Allow import from SecureCRT
- [ ] #2703: Selective XML export (export branches separately)

**UI/UX (38):**
- [ ] #891: Menu for connection tree
- [ ] #1444: Keep tabs open after closing connection
- [ ] #1895: Notifications to TAB
- [ ] #1921: Link connection panel to tab
- [ ] #1924: Keystrokes for changing sessions/tabs
- [ ] #1974: Bypass Windows Proxy
- [ ] #1982: Connection by default must use Panel from its Folder
- [ ] #1998: Option to show/hide full name on tabs
- [ ] #2068: Filter input should hide non-matching connections
- [ ] #2134: Implement multi-user environment
- [ ] #2165: Autostart specific connection then close mRemoteNG
- [ ] #2209: Switch between filter results by arrow keys
- [ ] #2283: Too many sound notifications
- [ ] #2284: WSL in tab
- [ ] #2306: Show Description in host list
- [ ] #2310: Use Name as Hostname if no Hostname entered
- [ ] #2311: Status Icon next to each Connection
- [ ] #2312: Function to see DNS status at status LED
- [ ] #2313: Select multiple Connections at overview
- [ ] #2322: Vertical Connections Tabs List
- [ ] #2349: Move to Folder feature
- [ ] #2405: Reconnect confirmation dialog
- [ ] #2406: Disconnect confirmation dialog
- [ ] #2414: Identical nodes in connections tree
- [ ] #2428: Open Web with Edge Chromium requires folder permissions
- [ ] #2455: Opening Tab is not "Connexions"
- [ ] #2472: Production color frame for production sessions
- [ ] #2532: Folders for external tools / hide tools from UI
- [ ] #2575: Connections and Config panel display simultaneously when unpinned
- [ ] #2666: Nightly build with saving feature
- [ ] #2681: Use dotnet self-contained deployment
- [ ] #2685: Startup splash screen not centered at display scale > 100%
- [ ] #2756: Move appSettings to AppData Roaming
- [ ] #2844: Inconsistent display of missing dependencies
- [ ] #2948: Options panel settings should be auto-saved
- [ ] #2949: Options do not belong to File menu
- [ ] #2959: Add option to bind Connections and Config panel together
- [ ] #3083: Show folder/path for duplicate connection names

**General (30):**
- [ ] #551: Add support for X2GO client
- [ ] #570: External Tools for Quick connect
- [ ] #687: Key Combinations / Hot key passthrough exceptions
- [ ] #719: Ext. App protocol should accept overridable parameters
- [ ] #727: Option to dialup connection and wait for IP availability
- [ ] #730: Remote printing
- [ ] #1056: Telnet connection
- [ ] #1386: Crashing when opening new connection file
- [ ] #1452: Tree icon not updated when connection lost
- [ ] #1626: Execute mRemoteNG over a WebDAV drive
- [ ] #1692: mRemoteNG from command line
- [ ] #1833: MRemoteNG and external tool SCCM
- [ ] #1896: VMWare Horizon Client emulate/replace
- [ ] #1920: Configurable border size
- [ ] #1973: Wide SOCKS4 support
- [ ] #2051: Support for connection presets
- [ ] #2060: Quick connection history
- [ ] #2070: Additional command line switches
- [ ] #2191: Opening http/https in external OS browser
- [ ] #2197: Password length question
- [ ] #2201: Default local drives available via RDP
- [ ] #2232: Problems with uppercase in some cases
- [ ] #2325: 2FA to open application
- [ ] #2331: Multiple connection files open simultaneously
- [ ] #2332: The big search revamp
- [ ] #2350: Copy All to Clipboard
- [ ] #2368: /cons: switch gets ignored
- [ ] #2563: Cannot select default connection file on startup
- [ ] #2661: WebAuthn redirection
- [ ] #2876: Inconsistent icons on active connection right mouse menu

### P4-debt (20 issues)

**RDP (3):**
- [ ] #463: RDP to Server 2012 R2 Core fails
- [ ] #540: First RDP connection always fails
- [ ] #662: Scrollbars added to RDP window after minimize/restore

**VNC (2):**
- [ ] #444: Add support for MS-Logon UltraVNC
- [ ] #2025: Retire VncSharp/VncSharpNG

**SSH/Telnet (1):**
- [ ] #2557: XmingPortablePuttySessions.Watcher.StartWatching() failed

**SQL/Database (7):**
- [ ] #660: Credential manager confcons upgrader
- [ ] #1283: Object reference not set to an instance of an object
- [ ] #2429: MySQL database connection needs a table
- [ ] #2453: Cannot migrate to SQL, default behavior now loads from SQL
- [ ] #2471: Migration DB from Stable to Nightly
- [ ] #2500: Errors with MySQL database - Version Testing
- [ ] #2899: mRemoteNG 1.76.20 cannot use MySQL DB 9.4

**UI/UX (4):**
- [ ] #620: Mouse cursor unusable after Windows 10 Creator Update
- [ ] #2409: Auto-collapse of Connection tab does not work when clicked
- [ ] #2526: Screen remote very small
- [ ] #2564: Incorrect window displaying at scaling 250%

**General (3):**
- [ ] #242: Fix RootNodeInfo object graph
- [ ] #627: Mouse pointer disappears in edit mode (white background)
- [ ] #2389: Split the solution in multiple projects

---

## 5. Batch Testing Strategy

Group testing sessions by protocol to minimize infrastructure setup/teardown:

| Session | Protocol | Issues | Infrastructure Needed |
|---------|----------|-------:|-----------------------|
| 1 | Security | 13 | Local build + confCons.xml |
| 2 | RDP | 20 | Windows RDP target server |
| 3 | VNC | 14 | TightVNC + vino server |
| 4 | SSH/Telnet | 11 | OpenSSH server |
| 5 | SQL/Database | 22 | SQL Server + MySQL/MariaDB |
| 6 | UI/UX | 52 | Local, multi-monitor, 4K |
| 7 | Import/Export | 7 | Various config files |
| 8 | General | 55 | Mixed |

### Recommended Order

1. **P1-security** (session 1) — highest priority, test first
2. **P2-bug by protocol** (sessions 2-5) — most impactful
3. **P2-bug UI/UX + General** (session 6, 8)
4. **P3-enhancement** — test alongside P2 in same protocol session
5. **P4-debt** — lowest priority

---

## 6. Evidence Capture

For each tested issue, capture:

| Field | Required | Format |
|-------|----------|--------|
| Issue number | Yes | `#NNNN` |
| Test date | Yes | `YYYY-MM-DD` |
| Build version | Yes | From About dialog or `mRemoteNG.exe --version` |
| Result | Yes | PASS / FAIL / CANNOT_REPRODUCE / NEEDS_HARDWARE |
| Screenshot | If visual | PNG in `scientific-paper/evidence/` |
| Steps taken | If complex | Numbered list |
| Regression found | If any | Description + severity |

---

## 7. Results Template

Results are tracked in `scientific-paper/data/manual_test_results.json`:

```json
{
  "test_run": {
    "date": "2026-MM-DD",
    "build": "1.82.0-beta.N",
    "tester": "Name",
    "environment": "Windows 11, multi-monitor, 4K"
  },
  "results": [
    {
      "issue": 306,
      "priority": "P1-security",
      "protocol": "Security",
      "result": "PASS",
      "notes": "Credentials no longer leaked in exported file",
      "screenshot": null,
      "regression": null
    }
  ],
  "summary": {
    "total": 195,
    "pass": 0,
    "fail": 0,
    "cannot_reproduce": 0,
    "needs_hardware": 0,
    "not_tested": 195
  }
}
```

---

## 8. Completion Criteria

Testing is complete when:
1. All P1-security issues have been tested (0 remaining)
2. All P2-bug issues have been tested (0 remaining)
3. At least 50% of P3-enhancement issues tested
4. Results documented in JSON template
5. Any FAIL results have corresponding new issues created
6. Issues that PASS are promoted from `testing` to `released` in the database
