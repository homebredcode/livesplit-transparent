# LiveSplit Transparent

Makes the [LiveSplit](https://livesplit.org/) background fully see-through on your own screen, while the text stays solid. Good for keeping your splits on top of the game without a box behind them.

LiveSplit's own **Opacity** setting fades the whole window, text included. This tool uses a Windows "color key" instead: every pixel of one exact color in the LiveSplit window becomes invisible, and everything else stays as it is.

- Windows only (uses Windows PowerShell 5.1, which comes with Windows 10/11)
- No install, no admin rights, nothing changed in LiveSplit itself
- Runs as a small tray icon and quits by itself when LiveSplit closes

> Only want the transparency on your stream, not on your own screen? You don't need this. Use a **Color Key** filter on the LiveSplit window capture in OBS.

## Setup

### 1. Get the files

Download this repo (green **Code** button → **Download ZIP**) and unzip it, or clone it:

```
git clone https://github.com/homebredcode/livesplit-transparent.git
```

### 2. Tell it where LiveSplit is

Pick one:

- **Easiest:** copy `livesplit-transparent.ps1` and `Start LiveSplit (transparent).cmd` into your LiveSplit folder (next to `LiveSplit.exe`).
- **Or:** keep the files where they are and create a file called `livesplit-path.txt` next to them, containing only the full path to `LiveSplit.exe`, for example:
  ```
  C:\Games\LiveSplit\LiveSplit.exe
  ```

### 3. Set the background color in LiveSplit

1. Right-click LiveSplit → **Edit Layout…** → **Layout Settings** → **Layout** tab.
2. **Background:** choose a solid color (not a gradient) and set it to **R 1, G 1, B 1** (`#010101`), alpha 255.
3. Set the background of components that draw their own (Title, Splits, Timer, Previous Segment, …) to fully transparent, or to the same `#010101`.
4. Click **OK** and save the layout (right-click → **Save Layout**).

### 4. Start it

Double-click **`Start LiveSplit (transparent).cmd`**.

- If LiveSplit isn't running, it starts it.
- If LiveSplit is already running, it just adds the transparency (no second LiveSplit).
- The background disappears within a second.

To turn it off: right-click the tray icon → **Exit**, or just close LiveSplit.

## Tips

- **Why `#010101` and not pure black?** Text shadows and outlines are usually pure black. With black as the key color they would disappear too.
- **Keep text readable:** in **Layout Settings**, turn on **Drop Shadows** or give **Text Outline** a solid black color. White text with no outline gets lost over bright parts of the game.
- **The edges of the text get a thin dark rim.** That's the anti-aliasing blending into `#010101`, and over a game it looks like an outline. A bright key color (e.g. magenta) would give a colored fringe instead, so a near-black one is the best choice.
- **Clicks go through the see-through parts.** To drag LiveSplit or open its right-click menu, click on the text.
- **Opacity still works.** If you also lower LiveSplit's own Opacity setting, the text fades and the background stays invisible.

## Using a different key color

Change the `COLOR` line in `Start LiveSplit (transparent).cmd`:

```
set "COLOR=#010101"
```

and set the same color as the background in LiveSplit. It has to match exactly.

You can also run the script directly:

```
powershell -NoProfile -ExecutionPolicy Bypass -File livesplit-transparent.ps1 -Color "#010101" -LiveSplitPath "C:\Games\LiveSplit\LiveSplit.exe"
```

`-LiveSplitPath` is optional. Without it, the script waits for LiveSplit to be started some other way.

## How it works

Every second, the script finds the LiveSplit window and gives it a layered-window color key (`SetLayeredWindowAttributes` with `LWA_COLORKEY`), keeping whatever opacity LiveSplit already uses. It checks again every second because LiveSplit resets the window when its opacity setting changes. On exit it removes the color key again.

`-ExecutionPolicy Bypass` is there because Windows blocks unsigned `.ps1` scripts by default. It only applies to this one launch and doesn't change any system setting.

## Troubleshooting

| What you see | Fix |
| --- | --- |
| Background still visible | The background color isn't exactly `#010101`, or it's a gradient. Check **Layout Settings** and each component's background. |
| Error "LiveSplit not found" | Check `livesplit-path.txt`, or put the files next to `LiveSplit.exe`. |
| Nothing happens | Look for the tray icon (it may be hidden under the `^` arrow). Only one copy runs at a time. |
