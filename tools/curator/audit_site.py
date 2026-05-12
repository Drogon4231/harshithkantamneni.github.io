#!/usr/bin/env python3
"""
Audit the website for content issues.

Checks run against every .astro / .md / .js file under src/pages/:

  - **future_date**     — a date in frontmatter or body that's after today.
                          Catches ISO format (2026-05-15) and English (May 15,
                          2026). Year defaults to current year if omitted.
  - **verify_marker**   — `[VERIFY ...]` markers left in. The curator validator
                          should already block these on new publishes, but
                          old pages may have them.
  - **todo_marker**     — TODO / FIXME / XXX / HACK markers in published text.
  - **forbidden_phrase** — cargo-cult phrases from
                          tools/curator/forbidden_phrases.txt (word-boundary
                          matched, blank lines and comments skipped).

Run from website root:

    python3 tools/curator/audit_site.py             # human-readable report
    python3 tools/curator/audit_site.py --json      # machine-readable
    python3 tools/curator/audit_site.py --no-exit   # always exit 0
                                                     # (default exits 1 if any
                                                     # issue found)
"""
import argparse
import datetime
import json
import re
import sys
from pathlib import Path

CURATOR_DIR = Path(__file__).resolve().parent
WEBSITE_ROOT = CURATOR_DIR.parent.parent
PAGES_DIR = WEBSITE_ROOT / "src" / "pages"
FORBIDDEN_FILE = CURATOR_DIR / "forbidden_phrases.txt"

TODAY = datetime.date.today()

MONTHS_FULL = ["January", "February", "March", "April", "May", "June",
               "July", "August", "September", "October", "November", "December"]
MONTHS_SHORT = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

PAT_ISO = re.compile(r"\b(\d{4})-(\d{2})-(\d{2})\b")
PAT_HUMAN = re.compile(
    r"\b(" + "|".join(MONTHS_FULL + MONTHS_SHORT)
    + r")\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s+(\d{4}))?\b",
    re.IGNORECASE,
)
PAT_VERIFY = re.compile(r"\[VERIFY[^\]]*\]")
PAT_TODO = re.compile(r"\b(TODO|FIXME|XXX|HACK)\b")

MONTH_INDEX = {m.lower(): i + 1 for i, m in enumerate(MONTHS_FULL)}
MONTH_INDEX.update({m.lower(): i + 1 for i, m in enumerate(MONTHS_SHORT)})


def parse_iso(m: re.Match) -> datetime.date | None:
    try:
        return datetime.date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    except ValueError:
        return None


def parse_human(m: re.Match) -> datetime.date | None:
    month = MONTH_INDEX.get(m.group(1).lower())
    if month is None:
        return None
    day = int(m.group(2))
    year = int(m.group(3)) if m.group(3) else TODAY.year
    try:
        return datetime.date(year, month, day)
    except ValueError:
        return None


def find_dates(text: str):
    """Yield (line_no, matched_str, parsed_date) for every date found."""
    for m in PAT_ISO.finditer(text):
        d = parse_iso(m)
        if d:
            yield (text[:m.start()].count("\n") + 1, m.group(0), d)
    for m in PAT_HUMAN.finditer(text):
        d = parse_human(m)
        if d:
            yield (text[:m.start()].count("\n") + 1, m.group(0), d)


def load_forbidden() -> list[str]:
    if not FORBIDDEN_FILE.exists():
        return []
    out = []
    for line in FORBIDDEN_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        out.append(line.lower())
    return out


def audit_file(p: Path, forbidden: list[str]) -> list[dict]:
    text = p.read_text(errors="replace")
    issues = []

    for lineno, matched, dt in find_dates(text):
        if dt > TODAY:
            issues.append({
                "line": lineno, "type": "future_date",
                "found": matched, "parsed": str(dt),
                "days_future": (dt - TODAY).days,
            })

    for m in PAT_VERIFY.finditer(text):
        issues.append({
            "line": text[:m.start()].count("\n") + 1,
            "type": "verify_marker", "found": m.group(0),
        })

    for m in PAT_TODO.finditer(text):
        issues.append({
            "line": text[:m.start()].count("\n") + 1,
            "type": "todo_marker", "found": m.group(0),
        })

    text_lower = text.lower()
    for phrase in forbidden:
        start = 0
        while True:
            idx = text_lower.find(phrase, start)
            if idx == -1:
                break
            prev = text_lower[idx - 1] if idx > 0 else " "
            nxt_pos = idx + len(phrase)
            nxt = text_lower[nxt_pos] if nxt_pos < len(text_lower) else " "
            if not prev.isalnum() and not nxt.isalnum():
                issues.append({
                    "line": text[:idx].count("\n") + 1,
                    "type": "forbidden_phrase", "found": phrase,
                })
            start = idx + len(phrase)

    issues.sort(key=lambda x: (x["line"], x["type"]))
    return issues


def main() -> None:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--json", action="store_true", help="machine-readable output")
    p.add_argument("--no-exit", action="store_true",
                   help="always exit 0 (default: exit 1 if issues found)")
    p.add_argument("--check-style", action="store_true",
                   help="also flag forbidden phrases from forbidden_phrases.txt "
                        "(off by default — the existing site uses some of them "
                        "intentionally in the operator's voice; the curator's "
                        "own validator already gates new content)")
    args = p.parse_args()

    forbidden = load_forbidden() if args.check_style else []
    all_results: dict[str, list[dict]] = {}

    file_iter = sorted(
        list(PAGES_DIR.rglob("*.astro"))
        + list(PAGES_DIR.rglob("*.md"))
        + list(PAGES_DIR.rglob("*.js"))
    )

    for f in file_iter:
        if not f.is_file():
            continue
        try:
            issues = audit_file(f, forbidden)
        except Exception as e:
            issues = [{"line": 0, "type": "audit_error", "found": str(e)}]
        if issues:
            all_results[str(f.relative_to(WEBSITE_ROOT))] = issues

    if args.json:
        print(json.dumps({"today": str(TODAY), "files": all_results}, indent=2))
        sys.exit(0 if args.no_exit or not all_results else 1)

    # Human output
    if not all_results:
        print(f"No issues found. (Audited on {TODAY})")
        sys.exit(0)

    is_tty = sys.stdout.isatty()
    BOLD = "\033[1m" if is_tty else ""
    RED = "\033[31m" if is_tty else ""
    YELLOW = "\033[33m" if is_tty else ""
    DIM = "\033[2m" if is_tty else ""
    OFF = "\033[0m" if is_tty else ""

    totals: dict[str, int] = {}
    print(f"Audit on {TODAY}. Findings:")
    print()
    for path, issues in all_results.items():
        print(f"{BOLD}{path}{OFF}")
        for i in issues:
            t = i["type"]
            totals[t] = totals.get(t, 0) + 1
            if t == "future_date":
                colour = RED
                tag = "FUTURE DATE"
                desc = (f"{i['found']!r} → parsed {i['parsed']} "
                        f"(+{i['days_future']}d from today)")
            elif t == "verify_marker":
                colour = YELLOW
                tag = "VERIFY    "
                desc = i["found"]
            elif t == "todo_marker":
                colour = YELLOW
                tag = "TODO      "
                desc = i["found"]
            elif t == "forbidden_phrase":
                colour = YELLOW
                tag = "FORBIDDEN "
                desc = repr(i["found"])
            else:
                colour = RED
                tag = t.upper().ljust(10)
                desc = i.get("found", "")
            print(f"  {DIM}L{i['line']:>4}{OFF}  {colour}{tag}{OFF}  {desc}")
        print()

    summary_bits = [f"{n} {t}" for t, n in sorted(totals.items())]
    total = sum(totals.values())
    print(f"Total: {total} issue(s) across {len(all_results)} file(s)  "
          f"[{', '.join(summary_bits)}]")
    sys.exit(0 if args.no_exit else 1)


if __name__ == "__main__":
    main()
