#!/usr/bin/env python3

import sys
import argparse
import base64
import os
import pprint
import requests
import json
import datetime

# API endpoint misc.
API_HOST = "www.arista.com"
SESSION_CODE_API_URL = "https://" + API_HOST + "/api/sessionCode/"

hw_url = "/api/eox/hwLifecycle/"
sw_url = "/api/eox/swLifecycle/"


# credential caching
SESSION_KEY_CACHE = str(os.environ.get("HOME")) + "/.anet-api-session-cache.json"
# number of minutes before the session token expires to trigger a refresh
SESSION_REFRESH_INTERVAL = 10


def getSessionCode(api_token):
    """
    args:
    - api_token(str): the arista API token for the user as a base64 encoded string

    returns: the session_code from the API call which can be used for subsequent
             interactions. (str)
    """

    data = {"accessToken": api_token}
    session_info = {}

    session_req = requests.post(SESSION_CODE_API_URL, json=data, timeout=5)
    if session_req.status_code != requests.codes.ok:
        print("session code request error:", session_req)
        print("-" * 40)
        pprint.pprint(session_req.content)
        sys.exit(1)
    else:
        session_info = session_req.json()
        pprint.pprint(session_info)
        if 200 <= int(session_info["status"]["code"]) < 300:
            api_session_key = session_info["data"]["session_code"]
        else:
            print("error: invalid session info")
            print("-" * 40)
            pprint.pprint(session_info)
            sys.exit(1)

    return session_info["data"]


def writeSessionCache(cache_path, data):
    print(
        f"""
          writing new session cache
          path: {cache_path}
          data: {data["session_date"]} + {data["session_life"]} """
    )
    with open(cache_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=True, indent=2)

    return


def getLifecycleData(session_code, search_params):
    """getLifecycleData - builds the search query based on the provided search_params,

    args:
      - session_code(str): encrypted session_code for the session
      - search_params(dict): search parameters

    returns:
      - dict/list with the search results

    """
    search_fields = ["releaseTrain", "mainSku", "altModelNumber"]
    search_results = {}
    data = {"sessionCode": session_code}

    for field in search_fields:
        if field in search_params and search_params[field] != "":
            data[field] = search_params[field]

    info_req = requests.post(search_params["url"], json=data, timeout=5)
    try:
        search_results = info_req.json()
    except requests.exceptions.JSONDecodeError:
        print("error: unable to decode info json")
        print("-" * 40)
        pprint.pprint(info_req.content)

    return search_results


def parse_cli_args():
    """parse command line options and CLI flag dependencies.

    parameters: none
    returns:
        type: argparse object
    """
    parser = argparse.ArgumentParser(usage=arg_usage())
    parser.add_argument(
        "--hw",
        dest="hw_query",
        help="hardware lifecycle query",
        required=False,
        action="store_true",
    )

    parser.add_argument(
        "--sw",
        dest="sw_query",
        help="EOS software lifecycle query",
        required=False,
        action="store_true",
    )

    parser.add_argument(
        "--test",
        dest="test_query",
        help="run a suite of test queries",
        required=False,
        action="store_true",
    )

    parser.add_argument(
        "--format",
        dest="output_format",
        help="output format, one of [json, line, raw]",
        required=False,
        action="store",
        default="line",
    )

    parser.add_argument("query_string", help="query string", nargs="?", default="")
    args = parser.parse_args()

    if not (args.hw_query or args.sw_query or args.test_query):
        print("\nERROR: you must pick a query type")
        print(arg_usage())
        sys.exit()

    if (args.hw_query or args.sw_query) and not args.query_string:
        print("\nERROR: if you're not running a test you must specify a query type")
        print(arg_usage())
        sys.exit()

    return args


def checkSessionCache(cache_path):
    """getSessionCache - loads the session info from the local cache,
    calculates whether or not it should get a fresh session code or use the one
    in the cache.

    :cache_path: TODO
    :returns: TODO

    """

    session_code = ""

    # get the current time (GMT)
    now = datetime.datetime.utcnow()

    # load cache file as json
    with open(cache_path) as f:
        cache = json.load(f)

    session_exp_time = datetime.datetime.strptime(
        cache["session_date"], "%Y-%m-%d %H:%M:%S (%Z)"
    )
    session_exp_time = session_exp_time + datetime.timedelta(
        minutes=int(cache["session_life"])
    )

    session_time_delta = session_exp_time - now
    cache_diff_minutes = (session_time_delta.days * 24 * 60) + (
        session_time_delta.seconds / 60
    )
    if cache_diff_minutes <= SESSION_REFRESH_INTERVAL:
        print("session expired/expiring - refreshing session key")
        token = str(os.environ.get("ANET_API_TOKEN"))
        creds = (base64.b64encode(token.encode())).decode("utf-8")
        session_info = getSessionCode(creds)
        writeSessionCache(SESSION_KEY_CACHE, session_info)
        session_code = session_info["session_code"]

    else:
        session_code = cache["session_code"]

    return session_code


def formatOutput(product_info, format):
    if format == "json":
        pprint.pprint(product_info)
    else:
        max_key_len = max(map(len, product_info))
        for k in product_info:
            row = f"{k:>{max_key_len}}: {product_info[k]:<}"
            print(row)


def test_queries(session_key, output_format):
    search_tests = [
        {
            "name": "invalid sku search: cedarville-lk",
            "mainSku": "DCS-7280SR3MK-48YC8A-S",
            "url": "https://" + API_HOST + hw_url,
        },
        {
            "name": "invalid sku search: C-230E",
            "mainSku": "C-230E",
            "url": "https://" + API_HOST + hw_url,
        },
        {
            "name": "valid sku search",
            "mainSku": "DCS-7150S-24",
            "url": "https://" + API_HOST + hw_url,
        },
        {
            "name": "valid sku search DCS-7050Q-16",
            "mainSku": "DCS-7050Q-16",
            "url": "https://" + API_HOST + hw_url,
        },
        {
            "name": "invalid sku search",
            "mainSku": "DCS-7800R3AK-25",
            "url": "https://" + API_HOST + hw_url,
        },
        {
            "name": "release search",
            "releaseTrain": "4.20",
            "url": "https://" + API_HOST + sw_url,
        },
        {
            "name": "invalid release search",
            "releaseTrain": "4.40",
            "url": "https://" + API_HOST + sw_url,
        },
    ]

    print("running test query suite")
    for idx, search in enumerate(search_tests):
        print(f'{idx}: {search["name"]}')
        print("-" * 70)
        results = getLifecycleData(session_key, search)

        if results["status"]["type"] != "Success":
            output_format = "raw"

        if output_format == "raw":
            pprint.pprint(results)
        else:
            if isinstance(results["data"], list):
                for result in results["data"]:
                    print("-" * 70)
                    formatOutput(result, output_format)

    return


def main():
    """where the action is jackson"""
    # parse cli arguments
    cli_opts = parse_cli_args()

    # get the session key
    session_key = checkSessionCache(SESSION_KEY_CACHE)

    if cli_opts.test_query:
        test_queries(session_key, cli_opts.output_format)
        sys.exit()

    search = {}

    if cli_opts.hw_query:
        search = {
            "mainSku": cli_opts.query_string,
            "url": "https://" + API_HOST + hw_url,
        }

    if cli_opts.sw_query:
        search = {
            "releaseTrain": cli_opts.query_string,
            "url": "https://" + API_HOST + sw_url,
        }

    results = getLifecycleData(session_key, search)
    if int(results["status"]["code"]) > 300:
        print("ERROR: model/release not found")
        print("query string:", cli_opts.query_string)
        print("-" * 70)
        pprint.pprint(results)
        sys.exit(1)

    if cli_opts.output_format == "raw":
        pprint.pprint(results)

    else:
        if isinstance(results["data"], list):
            for result in results["data"]:
                print("-" * 70)
                formatOutput(result, cli_opts.output_format)
        else:
            formatOutput(results["data"], "json")


def arg_usage():
    """output a reasonble usage message

    parameters: none
    returns:
        string: usage message"""

    return """

get-anet-eos.py [--hw|--sw] <query_string>

--hw - if seeking hw EoX info
       query_string in the form of "DCS-7800R3AK-36"

--sw - if seeking sw EoX info
       query_string in the form of "4.20"

--format - output format, one of json, line, raw
      json: the product data is emitted in json format (if successful)
            json is the only format supported for software lifecycle searches
      line: product info is emitted in key: value line format
      raw: the full API response is emitted in json format.  this includes the
      return status information and not only the "data" container.  useful for
      debugging unexpected results.

"""


if __name__ == "__main__":
    main()
