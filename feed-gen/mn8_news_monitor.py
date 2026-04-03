#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests>=2.31",
#     "feedparser>=6.0",
# ]
# ///
"""
mn8_news_monitor.py -- MN-8 candidate news aggregator.
monitors local MN news RSS feeds for mentions of candidates in
minnesota's 8th congressional district race.
"""

import argparse
import json
import os
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

# --- configuration ----------------------------------------------------------

# news sources with RSS feeds covering MN-8 territory
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

# candidates to track -- name variations for matching
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

# district-level keywords (catch articles about the race itself)
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

RSS_MAX_ITEMS = 100

# central timezone
CENTRAL_TZ = timezone(timedelta(hours=-6))

# polite delay between requests
REQUEST_DELAY = 1.0
USER_AGENT = "mn8-news-monitor/1.0 (local research tool)"

# --- feed fetching ----------------------------------------------------------

SESSION = requests.Session()
SESSION.headers.update({"User-Agent": USER_AGENT})


def fetch_feed(feed_config: dict) -> list[dict]:
    """fetch and parse an RSS feed, returning normalized article dicts."""
    url = feed_config["url"]
    source = feed_config["name"]

    try:
        resp = SESSION.get(url, timeout=30)
        resp.raise_for_status()
        parsed = feedparser.parse(resp.content)
    except requests.RequestException as e:
        print(f"  error fetching {source}: {e}")
        return []

    articles = []
    for entry in parsed.entries:
        title = entry.get("title", "").strip()
        link = entry.get("link", "").strip()
        summary = entry.get("summary", entry.get("description", "")).strip()

        # parse publication date
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

        guid = entry.get("id", entry.get("guid", link))
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


# --- candidate matching -----------------------------------------------------


def match_candidates(article: dict) -> dict:
    """check if an article mentions any tracked candidates or the MN-8 race.

    returns dict of matched candidate keys and race keyword matches.
    """
    # combine title + summary, strip HTML tags for matching
    raw_text = article["title"] + " " + article["summary"]
    text = re.sub(r"<[^>]+>", " ", raw_text).lower()

    matches = {
        "candidates": {},
        "race_keywords": [],
    }

    for key, info in CANDIDATES.items():
        for pattern in info["patterns"]:
            if re.search(r"\b" + re.escape(pattern) + r"\b", text):
                matches["candidates"][key] = info["display"]
                break  # one match per candidate is enough

    for keyword in RACE_KEYWORDS:
        if re.search(r"\b" + re.escape(keyword) + r"\b", text):
            matches["race_keywords"].append(keyword)

    return matches


def is_relevant(matches: dict) -> bool:
    """an article is relevant if it mentions any candidate or the race."""
    return bool(matches["candidates"]) or bool(matches["race_keywords"])


# --- state management -------------------------------------------------------


def load_state(state_file: Path) -> dict:
    if state_file.exists():
        with open(state_file) as f:
            return json.load(f)
    return {"last_run": None, "run_count": 0, "seen_articles": {}}


def save_state(state: dict, state_file: Path, cache_dir: Path):
    cache_dir.mkdir(parents=True, exist_ok=True)
    with open(state_file, "w") as f:
        json.dump(state, f, indent=2)


# --- report generation ------------------------------------------------------


def format_article_md(article: dict, matches: dict) -> str:
    """format an article as markdown."""
    title = article["title"]
    link = article["link"]
    source = article["source"]
    author = article.get("author", "")
    pub_date = article.get("pub_date")

    time_str = ""
    if pub_date:
        time_str = pub_date.astimezone(CENTRAL_TZ).strftime("%Y-%m-%d %I:%M %p CT")

    # strip HTML from summary
    summary = re.sub(r"<[^>]+>", " ", article.get("summary", ""))
    summary = re.sub(r"\s+", " ", summary).strip()
    if len(summary) > 400:
        summary = summary[:400] + "..."

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
    """generate the markdown report section."""
    time_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y-%m-%d %I:%M %p CT")
    lines = []

    if is_first:
        date_header = run_time.astimezone(CENTRAL_TZ).strftime("%A, %B %-d, %Y")
        lines.append(f"# MN-8 candidate news monitor -- {date_header}")
        lines.append("")

    lines.append(f"## snapshot: {time_str}")
    lines.append("")
    lines.append(f"**{len(results)} article(s) mentioning MN-8 candidates**")
    lines.append("")
    lines.append("---")
    lines.append("")

    if not results:
        lines.append("*No new candidate mentions found since last check.*")
        lines.append("")
    else:
        # group by candidate (articles can appear under multiple)
        by_candidate = {}
        general_race = []

        for article, matches in results:
            if matches["candidates"]:
                for ckey, cname in matches["candidates"].items():
                    by_candidate.setdefault(ckey, []).append((article, matches))
            elif matches["race_keywords"]:
                general_race.append((article, matches))

        # tracked candidates first
        priority_order = ["trina_swanson", "cyle_cramer", "pete_stauber"]
        shown_guids = set()

        for ckey in priority_order:
            if ckey not in by_candidate:
                continue
            cname = CANDIDATES[ckey]["display"]
            party = CANDIDATES[ckey]["party"]
            articles = by_candidate[ckey]
            lines.append(f"### {cname} ({party})")
            lines.append("")
            lines.append(f"**{len(articles)} mention(s)**")
            lines.append("")

            for article, matches in articles:
                if article["guid"] not in shown_guids:
                    lines.append(format_article_md(article, matches))
                    shown_guids.add(article["guid"])

        # other candidates
        for ckey in sorted(by_candidate.keys()):
            if ckey in priority_order:
                continue
            cname = CANDIDATES[ckey]["display"]
            party = CANDIDATES[ckey]["party"]
            articles = by_candidate[ckey]
            lines.append(f"### {cname} ({party})")
            lines.append("")
            lines.append(f"**{len(articles)} mention(s)**")
            lines.append("")

            for article, matches in articles:
                if article["guid"] not in shown_guids:
                    lines.append(format_article_md(article, matches))
                    shown_guids.add(article["guid"])

        # general race mentions
        if general_race:
            lines.append("### MN-8 race (general)")
            lines.append("")
            for article, matches in general_race:
                if article["guid"] not in shown_guids:
                    lines.append(format_article_md(article, matches))
                    shown_guids.add(article["guid"])

    lines.append("---")
    lines.append(f"*news monitor | MN-8 | {len(NEWS_FEEDS)} feeds | {time_str}*")
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


def generate_rss_item_html(article: dict, matches: dict) -> str:
    """generate HTML for a single article RSS item."""
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


def update_rss_feed(
    results: list[dict], run_time: datetime, rss_file: Path, rss_dir: Path
):
    """update RSS feed -- one item per matched article."""
    pub_date = format_datetime(run_time)

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

    # one item per article
    new_count = 0
    for article, matches in results:
        candidate_names = list(matches["candidates"].values())
        title_prefix = ", ".join(candidate_names) if candidate_names else "MN-8"

        item_title = f"{title_prefix}: {article['title']}"
        item_html = generate_rss_item_html(article, matches)

        # use article pub date if available, otherwise run time
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

    keep = max(0, RSS_MAX_ITEMS - new_count)
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
        description="MN-8 Candidate News Aggregator"
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
    state_file = cache_dir / "mn8_news_state.json"
    rss_dir = www_dir / "rss"
    rss_file = rss_dir / "mn8-news.rss"

    print("MN-8 candidate news monitor")
    print(f"   time: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}")
    print(f"   mode: {'DRY RUN' if args.dry_run else 'LIVE'}")
    print(
        f"   markdown: {'yes' if args.markdown else 'no (use -m/--markdown to enable)'}"
    )
    print(f"   feeds: {len(NEWS_FEEDS)}")
    tracked = [c["display"] for c in CANDIDATES.values()]
    print(f"   tracking: {', '.join(tracked)}")
    if args.force_all:
        print("   force mode: reporting everything as new")
    print()

    state = load_state(state_file)
    seen_articles = (
        set(state.get("seen_articles", {}).keys()) if not args.force_all else set()
    )

    run_time = datetime.now(timezone.utc)
    all_results = []
    new_seen = {}

    for feed_config in NEWS_FEEDS:
        print(f"  fetching {feed_config['name']}...", end=" ", flush=True)
        time.sleep(REQUEST_DELAY)

        articles = fetch_feed(feed_config)
        print(f"got {len(articles)} articles", end="")

        relevant_count = 0
        for article in articles:
            guid = article["guid"]

            # track for dedup
            new_seen[guid] = {
                "source": article["source"],
                "title": article["title"][:100],
                "seen_at": run_time.isoformat(),
            }

            if guid in seen_articles:
                continue

            matches = match_candidates(article)
            if is_relevant(matches):
                all_results.append((article, matches))
                relevant_count += 1

        print(f" -> {relevant_count} candidate mention(s)")

    # most recent first
    all_results.sort(
        key=lambda x: x[0].get("pub_date") or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )

    report_dir.mkdir(parents=True, exist_ok=True)
    date_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y%m%d")
    report_file = report_dir / f"{date_str}-mn8-news.md"
    is_first = not report_file.exists()
    report = generate_markdown_report(all_results, run_time, is_first=is_first)

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

        update_rss_feed(all_results, run_time, rss_file, rss_dir)
        print(f"  RSS feed updated: {rss_file}")

        # merge seen articles, prune entries older than 14 days
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
        save_state(state, state_file, cache_dir)
        print(f"  state updated: {len(merged)} tracked articles")

    print(
        f"\n  done. {len(all_results)} candidate mention(s)"
        f" across {len(NEWS_FEEDS)} feeds."
    )


if __name__ == "__main__":
    main()
