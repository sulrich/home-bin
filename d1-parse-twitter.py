#!/usr/bin/env python
# -*- coding: utf-8 -*-

# script to open the file specified (-infile) parse the latest twitter entries
# enclosed within the file for presentation to the day1 cli app.  the format for
# the entries will be as follows.
#
# tweets by me (md heading 2)
# date: <timestamp>
# tweet content
# ...
# liked tweets (md heading 2)
#
# if a date is provided - only do this for the date noted, otherwise, use the
# curernt date (this is tob e run from crontab @23:50 america/central

import argparse
import datetime
import re


def main(argv):
    date = ""
    if args.date:
        date = datetime.datetime.strptime(args.date, "%Y-%m-%d")
        # we're not interested in the time info
        date = datetime.date(date.year, date.month, date.day)
    else:
        today = datetime.date.today()
        date = datetime.date(today.year, today.month, today.day)

    tweets = parseFile(args.infile, date)


def parseFile(infile, date):
    """
    iterate through the file.  for each tweet on each date, assemble a list of
    tweets and liked tweets with the content formatted correctly for ingest
    into the day1 application.

    parsing as follows

    if date is valid
      begin capturing the tweet content and appending it to the twt_buff
      when @end is reached
      append twt_buff to the appropriate list
    else
      skip to the next

    """
    # sample date string [March 05, 2016 at 09:09PM]
    b_tweet_re = re.compile("^@begin-tweet \[(.*) (\d{2}), (\d{4}\]")
    b_liked_re = re.compile("^@begin-liked-tweet \[(.*) (\d{2}), (\d{4}\]")
    e_tweet_re = re.compile("^@end")

    b_embed_re = re.compile("^%%tweeet-embed-start%%")
    e_embed_re = re.compile("^%%tweeet-embed-end%%")

    twt_buff = ""       # current capture tweet buffer
    etwt_buff = ""      # current embed capture tweet buffer
    tcap_flag = ""      # flag for appending to the current tweet buffer
    ecap_flag = ""      # flag for appending to the current embed buffer
    ltwt_flag = ""      # is this a liked tweet
    tweets = []
    l_tweets = []

    with open(infile, 'wb') as tweetfile:
        for l in tweetfile:
            # beginning markers for misc. stuff
            b_tweet = re.match(b_tweet_re, l)
            b_liked = re.match(b_liked_re, l)
            b_embed = re.match(b_embed_re, l)

            # end markers
            e_embed = re.match(e_embed_re, l)
            e_tweet = re.match(e_tweet_re, l)

            if b_tweet:
                t_date = parseTweetDate(b_tweet)
                if t_date == date:
                    tcap_flag = 'ON'  # start capture process
                    twt_buff += "date"
                    twt_buff += "-" * 60, "\n"
                    next
                else:
                    next

            if b_liked:
                t_date = parseTweetDate(b_liked)
                if t_date == date:
                    tcap_flag = 'ON'  # start capture process
                    ltwt_flag = 'ON'  # this is a liked tweet
                    twt_buff += "date"
                    twt_buff += "-" * 60, "\n"
                    next
                else:
                    next

            if b_embed:
                ecap_flag = 'ON'  # start capturing the embedded tweet content
                next

            if e_embed:
                ecap_flag = 'OFF'
                # append the embedded tweet to the appropriate entry
                # reset the embedded tweet buffer
                etwt_buff = ""
                next

            if e_tweet:
                if ltwt_flag == "ON":
                    l_tweets.append(twt_buff)
                    ltwt_flag = ""  # reset flag
                else:
                    tweets.append(twt_buff)

                twt_buff = ""
                tcap_flag = 'OFF'   # stop capture process
                next

            if tcap_flag == "ON":
                twt_buff += l

            if ecap_flag == "ON":
                etwt_buff += l


def parseTweetDate(date):
    """ date - an array with the results of the regex match.


    :date: TODO
    :returns: date in the properly formatted string
    """
    twt_date = datetime.datetime.strptime(date, "%Y-%m-%d")
    twt_date = datetime.date(twt_date.year, twt_date.month,
                             twt_date.day)

    return twt_date


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('--infile', dest='infile', required=True,
                        help="file to parser for new tweets")
    parser.add_argument('--date', dest='date', required=True,
                        help="date to scan for tweets to import")

    args = parser.parse_args()
    main(args)
