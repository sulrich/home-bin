#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///

import json
import subprocess
import sys
from datetime import datetime
from zoneinfo import ZoneInfo


def main():
    # fetch PR data
    try:
        result = subprocess.run(
            "op plugin run -- gh pr list --limit 100 --json 'id,author,title,url,number,state,updatedAt' -s all",
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

    # sort: open first, then by updated time (newest first)
    state_order = {"OPEN": 0, "CLOSED": 1, "MERGED": 1}
    filtered_prs.sort(
        key=lambda x: (
            state_order.get(x["state"], 2),
            -datetime.fromisoformat(x["updatedAt"].replace("Z", "+00:00")).timestamp(),
        )
    )

    # print header
    print("| pr # | author | state | title | updated |")
    print("|:----:|:------:|:-----:|:------|:-------:|")

    # print rows
    for pr in filtered_prs:
        dt = datetime.fromisoformat(pr["updatedAt"].replace("Z", "+00:00"))
        pt = dt.astimezone(ZoneInfo("America/Los_Angeles"))

        author = pr["author"]["login"]
        if pr["author"].get("name"):
            author += f" ({pr['author']['name']})"

        pr_time = pt.strftime("%Y-%m-%d %H:%M %Z")
        print(
            f"| [{pr['number']}]({pr['url']}) | {author} | {pr['state']} | {pr['title']} | {pr_time} |"
        )


if __name__ == "__main__":
    main()
