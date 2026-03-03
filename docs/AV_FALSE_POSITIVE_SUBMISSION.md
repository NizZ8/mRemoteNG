# AV False Positive Submission — Templates & Materials

## Quick Reference

| Vendor | Submission URL | Expected Response |
|--------|---------------|-------------------|
| **BitDefender** | [bitdefender.com/consumer/support/answer/29358](https://www.bitdefender.com/consumer/support/answer/29358/) | 24-48h |
| **Windows Defender** | [microsoft.com/wdsi/filesubmission](https://www.microsoft.com/en-us/wdsi/filesubmission) | 24-72h |
| **ESET** | [support.eset.com/en/kb141](https://support.eset.com/en/kb141/) | 48-72h |
| **Kaspersky** | [opentip.kaspersky.com](https://opentip.kaspersky.com/) | 48-72h |
| **VirusTotal** | [virustotal.com](https://www.virustotal.com/) | Shared with all engines |

---

## Email Template (BitDefender)

**To:** virus_submission@bitdefender.com
**Subject:** False Positive Report — mRemoteNG (IL:Trojan.MSILZilla.212190)

---

Dear BitDefender Virus Lab,

I am reporting a **false positive detection** on mRemoteNG, an open-source multi-protocol remote connections manager for Windows.

**Detection details:**
- **Detection name:** `IL:Trojan.MSILZilla.212190`
- **File:** `mRemoteNG.dll` (main application assembly)
- **Product version:** 1.82.0-beta.1
- **SHA256:** `4080c9c2bf99a9a6a3c71f71311268d1d2bef83bc06990479c319c07129acb10` (nightly ZIP)

**Why this is a false positive:**

mRemoteNG is a well-known open-source project (2,700+ GitHub stars, 10+ years of active development) that manages RDP, SSH, VNC, and other remote connections. The APIs that trigger heuristic detection are **required for core functionality**:

| API | Legitimate Use in mRemoteNG |
|-----|----------------------------|
| `SendInput` (user32.dll) | Releases stuck modifier keys (Ctrl/Alt/Shift) after RDP session disconnect |
| `CryptProtectData` (DPAPI) | Encrypts saved connection credentials using Windows Data Protection API |
| COM Interop (`MSTSCLib`) | Controls the Microsoft RDP ActiveX component (built into Windows) |
| `Assembly.LoadFrom()` | Loads satellite assemblies for localization and NuGet packages from app directory |
| Multiple P/Invoke | Window management, clipboard operations, focus handling — standard WinForms patterns |

**Verification:**
- **Source code:** https://github.com/mRemoteNG/mRemoteNG (upstream, GPL v2)
- **Fork with CI:** https://github.com/robertpopa22/mRemoteNG
- **Nightly release:** https://github.com/robertpopa22/mRemoteNG/releases/tag/nightly
- **CI workflow:** Builds are reproducible via GitHub Actions — anyone can verify by building from source
- **Code signing:** SignPath Foundation signing is being implemented (free for open source)

**Attached:** `mRemoteNG-nightly.zip` (password: `infected`)

Please review and remove this false positive detection. This affects all users of mRemoteNG who use BitDefender.

Thank you for your time.

Best regards,
[Your Name]
mRemoteNG Contributor

---

## Web Form Template (Windows Defender / WDSI)

**URL:** https://www.microsoft.com/en-us/wdsi/filesubmission

**Steps:**
1. Select **"Software developer"** role
2. Select **"Incorrectly detected as malware/malicious (false positive)"**
3. Upload the flagged file or provide the nightly ZIP URL
4. In the description field, paste:

```
mRemoteNG is an open-source (GPL v2) multi-protocol remote connections manager
for Windows, actively developed for 10+ years with 2,700+ GitHub stars.

Repository: https://github.com/mRemoteNG/mRemoteNG
Fork (CI/nightly builds): https://github.com/robertpopa22/mRemoteNG
License: GPL v2

The flagged APIs (SendInput, DPAPI CryptProtectData, COM Interop for RDP ActiveX,
Assembly.LoadFrom for localization) are all required for the application's core
remote desktop management functionality. These are standard Windows APIs used
as documented by Microsoft.

We are in the process of implementing Authenticode code signing via SignPath
Foundation (free for open source projects).
```

---

## Preparing the Submission Package

### Get SHA256 of latest nightly

```powershell
# Download and hash
$url = "https://github.com/robertpopa22/mRemoteNG/releases/download/nightly/mRemoteNG-nightly-20260302-v1.82.0-beta.1-45612ed-x64.zip"
Invoke-WebRequest -Uri $url -OutFile nightly.zip
certutil -hashfile nightly.zip SHA256
```

### Create password-protected ZIP for email submission

```powershell
# Extract nightly, re-zip with password "infected"
Expand-Archive nightly.zip -DestinationPath nightly-extracted
# Use 7-Zip to create password-protected archive
& "C:\Program Files\7-Zip\7z.exe" a -p"infected" -tzip submission.zip .\nightly-extracted\mRemoteNG.dll
```

### Upload to VirusTotal first

Upload the nightly ZIP to https://www.virustotal.com/ before submitting to vendors. Include the VirusTotal scan URL in all submissions — this gives vendors immediate context about other engines' verdicts.

---

## APIs Justification Reference

For detailed technical documentation of each API and why it's required, see:
- [`docs/ANTIVIRUS_FALSE_POSITIVE.md`](ANTIVIRUS_FALSE_POSITIVE.md) — user-facing guide
- [`CODE_SIGNING_POLICY.md`](../CODE_SIGNING_POLICY.md) — signing policy

## After Submission

1. **Track responses** — most vendors respond within 24-72 hours
2. **Re-scan on VirusTotal** after vendor confirms fix — detection count should drop
3. **Note:** Each new build produces a new hash. Signed builds accumulate SmartScreen reputation automatically, making future FP reports less necessary
4. **Long-term fix:** Authenticode signing via SignPath Foundation (in progress) dramatically reduces heuristic scores
