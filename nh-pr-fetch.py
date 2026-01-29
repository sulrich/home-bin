#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "google-api-python-client",
#   "google-auth-httplib2",
#   "google-auth-oauthlib",
# ]
# ///

import argparse
import csv
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build


def format_duration_from_minutes(total_minutes):
    """convert total minutes to days-hours:minutes format"""
    days = int(total_minutes // (24 * 60))
    hours = int((total_minutes % (24 * 60)) // 60)
    minutes = int(total_minutes % 60)
    return f"{days} days {hours}:{minutes:02d}"


def parse_args():
    """Parse command line arguments."""
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
        help="get a specific number of PRs default: 1000",
        action="store",
        default="1000",
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

    parser.add_argument(
        "--gsheet",
        dest="spreadsheet_id",
        help="export PR data to Google Sheets (provide spreadsheet ID)",
        action="store",
        metavar="SPREADSHEET_ID",
        required=False,
    )

    parser.add_argument(
        "--credentials",
        dest="credentials_path",
        help="path to Google OAuth credentials.json (default: ./credentials.json)",
        action="store",
        default="./credentials.json",
        metavar="PATH",
        required=False,
    )
    return parser.parse_args()


def fetch_pr_data(limit, pr_state):
    """Run gh CLI and return raw PR data as list of dicts."""
    try:
        result = subprocess.run(
            "gh pr list"
            + f" --limit {limit}"
            + " --json 'id,author,title,url,number,state,closedAt,createdAt,isDraft,mergedAt,updatedAt,labels'"
            + f" -s {pr_state}",
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

    return json.loads(result.stdout)


def filter_and_sort_prs(prs):
    """filter for -nexthop authors, remove drafts, and sort by state/update time."""
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

    return filtered_prs


def prepare_pr_records(prs):
    """convert PRs to record dicts with formatted times. returns (records, merge_times)."""
    records = []
    closed_pr_merge_times = []

    for pr in prs:
        # extract label names from the labels structure
        label_names = [label["name"] for label in pr["labels"]]

        # set state to "-" if "Merged" label exists
        if "Merged" not in label_names and pr["state"] == "CLOSED":
            pr["state"] = "-"

        if "Merged" in label_names and pr["state"] == "CLOSED":
            pr["state"] = "MERGED"

        dt_create = datetime.fromisoformat(pr["createdAt"].replace("Z", "+00:00"))
        dt_update = datetime.fromisoformat(pr["updatedAt"].replace("Z", "+00:00"))

        # convert to pacific time
        pt_create = dt_create.astimezone(ZoneInfo("America/Los_Angeles"))
        pt_update = dt_update.astimezone(ZoneInfo("America/Los_Angeles"))

        # collect merge times for closed PRs
        if pr["state"] == "CLOSED":
            merge_time_minutes = (dt_update - dt_create).total_seconds() / 60
            closed_pr_merge_times.append(merge_time_minutes)

        author = pr["author"]["login"]
        pr_update_time = pt_update.strftime("%Y-%m-%d %H:%M %Z")
        pr_create_time = pt_create.strftime("%Y-%m-%d %H:%M %Z")

        records.append(
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

    return records, closed_pr_merge_times


def export_csv(records, filename):
    """Export records to CSV file."""
    try:
        with open(filename, "w", newline="") as csvfile:
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
            writer.writerows(records)
        print(f"\nCSV exported to: {filename}", file=sys.stderr)
    except IOError as e:
        print(f"Error writing CSV file: {e}", file=sys.stderr)
        sys.exit(1)


def print_markdown_table(records):
    """Print records as a markdown table."""
    print("| pr # | author | state | title | created | updated | notes |")
    print("|:----:|:------:|:-----:|:------|:-------:|:-------:|:------|")

    for record in records:
        # note, this should render as a single line
        print(
            f"| [{record['pr_number']}]({record['url']}) | {record['author']} |"
            f" {record['state']} | {record['title']} | {record['created']} |"
            f" {record['updated']} | - |"
        )


def print_statistics(merge_times):
    """Print statistics for closed PRs."""
    if merge_times:
        avg_merge_time_minutes = sum(merge_times) / len(merge_times)
        sorted_times = sorted(merge_times)
        median_time = (
            sorted_times[len(sorted_times) // 2]
            if len(sorted_times) % 2 == 1
            else (
                sorted_times[len(sorted_times) // 2 - 1]
                + sorted_times[len(sorted_times) // 2]
            )
            / 2
        )
        min_time = min(merge_times)
        max_time = max(merge_times)

        print(f"\n## closed PR statistics ({len(merge_times)} PRs)")
        print(
            f"**average merge time:** {format_duration_from_minutes(avg_merge_time_minutes)}"
        )
        print(f"- **median merge time:** {format_duration_from_minutes(median_time)}")
        print(f"- **min merge time:** {format_duration_from_minutes(min_time)}")
        print(f"- **max merge time:** {format_duration_from_minutes(max_time)}")
    else:
        print("\n**no closed PRs found for statistics calculation.**")


def print_url_list(records):
    """print URLs for open prs."""
    for record in records:
        if record["state"] == "OPEN":
            print(record["url"])


SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]


def get_google_sheets_service(credentials_path):
    """authenticate and return a google sheets service instance."""
    creds = None
    credentials_path = Path(credentials_path)
    token_path = credentials_path.parent / "token.json"

    # load existing token if available
    if token_path.exists():
        creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)

    # refresh or obtain new credentials
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not credentials_path.exists():
                print(
                    f"Error: credentials file not found at {credentials_path}",
                    file=sys.stderr,
                )
                sys.exit(1)
            flow = InstalledAppFlow.from_client_secrets_file(
                str(credentials_path), SCOPES
            )
            creds = flow.run_local_server(port=0)

        # save token for next run
        with open(token_path, "w") as token:
            token.write(creds.to_json())

    return build("sheets", "v4", credentials=creds)


def generate_tab_name(service, spreadsheet_id):
    """generate a unique tab name in YYYYMMDD format, with suffix if needed."""
    # get existing sheet names
    spreadsheet = service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
    existing_names = {sheet["properties"]["title"] for sheet in spreadsheet["sheets"]}

    # generate base name
    base_name = datetime.now().strftime("%Y%m%d")

    # check if base name is available
    if base_name not in existing_names:
        return base_name

    # find next available suffix
    suffix = 1
    while True:
        candidate = f"{base_name}-{suffix:02d}"
        if candidate not in existing_names:
            return candidate
        suffix += 1


def export_to_gsheet(service, spreadsheet_id, records):
    """export records to a new tab in the google sheets spreadsheet."""
    tab_name = generate_tab_name(service, spreadsheet_id)

    # create new tab
    request_body = {
        "requests": [
            {
                "addSheet": {
                    "properties": {
                        "title": tab_name,
                    }
                }
            }
        ]
    }
    service.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id, body=request_body
    ).execute()

    # prepare data with header row
    header = [
        "pr_number",
        "url",
        "pr_link",
        "author",
        "state",
        "title",
        "created",
        "updated",
        "notes",
    ]

    rows = [header]
    for record in records:
        # create hyperlink formula
        hyperlink = f'=HYPERLINK("{record["url"]}", "PR# {record["pr_number"]}")'
        rows.append(
            [
                record["pr_number"],
                record["url"],
                hyperlink,
                record["author"],
                record["state"],
                record["title"],
                record["created"],
                record["updated"],
                record["notes"],
            ]
        )

    # write data to the new tab
    range_name = f"{tab_name}!A1"
    body = {"values": rows}
    service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id,
        range=range_name,
        valueInputOption="USER_ENTERED",
        body=body,
    ).execute()

    print(f"\ngoogle sheets exported to tab: {tab_name}", file=sys.stderr)


def main():
    args = parse_args()

    # fetch and process PR data
    prs = fetch_pr_data(args.limit, args.pr_state)
    filtered_prs = filter_and_sort_prs(prs)
    records, closed_pr_merge_times = prepare_pr_records(filtered_prs)

    # print markdown table to stdout
    print_markdown_table(records)

    # export to CSV if requested
    if args.csv_file:
        export_csv(records, args.csv_file)

    # export to google sheets if requested
    if args.spreadsheet_id:
        service = get_google_sheets_service(args.credentials_path)
        export_to_gsheet(service, args.spreadsheet_id, records)

    # print statistics
    print_statistics(closed_pr_merge_times)

    # print URL list if requested
    if args.gen_url:
        print_url_list(records)


if __name__ == "__main__":
    main()
