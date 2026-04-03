#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests>=2.31",
# ]
# ///
"""
mn_politics_monitor.py -- minnesota political reddit monitor.
monitors MN-focused subreddits for politically relevant posts.
tracks state between runs to avoid duplicates.
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

SUBREDDITS = [
    "minneapolis",
    "minnesota",
    "duluth",
    "stateofMN",
    "bemidji",
    "grandrapidsmn",
]

RSS_MAX_ITEMS = 60  # ~30 days at 2x/day

# reddit API
USER_AGENT = "mn-politics-monitor/1.0 (local research tool)"
POSTS_PER_SUB = 100  # max reddit allows per request
REQUEST_DELAY = 2.0  # polite delay between requests

# central timezone (UTC-6 standard, UTC-5 daylight)
CENTRAL_TZ = timezone(timedelta(hours=-6))

# --- political relevance filtering ------------------------------------------

# minnesota politicians and political figures (lowercase for matching)
MN_POLITICIANS = [
    # governor and statewide
    "walz",
    "tim walz",
    "peggy flanagan",
    "keith ellison",
    "steve simon",
    "julie blaha",
    "alan page",
    # US senators
    "amy klobuchar",
    "klobuchar",
    "tina smith",
    # US representatives
    "brad finstad",
    "angie craig",
    "dean phillips",
    "betty mccollum",
    "ilhan omar",
    "tom emmer",
    "michelle fischbach",
    "pete stauber",
    # state legislature leaders
    "melissa hortman",
    "lisa demuth",
    "bobby joe champion",
    "mark johnson",
    "jeremy miller",
    # minneapolis/st. paul mayors
    "jacob frey",
    "frey",
    "melvin carter",
    # other notable MN political figures
    "mary moriarty",
    "hennepin county",
    "ramsey county",
    "scott jensen",
    "jim schultz",
]

# political topic keywords
POLITICAL_KEYWORDS = [
    # government and process
    "governor",
    "mayor",
    "senator",
    "representative",
    "congressman",
    "congresswoman",
    "city council",
    "county board",
    "state legislature",
    "legislature",
    "legislative",
    "capitol",
    "statehouse",
    "election",
    "ballot",
    "vote",
    "voting",
    "voter",
    "caucus",
    "primary",
    "campaign",
    "candidate",
    "political",
    "politics",
    "democrat",
    "republican",
    "dfl",
    "gop",
    "liberal",
    "conservative",
    "progressive",
    "bipartisan",
    "partisan",
    # policy areas
    "legislation",
    "bill",
    "law",
    "ordinance",
    "regulation",
    "budget",
    "tax",
    "taxes",
    "funding",
    "deficit",
    "spending",
    "healthcare",
    "medicaid",
    "medicare",
    "insurance mandate",
    "education funding",
    "school board",
    "public school",
    "housing policy",
    "zoning",
    "rent control",
    "affordable housing",
    "minimum wage",
    "labor union",
    "workers rights",
    "police",
    "public safety",
    "crime bill",
    "gun control",
    "gun rights",
    "second amendment",
    "firearms",
    "immigration",
    "refugee",
    "asylum",
    "ice",
    "deportation",
    "border",
    "undocumented",
    "environment",
    "climate",
    "clean energy",
    "pipeline",
    "line 3",
    "enbridge",
    "mining",
    "sulfide mining",
    "abortion",
    "reproductive rights",
    "roe",
    "marijuana",
    "cannabis",
    "legalization",
    "infrastructure",
    "transit",
    "light rail",
    "southwest lrt",
    "blue line",
    "green line",
    "mndot",
    # trump administration / federal impact
    "trump",
    "executive order",
    "federal funding",
    "federal government",
    "white house",
    "administration",
    "doge",
    "elon musk",
    "musk",
    "tariff",
    "trade war",
    "federal cuts",
    "government shutdown",
    "national guard",
    "fema",
    "usda",
    "epa",
    "department of education",
    "title ix",
    "dei",
    "diversity equity",
    "affirmative action",
    "january 6",
    "j6",
    "insurrection",
    "project 2025",
    "heritage foundation",
    "social security",
    "snap",
    "food stamps",
    # minnesota-specific
    "minneapolis",
    "saint paul",
    "st. paul",
    "st paul",
    "duluth",
    "rochester",
    "bloomington",
    "eden prairie",
    "maple grove",
    "brooklyn park",
    "plymouth",
    "hennepin",
    "ramsey",
    "dakota county",
    "anoka",
    "iron range",
    "boundary waters",
    "bwca",
    "twin cities",
    "metro council",
    "met council",
    "mn united",
    "mall of america",  # sometimes political context
    "3m",
    "target corp",
    "mayo clinic",  # corporate political activity
]

# flair patterns that signal political content
POLITICAL_FLAIRS = [
    "politics",
    "political",
    "news",
    "government",
    "election",
    "legislation",
    "policy",
    "discussion",
    "opinion",
    "breaking",
    "local news",
    "state news",
]

# --- reddit fetching --------------------------------------------------------

SESSION = requests.Session()
SESSION.headers.update({"User-Agent": USER_AGENT})


def fetch_subreddit_posts(subreddit: str) -> list[dict]:
    """fetch recent posts from a subreddit via reddit's json API."""
    url = f"https://www.reddit.com/r/{subreddit}/new.json"
    params = {"limit": POSTS_PER_SUB}

    try:
        resp = SESSION.get(url, params=params, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        posts = data.get("data", {}).get("children", [])
        return [p["data"] for p in posts if p.get("kind") == "t3"]
    except requests.HTTPError as e:
        print(f"  ⚠ HTTP {e.response.status_code} fetching r/{subreddit}")
        return []
    except requests.RequestException as e:
        print(f"  ⚠ network error fetching r/{subreddit}: {e}")
        return []
    except Exception as e:
        print(f"  ⚠ unexpected error fetching r/{subreddit}: {e}")
        return []


# --- political relevance ----------------------------------------------------


def _word_boundary_match(term: str, text: str) -> bool:
    """check if term appears as a whole word/phrase in text (not substring)."""
    pattern = r"\b" + re.escape(term) + r"\b"
    return bool(re.search(pattern, text))


def is_politically_relevant(post: dict) -> tuple[bool, list[str]]:
    """check if a post is politically relevant.

    returns (is_relevant, list_of_matched_terms).
    uses word-boundary matching to avoid false positives (e.g. "tax" in "taxi").
    """
    matches = []

    # combine title + selftext for searching
    text = (post.get("title", "") + " " + post.get("selftext", "")).lower()

    # check flair
    flair = (post.get("link_flair_text") or "").lower()
    for f in POLITICAL_FLAIRS:
        if f in flair:
            matches.append(f"flair:{flair}")
            break

    # check politicians (word boundary)
    for politician in MN_POLITICIANS:
        if _word_boundary_match(politician, text):
            matches.append(f"politician:{politician}")

    # check keywords (word boundary)
    for keyword in POLITICAL_KEYWORDS:
        if _word_boundary_match(keyword, text):
            matches.append(f"keyword:{keyword}")

    # deduplicate
    matches = list(dict.fromkeys(matches))

    return len(matches) > 0, matches[:10]  # cap at 10 for readability


# --- state management -------------------------------------------------------


def load_state(state_file: Path) -> dict:
    """load the state file tracking previously seen posts."""
    if state_file.exists():
        with open(state_file) as f:
            return json.load(f)
    return {"last_run": None, "seen_posts": {}, "run_count": 0}


def save_state(state: dict, state_file: Path, cache_dir: Path):
    """persist state to disk."""
    cache_dir.mkdir(parents=True, exist_ok=True)
    with open(state_file, "w") as f:
        json.dump(state, f, indent=2)


# --- report generation ------------------------------------------------------


def format_post_summary(post: dict, matches: list[str]) -> str:
    """format a single post as a markdown entry."""
    title = post.get("title", "Untitled")
    author = post.get("author", "unknown")
    score = post.get("score", 0)
    num_comments = post.get("num_comments", 0)
    upvote_ratio = post.get("upvote_ratio", 0)
    permalink = f"https://reddit.com{post.get('permalink', '')}"
    created_utc = post.get("created_utc", 0)
    flair = post.get("link_flair_text") or ""

    # convert UTC timestamp to central
    dt = datetime.fromtimestamp(created_utc, tz=CENTRAL_TZ)
    time_str = dt.strftime("%Y-%m-%d %I:%M %p CT")

    # build synopsis from selftext
    selftext = post.get("selftext", "").strip()
    if selftext:
        synopsis = selftext[:300].replace("\n", " ").strip()
        if len(selftext) > 300:
            synopsis += "..."
    else:
        url = post.get("url", "")
        if url and url != permalink:
            synopsis = f"Link: {url}"
        else:
            synopsis = "*No text body*"

    tag_str = ", ".join(m.split(":", 1)[1] for m in matches[:5])

    lines = []
    lines.append(f"### [{title}]({permalink})")
    lines.append("")
    lines.append(f"- **Posted:** {time_str} by u/{author}")
    if flair:
        lines.append(f"- **Flair:** {flair}")
    lines.append(
        f"- **Score:** {score} | **Comments:** {num_comments}"
        f" | **Upvote ratio:** {upvote_ratio:.0%}"
    )
    lines.append(f"- **Matched on:** {tag_str}")
    lines.append("")
    lines.append(f"> {synopsis}")
    lines.append("")

    return "\n".join(lines)


def generate_report_section(
    results: dict[str, list], run_time: datetime, is_first: bool
) -> str:
    """generate a report section for this snapshot run."""
    time_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y-%m-%d %I:%M %p CT")
    total_posts = sum(len(posts) for posts in results.values())

    lines = []

    if is_first:
        date_header = run_time.astimezone(CENTRAL_TZ).strftime("%A, %B %-d, %Y")
        lines.append(f"# Minnesota Political Reddit Monitor -- {date_header}")
        lines.append("")

    lines.append(f"## Snapshot: {time_str}")
    lines.append("")
    lines.append(
        f"**{total_posts} politically relevant posts found"
        f" across {len(SUBREDDITS)} subreddits**"
    )
    lines.append("")
    lines.append("---")
    lines.append("")

    for subreddit in SUBREDDITS:
        posts = results.get(subreddit, [])
        lines.append(f"### r/{subreddit}")
        lines.append("")

        if not posts:
            lines.append("*No new politically relevant posts since last check.*")
            lines.append("")
        else:
            lines.append(f"**{len(posts)} post(s) found**")
            lines.append("")

            # sort by score descending
            posts.sort(key=lambda x: x[0].get("score", 0), reverse=True)

            for post, matches in posts:
                lines.append(format_post_summary(post, matches))

        lines.append("---")
        lines.append("")

    lines.append(f"*Snapshot completed: {time_str} | Subreddits: {len(SUBREDDITS)}*")
    lines.append("")

    return "\n".join(lines)


# --- RSS feed generation ----------------------------------------------------


def _sanitize_xml(text: str) -> str:
    """strip characters that are invalid in XML 1.0."""
    # valid: #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD]
    return re.sub(
        r"[^\x09\x0A\x0D\x20-\uD7FF\uE000-\uFFFD\U00010000-\U0010FFFF]",
        "",
        text,
    )


def generate_rss_item_html(subreddit: str, posts: list, run_time: datetime) -> str:
    """generate HTML content for a single subreddit's RSS item."""
    html_parts = []

    html_parts.append(f"<p><strong>{len(posts)} post(s) found</strong></p>")

    posts.sort(key=lambda x: x[0].get("score", 0), reverse=True)

    for post, matches in posts:
        title = escape(post.get("title", "Untitled"))
        author = escape(post.get("author", "unknown"))
        score = post.get("score", 0)
        num_comments = post.get("num_comments", 0)
        upvote_ratio = post.get("upvote_ratio", 0)
        permalink = f"https://reddit.com{post.get('permalink', '')}"
        created_utc = post.get("created_utc", 0)
        flair = post.get("link_flair_text") or ""

        dt = datetime.fromtimestamp(created_utc, tz=CENTRAL_TZ)
        post_time = dt.strftime("%Y-%m-%d %I:%M %p CT")

        selftext = post.get("selftext", "").strip()
        if selftext:
            synopsis = escape(selftext[:300].replace("\n", " ").strip())
            if len(selftext) > 300:
                synopsis += "..."
        else:
            url = post.get("url", "")
            if url and url != permalink:
                synopsis = f'<a href="{escape(url)}">{escape(url)}</a>'
            else:
                synopsis = "<em>No text body</em>"

        tag_str = escape(", ".join(m.split(":", 1)[1] for m in matches[:5]))

        flair_line = ""
        if flair:
            flair_line = f"<br/>Flair: {escape(flair)}"

        html_parts.append(f"""
<div style="margin-bottom:1.5em;border-left:3px solid #ccc;padding-left:10px;">
  <p><strong><a href="{escape(permalink)}">{title}</a></strong></p>
  <p style="font-size:0.9em;color:#666;">
    {post_time} by u/{author}{flair_line}<br/>
    Score: {score} | Comments: {num_comments} | Upvote ratio: {upvote_ratio:.0%}<br/>
    Matched on: {tag_str}
  </p>
  <blockquote>{synopsis}</blockquote>
</div>""")

    return "\n".join(html_parts)


def update_rss_feed(
    results: dict[str, list], run_time: datetime, rss_file: Path, rss_dir: Path
):
    """update the RSS feed file with one item per subreddit that has new posts."""
    time_str = run_time.astimezone(CENTRAL_TZ).strftime("%I:%M %p CT")
    date_str = run_time.astimezone(CENTRAL_TZ).strftime("%A, %B %-d, %Y")
    pub_date = format_datetime(run_time)

    # load existing feed or start fresh
    existing_items = []
    if rss_file.exists():
        try:
            tree = ET.parse(rss_file)
            root = tree.getroot()
            channel = root.find("channel")
            if channel is not None:
                existing_items = channel.findall("item")
        except ET.ParseError:
            existing_items = []

    rss = ET.Element("rss", version="2.0")
    channel = ET.SubElement(rss, "channel")

    ET.SubElement(channel, "title").text = "Minnesota Political Reddit Monitor"
    ET.SubElement(channel, "link").text = "https://www.reddit.com/r/minnesota/"
    ET.SubElement(
        channel, "description"
    ).text = "Politically relevant posts from Minnesota subreddits"
    ET.SubElement(channel, "language").text = "en-us"
    ET.SubElement(channel, "lastBuildDate").text = pub_date

    # one item per subreddit that has new posts
    new_item_count = 0
    for subreddit in SUBREDDITS:
        posts = results.get(subreddit, [])
        if not posts:
            continue

        item_title = f"r/{subreddit}: {len(posts)} posts -- {date_str} {time_str}"
        item_html = generate_rss_item_html(subreddit, posts, run_time)
        item_link = f"https://www.reddit.com/r/{subreddit}/new/"
        guid = f"mn-politics-{subreddit}-{run_time.strftime('%Y%m%d-%H%M%S')}"

        new_item = ET.SubElement(channel, "item")
        ET.SubElement(new_item, "title").text = item_title
        ET.SubElement(new_item, "link").text = item_link
        ET.SubElement(new_item, "description").text = item_html
        ET.SubElement(new_item, "pubDate").text = pub_date
        ET.SubElement(new_item, "guid", isPermaLink="false").text = guid
        new_item_count += 1

    # keep existing items up to the max
    keep = max(0, RSS_MAX_ITEMS - new_item_count)
    for old_item in existing_items[:keep]:
        channel.append(old_item)

    # write feed, sanitizing invalid XML chars
    rss_dir.mkdir(parents=True, exist_ok=True)
    ET.indent(rss, space="  ")
    tree = ET.ElementTree(rss)
    with open(rss_file, "w", encoding="utf-8") as f:
        xml_str = ET.tostring(rss, encoding="unicode", xml_declaration=True)
        f.write(_sanitize_xml(xml_str))
        f.write("\n")


# --- main -------------------------------------------------------------------


def parse_args():
    parser = argparse.ArgumentParser(
        description="Minnesota Political Reddit Monitor"
    )
    parser.add_argument(
        "-n", "--dry-run", action="store_true",
        help="print what would be saved without writing files",
    )
    parser.add_argument(
        "-f", "--force-all", action="store_true",
        help="ignore state file, fetch everything available",
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
    state_file = cache_dir / "mn_politics_state.json"
    rss_dir = www_dir / "rss"
    rss_file = rss_dir / "mn-politics.rss"

    print("mn politics reddit monitor")
    print(f"   time: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}")
    print(f"   mode: {'DRY RUN' if args.dry_run else 'LIVE'}")
    print(
        f"   markdown: {'yes' if args.markdown else 'no (use -m/--markdown to enable)'}"
    )
    if args.force_all:
        print("   force mode: ignoring previous state")
    print()

    # load state
    state = load_state(state_file)
    seen_posts = (
        set(state.get("seen_posts", {}).keys()) if not args.force_all else set()
    )

    run_time = datetime.now(timezone.utc)
    results = {}
    new_seen = {}

    for subreddit in SUBREDDITS:
        print(f"  fetching r/{subreddit}...", end=" ", flush=True)
        time.sleep(REQUEST_DELAY)

        posts = fetch_subreddit_posts(subreddit)
        print(f"got {len(posts)} posts", end="")

        relevant = []
        for post in posts:
            post_id = post.get("id", "")

            # track all posts for dedup on next run
            new_seen[post_id] = {
                "subreddit": subreddit,
                "created_utc": post.get("created_utc", 0),
                "seen_at": run_time.isoformat(),
            }

            if post_id in seen_posts:
                continue

            is_relevant, matches = is_politically_relevant(post)
            if is_relevant:
                relevant.append((post, matches))

        print(f" -> {len(relevant)} politically relevant (new)")
        results[subreddit] = relevant

    total_found = sum(len(posts) for posts in results.values())

    # one file per day, append if it already exists
    report_dir.mkdir(parents=True, exist_ok=True)
    date_str = run_time.astimezone(CENTRAL_TZ).strftime("%Y%m%d")
    report_file = report_dir / f"{date_str}-reddit-politics.md"
    is_first = not report_file.exists()
    report = generate_report_section(results, run_time, is_first=is_first)

    if args.dry_run:
        print(f"\n{'=' * 60}")
        print(report)
        print(f"{'=' * 60}")
        print(f"\n  would {'create' if is_first else 'append to'}: {report_file}")
        print(f"  would update RSS feed: {rss_file}")
        print(f"  would update state with {len(new_seen)} seen posts")
    else:
        if args.markdown:
            with open(report_file, "a") as f:
                if not is_first:
                    f.write("\n\n")
                f.write(report)
            action = "created" if is_first else "appended to"
            print(f"\n  report {action}: {report_file}")

        # RSS feed (always)
        update_rss_feed(results, run_time, rss_file, rss_dir)
        print(f"  RSS feed updated: {rss_file}")

        # merge new seen posts, prune entries older than 7 days
        cutoff = (run_time - timedelta(days=7)).timestamp()
        merged_seen = {}

        for pid, info in state.get("seen_posts", {}).items():
            if info.get("created_utc", 0) > cutoff:
                merged_seen[pid] = info

        merged_seen.update(new_seen)

        state["seen_posts"] = merged_seen
        state["last_run"] = run_time.isoformat()
        state["run_count"] = state.get("run_count", 0) + 1
        save_state(state, state_file, cache_dir)
        print(f"  state updated: {len(merged_seen)} tracked posts")

    print(
        f"\n  done. {total_found} politically relevant posts"
        f" across {len(SUBREDDITS)} subreddits."
    )


if __name__ == "__main__":
    main()
