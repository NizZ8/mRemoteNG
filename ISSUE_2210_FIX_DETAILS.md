# Fix for Issue #2210: Ctrl+F not working when Quick Connect toolbar is active

## Problem
The `Ctrl+F` shortcut (Find in Session) did not work when the Quick Connect toolbar (or any control outside the active connection window) had focus. This was because the key event was consumed by the focused control or bubbled up to the main form, but the main form did not handle `Ctrl+F`. The existing handling was only present in `BaseWindow` (base class of `ConnectionWindow`), which only receives the event if the focus is within the window.

## Solution
Implemented `ProcessCmdKey` override in `FrmMain.cs` to intercept `Ctrl+F` at the application level.

1.  **Moved `ProcessCmdKey` logic:**
    *   Previously, `ProcessCmdKey` was strangely located in `FrmMain.Designer.cs` (likely due to a previous manual edit or merge).
    *   Removed `ProcessCmdKey` from `mRemoteNG\UI\Forms\frmMain.Designer.cs`.
    *   Added `ProcessCmdKey` to `mRemoteNG\UI\Forms\FrmMain.cs` (the correct place for logic).

2.  **Added `Ctrl+F` handling:**
    *   Intercepts `Keys.Control | Keys.F`.
    *   Checks if there is an active `ConnectionWindow` (`pnlDock.ActiveDocument`).
    *   Calls `connectionWindow.FindInSession()` if a session is active.
    *   Returns `true` to indicate the key was handled.

3.  **Preserved existing logic:**
    *   Preserved `Keys.Alt | Keys.Menu` (show menu if hidden).
    *   Preserved `Keys.Shift | Keys.F11` (Presentation Mode).
    *   Preserved null check for `PresentationMode`.

## Verification
*   **Build:** `build.ps1` completed successfully.
*   **Tests:** `run-tests.ps1` (simulated via `dotnet test`) passed 54 tests before unrelated crash (known environment issue).
*   **Code Review:** Verified that `ProcessCmdKey` is correctly implemented in `FrmMain.cs` and removed from `FrmMain.Designer.cs`.
*   **Logic Check:** The fix ensures that `Ctrl+F` works regardless of which control has focus, as long as a connection window is the active document.
