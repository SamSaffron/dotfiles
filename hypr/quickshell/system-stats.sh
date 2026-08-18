#!/usr/bin/env bash

# Emit compact JSON for SystemStats.qml. CPU is sampled twice because /proc/stat
# contains counters rather than an instantaneous percentage.
read_cpu() {
  awk '/^cpu / { idle=$5+$6; total=0; for (i=2; i<=NF; i++) total += $i; print idle, total; exit }' /proc/stat
}

normalize_number() {
  local value=$1
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  if [[ $value =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' -1
  fi
}

read_cpu_temperature() {
  local label_file label input_file value maximum=-1
  shopt -s nullglob
  for label_file in /sys/class/hwmon/hwmon*/temp*_label; do
    label=$(<"$label_file")
    if [[ $label =~ ^(Package\ id\ 0|Tctl|Tdie|CPU)$ ]]; then
      input_file="${label_file%_label}_input"
      if [[ -r $input_file ]]; then
        value=$(<"$input_file")
        if [[ $value =~ ^[0-9]+$ ]] && (( value > maximum )); then
          maximum=$value
        fi
      fi
    fi
  done
  shopt -u nullglob

  if (( maximum >= 0 )); then
    printf '%d\n' "$(((maximum + 500) / 1000))"
  else
    printf '%d\n' -1
  fi
}

read -r idle_a total_a < <(read_cpu)
sleep 0.12
read -r idle_b total_b < <(read_cpu)

delta_total=$((total_b - total_a))
delta_idle=$((idle_b - idle_a))
if (( delta_total > 0 )); then
  cpu=$((100 * (delta_total - delta_idle) / delta_total))
else
  cpu=0
fi

cpu_temp=$(read_cpu_temperature)
cpu_mhz=$(awk '/^cpu MHz/ { total += $4; count++ } END { if (count) printf "%.0f", total/count; else print -1 }' /proc/cpuinfo)
cpu_threads=$(nproc 2>/dev/null || printf '%d' 0)
read -r load_1 load_5 load_15 _ < /proc/loadavg

read -r memory_total memory_available memory_cached swap_total swap_free < <(
  awk '
    /MemTotal:/ { total=$2 }
    /MemAvailable:/ { available=$2 }
    /^Cached:/ { cached=$2 }
    /SReclaimable:/ { reclaimable=$2 }
    /SwapTotal:/ { swap_total=$2 }
    /SwapFree:/ { swap_free=$2 }
    END { print total, available, cached+reclaimable, swap_total, swap_free }
  ' /proc/meminfo
)
memory_used=$((memory_total - memory_available))
swap_used=$((swap_total - swap_free))
memory=$((100 * memory_used / memory_total))
read -r disk_device disk_type disk_total disk_used disk_available disk disk_mount < <(
  df -PkT / | awk 'NR == 2 { gsub(/%/, "", $6); print $1, $2, $3, $4, $5, $6, $7 }'
)

gpu=-1
gpu_memory_util=-1
gpu_memory_used=-1
gpu_memory_total=-1
gpu_temp=-1
gpu_power=-1
gpu_power_limit=-1
gpu_clock=-1

if command -v nvidia-smi >/dev/null 2>&1; then
  gpu_line=$(nvidia-smi \
    --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu,power.draw,power.limit,clocks.current.graphics \
    --format=csv,noheader,nounits 2>/dev/null | head -n 1)
  if [[ -n $gpu_line ]]; then
    IFS=',' read -r raw_gpu raw_memory_util raw_memory_used raw_memory_total raw_temp raw_power raw_power_limit raw_clock <<< "$gpu_line"
    gpu=$(normalize_number "$raw_gpu")
    gpu_memory_util=$(normalize_number "$raw_memory_util")
    gpu_memory_used=$(normalize_number "$raw_memory_used")
    gpu_memory_total=$(normalize_number "$raw_memory_total")
    gpu_temp=$(normalize_number "$raw_temp")
    gpu_power=$(normalize_number "$raw_power")
    gpu_power_limit=$(normalize_number "$raw_power_limit")
    gpu_clock=$(normalize_number "$raw_clock")
  fi
fi

if (( gpu < 0 )); then
  maximum=-1
  shopt -s nullglob
  for busy_file in /sys/class/drm/card*/device/gpu_busy_percent; do
    if [[ -r $busy_file ]]; then
      current=$(<"$busy_file")
      if [[ $current =~ ^[0-9]+$ ]] && (( current > maximum )); then
        maximum=$current
      fi
    fi
  done
  shopt -u nullglob
  gpu=$maximum
fi

printf '{"cpu":%d,"cpu_temp":%d,"cpu_mhz":%d,"cpu_threads":%d,"load_1":%s,"load_5":%s,"load_15":%s,"memory":%d,"memory_total_kib":%d,"memory_used_kib":%d,"memory_available_kib":%d,"memory_cached_kib":%d,"swap_total_kib":%d,"swap_used_kib":%d,"gpu":%s,"gpu_memory_util":%s,"gpu_memory_used_mib":%s,"gpu_memory_total_mib":%s,"gpu_temp":%s,"gpu_power":%s,"gpu_power_limit":%s,"gpu_clock":%s,"disk":%d,"disk_total_kib":%d,"disk_used_kib":%d,"disk_available_kib":%d,"disk_device":"%s","disk_type":"%s","disk_mount":"%s"}\n' \
  "$cpu" "$cpu_temp" "$cpu_mhz" "$cpu_threads" "$load_1" "$load_5" "$load_15" \
  "$memory" "$memory_total" "$memory_used" "$memory_available" "$memory_cached" "$swap_total" "$swap_used" \
  "$gpu" "$gpu_memory_util" "$gpu_memory_used" "$gpu_memory_total" "$gpu_temp" "$gpu_power" "$gpu_power_limit" "$gpu_clock" \
  "$disk" "$disk_total" "$disk_used" "$disk_available" "$disk_device" "$disk_type" "$disk_mount"
