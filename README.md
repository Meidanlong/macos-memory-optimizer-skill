# macos-optimizer-skill

macOS 本机内存与磁盘排查与优化 Skill。**内存线**先采集系统硬件信息，再输出只读内存诊断报告，分级给出优化建议；**磁盘线**提供安全清理脚本（默认预演、只统计不删除），覆盖用户级缓存、日志、Xcode 编译缓存与废纸篓（需显式确认）。

## 功能

### 内存线
- **L1 诊断（只读）**：一键输出系统信息、内存压力等级、用量明细、Swap、Top 10 内存占用进程、异常大户标注
- **L2 建议（只读分析）**：基于诊断结果给出可执行的优化建议
- **L3 执行（需确认）**：清缓存、退指定应用，必须列清单经用户确认后执行（红线：不 kill/purge/sudo，不碰 `com.apple.*` 且 PPID=1 的系统进程）

### 磁盘线
- **L1 磁盘排查（只读）**：`df` / `tmutil listlocalsnapshots` / `du` 快速定位空间占用，首选系统自带"存储"面板
- **L2 安全清理（需确认）**：`bash scripts/mac_clean.sh`（默认预演只统计；`--execute` 实际清理；`--execute --trash` 额外清空废纸篓）
- **L3 黑名单（禁止）**：`/System` `/Library` `/private/var/db`、关闭 SIP、删个人目录文件、未确认清空废纸篓、任何 `sudo rm -rf` 系统路径

## 文件结构

```
macos-optimizer-skill/
├── SKILL.md
├── scripts/
│   ├── mem_diagnose.sh       # 内存线 L1 只读诊断脚本
│   └── mac_clean.sh          # 磁盘线 L1/L2 安全清理脚本（默认预演）
└── references/
    ├── common-bottlenecks.md # 内存常见大户速查表
    └── macos-disk.md         # 磁盘清理与优化参考
```

## 快速使用

```bash
bash scripts/mem_diagnose.sh          # 内存只读诊断
bash scripts/mac_clean.sh             # 磁盘清理预演（只统计不删除）
bash scripts/mac_clean.sh --execute --trash   # 实际清理 + 清空废纸篓（需用户确认）
```

## 安全原则

- 默认全程只读，不杀进程、不清缓存、不改系统
- 任何有副作用的操作必须列清单 → 用户确认 → 执行
- 不使用 sudo；废纸篓默认不清理，需 `--execute --trash` 双参数
