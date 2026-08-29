# High Load but Low CPU Usage

A high Linux load average does **not** always mean the CPU is overloaded.

In production, a server can report a load average of 20, 30, or even 50 while CPU utilization remains relatively low.

The missing piece is often **blocked I/O**.

> **Triage fast. Prove the cause. Recover safely.**

---

## Symptom

Users report that an application is very slow.

You check:

```bash
uptime
```

Example:

```text
 00:21:31 up 42 days,  4:16,  2 users,  load average: 38.42, 35.10, 29.76
```

At first glance, this looks like a CPU problem.

But then:

```bash
mpstat -P ALL 1 5
```

shows that CPU utilization is only around 20–30%.

So where does the load come from?

---

## Quick Triage

Start with:

```bash
uptime
top
vmstat 1 5
mpstat -P ALL 1 5
iostat -xz 1 5
```

Look specifically for:

- Processes in `D` state
- High `wa` (I/O wait)
- High disk latency
- Blocked processes
- Multipath or storage errors

---

## Check for blocked processes

Run:

```bash
ps -eo state,pid,ppid,comm | awk '$1=="D"'
```

Example:

```text
D  1102     1 systemd-journal
D  4509  2310 java
D  4721  2310 java
```

Processes in `D` state are waiting in **uninterruptible sleep**, usually for storage or network I/O.

A large number of blocked processes can increase the load average even when CPU utilization is low.

---

## Check I/O wait

Run:

```bash
vmstat 1 5
```

Example:

```text
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 2 18      0 812344  22000 912344    0    0  9400 10200 2110 3312 12  5 38 45  0
```

Important fields:

- `b` = blocked processes
- `wa` = CPU time waiting for I/O

Here:

```text
b = 18
wa = 45%
```

This strongly suggests an I/O bottleneck.

---

## Check storage latency

Run:

```bash
iostat -xz 1 5
```

Look for:

- high device latency
- growing queues
- abnormal utilization
- sustained I/O wait

For example:

```text
Device            r/s     w/s   await  aqu-sz  %util
dm-3             84.2   120.4   287.4    18.1   99.8
```

An `await` close to 300 ms on a production storage device is a strong warning sign.

---

## SAN / Multipath systems

If the filesystem is backed by SAN storage, check:

```bash
multipath -ll
```

Example:

```text
mpatha (3600508b400105df70000e00000ac0000) dm-3
size=500G features='1 queue_if_no_path' hwhandler='1 alua' wp=rw

|-+- policy='service-time 0' prio=50 status=active
| `- 2:0:0:1 sdb 8:16 active ready running

`-+- policy='service-time 0' prio=10 status=enabled
  `- 3:0:0:1 sdc 8:32 failed faulty running
```

One path is degraded.

The failure chain may therefore be:

```text
SAN path instability
        ↓
Storage latency
        ↓
Processes blocked in D state
        ↓
Load average increases
        ↓
Application becomes slow
```

---

## Key Lesson

Do not translate:

```text
High load
```

directly into:

```text
High CPU
```

The Linux load average also includes processes waiting in uninterruptible sleep.

Always verify the actual bottleneck.

---

## Useful Commands

```bash
uptime
top
vmstat 1 5
mpstat -P ALL 1 5
iostat -xz 1 5
ps -eo state,pid,ppid,comm
multipath -ll
journalctl -k
```

---

## Full Linux Ops Rescue Kit

This incident is adapted from the **Linux Ops Rescue Kit** methodology.

The complete runbook contains:

- 30 real-world production incidents
- RHEL 8 / 9 / 10 focused troubleshooting
- Commands and realistic outputs
- Evidence collection
- Recovery procedures
- Verification and rollback guidance
- Stop & Escalate conditions

The PRO edition also includes diagnostic scripts and advanced N3 scenarios.

👉 Full runbook:

https://payhip.com/b/HON4g

---

## Disclaimer

This content is intended for educational and operational guidance.

Always review commands and procedures against your own environment before using them in production.

Linux Ops Rescue Kit is an independent technical project and is not affiliated with, sponsored by, or endorsed by Red Hat.
