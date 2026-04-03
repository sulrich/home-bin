# feed-gen

RSS feed generators for monitoring minnesota politics. these scripts
track reddit posts, FEC campaign finance data, and local news mentions
for the MN-8 congressional district race.

all three python scripts use `uv run --script` with inline PEP 723
dependency metadata -- no virtualenvs or requirements files needed.

## scripts

- `mn_politics_monitor.py` - monitors MN-focused subreddits for politically
  relevant posts. filters by politician names, political keywords, and flair
  tags. deduplicates across runs via a state file.

- `mn8_fec_monitor.py` - tracks FEC campaign finance data for the MN-8 race
  (2026 cycle). monitors candidate filings, financial totals, new entrants, and
  withdrawals.

- `mn8_news_monitor.py` - aggregates local MN news RSS feeds (star tribune,
  minnpost, minnesota reformer, WDIO, etc.) for mentions of MN-8 candidates.

- `feed-gen.sh` - cron-ready wrapper that sources credentials and
  runs all three monitors. no flags needed.

## configuration

paths and credentials are sourced from an env file, following the same pattern
as `pr-snarf.sh`. create `~/.credentials/feed-gen.env` with:

```bash
FEED_GEN_WWW_DIR="/Volumes/media/dyn.botwerks.net/www"
FEED_GEN_REPORT_DIR="${HOME}/path/to/obsidian/vault/reports"
FEED_GEN_CACHE_DIR="${HOME}/.cache/feed-gen"
FEC_API_KEY="your-key-here"  # optional, defaults to DEMO_KEY
```

the env vars control where output goes:

- `FEED_GEN_WWW_DIR` -- web root. RSS feeds land in `<www>/rss/`.
- `FEED_GEN_REPORT_DIR` -- where markdown reports go. point this at a directory
  inside your obsidian vault to have reports show up there automatically.
  reports are written as `<report-dir>/<date>-<name>.md`.
- `FEED_GEN_CACHE_DIR` -- where state and cache files live between runs. keeps
  track of previously seen posts/articles/filings to avoid duplicates.
- `FEC_API_KEY` -- only used by the FEC monitor. get a real key at
  https://api.data.gov/signup/ if you're hitting rate limits with `DEMO_KEY`.

## usage

### via cron (typical)

just run the wrapper -- it sources the env file and passes everything
through:

```text
*/30 * * * * /path/to/feed-gen/feed-gen.sh
```

### running scripts individually

each script accepts the same core flags plus env var fallbacks:

```text
uv run --script mn_politics_monitor.py \
  -w /path/to/www -r /path/to/reports -c /path/to/cache
```

#### common flags

| short | long           | description                                  |
|:-----:|:---------------|:---------------------------------------------|
|  `-n` | `--dry-run`    | print what would be saved, write nothing     |
|  `-f` | `--force-all`  | ignore state file, process everything        |
|  `-m` | `--markdown`   | write a daily markdown report                |
|  `-w` | `--www-dir`    | web root for RSS (env: FEED_GEN_WWW_DIR)     |
|  `-r` | `--report-dir` | report output dir (env: FEED_GEN_REPORT_DIR) |
|  `-c` | `--cache-dir`  | cache/state dir (env: FEED_GEN_CACHE_DIR)    |

#### FEC monitor only

| short | long             | description                              |
|-------|------------------|------------------------------------------|
| `-k`  | `--fec-api-key`  | FEC API key (env: FEC_API_KEY)           |

CLI flags override env vars. `--www-dir`, `--report-dir`, and
`--cache-dir` are all required one way or another - the scripts will
exit with an error if neither the flag nor the env var is set.

## output

each script produces:

- **RSS feed** (always) - written to `<www-dir>/rss/<feed-name>.rss`
- **markdown report** (opt-in via `-m`) - daily file appended to
  `<report-dir>/<date>-<name>.md`
- **state file** - tracks seen posts/articles/filings to avoid
  duplicates between runs. stored in `<cache-dir>/`.

## dependencies

managed inline via PEP 723 script metadata. `uv` handles resolution
and caching automatically. the main deps are:

- `requests` -- all three scripts
- `feedparser` -- news monitor only
