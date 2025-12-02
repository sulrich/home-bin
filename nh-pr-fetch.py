#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///

import argparse
import json
import subprocess
import sys
from datetime import datetime
from zoneinfo import ZoneInfo


def format_duration_from_minutes(total_minutes):
    """Convert total minutes to days-hours:minutes format"""
    days = int(total_minutes // (24 * 60))
    hours = int((total_minutes % (24 * 60)) // 60)
    minutes = int(total_minutes % 60)
    return f"{days}-{hours}:{minutes:02d}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--gen_url",
        dest="gen_url",
        help="generate a list of URLs for OPEN PRs",
        action="store_true",
        required=False,
    )
    args = parser.parse_args()

    # fetch PR data
    try:
        result = subprocess.run(
            "op plugin run -- gh pr list --limit 100"
            + " --json 'id,author,title,url,number,state,createdAt,isDraft,updatedAt'"
            + " -s all",
            capture_output=True,
            text=True,
            shell=True,
            check=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"error running gh command: {e}", file=sys.stderr)
        print(f"stderr: {e.stderr}", file=sys.stderr)
        print(f"stdout: {e.stdout}", file=sys.stderr)
        sys.exit(1)

    prs = json.loads(result.stdout)

    # filter for -nexthop authors
    filtered_prs = [pr for pr in prs if pr["author"]["login"].endswith("-nexthop")]
    filtered_prs = [pr for pr in filtered_prs if not pr["isDraft"]]

    # sort: open first, then by updated time (newest first)
    state_order = {"OPEN": 0, "CLOSED": 1, "MERGED": 1}
    filtered_prs.sort(
        key=lambda x: (
            state_order.get(x["state"], 2),
            -datetime.fromisoformat(x["updatedAt"].replace("Z", "+00:00")).timestamp(),
        )
    )

    # collect merge times for closed PRs
    closed_pr_merge_times = []

    # print header
    print(
        "| pr # | author | state | title | program | created | updated | elapsed | notes |"
    )
    print(
        "|:----:|:------:|:-----:|:------|:-------:|:-------:|:-------:|:-------:|:------|"
    )

    url_list = []

    # print rows
    for pr in filtered_prs:
        dt_update = datetime.fromisoformat(pr["updatedAt"].replace("Z", "+00:00"))
        dt_create = datetime.fromisoformat(pr["createdAt"].replace("Z", "+00:00"))
        pt_update = dt_update.astimezone(ZoneInfo("America/Los_Angeles"))
        pt_create = dt_create.astimezone(ZoneInfo("America/Los_Angeles"))

        # calculate elapsed time for all PRs
        elapsed_time_minutes = (dt_update - dt_create).total_seconds() / 60
        elapsed_formatted = format_duration_from_minutes(elapsed_time_minutes)

        # collect merge times for closed PRs
        if pr["state"] == "CLOSED":
            closed_pr_merge_times.append(elapsed_time_minutes)

        author = pr["author"]["login"]
        if pr["author"].get("name"):
            author += f" ({pr['author']['name']})"

        pr_update_time = pt_update.strftime("%Y-%m-%d %H:%M %Z")
        pr_create_time = pt_create.strftime("%Y-%m-%d %H:%M %Z")
        print(
            f"| [{pr['number']}]({pr['url']}) | {author} | {pr['state']} | {pr['title']} | - | {pr_create_time} | {pr_update_time} | {elapsed_formatted} | - |"
        )
        if pr["state"] == "OPEN":
            url_list.append(pr["url"])

    # calculate and display statistics for closed PRs
    if closed_pr_merge_times:
        avg_merge_time_minutes = sum(closed_pr_merge_times) / len(closed_pr_merge_times)
        sorted_times = sorted(closed_pr_merge_times)
        median_time = (
            sorted_times[len(sorted_times) // 2]
            if len(sorted_times) % 2 == 1
            else (
                sorted_times[len(sorted_times) // 2 - 1]
                + sorted_times[len(sorted_times) // 2]
            )
            / 2
        )
        min_time = min(closed_pr_merge_times)
        max_time = max(closed_pr_merge_times)

        print(f"\n## closed PR statistics ({len(closed_pr_merge_times)} PRs)")
        print(
            f"**average merge time:** {format_duration_from_minutes(avg_merge_time_minutes)}"
        )
        print(f"**median merge time:** {format_duration_from_minutes(median_time)}")
        print(f"**min merge time:** {format_duration_from_minutes(min_time)}")
        print(f"**max merge time:** {format_duration_from_minutes(max_time)}")
    else:
        print("\n**No closed PRs found for statistics calculation.**")

    if args.gen_url:
        for u in url_list:
            print(u)


if __name__ == "__main__":
    main()
