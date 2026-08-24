# DeepSeek Harness 桌面版

中文 | [English](#english)

DeepSeek Harness **一键安装为桌面应用**：体积极小、无需任何额外封装，仅作为 Edge 快捷方式——双击即用，一键打开终端与独立网页。

整个项目只有 **5 个文件、几 KB**：安装脚本 + 一个无窗口启动器 + 双语说明。不打包、不注入、不装额外运行时，只借用你电脑上**系统自带的 Microsoft Edge 框架**（`msedge --app=` 应用模式：无标签栏、无地址栏、独立图标），以及官方 npm 包 `@deepseek-ai/dsh`。

## 特性

- **体积极小**：仅 5 个文件、几 KB。无 Electron、无包装层、无后台驻留，安装即用完即走
- **跟随官方更新**：每次点击快捷方式，后台自动检查 npm 官方源的最新版本并自动安装——官方发布即升级，零手动操作（服务运行中点击秒开不打扰；新版本在下次冷启动时自动应用）
- **利用系统自带 Edge 框架**：独立应用窗口由系统 Edge 提供（`msedge --app=`），不下载任何浏览器、不占用额外存储
- **一键安装**：自动安装 Node.js（缺失时）→ 自动安装/升级 dsh（已装且最新则秒级跳过）→ 创建桌面 + 开始菜单快捷方式
- **全程无窗口**：更新检查、服务启动、日志全部后台静默完成，不弹任何黑窗口
- **只安装、不打扰**：日志在 `%LOCALAPPDATA%\dsh-edge-app\`，不需要时手动删快捷方式 + 卸载 npm 包即可（详见"如何移除"）

## 系统要求

Windows 10/11 + Microsoft Edge + Node.js >= 18（缺失时自动通过 winget 安装）。

## 快速开始

双击 `双击安装.bat`，或运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

脚本会先检查：Node.js 缺失自动安装；dsh 已安装且为最新版则跳过，否则自动安装/升级。

安装完成后，桌面会出现 **"DeepSeek Harness"** 快捷方式（开始菜单也有）。

以后每次使用：双击该快捷方式即可——脚本会自动完成"检查更新 + 启动服务 + 打开应用窗口"，无需再开命令行。冷启动时若检测到新版，会先完成升级再打开窗口（首次可能多等几十秒，之后每次点击秒开）。

> **关于"在 Edge 里安装为应用"（edge://apps）**：`msedge --app=` 打开的是"应用模式"窗口，**不会**注册到 Edge 的 `edge://apps` 已安装应用列表（那是 PWA 专属）。dsh web 本身是标准 PWA，想要系统级应用条目时：
>
> 1. 在 Edge 中打开 http://127.0.0.1:3080
> 2. 点击地址栏右侧的"应用"按钮 → "将此站点安装为应用" → "安装"
> 3. 之后即可在 `edge://apps` 中看到该应用：可设置自启动、创建快捷方式，需要时也能**从这里卸载**（应用卡片 → 详情 → 卸载，或 Windows 设置 → 应用 → 已安装的应用）
>
> 注意：PWA 只是网页壳，**不负责启动 dsh 服务**（双击 PWA 图标时后台服务可能未运行），日常打开仍建议使用本项目的桌面快捷方式（自动完成"更新 + 启动服务 + 打开窗口"）。

## 工作原理

```
点击快捷方式 (DeepSeek Harness)
    │  (目标: wscript.exe //B launcher.vbs，全程无窗口)
    ▼
检查更新（install.ps1 -UpdateCheck，带并发锁）
    │  服务运行中 → 异步执行，本次跳过安装（npm 无法替换运行中文件）
    │  服务未运行 → 同步等待：有新版本先升级，无则立即返回
    ▼
launcher.vbs 检查 http://127.0.0.1:3080 是否就绪
    │  未就绪 → install.ps1 -StartService（占锁启动 dsh web，日志重定向，最多等 90 秒）
    ▼
msedge --app=http://127.0.0.1:3080  ← 独立应用窗口打开 DSH 后台
```

## 常用操作

| 操作 | 方式 |
| --- | --- |
| 打开 DSH 后台 | 双击桌面 "DeepSeek Harness" 快捷方式 |
| 停止后台服务 | `Stop-Process -Id (Get-NetTCPConnection -LocalPort 3080).OwningProcess -Force` |
| 重新安装 / 更新 dsh | 重新运行 `双击安装.bat`（已装且最新会自动跳过） |
| 查看运行日志 | `%LOCALAPPDATA%\dsh-edge-app\dsh-web.log` / `dsh-web.err.log` |

## 如何移除

本应用**只安装了三样东西**：两个快捷方式、一个 `%LOCALAPPDATA%\dsh-edge-app\` 目录、全局 npm 包 `@deepseek-ai/dsh`。需要移除时手动执行：

1. 删除桌面与开始菜单的 "DeepSeek Harness" 快捷方式
2. `npm uninstall -g @deepseek-ai/dsh`
3. 删除 `%LOCALAPPDATA%\dsh-edge-app\` 目录（启动器/图标/日志）

你的工作区与文档（dsh 工作目录、Agent 项目、Node.js）不受任何影响。

## 常见问题

- **执行策略限制**：请通过 `双击安装.bat` 运行，或使用 `-ExecutionPolicy Bypass` 参数
- **安装后找不到 `dsh` 命令**：重开终端让 PATH 生效
- **端口 3080 被占用**：停止占用该端口的进程后再点击应用（升级/卸载仅停止 dsh 相关进程，不影响其他应用）
- **应用窗口打不开**：查看 `dsh-web.err.log`；确认 Edge 已安装
- **应用窗口提示"无法访问此页面 / ERR_CONNECTION_REFUSED"**：dsh web 后台服务未运行（常见于重启电脑后通过 edge://apps 的 PWA 图标打开——PWA 只是网页壳，不会启动服务）。双击桌面 "DeepSeek Harness" 快捷方式即可自动启动服务，或手动运行 `dsh web` 后刷新页面
- **为什么 edge://apps 里没有它**：见上方"关于在 Edge 里安装为应用"的说明

---

## English

One-command installer for [DeepSeek Harness (dsh)](https://github.com/deepseek-ai/deepseek-harness) on Windows. **Tiny footprint, zero wrapper** — just a few KB of scripts that turn the official npm package `@deepseek-ai/dsh` into a desktop app using your **system-installed Microsoft Edge** as the app framework (`msedge --app=`): double-click to open the terminal + standalone web UI.

### Features

- **Extremely small**: 5 files, a few KB. No Electron, no packaging, nothing installed beyond npm's official `@deepseek-ai/dsh` and two shortcuts
- **Always follows official releases**: every launch silently checks npm for the newest version and installs it automatically — when the official package updates, your app updates (clicks while the service is running open instantly; upgrades apply on the next cold start)
- **Built on your system Edge**: the standalone app window (no tabs, no address bar) is provided by the Edge already on your PC — no browser download, no extra runtime
- **One-command install**: auto-installs Node.js if missing → installs/upgrades dsh (skips in a second when already up to date) → creates desktop + Start Menu shortcuts
- **Fully windowless**: update checks, service start and logs all happen silently in the background
- **Easy to remove**: just delete the shortcuts, run `npm uninstall -g @deepseek-ai/dsh` and remove `%LOCALAPPDATA%\dsh-edge-app\` — your workspace and documents are untouched

### Requirements

Windows 10/11, Microsoft Edge, Node.js >= 18 (auto-installed via winget if missing).

### Quick start

Double-click `双击安装.bat`, or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Then just double-click the **"DeepSeek Harness"** shortcut on your desktop — it handles everything (check updates + start server + open app window). On a cold start with a pending update, the upgrade runs first, so the first click may take a few dozen seconds; afterwards every click opens instantly.

> **Install as a real Edge app (`edge://apps`)**: `msedge --app=` opens an "app mode" window but does not register in Edge's installed-apps list (PWA-only). dsh web is a standard PWA, so for a system-level entry: open http://127.0.0.1:3080 in Edge → click the "Apps" button next to the address bar → "Install this site as an app" → "Install". It then appears in `edge://apps`, where you can enable auto-start, create shortcuts, and **uninstall it** (app card → Details → Uninstall, or Windows Settings → Apps → Installed apps). Note the PWA is just a web shell — it does not start the dsh service, so use this project's shortcut for daily use (update + service start + window in one click).

### How it works

```
Click shortcut (DeepSeek Harness)
    │  (target: wscript.exe //B launcher.vbs, fully windowless)
    ▼
Update check (install.ps1 -UpdateCheck, concurrency-locked)
    │  service running  → async, install skipped this click (npm can't replace locked files)
    │  service not running → sync wait: upgrade first if a new version exists, else return
    ▼
launcher.vbs probes http://127.0.0.1:3080
    │  not ready → install.ps1 -StartService (lock-protected start, logs redirected, waits up to 90s)
    ▼
msedge --app=http://127.0.0.1:3080  ← standalone app window opens the DSH UI
```

### Common tasks

| Task | How |
| --- | --- |
| Open DSH UI | Double-click the "DeepSeek Harness" shortcut |
| Stop the background service | `Stop-Process -Id (Get-NetTCPConnection -LocalPort 3080).OwningProcess -Force` |
| Reinstall / update dsh | Re-run `双击安装.bat` (skips automatically when already up to date) |
| View logs | `%LOCALAPPDATA%\dsh-edge-app\dsh-web.log` / `dsh-web.err.log` |

### FAQ

- **The app window shows "ERR_CONNECTION_REFUSED"**: the dsh web service is not running (typical after a reboot when opened via the edge://apps PWA icon — the PWA is only a web shell and never starts the service). Double-click the "DeepSeek Harness" desktop shortcut (it starts the service automatically) or run `dsh web` manually, then refresh.

### Removal

Only three things are installed: two shortcuts, the `%LOCALAPPDATA%\dsh-edge-app\` directory, and the global npm package `@deepseek-ai/dsh`. To remove: delete the shortcuts, run `npm uninstall -g @deepseek-ai/dsh`, and delete `%LOCALAPPDATA%\dsh-edge-app\`. Your workspace and documents are never touched.
