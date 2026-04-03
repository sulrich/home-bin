#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests>=2.31",
# ]
# ///
"""
mn8_fec_monitor.py — MN-8 Congressional Race FEC Monitor
Tracks campaign finance data, filings, and new entrants for
Minnesota's 8th Congressional District (2026 cycle).

Usage:
    uv run mn8_fec_monitor.py [--dry-run] [--force-all] [--markdown]

    --dry-run    Print what would be saved without writing files
    --force-all  Ignore state file, report everything as new
    --markdown   Also write a daily markdown report
"""

import json
import os
import re
import sys
import time
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from email.utils import format_datetime
from html import escape
from pathlib import Path

import requests

# ─── Configuration ───────────────────────────────────────────────────────────

# FEC API — DEMO_KEY works but is rate-limited (1000/hr).
# Get a real key at https://api.data.gov/signup/ for production use.
FEC_API_KEY = os.environ.get("FEC_API_KEY", "DEMO_KEY")
FEC_API_BASE = "https://api.open.fec.gov/v1"

# Race parameters
STATE = "MN"
DISTRICT = "08"
ELECTION_YEAR = 2026

# Candidates we're specifically tracking
TRACKED_CANDIDATES = {
    "H6MN08179": {"name": "Trina Swanson", "party": "DFL", "role": "challenger"},
    "H6MN08138": {"name": "Cyle Cramer", "party": "DFL", "role": "challenger"},
    "H8MN08043": {"name": "Pete Stauber", "party": "REP", "role": "incumbent"},
}

# File paths
WWW_DIR = Path("/Volumes/media/dyn.botwerks.net/www")
OC_DIR = Path.home() / "nanoclaw"
CACHE_DIR = OC_DIR / ".cache"
STATE_FILE = CACHE_DIR / "mn8_fec_state.json"
OUTPUT_DIR = OC_DIR / "reports"
RSS_DIR = WWW_DIR / "rss"
RSS_FILE = RSS_DIR / "mn8-fec.rss"
RSS_MAX_ITEMS = 60

# Central timezone
CENTRAL_TZ = timezone(timedelta(hours=-6))

# API politeness
REQUEST_DELAY = 1.0

# ─── FEC API Client ──────────────────────────────────────────────────────────

SESSION = requests.Session()
SESSION.headers.update({"Accept": "application/json"})


def fec_get(endpoint: str, params: dict = None) -> dict | None:
    """
    Make a request to the FEC API with retry on rate limiting.
    Returns None on failure (distinguishes from empty results).
    """
    params = params or {}
    params["api_key"] = FEC_API_KEY
    url = f"{FEC_API_BASE}{endpoint}"

    max_retries = 3
    for attempt in range(max_retries):
        try:
            resp = SESSION.get(url, params=params, timeout=30)
            if resp.status_code == 429:
                wait = (attempt + 1) * 10
                print(f"\n    ⏳ Rate limited, waiting {wait}s...", end=" ", flush=True)
                time.sleep(wait)
                continue
            resp.raise_for_status()
            return resp.json()
        except requests.RequestException as e:
            print(f"  ⚠ FEC API error: {e}")
            if attempt < max_retries - 1:
                time.sleep(5)
                continue
            return None

    return None


# ─── Data Collection ─────────────────────────────────────────────────────────


def get_all_candidates() -> list[dict] | None:
    """Get all candidates filed for MN-08 in the target election year.
    Returns None on API failure (vs empty list for genuinely no candidates)."""
    time.sleep(REQUEST_DELAY)
    data = fec_get(
        "/candidates/search/",
        {
            "state": STATE,
            "district": DISTRICT,
            "election_year": ELECTION_YEAR,
            "sort": "name",
            "per_page": 50,
        },
    )
    if data is None:
        return None
    return data.get("results", [])


def get_candidate_totals(candidate_id: str) -> dict | None:
    """Get financial totals for a candidate."""
    time.sleep(REQUEST_DELAY)
    data = fec_get(
        f"/candidate/{candidate_id}/totals/",
        {
            "election_year": ELECTION_YEAR,
        },
    )
    if data is None:
        return None
    results = data.get("results", [])
    return results[0] if results else None


def get_candidate_filings(candidate_id: str, per_page: int = 10) -> list[dict]:
    """Get recent filings for a candidate."""
    time.sleep(REQUEST_DELAY)
    data = fec_get(
        f"/candidate/{candidate_id}/filings/",
        {
            "per_page": per_page,
            "sort": "-receipt_date",
        },
    )
    if data is None:
        return []
    return data.get("results", [])


def get_committee_filings(committee_id: str, per_page: int = 10) -> list[dict]:
    """Get recent filings for a committee (financial reports)."""
    time.sleep(REQUEST_DELAY)
    data = fec_get(
        f"/committee/{committee_id}/filings/",
        {
            "per_page": per_page,
            "sort": "-receipt_date",
        },
    )
    if data is None:
        return []
    return data.get("results", [])


# ─── State Management ───────────────────────────────────────────────────────


def load_state() -> dict:
    """Load state from previous runs."""
    if STATE_FILE.exists():
        with open(STATE_FILE) as f:
            return json.load(f)
    return {
        "last_run": None,
        "run_count": 0,
        "known_candidates": {},
        "known_filings": {},
        "last_totals": {},
    }


def save_state(state: dict):
    """Save state to disk."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


# ─── Analysis ────────────────────────────────────────────────────────────────


def analyze_race(state: dict, force_all: bool) -> dict:
    """
    Fetch all data and analyze changes since last run.
    Returns a dict with all findings.
    """
    findings = {
        "new_candidates": [],
        "withdrawn_candidates": [],
        "tracked_financials": {},
        "financial_changes": [],
        "new_filings": [],
        "all_candidates": [],
        "run_time": datetime.now(timezone.utc),
    }

    known_candidates = set(state.get("known_candidates", {}).keys())
    known_filings = set(state.get("known_filings", {}).keys())
    last_totals = state.get("last_totals", {})

    # ── 1. Get all candidates in the race ──
    print("  📡 Fetching candidate list...", end=" ", flush=True)
    candidates = get_all_candidates()
    current_ids = set()

    if candidates is None:
        print("⚠ API unavailable, using cached candidate list")
        # Fall back to known candidates from state so we don't flag withdrawals
        candidates = []
        for cid, info in state.get("known_candidates", {}).items():
            candidates.append(
                {
                    "candidate_id": cid,
                    "name": info.get("name", cid),
                    "party": info.get("party", "?"),
                    "first_file_date": "?",
                    "candidate_status": "?",
                    "has_raised_funds": False,
                    "incumbent_challenge": "",
                    "principal_committees": [],
                }
            )
        api_failed = True
    else:
        api_failed = False
        print(f"found {len(candidates)} candidates")

    for c in candidates:
        cid = c["candidate_id"]
        current_ids.add(cid)
        cname = c["name"]
        cparty = c.get("party", "?")
        cfiled = c.get("first_file_date", "?")
        cstatus = c.get("candidate_status", "?")

        findings["all_candidates"].append(
            {
                "id": cid,
                "name": cname,
                "party": cparty,
                "filed": cfiled,
                "status": cstatus,
                "has_raised_funds": c.get("has_raised_funds", False),
                "incumbent": c.get("incumbent_challenge", "") == "I",
                "committees": c.get("principal_committees", []),
            }
        )

        # Check for new entrants
        if cid not in known_candidates and not force_all:
            findings["new_candidates"].append(
                {
                    "id": cid,
                    "name": cname,
                    "party": cparty,
                    "filed": cfiled,
                }
            )
            print(f"    🆕 New candidate: {cname} ({cparty}) — filed {cfiled}")

    # Check for withdrawn candidates (only if we got fresh data from the API)
    if not force_all and not api_failed:
        for old_id in known_candidates:
            if old_id not in current_ids:
                old_name = state["known_candidates"][old_id].get("name", old_id)
                findings["withdrawn_candidates"].append(
                    {
                        "id": old_id,
                        "name": old_name,
                    }
                )
                print(f"    ❌ Candidate withdrawn: {old_name}")

    # ── 2. Get financials for tracked candidates ──
    for cid, info in TRACKED_CANDIDATES.items():
        print(f"  💰 Fetching financials for {info['name']}...", end=" ", flush=True)

        totals = get_candidate_totals(cid)
        if totals:
            receipts = totals.get("receipts", 0) or 0
            disbursements = totals.get("disbursements", 0) or 0
            cash = totals.get("cash_on_hand_end_period", 0) or 0
            debts = totals.get("debts_owed_by_committee", 0) or 0
            indiv_contributions = totals.get("individual_contributions", 0) or 0
            coverage_end = totals.get("coverage_end_date", "")

            findings["tracked_financials"][cid] = {
                "name": info["name"],
                "party": info["party"],
                "role": info["role"],
                "receipts": receipts,
                "disbursements": disbursements,
                "cash_on_hand": cash,
                "debts": debts,
                "individual_contributions": indiv_contributions,
                "coverage_end": coverage_end,
            }

            print(f"${receipts:,.0f} raised")

            # Check for changes
            prev = last_totals.get(cid, {})
            if prev and not force_all:
                prev_receipts = prev.get("receipts", 0)
                if receipts != prev_receipts:
                    delta = receipts - prev_receipts
                    findings["financial_changes"].append(
                        {
                            "candidate": info["name"],
                            "field": "receipts",
                            "old": prev_receipts,
                            "new": receipts,
                            "delta": delta,
                        }
                    )
        else:
            findings["tracked_financials"][cid] = {
                "name": info["name"],
                "party": info["party"],
                "role": info["role"],
                "receipts": 0,
                "disbursements": 0,
                "cash_on_hand": 0,
                "debts": 0,
                "individual_contributions": 0,
                "coverage_end": "",
            }
            print("no financial data yet")

    # ── 3. Get recent filings for tracked candidates ──
    for cid, info in TRACKED_CANDIDATES.items():
        print(f"  📋 Fetching filings for {info['name']}...", end=" ", flush=True)

        # Get candidate filings (F2 statements of candidacy, etc.)
        filings = get_candidate_filings(cid)

        # Also check committee filings (F3 financial reports)
        candidate_data = next(
            (c for c in findings["all_candidates"] if c["id"] == cid), None
        )
        if candidate_data and candidate_data["committees"]:
            comm_id = candidate_data["committees"][0].get("committee_id")
            if comm_id:
                comm_filings = get_committee_filings(comm_id)
                filings.extend(comm_filings)

        new_count = 0
        for f in filings:
            # Use a unique key for dedup
            fkey = (
                f"{cid}_{f.get('form_type') or ''}"
                f"_{f.get('receipt_date') or ''}"
                f"_{f.get('beginning_image_number') or ''}"
            )

            if fkey not in known_filings or force_all:
                new_count += 1
                findings["new_filings"].append(
                    {
                        "candidate_id": cid,
                        "candidate_name": info["name"],
                        "form_type": f.get("form_type", "?"),
                        "description": f.get("document_description", ""),
                        "receipt_date": f.get("receipt_date", ""),
                        "coverage_start": f.get("coverage_start_date", ""),
                        "coverage_end": f.get("coverage_end_date", ""),
                        "total_receipts": f.get("total_receipts", 0),
                        "total_disbursements": f.get("total_disbursements", 0),
                        "cash_on_hand": f.get("cash_on_hand_end_period", 0),
                        "pdf_url": f.get("pdf_url", ""),
                        "fec_url": f.get("fec_url", ""),
                        "fkey": fkey,
                    }
                )

        print(f"{new_count} new filing(s)")

    return findings


# ─── Report Generation ──────────────────────────────────────────────────────


def format_currency(amount) -> str:
    """Format a number as currency."""
    if amount is None:
        return "$0"
    return f"${amount:,.0f}"


def generate_markdown_report(findings: dict, is_first: bool) -> str:
    """Generate the markdown report section."""
    run_time = findings["run_time"]
    time_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y-%m-%d %I:%M %p CT")
    lines = []

    if is_first:
        date_header = run_time.astimezone(CENTRAL_TZ).strftime("%A, %B %-d, %Y")
        lines.append(f"# MN-8 FEC Campaign Finance Monitor — {date_header}")
        lines.append("")

    lines.append(f"## 📸 Snapshot: {time_str}")
    lines.append("")

    # ── Alerts ──
    if findings["new_candidates"]:
        lines.append("### 🆕 New Candidates Entered")
        lines.append("")
        for c in findings["new_candidates"]:
            lines.append(f"- **{c['name']}** ({c['party']}) — filed {c['filed']}")
        lines.append("")

    if findings["withdrawn_candidates"]:
        lines.append("### ❌ Candidates Withdrawn")
        lines.append("")
        for c in findings["withdrawn_candidates"]:
            lines.append(f"- **{c['name']}**")
        lines.append("")

    if findings["financial_changes"]:
        lines.append("### 📈 Financial Changes")
        lines.append("")
        for ch in findings["financial_changes"]:
            direction = "↑" if ch["delta"] > 0 else "↓"
            lines.append(
                f"- **{ch['candidate']}** {ch['field']}: "
                f"{format_currency(ch['old'])} → {format_currency(ch['new'])} "
                f"({direction} {format_currency(abs(ch['delta']))})"
            )
        lines.append("")

    # ── Financial Summary Table ──
    lines.append("### 💰 Campaign Finance Summary")
    lines.append("")
    lines.append(
        "| Candidate | Party | Receipts | Disbursements | Cash on Hand | Coverage Through |"
    )
    lines.append(
        "|-----------|-------|----------|---------------|--------------|------------------|"
    )

    for cid in TRACKED_CANDIDATES:
        fin = findings["tracked_financials"].get(cid, {})
        name = fin.get("name", "?")
        party = fin.get("party", "?")
        role = fin.get("role", "")
        role_tag = " 🏛️" if role == "incumbent" else ""
        coverage = fin.get("coverage_end", "")
        if coverage:
            coverage = coverage[:10]  # just the date

        lines.append(
            f"| {name}{role_tag} | {party} | "
            f"{format_currency(fin.get('receipts', 0))} | "
            f"{format_currency(fin.get('disbursements', 0))} | "
            f"{format_currency(fin.get('cash_on_hand', 0))} | "
            f"{coverage} |"
        )

    lines.append("")

    # ── New Filings ──
    if findings["new_filings"]:
        lines.append("### 📋 Recent Filings")
        lines.append("")
        for f in findings["new_filings"]:
            desc = f["description"] or f["form_type"]
            date = (f["receipt_date"] or "")[:10]
            pdf = f.get("pdf_url", "")
            link = f" — [PDF]({pdf})" if pdf else ""
            lines.append(f"- **{f['candidate_name']}**: {desc} ({date}){link}")
        lines.append("")

    # ── Full Candidate Field ──
    lines.append("### 🏃 All Filed Candidates")
    lines.append("")
    for c in findings["all_candidates"]:
        tracked = " ⭐" if c["id"] in TRACKED_CANDIDATES else ""
        incumbent = " 🏛️" if c["incumbent"] else ""
        raised = " 💰" if c["has_raised_funds"] else ""
        lines.append(
            f"- **{c['name']}** ({c['party']}){incumbent}{tracked}{raised}"
            f" — filed {c['filed']} [{c['id']}]"
        )
    lines.append("")

    lines.append("---")
    lines.append(f"*FEC Monitor | MN-08 | {time_str}*")
    lines.append("")

    return "\n".join(lines)


# ─── RSS Generation ──────────────────────────────────────────────────────────


def _sanitize_xml(text: str) -> str:
    """Remove characters that are invalid in XML 1.0."""
    return re.sub(
        r"[^\x09\x0A\x0D\x20-\uD7FF\uE000-\uFFFD\U00010000-\U0010FFFF]",
        "",
        text,
    )


def generate_rss_html(findings: dict) -> str:
    """Generate HTML content for the RSS item."""
    run_time = findings["run_time"]
    time_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y-%m-%d %I:%M %p CT")
    parts = []

    # Alerts
    if findings["new_candidates"]:
        parts.append("<h3>🆕 New Candidates</h3><ul>")
        for c in findings["new_candidates"]:
            parts.append(
                f"<li><strong>{escape(c['name'])}</strong>"
                f" ({escape(c['party'])}) — filed {escape(c['filed'])}</li>"
            )
        parts.append("</ul>")

    if findings["withdrawn_candidates"]:
        parts.append("<h3>❌ Withdrawn</h3><ul>")
        for c in findings["withdrawn_candidates"]:
            parts.append(f"<li><strong>{escape(c['name'])}</strong></li>")
        parts.append("</ul>")

    if findings["financial_changes"]:
        parts.append("<h3>📈 Financial Changes</h3><ul>")
        for ch in findings["financial_changes"]:
            direction = "↑" if ch["delta"] > 0 else "↓"
            parts.append(
                f"<li><strong>{escape(ch['candidate'])}</strong> {escape(ch['field'])}: "
                f"{format_currency(ch['old'])} → {format_currency(ch['new'])} "
                f"({direction} {format_currency(abs(ch['delta']))})</li>"
            )
        parts.append("</ul>")

    # Financial summary
    parts.append("<h3>💰 Campaign Finance Summary</h3>")
    parts.append(
        "<table border='1' cellpadding='5' cellspacing='0'>"
        "<tr><th>Candidate</th><th>Party</th><th>Receipts</th>"
        "<th>Disbursements</th><th>Cash on Hand</th><th>Coverage</th></tr>"
    )

    for cid in TRACKED_CANDIDATES:
        fin = findings["tracked_financials"].get(cid, {})
        name = escape(fin.get("name", "?"))
        party = escape(fin.get("party", "?"))
        role = fin.get("role", "")
        role_tag = " 🏛️" if role == "incumbent" else ""
        coverage = (fin.get("coverage_end") or "")[:10]

        parts.append(
            f"<tr><td>{name}{role_tag}</td><td>{party}</td>"
            f"<td>{format_currency(fin.get('receipts', 0))}</td>"
            f"<td>{format_currency(fin.get('disbursements', 0))}</td>"
            f"<td>{format_currency(fin.get('cash_on_hand', 0))}</td>"
            f"<td>{coverage}</td></tr>"
        )

    parts.append("</table>")

    # Recent filings
    if findings["new_filings"]:
        parts.append("<h3>📋 Recent Filings</h3><ul>")
        for f in findings["new_filings"]:
            desc = escape(f["description"] or f["form_type"])
            date = (f["receipt_date"] or "")[:10]
            pdf = f.get("pdf_url", "")
            link = f' — <a href="{escape(pdf)}">PDF</a>' if pdf else ""
            parts.append(
                f"<li><strong>{escape(f['candidate_name'])}</strong>:"
                f" {desc} ({date}){link}</li>"
            )
        parts.append("</ul>")

    # All candidates
    parts.append("<h3>🏃 All Filed Candidates</h3><ul>")
    for c in findings["all_candidates"]:
        tracked = " ⭐" if c["id"] in TRACKED_CANDIDATES else ""
        incumbent = " 🏛️" if c["incumbent"] else ""
        parts.append(
            f"<li><strong>{escape(c['name'])}</strong>"
            f" ({escape(c['party'])}){incumbent}{tracked}"
            f" — filed {escape(c['filed'])}</li>"
        )
    parts.append("</ul>")

    return "\n".join(parts)


def update_rss_feed(findings: dict):
    """Update the RSS feed with a new item."""
    run_time = findings["run_time"]
    time_str = run_time.astimezone(CENTRAL_TZ).strftime("%I:%M %p CT")
    date_str = run_time.astimezone(CENTRAL_TZ).strftime("%A, %B %-d, %Y")
    pub_date = format_datetime(run_time)

    # Load existing feed
    existing_items = []
    if RSS_FILE.exists():
        try:
            tree = ET.parse(str(RSS_FILE))
            root = tree.getroot()
            channel = root.find("channel")
            if channel is not None:
                existing_items = channel.findall("item")
        except ET.ParseError:
            existing_items = []

    # Build feed
    rss = ET.Element("rss", version="2.0")
    channel = ET.SubElement(rss, "channel")

    ET.SubElement(channel, "title").text = "MN-8 FEC Campaign Finance Monitor"
    ET.SubElement(
        channel, "link"
    ).text = "https://www.fec.gov/data/elections/house/MN/08/2026/"
    ET.SubElement(
        channel, "description"
    ).text = (
        "Campaign finance tracking for Minnesota's 8th Congressional District (2026)"
    )
    ET.SubElement(channel, "language").text = "en-us"
    ET.SubElement(channel, "lastBuildDate").text = pub_date

    # Build title with alert indicators
    alerts = []
    if findings["new_candidates"]:
        alerts.append(f"{len(findings['new_candidates'])} new candidate(s)")
    if findings["financial_changes"]:
        alerts.append("financial changes")
    if findings["new_filings"]:
        alerts.append(f"{len(findings['new_filings'])} filing(s)")

    title_suffix = f" — {', '.join(alerts)}" if alerts else ""
    item_title = f"MN-8 FEC Update: {date_str} {time_str}{title_suffix}"

    item_html = generate_rss_html(findings)
    guid = f"mn8-fec-{run_time.strftime('%Y%m%d-%H%M%S')}"

    new_item = ET.SubElement(channel, "item")
    ET.SubElement(new_item, "title").text = item_title
    ET.SubElement(
        new_item, "link"
    ).text = "https://www.fec.gov/data/elections/house/MN/08/2026/"
    ET.SubElement(new_item, "description").text = item_html
    ET.SubElement(new_item, "pubDate").text = pub_date
    ET.SubElement(new_item, "guid", isPermaLink="false").text = guid

    # Keep existing items
    keep = max(0, RSS_MAX_ITEMS - 1)
    for old_item in existing_items[:keep]:
        channel.append(old_item)

    # Write
    RSS_DIR.mkdir(parents=True, exist_ok=True)
    ET.indent(rss, space="  ")
    with open(RSS_FILE, "w", encoding="utf-8") as f:
        xml_str = ET.tostring(rss, encoding="unicode", xml_declaration=True)
        f.write(_sanitize_xml(xml_str))
        f.write("\n")


# ─── Main ────────────────────────────────────────────────────────────────────


def main():
    dry_run = "--dry-run" in sys.argv
    force_all = "--force-all" in sys.argv
    write_markdown = "--markdown" in sys.argv

    print("🏛️  MN-8 FEC Campaign Finance Monitor")
    print(f"   Time: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}")
    print(f"   Mode: {'DRY RUN' if dry_run else 'LIVE'}")
    print(
        f"   Markdown: {'yes' if write_markdown else 'no (use --markdown to enable)'}"
    )
    print(f"   Race: MN-08 ({ELECTION_YEAR})")
    print(f"   Tracking: {', '.join(c['name'] for c in TRACKED_CANDIDATES.values())}")
    if force_all:
        print("   ⚡ Force mode: reporting everything as new")
    print()

    # Load state
    state = load_state()

    # Collect and analyze
    findings = analyze_race(state, force_all)

    # Generate markdown report
    run_time = findings["run_time"]
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    date_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y%m%d")
    report_file = OUTPUT_DIR / f"{date_str}-mn8-fec.md"
    is_first = not report_file.exists()
    report = generate_markdown_report(findings, is_first=is_first)

    if dry_run:
        print(f"\n{'=' * 60}")
        print(report)
        print(f"{'=' * 60}")
        print(f"\n  Would {'create' if is_first else 'append to'}: {report_file}")
        print(f"  Would update RSS feed: {RSS_FILE}")
    else:
        # Markdown report (opt-in)
        if write_markdown:
            with open(report_file, "a") as f:
                if not is_first:
                    f.write("\n\n")
                f.write(report)
            action = "created" if is_first else "appended to"
            print(f"\n  📄 Report {action}: {report_file}")

        # RSS feed (always)
        update_rss_feed(findings)
        print(f"  📡 RSS feed updated: {RSS_FILE}")

        # Update state
        new_state = {
            "last_run": run_time.isoformat(),
            "run_count": state.get("run_count", 0) + 1,
            "known_candidates": {
                c["id"]: {"name": c["name"], "party": c["party"]}
                for c in findings["all_candidates"]
            },
            "known_filings": {
                **state.get("known_filings", {}),
                **{f["fkey"]: True for f in findings["new_filings"]},
            },
            "last_totals": {
                cid: {
                    "receipts": fin.get("receipts", 0),
                    "disbursements": fin.get("disbursements", 0),
                    "cash_on_hand": fin.get("cash_on_hand", 0),
                }
                for cid, fin in findings["tracked_financials"].items()
            },
        }
        save_state(new_state)
        print(f"  💾 State updated")

    # Summary
    n_candidates = len(findings["all_candidates"])
    n_new = len(findings["new_candidates"])
    n_filings = len(findings["new_filings"])
    print(
        f"\n  ✅ Done! {n_candidates} candidates in race, "
        f"{n_new} new entrant(s), {n_filings} filing(s)."
    )


if __name__ == "__main__":
    main()
