#!/usr/bin/env python3
"""Reusable file-watcher loop: watches a directory, processes files, tracks state.

Usage:
    python file-watcher.py                    # Process once
    python file-watcher.py --watch            # Poll continuously
    python file-watcher.py --watch --interval 5  # Poll every 5 seconds (default: 1)

Customize by editing the PROCESSOR and CONFIG dicts below.
"""
import csv
import json
import os
import shutil
import sys
import time
from pathlib import Path

# ── Configuration (customize per task) ─────────────────────────────
BASE_DIR = Path(__file__).resolve().parent
INCOMING = BASE_DIR / "incoming"
DONE = BASE_DIR / "done"
RESULTS_CSV = BASE_DIR / "results.csv"
STATE_MD = BASE_DIR / "STATE.md"

# How to process a single file — override this function for your task
def process_file(filepath: Path) -> dict:
    """Read a file and return stats. Override for domain-specific logic."""
    text = filepath.read_text(encoding="utf-8")
    return {
        "filename": filepath.name,
        "lines": len(text.splitlines()),
        "words": len(text.split()),
        "chars": len(text),
    }

CSV_HEADERS = ["filename", "lines", "words", "chars"]
# ────────────────────────────────────────────────────────────────────


def init_csv():
    if not RESULTS_CSV.exists():
        with open(RESULTS_CSV, "w", newline="") as f:
            csv.writer(f).writerow(CSV_HEADERS)
        print(f"Created {RESULTS_CSV}")


def append_result(result: dict):
    with open(RESULTS_CSV, "a", newline="") as f:
        csv.DictWriter(f, fieldnames=CSV_HEADERS).writerow(result)


def write_state(summary: dict):
    """Write lightweight code-task STATE.md."""
    content = f"""# File Processing State

## Summary
- **Total files processed:** {summary['total_files']}
- **Total words:** {summary['total_words']}
- **Status:** COMPLETE

## Results
Results written to {RESULTS_CSV.name}
"""
    STATE_MD.write_text(content)
    print(f"Wrote {STATE_MD}")


def process_all():
    """Process all .txt files currently in incoming/."""
    os.makedirs(DONE, exist_ok=True)
    txt_files = sorted(INCOMING.glob("*.txt"))
    if not txt_files:
        print("No files to process.")
        return

    results = []
    for fp in txt_files:
        print(f"Processing: {fp.name}")
        stats = process_file(fp)
        print(f"  lines={stats['lines']}, words={stats['words']}, chars={stats['chars']}")
        append_result(stats)
        shutil.move(str(fp), str(DONE / fp.name))
        print(f"  Moved to done/{fp.name}")
        results.append(stats)

    total_words = sum(r["words"] for r in results)
    write_state({"total_files": len(results), "total_words": total_words})
    print(f"\nDone. {len(results)} file(s) processed, {total_words} total words.")


def watch_loop(interval: int = 1):
    print(f"Watching {INCOMING} every {interval}s (Ctrl+C to stop)...")
    try:
        while True:
            process_all()
            time.sleep(interval)
    except KeyboardInterrupt:
        print("\nWatcher stopped.")


if __name__ == "__main__":
    init_csv()
    if "--watch" in sys.argv:
        idx = sys.argv.index("--watch")
        iv = int(sys.argv[idx + 1]) if idx + 1 < len(sys.argv) and sys.argv[idx + 1].isdigit() else 1
        watch_loop(iv)
    else:
        process_all()
