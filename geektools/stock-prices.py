#!/usr/bin/env python3

import time
import argparse
import yfinance as yf
import yaml


def load_holdings(stock_yaml):
    stream = open(stock_yaml, "r")
    holdings = yaml.load(stream, Loader=yaml.SafeLoader)

    return holdings


def get_quote(ticker):
    stockinfo = yf.Ticker(ticker)
    return stockinfo.info


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "stock_list", help="file containing the lists of stocks to track"
    )

    args = parser.parse_args()
    stocks = load_holdings(args.stock_list)
    # pp.pprint(stocks)

    t = time.localtime()
    current_time = time.strftime("%d-%b, %Y [%H:%M:%S]", t)
    print(current_time)

    stock_header = (
        #          1         2         3         4         5         6
        # 123456789012345678901234567890123456789012345678901234567890
        f"                 market\n"
        + f"stock             price  market(h)  market(l)    52w(h)    52w(l)"
    )
    print(stock_header)

    for stock in stocks:
        grants = stocks[stock]
        quote = get_quote(stock)

        stock_row = (
            f"{quote['symbol']:<15}"
            + f"{quote['regularMarketPrice']:>8.2f}"
            + f"{quote['regularMarketDayHigh']:>11.2f}"
            + f"{quote['regularMarketDayLow']:>11.2f}"
            + f"{quote['fiftyTwoWeekHigh']:>10.2f}"
            + f"{quote['fiftyTwoWeekLow']:>10.2f}"
        )
        print(stock_row)

        grant_header = (
            #          1         2         3         4
            # 123456789012345678901234567890123456789012345678901234567890
            f"       grant id                qty      price     value       g/l"
        )
        # output_table.append(grant_header)
        print(grant_header)
        g_total = 0
        for g in grants:
            grant_value = g["quantity"] * quote["regularMarketPrice"]
            g_total += grant_value
            gain_loss = grant_value - (g["quantity"] * g["price"])

            grant_line = (
                f"{g['grant_id']:>15}"
                + f"{quote['regularMarketPrice']:>8.2f}"
                + f"{g['quantity']:>11}"
                + f"{g['price']:>11.2f}"
                + f"{grant_value:>10.2f}"
                + f"{gain_loss:>10.2f}"
            )

            print(grant_line)

        stock_total = "total:" + f"{g_total:>49.2f}"
        print(stock_total)


if __name__ == "__main__":
    main()
