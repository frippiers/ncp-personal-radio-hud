# Build instructions — ncp_media_helper.exe

The bundled `ncp_media_helper.exe` is built from `ncp_media_helper.py` with
PyInstaller (Python 3.12, Windows x64). No obfuscation, no extra payloads.

## Steps
1. Install Python 3.12 (x64) for Windows.
2. Install dependencies:
   pip install winsdk pyinstaller
3. Build:
   python -m PyInstaller --noconfirm --onefile --noconsole ^
     --name ncp_media_helper ^
     --hidden-import winsdk ^
     --hidden-import winsdk.windows ^
     --hidden-import winsdk.windows.media.control ^
     ncp_media_helper.py
4. Output: dist\ncp_media_helper.exe  (≈20 MB, single file, no install)

## What it does
- Polls the Windows SMTC (System Media Transport Controls) session
  (Apple Music / NetEase Cloud Music), writes current track metadata to
  media.json for the in-game HUD.
- Watches cmd.json to play/pause/skip via SMTC.
- Single-instance via a localhost port lock; reads side config.json.
- Pure Python + Windows Runtime API via winsdk (no network, no admin).
