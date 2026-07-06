# NCS WhatsApp Tender Bot

A Python bot that scrapes MSEDCL (Maharashtra State Electricity Distribution Co. Ltd.) and Mahatenders (Government of Maharashtra e-Tendering Portal) for new tenders across Maharashtra districts and talukas, then sends formatted, deduplicated alerts to WhatsApp groups through the Evolution API.

Built so tenders don't have to be tracked manually by refreshing government portals every day.

## Features

- Scrapes two sources: the MSEDCL e-tendering API and the Mahatenders NIC GEP portal.
- Matches tender descriptions and titles against a built-in map of districts and their talukas (Nagpur, Yavatmal, Amravati, Akola, Wardha, Nanded, Latur, Jalna, and more), so only relevant tenders get surfaced.
- Keeps a local JSON archive (`tender_archive.json`) of tenders already seen, and flags any tender whose closing date has changed as an updated/reflated tender instead of sending it as new.
- Sends formatted WhatsApp messages with tender number/ID, description, key dates, tender amount, EMD, and tender fee, with amounts auto-converted into lakh/crore format.
- Adds randomized delays between messages (40-120 seconds) and a longer randomized gap between the MSEDCL and Mahatenders batches (10-20 minutes), so the sending pattern doesn't look automated.
- Logs every run to a dated file under `logs/`, in addition to console output.
- Runs once a day at a randomized time within a set window, using `run_random.sh` plus a cron entry, so the run time isn't fixed and predictable.
- Comes with a `docker-compose.yml` to self-host the Evolution API (the WhatsApp gateway) with a Postgres backend.

## Tech Stack

- Python 3
- `requests` and `BeautifulSoup4` for scraping
- `python-dotenv` for configuration
- `urllib3` for suppressing SSL warnings (government portals often have certificate issues)
- Evolution API, self-hosted via Docker, as the WhatsApp gateway
- PostgreSQL 15 as the backing database for Evolution API
- Bash and cron for scheduling

## Project Structure

```
ncs-whatsapp-bot/
├── main.py                # Core scraper and WhatsApp notifier logic
├── requirements.txt        # Python dependencies
├── docker-compose.yml       # Evolution API + Postgres containers
├── run_random.sh            # Randomized-delay wrapper script, used by cron
├── cronjob.txt              # Reference crontab entry
├── tender_archive.json       # Auto-generated store of already-notified tenders
└── logs/                    # Auto-generated daily log files (DDMMYYYY.txt)
```

## How It Works

1. `check_msedcl()` calls the MSEDCL tender API, parses each tender, matches it to a district and taluka, and formats a message with dates, amounts, and fees.
2. `check_mahatenders()` submits a search per district on the Mahatenders portal, scrapes the results table, and visits each tender's detail page for its value, fee, and EMD.
3. Every tender ID or description is checked against `tender_archive.json`. New tenders go out as fresh alerts, tenders with a changed closing date go out as updated/reflated alerts, and unchanged tenders are skipped.
4. Messages are grouped by district: a district header goes out first, followed by each tender, with a delay between sends.
5. Once the MSEDCL batch is done, the bot waits a random 10-20 minutes before starting on Mahatenders (only if at least one MSEDCL message actually went out).
6. At the end of the run, any newly seen tenders are merged into `tender_archive.json`.

## Getting Started

### Prerequisites

- Python 3.9+
- Docker and Docker Compose, for running your own WhatsApp gateway via Evolution API
- A WhatsApp number to connect as the sending instance

### Clone the repository

```bash
git clone https://github.com/chiragjaju13/ncs-whatsapp-bot.git
cd ncs-whatsapp-bot
```

### Set up a virtual environment and install dependencies

```bash
python3 -m venv venv
source venv/bin/activate      # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Start the WhatsApp gateway

```bash
docker-compose up -d
```

This starts two containers:
- `evolution-postgres`, the Postgres 15 backing store
- `evolution-api`, the Evolution API server, exposed on `http://localhost:8080`

Open the Evolution API manager, create an instance, and scan the QR code with the WhatsApp account the bot should send from. Note down the API key and instance name, since they're needed in the next step.

### Configure environment variables

Create a `.env` file in the project root:

```env
EVOLUTION_API_URL=http://localhost:8080
EVOLUTION_API_KEY=your_evolution_api_key
EVOLUTION_INSTANCE=your_instance_name
WA_GROUP_MSEDCL=xxxxxxxxxx-xxxxxxxxxx@g.us
WA_GROUP_MAHATENDERS=xxxxxxxxxx-xxxxxxxxxx@g.us
```

`WA_GROUP_MSEDCL` and `WA_GROUP_MAHATENDERS` are the WhatsApp group IDs that MSEDCL and Mahatenders alerts get sent to. They can point to the same group if there's no need to separate them.

### Run it manually

```bash
python3 main.py
```

Logs for the run get written to `logs/<DDMMYYYY>.txt` and printed to the console.

## Scheduling

`run_random.sh` activates the virtual environment, waits a random delay (0-659 minutes), logs the scheduled fire time to `bash_cron.log`, then runs `main.py`.

1. Update the path inside `run_random.sh` to match wherever the bot is deployed:
   ```bash
   TARGET_DIR="Desktop/whatsapp_tender_bot"
   ```
2. Add a cron entry to trigger the wrapper once a day, using `cronjob.txt` as a reference:
   ```cron
   0 7 * * * /bin/bash /home/Desktop/whatsapp_tender_bot/run_random.sh
   ```
   This fires the wrapper daily at 8:00 AM, which then waits a random amount of time before the actual scrape runs, so the real run lands at a different time each day.

Edit with `crontab -e` and adjust the path and time as needed.

## Districts Covered

Amravati, Akola, Washim, Buldhana, Yavatmal, Nagpur, Wardha, Bhandara, Gondia, Chandrapur, Gadchiroli, Latur, Dharashiv, Nanded, Beed, Hingoli, Parbhani, and Jalna, matched down to the taluka level.

To add or change coverage, edit the `DISTRICT_DATA` dictionary in `main.py`.

## Notes

- This scrapes public government tender portals. Use it responsibly, respect the source portals' terms of use, and avoid running it often enough to burden their servers.
- SSL verification is disabled (`verify=False`) for requests to these portals because of certificate issues on some government sites. Worth keeping in mind if this code gets adapted for other sites.
- `tender_archive.json` and the `logs/` folder grow over time since they're generated at runtime. Consider cleaning them up periodically for long-running deployments.

## Contributing

Issues and pull requests are welcome. If a parser breaks because a portal's HTML changed, or there's a district or tender source worth adding, feel free to open a PR.
