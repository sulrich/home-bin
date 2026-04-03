#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests>=2.31",
# ]
# ///
"""
mn8_fec_monitor.py -- MN-8 congressional race FEC monitor.
tracks campaign finance data, filings, and new entrants for
minnesota's 8th congressional district (2026 cycle).
"""

import argparse
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

# --- configuration ----------------------------------------------------------

FEC_API_BASE = "https://api.open.fec.gov/v1"

# race parameters
STATE = "MN"
DISTRICT = "08"
ELECTION_YEAR = 2026

# candidates we're specifically tracking
TRACKED_CANDIDATES = {
    "H6MN08179": {"name": "Trina Swanson", "party": "DFL", "role": "challenger"},
    "H6MN08138": {"name": "Cyle Cramer", "party": "DFL", "role": "challenger"},
    "H8MN08043": {"name": "Pete Stauber", "party": "REP", "role": "incumbent"},
}

RSS_MAX_ITEMS = 60

# central timezone
CENTRAL_TZ = timezone(timedelta(hours=-6))

# polite delay between API requests
REQUEST_DELAY = 1.0

# --- FEC API client ---------------------------------------------------------

SESSION = requests.Session()
SESSION.headers.update({"Accept": "application/json"})


def fec_get(endpoint: str, params: dict = None, api_key: str = "DEMO_KEY") -> dict | None:
    """hit the FEC API with retry on rate limiting.

    returns None on failure (distinguishes from empty results).
    """
    params = params or {}
    params["api_key"] = api_key
    url = f"{FEC_API_BASE}{endpoint}"

    max_retries = 3
    for attempt in range(max_retries):
        try:
            resp = SESSION.get(url, params=params, timeout=30)
            if resp.status_code == 429:
                wait = (attempt + 1) * 10
                print(f"\n    rate limited, waiting {wait}s...", end=" ", flush=True)
                time.sleep(wait)
                continue
            resp.raise_for_status()
            return resp.json()
        except requests.RequestException as e:
            print(f"  FEC API error: {e}")
            if attempt < max_retries - 1:
                time.sleep(5)
                continue
            return None

    return None


# --- data collection --------------------------------------------------------


def get_all_candidates(api_key: str) -> list[dict] | None:
    """get all candidates filed for MN-08 in the target election year.

    returns None on API failure (vs empty list for genuinely no candidates).
    """
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
        api_key=api_key,
    )
    if data is None:
        return None
    return data.get("results", [])


def get_candidate_totals(candidate_id: str, api_key: str) -> dict | None:
    """get financial totals for a candidate."""
    time.sleep(REQUEST_DELAY)
    data = fec_get(
        f"/candidate/{candidate_id}/totals/",
        {
            "election_year": ELECTION_YEAR,
        },
        api_key=api_key,
    )
    if data is None:
        return None
    results = data.get("results", [])
    return results[0] if results else None


def get_candidate_filings(
    candidate_id: str, api_key: str, per_page: int = 10
) -> list[dict]:
    """get recent filings for a candidate."""
    time.sleep(REQUEST_DELAY)
    data = fec_get(
        f"/candidate/{candidate_id}/filings/",
        {
            "per_page": per_page,
            "sort": "-receipt_date",
        },
        api_key=api_key,
    )
    if data is None:
        return []
    return data.get("results", [])


def get_committee_filings(
    committee_id: str, api_key: str, per_page: int = 10
) -> list[dict]:
    """get recent filings for a committee (financial reports)."""
    time.sleep(REQUEST_DELAY)
    data = fec_get(
        f"/committee/{committee_id}/filings/",
        {
            "per_page": per_page,
            "sort": "-receipt_date",
        },
        api_key=api_key,
    )
    if data is None:
        return []
    return data.get("results", [])


# --- state management -------------------------------------------------------


def load_state(state_file: Path) -> dict:
    """load state from previous runs."""
    if state_file.exists():
        with open(state_file) as f:
            return json.load(f)
    return {
        "last_run": None,
        "run_count": 0,
        "known_candidates": {},
        "known_filings": {},
        "last_totals": {},
    }


def save_state(state: dict, state_file: Path, cache_dir: Path):
    """persist state to disk."""
    cache_dir.mkdir(parents=True, exist_ok=True)
    with open(state_file, "w") as f:
        json.dump(state, f, indent=2)


# --- analysis ---------------------------------------------------------------


def analyze_race(state: dict, force_all: bool, api_key: str) -> dict:
    """fetch all data and analyze changes since last run."""
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

    # 1. get all candidates in the race
    print("  fetching candidate list...", end=" ", flush=True)
    candidates = get_all_candidates(api_key)
    current_ids = set()

    if candidates is None:
        print("API unavailable, using cached candidate list")
        # fall back to known candidates so we don't flag false withdrawals
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

        # new entrant?
        if cid not in known_candidates and not force_all:
            findings["new_candidates"].append(
                {
                    "id": cid,
                    "name": cname,
                    "party": cparty,
                    "filed": cfiled,
                }
            )
            print(f"    new candidate: {cname} ({cparty}) -- filed {cfiled}")

    # check for withdrawn candidates (only with fresh API data)
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
                print(f"    candidate withdrawn: {old_name}")

    # 2. get financials for tracked candidates
    for cid, info in TRACKED_CANDIDATES.items():
        print(f"  fetching financials for {info['name']}...", end=" ", flush=True)

        totals = get_candidate_totals(cid, api_key)
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

            # check for changes vs last run
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

    # 3. get recent filings for tracked candidates
    for cid, info in TRACKED_CANDIDATES.items():
        print(f"  fetching filings for {info['name']}...", end=" ", flush=True)

        # candidate filings (F2 statements of candidacy, etc.)
        filings = get_candidate_filings(cid, api_key)

        # also check committee filings (F3 financial reports)
        candidate_data = next(
            (c for c in findings["all_candidates"] if c["id"] == cid), None
        )
        if candidate_data and candidate_data["committees"]:
            comm_id = candidate_data["committees"][0].get("committee_id")
            if comm_id:
                comm_filings = get_committee_filings(comm_id, api_key)
                filings.extend(comm_filings)

        new_count = 0
        for f in filings:
            # unique key for dedup
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


# --- report generation ------------------------------------------------------


def format_currency(amount) -> str:
    """format a number as currency."""
    if amount is None:
        return "$0"
    return f"${amount:,.0f}"


def generate_markdown_report(findings: dict, is_first: bool) -> str:
    """generate the markdown report section."""
    run_time = findings["run_time"]
    time_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y-%m-%d %I:%M %p CT")
    lines = []

    if is_first:
        date_header = run_time.astimezone(CENTRAL_TZ).strftime("%A, %B %-d, %Y")
        lines.append(f"# MN-8 FEC campaign finance monitor -- {date_header}")
        lines.append("")

    lines.append(f"## snapshot: {time_str}")
    lines.append("")

    # alerts
    if findings["new_candidates"]:
        lines.append("### new candidates entered")
        lines.append("")
        for c in findings["new_candidates"]:
            lines.append(f"- **{c['name']}** ({c['party']}) -- filed {c['filed']}")
        lines.append("")

    if findings["withdrawn_candidates"]:
        lines.append("### candidates withdrawn")
        lines.append("")
        for c in findings["withdrawn_candidates"]:
            lines.append(f"- **{c['name']}**")
        lines.append("")

    if findings["financial_changes"]:
        lines.append("### financial changes")
        lines.append("")
        for ch in findings["financial_changes"]:
            direction = "up" if ch["delta"] > 0 else "down"
            lines.append(
                f"- **{ch['candidate']}** {ch['field']}: "
                f"{format_currency(ch['old'])} -> {format_currency(ch['new'])} "
                f"({direction} {format_currency(abs(ch['delta']))})"
            )
        lines.append("")

    # financial summary table
    lines.append("### campaign finance summary")
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
        role_tag = " (incumbent)" if role == "incumbent" else ""
        coverage = fin.get("coverage_end", "")
        if coverage:
            coverage = coverage[:10]

        lines.append(
            f"| {name}{role_tag} | {party} | "
            f"{format_currency(fin.get('receipts', 0))} | "
            f"{format_currency(fin.get('disbursements', 0))} | "
            f"{format_currency(fin.get('cash_on_hand', 0))} | "
            f"{coverage} |"
        )

    lines.append("")

    # new filings
    if findings["new_filings"]:
        lines.append("### recent filings")
        lines.append("")
        for f in findings["new_filings"]:
            desc = f["description"] or f["form_type"]
            date = (f["receipt_date"] or "")[:10]
            pdf = f.get("pdf_url", "")
            link = f" -- [PDF]({pdf})" if pdf else ""
            lines.append(f"- **{f['candidate_name']}**: {desc} ({date}){link}")
        lines.append("")

    # full candidate field
    lines.append("### all filed candidates")
    lines.append("")
    for c in findings["all_candidates"]:
        tracked = " *" if c["id"] in TRACKED_CANDIDATES else ""
        incumbent = " (incumbent)" if c["incumbent"] else ""
        raised = " $" if c["has_raised_funds"] else ""
        lines.append(
            f"- **{c['name']}** ({c['party']}){incumbent}{tracked}{raised}"
            f" -- filed {c['filed']} [{c['id']}]"
        )
    lines.append("")

    lines.append("---")
    lines.append(f"*FEC monitor | MN-08 | {time_str}*")
    lines.append("")

    return "\n".join(lines)


# --- RSS generation ---------------------------------------------------------


def _sanitize_xml(text: str) -> str:
    """strip characters that are invalid in XML 1.0."""
    return re.sub(
        r"[^\x09\x0A\x0D\x20-\uD7FF\uE000-\uFFFD\U00010000-\U0010FFFF]",
        "",
        text,
    )


def generate_rss_html(findings: dict) -> str:
    """generate HTML content for the RSS item."""
    run_time = findings["run_time"]
    time_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y-%m-%d %I:%M %p CT")
    parts = []

    if findings["new_candidates"]:
        parts.append("<h3>New Candidates</h3><ul>")
        for c in findings["new_candidates"]:
            parts.append(
                f"<li><strong>{escape(c['name'])}</strong>"
                f" ({escape(c['party'])}) -- filed {escape(c['filed'])}</li>"
            )
        parts.append("</ul>")

    if findings["withdrawn_candidates"]:
        parts.append("<h3>Withdrawn</h3><ul>")
        for c in findings["withdrawn_candidates"]:
            parts.append(f"<li><strong>{escape(c['name'])}</strong></li>")
        parts.append("</ul>")

    if findings["financial_changes"]:
        parts.append("<h3>Financial Changes</h3><ul>")
        for ch in findings["financial_changes"]:
            direction = "up" if ch["delta"] > 0 else "down"
            parts.append(
                f"<li><strong>{escape(ch['candidate'])}</strong> {escape(ch['field'])}: "
                f"{format_currency(ch['old'])} -> {format_currency(ch['new'])} "
                f"({direction} {format_currency(abs(ch['delta']))})</li>"
            )
        parts.append("</ul>")

    # financial summary
    parts.append("<h3>Campaign Finance Summary</h3>")
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
        role_tag = " (incumbent)" if role == "incumbent" else ""
        coverage = (fin.get("coverage_end") or "")[:10]

        parts.append(
            f"<tr><td>{name}{role_tag}</td><td>{party}</td>"
            f"<td>{format_currency(fin.get('receipts', 0))}</td>"
            f"<td>{format_currency(fin.get('disbursements', 0))}</td>"
            f"<td>{format_currency(fin.get('cash_on_hand', 0))}</td>"
            f"<td>{coverage}</td></tr>"
        )

    parts.append("</table>")

    if findings["new_filings"]:
        parts.append("<h3>Recent Filings</h3><ul>")
        for f in findings["new_filings"]:
            desc = escape(f["description"] or f["form_type"])
            date = (f["receipt_date"] or "")[:10]
            pdf = f.get("pdf_url", "")
            link = f' -- <a href="{escape(pdf)}">PDF</a>' if pdf else ""
            parts.append(
                f"<li><strong>{escape(f['candidate_name'])}</strong>:"
                f" {desc} ({date}){link}</li>"
            )
        parts.append("</ul>")

    parts.append("<h3>All Filed Candidates</h3><ul>")
    for c in findings["all_candidates"]:
        tracked = " *" if c["id"] in TRACKED_CANDIDATES else ""
        incumbent = " (incumbent)" if c["incumbent"] else ""
        parts.append(
            f"<li><strong>{escape(c['name'])}</strong>"
            f" ({escape(c['party'])}){incumbent}{tracked}"
            f" -- filed {escape(c['filed'])}</li>"
        )
    parts.append("</ul>")

    return "\n".join(parts)


def update_rss_feed(findings: dict, rss_file: Path, rss_dir: Path):
    """update the RSS feed with a new item."""
    run_time = findings["run_time"]
    time_str = run_time.astimezone(CENTRAL_TZ).strftime("%I:%M %p CT")
    date_str = run_time.astimezone(CENTRAL_TZ).strftime("%A, %B %-d, %Y")
    pub_date = format_datetime(run_time)

    # load existing feed
    existing_items = []
    if rss_file.exists():
        try:
            tree = ET.parse(str(rss_file))
            root = tree.getroot()
            channel = root.find("channel")
            if channel is not None:
                existing_items = channel.findall("item")
        except ET.ParseError:
            existing_items = []

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

    # build title with alert indicators
    alerts = []
    if findings["new_candidates"]:
        alerts.append(f"{len(findings['new_candidates'])} new candidate(s)")
    if findings["financial_changes"]:
        alerts.append("financial changes")
    if findings["new_filings"]:
        alerts.append(f"{len(findings['new_filings'])} filing(s)")

    title_suffix = f" -- {', '.join(alerts)}" if alerts else ""
    item_title = f"MN-8 FEC update: {date_str} {time_str}{title_suffix}"

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

    keep = max(0, RSS_MAX_ITEMS - 1)
    for old_item in existing_items[:keep]:
        channel.append(old_item)

    rss_dir.mkdir(parents=True, exist_ok=True)
    ET.indent(rss, space="  ")
    with open(rss_file, "w", encoding="utf-8") as f:
        xml_str = ET.tostring(rss, encoding="unicode", xml_declaration=True)
        f.write(_sanitize_xml(xml_str))
        f.write("\n")


# --- main -------------------------------------------------------------------


def parse_args():
    parser = argparse.ArgumentParser(
        description="MN-8 Congressional Race FEC Monitor"
    )
    parser.add_argument(
        "-n", "--dry-run", action="store_true",
        help="print what would be saved without writing files",
    )
    parser.add_argument(
        "-f", "--force-all", action="store_true",
        help="ignore state file, report everything as new",
    )
    parser.add_argument(
        "-m", "--markdown", action="store_true",
        help="also write a daily markdown report",
    )
    parser.add_argument(
        "-w", "--www-dir",
        default=os.environ.get("FEED_GEN_WWW_DIR"),
        help="web root for RSS output (env: FEED_GEN_WWW_DIR)",
    )
    parser.add_argument(
        "-r", "--report-dir",
        default=os.environ.get("FEED_GEN_REPORT_DIR"),
        help="directory for markdown reports (env: FEED_GEN_REPORT_DIR)",
    )
    parser.add_argument(
        "-c", "--cache-dir",
        default=os.environ.get("FEED_GEN_CACHE_DIR"),
        help="directory for state/cache files (env: FEED_GEN_CACHE_DIR)",
    )
    parser.add_argument(
        "-k", "--fec-api-key",
        default=os.environ.get("FEC_API_KEY", "DEMO_KEY"),
        help="FEC API key (env: FEC_API_KEY, default: DEMO_KEY)",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    missing = []
    if not args.www_dir:
        missing.append("--www-dir / FEED_GEN_WWW_DIR")
    if not args.report_dir:
        missing.append("--report-dir / FEED_GEN_REPORT_DIR")
    if not args.cache_dir:
        missing.append("--cache-dir / FEED_GEN_CACHE_DIR")
    if missing:
        print(f"error: required: {', '.join(missing)}", file=sys.stderr)
        sys.exit(1)

    www_dir = Path(args.www_dir)
    report_dir = Path(args.report_dir)
    cache_dir = Path(args.cache_dir)
    state_file = cache_dir / "mn8_fec_state.json"
    rss_dir = www_dir / "rss"
    rss_file = rss_dir / "mn8-fec.rss"

    print("MN-8 FEC campaign finance monitor")
    print(f"   time: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}")
    print(f"   mode: {'DRY RUN' if args.dry_run else 'LIVE'}")
    print(
        f"   markdown: {'yes' if args.markdown else 'no (use -m/--markdown to enable)'}"
    )
    print(f"   race: MN-08 ({ELECTION_YEAR})")
    print(f"   tracking: {', '.join(c['name'] for c in TRACKED_CANDIDATES.values())}")
    if args.force_all:
        print("   force mode: reporting everything as new")
    print()

    state = load_state(state_file)
    findings = analyze_race(state, args.force_all, args.fec_api_key)

    run_time = findings["run_time"]
    report_dir.mkdir(parents=True, exist_ok=True)
    date_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y%m%d")
    report_file = report_dir / f"{date_str}-mn8-fec.md"
    is_first = not report_file.exists()
    report = generate_markdown_report(findings, is_first=is_first)

    if args.dry_run:
        print(f"\n{'=' * 60}")
        print(report)
        print(f"{'=' * 60}")
        print(f"\n  would {'create' if is_first else 'append to'}: {report_file}")
        print(f"  would update RSS feed: {rss_file}")
    else:
        if args.markdown:
            with open(report_file, "a") as f:
                if not is_first:
                    f.write("\n\n")
                f.write(report)
            action = "created" if is_first else "appended to"
            print(f"\n  report {action}: {report_file}")

        update_rss_feed(findings, rss_file, rss_dir)
        print(f"  RSS feed updated: {rss_file}")

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
        save_state(new_state, state_file, cache_dir)
        print(f"  state updated")

    n_candidates = len(findings["all_candidates"])
    n_new = len(findings["new_candidates"])
    n_filings = len(findings["new_filings"])
    print(
        f"\n  done. {n_candidates} candidates in race, "
        f"{n_new} new entrant(s), {n_filings} filing(s)."
    )


if __name__ == "__main__":
    main()
