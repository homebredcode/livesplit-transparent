# Makes one exact color in the LiveSplit window fully see-through (a Windows "color key"),
# so the background disappears while text stays solid.
# Set LiveSplit's layout background to a SOLID color that matches -Color.
# Runs as a tray icon; right-click it -> Exit to turn the effect off.
# It also quits by itself when LiveSplit closes.

param(
    [string]$Color = '#010101',
    [string]$LiveSplitPath = '',
    [string]$ProcessName = 'LiveSplit'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

function Show-Error([string]$msg) {
    [System.Windows.Forms.MessageBox]::Show($msg, 'LiveSplit transparency', 'OK', 'Error') | Out-Null
}

# Only one copy at a time
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\LiveSplitTransparent', [ref]$created)
if (-not $created) { exit }

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class LayeredWin {
    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW")] static extern IntPtr GetWindowLongPtr(IntPtr h, int index);
    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW")] static extern IntPtr SetWindowLongPtr(IntPtr h, int index, IntPtr value);
    [DllImport("user32.dll")] static extern bool SetLayeredWindowAttributes(IntPtr h, uint key, byte alpha, uint flags);
    [DllImport("user32.dll")] static extern bool GetLayeredWindowAttributes(IntPtr h, out uint key, out byte alpha, out uint flags);
    [DllImport("user32.dll")] static extern bool InvalidateRect(IntPtr h, IntPtr rect, bool erase);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);

    const int GWL_EXSTYLE = -20;
    const long WS_EX_LAYERED = 0x80000;
    const uint LWA_COLORKEY = 1, LWA_ALPHA = 2;

    // Adds the color key, keeping LiveSplit's own opacity setting. Returns true if it changed anything.
    public static bool Apply(IntPtr h, uint key) {
        long ex = GetWindowLongPtr(h, GWL_EXSTYLE).ToInt64();
        byte alpha = 255;
        if ((ex & WS_EX_LAYERED) != 0) {
            uint curKey, flags; byte a;
            if (GetLayeredWindowAttributes(h, out curKey, out a, out flags)) {
                if ((flags & LWA_COLORKEY) != 0 && curKey == key) return false;
                if ((flags & LWA_ALPHA) != 0) alpha = a;
            }
        } else {
            SetWindowLongPtr(h, GWL_EXSTYLE, new IntPtr(ex | WS_EX_LAYERED));
        }
        SetLayeredWindowAttributes(h, key, alpha, LWA_COLORKEY | LWA_ALPHA);
        return true;
    }

    // Takes the color key off again (keeps LiveSplit's opacity if it uses one).
    public static void Remove(IntPtr h) {
        long ex = GetWindowLongPtr(h, GWL_EXSTYLE).ToInt64();
        if ((ex & WS_EX_LAYERED) == 0) return;
        uint key, flags; byte alpha;
        if (GetLayeredWindowAttributes(h, out key, out alpha, out flags) && (flags & LWA_ALPHA) != 0 && alpha < 255) {
            SetLayeredWindowAttributes(h, 0, alpha, LWA_ALPHA);
        } else {
            SetWindowLongPtr(h, GWL_EXSTYLE, new IntPtr(ex & ~WS_EX_LAYERED));
        }
        InvalidateRect(h, IntPtr.Zero, true);
    }
}
'@

# "#RRGGBB" -> COLORREF (0x00BBGGRR)
if ($Color -notmatch '^#?([0-9a-fA-F]{6})$') {
    Show-Error "Color must look like #010101 (got '$Color')."
    exit 1
}
$hex = $Matches[1]
$r = [Convert]::ToUInt32($hex.Substring(0, 2), 16)
$g = [Convert]::ToUInt32($hex.Substring(2, 2), 16)
$b = [Convert]::ToUInt32($hex.Substring(4, 2), 16)
$key = [uint32]($r -bor ($g -shl 8) -bor ($b -shl 16))

if ($LiveSplitPath -and -not (Get-Process $ProcessName -ErrorAction SilentlyContinue)) {
    if (-not (Test-Path $LiveSplitPath)) {
        Show-Error "LiveSplit not found at:`n$LiveSplitPath"
        exit 1
    }
    Start-Process $LiveSplitPath -WorkingDirectory (Split-Path $LiveSplitPath)
}

$icon = [System.Drawing.SystemIcons]::Application
if ($LiveSplitPath -and (Test-Path $LiveSplitPath)) {
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($LiveSplitPath)
}

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = $icon
$tray.Text = "LiveSplit transparency ($Color)"
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$exitItem = $menu.Items.Add('Exit (turn transparency off)')
$tray.ContextMenuStrip = $menu
$tray.Visible = $true

$script:handles = @{}
$script:seenLiveSplit = $false

function Stop-Transparency {
    $timer.Stop()
    foreach ($h in $script:handles.Keys) {
        if ([LayeredWin]::IsWindow($h)) { [LayeredWin]::Remove($h) }
    }
    $tray.Visible = $false
    $tray.Dispose()
    [System.Windows.Forms.Application]::Exit()
}

# LiveSplit resets the window when its opacity changes, so re-apply every second
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $procs = @(Get-Process $ProcessName -ErrorAction SilentlyContinue)
    if ($procs.Count -eq 0) {
        if ($script:seenLiveSplit) { Stop-Transparency }
        return
    }
    foreach ($p in $procs) {
        $h = $p.MainWindowHandle
        if ($h -ne [IntPtr]::Zero) {
            $script:seenLiveSplit = $true
            $script:handles[$h] = $true
            [LayeredWin]::Apply($h, $key) | Out-Null
        }
    }
})
$exitItem.Add_Click({ Stop-Transparency })

$timer.Start()
[System.Windows.Forms.Application]::Run()
$mutex.ReleaseMutex()
