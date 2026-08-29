# `/data` Disappeared After Reboot — LVM & Multipath Troubleshooting

A missing filesystem after reboot does **not** automatically mean the filesystem or LVM metadata is corrupted.

In enterprise Linux environments, the real problem may exist several layers below the mount point.

> **Triage fast. Prove the cause. Recover safely.**

---

## Symptom

After a reboot, `/data` is no longer mounted.

The application fails to start and systemd may report:

```text
Failed to mount /data.
Dependency failed for Local File Systems.
```

The server may even enter emergency mode.

The dangerous reaction is to immediately recreate the missing storage objects.

For example:

```text
pvcreate
vgcreate
lvcreate
```

**Do not do this until you understand why the original storage is missing.**

Those commands can turn a recoverable storage visibility problem into permanent data loss.

---

## The Failure-Layer Approach

The visible symptom is:

```text
/data missing
```

But the actual dependency chain may be:

```text
/data
  ↓
Filesystem
  ↓
Logical Volume
  ↓
Volume Group
  ↓
Physical Volume
  ↓
Multipath device
  ↓
SAN LUN
  ↓
Storage paths
```

Troubleshoot downward until you identify the **first broken layer**.

---

## Step 1 — Confirm the Mount Failure

Start with read-only checks:

```bash
findmnt /data
grep -w '/data' /etc/fstab
lsblk -f
```

Check boot errors:

```bash
journalctl -b -p err..alert --no-pager
```

You may see:

```text
Failed to mount /data
Dependency failed for Local File Systems
```

At this point, do not assume the filesystem itself is damaged.

---

## Step 2 — Check the Logical Volume

Run:

```bash
lvs -a -o lv_name,vg_name,lv_attr,devices
```

Example expected state:

```text
LV       VG       Attr       Devices
lv_data  vg_data  -wi-a----- /dev/mapper/mpatha(0)
```

If `lv_data` is missing, continue down one layer.

---

## Step 3 — Check the Volume Group

Run:

```bash
vgs
```

Expected:

```text
VG       #PV #LV #SN Attr   VSize   VFree
vg_data    1   1   0 wz--n- 500.00g 20.00g
```

If `vg_data` is missing, **do not recreate it**.

Continue to the Physical Volume layer.

---

## Step 4 — Check Physical Volumes

Run:

```bash
pvs -o pv_name,vg_name,pv_size,pv_free
```

Expected:

```text
PV                  VG       PSize   PFree
/dev/mapper/mpatha  vg_data  500.00g 20.00g
```

If `/dev/mapper/mpatha` is missing, the issue is now clearly below LVM.

---

## Step 5 — Check Multipath

Run:

```bash
multipath -ll
```

Healthy example:

```text
mpatha (3600508b400105df70000e00000ac0000) dm-3
size=500G features='1 queue_if_no_path' hwhandler='1 alua' wp=rw

|-+- policy='service-time 0' prio=50 status=active
| `- 2:0:0:1 sdb 8:16 active ready running

`-+- policy='service-time 0' prio=10 status=enabled
  `- 3:0:0:1 sdc 8:32 active ready running
```

If the expected WWID is completely absent, the problem may be SAN visibility rather than LVM.

---

## Step 6 — Inspect Individual Paths

If available:

```bash
multipathd show paths
```

You can also inspect block devices:

```bash
lsblk
```

and SCSI devices:

```bash
lsscsi
```

A degraded system may show:

```text
sdb  active ready running
sdc  failed faulty running
```

A completely missing LUN may show neither expected path.

---

## Example Failure Chain

Consider this situation:

```text
findmnt /data
    → nothing mounted

lvs
    → lv_data missing

vgs
    → vg_data missing

pvs
    → /dev/mapper/mpatha missing

multipath -ll
    → expected WWID missing
```

The most likely failure chain is therefore:

```text
SAN LUN not visible
        ↓
Multipath map missing
        ↓
Physical Volume missing
        ↓
Volume Group missing
        ↓
Logical Volume missing
        ↓
Filesystem unavailable
        ↓
/data not mounted
```

The mount failure is only the **top-level symptom**.

---

## What Not to Do

Do not immediately run commands such as:

```bash
pvcreate /dev/mapper/mpatha
vgcreate vg_data /dev/mapper/mpatha
lvcreate ...
mkfs.xfs ...
```

unless you have explicitly confirmed that this is a new storage device and that recreating storage metadata is intended.

On an existing production LUN, such commands may overwrite valuable metadata.

---

## Evidence to Collect Before Escalation

Before escalating to the SAN, VMware, storage, or infrastructure team, capture:

```bash
date
hostnamectl
uname -r
lsblk -f
findmnt
pvs
vgs
lvs -a -o +devices
multipath -ll
multipathd show paths
journalctl -b -p err..alert --no-pager
```

If the issue is complex and the environment permits it:

```bash
sos report
```

Review diagnostic archives before sending them outside your environment.

---

## Key Lesson

A missing filesystem does not necessarily mean:

```text
Filesystem corruption
```

It may actually mean:

```text
Storage visibility failure
```

Always move down the dependency chain and identify the **first broken layer**.

The goal is not to ask:

> **Which command can recreate `/data`?**

The better question is:

> **Which command proves why `/data` disappeared?**

---

## Useful Commands

```bash
findmnt
lsblk -f
pvs
vgs
lvs -a -o +devices
multipath -ll
multipathd show paths
lsscsi
journalctl -b -p err..alert --no-pager
```

---

## Full Linux Ops Rescue Kit

This incident is adapted from the **Linux Ops Rescue Kit** troubleshooting methodology.

The complete runbook includes:

- 30 real-world production incidents
- RHEL 8 / 9 / 10 focused troubleshooting
- 60-second triage workflows
- Commands with realistic outputs
- Evidence collection
- Failure-layer diagnosis
- Safe recovery procedures
- Verification and rollback guidance
- Stop & Escalate conditions

The **PRO edition** also includes:

- 5 advanced N3 scenarios
- 4 read-only diagnostic scripts
- First 10 Minutes checklist
- Linux command cheat sheet
- Storage mapping and WWID helper

👉 **Full runbook and PRO toolkit:**

https://payhip.com/b/HON4g

---

## Disclaimer

This content is intended for educational and operational guidance.

Storage recovery procedures must always be validated against your architecture, backups, change process, and vendor procedures before use in production.

Linux Ops Rescue Kit is an independent technical project and is not affiliated with, sponsored by, or endorsed by Red Hat.
