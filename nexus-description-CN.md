# NC PERSONAL Radio HUD — 把你的音乐带进夜之城

把 **Apple Music / 网易云音乐** 变成游戏里真正可听的电台。在原生车载/随身电台列表选择 **94.7 Piers "Piercer" Random Radio**，屏幕会实时显示正在播放的歌曲、歌手与专辑——独立右对齐 HUD，同时也写入原生 RADIOPORT 弹窗的 Now Playing。

## 特性
- 原生电台列表新增个人电台 `94.7 Piers "Piercer" Random Radio`
- 实时曲目 HUD（右侧、透明背景、自动换行、字幕级字号）：电台名 · 歌曲 · 歌手 · 专辑
- 原生电台弹窗同步显示真实歌名
- 步行（Z 随身收音机）与车内均可；随电台状态自动播放/暂停
- 支持 Apple Music 与 网易云音乐（Windows 系统媒体会话 SMTC）
- 中文全量字形 + 游戏风格拉丁字体（全部免费可分发，含许可）
- 一键安装器（setup.bat），媒体助手为独立 exe，无需 Python

## 前置依赖（先安装）
- Cyber Engine Tweaks / RED4ext / TweakXL / redscript
- External Radio 2.1.14（本包会覆盖其电台改名 tweak）

## 安装
解压后双击 `setup.bat`：自动定位游戏目录、检查依赖、安装 mod、配置字体（ChineseFull）、安装助手 exe、可选开机自启。手动步骤见压缩包内 README。

## 使用
1. 启动助手 `ncp_media_helper.exe`（后台运行，单实例）
2. 播放 Apple Music，或网易云音乐（**需在网易云设置里开启「系统媒体控制」**）
3. 游戏中选择 `94.7 Piers "Piercer" Random Radio`
4. 开车即可，切歌自动更新

**使用小贴士：** 先打开音乐软件并点一次**暂停**，再启动游戏——这样游戏内选中电台后才能可靠接管播放。**推荐开启随机播放**（毕竟游戏内无法切歌）。

切换优先控制的 App：修改助手旁 `config.json` 的 `prefer`（逗号分隔、按顺序匹配）。

## 常见问题 / 说明
- 安装器会配置 CET 字体：拉丁=Rajdhani、中文=HarmonyOS Sans 全量（无豆腐块）；原字体自动备份 `.nc-bak`，还原见 README
- 本包不包含任何第三方 mod 二进制，请按 Requirements 自行安装
- 字体许可：Rajdhani（SIL OFL 1.1）、HarmonyOS Sans（免费商用）均随包附许可



## 支持语言说明
- **HUD（本 mod 的界面）**：简体中文与英文完整支持；中文全量字库同时覆盖日文假名与大部分常用日文汉字（个别日文异体/生僻字可能缺失）
- 曲目元数据按 UTF-8 读取——歌名/歌手无论来自哪种语言都能被读到；能否显示取决于上面的字体覆盖
- 游戏原生电台弹窗使用游戏自带字库（受游戏本地化语言限制）；我们的 HUD 独立渲染、不受影响
- **不支持**：俄文/西里尔、希腊字母等（CET 一次只合并一种语言字库，本 mod 以中文全量集为基准）

## 致谢
- 基于 DrJackieBright 的 External Radio；可选与 RadioExt 共存
- 字体：Rajdhani / HarmonyOS Sans / Noto Sans

## 自定义电台名称（随时改名）
电台名完全由你决定，无需手动改文件：
- **安装时**：安装器会询问是否自定义台名（直接回车则保留默认名）
- **装好之后随时改**：运行包内的 `rename_station.bat`（或 `rename_station.ps1 -StationName "88.8 My Radio"`）；输入为空则恢复默认名 `94.7 Piers "Piercer" Random Radio`
- 工具会自动同步**两处**（电台列表 yaml + HUD），支持中文/UTF-8，并校验名字以「数字+空格」开头（如 `88.8 My Radio`），保证原生电台列表排序正常；改完重启游戏生效。

## 音乐软件与优先级（重要提醒）
- **同一时间最好只运行一个音乐软件并保持播放**，且该软件必须支持 **SMTC**（Windows 系统媒体会话）：
  - **Apple Music**：默认支持
  - **网易云音乐**：必须在其设置里开启「**系统媒体控制**」——不开启不会注册媒体会话，将无法显示/控制
  - 浏览器（YouTube 等）也会注册媒体会话
- HUD 显示的曲目由助手的 `prefer` 顺序决定（默认 `apple,cloudmusic`，改 helper 旁 `config.json` 可调整）；但游戏内播放/暂停跟随系统「当前」媒体会话——**同时只开一个音乐软件**行为才可控
- 若控制到错误的应用：暂停/关闭其它播放器，或调整 `prefer`


## 作者的话

> 由于作者技术限制，本 mod 无法直接在游戏内切歌，毕竟是电台（笑），请大家予以谅解 🎵
>
> 电台的默认频率，来自作者小时候最喜欢听的广播电台——**上海经典947（FM94.7）**。
