#!/usr/bin/env python3

import time
import argparse
import yfinance as yf
from tabulate import tabulate
import sys


def load_stocklist(stockfile):
    stocks = []
    try:
        with open(stockfile) as file:
            stocks = file.readlines()
    except IOError:
        print("error opening stock ticker file:", stockfile)
        sys.exit()

    # cleanup any white space
    stocks = [x.strip() for x in stocks]
    return stocks


def get_quote(ticker):
    stockinfo = yf.Ticker(ticker)
    return stockinfo.info


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "stock_list", help="file containing the lists of stocks to track"
    )

    args = parser.parse_args()
    stocks = load_stocklist(args.stock_list)

    output_table = []
    headers = [
        "\nstock",
        "market\nprice",
        "(high)\nmarket price",
        "(low)\nmarket price",
        "\n52w high",
        "\n52w low",
        "\n50d avg",
    ]

    for s in stocks:
        quote = get_quote(s)
        row = [
            quote["symbol"],
            quote["regularMarketPrice"],
            quote["regularMarketDayHigh"],
            quote["regularMarketDayLow"],
            quote["fiftyTwoWeekHigh"],
            quote["fiftyTwoWeekLow"],
            quote["fiftyDayAverage"],
        ]
        output_table.append(row)

    table = tabulate(output_table, headers=headers, floatfmt=".2f")

    t = time.localtime()
    current_time = time.strftime("%d-%b, %Y [%H:%M:%S]", t)
    print(current_time)
    print(table)


if __name__ == "__main__":
    main()
