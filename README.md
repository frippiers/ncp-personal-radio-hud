# NC PERSONAL Radio HUD (v1.0)

把 **Apple Music / 网易云音乐** 的播放信息（歌名/歌手/专辑）送进《赛博朋克 2077》的原生电台界面。

- 游戏电台列表新增个人电台 **94.7 Piers "Piercer" Random Radio**
- 开车/随身收音机场景，屏幕右侧显示：电台名 + 歌曲 + 歌手 + 专辑（右对齐、可换行、透明背景）
- 游戏原生 RADIOPORT 弹窗的 NOW PLAYING 也会显示真实歌名
- 支持 Apple Music 与 网易云音乐（通过 Windows 系统媒体会话 SMTC）
- 中文全量字形 + 游戏风格拉丁字体（全免费许可，可再分发）

## 前置依赖（先装好，Nexus 下载）

| Mod | Nexus | 必需 |
|---|---|---|
| Cyber Engine Tweaks (CET) | nexus 107 | ✅ |
| RED4ext | nexus 2380 | ✅ |
| TweakXL | nexus 4197 | ✅ |
| redscript | nexus 1511 | ✅ |
| **External Radio 2.1.14** | nexus 3741 | ✅（本包会覆盖它的电台改名 yaml） |

安装顺序：RED4ext → CET → TweakXL → redscript → External Radio → **本 mod**。

## 安装

**推荐（自动安装器）**：解压本包 → 双击 `setup.bat`
它会自动：定位游戏目录 → 校验依赖 → 安装 mod 文件 → 配置字体（中文全量）→ 安装媒体助手 exe 到 `%LOCALAPPDATA%\NCPersonalRadio` → 写配置 → 开机自启。

**手动**（可选）：
1. 把 `game\` 内文件按路径放进游戏根目录（覆盖 `r6\tweaks\CP77-External-Radio.yaml` 前先备份原文件）
2. 把 `companion\ncp_media_helper.exe` 放到任意固定目录，并在同目录创建 `config.json`：
   ```json
   {"out":"<游戏目录>\\bin\\x64\\plugins\\cyber_engine_tweaks\\mods\\NCPersonal\\media.json",
    "cmd":"<同上目录>\\cmd.json","prefer":"apple,cloudmusic"}
   ```
3. 字体（让 HUD 中文/日文正常显示）：
   - 备份 `bin\x64\plugins\cyber_engine_tweaks\fonts\NotoSans-Regular.ttf` 和 `NotoSansTC-Regular.otf`
   - 用 `fonts\Latin-Rajdhani-Regular.ttf` 覆盖前者；用 `fonts\CJK-HarmonyOS-SC-Regular.ttf` 覆盖后者
   - 在 `...\cyber_engine_tweaks\config.json` 中设置 `font.language = "ChineseFull"`
4. 运行 `ncp_media_helper.exe`（或让它开机自启）

## 修改电台名称（可选）
台名存放在**两处，必须完全一致**：
1. `r6/tweaks/CP77-External-Radio.yaml` → `displayName`
2. `.../mods/NCPersonal/init.lua` 顶部 → `STATION_NAME`
规则：以**「数字 + 空格」开头**（如 `94.7 My Radio`），避免与 RadioExt 电台列表排序冲突；两处都改后**重启游戏**。

## 重要提醒：一次只开一个音乐软件 + 开启 SMTC
- **同一时间只保留一个音乐软件运行**（Apple Music 或 网易云，二选一）。游戏内播放/暂停控制系统的「当前媒体会话」，多开可能控制错对象。
- Apple Music 自带 SMTC；网易云需开启**设置 → 系统媒体控制**并重启客户端。
- 助手按旁 `config.json` 的 `prefer` 顺序取元数据（默认 `apple,cloudmusic`，可调）。

## 随时改台名（无需重装）
双击 `rename_station.bat`（或 `rename_station.ps1 -StationName "88.8 My Radio"`），
自动同步电台列表 + HUD 两处；名字须以「数字+空格」开头，改完重启游戏。

## 使用

1. 先启动媒体助手（`ncp_media_helper.exe`，托盘无界面）
2. 打开 Apple Music 或 网易云音乐并播放
   - 网易云需开启设置里的「系统媒体控制」
3. 进游戏，在车载/随身电台列表选择 **94.7 Piers "Piercer" Random Radio**
   - 会通过 Windows 媒体会话自动播放/暂停当前音乐 App
4. 屏幕右侧显示当前曲目信息，切歌自动更新

想切换优先控制的 App：编辑 helper 旁 `config.json` 的 `prefer`（逗号分隔关键词，按顺序匹配）。

## 卸载

1. 删除 `%LOCALAPPDATA%\NCPersonalRadio` 与启动文件夹里的 "NCPERSONAL Media Helper.lnk"
2. 游戏内删除 `bin\x64\plugins\cyber_engine_tweaks\mods\NCPersonal`
3. 还原 `r6\tweaks\CP77-External-Radio.yaml.bak`（或重装 External Radio）
4. 还原字体：`.nc-bak` 后缀备份文件复制回原名
5. 可选：`config.json` 的 `font.language` 改回 `"Default"`

## 许可与致谢

- 本 mod 原创部分：可自由分发（注明出处即可）
- 电台集成基于 **External Radio** (DrJackieBright, Nexus 3741) 与 **RadioExt**（可选共存），请尊重原作者许可
- 字体：Rajdhani (SIL OFL 1.1)、HarmonyOS Sans (免费商用，见 `fonts\` 下 LICENSE)、Noto Sans (OFL)
- Windows SMTC 控制使用 winsdk (Python) / 原生 WinRT

> 注意：包内不含 External Radio / CET 等第三方二进制，请按上表自行安装。


## 修改电台名称
电台列表显示的名字由**两处定义（必须一致）**：
1. `r6/tweaks/CP77-External-Radio.yaml` 的 `displayName`
2. `bin/x64/plugins/cyber_engine_tweaks/mods/NCPersonal/init.lua` 的 `STATION_NAME`（HUD）

命名建议以「数字+空格」开头（如 `94.7 My Radio`），电台列表才能正常排序；改完重启游戏生效。

## 音乐软件与优先级（重要提醒）
- **同一时间最好只运行一个音乐软件并保持播放**，且该软件必须支持 **SMTC**（Windows 系统媒体会话）：
  - **Apple Music**：默认支持
  - **网易云音乐**：必须在其设置里开启「**系统媒体控制**」——不开启不会注册媒体会话，将无法显示/控制
  - 浏览器（YouTube 等）也会注册媒体会话
- HUD 显示的曲目由助手的 `prefer` 顺序决定（默认 `apple,cloudmusic`，改 helper 旁 `config.json` 可调整）；但游戏内播放/暂停跟随系统「当前」媒体会话——**同时只开一个音乐软件**行为才可控
- 若控制到错误的应用：暂停/关闭其它播放器，或调整 `prefer`

---

## Customizing the station name
The name shown in the radio list is defined in **two places that must match**:
1. `r6/tweaks/CP77-External-Radio.yaml` → `displayName`
2. `bin/x64/plugins/cyber_engine_tweaks/mods/NCPersonal/init.lua` → `STATION_NAME` (HUD)

Keep the name starting with a number + space (e.g. `94.7 My Radio`) so the radio list keeps working. Restart the game afterwards.

## Music apps & priority (important)
- Keep **only ONE media app open/playing at a time**, and make sure it exposes **SMTC** (System Media Transport Controls):
  - **Apple Music**: works out of the box.
  - **NetEase Cloud Music**: enable **"System Media Control"** in its settings — without it no media session is registered and nothing will show/control.
  - Browsers (YouTube, etc.) also register a media session.
- The HUD data is picked by the helper's `prefer` list (default `apple,cloudmusic`, edit the helper `config.json` to reorder), but in-game play/pause follows the OS **current** media session — so running a single music app gives predictable behavior.
- If the wrong app gets controlled, pause/close other players or change `prefer`.
