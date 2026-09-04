# NC PERSONAL Radio HUD — stream your own music into Night City

Turns **Apple Music / NetEase Cloud Music** into a real in-game radio station.
Pick **94.7 Piers "Piercer" Random Radio** in the vanilla car / pocket radio list and the game shows what's actually playing — song, artist and album — in a clean right-aligned HUD, plus in the native RADIOPORT Now Playing panel.

## Features
- New personal station in the vanilla radio list: `94.7 Piers "Piercer" Random Radio`
- Live metadata HUD (right side, transparent, wraps, subtitle-class sizing): station · song · artist · album
- Native RADIOPORT popup also shows the real track title
- Works on foot (Z pocket radio) and in vehicles; auto play/pause with radio state
- Apple Music and NetEase Cloud Music supported (Windows SMTC)
- Full CJK glyph coverage + game-flavored Latin font — all fonts free to redistribute (licenses included)
- Includes a one-click installer (`setup.bat`) — no Python required (helper ships as a standalone exe)

## Requirements (install first)
- Cyber Engine Tweaks
- RED4ext
- TweakXL
- redscript
- External Radio 2.1.14 (this package overrides its station-name tweak)

## Install
Unzip anywhere → double-click `setup.bat`. It detects the game folder, checks dependencies, installs the mod, configures fonts (ChineseFull), installs the helper exe and adds optional autostart.
Manual install steps are documented in the README inside the archive.

## Usage
1. Start the helper (`ncp_media_helper.exe`, runs in background, single-instance)
2. Play music in Apple Music, or NetEase Cloud Music — **enable "System Media Control" in NetEase settings**
3. In game, select `94.7 Piers "Piercer" Random Radio`
4. Drive. The HUD tracks every song change.

**Pro tip:** open your music app and press **pause** first, then launch the game — picking the station in-game will then start playback reliably. **Shuffle mode is recommended** (there's no in-game track skipping).

To switch which app gets priority, edit `prefer` in the helper's `config.json` (comma-separated app keywords, tried in order).

## Notes / FAQ
- The install configures CET's ImGui font: Latin = Rajdhani, CJK = HarmonyOS Sans (full glyphs, no tofu). Originals are backed up (`.nc-bak`) — see README to revert.
- This package contains no third-party mod binaries; please install the Requirements above.
- Fonts: Rajdhani (SIL OFL 1.1), HarmonyOS Sans (free for commercial use). Licenses included.



## Supported languages
- **HUD**: Simplified Chinese & English fully supported. The full CJK glyph set also covers Japanese kana and most common Japanese kanji (a few rare/variant glyphs may be missing).
- Track metadata is read as UTF-8 regardless of source language — the song title/artist always arrive; how they render depends on font coverage above.
- The in-game native radio popup uses the game's own localized fonts (limited to the game's language); this HUD is independent and unaffected.
- **Not supported**: Cyrillic/Russian, Greek, etc. (CET merges one language glyph set per session; this mod targets the full-Chinese set.)

## Credits
- Based on External Radio by DrJackieBright; optional coexistence with RadioExt
- Icons/typography: Rajdhani, HarmonyOS Sans, Noto Sans

## Custom radio station name (rename anytime)
The station name is yours to change — no need to touch files:
- During install: the installer asks for a custom name (or press Enter to keep the default).
- Anytime after install: run `rename_station.bat` (or `rename_station.ps1 -StationName "88.8 My Radio"`). Pressing Enter restores the default `94.7 Piers "Piercer" Random Radio`.
- It auto-syncs both places (radio list yaml + HUD), supports Chinese/UTF-8, and validates the name starts with a number + space (e.g. `88.8 My Radio`) so the vanilla radio list keeps sorting correctly. Restart the game to apply.

## Music apps & priority (important)
- Keep **only ONE media app open/playing at a time**, and make sure it exposes **SMTC** (System Media Transport Controls):
  - **Apple Music**: works out of the box.
  - **NetEase Cloud Music**: enable **"System Media Control"** in its settings — without it no media session is registered and nothing will show/control.
  - Browsers (YouTube, etc.) also register a media session.
- The HUD data is picked by the helper's `prefer` list (default `apple,cloudmusic`, edit the helper `config.json` to reorder), but in-game play/pause follows the OS **current** media session — so running a single music app gives predictable behavior.
- If the wrong app gets controlled, pause/close other players or change `prefer`.


## A word from the author

> Due to the author's technical limitations, this mod cannot skip tracks directly in-game — after all, it's a radio (lol). Thank you for your understanding. 🎵
>
> The station's default frequency comes from the author's favourite childhood radio station: **Shanghai Classical Music Radio FM 94.7**.
