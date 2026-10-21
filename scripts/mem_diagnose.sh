#!/bin/bash
# =============================================================================
# mem_diagnose.sh — macOS 内存健康诊断脚本（L1，纯只读）
# -----------------------------------------------------------------------------
# 仅使用 macOS 原生命令：sw_vers / uname / sysctl / vm_stat / ps
# 不依赖任何第三方工具，不执行任何写入/清理/杀进程操作。
# 输出：系统信息 → 物理内存总量 → 压力等级 → 用量明细 → Swap → Top10 进程 → 异常大户 → 结论
# =============================================================================
set -euo pipefail

PAGE_BYTES=4096

# ---------- 单位换算 ----------
pages_to_human() {
  local pages="$1"
  local mib=$(( pages * PAGE_BYTES / 1048576 ))
  if (( mib >= 1024 )); then
    printf "%d.%02d GiB" $(( mib / 1024 )) $(( (mib % 1024) * 100 / 1024 ))
  else
    printf "%d MiB" "$mib"
  fi
}

rss_to_human() {
  local kb="$1"
  local mib=$(( kb / 1024 ))
  if (( mib >= 1024 )); then
    printf "%d.%02d GiB" $(( mib / 1024 )) $(( (mib % 1024) * 100 / 1024 ))
  else
    printf "%d MiB" "$mib"
  fi
}

bytes_to_human() {
  local bytes="$1"
  local gib=$(( bytes / 1073741824 ))
  local mib=$(( (bytes % 1073741824) / 1048576 ))
  if (( gib > 0 )); then
    printf "%d.%02d GiB" "$gib" "$mib"
  else
    printf "%d MiB" "$mib"
  fi
}

echo "=============================================================="
echo " macOS 内存健康诊断报告（L1 · 只读）"
echo " 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================================="

# ---------- 0. 系统信息（第一步：先了解本机环境）----------
echo ""
echo "【0. 系统与硬件信息】"
# macOS 版本
macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
build_version=$(sw_vers -buildVersion 2>/dev/null || echo "unknown")
echo "  macOS 版本: macOS $macos_version (build $build_version)"

# 架构与内核
kernel_version=$(uname -r 2>/dev/null || echo "unknown")
arch=$(uname -m 2>/dev/null || echo "unknown")
echo "  内核版本: Darwin $kernel_version ($arch)"

# CPU 型号
cpu_brand=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "unknown")
cpu_core=$(sysctl -n hw.physicalcpu 2>/dev/null || echo "?")
cpu_logic=$(sysctl -n hw.logicalcpu 2>/dev/null || echo "?")
echo "  CPU: $cpu_brand ($cpu_core 核物理 / $cpu_logic 核逻辑)"

# 主机名
hostname_str=$(hostname 2>/dev/null || echo "unknown")
echo "  主机名: $hostname_str"

# ---------- 1. 物理内存总量 ----------
total_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
total_pages=$(( total_bytes / PAGE_BYTES ))
echo ""
echo "【1. 物理内存总量】"
echo "  总物理内存: $(bytes_to_human "$total_bytes") ($total_pages 页)"

# ---------- 2. 内存压力等级 ----------
# 读 vm_stat
vm_stat_output=$(vm_stat 2>/dev/null || echo "")
pages_free=$(echo "$vm_stat_output" | grep "Pages free" | awk '{print $3}' | tr -d '.')
pages_active=$(echo "$vm_stat_output" | grep "Pages active" | awk '{print $3}' | tr -d '.')
pages_inactive=$(echo "$vm_stat_output" | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
pages_speculative=$(echo "$vm_stat_output" | grep "Pages speculative" | awk '{print $3}' | tr -d '.')
pages_wired=$(echo "$vm_stat_output" | grep "Pages wired down" | awk '{print $4}' | tr -d '.')
pages_compressed=$(echo "$vm_stat_output" | grep "Pages occupied by compressor" | awk '{print $5}' | tr -d '.')
pages_filebacked=$(echo "$vm_stat_output" | grep "File-backed pages" | awk '{print $3}' | tr -d '.')
pages_purgeable=$(echo "$vm_stat_output" | grep "Pages purgeable" | awk '{print $3}' | tr -d '.')

# Swap 信息
swap_info=$(sysctl -n vm.swapusage 2>/dev/null || echo "")
swap_total=$(echo "$swap_info" | grep -o 'total = [0-9.]*[MG]' | awk '{print $3}')
swap_used=$(echo "$swap_info" | grep -o 'used = [0-9.]*[MG]' | awk '{print $3}')
swap_free=$(echo "$swap_info" | grep -o 'free = [0-9.]*[MG]' | awk '{print $3}')

# 压力判断：空闲占比（用 awk 算百分比，避免 bc 浮点比较问题）
free_pct=$(awk -v f="${pages_free:-0}" -v t="$total_pages" 'BEGIN { if (t>0) printf "%d", (f/t)*100; else print 0 }')

if (( free_pct > 30 )); then
  pressure="低 / 正常 (绿色)"
elif (( free_pct > 15 )); then
  pressure="中等 (黄色)"
else
  pressure="高 / 紧张 (红色)"
fi

echo ""
echo "【2. 内存压力等级】"
echo "  结论: $pressure"
echo "  依据: 空闲占比=${free_pct}%"

# ---------- 3. 内存用量明细 ----------
echo ""
echo "【3. 内存用量明细】"
printf "  %-30s %12s\n" "项目" "用量"
printf "  %-30s %12s\n" "----" "----"
printf "  %-30s %12s\n" "空闲 Free" "$(pages_to_human "${pages_free:-0}")"
printf "  %-30s %12s\n" "文件缓存 File-backed" "$(pages_to_human "${pages_filebacked:-0}")"
printf "  %-30s %12s\n" "可清除 Purgeable" "$(pages_to_human "${pages_purgeable:-0}")"
printf "  %-30s %12s\n" "联动 Wired（内核锁定）" "$(pages_to_human "${pages_wired:-0}")"
printf "  %-30s %12s\n" "压缩 Compressed（物理占用）" "$(pages_to_human "${pages_compressed:-0}")"
printf "  %-30s %12s\n" "活跃 Active" "$(pages_to_human "${pages_active:-0}")"
printf "  %-30s %12s\n" "非活跃 Inactive" "$(pages_to_human "${pages_inactive:-0}")"
printf "  %-30s %12s\n" "投机 Speculative" "$(pages_to_human "${pages_speculative:-0}")"

# ---------- 4. Swap ----------
echo ""
echo "【4. 交换分区 Swap】"
echo "  total = ${swap_total:-N/A}  used = ${swap_used:-N/A}  free = ${swap_free:-N/A}  (encrypted)"

# ---------- 5. Top 10 内存占用进程 ----------
echo ""
echo "【5. Top 10 内存占用进程 (RSS)】"
printf "  %-4s %-8s %-40s %10s\n" "排名" "PID" "进程" "RSS"
printf "  %-4s %-8s %-40s %10s\n" "----" "----" "----" "----"

# 用 ps 按 RSS 排序取前 10（用 awk 截取避免 SIGPIPE）
rank=1
ps -axm -o pid,rss,comm 2>/dev/null | tail -n +2 | awk 'NR<=10' | while read -r pid rss comm; do
  proc_name=$(basename "$comm" 2>/dev/null || echo "$comm")
  rss_human=$(rss_to_human "$rss")
  warn=""
  if (( rss > 2097152 )); then
    warn=" ⚠️"
  fi
  printf "  %-4s %-8s %-40s %10s%s\n" "$rank" "$pid" "${proc_name:0:38}" "$rss_human" "$warn"
  rank=$(( rank + 1 ))
done

# ---------- 6. 异常大户标注 ----------
echo ""
echo "【6. 异常大户标注（RSS > 2 GiB）】"
big_guys=$(ps -axm -o rss,comm 2>/dev/null | tail -n +2 | awk '$1 > 2097152 {printf "  %s: %.2f GiB\n", $2, $1/1048576}' | head -10)
if [ -n "$big_guys" ]; then
  echo "$big_guys"
  echo "  提示: 详见 references/common-bottlenecks.md 判断能否安全释放。"
else
  echo "  未发现超过 2 GiB 的单进程占用。"
fi

# ---------- 7. 总体结论 ----------
used_pages=$(( pages_active + pages_wired + pages_compressed ))
used_human=$(pages_to_human "$used_pages")
echo ""
echo "【7. 总体结论】"
echo "  物理内存 $(bytes_to_human "$total_bytes") | 空闲 $(pages_to_human "${pages_free:-0}") | Swap 使用 ${swap_used:-N/A}"
echo "  压力等级: $pressure"
if [[ "$pressure" == 低* ]]; then
  echo "  状态健康，无需处理；如需优化可参考 L2 建议。"
else
  echo "  建议查看上方异常大户，或运行 L2 建议分析。"
fi
echo "=============================================================="
echo " 本脚本为只读诊断，未执行任何清理 / 杀进程 / purge 操作。"
echo "=============================================================="
