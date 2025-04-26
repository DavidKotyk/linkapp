# ScraperAgent

This directory provides a Python-based web scraping agent for gathering local event and venue data.

## Requirements
Install the dependencies using:
```
cd ScraperAgent
pip install -r requirements.txt
python -m spacy download en_core_web_sm
playwright install
```

## Usage
```
cd ScraperAgent
python scraper_agent.py "San Francisco"
```
This will output structured JSON containing scraped event and venue data.

## Structure
- `utils.py`: Proxy rotation, user-agent, and timing utilities.
- `geocode.py`: Geocoding using Nominatim (OpenStreetMap).
- `parser.py`: NLP parsing using spaCy for entity extraction.
- `scraper_agent.py`: Main orchestrator using Playwright to scrape various sources.
- `requirements.txt`: Python dependencies for the agent.

## Notes
- You must respect each site's Terms of Service.
- Configure `PROXIES` in `utils.py` to use your own proxy servers.
- Expand the `scrape_*` functions with actual parsing logic for each provider.