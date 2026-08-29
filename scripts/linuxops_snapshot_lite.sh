#!/usr/bin/env bash

# ============================================================
# Linux Ops Rescue Kit - Snapshot Lite
# Version: 1.0
# License: MIT
# Copyright (c) 2026 Linux Ops Lab
# See: ../LICENSE.md
#
# Free read-only diagnostic helper for Linux on-call engineers.
#
# This script does NOT:
# - restart services
# - modify network configuration
# - repair filesystems
# - modify LVM or Multipath
# - reboot the system
#
# It only collects basic diagnostic information and writes
# a private report under /tmp.
#
# Full Linux Ops Rescue Kit:
# https://payhip.com/b/HON4g
# ============================================================

umask 077

HOST_SHORT="$(hostname -s 2>/dev/null || hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT="/tmp/linuxops_snapshot_lite_${HOST_SHORT}_${TIMESTAMP}.txt"

section() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

run_if_available() {
    local cmd="$1"
    shift

    if command -v "$cmd" >/dev/null 2>&1; then
        "$cmd" "$@"
    else
        echo "NOT AVAILABLE: $cmd"
    fi
}

exec > >(tee "$OUT") 2>&1

echo "Linux Ops Rescue Kit - Snapshot Lite"
echo "Generated: $(date)"
echo "Output: $OUT"

section "SYSTEM IDENTITY"

date

if command -v hostnamectl >/dev/null 2>&1; then
    hostnamectl
else
    hostname
fi

section "KERNEL"

uname -a

section "UPTIME / LOAD"

uptime

section "FAILED SYSTEMD UNITS"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --failed --no-pager
else
    echo "NOT AVAILABLE: systemctl"
fi

section "RECENT BOOT ERRORS"

if command -v journalctl >/dev/null 2>&1; then
    journalctl -b -p err..alert --no-pager 2>/dev/null | tail -80
else
    echo "NOT AVAILABLE: journalctl"
fi

section "FILESYSTEM USAGE"

df -hT

section "INODE USAGE"

df -i

section "BLOCK DEVICES"

if command -v lsblk >/dev/null 2>&1; then
    lsblk -f
else
    echo "NOT AVAILABLE: lsblk"
fi

section "MEMORY"

if command -v free >/dev/null 2>&1; then
    free -h
else
    echo "NOT AVAILABLE: free"
fi

section "NETWORK ADDRESSES"

if command -v ip >/dev/null 2>&1; then
    ip -br addr
else
    echo "NOT AVAILABLE: ip"
fi

section "ROUTING TABLE"

if command -v ip >/dev/null 2>&1; then
    ip route
else
    echo "NOT AVAILABLE: ip"
fi

section "LISTENING PORTS"

if command -v ss >/dev/null 2>&1; then
    ss -lntup
else
    echo "NOT AVAILABLE: ss"
fi

section "SUMMARY"

echo "Snapshot completed."
echo
echo "Report saved to:"
echo "$OUT"
echo
echo "Permissions:"
ls -l "$OUT" 2>/dev/null || true

echo
echo "This script performs diagnostic collection only."
echo "Review the report before sharing it outside your environment."
echo
echo "Full Linux Ops Rescue Kit:"
echo "https://payhip.com/b/HON4g"
