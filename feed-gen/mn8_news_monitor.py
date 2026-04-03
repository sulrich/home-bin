#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests>=2.31",
#     "feedparser>=6.0",
# ]
# ///
"""
mn8_news_monitor.py — MN-8 Candidate News Aggregator
Monitors local MN news RSS feeds for mentions of candidates in
Minnesota's 8th Congressional District race.

Usage:
    uv run mn8_news_monitor.py [--dry-run] [--force-all] [--markdown]

    --dry-run    Print what would be saved without writing files
    --force-all  Ignore state file, report everything as new
    --markdown   Also write a daily markdown report
"""

import json
import re
import sys
import time
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from email.utils import format_datetime, parsedate_to_datetime
from html import escape
from pathlib import Path

import feedparser
import requests

# ─── Configuration ───────────────────────────────────────────────────────────

# News sources with RSS feeds covering MN-8 territory
NEWS_FEEDS = [
    {
        "name": "Star Tribune",
        "url": "https://www.startribune.com/rss",
        "region": "Statewide",
    },
    {
        "name": "MinnPost Politics",
        "url": "https://www.minnpost.com/category/politics-policy/feed/",
        "region": "Statewide",
    },
    {
        "name": "Minnesota Reformer",
        "url": "https://minnesotareformer.com/feed/",
        "region": "Statewide",
    },
    {
        "name": "WDIO",
        "url": "https://www.wdio.com/feed/",
        "region": "Duluth / Iron Range",
    },
    {
        "name": "Fox 21 Duluth",
        "url": "https://www.fox21online.com/feed/",
        "region": "Duluth / NE Minnesota",
    },
    {
        "name": "KARE 11",
        "url": "https://www.kare11.com/feeds/syndication/rss/news",
        "region": "Twin Cities / Minnesota",
    },
    {
        "name": "Sahan Journal",
        "url": "https://sahanjournal.com/feed/",
        "region": "MN Immigrant Communities",
    },
]

# Candidates to track — name variations for matching
CANDIDATES = {
    "trina_swanson": {
        "display": "Trina Swanson",
        "party": "DFL",
        "patterns": ["trina swanson", "swanson"],
    },
    "cyle_cramer": {
        "display": "Cyle Cramer",
        "party": "DFL",
        "patterns": ["cyle cramer", "cramer"],
    },
    "pete_stauber": {
        "display": "Pete Stauber",
        "party": "REP",
        "patterns": ["pete stauber", "stauber", "rep. stauber", "congressman stauber"],
    },
    "emanuel_anastos": {
        "display": "Emanuel Anastos",
        "party": "DFL",
        "patterns": ["emanuel anastos", "anastos"],
    },
    "john_paul_mcbride": {
        "display": "John-Paul McBride",
        "party": "DFL",
        "patterns": ["john-paul mcbride", "john paul mcbride", "mcbride"],
    },
}

# District-level keywords (catch articles about the race itself)
RACE_KEYWORDS = [
    "8th congressional district",
    "8th district",
    "eighth congressional district",
    "eighth district",
    "mn-8",
    "mn 8",
    "minnesota's 8th",
    "minnesota 8th",
]

# File paths
WWW_DIR = Path("/Volumes/media/dyn.botwerks.net/www")
OC_DIR = Path.home() / "nanoclaw"
CACHE_DIR = OC_DIR / ".cache"
STATE_FILE = CACHE_DIR / "mn8_news_state.json"
OUTPUT_DIR = OC_DIR / "reports"
RSS_DIR = WWW_DIR / "rss"
RSS_FILE = RSS_DIR / "mn8-news.rss"
RSS_MAX_ITEMS = 100

# Central timezone
CENTRAL_TZ = timezone(timedelta(hours=-6))

# Be polite
REQUEST_DELAY = 1.0
USER_AGENT = "mn8-news-monitor/1.0 (local research tool)"

# ─── Feed Fetching ───────────────────────────────────────────────────────────

SESSION = requests.Session()
SESSION.headers.update({"User-Agent": USER_AGENT})


def fetch_feed(feed_config: dict) -> list[dict]:
    """Fetch and parse an RSS feed, returning normalized article dicts."""
    url = feed_config["url"]
    source = feed_config["name"]

    try:
        resp = SESSION.get(url, timeout=30)
        resp.raise_for_status()
        parsed = feedparser.parse(resp.content)
    except requests.RequestException as e:
        print(f"  ⚠ Error fetching {source}: {e}")
        return []

    articles = []
    for entry in parsed.entries:
        # Normalize the entry
        title = entry.get("title", "").strip()
        link = entry.get("link", "").strip()
        summary = entry.get("summary", entry.get("description", "")).strip()

        # Parse publication date
        pub_date = None
        if hasattr(entry, "published_parsed") and entry.published_parsed:
            try:
                pub_date = datetime(*entry.published_parsed[:6], tzinfo=timezone.utc)
            except (TypeError, ValueError):
                pass
        if (
            pub_date is None
            and hasattr(entry, "updated_parsed")
            and entry.updated_parsed
        ):
            try:
                pub_date = datetime(*entry.updated_parsed[:6], tzinfo=timezone.utc)
            except (TypeError, ValueError):
                pass

        # Generate a unique ID
        guid = entry.get("id", entry.get("guid", link))

        # Get author
        author = entry.get("author", entry.get("dc_creator", ""))

        articles.append(
            {
                "title": title,
                "link": link,
                "summary": summary,
                "pub_date": pub_date,
                "guid": guid,
                "author": author,
                "source": source,
                "source_region": feed_config["region"],
            }
        )

    return articles


# ─── Candidate Matching ─────────────────────────────────────────────────────


def match_candidates(article: dict) -> dict:
    """
    Check if an article mentions any tracked candidates or the MN-8 race.
    Returns dict of matched candidate keys and race keyword matches.
    """
    # Combine title + summary, strip HTML tags for matching
    raw_text = article["title"] + " " + article["summary"]
    text = re.sub(r"<[^>]+>", " ", raw_text).lower()

    matches = {
        "candidates": {},
        "race_keywords": [],
    }

    # Check each candidate
    for key, info in CANDIDATES.items():
        for pattern in info["patterns"]:
            if re.search(r"\b" + re.escape(pattern) + r"\b", text):
                matches["candidates"][key] = info["display"]
                break  # one match per candidate is enough

    # Check race-level keywords
    for keyword in RACE_KEYWORDS:
        if re.search(r"\b" + re.escape(keyword) + r"\b", text):
            matches["race_keywords"].append(keyword)

    return matches


def is_relevant(matches: dict) -> bool:
    """An article is relevant if it mentions any candidate or the race."""
    return bool(matches["candidates"]) or bool(matches["race_keywords"])


# ─── State Management ───────────────────────────────────────────────────────


def load_state() -> dict:
    if STATE_FILE.exists():
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"last_run": None, "run_count": 0, "seen_articles": {}}


def save_state(state: dict):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


# ─── Report Generation ──────────────────────────────────────────────────────


def format_article_md(article: dict, matches: dict) -> str:
    """Format an article as markdown."""
    title = article["title"]
    link = article["link"]
    source = article["source"]
    author = article.get("author", "")
    pub_date = article.get("pub_date")

    time_str = ""
    if pub_date:
        time_str = pub_date.astimezone(CENTRAL_TZ).strftime("%Y-%m-%d %I:%M %p CT")

    # Clean summary of HTML
    summary = re.sub(r"<[^>]+>", " ", article.get("summary", ""))
    summary = re.sub(r"\s+", " ", summary).strip()
    if len(summary) > 400:
        summary = summary[:400] + "..."

    # Build match tags
    tags = []
    for ckey, cname in matches["candidates"].items():
        tags.append(cname)
    for kw in matches["race_keywords"]:
        tags.append(kw)
    tag_str = ", ".join(tags)

    lines = []
    lines.append(f"### [{title}]({link})")
    lines.append("")
    lines.append(f"- **Source:** {source}")
    if time_str:
        lines.append(f"- **Published:** {time_str}")
    if author:
        lines.append(f"- **Author:** {author}")
    lines.append(f"- **Mentions:** {tag_str}")
    lines.append("")
    if summary:
        lines.append(f"> {summary}")
        lines.append("")
    return "\n".join(lines)


def generate_markdown_report(
    results: list[dict], run_time: datetime, is_first: bool
) -> str:
    """Generate the markdown report section."""
    time_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y-%m-%d %I:%M %p CT")
    lines = []

    if is_first:
        date_header = run_time.astimezone(CENTRAL_TZ).strftime("%A, %B %-d, %Y")
        lines.append(f"# MN-8 Candidate News Monitor — {date_header}")
        lines.append("")

    lines.append(f"## 📸 Snapshot: {time_str}")
    lines.append("")
    lines.append(f"**{len(results)} article(s) mentioning MN-8 candidates**")
    lines.append("")
    lines.append("---")
    lines.append("")

    if not results:
        lines.append("*No new candidate mentions found since last check.*")
        lines.append("")
    else:
        # Group by candidate mentioned (articles can appear under multiple)
        by_candidate = {}
        general_race = []

        for article, matches in results:
            if matches["candidates"]:
                for ckey, cname in matches["candidates"].items():
                    by_candidate.setdefault(ckey, []).append((article, matches))
            elif matches["race_keywords"]:
                general_race.append((article, matches))

        # Output by candidate (tracked candidates first)
        priority_order = ["trina_swanson", "cyle_cramer", "pete_stauber"]
        shown_guids = set()

        for ckey in priority_order:
            if ckey not in by_candidate:
                continue
            cname = CANDIDATES[ckey]["display"]
            party = CANDIDATES[ckey]["party"]
            articles = by_candidate[ckey]
            lines.append(f"### 👤 {cname} ({party})")
            lines.append("")
            lines.append(f"**{len(articles)} mention(s)**")
            lines.append("")

            for article, matches in articles:
                if article["guid"] not in shown_guids:
                    lines.append(format_article_md(article, matches))
                    shown_guids.add(article["guid"])

        # Other candidates
        for ckey in sorted(by_candidate.keys()):
            if ckey in priority_order:
                continue
            cname = CANDIDATES[ckey]["display"]
            party = CANDIDATES[ckey]["party"]
            articles = by_candidate[ckey]
            lines.append(f"### 👤 {cname} ({party})")
            lines.append("")
            lines.append(f"**{len(articles)} mention(s)**")
            lines.append("")

            for article, matches in articles:
                if article["guid"] not in shown_guids:
                    lines.append(format_article_md(article, matches))
                    shown_guids.add(article["guid"])

        # General race mentions
        if general_race:
            lines.append("### 🏛️ MN-8 Race (General)")
            lines.append("")
            for article, matches in general_race:
                if article["guid"] not in shown_guids:
                    lines.append(format_article_md(article, matches))
                    shown_guids.add(article["guid"])

    lines.append("---")
    lines.append(f"*News Monitor | MN-8 | {len(NEWS_FEEDS)} feeds | {time_str}*")
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


def generate_rss_item_html(article: dict, matches: dict) -> str:
    """Generate HTML for a single article RSS item."""
    source = escape(article["source"])
    author = escape(article.get("author", ""))
    summary = re.sub(r"<[^>]+>", " ", article.get("summary", ""))
    summary = escape(re.sub(r"\s+", " ", summary).strip()[:500])

    tags = []
    for ckey, cname in matches["candidates"].items():
        tags.append(escape(cname))
    for kw in matches["race_keywords"]:
        tags.append(escape(kw))
    tag_str = ", ".join(tags)

    author_line = f"<br/>Author: {author}" if author else ""

    return (
        f'<p style="font-size:0.9em;color:#666;">'
        f"Source: {source}{author_line}<br/>"
        f"Mentions: {tag_str}</p>"
        f"<blockquote>{summary}</blockquote>"
    )


def update_rss_feed(results: list[dict], run_time: datetime):
    """Update RSS feed — one item per matched article."""
    pub_date = format_datetime(run_time)

    # Load existing
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

    ET.SubElement(channel, "title").text = "MN-8 Candidate News Monitor"
    ET.SubElement(
        channel, "link"
    ).text = "https://ballotpedia.org/Minnesota%27s_8th_Congressional_District"
    ET.SubElement(
        channel, "description"
    ).text = (
        "News mentions of candidates in Minnesota's 8th Congressional District race"
    )
    ET.SubElement(channel, "language").text = "en-us"
    ET.SubElement(channel, "lastBuildDate").text = pub_date

    # Add one item per article
    new_count = 0
    for article, matches in results:
        candidate_names = list(matches["candidates"].values())
        title_prefix = ", ".join(candidate_names) if candidate_names else "MN-8"

        item_title = f"{title_prefix}: {article['title']}"
        item_html = generate_rss_item_html(article, matches)

        # Use article pub date if available, otherwise run time
        if article.get("pub_date"):
            item_pub = format_datetime(article["pub_date"])
        else:
            item_pub = pub_date

        guid = f"mn8-news-{hash(article['guid']) & 0xFFFFFFFF:08x}"

        new_item = ET.SubElement(channel, "item")
        ET.SubElement(new_item, "title").text = item_title
        ET.SubElement(new_item, "link").text = article["link"]
        ET.SubElement(new_item, "description").text = item_html
        ET.SubElement(new_item, "pubDate").text = item_pub
        ET.SubElement(new_item, "guid", isPermaLink="false").text = guid
        ET.SubElement(new_item, "source", url=article["link"]).text = article["source"]
        new_count += 1

    # Keep existing items
    keep = max(0, RSS_MAX_ITEMS - new_count)
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

    print("📰 MN-8 Candidate News Monitor")
    print(f"   Time: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}")
    print(f"   Mode: {'DRY RUN' if dry_run else 'LIVE'}")
    print(
        f"   Markdown: {'yes' if write_markdown else 'no (use --markdown to enable)'}"
    )
    print(f"   Feeds: {len(NEWS_FEEDS)}")
    tracked = [c["display"] for c in CANDIDATES.values()]
    print(f"   Tracking: {', '.join(tracked)}")
    if force_all:
        print("   ⚡ Force mode: reporting everything as new")
    print()

    # Load state
    state = load_state()
    seen_articles = (
        set(state.get("seen_articles", {}).keys()) if not force_all else set()
    )

    run_time = datetime.now(timezone.utc)
    all_results = []  # (article, matches) tuples
    new_seen = {}

    for feed_config in NEWS_FEEDS:
        print(f"  📡 Fetching {feed_config['name']}...", end=" ", flush=True)
        time.sleep(REQUEST_DELAY)

        articles = fetch_feed(feed_config)
        print(f"got {len(articles)} articles", end="")

        relevant_count = 0
        for article in articles:
            guid = article["guid"]

            # Track for dedup
            new_seen[guid] = {
                "source": article["source"],
                "title": article["title"][:100],
                "seen_at": run_time.isoformat(),
            }

            # Skip already-seen
            if guid in seen_articles:
                continue

            # Check relevance
            matches = match_candidates(article)
            if is_relevant(matches):
                all_results.append((article, matches))
                relevant_count += 1

        print(f" → {relevant_count} candidate mention(s)")

    # Sort by pub date (most recent first)
    all_results.sort(
        key=lambda x: x[0].get("pub_date") or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )

    # Generate markdown report
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    date_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y%m%d")
    report_file = OUTPUT_DIR / f"{date_str}-mn8-news.md"
    is_first = not report_file.exists()
    report = generate_markdown_report(all_results, run_time, is_first=is_first)

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
        update_rss_feed(all_results, run_time)
        print(f"  📡 RSS feed updated: {RSS_FILE}")

        # Update state — merge seen articles, prune old (>14 days)
        cutoff = (run_time - timedelta(days=14)).isoformat()
        merged = {}
        for guid, info in state.get("seen_articles", {}).items():
            if info.get("seen_at", "") > cutoff:
                merged[guid] = info
        merged.update(new_seen)

        state = {
            "last_run": run_time.isoformat(),
            "run_count": state.get("run_count", 0) + 1,
            "seen_articles": merged,
        }
        save_state(state)
        print(f"  💾 State updated: {len(merged)} tracked articles")

    print(
        f"\n  ✅ Done! {len(all_results)} candidate mention(s)"
        f" across {len(NEWS_FEEDS)} feeds."
    )


if __name__ == "__main__":
    main()
