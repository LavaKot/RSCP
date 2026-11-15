#!/usr/bin/env python3
"""Benchmark runner for RSCP.

Usage:
    python3 bench.py [path-to-rscp] [--n 5] [--save out.json] [--base base.json]

Runs each bench/*.rscp program N times, reports the best (min) wall time,
which is the most stable estimator for CPU-bound work in a noisy sandbox.
With --base, prints the speedup against a saved baseline.
"""
import argparse
import json
import statistics
import subprocess
import sys
import time
from pathlib import Path

BENCHES = [
    "fib", "loop", "globals", "arrays", "maps", "oop", "strings", "output",
    "startup",
]


def run_one(binary: str, bench: str, n: int) -> dict:
    script = "" if bench == "startup" else str(
        (Path(__file__).resolve().parent.parent / "bench" / f"{bench}.rscp"))
    if bench == "startup":
        script = str(Path(__file__).resolve().parent.parent / "examples" / "hello.rscp")
    if not script:
        raise SystemExit("bench not found: " + bench)

    # warmup (page cache, binary load)
    r = subprocess.run([binary, script], capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout, r.stderr, sep="\n")
        raise SystemExit(f"{bench} failed to run")

    times, out = [], r.stdout.strip()
    for _ in range(n):
        t0 = time.perf_counter()
        r = subprocess.run([binary, script], capture_output=True, text=True)
        dt = time.perf_counter() - t0
        if r.returncode != 0 or r.stdout.strip() != out:
            raise SystemExit(f"{bench}: inconsistent output\n{r.stdout}\n{r.stderr}")
        times.append(dt)
    return {
        "min_ms": min(times) * 1000,
        "median_ms": statistics.median(times) * 1000,
        "out": out.splitlines()[0][:40] if out else "",
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("binary", nargs="?", default="target/release/rscp")
    ap.add_argument("--n", type=int, default=5)
    ap.add_argument("--save", default=None)
    ap.add_argument("--base", default=None)
    args = ap.parse_args()

    base = {}
    if args.base:
        base = json.loads(Path(args.base).read_text())

    results = {}
    header = f"{'bench':10s} {'min ms':>10s} {'median ms':>10s}"
    if base:
        header += f" {'base ms':>10s} {'speedup':>8s}"
    print(header)
    print("-" * len(header))
    for b in BENCHES:
        r = run_one(args.binary, b, args.n)
        results[b] = r
        line = f"{b:10s} {r['min_ms']:10.1f} {r['median_ms']:10.1f}"
        if base and b in base:
            old = base[b]["min_ms"]
            line += f" {old:10.1f} {old / r['min_ms']:7.2f}x"
        print(line)
    print("-" * len(header))
    if base:
        ratios = [base[b]["min_ms"] / results[b]["min_ms"]
                  for b in results if b in base]
        if ratios:
            print(f"geometric mean speedup: "
                  f"{statistics.geometric_mean(ratios):.2f}x")

    if args.save:
        Path(args.save).write_text(json.dumps(results, indent=2))
        print(f"saved -> {args.save}")


if __name__ == "__main__":
    main()
