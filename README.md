# Linux Ops Rescue Kit

**Free RHEL troubleshooting tools & production incident samples**

Practical troubleshooting resources for Linux system engineers, SREs, production operations teams, and N3 support engineers working with Red Hat Enterprise Linux environments.

> **Triage fast. Prove the cause. Recover safely.**

---

## What you'll find here

This repository provides free resources extracted and adapted from the Linux Ops Rescue Kit methodology:

- Read-only Linux diagnostic tools
- Real-world production incident examples
- Evidence-first troubleshooting workflows
- Failure-layer troubleshooting methodology
- RHEL 8 / 9 / 10 focused examples
- Safe diagnosis before remediation

The goal is not to provide another collection of random Linux commands.

The goal is to answer:

> **Which command proves where the failure is?**

before asking:

> **Which command might fix it?**

---

## Failure-Layer Troubleshooting

When a filesystem such as `/data` disappears, immediately recreating the Volume Group is not troubleshooting.

The real failure chain may be:

```text
Application
    ↓
Filesystem
    ↓
Logical Volume
    ↓
Volume Group
    ↓
Physical Volume
    ↓
Multipath
    ↓
SAN / Storage
```

The safest approach is to identify the **first broken layer** before changing anything.

For example:

```bash
lsblk -f
findmnt
pvs
vgs
lvs -a -o +devices
multipath -ll
```

If the SAN LUN is missing, recreating the PV or VG can turn a recoverable storage visibility problem into data loss.

---

## Free Resources

### Diagnostic Tools

- [`linuxops_snapshot_lite.sh`](scripts/linuxops_snapshot_lite.sh)  
  Read-only Linux snapshot tool that collects system identity, kernel, load, failed services, boot errors, filesystem usage, inodes, block devices, memory, network configuration, routing and listening ports.

### Incident Samples

- [`High Load but Low CPU Usage`](incidents/high-load-low-cpu.md)  
  Learn why a high Linux load average does not always mean CPU saturation and how blocked I/O, storage latency and Multipath issues can be the real cause.

### Troubleshooting Method

The resources in this repository follow the same principle:

```text
Symptom
   ↓
Evidence
   ↓
Failure Layer
   ↓
Root Cause
   ↓
Safest Recovery
   ↓
Verification
```

The objective is to prove where the failure is before applying a fix.

More free incident samples and diagnostic tools will be added over time.

---

## Full Linux Ops Rescue Kit

The complete **Linux Ops Rescue Kit** is an on-call runbook designed for real production incidents.

It includes:

- **30 real-world production incidents**
- 60-second triage workflows
- Realistic commands and outputs
- Evidence collection
- Failure-layer diagnosis
- Safe recovery procedures
- Verification steps
- Rollback guidance
- Stop & Escalate conditions

### PRO Edition

The PRO edition also includes:

- 5 advanced N3 cross-domain scenarios
- 4 read-only diagnostic scripts
- First 10 Minutes incident checklist
- Linux command cheat sheet
- Storage mapping and WWID helper
- Network route diagnostic helper
- Performance snapshot helper

👉 **Full runbook and PRO toolkit:**

https://payhip.com/b/HON4g

---

## RHEL Focus

The examples are especially relevant to:

- Red Hat Enterprise Linux 8
- Red Hat Enterprise Linux 9
- Red Hat Enterprise Linux 10

Common technologies covered include:

`systemd` • `NetworkManager` • `LVM` • `XFS` • `Device Mapper Multipath` • `SSSD` • `Kerberos` • `Leapp`

---

## Production-Safety Philosophy

The project follows several principles:

1. Collect evidence before making changes.
2. Identify the failing layer before attempting recovery.
3. Prefer read-only diagnostics first.
4. Clearly identify high-risk commands.
5. Always verify the result.
6. Know when to stop and escalate.

---

## Disclaimer

Linux Ops Rescue Kit is an independent technical project.

It is not affiliated with, sponsored by, or endorsed by Red Hat.

Red Hat and Red Hat Enterprise Linux are trademarks or registered trademarks of Red Hat, Inc.

Commands and procedures must be reviewed and adapted to your own environment before use in production.
