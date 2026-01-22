#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///

import argparse
import csv
import json
import subprocess
import sys
from datetime import datetime
from zoneinfo import ZoneInfo


def format_duration_from_minutes(total_minutes):
    """convert total minutes to days-hours:minutes format"""
    days = int(total_minutes // (24 * 60))
    hours = int((total_minutes % (24 * 60)) // 60)
    minutes = int(total_minutes % 60)
    return f"{days} days {hours}:{minutes:02d}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-g",
        "--gen_url",
        dest="gen_url",
        help="generate a list of URLs for OPEN PRs",
        action="store_true",
        required=False,
    )

    parser.add_argument(
        "-s",
        "--state",
        dest="pr_state",
        help="get PRs in one of the noted states (open|closed|merged|all) default: all",
        action="store",
        default="all",
        required=False,
    )

    parser.add_argument(
        "-l",
        "--limit",
        dest="limit",
        help="get a speciifc number of PRs default: 100",
        action="store",
        default="100",
        required=False,
    )

    parser.add_argument(
        "--csv",
        dest="csv_file",
        help="export PR data to CSV file",
        action="store",
        metavar="FILENAME",
        required=False,
    )
    args = parser.parse_args()

    # fetch PR data
    try:
        result = subprocess.run(
            # "op plugin run -- gh pr list"
            "gh pr list"
            + f" --limit {args.limit}"
            + " --json 'id,author,title,url,number,state,closedAt,createdAt,isDraft,mergedAt,updatedAt,labels'"
            + f" -s {args.pr_state}",
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

    # collect CSV data
    csv_data = []

    # print header
    print("| pr # | author | state | title | created | updated | notes |")
    print("|:----:|:------:|:-----:|:------|:-------:|:-------:|:------|")

    url_list = []

    # print rows
    for pr in filtered_prs:
        # extract label names from the labels structure
        label_names = [label["name"] for label in pr["labels"]]

        # set state to "-" if "Merged" label exists
        if "Merged" not in label_names and pr["state"] == "CLOSED":
            pr["state"] = "-"

        if "Merged" in label_names and pr["state"] == "CLOSED":
            pr["state"] = "MERGED"

        dt_create = datetime.fromisoformat(pr["createdAt"].replace("Z", "+00:00"))
        dt_update = datetime.fromisoformat(pr["updatedAt"].replace("Z", "+00:00"))
        # see obsidian://open?vault=personal-journal&file=2025%2F20251204
        # dt_closed = datetime.fromisoformat(pr["closedAt"].replace("Z", "+00:00"))
        # dt_merged = datetime.fromisoformat(pr["mergedAt"].replace("Z", "+00:00"))
        # convert to pacific time
        pt_create = dt_create.astimezone(ZoneInfo("America/Los_Angeles"))
        pt_update = dt_update.astimezone(ZoneInfo("America/Los_Angeles"))
        # pt_closed = dt_closed.astimezone(ZoneInfo("America/Los_Angeles"))
        # pt_merged = dt_merged.astimezone(ZoneInfo("America/Los_Angeles"))

        # calculate elapsed time for all PRs
        # elapsed_time_minutes = (dt_update - dt_create).total_seconds() / 60
        # elapsed_formatted = format_duration_from_minutes(elapsed_time_minutes)

        # collect merge times for closed PRs
        if pr["state"] == "CLOSED":
            merge_time_minutes = (dt_update - dt_create).total_seconds() / 60
            closed_pr_merge_times.append(merge_time_minutes)

        author = pr["author"]["login"]

        pr_update_time = pt_update.strftime("%Y-%m-%d %H:%M %Z")
        pr_create_time = pt_create.strftime("%Y-%m-%d %H:%M %Z")

        # format labels for display
        # labels_display = ", ".join(label_names) if label_names else "-"

        # collect data for CSV
        csv_data.append(
            {
                "pr_number": pr["number"],
                "url": pr["url"],
                "author": author,
                "state": pr["state"],
                "title": pr["title"],
                "created": pr_create_time,
                "updated": pr_update_time,
                "notes": "-",
            }
        )

        print(
            f"| [{pr['number']}]({pr['url']}) | {author} | {pr['state']} | {pr['title']} | {pr_create_time} | {pr_update_time} | - |"
        )
        if pr["state"] == "OPEN":
            url_list.append(pr["url"])

    # write CSV file if requested
    if args.csv_file:
        try:
            with open(args.csv_file, "w", newline="") as csvfile:
                fieldnames = [
                    "pr_number",
                    "url",
                    "author",
                    "state",
                    "title",
                    "created",
                    "updated",
                    "notes",
                ]
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(csv_data)
            print(f"\nCSV exported to: {args.csv_file}", file=sys.stderr)
        except IOError as e:
            print(f"Error writing CSV file: {e}", file=sys.stderr)
            sys.exit(1)

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
        print(f"- **median merge time:** {format_duration_from_minutes(median_time)}")
        print(f"- **min merge time:** {format_duration_from_minutes(min_time)}")
        print(f"- **max merge time:** {format_duration_from_minutes(max_time)}")
    else:
        print("\n**no closed PRs found for statistics calculation.**")

    if args.gen_url:
        for u in url_list:
            print(u)


if __name__ == "__main__":
    main()
