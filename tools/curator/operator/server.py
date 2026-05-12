#!/usr/bin/env python3
"""
Local operator dashboard for the curator pipeline.

Single-user, localhost-only. Reads manifests / channel drafts / logs and
exposes a few action endpoints (retry held, mark a channel draft pasted).
Browser UI at http://127.0.0.1:8088/.

Run:
    bash tools/curator/cli.sh ui            # spawns + opens browser
    python3 tools/curator/operator/server.py --port 8088 --no-browser

Read-only by design except for two safe mutations:
  - retry: flip a held candidate's curator_state back to 'pending'
  - mark-pasted: delete a channel-draft .txt file once the operator pasted it

For anything else (vetoes, editing voice anchors, running the pipeline),
use the terminal CLI. The dashboard is a glance + light-touch tool.
"""
import argparse
import datetime
import http.server
import json
import os
import socketserver
import subprocess
import sys
import threading
import urllib.parse
import webbrowser
from pathlib import Path

OPERATOR_DIR = Path(__file__).resolve().parent
CURATOR_DIR = OPERATOR_DIR.parent
WEBSITE_ROOT = CURATOR_DIR.parent.parent

HIVE_DIR = Path.home() / "Desktop" / "Fun" / "lab" / "publish_candidates"
AGI_DIR = Path.home() / "Desktop" / "AGI" / "data" / "publish_candidates"
CHANNEL_DIR = CURATOR_DIR / "channel_drafts"
LOG_DIR = CURATOR_DIR / "log"

HOST = "127.0.0.1"
DEFAULT_PORT = 8088


# ── Read helpers ──────────────────────────────────────────────────────────

def iter_candidates():
    for lab, dir_path in [("HIVE", HIVE_DIR), ("AGI", AGI_DIR)]:
        if not dir_path.is_dir():
            continue
        for f in sorted(dir_path.glob("*.json")):
            try:
                d = json.load(open(f))
            except Exception:
                continue
            d["_lab"] = lab
            d["_file"] = str(f)
            yield d


def get_status():
    candidates = list(iter_candidates())

    def summarize(c):
        return {
            "lab": c.get("_lab"),
            "id": c.get("id", ""),
            "type": c.get("type", ""),
            "tier": c.get("risk_tier"),
            "state": c.get("curator_state", "unknown"),
            "title": c.get("title", ""),
            "summary": c.get("summary", ""),
            "held_reason": c.get("held_reason", ""),
            "processing_started_at": c.get("processing_started_at", ""),
            "published_at": c.get("published_at", ""),
            "channels": c.get("channels", []),
        }

    queue = [summarize(c) for c in candidates
             if c.get("curator_state") not in ("published", "vetoed")]
    published = [summarize(c) for c in candidates
                 if c.get("curator_state") == "published"]
    published.sort(key=lambda x: x.get("published_at") or "", reverse=True)

    drafts = {"hackernews": [], "linkedin": []}
    for ch in ("hackernews", "linkedin"):
        d = CHANNEL_DIR / ch
        if d.is_dir():
            for f in sorted(d.glob("*.txt")):
                drafts[ch].append({
                    "id": f.stem,
                    "bytes": f.stat().st_size,
                    "mtime": datetime.datetime.fromtimestamp(
                        f.stat().st_mtime, tz=datetime.timezone.utc,
                    ).isoformat(),
                })

    try:
        out = subprocess.run(
            ["launchctl", "list"], capture_output=True, text=True, timeout=2,
        )
        loaded = out.stdout
    except Exception:
        loaded = ""
    launchd = {
        "curator": "com.harshith.website-curator" in loaded,
        "veto_check": "com.harshith.website-veto-check" in loaded,
    }

    today_log = LOG_DIR / f"{datetime.date.today().isoformat()}.log"
    log_excerpt = ""
    if today_log.exists():
        try:
            lines = today_log.read_text(errors="replace").splitlines()
            log_excerpt = "\n".join(lines[-40:])
        except Exception:
            log_excerpt = ""

    runs = recent_runs(limit=8)

    return {
        "today": datetime.date.today().isoformat(),
        "queue": queue,
        "published_recent": published[:5],
        "channel_drafts": drafts,
        "launchd": launchd,
        "log_excerpt": log_excerpt,
        "runs": runs,
    }


def recent_runs(limit=10):
    if not LOG_DIR.is_dir():
        return []
    log_files = sorted(LOG_DIR.glob("2*.log"), reverse=True)[:7]
    out = []
    for f in log_files:
        try:
            text = f.read_text(errors="replace")
        except Exception:
            continue
        run_ids = sorted(set(re.findall(r"\[(\d{8}-\d{6}-\d+)\]", text)),
                         reverse=True)
        for run_id in run_ids:
            run_lines = [ln for ln in text.splitlines() if f"[{run_id}]" in ln]
            blob = "\n".join(run_lines)
            if "FAILED" in blob:
                outcome = "fail"
            elif "curator run end (exit 0)" in blob:
                outcome = "ok"
            else:
                outcome = "partial"
            candidates = sum(1 for ln in run_lines if "── candidate:" in ln)
            out.append({
                "run_id": run_id,
                "outcome": outcome,
                "candidates": candidates,
                "source": f.name,
            })
            if len(out) >= limit:
                return out
    return out


# ── Mutation helpers ──────────────────────────────────────────────────────

def retry_candidate(target_id: str):
    for c in iter_candidates():
        if c.get("id") == target_id:
            f = Path(c["_file"])
            d = json.load(open(f))
            if d.get("curator_state") != "held":
                return {"ok": False,
                        "error": f"state is '{d.get('curator_state')}', not held"}
            d["curator_state"] = "pending"
            d.pop("held_reason", None)
            f.write_text(json.dumps(d, indent=2))
            return {"ok": True, "message": f"{target_id} → pending"}
    return {"ok": False, "error": "candidate not found"}


def get_channel_draft(channel: str, draft_id: str):
    if channel not in ("hackernews", "linkedin"):
        return None
    f = CHANNEL_DIR / channel / f"{draft_id}.txt"
    if not f.is_file():
        return None
    return f.read_text()


def delete_channel_draft(channel: str, draft_id: str) -> bool:
    if channel not in ("hackernews", "linkedin"):
        return False
    f = CHANNEL_DIR / channel / f"{draft_id}.txt"
    if not f.is_file():
        return False
    f.unlink()
    return True


# ── HTTP handler ──────────────────────────────────────────────────────────

import re  # used in recent_runs; imported here so it's available at runtime


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):  # quieter logs
        pass

    def _send_json(self, payload, status: int = 200):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _send_file(self, p: Path, content_type: str):
        if not p.is_file():
            self.send_response(404); self.end_headers(); return
        data = p.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        url = urllib.parse.urlparse(self.path)
        path = url.path
        qs = urllib.parse.parse_qs(url.query)

        if path in ("/", "/index.html"):
            self._send_file(OPERATOR_DIR / "dashboard.html",
                            "text/html; charset=utf-8")
        elif path == "/api/status":
            self._send_json(get_status())
        elif path == "/api/channel-draft":
            channel = qs.get("channel", [""])[0]
            cid = qs.get("id", [""])[0]
            text = get_channel_draft(channel, cid)
            if text is None:
                self._send_json({"ok": False, "error": "not found"}, 404)
            else:
                self._send_json({"ok": True, "content": text})
        else:
            self.send_response(404); self.end_headers()

    def do_POST(self):
        url = urllib.parse.urlparse(self.path)
        path = url.path
        length = int(self.headers.get("Content-Length", 0))
        try:
            data = json.loads(self.rfile.read(length).decode("utf-8") or "{}")
        except json.JSONDecodeError:
            data = {}

        if path == "/api/retry":
            target = (data.get("id") or "").strip()
            if not target:
                self._send_json({"ok": False, "error": "id required"}, 400)
                return
            result = retry_candidate(target)
            self._send_json(result, 200 if result.get("ok") else 400)
        else:
            self.send_response(404); self.end_headers()

    def do_DELETE(self):
        url = urllib.parse.urlparse(self.path)
        path = url.path
        qs = urllib.parse.parse_qs(url.query)

        if path == "/api/channel-draft":
            channel = qs.get("channel", [""])[0]
            cid = qs.get("id", [""])[0]
            ok = delete_channel_draft(channel, cid)
            self._send_json({"ok": ok})
        else:
            self.send_response(404); self.end_headers()


# ── Main ──────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--port", type=int, default=DEFAULT_PORT)
    p.add_argument("--no-browser", action="store_true",
                   help="don't auto-open browser")
    args = p.parse_args()

    try:
        server = socketserver.ThreadingTCPServer((HOST, args.port), Handler)
    except OSError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        print(f"  Port {args.port} may already be in use. Try --port 8089.",
              file=sys.stderr)
        sys.exit(1)

    server.daemon_threads = True
    url = f"http://{HOST}:{args.port}/"
    print(f"Operator dashboard at {url}")
    print(f"  (CTRL-C to stop)")

    if not args.no_browser:
        threading.Timer(0.5, lambda: webbrowser.open(url)).start()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nshutting down")
        server.shutdown()


if __name__ == "__main__":
    main()
