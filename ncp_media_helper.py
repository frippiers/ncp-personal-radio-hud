# -*- coding: utf-8 -*-
"""
NC PERSONAL media helper v2
 - polls SMTC (Apple Music preferred) -> media.json (for in-game HUD)
 - watches cmd.json -> executes play/pause/toggle/next/previous on Apple
Usage:
  python ncp_media_helper.py --out <media.json> [--cmd <cmd.json>]
"""
import argparse, asyncio, json, os, sys, time

import socket
_LOCK_PORT = 47771
_lock_sock = None

def _acquire_lock():
    global _lock_sock
    _lock_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        _lock_sock.bind(("127.0.0.1", _LOCK_PORT))
        _lock_sock.listen(1)
        return True
    except OSError:
        return False

if not _acquire_lock():
    raise SystemExit("already running")


try:
    from winsdk.windows.media.control import (
        GlobalSystemMediaTransportControlsSessionManager as GsmTcsMgr,
    )
except ImportError:
    raise SystemExit("winsdk missing. Run: python -m pip install winsdk")

PLAYING = 4
PREFERS = ["apple", "cloudmusic", "music"]
_names = ["Closed", "Opened", "Changing", "Stopped", "Playing", "Paused"]

def _status(s):
    try: return _names[int(s)]
    except Exception: return str(s)

def _pick_session(manager, prefers):
    """Return the first session whose app id matches any prefer keyword (in order),
    falling back to the current session."""
    try:
        all_s = list(manager.get_sessions())
    except Exception:
        all_s = []
    for kw in prefers:
        for s in all_s:
            try:
                aid = (s.source_app_user_model_id or "") or ""
            except Exception:
                aid = ""
            if kw.lower() in aid.lower():
                return s
    if all_s:
        # prefer the actively playing one if no keyword matched
        for s in all_s:
            try:
                if int(s.get_playback_info().playback_status) == PLAYING:
                    return s
            except Exception:
                pass
    try:
        return manager.get_current_session()
    except Exception:
        return None

async def _do_cmd(manager, cmd):
    s = _pick_session(manager, PREFERS)
    if s is None:
        return False
    try:
        if cmd == "play":
            await s.try_play_async()
        elif cmd == "pause":
            await s.try_pause_async()
        elif cmd == "toggle":
            await s.try_toggle_play_pause_async()
        elif cmd == "next":
            await s.try_skip_next_async()
        elif cmd == "previous":
            await s.try_skip_previous_async()
        else:
            return False
        return True
    except Exception:
        return False

async def run(out_path, cmd_path, interval=0.35):
    manager = await GsmTcsMgr.request_async()
    last_key = None
    last_cmd_id = None

    while True:
        # --- media poll -> out ---
        entry = {"app": "", "playing": False, "status": "", "title": "", "artist": "", "album": "", "ts": int(time.time())}
        try:
            s = _pick_session(manager, PREFERS)
            if s is not None:
                try: entry["app"] = s.source_app_user_model_id or ""
                except Exception: pass
                try:
                    pb = s.get_playback_info()
                    entry["playing"] = int(pb.playback_status) == PLAYING
                    entry["status"] = _status(pb.playback_status)
                except Exception: pass
                try:
                    props = await s.try_get_media_properties_async()
                    entry["title"] = props.title or ""
                    entry["artist"] = props.artist or ""
                    entry["album"] = props.album_title or ""
                except Exception: pass
        except Exception:
            pass
        key = (entry["app"], entry["title"], entry["artist"], entry["album"], entry["playing"])
        if key != last_key:
            last_key = key
            try:
                tmp = out_path + ".tmp"
                with open(tmp, "w", encoding="utf-8") as fh:
                    json.dump(entry, fh, ensure_ascii=False)
                os.replace(tmp, out_path)
            except Exception:
                pass

        # --- command channel ---
        if cmd_path:
            try:
                with open(cmd_path, "r", encoding="utf-8") as fh:
                    raw = fh.read().strip()
                if raw:
                    data = json.loads(raw)
                    c = data.get("cmd", "")
                    cid = data.get("id")
                    if c and cid != last_cmd_id:
                        last_cmd_id = cid
                        await _do_cmd(manager, c)
                        # clear so the sender can confirm
                        with open(cmd_path, "w", encoding="utf-8") as fh:
                            json.dump({"cmd": "", "id": cid}, fh)
            except Exception:
                pass

        await asyncio.sleep(interval)

def _load_side_config():
    """Read config.json placed next to this script/exe (optional)."""
    cfg = {}
    if getattr(sys, "frozen", False):
        base = os.path.dirname(os.path.abspath(sys.executable))
    else:
        base = os.path.dirname(os.path.abspath(__file__))
    cfgp = os.path.join(base, "config.json")
    try:
        with open(cfgp, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        for k in ("out", "cmd", "prefer", "interval"):
            if k in data:
                cfg[k] = data[k]
    except Exception:
        pass
    return cfg

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=None)
    ap.add_argument("--cmd", default=None)
    ap.add_argument("--interval", type=float, default=None)
    ap.add_argument("--prefer", default=None,
                    help="comma-separated app keywords, tried in order")
    a = ap.parse_args()
    side = _load_side_config()

    out = a.out or side.get("out")
    if not out:
        raise SystemExit("No output path. Pass --out or put config.json next to this file.")
    cmd_path = a.cmd or side.get("cmd")
    interval = a.interval if a.interval is not None else float(side.get("interval", 0.35))
    prefer = a.prefer or side.get("prefer", "apple,cloudmusic")

    global PREFERS
    PREFERS = [x.strip() for x in str(prefer).split(",") if x.strip()]
    asyncio.run(run(out, cmd_path, interval))

if __name__ == "__main__":
    main()
