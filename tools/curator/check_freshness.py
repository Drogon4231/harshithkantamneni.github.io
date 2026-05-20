#!/usr/bin/env python3
"""
Content freshness audit for the website.

Reads every published page's `meta` block (Astro `export const meta = {...}`)
to determine when content should be re-verified. Time-sensitive content
that references current state (lab cycle counts, telemetry numbers, ongoing
feature claims, "today" statements) needs periodic re-verification by the
operator; this tool flags pages whose `last_verified` date has exceeded
their `verification_interval_days`.

Convention (add to meta block on time-sensitive pages):

  export const meta = {
    title: "...",
    date: "2026-05-05",
    freshness_class: "time-sensitive",     // or "evergreen" | "factual-snapshot"
    last_verified: "2026-05-20",           // ISO date; defaults to `date` if absent
    verification_interval_days: 90,        // optional; default 90 for time-sensitive
    verification_subject: "lab cycle count, RUSTSEC IDs",  // free text; what to recheck
  };

Class semantics:
  - **time-sensitive**   — references current state; needs periodic re-verify.
                           Default interval: 90 days.
  - **evergreen**         — universal principles / mathematical claims / historical
                           analyses without ongoing-claim semantics. NEVER stale.
  - **factual-snapshot**  — explicitly dated observation of a moment in time
                           ("Cross-Lab Diagnosis April 2026"). By design fixed
                           at the date; not stale.

If `freshness_class` is missing, the default is inferred from the page's
directory under src/pages/:
  - pages/labs/, pages/now.astro       → time-sensitive (60-day default)
  - pages/notes/, pages/reports/       → factual-snapshot (analytical posts)
  - pages/about, pages/index, contact  → evergreen
  - everything else                    → time-sensitive (conservative)

Usage from website root:

    python3 tools/curator/check_freshness.py             # human-readable report
    python3 tools/curator/check_freshness.py --json      # JSON
    python3 tools/curator/check_freshness.py --no-exit   # always exit 0
    python3 tools/curator/check_freshness.py --grace-days 14  # also flag items within N days of expiry
    python3 tools/curator/check_freshness.py --mark-verified src/pages/labs/hive.astro
        → updates last_verified to today (idempotent; appends meta field if missing)
"""
from __future__ import annotations

import argparse
import datetime
import json
import re
import sys
from pathlib import Path

CURATOR_DIR = Path(__file__).resolve().parent
WEBSITE_ROOT = CURATOR_DIR.parent.parent
PAGES_DIR = WEBSITE_ROOT / "src" / "pages"

TODAY = datetime.date.today()

# ---------------------------------------------------------------------------
# Default freshness rules (used when frontmatter doesn't specify)
# ---------------------------------------------------------------------------

DEFAULT_INTERVAL_DAYS = 90

# (path_prefix relative to src/pages/, freshness_class, interval_days)
DEFAULT_BY_PATH: list[tuple[str, str, int]] = [
    ("labs/",      "time-sensitive",   60),
    ("now",        "time-sensitive",   30),
    ("notes/",     "factual-snapshot",  0),
    ("reports/",   "factual-snapshot",  0),
    ("about",      "evergreen",         0),
    ("contact",    "evergreen",         0),
    ("index",      "evergreen",         0),
    ("404",        "evergreen",         0),
]


def default_for(path_rel: str) -> tuple[str, int]:
    """Pick default freshness_class + interval for a page given its path."""
    for prefix, cls, interval in DEFAULT_BY_PATH:
        if path_rel.startswith(prefix) or path_rel == prefix + ".astro" or path_rel == prefix + ".md":
            return cls, interval
    return "time-sensitive", DEFAULT_INTERVAL_DAYS


# ---------------------------------------------------------------------------
# Meta block parsing (Astro: `export const meta = { ... };`)
# ---------------------------------------------------------------------------

RE_META_BLOCK = re.compile(
    r"export\s+const\s+meta\s*=\s*\{(.*?)\}\s*;",
    re.DOTALL,
)
# Field extraction inside the meta block. Handles single + double quotes;
# tolerates trailing commas; only matches string-literal values.
RE_META_FIELD = re.compile(
    r'''(\w+)\s*:\s*(?:"([^"]*)"|'([^']*)'|(\d+))''',
)


def parse_meta(file_path: Path) -> dict | None:
    """Parse the meta block from an Astro page. Returns dict or None if missing."""
    try:
        text = file_path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return None
    m = RE_META_BLOCK.search(text)
    if not m:
        return None
    block = m.group(1)
    meta: dict[str, str | int] = {}
    for field_m in RE_META_FIELD.finditer(block):
        key = field_m.group(1)
        dq, sq, num = field_m.group(2), field_m.group(3), field_m.group(4)
        if num is not None:
            meta[key] = int(num)
        else:
            meta[key] = dq if dq is not None else (sq or "")
    return meta


def parse_iso_date(s: str | None) -> datetime.date | None:
    """Parse ISO-style date 'YYYY-MM-DD'. Returns None on failure."""
    if not s:
        return None
    try:
        return datetime.date.fromisoformat(s)
    except (ValueError, TypeError):
        return None


# ---------------------------------------------------------------------------
# Audit logic
# ---------------------------------------------------------------------------


def audit_page(file_path: Path, grace_days: int = 0) -> dict | None:
    """Audit a single page. Returns issue dict if stale, else None.

    grace_days: if >0, also flag items within `grace_days` of becoming stale
    (so operator can re-verify before the deadline rather than after).
    """
    meta = parse_meta(file_path)
    if meta is None:
        return None  # not a published page with meta block

    rel = str(file_path.relative_to(PAGES_DIR))
    default_cls, default_interval = default_for(rel)

    cls = meta.get("freshness_class") or default_cls
    interval = int(meta.get("verification_interval_days") or default_interval)

    # Never-stale classes
    if cls in ("evergreen", "factual-snapshot"):
        return None

    # Time-sensitive: compute age
    last_verified = parse_iso_date(meta.get("last_verified"))
    if last_verified is None:
        last_verified = parse_iso_date(meta.get("date"))
    if last_verified is None:
        # No verifiable date — flag as needs-attention
        return {
            "file": str(file_path.relative_to(WEBSITE_ROOT)),
            "kind": "missing_verification_anchor",
            "freshness_class": cls,
            "detail": "no `last_verified` or `date` field in meta — cannot compute staleness",
        }

    age = (TODAY - last_verified).days
    days_until_stale = interval - age

    if days_until_stale <= 0:
        return {
            "file": str(file_path.relative_to(WEBSITE_ROOT)),
            "kind": "stale_content",
            "freshness_class": cls,
            "title": meta.get("title", ""),
            "last_verified": last_verified.isoformat(),
            "age_days": age,
            "interval_days": interval,
            "days_overdue": -days_until_stale,
            "verification_subject": meta.get("verification_subject", "(not specified)"),
        }

    if grace_days > 0 and days_until_stale <= grace_days:
        return {
            "file": str(file_path.relative_to(WEBSITE_ROOT)),
            "kind": "expiring_soon",
            "freshness_class": cls,
            "title": meta.get("title", ""),
            "last_verified": last_verified.isoformat(),
            "age_days": age,
            "interval_days": interval,
            "days_until_stale": days_until_stale,
            "verification_subject": meta.get("verification_subject", "(not specified)"),
        }

    return None


# ---------------------------------------------------------------------------
# Mark-verified: idempotent update of last_verified in a meta block
# ---------------------------------------------------------------------------


def mark_verified(file_path: Path) -> bool:
    """Set/update the `last_verified` field in a page's meta block to today.

    Returns True on success, False otherwise. Idempotent.
    """
    try:
        text = file_path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        print(f"ERROR: cannot read {file_path}", file=sys.stderr)
        return False

    m = RE_META_BLOCK.search(text)
    if not m:
        print(f"ERROR: no meta block found in {file_path}", file=sys.stderr)
        return False

    today_iso = TODAY.isoformat()
    block = m.group(1)
    block_start, block_end = m.start(1), m.end(1)

    if "last_verified" in block:
        # Replace existing value
        new_block = re.sub(
            r'(last_verified\s*:\s*)["\'][^"\']*["\']',
            rf'\1"{today_iso}"',
            block,
            count=1,
        )
    else:
        # Append a new line before the closing brace; preserve trailing whitespace
        # Insert before the final newline of the block (which abuts the closing `}`)
        if block.rstrip().endswith(","):
            # Easy case: existing trailing comma
            new_block = block.rstrip() + f'\n  last_verified: "{today_iso}",\n'
        else:
            # Add comma then new line
            new_block = block.rstrip() + f',\n  last_verified: "{today_iso}",\n'

    new_text = text[:block_start] + new_block + text[block_end:]
    file_path.write_text(new_text, encoding="utf-8")
    print(f"Marked {file_path.relative_to(WEBSITE_ROOT)} as verified on {today_iso}")
    return True


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def gather_pages() -> list[Path]:
    return [p for p in PAGES_DIR.rglob("*")
            if p.is_file() and p.suffix in (".astro", ".md", ".mdx")]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit website pages for content freshness / staleness.",
    )
    parser.add_argument("--json", action="store_true", help="Output JSON.")
    parser.add_argument("--no-exit", action="store_true",
                        help="Always exit 0 even if stale items found.")
    parser.add_argument("--grace-days", type=int, default=0,
                        help="Also flag items within N days of becoming stale.")
    parser.add_argument("--mark-verified", metavar="PATH",
                        help="Update last_verified to today for the given page (no audit).")
    args = parser.parse_args()

    if args.mark_verified:
        target = Path(args.mark_verified).resolve()
        if not target.exists():
            print(f"ERROR: file not found: {target}", file=sys.stderr)
            return 2
        return 0 if mark_verified(target) else 2

    pages = gather_pages()
    issues: list[dict] = []
    for p in pages:
        iss = audit_page(p, grace_days=args.grace_days)
        if iss:
            issues.append(iss)

    if args.json:
        print(json.dumps({
            "audited_pages": len(pages),
            "issues_found": len(issues),
            "today": TODAY.isoformat(),
            "issues": issues,
        }, indent=2))
    else:
        if not issues:
            print(f"All {len(pages)} pages are fresh. (Audited on {TODAY})")
        else:
            stale = [i for i in issues if i["kind"] == "stale_content"]
            soon = [i for i in issues if i["kind"] == "expiring_soon"]
            missing = [i for i in issues if i["kind"] == "missing_verification_anchor"]
            print(f"Freshness audit ({TODAY}): {len(pages)} pages, {len(issues)} issue(s)\n")

            if stale:
                print(f"  STALE — {len(stale)} pages overdue for re-verification:")
                for i in stale:
                    print(f"    {i['file']}")
                    print(f"      class: {i['freshness_class']}  last verified: {i['last_verified']}  age: {i['age_days']}d  overdue by: {i['days_overdue']}d")
                    print(f"      subject: {i['verification_subject']}")
                print()
            if soon:
                print(f"  EXPIRING SOON — {len(soon)} pages within grace window:")
                for i in soon:
                    print(f"    {i['file']}  ({i['days_until_stale']}d until stale)")
                    print(f"      subject: {i['verification_subject']}")
                print()
            if missing:
                print(f"  MISSING ANCHOR — {len(missing)} time-sensitive pages with no `date` or `last_verified`:")
                for i in missing:
                    print(f"    {i['file']}")
                print()

            print("Re-verify a page after rechecking its claims:")
            print("  python3 tools/curator/check_freshness.py --mark-verified <path>\n")

    if issues and not args.no_exit:
        # Distinguish severity: stale = exit 1; expiring_soon + missing = warning (exit 0)
        if any(i["kind"] == "stale_content" for i in issues):
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
