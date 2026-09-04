# NC PERSONAL Radio HUD — 版本迭代记录 (Changelog)

## 最终版 v1.0-final
- 定版；本地与发行包逐文件 hash 一致。

## 开发历程（按逻辑阶段）

### 阶段 0 · 方案推翻与选定
- v0 (概念): Frequency + localhost 桥 + CET companion → 判定不满足需求
- v1: 改用 CP77 External Radio 2.1.14（SMTC 原生）为底座
  - 修复: 台名 "Enable Aux Radio" → "97.5 NC PERSONAL" → "94.7 Piers "Piercer" Random Radio"（保持数字前缀以兼容 RadioExt 排序）

### 阶段 1 · HUD 起步与踩坑修复
- v2: 修复 GetAllBlackboardDefs 顶层调用崩溃；引入 NCPersonal.log 落盘诊断
- v3: 检测改为「上车 && 播放中」代理信号（CET 全局 API 不可用问题的规避）
- v4: 修复 `_G` nil 导致的加载失败；原生 RADIOPORT 弹窗 NOW PLAYING 注入成功
- v5: 常驻 ImGui overlay 初版（右侧两行）
- v6: 顶部单行·双色·无框·大字（字幕级）
  - 乱码根因：CName tostring → ToCName{} 垃圾；改为 GetLocalizedTextByKey 正规本地化
- v7: 右下角两行双色；修复 autosize+GetWindowSize 时序导致的“双影/闪烁”
  - v7.1: 安全文本转换 + 防对象转储兜底
  - v7.2: 换行/控制符消毒
- v8: 确定性布局（Begin 前算死位置尺寸，杜绝闪）→ v8.1 透明背景三重保险 → v8.2~v8.4 字号/区域/换行调优
- v9: 歌/手/辑分行·右对齐·多色 → v9.1 更小字号 + 保留真实换行
- v10: 全量重写稳定基线（media 相对路径化、去历史补丁残留）

### 阶段 2 · 随“电台开关”的状态机
- v11: HUD 随收音机开关；新增 cmd.json 命令通道与游戏事件钩子
  - v11.1~11.3: 原生台曲目恢复显示；下车/关随身清除残留；换行全形态归一（\r\n、\n、CR）
- v12: 改用「当前选中台 cur」判定（修 94.7 收回页面 HUD 误消失）
  - 根因：External Radio 关闭原生接收器被误判为“关收音机”
  - v12.1: 暂停时也显示（不再要求 playing=true）
- v13: 修“v13 误删 draw 常量导致 HUD 全灭”事故（常量补回）
- v14: Z 键 = 94.7 专用播放/暂停（方案A，原生随身不跳台）
  - v14.1: 引入 musicOn 意图计数，避免 pocket on/off 状态被强制重置造成的奇偶混乱
  - v14.2/v14.3: 车内原生台名捕获尝试（GetCurrentRadioIndex / VehicleRadioEvent）
- v15: 原生台仅显示“曲目行”（跟随电台开关）；94.7 保持完整卡
  - 结论：游戏不暴露原生台名，黑箱方案放弃台名
- v16(final): 94.7 完整卡 + 原生台曲目行 + Z 开关 + 上车不自动播（改 .reds）→ 定版

### 字体与多语言
- Rajdhani（拉丁游戏感）为 base；中文全量由 ChineseFull 通道提供
- 尝试链: Noto → Rajdhani → NotoSC(otf/base 失败) → SimHei(版权弃用) → NotoSC variable(缺字) → NotoSC 静态化(仍缺“冀”样式问题) → HarmonyOS Sans SC（全字面验证含 島/絵/假名）
- 根因: CET base 永远只用 default range；中文必须靠 font.language=ChineseFull + 对应槽字库
- 字体验证: fontTools 检查 cmap + 轮廓有效性
- 支持: 简中/英文完整、日文假名+常用汉字大部分；不支持西里尔/希腊（CET 单语言字库机制）

### 媒体助手 helper
- v1: winsdk SMTC 轮询 → media.json（Apple 优先）
- v2: 命令通道 cmd.json（play/pause/toggle/next/prev）；--prefer 优先级列表（Apple/网易云）
- v3: 旁置 config.json（frozen 感知取 exe 目录）；单实例锁（端口绑定）；PyInstaller 独立 exe（修复 import sys）

### 发行
- setup.bat / setup.ps1：定位游戏、校验依赖、装 mod/字体/helper、ChineseFull、自启
- 字体许可随包（Rajdhani OFL / HarmonyOS / Noto）
- 描述（EN/CN）迭代: 去重、改台名方法、单软件+SMTC 提醒、作者的话(FM94.7)、支持语言说明、使用小贴士
- UPLOAD-CHECKLIST.md 上传清单

## 已知限制
- 游戏内不可切歌（天然电台设计）
- 原生台不显示台名（游戏脚本层不暴露；黑箱）
- 电台弹窗日文汉字缺字（游戏原生字库限制）
- 俄文/希腊不支持（CET 单语言字库）


## v1.0.1-fix（发行前加固 2026-09-04）
- setup 修复：检测 `bin\x64\Cyberpunk2077.exe`（原误用根目录 exe）；4 处 `-and` 括号（Test-Path 参数陷阱）；PS5.1 JSON 无 BOM 写入；全局 trap 不闪退；输入净化+限次
- setup 增强：接受输入 `bin\x64` 子目录自动归位到游戏根；全自动检测游戏目录（Steam 注册表/libraryfolders.vdf 多库/GOG/Epic/各盘常见路径）；装完自动后台启动 helper；自动把 mods 下残留的 `NCPersonal*.__nc` 备份目录移出（防 CET 双加载）
- 已知坑记录：mods 目录内任何带 init.lua 的备份/隐藏目录会被 CET 当作第二个 mod → HUD 两遍上下两行
