#!/usr/bin/env python3
"""
Cross-link integrity audit for the website.

Walks every .astro / .md / .mdx page under src/pages/ + components under
src/components/ + layouts under src/layouts/, extracts internal links and
asset references, and verifies each resolves to a real target.

Checks:
  - **broken_internal_link**     — `<a href="/path">` whose target doesn't
                                   exist under src/pages/. Handles Astro
                                   routing (foo.astro → /foo, foo/index.astro
                                   → /foo, foo/[slug].astro → /foo/anything).
  - **broken_anchor**            — `<a href="/path#frag">` where the target
                                   page has no heading with that slug.
  - **broken_image_src**         — `<img src="/asset">` whose file is missing
                                   under public/.
  - **broken_relative_import**   — `import X from '../foo.astro'` (frontmatter)
                                   whose target doesn't exist.

Does NOT check:
  - External links (http://, https://) — use --check-external to opt in.
  - mailto: / tel: / javascript: (always treated as valid).
  - Dynamic-route placeholders like /notes/[slug] are accepted as "exists"
    if the [slug].astro file is present (cannot enumerate all valid slugs).

Usage from website root:

    python3 tools/curator/check_links.py             # human-readable, exits 1 on issues
    python3 tools/curator/check_links.py --json      # machine-readable JSON
    python3 tools/curator/check_links.py --no-exit   # always exit 0
    python3 tools/curator/check_links.py --check-external  # also HEAD external URLs

Designed to be cheap (no network on default path) and run in pre-commit.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Layout / conventions
# ---------------------------------------------------------------------------

CURATOR_DIR = Path(__file__).resolve().parent
WEBSITE_ROOT = CURATOR_DIR.parent.parent
PAGES_DIR = WEBSITE_ROOT / "src" / "pages"
COMPONENTS_DIR = WEBSITE_ROOT / "src" / "components"
LAYOUTS_DIR = WEBSITE_ROOT / "src" / "layouts"
PUBLIC_DIR = WEBSITE_ROOT / "public"
ASTRO_CONFIG = WEBSITE_ROOT / "astro.config.mjs"

SCAN_DIRS = [PAGES_DIR, COMPONENTS_DIR, LAYOUTS_DIR]
SCAN_EXTS = {".astro", ".md", ".mdx", ".html"}


def read_astro_base() -> str:
    """Read the `base` setting from astro.config.mjs. Returns '' if absent."""
    if not ASTRO_CONFIG.exists():
        return ""
    try:
        text = ASTRO_CONFIG.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return ""
    # Strip line comments first so we don't match `// base: '/foo'`
    cleaned = re.sub(r"//[^\n]*", "", text)
    m = re.search(r"""base\s*:\s*["']([^"']+)["']""", cleaned)
    if not m:
        return ""
    base = m.group(1).rstrip("/")
    return base


# Resolved once at import time
SITE_BASE = read_astro_base()


def strip_base(url_path: str) -> str:
    """Strip the configured site base prefix from a URL path, if present.

    Astro `base: '/foo'` means all internal links are written as `/foo/page`
    but resolve at build time to `/page` under src/pages/.
    """
    if not SITE_BASE:
        return url_path
    if url_path == SITE_BASE:
        return "/"
    if url_path.startswith(SITE_BASE + "/"):
        return url_path[len(SITE_BASE):]
    return url_path

# ---------------------------------------------------------------------------
# Regexes (intentionally conservative — false-positive rate matters less than
# false-negative rate; better to flag a weird shape than to silently skip it)
# ---------------------------------------------------------------------------

# href + src attribute extraction (HTML / JSX style; tolerates single + double
# quotes; tolerates whitespace; intentionally does NOT match expression
# bindings like href={someVar} since those can't be statically resolved).
RE_HREF = re.compile(r'''(?:href|to)\s*=\s*["']([^"']+)["']''', re.IGNORECASE)
RE_SRC = re.compile(r'''(?:src)\s*=\s*["']([^"']+)["']''', re.IGNORECASE)

# Astro frontmatter import (between leading --- fences)
RE_IMPORT = re.compile(
    r'''^\s*import\s+(?:[^'"]+?\s+from\s+)?["']([^"']+)["']''',
    re.MULTILINE,
)

# Heading slug discovery (Astro's slug rules: lowercase, alphanumerics + dash,
# spaces → dashes, strip punctuation).
RE_HEADING = re.compile(r'^\s*#{1,6}\s+(.+?)\s*$', re.MULTILINE)
RE_HTML_HEADING = re.compile(
    r'<h[1-6][^>]*?(?:\s+id\s*=\s*["\']([^"\']+)["\'])?[^>]*>(.+?)</h[1-6]>',
    re.IGNORECASE | re.DOTALL,
)

# Any element with an id attribute (for anchor-fragment validation beyond
# just headings — components often expose props like id="subscribe" that
# render to `<section id="subscribe">` etc.)
RE_ELEMENT_ID = re.compile(r'''\bid\s*=\s*["']([\w-]+)["']''')

EXTERNAL_PREFIXES = ("http://", "https://", "mailto:", "tel:", "javascript:")
ALWAYS_VALID_PREFIXES = ("mailto:", "tel:", "javascript:", "#")

# href targets ending in these extensions are asset references (public/) not
# page references (src/pages/). Treats `<a href="/foo.pdf">` like `<img src>`.
ASSET_EXTENSIONS = {
    ".pdf", ".svg", ".png", ".jpg", ".jpeg", ".gif", ".webp", ".avif",
    ".ico", ".css", ".js", ".mjs", ".xml", ".json", ".txt", ".csv",
    ".tsv", ".webmanifest", ".woff", ".woff2", ".ttf", ".otf", ".mp4",
    ".webm", ".mp3", ".wav", ".zip", ".tar", ".gz",
}


def looks_like_asset(url_path: str) -> bool:
    """True if a URL path ends with a known asset extension."""
    p = url_path.split("?", 1)[0].split("#", 1)[0].lower()
    return any(p.endswith(ext) for ext in ASSET_EXTENSIONS)


# ---------------------------------------------------------------------------
# Page resolution
# ---------------------------------------------------------------------------


def slugify_heading(text: str) -> str:
    """Approximate Astro's heading-id slug generation."""
    text = text.lower().strip()
    # Strip code fences, links, emphasis
    text = re.sub(r"`+", "", text)
    text = re.sub(r"\[(.+?)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"[*_]+", "", text)
    # Replace whitespace + non-alphanum with dashes
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"\s+", "-", text)
    text = re.sub(r"-+", "-", text).strip("-")
    return text


def page_url_to_files(url_path: str) -> list[Path]:
    """Map a URL path like `/notes/foo` to candidate source files under PAGES_DIR.

    Astro routing:
      /                  → pages/index.astro
      /foo               → pages/foo.astro OR pages/foo/index.astro
      /foo/bar           → pages/foo/bar.astro OR pages/foo/bar/index.astro
      /foo/anything-here → pages/foo/[slug].astro (dynamic)

    Returns the list of candidate file paths in priority order.
    """
    # Strip trailing slash + leading slash
    p = url_path.strip("/")
    if not p:
        return [PAGES_DIR / "index.astro"]

    candidates: list[Path] = []
    base = PAGES_DIR / p

    for ext in (".astro", ".md", ".mdx", ".html"):
        candidates.append(base.with_suffix(ext))
        candidates.append(base / f"index{ext}")

    # Dynamic route: pages/<parent>/[slug].astro
    parent = base.parent
    if parent != PAGES_DIR.parent:
        for ext in (".astro", ".md", ".mdx"):
            for stub in parent.glob(f"[[]*[]]{ext}"):
                candidates.append(stub)

    return candidates


def page_resolves(url_path: str) -> tuple[bool, Path | None]:
    """True if a URL path resolves to any page source. Returns (ok, file)."""
    for cand in page_url_to_files(url_path):
        if cand.exists():
            return True, cand
    return False, None


def public_asset_exists(url_path: str) -> bool:
    """True if a /asset.png style path resolves to public/asset.png."""
    p = url_path.lstrip("/")
    return (PUBLIC_DIR / p).exists()


# ---------------------------------------------------------------------------
# Heading extraction for anchor checks
# ---------------------------------------------------------------------------


def headings_in_page(file_path: Path) -> set[str]:
    """Return the set of heading slugs in a page file."""
    if not file_path.exists():
        return set()
    try:
        text = file_path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return set()

    slugs: set[str] = set()
    # Markdown-style # headings
    for m in RE_HEADING.finditer(text):
        slugs.add(slugify_heading(m.group(1)))
    # HTML headings with explicit id attribute
    for m in RE_HTML_HEADING.finditer(text):
        explicit_id, inner = m.group(1), m.group(2)
        if explicit_id:
            slugs.add(explicit_id.strip())
        # Also derive from inner text (strip nested tags)
        plain = re.sub(r"<[^>]+>", "", inner)
        if plain.strip():
            slugs.add(slugify_heading(plain))
    # Any element with id="..." attribute (covers components that emit
    # `<section id="foo">` via prop-passing, e.g., SectionHead id="subscribe")
    for m in RE_ELEMENT_ID.finditer(text):
        slugs.add(m.group(1))
    return slugs


# ---------------------------------------------------------------------------
# Link extraction + validation
# ---------------------------------------------------------------------------


def extract_links(file_path: Path) -> list[tuple[int, str, str]]:
    """Yield (line_number, kind, target) for each href/src/import in file."""
    try:
        text = file_path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return []

    results: list[tuple[int, str, str]] = []
    lines = text.splitlines()

    # href / to attributes
    for m in RE_HREF.finditer(text):
        line_no = text[: m.start()].count("\n") + 1
        results.append((line_no, "href", m.group(1)))

    # src attributes
    for m in RE_SRC.finditer(text):
        line_no = text[: m.start()].count("\n") + 1
        results.append((line_no, "src", m.group(1)))

    # frontmatter imports (only relevant for .astro)
    if file_path.suffix == ".astro":
        # find the frontmatter block between leading --- fences
        fm_match = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
        if fm_match:
            fm_text = fm_match.group(1)
            for m in RE_IMPORT.finditer(fm_text):
                # line number is within the frontmatter (line 1 = ---, line 2 = first code line)
                line_no = fm_text[: m.start()].count("\n") + 2
                results.append((line_no, "import", m.group(1)))

    return results


def validate_link(
    source_file: Path,
    line_no: int,
    kind: str,
    target: str,
    check_external: bool = False,
) -> dict | None:
    """Return an issue dict if the link is broken, else None."""

    # Skip always-valid prefixes
    if target.startswith(ALWAYS_VALID_PREFIXES):
        return None

    # External
    if target.startswith(("http://", "https://")):
        if not check_external:
            return None
        # External link checking: HEAD with short timeout.
        try:
            import urllib.request
            req = urllib.request.Request(target, method="HEAD")
            with urllib.request.urlopen(req, timeout=6) as resp:
                if resp.status >= 400:
                    return {
                        "file": str(source_file.relative_to(WEBSITE_ROOT)),
                        "line": line_no,
                        "kind": "broken_external_link",
                        "target": target,
                        "detail": f"HTTP {resp.status}",
                    }
        except Exception as e:
            return {
                "file": str(source_file.relative_to(WEBSITE_ROOT)),
                "line": line_no,
                "kind": "broken_external_link",
                "target": target,
                "detail": f"{type(e).__name__}: {e}",
            }
        return None

    # Imports (relative paths in frontmatter)
    if kind == "import":
        if target.startswith("."):
            resolved = (source_file.parent / target).resolve()
            # Try with declared suffix first, then common Astro suffixes
            cands = [resolved]
            if resolved.suffix == "":
                for ext in (".astro", ".ts", ".tsx", ".js", ".jsx", ".md"):
                    cands.append(resolved.with_suffix(ext))
            for c in cands:
                if c.exists():
                    return None
            return {
                "file": str(source_file.relative_to(WEBSITE_ROOT)),
                "line": line_no,
                "kind": "broken_relative_import",
                "target": target,
                "detail": f"resolved to {resolved} — file not found",
            }
        return None  # bare module imports (e.g., 'astro' / npm packages) are out of scope

    # Internal href / src — split off anchor fragment
    fragment = ""
    url_part = target
    if "#" in target and not target.startswith("#"):
        url_part, fragment = target.split("#", 1)
        url_part = url_part.rstrip("/")

    # Strip site base prefix (Astro `base: '/foo'` setting) before resolving.
    # The site config is base-prefixed; source links are written with the
    # prefix but resolve to source files without it.
    url_resolved = strip_base(url_part)

    # Image src or other asset under /public/
    if kind == "src":
        if url_resolved.startswith("/"):
            if not public_asset_exists(url_resolved):
                return {
                    "file": str(source_file.relative_to(WEBSITE_ROOT)),
                    "line": line_no,
                    "kind": "broken_image_src",
                    "target": target,
                    "detail": f"no file at public{url_resolved}",
                }
        return None

    # href — must resolve to a page
    if not url_resolved.startswith("/"):
        # Relative href in JSX is unusual; skip
        return None

    # If the href looks like an asset (ends in .pdf/.svg/.png/etc.), validate
    # against public/ rather than treating as a missing page. This covers
    # `<a href="/foo.pdf">download</a>` + `<link rel="icon" href="/foo.svg">`.
    if looks_like_asset(url_resolved):
        if not public_asset_exists(url_resolved):
            return {
                "file": str(source_file.relative_to(WEBSITE_ROOT)),
                "line": line_no,
                "kind": "broken_asset_href",
                "target": target,
                "detail": f"no file at public{url_resolved}",
            }
        return None

    ok, target_file = page_resolves(url_resolved)
    if not ok:
        return {
            "file": str(source_file.relative_to(WEBSITE_ROOT)),
            "line": line_no,
            "kind": "broken_internal_link",
            "target": target,
            "detail": f"no page resolves to {url_resolved}"
                      + (f" (after stripping base '{SITE_BASE}')" if SITE_BASE and url_resolved != url_part else ""),
        }

    # If fragment, check it exists on target
    if fragment and target_file is not None:
        slugs = headings_in_page(target_file)
        if fragment not in slugs:
            return {
                "file": str(source_file.relative_to(WEBSITE_ROOT)),
                "line": line_no,
                "kind": "broken_anchor",
                "target": target,
                "detail": f"page {url_resolved} exists but has no heading slug '{fragment}'",
            }

    return None


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def gather_source_files(file_args: list[str]) -> list[Path]:
    """Gather files to audit. If args provided, use them; else walk SCAN_DIRS."""
    if file_args:
        return [Path(f).resolve() for f in file_args if Path(f).exists()]
    files: list[Path] = []
    for d in SCAN_DIRS:
        if not d.exists():
            continue
        for p in d.rglob("*"):
            if p.is_file() and p.suffix in SCAN_EXTS:
                files.append(p)
    return files


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit website for broken internal links + asset references.",
    )
    parser.add_argument("files", nargs="*",
                        help="Specific files to audit (default: all under src/pages/, src/components/, src/layouts/).")
    parser.add_argument("--json", action="store_true", help="Output JSON.")
    parser.add_argument("--no-exit", action="store_true",
                        help="Always exit 0 even if issues found.")
    parser.add_argument("--check-external", action="store_true",
                        help="Also HEAD external URLs (slower; needs network).")
    args = parser.parse_args()

    files = gather_source_files(args.files)
    issues: list[dict] = []

    for f in files:
        for line_no, kind, target in extract_links(f):
            issue = validate_link(f, line_no, kind, target,
                                  check_external=args.check_external)
            if issue:
                issues.append(issue)

    if args.json:
        print(json.dumps({
            "audited_files": len(files),
            "issues_found": len(issues),
            "issues": issues,
        }, indent=2))
    else:
        if not issues:
            print(f"No issues found across {len(files)} audited files. (Audited on {__import__('datetime').date.today()})")
        else:
            print(f"Found {len(issues)} issue(s) across {len(files)} audited files:\n")
            # Group by file for readability
            by_file: dict[str, list[dict]] = {}
            for iss in issues:
                by_file.setdefault(iss["file"], []).append(iss)
            for fpath, fissues in sorted(by_file.items()):
                print(f"  {fpath}")
                for iss in fissues:
                    print(f"    line {iss['line']:>4}  [{iss['kind']}]  {iss['target']}")
                    print(f"                {iss['detail']}")
                print()

    if issues and not args.no_exit:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
