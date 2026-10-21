# macos-memory-optimizer

macOS 本机内存排查与优化 Skill。先采集系统硬件信息，再输出只读内存诊断报告，分级给出优化建议。

## 功能

- **L1 诊断（只读）**：一键输出系统信息、内存压力等级、用量明细、Swap、Top 10 内存占用进程、异常大户标注
- **L2 建议（只读分析）**：基于诊断结果给出可执行的优化建议
- **L3 执行（需确认）**：清理缓存、退出指定应用，必须列清单经用户确认后执行

## 文件结构

```
macos-memory-optimizer/
├── SKILL.md
├── scripts/
│   └── mem_diagnose.sh       # L1 只读诊断脚本
└── references/
    └── common-bottlenecks.md # 常见内存大户速查表
```

## 快速使用

```bash
bash scripts/mem_diagnose.sh
```

## 安全原则

- 默认全程只读，不杀进程、不清缓存、不改系统
- 任何有副作用的操作必须列清单 → 用户确认 → 执行
- 不使用 sudo
